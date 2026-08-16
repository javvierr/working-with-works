# Prototype evaluation

## What the prototype demonstrates

This prototype demonstrates an end-to-end technical path from MEI-like XML files to a database-backed catalogue browser:

MEI XML source records -> Nokogiri import/transformation -> PostgreSQL relational model -> JSON API -> Rails web pages.

The importer can read a directory of `.xml` or `.mei` files, extract selected catalogue fields, create or update records, preserve file- and record-level source traceability through the source filename/path and source identifier, and record import logs with warnings.

## Fields successfully imported

The four included MEI files are described as follows: “Purpose-built, non-authoritative prototype fixtures informed by Carl Nielsen catalogue data and MEI structures.” They are not authoritative records, direct dataset extracts, or independently verified transcriptions.

These four fixtures exercise these fields:

- composer name
- work title
- catalogue identifiers, including CNW and FS-style identifiers
- composition date and extracted composition year
- genre/category
- instrumentation
- movements or sections
- source references and repositories
- performance dates, locations, and performers
- external catalogue references
- source XML filename/path
- source XML identifier where present

## Difficult or omitted fields

The prototype does not attempt to parse the full MEI model. It omits or simplifies:

- complex responsibility statements
- uncertain, approximate, or ranged date semantics beyond extracting a first year
- manuscript source hierarchies beyond a simple source reference
- alternate titles and title language handling
- detailed performance forces and score structure
- multiple works stored in a single MEI file
- preservation of exact source XPath locations for every imported value

## Feasibility assessment

The simplified database and API model appears feasible for a first catalogue exploration layer. Separating works, identifiers, movements, instrumentation, sources, performances, and external references preserves more catalogue structure than a flat title/composer table while remaining small enough for Rails views and JSON endpoints.

The biggest next risk is real-data variability. Namespace handling succeeded for the four tested fixtures, but this does not establish compatibility with authoritative LOAR records or with broader MEI structures. Import-log and warning paths are implemented, but the verified fixtures did not exercise warning-producing behavior.

The direct Rails test suite passes with 12 runs and 54 assertions. Basic API and HTML smoke checks demonstrate that selected endpoints respond with the fixture-derived data; they are not evidence of usability, accessibility, performance, security, or production readiness. The current `bin/ci` command fails because the referenced `bin/importmap` executable is absent, so a passing direct test run must not be described as a passing CI workflow.

Deployment readiness is also unproven. Production Action Cable selects Redis while the corresponding Redis dependency is not installed, and Puma conditionally references Solid Queue without the corresponding installed and configured dependency.

## Recommended improvements

- Run the importer against a larger real Carl Nielsen MEI subset.
- Add field-level provenance, such as XPath or XML snippets, for stronger traceability.
- Add a data-quality review page for failed imports and warnings.
- Expand tests with real MEI examples once available.
- Add pagination, sorting, and full-text search for larger datasets.
