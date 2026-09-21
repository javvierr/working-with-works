# Portable launchers: explicit targets, installed dependencies, no service management.
require "uri"
require "rbconfig"
require "rubygems"

module Release
  class Refusal < StandardError; end
  class ChildFailure < StandardError
    attr_reader :status
    def initialize(status)
      @status = status
    end
  end

  class Commands
    ROOT = File.expand_path("../..", __dir__)
    CONFLICTING_ENV = %w[PGSERVICE PGSERVICEFILE PGHOST PGHOSTADDR PGPORT PGDATABASE PGUSER PGOPTIONS PGPASSWORD PGPASSFILE].freeze
    CONTROL_DECLARATIONS = %w[RAILS_ENV RACK_ENV DATABASE_URL DEVELOPMENT_DATABASE_URL TEST_DATABASE_URL].freeze

    def initialize(environment = ENV.to_h, arguments = ARGV, root: ROOT)
      @environment = environment.to_h.dup
      CONTROL_DECLARATIONS.each do |key|
        value = @environment[key]
        @environment[key] = nil if value.is_a?(String) && value.match?(/\A[[:space:]]*\z/)
      end
      @arguments = arguments
      @root = root
    end

    def run(mode, steps = [])
      if @arguments == ["--help"]
        puts(mode == :setup ? "Usage: RAILS_ENV=development|test DATABASE_URL=<explicit PostgreSQL URL> bin/setup" : "Usage: TEST_DATABASE_URL=<explicit PostgreSQL URL> bin/ci")
        return 0
      end
      raise Refusal, "Unsupported arguments. Use --help; reset, cleanup and server flags are not supported." unless @arguments.empty?

      environment = child_environment(mode)
      check_dependencies(environment)
      if mode == :setup
        run_child(environment, "Migrate the explicitly selected existing database", ruby, "bin/rails", "runner", "script/release/migrate.rb")
      else
        steps.each { |label, *command| run_child(environment, label, ruby, *command) }
      end
      0
    rescue Refusal => error
      warn "Refused: #{error.message}"
      2
    rescue ChildFailure => error
      error.status
    end

    def child_environment(mode)
      conflicting = @environment.keys.select do |key|
        (@environment[key] && !@environment[key].empty?) &&
          (CONFLICTING_ENV.include?(key) || (key.end_with?("_DATABASE_URL") && !%w[TEST_DATABASE_URL DEVELOPMENT_DATABASE_URL].include?(key)))
      end
      raise Refusal, "Remove conflicting database environment overrides before running this command." unless conflicting.empty?

      rails_env = @environment["RAILS_ENV"]
      rack_env = @environment["RACK_ENV"]
      raise Refusal, "RAILS_ENV and RACK_ENV conflict." if rails_env && rack_env && rails_env != rack_env

      if mode == :setup
        raise Refusal, "Set RAILS_ENV explicitly to development or test." unless %w[development test].include?(rails_env)
        url = @environment["DATABASE_URL"]
        target = parse_target(url, "DATABASE_URL")
        opposite = rails_env == "development" ? "TEST_DATABASE_URL" : "DEVELOPMENT_DATABASE_URL"
        if present?(opposite) && same_database_name?(target, parse_target(@environment[opposite], opposite))
          raise Refusal, "Development and test database names must be different."
        end
      else
        explicit_test = [rails_env, rack_env].include?("test") && [rails_env, rack_env].all? { |value| value.nil? || value == "test" }
        rails_env = "test"
        url = @environment["TEST_DATABASE_URL"]
        target = parse_target(url, "TEST_DATABASE_URL")
        protected = ["DEVELOPMENT_DATABASE_URL"]
        protected << "DATABASE_URL" unless explicit_test
        protected.each do |key|
          next unless present?(key)
          if same_database_name?(target, parse_target(@environment[key], key))
            raise Refusal, "Development and test database names must be different."
          end
        end
      end
      @environment.merge("RAILS_ENV" => rails_env, "RACK_ENV" => rails_env, "DATABASE_URL" => url,
        "SKIP_TEST_DATABASE" => "true", "PARALLEL_WORKERS" => "1", "BUNDLE_FROZEN" => "true",
        "BUNDLE_GEMFILE" => File.join(@root, "Gemfile"))
    end

    # Require endpoint, role and database; reject parameters that can override them.
    # Error text deliberately excludes the URL and its possible credentials.
    def parse_target(value, label)
      raise Refusal, "Set #{label} to an explicit PostgreSQL URL." unless value.is_a?(String) && !value.empty?
      raise Refusal, "#{label} must not contain surrounding whitespace." unless value == value.strip
      uri = URI::RFC2396_PARSER.parse(value)
      raise ArgumentError unless %w[postgres postgresql].include?(uri.scheme) && !uri.fragment && !uri.opaque
      raw_keys = (uri.query || "").split("&").map { |pair| pair.split("=", 2).first }
      raise ArgumentError unless (raw_keys - %w[host port sslmode username]).empty?
      query = URI.decode_www_form(uri.query || "")
      raise ArgumentError unless query.map(&:first).uniq.length == query.length && (query.map(&:first) - %w[host port sslmode username]).empty?
      parameters = query.to_h
      url_host = uri.host unless uri.host.nil? || uri.host.empty?
      raise ArgumentError if url_host&.include?("%")
      raise ArgumentError if url_host && parameters["host"] || uri.port && parameters["port"]
      raise ArgumentError if uri.userinfo && parameters["username"]
      host = url_host || parameters["host"]
      port = uri.port || parameters["port"]
      user = uri.user ? URI.decode_www_form_component(uri.user) : parameters.fetch("username", "")
      database = URI.decode_www_form_component((uri.path || "").delete_prefix("/"))
      raise ArgumentError if user.empty? || user.match?(/[\s\x00]/) || host.nil? || host.empty? || host.match?(/[\s,\x00]/)
      raise ArgumentError unless url_host || host.start_with?("/")
      raise ArgumentError unless port.to_s.match?(/\A[0-9]+\z/) && (1..65_535).cover?(port.to_i)
      raise ArgumentError unless database.match?(/\A[A-Za-z_][A-Za-z0-9_-]*\z/) && !%w[postgres template0 template1].include?(database)
      raise ArgumentError if parameters["sslmode"] && !%w[disable allow prefer require verify-ca verify-full].include?(parameters["sslmode"])
      [host, port.to_i, user, database]
    rescue URI::Error, ArgumentError
      raise Refusal, "#{label} must identify a PostgreSQL host (or absolute socket directory), port, user and non-maintenance database; conflicting URL parameters are not allowed."
    end

    def check_dependencies(environment)
      expected_ruby = File.read(File.join(@root, ".ruby-version")).strip.delete_prefix("ruby-")
      raise Refusal, "Use Ruby #{expected_ruby}; the current interpreter is #{RUBY_VERSION}. No installation was attempted." unless RUBY_VERSION == expected_ruby
      lock = File.read(File.join(@root, "Gemfile.lock"))
      bundler_version = lock.match(/BUNDLED WITH\s+([0-9.]+)/)&.captures&.first
      raise Refusal, "Gemfile.lock must declare its Bundler version." unless bundler_version
      begin
        bundle = Gem.bin_path("bundler", "bundle", bundler_version)
      rescue Gem::Exception
        raise Refusal, "Install Bundler #{bundler_version} through your chosen Ruby environment, then retry. No installation was attempted."
      end
      run_child(environment, "Check installed locked dependencies (no installation)", ruby, bundle, "check")
    end

    def run_child(environment, label, *command)
      puts "== #{label} =="
      return if execute(environment, command)
      status = $?.respond_to?(:exitstatus) ? $?.exitstatus : nil
      warn "#{label} failed; stopping. No later steps were run."
      raise ChildFailure, status || 1
    end

    def execute(environment, command)
      system(environment, *command, chdir: @root)
    end

    def ruby
      RbConfig.ruby
    end

    private
      # Deliberately conservative: endpoint spelling cannot prove separation.
      def same_database_name?(left, right)
        left.last == right.last
      end

      def present?(key)
        @environment[key] && !@environment[key].empty?
      end
  end
end
