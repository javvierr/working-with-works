# Working with works

Working with works is a University of London final-project prototype for exploring selected information in a thematic music catalogue. It imports MEI XML into PostgreSQL and exposes a read-only JSON API and Rails interface. The evaluated official input is the Carl Nielsen catalogue (CNW); bundled examples are explicitly non-authoritative demo fixtures.

The pipeline is XML → strict Nokogiri parsing → a bounded relational projection → API and HTML. It is not a complete MEI implementation, catalogue editor, recommendation system or replacement for the scholarly source.

## Prerequisites

- Ruby **4.0.5**, Bundler **4.0.15**, and installed dependencies pinned in `Gemfile.lock`.
- An already running local PostgreSQL server, PostgreSQL client tools, and a role permitted to create two new databases. PostgreSQL **14.23** was used for release-preparation verification.

Provision the software and locked gems separately through your preferred environment. Project commands check installed dependencies; they do not install software, start PostgreSQL or register services. F5 verification reused installed dependencies and is not a cold installation test.

From the project directory:

```sh
ruby --version
bundle _4.0.15_ check
psql --version
```

## Separate database targets

Choose your local endpoint, role and **unused** development/test names. Never use an existing application database or one database for both environments: Rails tests load fixtures into their target. These examples use TCP; a local Unix socket is also supported.

```sh
APP_DB_HOST=127.0.0.1
APP_DB_PORT=5432
APP_DB_USER="$(id -un)"
psql -X -h "$APP_DB_HOST" -p "$APP_DB_PORT" -U "$APP_DB_USER" -d postgres
```

Within `psql`, check the names, then create the databases only if neither exists. Otherwise choose new names. F5 executed these statements with unique owned names and additional live-instance guards:

```sql
SELECT datname FROM pg_database
WHERE datname IN ('working_with_works_development', 'working_with_works_test');
CREATE DATABASE working_with_works_development
  TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE 'C' LC_CTYPE 'C';
CREATE DATABASE working_with_works_test
  TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE 'C' LC_CTYPE 'C';
```

Exit with `\q`, then set matching URLs. Keep credentials out of tracked files:

```sh
export DEVELOPMENT_DATABASE_URL="postgresql://${APP_DB_USER}@${APP_DB_HOST}:${APP_DB_PORT}/working_with_works_development"
export TEST_DATABASE_URL="postgresql://${APP_DB_USER}@${APP_DB_HOST}:${APP_DB_PORT}/working_with_works_test"
```

For a Unix socket use `postgresql:///DATABASE?host=/absolute/socket/directory&port=PORT&username=ROLE`. Percent-encode URL-special characters where needed. Every URL must identify host/socket, port, role and database. Remove conflicting `PG*` connection overrides and other `*_DATABASE_URL` overrides before running launchers. The documented pair is `DEVELOPMENT_DATABASE_URL` and `TEST_DATABASE_URL`; `DATABASE_URL` selects the current Rails command.

Development and test must have **different decoded database names**, even on different hosts, ports, sockets or roles. Names remain case-sensitive. This deliberately conservative rule does not resolve DNS aliases or discover unspecified databases; use dedicated targets and declare every target you want protected. Percent-encoded authority hosts (including encoded IPv6 scope identifiers) are unsupported. Ordinary bracketed IPv6, encoded role/database components, and percent-encoded absolute Unix socket query values remain supported; encode a literal socket-path `+` as `%2B`.

Absent, empty and whitespace-only `RAILS_ENV`, `RACK_ENV` and the three recognized URL declarations are treated as absent. Nonblank values are not trimmed into accepted values. Nonempty forbidden `PG*` and other `*_DATABASE_URL` overrides, including whitespace, are refused. Conflicting nonblank Rails/Rack environments fail before dependencies or children.

CI always protects a nonblank `DEVELOPMENT_DATABASE_URL`. It also protects inherited `DATABASE_URL` when the caller has a missing, blank, default or other non-test context; neither declaration can mask the other. A consistent explicit test context means either Rails/Rack value is exactly `test` and the other is absent or `test`; in that case CI may overwrite an inherited test selection with `TEST_DATABASE_URL`, while still protecting any declared development target. Minimal CI with only a valid `TEST_DATABASE_URL` remains supported.

For setup, `DATABASE_URL` remains the explicit selector and `RAILS_ENV` must be development or test. Development setup compares against the declared test name; test setup compares against the declared development name. A same-environment declaration is not a competing selector: the official-data setup below can select a third name while the demo development/test declarations remain set. These input checks do not prove live server identity; the isolated evaluation separately verifies its newly owned endpoints.


## Finite setup and demo import

```sh
RAILS_ENV=development DATABASE_URL="$DEVELOPMENT_DATABASE_URL" bin/setup
RAILS_ENV=test DATABASE_URL="$TEST_DATABASE_URL" bin/setup
```

