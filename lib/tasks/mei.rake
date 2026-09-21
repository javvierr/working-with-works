namespace :mei do
  desc "Import official MEI from MEI_DIR; demo requires MEI_PROFILE=demo and explicit fixture keys"
  task import: :environment do
    directory = ENV.fetch("MEI_DIR", Rails.root.join("data/mei_samples").to_s)
    profile = ENV.fetch("MEI_PROFILE", "official_cnw_v401")
    fixture_keys = JSON.parse(ENV.fetch("MEI_FIXTURE_KEYS_JSON", "{}"))
    abort "MEI_FIXTURE_KEYS_JSON must be a JSON object" unless fixture_keys.is_a?(Hash)
    result = Mei::Importer.new(directory: directory, input_profile: profile,
      fixture_key: ENV["MEI_FIXTURE_KEY"], fixture_keys: fixture_keys).call

    puts "MEI import complete"
    puts "Directory: #{directory}"
    puts "Input profile: #{profile}#{profile == 'demo' ? ' (non-authoritative demo)' : ''}"
    puts "Files seen: #{result.files_seen}"
    puts "Successes: #{result.successes}"
    puts "Failures: #{result.failures}"
    puts "Warnings:"
    result.warnings.uniq.each { |warning| puts "- #{warning}" }
    result.run_errors.each { |error| puts "Run error: #{error}" }

    abort "MEI import did not complete successfully" unless result.success?
  end
end
