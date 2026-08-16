require "test_helper"

module Mei
  class ImporterTest < ActiveSupport::TestCase
    setup do
      ImportLog.delete_all
      Work.destroy_all
      Composer.destroy_all
    end

    test "imports sample MEI files into related records" do
      result = Importer.new(directory: Rails.root.join("data/mei_samples")).call

      assert_equal 4, result.files_seen
      assert_equal 4, result.successes
      assert_equal 0, result.failures
      assert_equal 4, Work.count
      assert_equal 1, Composer.count
      assert_equal 4, ImportLog.where(status: "success").count

      work = Work.find_by!(catalogue_number: "CNW 29")
      assert_equal "Symphony No. 4, The Inextinguishable", work.title
      assert_equal "Carl Nielsen", work.composer.name
      assert_equal 4, work.movements.count
      assert_operator work.instrumentations.count, :>=, 4
      assert_equal "data/mei_samples/cnw_29_symphony_no_4.mei", work.source_file
      assert work.source_references.any?
      assert work.performances.any?
      assert work.external_references.any?
    end

    test "updates existing imported works instead of duplicating them" do
      importer = Importer.new(directory: Rails.root.join("data/mei_samples"))
      importer.call

      assert_no_difference "Work.count" do
        importer.call
      end
      assert_equal 8, ImportLog.where(status: "success").count
    end
  end
end
