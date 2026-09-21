# No Rails boot or database connection: consequential launcher boundaries.
ENV["BUNDLE_GEMFILE"] = File.expand_path("../../Gemfile", __dir__)
require "bundler/setup"
require "minitest/autorun"
require "json"
require_relative "../release/commands"
require_relative "../release/schema"
require_relative "../../config/ci"

class ReleaseCommandsTest < Minitest::Test
  DEVELOPMENT = "postgresql://local_user@localhost:5432/example_development"
  TEST = "postgresql://local_user@localhost:5432/example_test"

  class RecordingCommands < Release::Commands
    attr_reader :commands, :dependency_checks
    def initialize(*args)
      super
      @commands = []
      @dependency_checks = 0
    end
    def check_dependencies(_environment)
      @dependency_checks += 1
    end
    def execute(environment, command)
      @commands << [environment, command]
      true
    end
  end

  def launcher(environment, arguments = [])
    RecordingCommands.new(environment, arguments)
  end

  def assert_refuses_before_child(environment, arguments = [], mode: :setup)
    subject = launcher(environment, arguments)
    _out, error = capture_io { without_database_events { assert_equal 2, subject.run(mode, RELEASE_CI_STEPS) } }
    assert_match(/Refused:/, error)
    assert_equal 0, subject.dependency_checks
    assert_empty subject.commands
    error
  end

  def test_missing_target_and_environment_refuse_before_any_child
    assert_refuses_before_child({ "RAILS_ENV" => "development" })
    assert_refuses_before_child({ "DATABASE_URL" => DEVELOPMENT })
    assert_refuses_before_child({}, mode: :ci)
  end

  def test_invalid_and_redirecting_urls_never_reach_children_or_echo_credentials
    ["sqlite:///tmp/example", "postgresql://local_user@localhost:5432/", "postgresql://local_user@localhost:5432/postgres",
     "postgresql://local_user@/example", "postgresql://local_user@localhost/example",
     "postgresql://local_user:private-marker@localhost:5432/example?dbname=other",
     "postgresql://local_user@localhost:5432/example?hostaddr=127.0.0.1",
     "postgresql://local_user@localhost:5432/example?port=5433"].each do |url|
      error = assert_refuses_before_child({ "RAILS_ENV" => "development", "DATABASE_URL" => url })
      refute_includes error, "private-marker"
      refute_includes error, url
    end
  end

  def test_unknown_destructive_or_incompatible_arguments_refuse_before_dependencies
    [["--reset"], ["--skip-server"], ["--unknown"], ["--help", "--reset"]].each do |arguments|
      assert_refuses_before_child({ "RAILS_ENV" => "development", "DATABASE_URL" => DEVELOPMENT }, arguments)
      assert_refuses_before_child({ "TEST_DATABASE_URL" => TEST }, arguments, mode: :ci)
    end
  end

  def test_setup_rejects_conflicting_environment_and_database_overrides
    assert_refuses_before_child({ "RAILS_ENV" => "development", "RACK_ENV" => "test", "DATABASE_URL" => DEVELOPMENT })
    %w[PGSERVICE PGHOSTADDR PGHOST PGDATABASE PGPASSWORD PRIMARY_DATABASE_URL].each do |key|
      assert_refuses_before_child({ "RAILS_ENV" => "development", "DATABASE_URL" => DEVELOPMENT, key => "not-used" })
    end
  end

  def test_ci_overrides_inherited_development_for_every_child
    subject = launcher("RAILS_ENV" => "development", "RACK_ENV" => "development", "DATABASE_URL" => DEVELOPMENT,
      "DEVELOPMENT_DATABASE_URL" => DEVELOPMENT, "TEST_DATABASE_URL" => TEST, "PARALLEL_WORKERS" => "8")
    capture_io { assert_equal 0, subject.run(:ci, RELEASE_CI_STEPS) }
    assert_equal 1, subject.dependency_checks
    assert_equal RELEASE_CI_STEPS.length, subject.commands.length
    subject.commands.each do |environment, _command|
      assert_equal "test", environment["RAILS_ENV"]
      assert_equal "test", environment["RACK_ENV"]
      assert_equal TEST, environment["DATABASE_URL"]
      assert_equal "true", environment["SKIP_TEST_DATABASE"]
      assert_equal "1", environment["PARALLEL_WORKERS"]
      assert_equal "true", environment["BUNDLE_FROZEN"]
      assert_equal File.expand_path("../../Gemfile", __dir__), environment["BUNDLE_GEMFILE"]
    end
  end

  def test_same_declared_development_and_test_target_is_refused
    assert_refuses_before_child({ "RAILS_ENV" => "development", "DATABASE_URL" => DEVELOPMENT,
      "TEST_DATABASE_URL" => DEVELOPMENT }, mode: :ci)
    assert_refuses_before_child({ "RAILS_ENV" => "development", "DATABASE_URL" => DEVELOPMENT,
      "TEST_DATABASE_URL" => DEVELOPMENT })
    assert_refuses_before_child({ "RAILS_ENV" => "test", "DATABASE_URL" => TEST,
      "DEVELOPMENT_DATABASE_URL" => TEST })
  end

  def test_different_roles_do_not_make_a_shared_database_safe_for_tests
    assert_refuses_before_child({ "DEVELOPMENT_DATABASE_URL" => DEVELOPMENT,
      "TEST_DATABASE_URL" => DEVELOPMENT.sub("local_user", "another_role") }, mode: :ci)
  end

  def test_setup_accepts_explicit_private_socket_and_only_runs_migration_runner
    socket = "postgresql:///example_development?host=%2Ftmp%2Fexample_socket&port=5432&username=local_user"
    subject = launcher("RAILS_ENV" => "development", "DATABASE_URL" => socket)
    capture_io { assert_equal 0, subject.run(:setup) }
    assert_equal 1, subject.commands.length
    environment, command = subject.commands.first
    assert_equal socket, environment["DATABASE_URL"]
    assert_equal [RbConfig.ruby, "bin/rails", "runner", "script/release/migrate.rb"], command
    assert_equal "true", environment["SKIP_TEST_DATABASE"]
  end

  def test_socket_role_conflicts_and_rails_incompatible_userinfo_are_refused_before_children
    ["postgresql://local_user@/example_development?host=%2Ftmp%2Fexample_socket&port=5432",
     "postgresql://local_user@localhost:5432/example_development?username=other_user",
     "postgresql:///example_development?host=%2Ftmp%2Fexample_socket&port=5432&username=local_user&username=other_user",
     "postgresql:///example_development?host=%2Ftmp%2Fexample_socket&port=5432&%75sername=local_user"].each do |url|
      assert_refuses_before_child({ "RAILS_ENV" => "development", "DATABASE_URL" => url })
    end
  end

  def test_real_failing_child_returns_its_status_and_stops_later_ci_steps
    subject = Release::Commands.new({ "TEST_DATABASE_URL" => TEST }, [])
    def subject.check_dependencies(_environment); end
    steps = [["Deliberate child failure", "-e", "exit 23"], ["Must not run", "-e", "puts 'UNEXPECTED_LATER_STEP'"]]
    output, error = capture_io { assert_equal 23, subject.run(:ci, steps) }
    refute_includes output, "Must not run"
    refute_includes output, "UNEXPECTED_LATER_STEP"
    assert_includes error, "failed; stopping"
  end

  def test_schema_mismatch_refuses_without_changing_existing_readiness_metadata
    metadata = { schema_sha1: "previous-marker", environment: "test" }
    pool = Struct.new(:internal_metadata).new(metadata)
    dumper = Object.new
    def dumper.dump(_pool, stream); stream.write("different schema\n"); end
    error = assert_raises(Release::Refusal) { Release::Schema.record_current(pool, "expected schema\n", dumper: dumper) }
    assert_includes error.message, "No schema readiness marker was written"
    assert_equal({ schema_sha1: "previous-marker", environment: "test" }, metadata)
  end

  def test_only_exact_schema_match_records_the_digest_rails_checks
    expected = "same schema\n"
    metadata = { environment: "test" }
    pool = Struct.new(:internal_metadata).new(metadata)
    dumper = Object.new
    def dumper.dump(_pool, stream); stream.write("same schema\n"); end
    Release::Schema.record_current(pool, expected, dumper: dumper)
    assert_equal Digest::SHA1.hexdigest(expected), metadata[:schema_sha1]
    assert_equal "test", metadata[:environment]
    assert_equal [:environment, :schema_sha1], metadata.keys
  end

  def test_equivalent_whole_literal_array_text_cast_preserves_schema_readiness
    expected = "input_profile::text = ANY (ARRAY['official_cnw_v401'::character varying::text, 'demo'::character varying::text])"
    observed = "input_profile::text = ANY (ARRAY['official_cnw_v401'::character varying, 'demo'::character varying]::text[])"
    metadata = { environment: "test" }
    pool = Struct.new(:internal_metadata).new(metadata)
    dumper = Object.new
    dumper.define_singleton_method(:dump) { |_pool, stream| stream.write(observed) }
    Release::Schema.record_current(pool, expected, dumper: dumper)
    assert_equal Digest::SHA1.hexdigest(expected), metadata[:schema_sha1]
    assert_equal expected, Release::Schema.comparable(observed)
  end

  def test_cast_normalization_does_not_hide_changed_literals_types_or_predicates
    expected = "input_profile::text = ANY (ARRAY['official_cnw_v401'::character varying::text, 'demo'::character varying::text])"
    equivalent = "input_profile::text = ANY (ARRAY['official_cnw_v401'::character varying, 'demo'::character varying]::text[])"
    [equivalent.sub("'demo'", "'other'"),
     equivalent.sub(", 'demo'::character varying", ""),
     equivalent.sub("character varying", "character varying(4)"),
     equivalent.sub("'demo'::character varying", "NULL"),
     equivalent.sub("input_profile::text", "other_column::text"),
     equivalent.sub("::text[]", "::varchar[]")].each do |observed|
      metadata = { schema_sha1: "previous-marker" }
      pool = Struct.new(:internal_metadata).new(metadata)
      dumper = Object.new
      dumper.define_singleton_method(:dump) { |_pool, stream| stream.write(observed) }
      assert_raises(Release::Refusal) { Release::Schema.record_current(pool, expected, dumper: dumper) }
      assert_equal({ schema_sha1: "previous-marker" }, metadata)
    end
  end

  def test_help_exits_without_prerequisites_or_target
    subject = launcher({}, ["--help"])
    capture_io { assert_equal 0, subject.run(:setup) }
    assert_equal 0, subject.dependency_checks
    assert_empty subject.commands
  end
  # Prospective F5-R1 environment/URL matrix. Example endpoints are never contacted.
  TARGET_CONTRACT_CASES = JSON.parse(<<~'JSON').freeze
