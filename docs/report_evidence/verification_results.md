# Phase 1A verification results

Audit date: 15 August 2026

Project: Working with works: a new approach to music cataloguing

## 1. Evidence labels

- FRESH: produced during this audit from the current supplied repository in a disposable working copy and dedicated test database.
- STATIC: established by current source/schema/configuration inspection but not by the associated runtime path.
- HISTORICAL: found only in pre-existing logs or coursework/supporting documents.
- UNSUPPORTED: no adequate current evidence.
- BLOCKED: an intended verification could not proceed because of a named environmental blocker.

No historical log entry is used as a substitute for the fresh test, import, endpoint, or CI results below.

## 2. Isolation and preservation

- Main working copy: /Users/javier/Documents/academia/uol/final project/prototype/UoL final project
- Disposable baseline: /tmp/cm3070-phase1a.QA9RHU/baseline
- Disposable runtime copy: /tmp/cm3070-phase1a.QA9RHU/runtime
- Disposable bundle path: /tmp/cm3070-phase1a.QA9RHU/bundle
- Dedicated database: uol_final_project_phase1a_20260815_audit
- Rails environment for all stateful commands: test
- Database URL selected the named local database only; no development or production database was touched.
- No listening Rails server was started. Endpoint checks used ActionDispatch::Integration::Session in-process, so no server process required cleanup.
- The dedicated database was dropped after verification and a PostgreSQL query confirmed it no longer existed.
- The main working copy was compared with the pre-audit baseline before evidence authoring; no difference existed outside docs/report_evidence/.
- The initial broad rsync used for isolation duplicated config/master.key, config/credentials.yml.enc, and tmp/development_secret.txt into the disposable copies before their names were detected. No content was intentionally inspected, decrypted, or printed. All five temporary duplicate instances were deleted by exact path, and a filename-only search confirmed that none remained under the audit temp directory.

The repository had no tracked files or HEAD at the start. Preservation therefore depends on the external baseline comparison, not git diff.

## 3. Command/result ledger

Commands below are the substantive baseline, environment, setup, execution, diagnostic, and preservation commands. File-reading commands such as rg, sed, find, and diff were read-only.

### 3.1 Repository baseline

Command:

    git status --short --branch

- Environment: main working copy.
- Exit: 0.
- Relevant output: No commits yet on main; all non-ignored supplied paths were listed as untracked. A separate tracked-file count was zero, and ignored secret-like paths were classified with git check-ignore.
- Result: PASS, FRESH baseline.
- Proves: branch and working-tree status at audit start.
- Does not prove: that the untracked files are original or unchanged before the audit.

Commands:

    git rev-parse --show-toplevel
    git branch --show-current
    git rev-parse HEAD
    git log -5 --oneline --decorate

- Environment: main working copy.
- Exits: top-level 0; branch 0; HEAD 128; a final read-only git log confirmation also exited 128.
- Relevant output: repository root matched the working directory; branch main; HEAD was ambiguous; git log confirmed that main has no commits.
- Result: PASS for baseline discovery, FRESH; no-history condition confirmed.
- Proves: there is no commit SHA or meaningful recent history.
- Does not prove: file provenance.

Commands:

    git ls-files | wc -l
    git check-ignore -v config/master.key tmp/development_secret.txt config/credentials.yml.enc

