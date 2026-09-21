# These parser regressions also run standalone without Rails or a database.
require "minitest/autorun"
require "active_support/core_ext/object/blank"
require "tmpdir"
require_relative "../../../app/services/mei/input_document"

module Mei
  class InputDocumentTest < Minitest::Test
    def setup
      @directory = Dir.mktmpdir("f2-input-parser-")
    end

    def test_inert_comment_literals_do_not_become_declarations
      ["<!DOCTYPE mei>", '<!ENTITY example "inert">'].each do |literal|
        input = parse(xml.sub("<meiHead>", "<!-- #{literal} --><meiHead>"))
        assert input.valid?, input.error&.message
        assert_nil input.document.internal_subset
        assert_nil input.document.external_subset
      end
    end

    def test_title_cdata_preserves_inert_declaration_text
      ["Literal <!DOCTYPE mei> title", 'Literal <!ENTITY example "inert"> title'].each do |literal|
        input = parse(xml.sub("Synthetic title", "<![CDATA[#{literal}]]>"))
        assert input.valid?, input.error&.message
        assert_equal literal, input.title_rows.first.fetch(:raw_text)
        assert_equal literal, input.heading(input.title_rows).fetch(:row).fetch(:text)
      end
    end

    def test_actual_internal_and_external_declarations_remain_unsupported
      declarations = [
        "<!DOCTYPE mei>",
        '<!DOCTYPE mei [<!ENTITY example "declared but unused">]>',
        '<!DOCTYPE mei SYSTEM "https://f2-parser.invalid/never-fetch.dtd">'
      ]
      declarations.each do |declaration|
        input = parse(declaration + xml)
        refute input.valid?
        assert_equal "DTD and entity declarations are unsupported", input.error.message
      end
    end

    def test_entity_use_is_rejected_before_any_catalogue_extraction
      input = parse('<!DOCTYPE mei [<!ENTITY example "declared text">]>' + xml.sub("Synthetic title", "&example;"))
      refute input.valid?
      assert_nil input.work
      assert_nil input.identity
      assert_equal "DTD and entity declarations are unsupported", input.error.message
    end

    def test_malformed_xml_remains_a_strict_failure
      input = parse(xml.sub("</title>", ""))
      refute input.valid?
      assert_equal "Malformed XML", input.error.message
    end

    private

    def parse(contents)
      @input_number = (@input_number || 0) + 1
      path = File.join(@directory, "synthetic-#{@input_number}.xml")
      File.binwrite(path, contents)
      InputDocument.new(path: path, directory: @directory, input_profile: "official_cnw_v401").read
    end

    def xml
      <<~XML
        <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="4.0.1">
          <meiHead><workList><work xml:id="synthetic-parser-work">
            <identifier label="CNW">SYNTHETIC-F2-PARSER</identifier>
            <title>Synthetic title</title>
          </work></workList></meiHead>
        </mei>
      XML
    end
  end
end
