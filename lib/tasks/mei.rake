namespace :mei do
  desc "Import MEI XML files from MEI_DIR or data/mei_samples"
  task import: :environment do
    directory = ENV.fetch("MEI_DIR", Rails.root.join("data/mei_samples").to_s)
    result = Mei::Importer.new(directory: directory).call

    puts "MEI import complete"
    puts "Directory: #{directory}"
    puts "Files seen: #{result.files_seen}"
    puts "Successes: #{result.successes}"
    puts "Failures: #{result.failures}"
    puts "Warnings:"
    result.warnings.uniq.each { |warning| puts "- #{warning}" }

    abort "MEI import finished with failures" if result.failures.positive?
  end
end