Setup checks the exact Ruby and installed locked dependencies, then migrates only the explicit **existing** target. It compares the live schema in memory with unchanged `db/schema.rb` (allowing only equivalent PostgreSQL literal-array cast representations) before recording Rails’ schema-readiness digest, preventing an implicit test-database rebuild. It does not create/reset/drop databases, replant seeds, clear logs/temp files or start a server. Repeating it preserves imported rows. It accepts only no arguments or `--help`; old reset/server flags and unknown arguments are refused. An explicit development/test environment is required, and conflicting target/environment declarations fail before a database command. Generic Rails setup/reset commands are not this workflow.

Import the four bundled fixtures with their complete stable-key map:

```sh
RAILS_ENV=development DATABASE_URL="$DEVELOPMENT_DATABASE_URL" \
  MEI_DIR=data/mei_samples MEI_PROFILE=demo \
  MEI_FIXTURE_KEYS_JSON='{"cnw_18_maskarade.mei":"cnw-18","cnw_29_symphony_no_4.mei":"cnw-29","cnw_2_fynsk_foraar.mei":"cnw-2","cnw_34_helios.mei":"cnw-34"}' \
  bin/rails mei:import
```

Keep the keys stable on repeats. Import reports actual files, successes, failures and warnings, and exits nonzero if incomplete. Availability identifies demo records as non-authoritative. The default profile is strict official CNW; it never falls back to demo after a rejection. Specify the sample directory, demo profile and keys together.

## Tests, local CI and manual start

After preparing the test target:

```sh
RAILS_ENV=test RACK_ENV=test DATABASE_URL="$TEST_DATABASE_URL" \
  SKIP_TEST_DATABASE=true PARALLEL_WORKERS=1 bin/rails test
TEST_DATABASE_URL="$TEST_DATABASE_URL" bin/ci
```

CI checks installed dependencies, runs focused release-command tests, prepares the selected test database and runs the complete Rails suite. Every child uses the test environment and URL even if development was inherited. A failed child stops CI and returns nonzero. CI does not install packages, replant seeds, run unavailable importmap tooling or publish statuses. No dependency vulnerability scanner or cloud CI is claimed. The focused tests can also run with `bundle exec ruby script/f5_validation/release_commands_test.rb`.

Start the server explicitly:

```sh
RAILS_ENV=development RACK_ENV=development DATABASE_URL="$DEVELOPMENT_DATABASE_URL" \
  bin/dev --binding=127.0.0.1 --port=3000
```

