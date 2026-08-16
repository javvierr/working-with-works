# Phase 1A implementation inventory

Audit date: 15 August 2026

Project: Working with works: a new approach to music cataloguing

Evidence basis: the repository state captured during the audit, read-only source inspection, and the fresh isolated execution recorded in the private Phase 1A verification ledger. A repository path or symbol cited here is implementation evidence; README and report statements are supporting evidence only.

## 1. Repository and Git baseline

- Repository root: the project root containing Gemfile, app/, config/, db/, and test/.
- Baseline branch used for the audit: main.
- At audit start, the supplied repository content had not yet been placed behind a commit boundary, so commit-derived provenance was unavailable for that review.
- Ignore behavior was assessed separately from the proposed baseline: non-ignored project paths were treated as baseline candidates, while ignored paths such as config/master.key, tmp/development_secret.txt, and .DS_Store were classified as exclusions.
- Applicable AGENTS.md: none found in or above the repository during the scoped search.
- docs/report_evidence/ was absent before this audit.
- All six supplied coursework/supporting inputs were available.
- Evidence authoring added the four audit files under docs/report_evidence/.

Because no commit boundary existed at audit start, Git history could not distinguish pre-existing paths from audit additions. A content comparison against the initial audit snapshot, excluding docs/report_evidence/ and the identified secret-like basenames, confirmed that every other pre-existing path still matched.

### File inventory

Generated dependency content under vendor/ and temporary content under tmp/ are excluded from this count.

| Area | Files | Principal contents |
|---|---:|---|
| Repository root | 8 | .DS_Store, .gitignore, .ruby-version, Gemfile, Gemfile.lock, README.md, Rakefile, and config.ru |
| app/ | 26 | Models, controllers, views, importer service, assets, and Rails framework stubs |
| bin/ | 5 | ci, dev, rails, rake, setup |
| config/ | 20 | Application, environments, routes, database, CI, initializers, encrypted credentials |
| data/ | 6 | Four MEI-like fixtures, fixture documentation, and an ignored .DS_Store metadata file |
| db/ | 11 | Nine migrations, schema, and empty generated seeds file |
| docs/ | 1 before audit | prototype_evaluation.md |
| lib/ | 3 | MEI Rake task and placeholders |
| log/ | 3 | .keep plus nonempty historical development and test logs |
| public/ | 11 | Static error pages and icons |
| test/ | 25 | Test helper, fixtures, 12 substantive tests, empty generated placeholders |

### Repository/submission hygiene

Secret-like filenames were identified without opening, decrypting, or printing their contents:

| Path | Git status at audit start | Audit interpretation |
|---|---|---|
| config/master.key | Observed during the audit and ignored by .gitignore | Plaintext key-like file; must remain excluded from any submission. |
| config/credentials.yml.enc | Observed at audit start and not ignored at that time | A later key-path and credential-free runtime audit found no external-service credential or application dependency; the approved manifest excludes this file. |
| tmp/development_secret.txt | Observed during the audit and ignored through /tmp/* | Secret-like temporary file; must remain excluded. |
| .gitignore | Repository ignore policy | Defines the reviewed exclusions and should remain part of the repository baseline. |

Ignore rules support submission hygiene but do not replace an explicit manifest review. log/development.log and log/test.log are nonempty ignored/generated artifacts and are historical evidence only.

Safety note: no secret value was printed. The approved manifest excludes all three secret-like paths from Git and coursework.

## 2. Declared, locked, and observed stack

| Component | Declared | Locked | Freshly executed/observed | Qualification |
|---|---|---|---|---|
| Ruby | ruby-4.0.5 in .ruby-version; 4.0.5 in Gemfile | 4.0.5 in Gemfile.lock | Ruby 4.0.5 selected explicitly for isolated verification | The default shell Ruby did not satisfy the declared runtime requirement. |
| Bundler | Lockfile manager | 4.0.15 | 4.0.15 | The lockfile resolved successfully during isolated verification. |
| Rails | ~> 8.1.3 | 8.1.3 | 8.1.3 | config/application.rb loads Rails 7.0 defaults; schema/migrations use 7.0 versioning. |
| PostgreSQL | Adapter configured in config/database.yml | pg 1.6.3 | Client/server 14.23; pg gem 1.6.3; gem-reported libpq 18.1 | Runtime verification was scoped to the test environment. |
| Nokogiri | Unconstrained direct dependency | 1.19.4 | 1.19.4 | Used by Mei::Importer for XML parsing. |
| Puma | >= 6.0 | 8.0.2 | Locked, not exercised as a listening server | Endpoint checks used Rails' in-process integration session. |
| Jbuilder | ~> 2.13 | 2.15.1 | Dependency loaded by bundle | Feature JSON is assembled manually; no Jbuilder views implement this API. |
| Sprockets Rails | Direct dependency | 3.5.2 | Bundle satisfied | Supplies the CSS asset pipeline. |

Important configuration observations:

- config/application.rb loads Active Record, Action Controller/View/Job/Cable, and Rails test-unit, but omits Active Storage, Action Mailer, Action Mailbox, and Action Text.
- config/cable.yml selects Redis in production while the Redis gem is commented out in Gemfile.
- config/puma.rb can enable a Solid Queue plugin through an environment switch, but no Solid Queue dependency is declared.
- Production SSL enforcement and a concrete content security policy are not enabled.
- These observations do not support security, deployment, or production-readiness claims.

## 3. Implemented architecture and data flow

The implemented system is a conventional server-side Rails monolith:

    data/mei_samples or MEI_DIR
        -> lib/tasks/mei.rake
        -> Mei::Importer in app/services/mei/importer.rb
        -> Nokogiri DOM parsing and field extraction
        -> Active Record transaction
        -> PostgreSQL relational tables and ImportLog records
        -> Work.filtered query scopes
        -> WorksController ERB pages and Api::WorksController JSON

The application has no write API, browser-side application framework, background import job, platform-specific deployment configuration or demonstrated deployment, linked-data endpoint, or SPARQL endpoint. It is a local read-only catalogue prototype after an operator runs the import task.

## 4. Entity, relationship, constraint, and index inventory

The audited db/schema.rb corresponds to the nine migrations under db/migrate/.

| Entity | Relationships and model behavior | Database constraints and indexes | Evidence limitations |
|---|---|---|---|
| Composer | has_many :works, dependent: :destroy; name presence and uniqueness | name NOT NULL; unique name index | One imported composer was demonstrated. |
| Work | belongs_to :composer; has_many of all six catalogue child types with dependent destroy; has_many :import_logs with nullify; title/source_file presence; source_file uniqueness | composer_id, title, source_file NOT NULL; FK to composer; unique source_file; indexes on composer, title, catalogue number, year, genre | Exactly one composer per work. This is not a multi-composer relationship. |
| CatalogueIdentifier | belongs_to work; value required | work_id/value NOT NULL; FK; unique work_id + value; value index | identifier_type is not included in DB uniqueness although importer de-duplication uses type + value. |
| Movement | belongs_to work; position required, integer, > 0; association ordered by position | work_id NOT NULL; FK; unique work_id + position; position column itself nullable; no positive-value check; title, tempo_marking, and duration are nullable/unvalidated | Direct SQL can bypass the model and store null/invalid position; descriptive movement fields are not required. |
| Instrumentation | belongs_to work; name required; association ordered by name | work_id/name NOT NULL; FK; unique work_id + name; name index | section is nullable and excluded from uniqueness. |
| SourceReference | belongs_to work | work_id NOT NULL; FK; work and source_type indexes | label/type/repository/description are all nullable and unvalidated. |
| Performance | belongs_to work; association ordered by performed_on | work_id NOT NULL; FK; indexes on work/date/location | All descriptive fields are nullable; partial/unparseable dates can be nil. |
| ExternalReference | belongs_to work | work_id NOT NULL; FK; URL index | Label and URL are nullable; URL format/scheme is not validated. |
| ImportLog | optional belongs_to work; source_file/status/imported_at required; status limited by model to success/failure | required source_file/status/imported_at; warnings JSONB NOT NULL default []; indexes on work/source/status/time; FK permits null work | No DB status check; failed attempts are unattached, so a preserved work's UI can still show the preceding success. |

All declared foreign keys exist. Migrations do not set database-level cascading actions; dependent behavior relies on Active Record callbacks.

## 5. Importer inventory

Primary evidence: app/services/mei/importer.rb, class Mei::Importer.

### File discovery and top-level result

- initialize(directory:) defaults to Rails.root.join("data/mei_samples").
- files recursively returns sorted lowercase .xml and .mei paths.
- call attempts every discovered file and returns Result with files_seen, successes, failures, and aggregated warnings.
- A missing or empty directory produces a warning rather than a failure.
- Uppercase extensions are not discovered.

lib/tasks/mei.rake exposes mei:import, permits MEI_DIR, prints directory/counts/unique warnings, and aborts if the returned failure count is positive. It does not print stored per-file exception details.

### Per-file transaction

Mei::Importer#import_file:

1. Derives source_file relative to Rails.root where possible, not relative to the selected import directory; on an ArgumentError it stores path.to_s.
2. Opens one ActiveRecord::Base.transaction.
3. Calls parse_document, extract, and the persistence steps.
4. Uses Composer.find_or_create_by!(name:).
5. Uses Work.find_or_initialize_by(source_file:), assigns the extracted attributes/composer, and saves.
6. Calls replace_children to destroy and recreate catalogue identifiers, movements, instrumentations, source references, performances, and external references.
7. Creates an attached success ImportLog.

A StandardError raised within the transaction triggers rollback and is then caught by the method-level rescue, which creates a separate failure ImportLog outside the transaction. Consequences:

- On a failed re-import, the preceding work/children survive.
- The failure log is not linked to that work.
- Failure-log creation has no second rescue; if it fails, call can abort.
- Only error.message is stored, not the exception class/backtrace.

### XML parsing and namespaces

parse_document reads the whole file and configures Nokogiri with recover, nonet, and noblanks. Parser errors become warnings and namespaces are removed before XPath extraction.

This tactic accepts the four namespaced fixtures and makes simple XPath possible. It is not MEI schema validation, does not establish general namespace tolerance, can conflate same-named elements from different namespaces, and has no file-size boundary.

extract uses the first //work element, otherwise the root. The implementation therefore imports one work-shaped record per file even if a source contains multiple works.

### Implemented XPath/fallback behavior

| Field/group | Implemented extraction strategy |
|---|---|
| Composer | A document-global first match across work composer persName/composer, titleStmt composer persName/composer, then respStmt persName. Missing value becomes "Unknown composer" and adds a warning. Because this lookup is global rather than scoped to work_node, a multi-work document could combine the selected first work with a composer found elsewhere. |
| Title | Exact order: direct child main title, direct child uniform title, direct first title, descendant main title, descendant first title, then titleStmt main/first title. There is no descendant-uniform fallback. Missing title warns and later fails Work validation. |
| Identifiers | Direct identifier/idno, then descendant fallback. Type is type, label, or "catalogue"; first identifier is denormalized into Work.catalogue_number. |
| Composition date/year | First selected creation/composition-labelled date. Text becomes composition_date. composition_year is the first four-digit token across isodate, notbefore, notafter, then text. |
| Genre | Classification genre term, any genre term, genre element, then first classification term. |
| Movements | contents mdiv elements or movement elements. Title uses head/title/label or all text; position uses n/position/document order; tempo/duration use limited child fallbacks. |
| Instrumentation | perfMedium perfRes, instrumentation instrument, or descendant instrument; count can be prefixed to name; section comes from node or parent. |
| Sources | sourceDesc source plus work sourceList source; extracts label, type, repository, and description. |
| Performances | event with exact type firstPerformance/performance plus performance elements; extracts exact date, location, people/corporations, note. |
| External references | relation/ref/ptr with target; extracts label and URL. |
| Source identifier | work id/xml:id or root id. |

normalize uses Active Support squish.presence: whitespace is collapsed and blank text becomes nil. It does not apply Unicode, case, language, or catalogue-number normalization.

Performance dates require an exact YYYY-MM-DD substring. Partial dates silently become nil. Composition date uncertainty/ranges are reduced to a display string plus the first four-digit year; their semantics are not modelled.

### De-duplication and loss boundaries

- Identifiers: exact type + value.
- Instrumentation: case-insensitive final name only; section is ignored.
- Sources: label + description; type/repository are ignored.
- External references: URL only.
- Movements and performances: no explicit de-duplication.

The importer does not preserve source bytes, a checksum/version, XML fragments, XPath per field, an import batch, per-value provenance, or prior versions of overwritten values.

### Re-import semantics

Static code and fresh execution establish:

- Identical stored source_file reuses the Work row.
- All six child collections are destroyed/recreated; their identities/timestamps change.
- Every successful pass appends a new ImportLog.
- The resulting persisted state is therefore work-count idempotent, not row-level idempotent.

Additional static limitations:

- A renamed file or different path representation can create a second Work.
- An external MEI_DIR is still made relative to Rails.root where possible, so stored/exposed source_file can contain ../ path segments; fallback behavior can store path.to_s. This can affect identity and disclose local path topology.
- Removed source files do not prune catalogue rows.
- Changing composer can leave the former composer orphaned.
- Concurrent importers can race on unique source_file.
- A failed attempt is not the latest log visible through the preserved work association.

## 6. Demonstrated sample scope

Exactly four sample files are supplied:

- data/mei_samples/cnw_18_maskarade.mei
- data/mei_samples/cnw_29_symphony_no_4.mei
- data/mei_samples/cnw_2_fynsk_foraar.mei
- data/mei_samples/cnw_34_helios.mei

They are described as follows: “Purpose-built, non-authoritative prototype fixtures informed by Carl Nielsen catalogue data and MEI structures.” They are small, homogeneous, one-work, default-namespaced fixtures; their README and embedded comments do not present them as authoritative Royal Danish Library/LOAR catalogue records, direct dataset extracts, or independently verified transcriptions.

Fresh first-import totals were 1 composer, 4 works, 8 identifiers, 11 movements, 16 instrumentation rows, 4 sources, 4 performances, 4 external references, and 4 success logs. These totals demonstrate the implemented transformation for these fixtures only.

## 7. Routes, filters, API fields, and UI

### Routes

| Verb/path | Action | Output |
|---|---|---|
| GET / | WorksController#index | HTML work list |
| GET /works | WorksController#index | HTML work list |
| GET /works/:id | WorksController#show | HTML detail |
| GET /api/works | Api::WorksController#index | JSON array |
| GET /api/works/:id | Api::WorksController#show | JSON object |

There are no create/update/delete endpoints.

### Accepted filters

Both controllers permit q, catalogue_number, instrumentation, year_from, year_to, and genre. Work.filtered combines them with AND and orders output by title in the controllers.

| Filter | Behavior |
|---|---|
| q | Case-insensitive substring OR across title, denormalized catalogue_number, and composer name |
| catalogue_number | Case-insensitive substring of the denormalized first identifier only |
| instrumentation | Case-insensitive substring subquery over Instrumentation.name |
| year_from/year_to | Inclusive integer bounds; invalid text becomes 0 through to_i |
| genre | Case-insensitive substring |

String predicates use bound parameters and sanitize_sql_like. Secondary catalogue identifiers are not searched by q or catalogue_number. There is no selectable sort, relevance ranking, pagination, result metadata, or query validation.

### API index fields

Api::WorksController#work_summary emits:

- id
- title
- composer with id and name
- catalogue_number
- composition_date
- composition_year
- genre
- instrumentation as name strings
- source_file

### API detail fields

Api::WorksController#work_detail adds:

- source_identifier
- catalogue_identifiers with type/value
- movements with position/title/tempo_marking/duration
- sources with label/type/repository/description
- performances with performed_on/location/performers/note
- external_references with label/url

The API omits import logs/warnings/errors, timestamps, child IDs, instrumentation sections, pagination, versioning, authentication, and writes.

### Server-rendered interface

app/views/works/index.html.erb implements:

- search and all six filter inputs;
- clear action and result count;
- a table with title, composer, catalogue number, year/date, genre, and instrumentation;
- an explicit no-results message.

app/views/works/show.html.erb implements:

- core work/composer metadata;
- source path and source identifier;
- catalogue identifiers, instrumentation sections, movements, sources, performances, and external links;
- latest attached import-log status and warnings.

app/views/layouts/application.html.erb links the catalogue and API, and application.css supplies a basic responsive layout.

Implementation does not prove usability, accessibility, user-friendliness, or meaningful search usefulness. Detail collections can render as empty lists, external URL schemes are not validated, source type is not shown, and failure attempts are not surfaced globally.

## 8. Automated-test implementation inventory

There are exactly 12 substantive test declarations:

- ComposerTest: 3.
- WorkTest: 3.
- Mei::ImporterTest: 2.
- ApiWorksTest: 4.

Seven generated classes contain no executable tests: six model-test classes (CatalogueIdentifierTest, ExternalReferenceTest, InstrumentationTest, MovementTest, PerformanceTest, and SourceReferenceTest) plus ApplicationCable::ConnectionTest. There is no ImportLogTest. No controller, system, setup, performance/load benchmark, security, accessibility, or usability test exists.

Detailed per-test evidence is retained in the private Phase 1A verification ledger.

## 9. Implemented and documented limitations

The following are established by code or consistent documentation:

- limited, purpose-built, non-authoritative fixture set;
- one work and one composer per imported work;
- no general MEI or schema-validity claim;
- limited XPath alternatives and case-sensitive type matching;
- simplified uncertain/ranged/partial date handling;
- no alternate-title/language or detailed scholarly responsibility model;
- simple ILIKE substring search;
- no field-level provenance;
- no API pagination, versioning, authentication, write operations, or sort metadata;
- no usability, performance, scalability, security, accessibility, deployment, or production evaluation;
- no demonstrated multi-composer catalogue;
- no authoritative Carl Nielsen/LOAR evaluation.
- no repository screenshot, graph, or diagram artifact documenting the fresh implementation state; the preliminary-report PDF contains earlier diagrams, but they are coursework history rather than repository execution evidence.

Report-safe overall statement:

> The repository implements and freshly demonstrates an end-to-end Rails/PostgreSQL feasibility prototype using four files classified as “Purpose-built, non-authoritative prototype fixtures informed by Carl Nielsen catalogue data and MEI structures.” It transforms selected fields into related database records, a read-only JSON API, and server-rendered catalogue pages. It does not establish general MEI compatibility, authoritative catalogue fidelity, usability, production readiness, or full scholarly provenance.