[
  {"id":"ENV-01","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"ENV-02","mode":"ci","environment":{"RAILS_ENV":"development","RACK_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"ENV-03","mode":"ci","environment":{"DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development"},"expected":2,"arguments":[]},
  {"id":"ENV-04-empty","mode":"ci","environment":{"RAILS_ENV":"","RACK_ENV":"","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development"},"expected":2,"arguments":[]},
  {"id":"ENV-05-empty","mode":"ci","environment":{"RAILS_ENV":"development","DEVELOPMENT_DATABASE_URL":"","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development"},"expected":2,"arguments":[]},
  {"id":"ENV-04-space","mode":"ci","environment":{"RAILS_ENV":" \t\n","RACK_ENV":" \t\n","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development"},"expected":2,"arguments":[]},
  {"id":"ENV-05-space","mode":"ci","environment":{"RAILS_ENV":"development","DEVELOPMENT_DATABASE_URL":" \t\n","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development"},"expected":2,"arguments":[]},
  {"id":"ENV-06","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"ENV-07","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_official","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"ENV-08","mode":"ci","environment":{"RAILS_ENV":"test","RACK_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"ENV-09-absent","mode":"ci","environment":{"RAILS_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"ENV-09-empty","mode":"ci","environment":{"RAILS_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","RACK_ENV":""},"expected":0,"arguments":[]},
  {"id":"ENV-09-space","mode":"ci","environment":{"RAILS_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","RACK_ENV":" \t"},"expected":0,"arguments":[]},
  {"id":"ENV-10-absent","mode":"ci","environment":{"RACK_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"ENV-10-empty","mode":"ci","environment":{"RACK_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","RAILS_ENV":""},"expected":0,"arguments":[]},
  {"id":"ENV-10-space","mode":"ci","environment":{"RACK_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","RAILS_ENV":" \t"},"expected":0,"arguments":[]},
  {"id":"ENV-11-test","mode":"ci","environment":{"RAILS_ENV":"test","RACK_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"ENV-11-development","mode":"ci","environment":{"RAILS_ENV":"development","RACK_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"ENV-12-production","mode":"ci","environment":{"RAILS_ENV":"production","RACK_ENV":"production","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development"},"expected":2,"arguments":[]},
  {"id":"ENV-12-review","mode":"ci","environment":{"RAILS_ENV":"review","RACK_ENV":"review","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development"},"expected":2,"arguments":[]},
  {"id":"ENV-12-test","mode":"ci","environment":{"RAILS_ENV":" test ","RACK_ENV":" test ","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development"},"expected":2,"arguments":[]},
  {"id":"ENV-13","mode":"ci","environment":{"RAILS_ENV":"production","RACK_ENV":"production","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_official","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"ENV-14","mode":"ci","environment":{"RACK_ENV":"test","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development"},"expected":2,"arguments":[]},
  {"id":"ENV-15","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"invalid","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"ENV-16","mode":"ci","environment":{"DATABASE_URL":"invalid","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"ENV-test-context-overwrites-old-selection","mode":"ci","environment":{"RAILS_ENV":"test","DATABASE_URL":"invalid-old-test-selection","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"ENV-17-absent","mode":"ci","environment":{},"expected":2,"arguments":[]},
  {"id":"ENV-17-empty","mode":"ci","environment":{"TEST_DATABASE_URL":""},"expected":2,"arguments":[]},
  {"id":"ENV-17-space","mode":"ci","environment":{"TEST_DATABASE_URL":" \t"},"expected":2,"arguments":[]},
  {"id":"ENV-17-invalid","mode":"ci","environment":{"TEST_DATABASE_URL":"invalid"},"expected":2,"arguments":[]},
  {"id":"ENV-18","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://other_role@localhost:5432/example_development"},"expected":2,"arguments":[]},
  {"id":"ENV-19-host","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@127.0.0.1:5432/example_development"},"expected":2,"arguments":[]},
  {"id":"ENV-19-port","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:6543/example_development"},"expected":2,"arguments":[]},
  {"id":"ENV-19-all","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://other_role@other.invalid:6543/example_development"},"expected":2,"arguments":[]},
  {"id":"ENV-19-socket","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql:///example_development?host=%2Ftmp%2Fother_socket&port=5432&username=local_user"},"expected":2,"arguments":[]},
  {"id":"ENV-20","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example%5Fdevelopment"},"expected":2,"arguments":[]},
  {"id":"ENV-case-significance","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/Example_development"},"expected":0,"arguments":[]},
  {"id":"SET-01-absent","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"SET-01-empty","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","RACK_ENV":""},"expected":0,"arguments":[]},
  {"id":"SET-01-space","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","RACK_ENV":" \t"},"expected":0,"arguments":[]},
  {"id":"SET-01-matching","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","RACK_ENV":"development"},"expected":0,"arguments":[]},
  {"id":"SET-02","mode":"setup","environment":{"RAILS_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development"},"expected":0,"arguments":[]},
  {"id":"SET-03","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://other_role@other.invalid:5432/example_development"},"expected":2,"arguments":[]},
  {"id":"SET-04","mode":"setup","environment":{"RAILS_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","DEVELOPMENT_DATABASE_URL":"postgresql://other_role@other.invalid:5432/example_development"},"expected":2,"arguments":[]},
  {"id":"SET-05-absent","mode":"setup","environment":{"RACK_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"SET-05-empty","mode":"setup","environment":{"RACK_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","RAILS_ENV":""},"expected":2,"arguments":[]},
  {"id":"SET-05-space","mode":"setup","environment":{"RACK_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","RAILS_ENV":" \t"},"expected":2,"arguments":[]},
  {"id":"SET-06-production","mode":"setup","environment":{"RAILS_ENV":"production","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"SET-06-padded","mode":"setup","environment":{"RAILS_ENV":" test ","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"SET-06-conflict","mode":"setup","environment":{"RAILS_ENV":"test","RACK_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"SET-07-absent","mode":"setup","environment":{"RAILS_ENV":"development"},"expected":2,"arguments":[]},
  {"id":"SET-07-empty","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":""},"expected":2,"arguments":[]},
  {"id":"SET-07-space","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":" \t"},"expected":2,"arguments":[]},
  {"id":"SET-07-invalid","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":"invalid"},"expected":2,"arguments":[]},
  {"id":"SET-08-development-absent","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development"},"expected":0,"arguments":[]},
  {"id":"SET-08-development-empty","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":""},"expected":0,"arguments":[]},
  {"id":"SET-08-development-space","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":" \t"},"expected":0,"arguments":[]},
  {"id":"SET-09-development","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"invalid"},"expected":2,"arguments":[]},
  {"id":"SET-08-test-absent","mode":"setup","environment":{"RAILS_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"SET-08-test-empty","mode":"setup","environment":{"RAILS_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","DEVELOPMENT_DATABASE_URL":""},"expected":0,"arguments":[]},
  {"id":"SET-08-test-space","mode":"setup","environment":{"RAILS_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","DEVELOPMENT_DATABASE_URL":" \t"},"expected":0,"arguments":[]},
  {"id":"SET-09-test","mode":"setup","environment":{"RAILS_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","DEVELOPMENT_DATABASE_URL":"invalid"},"expected":2,"arguments":[]},
  {"id":"SET-10-official-sequence","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_official","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"URI-01-03-setup-%6cocalhost","mode":"setup","environment":{"RAILS_ENV":"test","DATABASE_URL":"postgresql://local_user@%6cocalhost:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-01-03-setup-localhost%2Canother.invalid","mode":"setup","environment":{"RAILS_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost%2Canother.invalid:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-01-03-setup-localhost%00","mode":"setup","environment":{"RAILS_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost%00:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-01-03-setup-localhost%20","mode":"setup","environment":{"RAILS_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost%20:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-01-03-setup-localhost%2Fanother.invalid","mode":"setup","environment":{"RAILS_ENV":"test","DATABASE_URL":"postgresql://local_user@localhost%2Fanother.invalid:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-01-03-setup-[fe80::1%25en0]","mode":"setup","environment":{"RAILS_ENV":"test","DATABASE_URL":"postgresql://local_user@[fe80::1%25en0]:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-01-03-ci-%6cocalhost","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@%6cocalhost:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-01-03-ci-localhost%2Canother.invalid","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost%2Canother.invalid:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-01-03-ci-localhost%00","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost%00:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-01-03-ci-localhost%20","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost%20:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-01-03-ci-localhost%2Fanother.invalid","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost%2Fanother.invalid:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-01-03-ci-[fe80::1%25en0]","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@[fe80::1%25en0]:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-02-protected","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@%6cocalhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-02-protected-setup","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@%6cocalhost:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-04-dns-ci","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"URI-04-dns-setup","mode":"setup","environment":{"RAILS_ENV":"test","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"URI-04-ipv4-ci","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@127.0.0.1:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"URI-04-ipv4-setup","mode":"setup","environment":{"RAILS_ENV":"test","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","DATABASE_URL":"postgresql://local_user@127.0.0.1:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"URI-05-ipv6-ci","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@[::1]:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"URI-05-ipv6-setup","mode":"setup","environment":{"RAILS_ENV":"test","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","DATABASE_URL":"postgresql://local_user@[::1]:5432/example_test"},"expected":0,"arguments":[]},
  {"id":"URI-06-encoded-socket-ci","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql:///example_test?host=%2Ftmp%2Fexample_socket&port=5432&username=local_user"},"expected":0,"arguments":[]},
  {"id":"URI-06-encoded-socket-setup","mode":"setup","environment":{"RAILS_ENV":"test","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","DATABASE_URL":"postgresql:///example_test?host=%2Ftmp%2Fexample_socket&port=5432&username=local_user"},"expected":0,"arguments":[]},
  {"id":"URI-07-plain-socket-ci","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql:///example_test?host=/tmp/example_socket&port=5432&username=local_user"},"expected":0,"arguments":[]},
  {"id":"URI-07-plain-socket-setup","mode":"setup","environment":{"RAILS_ENV":"test","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","DATABASE_URL":"postgresql:///example_test?host=/tmp/example_socket&port=5432&username=local_user"},"expected":0,"arguments":[]},
  {"id":"URI-07-plus-socket-ci","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql:///example_test?host=%2Ftmp%2Fexample%2Bsocket&port=5432&username=local_user"},"expected":0,"arguments":[]},
  {"id":"URI-07-plus-socket-setup","mode":"setup","environment":{"RAILS_ENV":"test","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","DATABASE_URL":"postgresql:///example_test?host=%2Ftmp%2Fexample%2Bsocket&port=5432&username=local_user"},"expected":0,"arguments":[]},
  {"id":"URI-08-role-database-ci","mode":"ci","environment":{"DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local%2Duser@localhost:5432/example%5Ftest"},"expected":0,"arguments":[]},
  {"id":"URI-08-role-database-setup","mode":"setup","environment":{"RAILS_ENV":"test","DEVELOPMENT_DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","DATABASE_URL":"postgresql://local%2Duser@localhost:5432/example%5Ftest"},"expected":0,"arguments":[]},
  {"id":"URI-09-10-encoded-key","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test?%68ost=/tmp/example"},"expected":2,"arguments":[]},
  {"id":"URI-09-10-duplicate-key","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql:///example_test?host=/tmp/example&host=/tmp/other&port=5432&username=local_user"},"expected":2,"arguments":[]},
  {"id":"URI-09-10-authority-query","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test?username=other"},"expected":2,"arguments":[]},
  {"id":"URI-09-10-no-port","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-09-10-maintenance","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/postgres"},"expected":2,"arguments":[]},
  {"id":"URI-09-10-invalid-port","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:65536/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-09-10-scheme","mode":"ci","environment":{"TEST_DATABASE_URL":"sqlite://local_user@localhost:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-09-10-opaque","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql:example_test"},"expected":2,"arguments":[]},
  {"id":"URI-09-10-leading-space","mode":"ci","environment":{"TEST_DATABASE_URL":" postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":[]},
  {"id":"URI-09-10-trailing-space","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test "},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGSERVICE-nonempty","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGSERVICE":"x"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGSERVICE-space","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGSERVICE":" \t"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGSERVICEFILE-nonempty","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGSERVICEFILE":"x"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGSERVICEFILE-space","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGSERVICEFILE":" \t"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGHOST-nonempty","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGHOST":"x"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGHOST-space","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGHOST":" \t"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGHOSTADDR-nonempty","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGHOSTADDR":"x"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGHOSTADDR-space","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGHOSTADDR":" \t"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGPORT-nonempty","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGPORT":"x"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGPORT-space","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGPORT":" \t"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGDATABASE-nonempty","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGDATABASE":"x"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGDATABASE-space","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGDATABASE":" \t"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGUSER-nonempty","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGUSER":"x"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGUSER-space","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGUSER":" \t"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGOPTIONS-nonempty","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGOPTIONS":"x"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGOPTIONS-space","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGOPTIONS":" \t"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGPASSWORD-nonempty","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGPASSWORD":"x"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGPASSWORD-space","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGPASSWORD":" \t"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGPASSFILE-nonempty","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGPASSFILE":"x"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PGPASSFILE-space","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PGPASSFILE":" \t"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PRIMARY_DATABASE_URL-nonempty","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PRIMARY_DATABASE_URL":"x"},"expected":2,"arguments":[]},
  {"id":"OLD-01-PRIMARY_DATABASE_URL-space","mode":"ci","environment":{"TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test","PRIMARY_DATABASE_URL":" \t"},"expected":2,"arguments":[]},
  {"id":"OLD-02-setup---reset","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":["--reset"]},
  {"id":"OLD-02-setup---unknown","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":["--unknown"]},
  {"id":"OLD-02-setup---help,--reset","mode":"setup","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":["--help","--reset"]},
  {"id":"OLD-03-setup","mode":"setup","environment":{},"expected":0,"arguments":["--help"]},
  {"id":"OLD-02-ci---reset","mode":"ci","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":["--reset"]},
  {"id":"OLD-02-ci---unknown","mode":"ci","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":["--unknown"]},
  {"id":"OLD-02-ci---help,--reset","mode":"ci","environment":{"RAILS_ENV":"development","DATABASE_URL":"postgresql://local_user@localhost:5432/example_development","TEST_DATABASE_URL":"postgresql://local_user@localhost:5432/example_test"},"expected":2,"arguments":["--help","--reset"]},
  {"id":"OLD-03-ci","mode":"ci","environment":{},"expected":0,"arguments":["--help"]}
]
  JSON

  def without_database_events
    events = []
    trace = TracePoint.new(:call, :c_call) do |event|
      owner = event.defined_class.to_s
      database = owner.include?("PG") && %i[connect new open async_connect sync_connect connect_start exec query exec_params prepare exec_prepared send_query send_query_params send_query_prepared].include?(event.method_id)
      network = owner.match?(/Socket/) && %i[new open tcp connect getaddrinfo].include?(event.method_id)
      if database || network
        events << { owner: owner, method: event.method_id }
        raise "Unexpected database/network call in pure launcher test"
      end
    end
    value = trace.enable { yield }
    assert_empty events, "No SQL/connection calls are permitted in launcher probes"
    value
  ensure
    trace&.disable
  end

  def verify_target_case(row)
    env = row.fetch("environment")
    subject = launcher(env, row.fetch("arguments"))
    output, error = capture_io do
      without_database_events { assert_equal row.fetch("expected"), subject.run(row.fetch("mode").to_sym, RELEASE_CI_STEPS), row.fetch("id") }
    end
    if row.fetch("expected") != 0
      assert_equal 0, subject.dependency_checks, row.fetch("id")
      assert_empty subject.commands
      assert_match(/Refused:/, error)
      env.each_value { |value| refute_includes error, value if value.is_a?(String) && value.include?("://") }
    elsif row.fetch("arguments") == ["--help"]
      assert_equal 0, subject.dependency_checks
      assert_empty subject.commands
    else
      assert_equal 1, subject.dependency_checks
      ci = row.fetch("mode") == "ci"
      expected_commands = ci ? RELEASE_CI_STEPS.map { |_, *args| [RbConfig.ruby, *args] } : [[RbConfig.ruby, "bin/rails", "runner", "script/release/migrate.rb"]]
      assert_equal expected_commands, subject.commands.map(&:last)
      subject.commands.each do |child, _|
        assert_equal ci ? "test" : env.fetch("RAILS_ENV"), child["RAILS_ENV"]
        assert_equal child["RAILS_ENV"], child["RACK_ENV"]
        assert_equal ci ? env.fetch("TEST_DATABASE_URL") : env.fetch("DATABASE_URL"), child["DATABASE_URL"]
        assert_equal "1", child["PARALLEL_WORKERS"]
        assert_equal "true", child["SKIP_TEST_DATABASE"]
        assert_equal "true", child["BUNDLE_FROZEN"]
        assert_equal File.expand_path("../../Gemfile", __dir__), child["BUNDLE_GEMFILE"]
        %w[RAILS_ENV RACK_ENV DATABASE_URL DEVELOPMENT_DATABASE_URL TEST_DATABASE_URL].each do |key|
          refute child[key].is_a?(String) && child[key].match?(/\A[[:space:]]*\z/), "Blank #{key} must be unset"
        end
      end
    end
  end

  %w[ENV SET URI OLD].each do |group|
    define_method("test_f5r1_#{group.downcase}_contract_matrix") do
      TARGET_CONTRACT_CASES.select { |row| row.fetch("id").start_with?(group+"-") }.each { |row| verify_target_case(row) }
    end
  end

end
