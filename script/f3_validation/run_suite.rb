# frozen_string_literal: true
require_relative "f3_guard"

started_utc = Time.now.utc.iso8601(6)
guard = F3Guard.boot!
controls = nil
guard.with_phase("suite_preflight") do
  controls = guard.run_negative_controls!
  guard.schema_current!
end
result_path = ENV.fetch("F3_SUITE_RESULT_JSON")
raise F3Guard::Refusal, "Suite result already exists" if File.exist?(result_path)
raise F3Guard::Refusal, "Suite evidence must be external F3 scratch" unless File.expand_path(result_path).start_with?("/private/tmp/www_f3_")

# No rails command/rake task wrapper: requiring the unchanged helper after a
# verified current schema permits its normal maintenance check but no purge.
# A TracePoint refuses any unexpected system/spawn/fork attempt before launch.
$LOAD_PATH.unshift Rails.root.join("test").to_s
guard.with_phase("test_helper") { require Rails.root.join("test/test_helper").to_s }
raise F3Guard::Refusal, "Reviewed Minitest 6.0.6 required" unless Minitest::VERSION == "6.0.6"
# Use Minitest's supported plain Expected/Actual formatter. Its default diff
# discovery/formatter launches subprocesses, outside this guarded process.
# Assertion comparisons and failure status remain unchanged.
Minitest::Assertions.diff = nil
ARGV.replace(["--seed", "190926"])

all_results = []
reporter_class = Class.new(Minitest::StatisticsReporter) do
  define_method(:record) do |result|
    super(result)
    all_results << result
  end
  define_method(:report) do
    super()
    payload = {
      status: passed? ? "PASS" : "FAIL", started_utc: started_utc,
      ended_utc: Time.now.utc.iso8601(6), seed: 190926, workers: 1,
      tests: count, assertions: assertions, failures: failures, errors: errors,
      skips: skips, duration_seconds: total_time, guard: guard.summary,
      wrong_identity_controls: controls,
      result_details: all_results.map do |result|
        { class: result.klass, name: result.name, assertions: result.assertions,
          failures: result.failures.map { |failure| { class: failure.class.name, message: failure.message } } }
      end
    }
    File.open(result_path, File::WRONLY | File::CREAT | File::EXCL, 0o600) { |file| file.puts(JSON.pretty_generate(payload)) }
  end
  define_method(:passed?) { super() && guard.summary[:refusals].empty? && count.positive? }
end

plugin = Module.new
plugin.define_singleton_method(:minitest_plugin_init) do |options|
  Minitest.reporter << reporter_class.new(options[:io], options)
end
Minitest.register_plugin(plugin)

paths = Dir[Rails.root.join("test/**/*_test.rb")].sort.reject { |path| path.match?(%r{/test/(?:system|dummy|fixtures)/}) }
raise F3Guard::Refusal, "No existing tests found" if paths.empty?
guard.emit(kind: "suite_inputs", seed: 190926, workers: 1,
           files: paths.map { |path| { path: Pathname.new(path).relative_path_from(Rails.root).to_s, sha256: Digest::SHA256.file(path).hexdigest } })
guard.with_phase("load_existing_tests") { paths.each { |path| require path } }
guard.ensure_no_refusals!
# Minitest's unmodified autorun executes once at exit with the fixed ARGV.
guard.set_phase!("suite_execution")