- Environment: main working copy.
- Exit: 0 for the tracked count; check-ignore matched master.key and the tmp secret-like file but not credentials.yml.enc.
- Relevant output: 0 tracked files; config/master.key ignored by /config/master.key; tmp/development_secret.txt ignored by /tmp/*.
- Result: PASS, FRESH.
- Proves: Git classification by filename.
- Does not prove: the contents or safety of any credential-like file; no content was intentionally inspected.

Command:

    diff -qr -x .git -x report_evidence /tmp/cm3070-phase1a.QA9RHU/baseline .

- Environment: main working copy, immediately before evidence authoring.
- Exit: 0; no output.
- Result: PASS, FRESH, at that historical point before the temporary secret-like duplicate cleanup.
- Proves: no pre-existing repository file differed from the initial broad baseline before evidence authoring.
- Does not prove: anything about files deliberately created under docs/report_evidence/. The identical comparison cannot be rerun after deleting the temporary secret-like baseline copies; the final scoped comparison therefore excludes their three basenames and is recorded below.

### 3.2 Runtime and dependencies

Command:

    ruby -v

- Environment: disposable runtime copy, default login-shell PATH.
- Exit: 0.
- Output: ruby 2.6.10p210.
- Result: FAIL as the project runtime; FRESH diagnostic.
- Proves: the default shell did not automatically select .ruby-version.
- Does not prove: Ruby 4.0.5 was unavailable.

Commands:

    bundle -v
    bundle exec rails --version
    bundle check

- Environment: disposable runtime copy, default login-shell PATH.
- Exit: 1 for each.
- Relevant output: Bundler 4.0.15 required by Gemfile.lock was unavailable under system Ruby 2.6.
- Result: FAIL under the default PATH, FRESH.
- Proves: README/setup commands are not directly reproducible in this shell without selecting the declared Ruby.
- Does not prove: the locked application cannot run with its declared runtime.

Commands:

    /Users/javier/.rubies/ruby-4.0.5/bin/ruby -v
    /Users/javier/.rubies/ruby-4.0.5/bin/bundle -v

- Environment: installed user Ruby, read-only.
- Exit: 0 for both.
- Output: Ruby 4.0.5; Bundler 4.0.15.
- Result: PASS, FRESH.
- Proves: the declared interpreter and locked Bundler were locally executable.
- Does not prove: that the default shell or a different machine selects them automatically.

Command:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH bundle check

- Environment: disposable runtime copy before dependency installation.
- Exit: 1.
- Relevant output: 75 locked gems, including Rails, pg, Nokogiri, and their dependencies, were missing.
- Result: FAIL prerequisite check, FRESH.
- Proves: dependencies were not already available for Ruby 4.0.5.
- Does not prove: the locked gems were unavailable from their configured source.

Command:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH bundle install --path /tmp/cm3070-phase1a.QA9RHU/bundle

- Environment: disposable runtime copy.
- Exit: 15.
- Relevant output: Bundler 4 removed --path and instructed use of bundle config set path.
- Result: FAIL, FRESH setup diagnostic.
- Proves: older documented/typical Bundler path syntax is incompatible with Bundler 4.0.15.
- Does not prove: dependency installation itself would fail when Bundler 4 configuration syntax is used.

Commands:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH bundle config set --local path /tmp/cm3070-phase1a.QA9RHU/bundle
    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH bundle install

- Environment: disposable runtime copy only.
- First exits: config 0; sandboxed install 17 because index.rubygems.org could not be reached.
- Approved network retry exit: 0.
- Relevant output: Bundle complete; 10 Gemfile dependencies and 75 gems installed under /tmp/cm3070-phase1a.QA9RHU/bundle.
- Result: PASS after an explicit network permission, FRESH.
- Proves: locked dependencies can be installed for the declared runtime.
- Does not prove: offline reproducibility.

Post-install command:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH bundle check

- Environment: disposable runtime copy using explicit Ruby 4.0.5 and the /tmp bundle path.
- Exit: 0.
- Output: The Gemfile's dependencies are satisfied.
- Result: PASS, FRESH dependency check.
- Proves: all locked dependencies required by the selected bundle were installed.
- Does not prove: application boot, database connectivity, or offline reproducibility.

Version command:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH bundle exec ruby -e 'require "rails"; require "nokogiri"; require "pg"; puts "Ruby=#{RUBY_VERSION}"; puts "Bundler=#{Bundler::VERSION}"; puts "Rails=#{Rails::VERSION::STRING}"; puts "Nokogiri=#{Nokogiri::VERSION}"; puts "PG_gem=#{PG::VERSION}"; puts "libpq=#{PG.library_version}"'

- Environment: disposable runtime copy with the installed locked bundle.
- Exit: 0.
- Output: Ruby 4.0.5; Bundler 4.0.15; Rails 8.1.3; Nokogiri 1.19.4; pg 1.6.3; libpq numeric version 180001.
- Result: PASS, FRESH executable-version evidence.
- Proves: these versions could be required and executed together.
- Does not prove: behavior of unexecuted dependencies or a production environment.

Lockfile comparison:

    cmp -s Gemfile.lock /tmp/cm3070-phase1a.QA9RHU/baseline/Gemfile.lock
    diff -u /tmp/cm3070-phase1a.QA9RHU/baseline/Gemfile.lock Gemfile.lock

- Environment: disposable runtime lockfile versus the saved pre-install baseline lockfile.
- Exit: comparison 1; diff 1.
- Relevant output: Bundler removed only its own 4.0.15 checksum entry from the disposable lockfile.
- Result: FAIL for lockfile neutrality, FRESH; the dependency installation itself passed.
- Proves: bundle install was successful but was not lockfile-byte-neutral under Bundler 4.0.15.
- Does not prove: that another platform/Bundler invocation would make the same edit. Main-copy Gemfile.lock was never changed.

PostgreSQL commands:

    psql --version
    psql -d postgres -Atqc 'SHOW server_version'
    pg_isready

- Environment: local PostgreSQL installation; client/server checks were read-only and did not target a project development/production database.
- Exits: psql client/version query 0; first sandboxed pg_isready 2; approved read-only pg_isready retry 0.
- Outputs: client 14.23; server 14.23; first readiness output /tmp:5432 - no response; approved retry /tmp:5432 - accepting connections.
- Result: FAIL for the sandboxed readiness attempt and PASS for the approved retry, FRESH.
- Proves: the PostgreSQL client and local server were available at the recorded versions/readiness state.
- Does not prove: production-database configuration or remote connectivity.
- Note: the Rails pg gem reported its bundled libpq as 18.1 (numeric version 180001).

### 3.3 Dedicated test database and schema

Pre-existence check:

    psql -d postgres -Atqc "SELECT datname FROM pg_database WHERE datname = 'uol_final_project_phase1a_20260815_audit'"

- Environment: read-only query to the local postgres maintenance database.
- Exit: 0; no row.
- Result: PASS, FRESH; the selected database did not pre-exist.
- Proves: the exact dedicated audit database name was unused before creation.
- Does not prove: the state of any unrelated database.

Creation:

    createdb uol_final_project_phase1a_20260815_audit

- Environment: local PostgreSQL; exact dedicated database name only.
- Sandboxed exit: 1, local-socket operation not permitted.
- Approved retry exit: 0.
- Relevant output: sandboxed socket error, then no error on the approved retry.
- Result: PASS after permission, FRESH; only the clearly named audit database was created.
- Proves: creation of that isolated database.
- Does not prove: schema readiness or any application behavior.

Preparation:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH RAILS_ENV=test DATABASE_URL=postgresql:///uol_final_project_phase1a_20260815_audit bin/rails db:prepare

- Environment: disposable runtime copy; Rails test environment; dedicated DATABASE_URL.
- Sandboxed exit: 1, socket operation not permitted.
- Approved retry exit: 0.
- Relevant output: sandboxed local-socket error; approved retry completed without error output.
- Result: PASS, FRESH.
- Proves: the current schema can be prepared in an empty dedicated PostgreSQL database.
- Does not prove: development/production setup or a clean remote-machine setup.

### 3.4 Full automated test suite

Command:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH RAILS_ENV=test DATABASE_URL=postgresql:///uol_final_project_phase1a_20260815_audit bin/rails test

- Environment: disposable copy, prepared dedicated database.
- Exit: 0.
- Exact result:

    Run options: --seed 8883
    Finished in 0.680413s, 17.6363 runs/s, 79.3636 assertions/s.
    12 runs, 54 assertions, 0 failures, 0 errors, 0 skips

- Result: PASS, FRESH.
- Proves: the 12 current tests pass together once in this isolated environment.
- Does not prove: coverage beyond the exact assertions inventoried below, repeatability across platforms, or general correctness.

Post-test count inspection found fixture residue:

Command:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH RAILS_ENV=test DATABASE_URL=postgresql:///uol_final_project_phase1a_20260815_audit bin/rails runner 'puts({database: ActiveRecord::Base.connection_db_config.database, composers: Composer.count, works: Work.count, catalogue_identifiers: CatalogueIdentifier.count, movements: Movement.count, instrumentations: Instrumentation.count, source_references: SourceReference.count, performances: Performance.count, external_references: ExternalReference.count, import_logs: ImportLog.count}.to_json)'

- Environment: disposable runtime copy; Rails test environment; dedicated DATABASE_URL after the full test run.
- Exit: 0.
- Relevant output: the named database plus 2 composers, 2 works, 2 identifiers, 2 movements, 3 instrumentation rows, 2 sources, 2 performances, 2 external references, and 0 logs.
- Result: PASS, FRESH read-only residue inspection.
- Proves: the query was connected to the named audit database and the suite left fixture rows.
- Does not prove: leakage outside that named database or any importer behavior.

    {"composers":2,"works":2,"catalogue_identifiers":2,"movements":2,"instrumentations":3,"source_references":2,"performances":2,"external_references":2,"import_logs":0}

The suite did not leave the database empty. To make import totals attributable only to sample files, the dedicated database was recreated:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH RAILS_ENV=test DATABASE_URL=postgresql:///uol_final_project_phase1a_20260815_audit bin/rails db:drop db:create db:schema:load

- Environment: disposable runtime copy; Rails test environment; exact dedicated DATABASE_URL.
- Exit: 0.
- Relevant output: the named database was dropped and recreated; schema load completed without error.
- Result: PASS, FRESH permitted reset of only the named disposable test database.
- Proves: a clean schema was recreated for import attribution.
- Does not prove: the reset behavior of development/production or any unrelated database.

Zero-count command:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH RAILS_ENV=test DATABASE_URL=postgresql:///uol_final_project_phase1a_20260815_audit bin/rails runner 'puts({composers: Composer.count, works: Work.count, catalogue_identifiers: CatalogueIdentifier.count, movements: Movement.count, instrumentations: Instrumentation.count, source_references: SourceReference.count, performances: Performance.count, external_references: ExternalReference.count, import_logs: ImportLog.count}.to_json)'

- Environment: disposable runtime copy; Rails test environment; dedicated DATABASE_URL immediately after reset.
- Exit: 0; every returned count was 0.
- Relevant output: all nine domain/log table counts were zero.
- Result: PASS, FRESH read-only empty-state inspection.
- Proves: the first import began from an empty domain schema.
- Does not prove: database state before the isolated reset.

### 3.5 First sample import

Command:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH RAILS_ENV=test DATABASE_URL=postgresql:///uol_final_project_phase1a_20260815_audit bin/rails mei:import

- Environment: disposable runtime copy; Rails test environment; dedicated empty audit database; default data/mei_samples directory.
- Exit: 0.
- Exact relevant output:

    MEI import complete
    Directory: /private/tmp/cm3070-phase1a.QA9RHU/runtime/data/mei_samples
    Files seen: 4
    Successes: 4
    Failures: 0
    Warnings:

- Result: PASS, FRESH.
- Proves: all four supplied fixtures completed the current importer once with no reported warning or failure.
- Does not prove: compatibility with authoritative or structurally varied MEI.

Fresh first-import counts:

| Record type | Count |
|---|---:|
| Files seen | 4 |
| Successes | 4 |
| Failures | 0 |
| Warning items | 0 |
| Composers | 1 |
| Works | 4 |
| Catalogue identifiers | 8 |
| Movements | 11 |
| Instrumentations | 16 |
| Source references | 4 |
| Performances | 4 |
| External references | 4 |
| Import logs | 4, all success |

Count/status command:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH RAILS_ENV=test DATABASE_URL=postgresql:///uol_final_project_phase1a_20260815_audit bin/rails runner 'puts({composers: Composer.count, works: Work.count, catalogue_identifiers: CatalogueIdentifier.count, movements: Movement.count, instrumentations: Instrumentation.count, source_references: SourceReference.count, performances: Performance.count, external_references: ExternalReference.count, import_logs: ImportLog.count, import_log_statuses: ImportLog.group(:status).count, import_warning_values: ImportLog.where.not(warnings: [nil, ""]).count}.to_json)'

- Environment: disposable runtime copy; Rails test environment; dedicated database immediately after first import.
- Exit: 0.
- Relevant output: the table counts above plus four success statuses came from this query.
- Result: PASS, FRESH count/status inspection, with the warning-predicate caveat below.
- The exploratory import_warning_values predicate returned 4 because it was not a valid measure for nonempty JSONB arrays; that value is not used as warning evidence. The task output printed no warnings, and the later Array(log.warnings).length sum returned 0.
- Proves: first-import record counts and four success statuses.
- Does not prove: semantic fidelity of every stored value.

### 3.6 Re-import

Exact command, run a second time:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH RAILS_ENV=test DATABASE_URL=postgresql:///uol_final_project_phase1a_20260815_audit bin/rails mei:import

- Environment: same disposable runtime/test database after the first import.
- Exit: 0.
- Output: 4 files seen, 4 successes, 0 failures, no warnings.
- Result: PASS, FRESH.
- Proves: the same four source paths completed a second time.
- Does not prove: re-import behavior for changed bytes, renamed paths, failures, or concurrency.

| Record type | After first import | After second import | Interpretation |
|---|---:|---:|---|
| Composers | 1 | 1 | Stable |
| Works | 4 | 4 | Work-count idempotence demonstrated |
| Catalogue identifiers | 8 | 8 | Count stable; IDs changed from the first set to 9-16 |
| Movements | 11 | 11 | Count stable; IDs became 12-22 |
| Instrumentations | 16 | 16 | Count stable; IDs became 17-32 |
| Source references | 4 | 4 | Count stable; IDs became 5-8 |
| Performances | 4 | 4 | Count stable; IDs became 5-8 |
| External references | 4 | 4 | Count stable; IDs became 5-8 |
| Import logs | 4 | 8 | Four new logs appended |
| Success/failure | 4/0 logs | 8/0 cumulative logs | All attempts successful |
| Warning/error items | 0/0 | 0/0 cumulative | No fresh warning/failure-path evidence |

Work IDs remained 1-4. Child IDs increasing while counts remained constant demonstrates destroy/recreate behavior, consistent with replace_children. This is not row-level idempotence and does not test changed input.

Post-reimport identity/status command:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH RAILS_ENV=test DATABASE_URL=postgresql:///uol_final_project_phase1a_20260815_audit bin/rails runner 'models = [Composer, Work, CatalogueIdentifier, Movement, Instrumentation, SourceReference, Performance, ExternalReference, ImportLog]; payload = models.to_h { |model| [model.table_name, {count: model.count, ids: model.order(:id).pluck(:id)}] }; payload[:import_statuses] = ImportLog.group(:status).count; payload[:warning_items] = ImportLog.all.sum { |log| Array(log.warnings).length }; payload[:error_messages] = ImportLog.where.not(error_message: [nil, ""]).count; puts payload.to_json'

- Environment: disposable runtime copy; Rails test environment; dedicated database after the second import.
- Exit: 0.
- Relevant output: stable work/child counts, Work IDs 1-4, replaced child ID ranges, 8 success logs, 0 warning items, and 0 nonblank errors.
- Result: PASS, FRESH post-reimport inspection.
- Proves: cumulative counts, IDs, eight success logs, zero warning items, and zero nonblank error messages after the second import.
- Does not prove: stability of child values, behavior with changed files, or concurrent/path-alias idempotence.

### 3.7 Routes

Command:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH RAILS_ENV=test DATABASE_URL=postgresql:///uol_final_project_phase1a_20260815_audit bin/rails routes

- Environment: disposable runtime copy; Rails test environment; dedicated database.
- Exit: 0.
- Result: PASS, FRESH.
- Output confirmed exactly five GET routes: /, /works, /works/:id, /api/works, /api/works/:id.
- Proves: route recognition in the current application.
- Does not prove: endpoint behavior; that is checked separately.

### 3.8 Web and API smoke checks

Harness: a temporary /tmp-only Ruby file used ActionDispatch::Integration::Session against Rails.application. The harness itself was not added to the repository.

Deterministic-input query:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH RAILS_ENV=test DATABASE_URL=postgresql:///uol_final_project_phase1a_20260815_audit bin/rails runner 'puts Work.includes(:composer, :instrumentations).order(:id).map { |w| {id: w.id, title: w.title, composer: w.composer.name, catalogue: w.catalogue_number, year: w.composition_year, genre: w.genre, instrumentation: w.instrumentations.map(&:name)} }.to_json'

- Environment: disposable runtime copy; Rails test environment; dedicated database after the second import.
- Exit: 0.
- Result: PASS, FRESH read-only input selection.
- Relevant output: IDs 1-4 were Maskarade (1905), Symphony No. 4 (1914), Fynsk Foraar (1921), and Helios Overture (1903), with their expected sample catalogue/genre/instrumentation values.
- Proves: the exact fixture-derived inputs used to make the smoke-query expectations deterministic.
- Does not prove: fidelity to an authoritative catalogue.

Command:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH RAILS_ENV=test DATABASE_URL=postgresql:///uol_final_project_phase1a_20260815_audit bin/rails runner /tmp/cm3070-phase1a.QA9RHU/endpoint_smoke.rb

- Environment: disposable runtime copy; Rails test environment; dedicated database after the second import; in-process ActionDispatch session, no listening server.
- First exit: 1 due solely to an audit-harness NameError (a method did not receive first_work). Result: FAIL for the temporary audit harness, FRESH. It proves only that the first harness was defective; the application response was not classified from that attempt.
- Corrected temporary harness exit: 0.
- Result: PASS on corrected run, FRESH.
- Relevant output: the status/content/result facts in the table below.
- Proves: limited current HTML/JSON serialization and filter behavior over the four imported fixtures.
- Does not prove: browser usability, accessibility, performance, production HTTP behavior, or a stable API contract.

| Check | Status/content type | Relevant response facts |
|---|---|---|
| GET / | 200 text/html | Works heading and first imported title present |
| GET /works | 200 text/html | Works heading and first imported title present |
| GET /works/1 | 200 text/html | Maskarade title present |
| GET /works?genre=Symphony | 200 text/html | Filtered page rendered; Maskarade absent |
| GET /api/works | 200 application/json | 4 results ordered by title; expected summary keys present |
| GET /api/works/1 | 200 application/json | Maskarade; all expected detail keys; 2 identifiers, 3 movements, 3 instrumentation entries, 1 source, 1 performance, 1 external reference |
| GET /api/works?q=Inextinguishable | 200 application/json | 1 result, work ID 2 |
| GET /api/works?catalogue_number=CNW%2034 | 200 application/json | 1 result, work ID 4 |
| GET /api/works?genre=Opera | 200 application/json | 1 result, work ID 1 |
| GET /api/works?instrumentation=strings | 200 application/json | 2 results, work IDs 4 and 2 |
| GET /api/works?year_from=1920&year_to=1922 | 200 application/json | 1 result, work ID 3 |
| GET /api/works?instrumentation=strings&year_from=1910&year_to=1920 | 200 application/json | 1 result, work ID 2 |
| GET /api/works?q=NoSuchCatalogueTermXYZ | 200 application/json | Empty JSON array |

These checks demonstrate limited request/serialization/filter behavior over the four imported fixtures. They do not establish usability, accessibility, performance, stable API contracts, production HTTP behavior, or broad data correctness.

### 3.9 CI workflow

config/ci.rb was inspected before execution. It runs setup, bin/importmap audit, Rails tests, and seed replanting.

First command, after the imports:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH RAILS_ENV=test DATABASE_URL=postgresql:///uol_final_project_phase1a_20260815_audit bin/ci

- Environment: disposable runtime copy; Rails test environment; dedicated database still containing the two import passes.
- Exit: 1.
- Setup: passed in 1.99s.
- Importmap audit: failed immediately.
- Rails tests: 12 runs, 0 assertions, 12 errors. Every error was fixture foreign-key validation: retained import_logs referenced work IDs removed/replaced by fixture loading.
- Seeds: passed.
- Result: FAIL, FRESH post-import-state CI run.
- Proves: setup did not make that populated test database fixture-safe; the configured importmap step also failed.
- Does not prove: clean-database CI behavior, which was evaluated separately.
- Interpretation: bin/setup --skip-server prepares but does not reset an already populated test database. CI is not state-independent after an import.

The database was then dropped/recreated, leaving schema preparation to CI:

    env PATH=/Users/javier/.rubies/ruby-4.0.5/bin:$PATH RAILS_ENV=test DATABASE_URL=postgresql:///uol_final_project_phase1a_20260815_audit bin/rails db:drop db:create

- Environment: disposable runtime copy; Rails test environment; exact dedicated DATABASE_URL.
- Exit: 0.
- Relevant output: Dropped database and Created database for the exact audit name.
- Result: PASS, FRESH reset of only the named disposable database.
- Proves: the following CI run began without the post-import rows.
- Does not prove: CI behavior on arbitrary pre-existing database states.

The identical bin/ci command was then run again.

- Environment: disposable runtime copy; Rails test environment; freshly recreated dedicated database whose schema preparation was left to CI.
- Exit: 1.
- Setup: passed in 1.80s.
- Importmap audit: failed immediately.
- Rails tests:

    Run options: --seed 13418
    Finished in 0.386565s, 31.0426 runs/s, 139.6919 assertions/s.
    12 runs, 54 assertions, 0 failures, 0 errors, 0 skips

- Seeds: passed in 0.66s.
- Overall: failed in 5.23s.
- Result: FAIL, FRESH clean-CI result.
- Proves: clean CI setup, Rails tests, and the no-op seed step complete, but the overall configured workflow fails because the importmap executable is absent.
- Does not prove: green CI, domain seed correctness, security, or behavior on another machine.

Direct diagnostic:

    bin/importmap audit

- Environment: disposable runtime copy; repository command lookup, no database dependency.
- Exit: 127.
- Exact output: zsh:1: no such file or directory: bin/importmap
- Result: FAIL, FRESH direct diagnostic.
- Proves: the configured relative executable is absent in the current repository.
- Does not prove: that another import-map audit tool could not be configured in a future workflow.
- Static cause: bin/importmap and config/importmap.rb are absent, and importmap-rails is not declared or locked.
- No repair was attempted.

The passing seed step only executes the generated comment-only db/seeds.rb; it is not evidence of domain seed correctness.

### 3.10 Cleanup

Temporary secret-like duplicate cleanup:

    find /tmp/cm3070-phase1a.QA9RHU -type f \( -name 'master.key' -o -name 'credentials.yml.enc' -o -name 'development_secret.txt' \) -print
    rm /tmp/cm3070-phase1a.QA9RHU/runtime/config/master.key /tmp/cm3070-phase1a.QA9RHU/runtime/config/credentials.yml.enc /tmp/cm3070-phase1a.QA9RHU/baseline/config/master.key /tmp/cm3070-phase1a.QA9RHU/baseline/config/credentials.yml.enc /tmp/cm3070-phase1a.QA9RHU/baseline/tmp/development_secret.txt
    find /tmp/cm3070-phase1a.QA9RHU -type f \( -name 'master.key' -o -name 'credentials.yml.enc' -o -name 'development_secret.txt' \) -print

- Environment: audit-owned disposable /tmp directory only; exact filenames/paths, no content display.
- Initial find: five temporary copies by filename.
- Exact-path removal exit: 0.
- Verification find: exit 0 with no output.
- Result: PASS for cleanup, FRESH, after a procedural safety deviation.
- Proves: none of the three named secret-like basenames remained under the audit temp directory.
- Does not prove: anything about their contents; none was intentionally inspected, decrypted, or printed.
- Original repository files were not removed or modified.

Command:

    dropdb uol_final_project_phase1a_20260815_audit

- Environment: local PostgreSQL; exact audit-created database only.
- Exit: 0.
- Relevant output: no error.
- Result: PASS, FRESH; the disposable database was removed.
- Proves: successful removal request for the exact audit database.
- Does not prove: absence until verified by the following query.

Verification:

    psql -d postgres -Atqc "SELECT datname FROM pg_database WHERE datname = 'uol_final_project_phase1a_20260815_audit'"

- Environment: read-only query to the local postgres maintenance database.
- Exit: 0; no row.
- Result: PASS, FRESH.
- Proves: the named audit database no longer existed.
- Does not prove: the state of any unrelated database, which was out of scope.

No temporary server existed to stop.

### 3.11 Final Git status and preservation

Commands:

    git status --short --branch
    git status --short --untracked-files=all
    git ls-files | wc -l

- Environment: main working copy after all evidence edits.
- Exits: 0.
- Concise status: No commits yet on main; the same non-ignored project paths remained untracked; tracked-file count remained 0.
- The full untracked listing included exactly the four intended audit outputs:

    ?? docs/report_evidence/claim_evidence_register.md
    ?? docs/report_evidence/gaps_and_next_evaluation.md
    ?? docs/report_evidence/implementation_inventory.md
    ?? docs/report_evidence/verification_results.md

- Result: PASS for final status capture, FRESH.
- Proves: final branch/tracked/untracked classification and presence of the four outputs.
- Does not prove: byte identity of untracked pre-existing files; the scoped baseline comparison below addresses all non-secret-like pre-existing paths.

Final scoped comparison:

    diff -qr -x .git -x report_evidence -x master.key -x credentials.yml.enc -x development_secret.txt /tmp/cm3070-phase1a.QA9RHU/baseline .

- Environment: sanitized disposable baseline versus the main working copy after all evidence edits.
- Exit: 0; no output.
- Result: PASS, FRESH scoped preservation check.
- Proves: outside docs/report_evidence/, every pre-existing path other than the three explicitly excluded secret-like basenames matched the sanitized baseline after all audit work.
- Does not prove: byte identity of the three excluded originals, because their temporary baseline duplicates were deliberately removed. No command wrote those originals, and their filenames/statuses remained present in the main working copy.

Final temporary-copy check:

    find /tmp/cm3070-phase1a.QA9RHU -type f \( -name 'master.key' -o -name 'credentials.yml.enc' -o -name 'development_secret.txt' \) -print

- Environment: audit-owned disposable /tmp directory, filename-only search.
- Exit: 0; no output.
- Result: PASS, FRESH cleanup confirmation.
- Proves: no file with any of the three named secret-like basenames remained under the audit temp directory.
- Does not prove: absence of unrelated sensitive content by other names; none was sought or displayed.

## 4. Static audit of all substantive tests

There are exactly 12 executable test declarations and 44 explicit assertion invocations in source. Rails reported 54 assertions because helper assertions such as assert_includes expand into multiple runtime assertions.

| File/class | Exact test name | Source assertions | Classification | Actual scope |
|---|---|---:|---|---|
| test/models/composer_test.rb, ComposerTest | requires a name | 2 | Model validation; negative | Blank name invalid and expected error |
| Same | requires a unique name | 2 | Model validation; negative | Duplicate fixture name invalid |
| Same | has works | 1 | Association | Fixture composer contains one fixture work |
| test/models/work_test.rb, WorkTest | requires a title | 2 | Model validation; negative | Nil title invalid |
| Same | requires source traceability | 2 | Model validation; negative | Nil source_file invalid |
| Same | exposes catalogue associations | 5 | Association | Composer name, one identifier, one movement, two instrumentation names |
| test/services/mei/importer_test.rb, Mei::ImporterTest | imports sample MEI files into related records | 14 | Importer success | 4/4/0 result, 4 works, 1 composer, 4 success logs; detailed assertions focus on CNW 29 |
| Same | updates existing imported works instead of duplicating them | 2 | Idempotence; importer success | Stable Work.count and 8 success logs after re-import |
| test/integration/api_works_test.rb, ApiWorksTest | index returns work summaries | 4 | API serialization | Success, two rows, first composer, instrumentation key |
| Same | show returns nested catalogue data | 5 | API serialization | Success, title, identifier values, movement titles, nonempty sources |
| Same | index filters by search term | 2 | API filtering | q=Helios returns Helios only |
| Same | index filters by instrumentation and year range | 3 | API filtering | Combined strings/1910-1920 query returns CNW 29 |

Category totals, allowing overlap:

- Model validation: 4.
- Association: 2.
- Importer success: 1 plus 1 idempotence test.
- Importer warning: 0.
- Importer failure: 0.
- API serialization: 2.
- API filtering: 2.
- Web request/interface: 0.
- Negative path: 4, all simple model invalidity.
- Edge case: 0.
- Setup/reproducibility: 0.
- Performance: 0.
- Usability: 0.

Empty generated placeholder classes:

- CatalogueIdentifierTest
- ExternalReferenceTest
- InstrumentationTest
- MovementTest
- PerformanceTest
- SourceReferenceTest
- ApplicationCable::ConnectionTest

There is no ImportLogTest, controller test, system test, performance/load benchmark test, security test, accessibility test, or coverage configuration. No coverage percentage is claimed.

### Shallow or broader-than-evidence assertions

- The instrumentation/year API test does not isolate instrumentation. The 1910-1920 range alone selects CNW 29, and the assertion for 4 horns is unrelated to requested strings.
- Idempotence asserts stable Work.count and cumulative logs only. It does not change a source file, verify an updated value, or inspect child counts/identities.
- The importer success test does not require zero warnings.
- Only CNW 29 receives meaningful field-level checks. Other fixtures mainly contribute to counts.
- Presence checks for source, performance, and external reference are shallow.
- API index/detail assertions cover only part of the emitted schema and do not assert content type/order/complete keys.
- Fixture source_file strings point into test/fixtures/files/, but that directory contains only .keep; the tests verify a string, not source-file existence.
- The unattached Brahms composer fixture does not demonstrate multi-composer import.

### Important implemented behavior without automated tests

- Parser warnings, malformed files, file-level failures, continued processing, rollback, and failure-log creation.
- Empty/missing/nested directories, .xml files, uppercase extensions, and alternate paths.
- Missing composer/title fallbacks, alternate XPath branches, uncertain/ranged/partial dates, invalid movement positions, and de-duplication behavior.
- Changed-value re-imports, child replacement, renamed/deleted files, and concurrent imports.
- Child validations and destroy/nullify behavior.
- Catalogue/genre filters; isolated instrumentation; composer/catalogue q search; wildcard escaping; invalid/inverted years; no results.
- API 404/malformed-parameter behavior, exact JSON contract, and ordering.
- All HTML routes, filters, empty states, latest-log display, navigation, accessibility, and usability.
- Setup, CI, seeds as domain behavior, performance, scalability, deployment, and security.

## 5. Historical evidence, kept separate

Pre-existing log/development.log and log/test.log were not fresh evidence.

- development.log contains 44 application actions recorded as 200: API index 8, API show 2, HTML works index 25, and HTML work show 9.
- Its SQL sequence is consistent with four initial Work creates, eight success logs, and child destroy/recreate on a second pass.
- test.log ratios are consistent with earlier executions of relevant tests, but it contains no authoritative runner summary.
- Historical import logs show empty warning arrays; there is no historical warning/failure-path evidence.
- development.log also contains unrelated /api/v2 request starts not processed by this application; they are excluded.

## 6. Setup, blocked checks, and evidence boundary

Requested safe checks completed: dependency resolution, test database preparation, full suite, first import, repeat import, database counts, routes, web/API smoke checks, clean CI, and cleanup.

- No supporting input was missing.
- No requested safe check remained BLOCKED. Sandboxed network/socket failures were resolved through explicit approvals within the isolated scope.
- The default-shell setup path failed until Ruby 4.0.5 was selected explicitly.
- README's standalone bin/rails db:setup and db:migrate commands were not separately executed. Fresh setup evidence comes from dedicated db:prepare and the bin/setup --skip-server step inside CI, so README-specific setup wording is only partially demonstrated.
- A real listening-server check was not necessary because endpoint behavior was verified in-process; no production server behavior is claimed.
- Authoritative-data validity, Phase 2 robustness, usability, performance, security, accessibility, and deployment evaluation were not attempted. They are evidence gaps, not environmental blockers.

## 7. Fresh verification summary

- Dependencies: installable and executable with explicit Ruby 4.0.5; bundle check passed; disposable bundle install changed one lockfile checksum line.
- Schema preparation: passed in a dedicated PostgreSQL 14.23 database.
- Tests: 12 runs, 54 assertions, 0 failures, 0 errors, 0 skips.
- Import: 4 files, 4 successes, 0 failures, 0 warnings.
- Re-import: works stable at 4; child counts stable but rows replaced; logs increased 4 to 8.
- Routes: all five expected GET routes present.
- Endpoints: every required page/API/filter/no-result check returned 200 with expected limited facts.
- CI: failed because bin/importmap is absent. On a clean database the Rails test and seed steps passed; on the post-import database fixture foreign-key errors also occurred.
- Cleanup: dedicated database removed; no server left running.
