# bin/ci validates TEST_DATABASE_URL and fixes every child to the test environment.
# No installation, security scanner, seed replant or remote status publication.
RELEASE_CI_STEPS = [
  ["Release command refusal and failure tests", "script/f5_validation/release_commands_test.rb"],
  ["Prepare the explicitly selected test database", "bin/setup"],
  ["Complete Rails test suite", "bin/rails", "test"]
].freeze