Open [the works list](http://127.0.0.1:3000/works) or [API index](http://127.0.0.1:3000/api/works). Ctrl-C stops the foreground server. Setup and CI do not start it; PostgreSQL lifecycle remains your responsibility.

## Official CNW input and attribution

The established source is the Royal Danish Library / Danish Centre for Music Editing dataset, [Thematic Catalogues of Works by Carl Nielsen, Johann Adolph Scheibe, Niels W. Gade and J.P.E. Hartmann](https://loar.kb.dk/handle/1902/49096). The [dated retrieval record](docs/report_evidence/phase2_corpus_reconnaissance.md) preserves attribution and the CC0 1.0 notice observed on 16 August 2026. This is historical documentation, not a fresh remote-licence verification. No new data licence is asserted and the official corpus is not bundled.

Obtain official input separately and verify its identity. The established `dcm-catalogue-data.zip` is **234,079,300 bytes**, SHA-256 `fa3ff9e3012a6a9e8d21c098105bea3be9670945bb76aa5ea46391d2c33cf8ec`. Its selected `cnw/data-cnw` directory has 446 files totalling 26,925,115 bytes. Other catalogues are outside evaluated scope. See the historical input manifest and [F4 corpus results](docs/final_submission/f4/F4_corpus_results.csv).

Create a separate official-data database using the same explicit process. Set ordinary shell variables `OFFICIAL_DATABASE_URL` and `OFFICIAL_CNW_DIRECTORY` to that new target and the intended directory; do not export them as extra Rails connection overrides. Then:

```sh
RAILS_ENV=development DATABASE_URL="$OFFICIAL_DATABASE_URL" bin/setup
RAILS_ENV=development DATABASE_URL="$OFFICIAL_DATABASE_URL" \
  MEI_PROFILE=official_cnw_v401 MEI_DIR="$OFFICIAL_CNW_DIRECTORY" \
  bin/rails mei:import
```

F5 checks only the separately pinned six-record official smoke subset, not a new full-corpus evaluation.

## Supported meaning and import history

`CatalogueDocument` gives a validated record logical identity `(input_profile, catalogue, record_key)`. Official CNW keys retain punctuation and leading zeros; XML IDs are document-local provenance. The official profile requires the MEI namespace, version 4.0.1, one direct work and one unambiguous direct CNW identifier. Parsing retains namespaces and rejects unsupported shapes, duplicate XML IDs and DTD/entity declarations. This is bounded validation, not complete MEI schema conformance.

`WorkTitle` retains direct title order, type, language and locators. Display prefers main, untyped, uniform, alternative, then subordinate titles. Unknown types remain stored/searchable but cannot supply headings. `WorkClassificationTerm` retains work-owned direct classifications; nested documentary/component terms are not promoted to whole-work genre.

`SourceDescription`, `HeldItem` and `SourceRelation` preserve selected direct manifestation/item fields and explicit document-local relationships. Repository/shelfmark fields stay with their item. Document membership or an expression target does not establish whole-work coverage, a numbered component or a verified physical holding. Full expression graphs, cross-file resolution and other catalogues remain outside scope. Legacy bibliographic `SourceReference` rows are distinct from projected sources/items.

Same-byte reimport keeps supported facts/identities and adds an attempt. Changed valid data replaces the projection atomically within its identity/path ownership rules. Failure preserves the last committed facts and separately records the latest unsuccessful attempt. HTML distinguishes latest attempt from last success, and absent, partial, unsupported/unresolved and unprojected states. Imported paths are escaped provenance text, not promised public source links. See [F1 decisions](docs/final_submission/f1/F1_decisions.md), [F2 decisions](docs/final_submission/f2/F2_decisions.md) and [F2-R1 clarification](docs/final_submission/f2r1/F2R1_decisions.md).

## Interface and API

The list combines title-variant/composer/catalogue-text search with catalogue, instrumentation, genre and year filters. Same-title links include catalogue cues; Clear resets filters. `CNW 29` matches that typed identifier exactly; bare `29` searches stored catalogue text by substring. Instrumentation filters use source wording. Only exact `1 pf.` and `1 vl.` receive verified “one piano” and “one violin” explanations; other wording stays raw. Details expose provenance and native source/item disclosures with truthful counts and absence/partial messages.

`GET /api/works` is a bare JSON array ordered by `title ASC, id ASC`. Parameters are `q`, `catalogue_number`, `instrumentation`, `genre`, `year_from`, `year_to`, `page` and `per_page`. Defaults are page 1 and size 20; size is limited to 1–100. Success responses include `X-Total-Count`, `X-Page`, `X-Per-Page`, `X-Total-Pages` and applicable relative `Link` navigation. Traverse pages for complete results. Stable ordering assumes an unchanged dataset, not concurrent-update snapshot isolation.

`GET /api/works/:id` adds selected title/classification, legacy related fields, import history, availability and document-owned source/item/relation detail. Handled errors are JSON: invalid parameters (400), missing/invalid identity (404), unsupported format (406), without pagination metadata or sensitive input/exception values. Wildcards are literal user text. There are no write endpoints, authentication or general graph API. The [frozen API contract](docs/final_submission/f3/F3_api_contract.md) specifies normalization, error/format precedence and navigation precisely.

## Evidence and limits

[F4 technical findings](docs/final_submission/f4/F4_completion.md) retain their original build: 446 successful initial imports, repeats and replay; 1,800 selected source units independently compared with SQL and API; 234 synthetic and 272 canonical API cases; and 164 tests / 2,586 assertions per F4 suite run. These are separate measures. Successful import and SQL/API agreement do not establish whole-catalogue accuracy.

The 83 historical assertions remain visible: 38 preserved, six transformed, **34 omitted**, five technical/not applicable. One nested item is outside the direct-item path and one relation is unresolved. The semantic sample is purposive. Broader expressions/contributor roles, rich resource metadata, graph relationships, date interpretation and substring search retain their stated limits.

F4 timings were serial, warm-cache in-process Rack measurements including guard overhead and excluding HTTP/browser cost. They do not establish scale or comparative speed. Historical keyboard/layout/actual-200%-zoom checks are developer observations, not accessibility certification. Follow-up participant evaluation is **NOT_EVALUATED_BY_USER_DECISION**; the public three-person formative study does not establish later participant benefit.

The unchanged F4 review and additive reviewer supplement form a pair: the supplement restores 17 already-frozen expected API detail objects omitted by an archive filter, without a new experiment or changed application result. The [F5 evidence index](docs/final_submission/f5/F5_evidence_index.md), [reproduction record](docs/final_submission/f5/F5_reproduction.md) and [publication handoff](docs/final_submission/f5/F5_release_handoff.md) identify actual candidate/command results and remaining work. The accepted [F5-R1 correction](docs/final_submission/f5r1/F5R1_completion.md) records the database-target guard follow-up while preserving F5’s historical PARTIAL/P5-01 FAIL.

The linked phase records retain their dated preparation statuses, including pending publication and unperformed public-clone checks; they do not describe the distribution status of this checkout. Any later publication or exact-commit public-clone claim needs separate dated evidence. This README update establishes neither. Local preparation is not coursework submission. Final report/figures/citations/word limits, the student's own compliant video and submission receipt remain separate tasks.
