# Working with works

Feature prototype for the University of London final project "Working with works: a new approach to music cataloguing".

The prototype demonstrates this pipeline:

MEI XML source records -> Nokogiri import/transformation -> PostgreSQL relational database -> JSON API -> simple Rails web interface.

It is intentionally small. The goal is to prove feasibility, not to model the full MEI specification or build a polished catalogue product.

## Stack

- Ruby 4.0.5
- Rails 8.1.3
- PostgreSQL
- Nokogiri
- Rails server-rendered views

## Prototype scope

Imported works are stored across related tables:

- `Composer`
- `Work`
- `CatalogueIdentifier`
- `Movement`
- `Instrumentation`
- `SourceReference`
- `Performance`
- `ExternalReference`
- `ImportLog`

The importer extracts the fields needed to show catalogue complexity: composer, title, catalogue identifiers, composition date/year, genre, instrumentation, movements, source references, performance information, external references, and source XML traceability.

## Setup

Install dependencies:

```bash
bundle install
```

Create and migrate the database:

```bash
bin/rails db:setup
```

If the database already exists:

```bash
bin/rails db:migrate
```

## Import MEI XML

The default sample directory is `data/mei_samples`. These files are MEI-like fixtures for prototype testing, not authoritative Carl Nielsen records.

Import the sample records:

```bash
bin/rails mei:import
```

Import another directory of `.xml` or `.mei` files:

```bash
MEI_DIR=/path/to/mei/files bin/rails mei:import
```

The importer creates `ImportLog` rows for every file, including success/failure status, extracted work title, parser warnings, missing-field warnings, and error messages.

## Run the app

```bash
bin/rails server
```

Open:

- Web interface: `http://localhost:3000/works`
- API index: `http://localhost:3000/api/works`

## API endpoints

### List works

```http
GET /api/works
```

Supported filters:

- `q`
- `catalogue_number`
- `instrumentation`
- `year_from`
- `year_to`
- `genre`

Examples:

```bash
curl "http://localhost:3000/api/works?q=Helios"
curl "http://localhost:3000/api/works?instrumentation=strings&year_from=1910&year_to=1920"
curl "http://localhost:3000/api/works?genre=Symphony"
```

### Show one work

```http
GET /api/works/:id
```

The show response includes nested catalogue identifiers, movements, instrumentation, source references, performances, external references, and source XML traceability.

## Web interface

The Rails views provide:

- works list page
- search and basic filters
- work detail page
- visible source XML filename/path and source identifier
- related catalogue sections for movements, instrumentation, sources, performances, and external references

## Tests

Run the test suite:

```bash
bin/rails test
```

Current coverage focuses on:

- core model validations and associations
- importer behavior using sample MEI fixtures
- API index/show responses
- API filtering by search term, instrumentation, and year range

## Known limitations

- The sample XML files are representative fixtures, not authoritative Royal Danish Library / LOAR records.
- The parser supports a limited MEI subset and removes namespaces after parsing so XPath queries are stable across namespaced and simple XML.
- The prototype assumes one imported work per source file and uses `works.source_file` as a unique traceability key.
- Only selected catalogue relationships are modeled. The full MEI model is intentionally out of scope.
- Date handling extracts the first available year and only stores exact performance dates when they can be parsed safely.
- Search uses simple PostgreSQL `ILIKE` filters rather than full-text search.
- The API has no pagination, authentication, versioning, or write endpoints.
- The UI is functional rather than polished.

## Next steps

- Test against a larger set of real LOAR Carl Nielsen MEI records.
- Revisit source-file uniqueness if real files contain multiple work records.
- Preserve selected XML fragments or source XPath references for stronger scholarly traceability.
- Add richer date normalization for uncertain, ranged, and approximate dates.
- Add pagination and response metadata to `/api/works`.
- Expand importer warnings into a review page for data quality checks.
