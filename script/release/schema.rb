require "stringio"
require "digest"
require_relative "commands"

module Release
  module Schema
    # PostgreSQL may render text casts per literal or over the complete varchar
    # literal array. Only this unbounded string-literal form is equivalent here;
    # retain every literal, its order, and every other byte of the schema.
    VARCHAR_LITERAL = /'(?:[^'\\\r\n]|'')*'::character varying/
    VARCHAR_ARRAY_TO_TEXT = /ARRAY\[(#{VARCHAR_LITERAL}(?:, #{VARCHAR_LITERAL})*)\]::text\[\](?!\[)/

    def self.comparable(text)
      text.gsub(VARCHAR_ARRAY_TO_TEXT) do
        literals = Regexp.last_match(1).scan(VARCHAR_LITERAL)
        "ARRAY[#{literals.map { |literal| "#{literal}::text" }.join(', ')}]"
      end
    end

    # Rails otherwise interprets an absent schema digest as permission to rebuild
    # the test database. Record readiness only after proving the live schema matches.
    def self.record_current(pool, expected, dumper: ActiveRecord::SchemaDumper)
      observed = StringIO.new
      dumper.dump(pool, observed)
      unless comparable(observed.string) == comparable(expected)
        raise Refusal, "The migrated database differs from db/schema.rb. No schema readiness marker was written; review the schema before testing."
      end
      pool.internal_metadata[:schema_sha1] = Digest::SHA1.hexdigest(expected)
    end
  end
end
