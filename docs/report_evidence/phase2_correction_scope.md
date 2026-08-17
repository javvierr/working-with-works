# Phase 2 authoritative-corpus correction scope

## 1. Executive recommendation

The smallest defensible correction scope is four packages, in this order:

1. **Catalogue identity and complete ingestion:** permit the same identifier value under different identifier types, derive `Work.catalogue_number` from the direct CNW identifier, and accept the bounded `CNW <value>` catalogue-search form.
2. **Direct work attribution and date boundaries:** select the direct work contributor whose role is composer and never treat a nested bibliography or expression date as the work composition date.
3. **Bounded performance-event extraction:** read events from `eventList[@type='performances']` into the existing flat performance model without claiming full responsibility or date semantics.
4. **External-reference boundary:** store only syntactically absolute HTTP(S) targets as `ExternalReference` rows; leave internal catalogue graphs and local assets unmodelled rather than mislabelling them as external links.

These packages address the five lost works, a deterministic composer error across the corpus, one directly confirmed false composition date, corpus-wide omission of an existing intended performance domain, and a material link-category error. They are supported by both official-source observations and current implementation inspection, fit the existing relational design, and remain measurable with the frozen Stage A–D protocol.

The current pass should **not** redesign movement/component, manifestation/item, multilingual-title, responsibility, or instrumentation models. It should also not broaden into general API polish, CI repair, or deployment configuration. Those concerns are real, but either need a scholarly or product mapping decision, require a wider schema redesign, or are less important than authoritative-data correctness.

This is a planning decision, not an implementation result. The committed Stage A–D artifacts remain the frozen baseline. No percentage in this document represents overall catalogue accuracy.

## 2. Evidence basis and decision rules

The review used the frozen evaluation protocol, corpus reconnaissance, sample manifest, Stage A import report, Stage B fidelity matrix, Stage C probe report, Stage D API report, Phase 1 evidence registers, and static inspection of the current importer, models, schema, migrations, routes, views, configuration, and tests. Bounded official-source structures already present in the ignored corpus were used only to confirm source context recorded in the committed evidence. No database query, importer execution, Rails command, API request, test run, network access, or application change was part of this review.

The comparison basis is:

- 446 official Carl Nielsen XML files;
- 441 successful imports and 5 logged, rolled-back failures;
- 441 works, 1,702 catalogue identifiers, 0 movements, 1,651 instrumentations, 0 source references, 0 performances, 2,001 external references, and 446 import logs;
- 83 frozen Stage B rows: 48 detailed-fidelity and 35 boundary/stress rows, with 78 eligible semantic assertions;
- 7 frozen Stage C probes;
- the exact 14-request Stage D matrix.

The issue labels used below mean:

- **confirmed correctness defect:** the source, stored result, and code establish a contradictory value, failed import, or material category error;
- **incomplete but intentional prototype scope:** source meaning is omitted or flattened by the reduced model without a contradictory replacement;
- **usability/API-quality issue:** transport, filtering, validation, error-shape, or ordering behaviour is inconvenient or ambiguous without itself changing the underlying database truth;
- **deployment concern:** the issue affects CI or a production-only subsystem rather than the evaluated local catalogue transformation;
- **insufficiently evidenced:** a correction would require a mapping or product decision that the current evidence does not justify.

Warning volume alone is not treated as a defect. In particular, 60 files genuinely have no performance event, 39 have no `perfRes`, 4 have no manifestation, and 7 have no direct work creation date.

## 3. Evidence-backed issue inventory

### 3.1 Five identifier-value collisions roll back complete works

- **Classification:** confirmed correctness defect.
- **Evidence and finding:** `phase2_baseline_import_results.md` records five failures—`cnw0027.xml`, `cnw0064.xml`, `cnw0070.xml`, `cnw0081.xml`, and `cnw0237.xml`—with no surviving work or child rows. `phase2_focused_probe_results.md` confirms that each repeats one value under two different identifier labels.
- **Root cause:** `Mei::Importer#catalogue_identifiers` deliberately retains unique `(identifier_type, value)` pairs, while `db/schema.rb` enforces uniqueness on `(work_id, value)` only. The second differently typed value violates the index inside the per-file transaction.
- **Affected scope and impact:** 5 of 446 files in this archive release; the complete catalogue record becomes undiscoverable after rollback.
- **Minimal correction and affected areas:** replace the value-only unique index with `(work_id, identifier_type, value)`, require a normalized nonblank type, and align model validation with the database. Likely areas are a new migration, `db/schema.rb`, `CatalogueIdentifier`, the importer only if normalization needs clarification, and importer/model tests. **Migration required: yes.**
- **Tests and post-correction measures:** accept equal values under different types; reject or de-duplicate an exact repeated type/value; retain rollback coverage for a genuinely invalid child. Re-measure Stage A successes/failures/works/identifiers/logs, all five Stage C identifier probes, per-file reconciliation, and orphan counts.
- **Risks:** SQL null semantics or inconsistent type casing could reintroduce duplicates; relaxing the index without matching validation would create another model/database mismatch.
- **Recommendation:** **include now**, highest priority.

### 3.2 Composer selection is wrong; wider responsibilities are unmodelled

- **Classification:** mixed—confirmed correctness defect for composer attribution; incomplete prototype scope for other responsibilities.
- **Evidence and finding:** the corpus profile records one direct Carl Nielsen composer in every file and 829 role-bearing direct names overall. Stage B classifies all four sampled responsibility assertions as incorrect because the stored composer is header editor Niels Bo Foltmann. Some 352 files have more than one direct contributor and role.
- **Root cause:** the official records use immediate `work/contributor/persName[@role='composer']`; `Mei::Importer#extract` first looks for nonexistent `<composer>` structures and ultimately accepts the first document-level `respStmt/persName`, which is header editorial metadata. `Work` can store only one composer and has no contributor-role association.
- **Affected scope and impact:** composer misattribution is structurally predicted for all 446 records. The canonical database contains one composer row, and the four sampled stored works identify that composer as Niels Bo Foltmann; this is not a row-by-row manual observation of all 441 works. Author, dedicatee, translator, arranger, and other roles remain absent from search, API, and UI.
- **Minimal correction and affected areas:** choose the direct work contributor with role `composer`, retain explicit composer-element compatibility for the prototype fixtures, and use `Unknown composer` plus a warning when neither form exists; do not use an unrelated header editor as composer. Likely files are `app/services/mei/importer.rb` and importer tests. **Migration required: no** for composer correction; a future full responsibility model would require one.
- **Tests and post-correction measures:** direct role-bearing composer with misleading header editor; extra author/translator/dedicatee must not replace composer; missing-composer fallback; existing fixture regression. Compare the corpus composer inventory and the same four Stage B responsibility IDs. With the reduced schema, the simple CNW 417 assertion may become preserved while compound assertions should normally improve from incorrect to omitted because non-composer roles remain absent.
- **Risks:** a broad descendant selector could select performance participants or expression contributors; fixing composer alone must not be reported as preservation of all responsibilities.
- **Recommendation:** **include the composer correction now; defer and document the full responsibility model.**

### 3.3 A nested bibliography date is stored as a composition date

- **Classification:** confirmed correctness defect.
- **Evidence and finding:** Stage C confirms that CNW 67 has no direct work creation date, but the baseline stores the first descendant bibliography-entry date, `1913-04-29`, and year 1913 as composition data. Seven files lack a direct work date; only CNW 67 is the directly confirmed descendant false positive.
- **Root cause:** `Mei::Importer#extract` prioritizes `.//creation//date`; `Mei::Importer#first_node` uses `at_xpath`, so structural context is discarded.
- **Affected scope and impact:** one observed incorrect record and a structurally unsafe selector wherever nested creation data occurs. The false year affects display and year filtering.
- **Minimal correction and affected areas:** select only the direct work creation date, with narrowly justified direct composition-labelled alternatives. If no direct date exists, store null date/year and retain a missing-date warning. Likely files are the importer and importer tests. **Migration required: no.**
- **Tests and post-correction measures:** direct work date must win over nested bibliography/expression dates; nested-only dates must remain null; exact and ranged direct dates must retain baseline behaviour. Repeat the CNW 67 Stage C probe, reclassify the existing Stage B date assertions, compare missing-date warnings, and rerun the frozen year requests against the corrected database.
- **Risks:** null counts will increase, but an explicit absence is preferable to a false scholarly assertion. Direct ranged/uncertain text must not be accidentally discarded.
- **Recommendation:** **include now.**

### 3.4 No official component structure becomes a movement

- **Classification:** incomplete prototype scope with an insufficiently resolved target mapping.
- **Evidence and finding:** Stage A stores zero movements and reports `no_movements` for all files. The archive contains no `<mdiv>`, `<movement>`, or `<section>` elements, but it contains 602 top-level expressions and 593 direct component expressions in 70 component-bearing files. All nine Stage B component assertions are omitted.
- **Root cause:** `Mei::Importer#movements` selects only `contents/mdiv` or `<movement>`. The flat `Movement` model has a unique position but no hierarchy or component type.
- **Affected scope and impact:** component/version/act/scene/movement-like structure is absent from database, API, and UI. The warning on files without a defensible movement mapping is not itself proof that a movement should exist.
- **Minimal correction and affected areas:** no immediate `Movement` correction is defensible. First decide which expression/component structures represent movements, versions, arrangements, acts, scenes, or another entity. A faithful solution may require a hierarchy-aware model, migration, importer/API/UI changes, and tests for nested order, multilingual titles, tempo, meter, and ambiguous `n` values. **Migration required: likely, after the mapping decision.**
- **Tests and post-correction measures:** after approval, hierarchy/order cases, repeated or nonnumeric labels, nested component lists, and no-component records; reclassify all nine frozen component IDs and compare stored structural totals without changing denominators.
- **Risks:** treating every expression as a movement would manufacture unsupported semantics and can collide on flat positions.
- **Recommendation:** **investigate further before deciding; defer from this correction pass.**

### 3.5 Manifestation and held-item evidence is absent from source references

- **Classification:** confirmed coverage omission within an intentionally reduced model; target-model adequacy is insufficiently resolved.
- **Evidence and finding:** Stage A stores zero source references and warns on all files. The source has 2,148 manifestations in 442 files and 1,370 held items in 392 files, but no structures matching the importer selectors. Stage B has 12 source-description omissions and one correctly preserved absence.
- **Root cause:** `Mei::Importer#source_references` looks for `sourceDesc/source` and work-descendant `sourceList/source`; the official data uses sibling manifestation/item hierarchies. The flat `SourceReference` fields cannot distinguish manifestation identity, held items, repository hierarchy, hand data, and multiple shelf locations.
- **Affected scope and impact:** 442 records lose manifestation descriptions and 392 lose held-item context; users cannot inspect the authoritative manuscript/source hierarchy through the prototype.
- **Minimal correction and affected areas:** first decide whether a stored row denotes a manifestation, an item, or a lossy combined summary. A faithful solution likely needs separate manifestation/item entities or an explicit hierarchy, affecting importer, models, migration/schema, API, views, and tests. **Migration required: likely.**
- **Tests and post-correction measures:** manifestations with zero/one/multiple items, repository and shelf/location identifiers, hand information, missing repositories, and stable hierarchy/order. Reclassify all 13 frozen source assertions and compare manifestation/item coverage rather than only row totals.
- **Risks:** a simple descendant selector could ingest unrelated bibliography data; one flat row can appear complete while silently losing hierarchy.
- **Recommendation:** **investigate further before deciding; defer unless a bounded mapping contract is separately approved.**

### 3.6 Performance events are entirely missed

- **Classification:** confirmed correctness/coverage defect within an already intended domain.
- **Evidence and finding:** Stage A stores zero performances and warns on all 446 files. The official source has 4,840 untyped events beneath 477 `eventList type="performances"` containers in 386 files; 60 files genuinely have none. Stage B has five omitted event assertions and two preserved absences in the dedicated performance domain; the performance half of compound assertion `417-12` is also a preserved absence.
- **Root cause:** `Mei::Importer#performances` requires the type on each event or a `<performance>` element, but this corpus places the type on the parent event list. Existing descendant field selectors also risk pulling dates or people from nested review bibliography.
- **Affected scope and impact:** performance history is missing for 386 files, including the representative 38, 92, 211, and 602-event records.
- **Minimal correction and affected areas:** select direct event children of a performance-typed event list and map only bounded direct event date, venue/place, people/corporations, and description into the existing flat table. Explicitly account for empty or unmappable event nodes rather than inventing values. Likely files are the importer and importer tests. **Migration required: no** for this bounded mapping.
- **Tests and post-correction measures:** parent-list type inheritance; direct date versus nested review date; venue/place; person/corporation roles in a stable flattened representation; blank event; partial date; genuine no-event record. Reconcile all 4,840 source events as stored or explicitly skipped/warned, compare Stage A performance totals/warnings, and reclassify the seven dedicated Stage B performance assertions plus the performance half of `417-12`.
- **Risks:** the flat model still loses structured participant roles and non-exact date semantics; large event volumes can expose duplicate/order behaviour. Import completion must not be equated with complete event meaning.
- **Recommendation:** **include now with the stated bounded flattening.**

### 3.7 Internal catalogue relations are presented as external links

- **Classification:** confirmed correctness defect through material category mislabelling.
- **Evidence and finding:** the current selector sees 2,069 relation/ref/ptr targets, of which only 459 are HTTP(S); at least 1,610 are internal, query-style, or root-relative. Stage B relation-target results contain 10 incorrect, 3 omitted, and 2 preserved assertions. The HTML detail view renders every stored row as a link under “External references.”
- **Root cause:** `Mei::Importer#external_references` stores every targeted relation, ref, or ptr in `ExternalReference`, whose schema has only label and URL and no relation category.
- **Affected scope and impact:** internal collection graphs, catalogue navigation targets, and local assets are materially mislabelled and exposed as though they were external resources.
- **Minimal correction and affected areas:** persist only syntactically absolute HTTP(S) targets in `ExternalReference`; keep existing labels and de-duplication. Leave internal relations, graphics, root-relative assets, target validation, and URL dereferencing out of scope. Likely files are the importer and importer tests; API/UI need no structural change because they already expose this association. **Migration required: no.**
- **Tests and post-correction measures:** include absolute HTTP and HTTPS targets even when their URL ends in `.xml` or contains a query; exclude relative `.xml` paths, relative/query-style `document.xq` targets, fragment-only targets, root-relative paths, and non-HTTP schemes; verify per-work duplicate handling. Compare Stage A external-reference totals/warnings, all 15 Stage B relation assertions, and the relation half of compound assertion `417-12`. Verify that every stored URL is HTTP(S), but do not test or claim authority or availability.
- **Risks:** useful institutional/local targets disappear until an internal-relation/resource model exists. The change improves classification by converting contradictory rows into documented omissions; it does not preserve the graph.
- **Recommendation:** **include now.**

### 3.8 Display-title precedence and alternate-title loss

- **Classification:** mixed—one confirmed selected-title mismatch and a broader intentional single-title limitation.
- **Evidence and finding:** the corpus has 1,238 direct titles; 445 files have more than one, 101 have a uniform title, and 91 have alternative titles. Stage B finds one incorrect title assertion for CNW 277, where the uniform title displaces the frozen first untyped title, and five omissions for language/type/alternate-title meaning.
- **Root cause:** the importer prefers a direct uniform title before the first direct title; `Work` has only one title column and no language/type metadata.
- **Affected scope and impact:** up to 101 uniform-bearing records are exposed to selection changes; 445 records cannot preserve all direct titles. Search and result ordering depend on the chosen display title.
- **Minimal correction and affected areas:** a display-only correction could prefer the first immediate untyped title with explicit fallbacks, affecting the importer and tests without a migration. Full title preservation would require title entities, migration/schema, API/UI/search changes, and multilingual/type tests.
- **Tests and post-correction measures:** first untyped versus uniform/alternative/subordinate values, records lacking an untyped title, language order, nested title exclusion, and search/order changes; reclassify the same six title assertions.
- **Risks:** the archive does not independently declare the project’s preferred display title. Changing 101 records merely to match one oracle case could overfit the evaluation. A project display policy must not be called an authoritative preference.
- **Recommendation:** **investigate the display-title policy before deciding; defer the full alternate/language model.**

### 3.9 Instrumentation is a partial flattened summary

- **Classification:** incomplete but intentional prototype scope.
- **Evidence and finding:** the corpus has 1,994 `perfRes` elements in 407 files, including 1,984 codes, 1,948 counts, and 1,555 solo flags. Stage A stores 1,651 instrumentation rows after five complete-file failures. Stage B instrumentation results are 2 preserved and 7 omitted, with 0 incorrect after the reviewed classification audit.
- **Root cause:** the importer folds count into a name, stores a shallow section string, and de-duplicates by lowercase name; the schema has no code, count, solo flag, source order, grouping, or expression context, and its unique index also collapses repeated names.
- **Affected scope and impact:** labels are useful but non-exhaustive; repeated resources and material attributes disappear, especially in dense records.
- **Minimal correction and affected areas:** a faithful change needs a mapping design plus new fields or a performance-medium/resource hierarchy, a revised uniqueness rule, migration/schema, importer, API/UI/filter changes, and tests. **Migration required: yes for meaningful expansion.**
- **Tests and post-correction measures:** same-name resources in different contexts, groups, counts/codes/solo flags, source order, and filtering; reclassify all nine instrumentation assertions and compare sample/corpus rows after resolving the five failed imports.
- **Risks:** row-count increases are not automatically fidelity gains; a new schema can still flatten hierarchy or change API meaning.
- **Recommendation:** **defer and document as a limitation; investigate further before schema design.**

### 3.10 `Work.catalogue_number` uses the first identifier rather than CNW

- **Classification:** confirmed correctness defect.
- **Evidence and finding:** every file has a direct CNW identifier, but Opus is first in 70 files. Stage B records `Work.catalogue_number=9` for CNW 63 and `41` for CNW 18 while their typed CNW values are 63 and 18.
- **Root cause:** `Mei::Importer#extract` assigns `identifiers.first[:value]` to the denormalized field.
- **Affected scope and impact:** at least the 70 Opus-first records can display and filter by the wrong catalogue family; all five failed records also need the identifier constraint corrected before their value exists.
- **Minimal correction and affected areas:** select the direct typed CNW identifier; fall back to the first identifier only for a source without CNW, preserving fixture compatibility. Do not discard or reorder typed child identifiers. Likely files are the importer and importer tests. **Migration required: no beyond issue 3.1.**
- **Tests and post-correction measures:** Opus-first/CNW-second, CNW-only, and no-CNW fallback cases. Compare all 446 denormalized values with direct CNW identifiers, the eight Stage B common measurements, and Stage D catalogue searches.
- **Risks:** bare source values and formatted display labels differ; storage formatting and search normalization must be documented separately.
- **Recommendation:** **include now, in the catalogue-identity package.**

### 3.11 `CNW 417` does not match the catalogue filter

- **Classification:** usability/API-quality issue with a catalogue-identity dependency.
- **Evidence and finding:** Stage D returned CNW 417 for bare `417` and zero rows for `CNW 417`; both results matched the current database query.
- **Root cause:** `Work.with_catalogue_number` performs a literal substring search over the one denormalized field and does not interpret a typed identifier label.
- **Affected scope and impact:** only CNW 417 was executed in Stage D, but the mechanism applies to prefixed CNW input generally. The UI itself suggests a `CNW 29` form.
- **Minimal correction and affected areas:** after CNW identity is reliable, accept a bounded CNW prefix by querying the typed identifier association or safely normalizing that one label. Likely files are `app/models/work.rb` and model/API tests. **Migration required: no additional migration.**
- **Tests and post-correction measures:** bare and prefixed CNW forms return the same unique record; mixed case; whitespace; no duplicate work rows; no accidental match across other identifier types. Repeat Stage D D04 and D05 and label D05’s changed result as intentional.
- **Risks:** blindly stripping a prefix from an unreliable first-identifier field would preserve the underlying defect; arbitrary CNU/CNS/FS search is outside this bounded package.
- **Recommendation:** **include now only as part of the catalogue-identity package.**

### 3.12 Invalid and inverted year parameters are silently accepted

- **Classification:** confirmed usability/API-quality issue.
- **Evidence and finding:** Stage D showed nonnumeric `year_from` silently behaving as 0 and returning 435 rows, nonnumeric `year_to` returning none, and inverted `1900..1899` returning an empty HTTP 200 response without reporting inversion.
- **Root cause:** `Work.from_year` and `to_year` call `to_i`; both controllers pass permitted strings without syntax, range, or pair validation.
- **Affected scope and impact:** malformed input can produce plausible but misleading results in API and HTML filters.
- **Minimal correction and affected areas:** parse integer input once and adopt an explicit invalid/inverted contract for JSON and HTML. Likely areas are `Work` plus both controllers or a small filter object, with model, API, and HTML-controller tests. **Migration required: no.**
- **Tests and post-correction measures:** nonnumeric, decimal, blank, extreme, inclusive, and inverted cases; repeat D07–D13 and compare status/content type/shape and result sets.
- **Risks:** 400 versus 422 and the HTML feedback path are product-contract decisions; changing them now would widen the correction pass.
- **Recommendation:** **defer and document; approve a client-error contract first.**

### 3.13 Instrumentation and tied-title ordering are not fully deterministic

- **Classification:** bounded usability/API-quality issue; the exact D03 child-order mechanism is not fully resolved.
- **Evidence and finding:** Stage D D03 matched IDs, counts, scalar values, and instrumentation multiset, but CNW 417’s two instrumentation names were reversed relative to the independently ordered database expectation. Seven tied-title groups existed; `order(:title)` has no tie-breaker.
- **Root cause:** index serialization relies on the loaded association order at response time, while controller ordering specifies title only. The code confirms the missing title tie-breaker; preserved evidence does not conclusively isolate why one preloaded instrumentation array differed.
- **Affected scope and impact:** one observed child-array discrepancy and run-specific order within equal titles; no value-set loss was found.
- **Minimal correction and affected areas:** after defining the response contract, sort instrumentation explicitly at serialization and order works by title plus a stable secondary key. Likely files are the two works controllers and integration/controller tests. **Migration required: no.**
- **Tests and post-correction measures:** deliberately unsorted child rows and tied titles; repeat D01 and D03. State clearly that alphabetical order is not source order or scholarly order.
- **Risks:** a cosmetic sort can conceal the absence of source-position data; changing tied order affects exact ID-sequence comparison.
- **Recommendation:** **defer; investigate D03’s precise loading path before implementation.**

### 3.14 Missing API detail is HTML rather than JSON

- **Classification:** confirmed API-contract quality issue.
- **Evidence and finding:** Stage D D14 returned HTTP 404 with `text/html`; the successful API requests returned JSON.
- **Root cause:** `Api::WorksController#show` uses `find`, with no API-scoped `RecordNotFound` handler that renders a JSON error object.
- **Affected scope and impact:** API clients receive a content type and shape inconsistent with the successful API contract.
- **Minimal correction and affected areas:** add a narrowly scoped JSON 404 handler in the API controller or API base controller and an integration test. **Migration required: no.**
- **Tests and post-correction measures:** confirmed absent ID, JSON content type, stable bounded error keys, and no raw exception context; repeat D14.
- **Risks:** the exact error schema is not yet frozen. This does not affect importer correctness or the planned HTML usability exercise.
- **Recommendation:** **defer and document.**

### 3.15 CI, Redis/Action Cable, and Solid Queue are not self-consistent

- **Classification:** confirmed reproducibility concern plus deployment concerns, not an authoritative-import defect.
- **Evidence and finding:** Phase 1 evidence records that `bin/ci` cannot complete because it invokes absent `bin/importmap`. Production Cable selects Redis while Redis is not installed, and Puma conditionally names Solid Queue while the corresponding dependency/configuration is absent. No production deployment was evaluated.
- **Root cause:** CI retains an audit step for an asset stack the project does not declare; production template configuration refers to optional subsystems that are not installed.
- **Affected scope and impact:** the repository cannot claim a green configured CI workflow or self-contained production configuration. These paths did not affect the local Stage A–D evidence.
- **Minimal correction and affected areas:** make separate architecture decisions: remove the irrelevant CI step or deliberately adopt Importmap; install/configure Redis or select an intended alternative; remove the unused Solid Queue hook or fully adopt it. Likely files are `config/ci.rb`, possibly `bin/`, `Gemfile*`, `config/cable.yml`, and `config/puma.rb`. **Migration required:** not for removal/adapter clarification; possible if Solid Queue is deliberately adopted.
- **Tests and post-correction measures:** later clean `bin/ci` run under a declared data-state precondition and a separately scoped production-subsystem boot matrix.
- **Risks:** dependency/configuration choices require a deployment target and can introduce unrelated code, services, or migrations that confound the fidelity comparison.
- **Recommendation:** **defer to a separate repository-hardening/deployment decision; retain the limitation.**

## 4. Recommended correction packages

### Package 1 — catalogue identity and complete ingestion

**Problem addressed:** issues 3.1, 3.10, and the bounded CNW-prefix behaviour in 3.11.

**Included behaviour:** typed identifier uniqueness; exact-duplicate protection; direct CNW selection for the denormalized catalogue number; bare and `CNW`-prefixed lookup for the CNW family.

**Excluded behaviour:** arbitrary secondary-identifier search, identifier entity resolution, filename-derived identity, multi-work files, and display-policy changes for titles.

**Proposed components:** new catalogue-identifier index migration, `db/schema.rb`, `CatalogueIdentifier`, `Mei::Importer`, `Work` filtering, importer/model/API tests.

**Acceptance criteria:**

- the fresh corrected run reports 446 successes, 0 failures, 446 stored works, and 446 `ImportLog` rows, with the five formerly failed files committed rather than rolled back;
- different types may retain the same value, while an exact type/value duplicate does not survive twice for one work;
- each official work’s `Work.catalogue_number` equals its direct CNW value under one documented bare-value representation;
- bare `417` and prefixed `CNW 417` resolve to the same single CNW 417 work without duplicate rows;
- typed child identifiers retain their type and value.

**Tests:** composite uniqueness at model/database boundaries; five duplicate-pattern cases; Opus-first record; CNW-only and no-CNW fallback; prefix/mixed-case/whitespace lookup; rollback regression.

**Baseline measures:** 441 successes, 5 failures, 441 works, 1,702 identifiers; five confirmed Stage C failures; D04 count 1 and D05 count 0.

**Post-correction comparison:** exact Stage A completion/log/work/identifier counts; all five Stage C probes; the eight Stage B common identity/catalogue measurements; D04 and D05 result sets. The corrected identifier total remains an observed result rather than a value forced in advance. A changed D05 or Stage C failure outcome is an intentional correction, not silent replacement of baseline evidence.

**Dependencies:** first package; later corpus totals depend on importing all five previously absent works.

### Package 2 — direct work attribution and date boundaries

**Problem addressed:** the composer part of issue 3.2 and issue 3.3.

**Included behaviour:** direct role-bearing composer selection; explicit fixture-compatible composer fallback; direct work creation-date selection; truthful missing-date warning.

**Excluded behaviour:** author/dedicatee/translator/arranger storage; field-level provenance; structured date bounds/uncertainty columns; title selection changes.

**Proposed components:** `Mei::Importer` and importer tests; no migration.

**Acceptance criteria:**

- all official imported works resolve their direct composer as Carl Nielsen rather than the header editor;
- additional work contributors cannot displace the composer;
- CNW 67 stores no composition date/year from bibliography or expression context and records the missing-date condition;
- existing direct exact and ranged work dates retain their display text and derived year behaviour.

**Tests:** misleading header editor; direct composer plus other roles; missing composer; direct versus nested creation dates; exact and ranged direct dates; fixture regression.

**Baseline measures:** one stored composer name, Niels Bo Foltmann, across the canonical database; four Stage B responsibility assertions incorrect; CNW 67 stores `1913-04-29`/1913 and confirms the descendant-date prediction; six missing-date warnings.

**Post-correction comparison:** composer inventory; the same four responsibility IDs; all existing Stage B date IDs; CNW 67 Stage C observation; missing-date warning count; Stage D title/search/year requests against the corrected state.

**Dependencies:** may be implemented independently, but corpus-wide acceptance should be measured after Package 1.

### Package 3 — bounded performance-event extraction

**Problem addressed:** issue 3.6.

**Included behaviour:** direct events whose parent list declares performance semantics; bounded direct event date, venue/place, participants/corporations, and description; explicit accounting for unmappable events.

**Excluded behaviour:** complete person/entity modeling, role-preserving participant tables, uncertain performance-date modeling, review bibliography, general event ontology, and a performance benchmark.

**Proposed components:** `Mei::Importer` and importer tests; existing `Performance` model/API/UI shape retained; no migration.

**Acceptance criteria:**

- the 4,840 official event nodes are reconciled as stored or explicitly skipped with a stable reason; they are never silently lost through the old type-location mismatch;
- representative CNW 63, CNW 18, CNW 17, and CNW 2 events retain bounded direct values without nested review contamination;
- the 60 true no-event files remain empty without being misrepresented as parser failures;
- API detail counts equal the corrected database state, including the highest-volume sampled record, without treating contextual completion time as a general performance result.

**Tests:** typed parent/untyped child; direct versus nested dates/people; venue and place; corporate participant; blank event; partial date; no-event record; high-count replacement/idempotence regression.

**Baseline measures:** 0 stored performances; `no_performance_information` on 446 files; five Stage B omissions and two preserved absences.

**Post-correction comparison:** Stage A performance total and warning categories; all seven dedicated Stage B performance assertions plus the performance half of `417-12`; representative values/counts; relevant API detail collections. Timing remains contextual only.

**Dependencies:** Package 1 is required before interpreting full-corpus row and file coverage.

### Package 4 — strict external-reference boundary

**Problem addressed:** issue 3.7.

**Included behaviour:** absolute HTTP(S) relation/ref/ptr targets only, with existing label and per-work URL de-duplication.

**Excluded behaviour:** internal work graphs, collection/part relations, local/root-relative assets, graphics, authority validation, URL availability checks, and URL dereferencing.

**Proposed components:** `Mei::Importer` and importer tests; no migration.

**Acceptance criteria:**

- every stored `ExternalReference.url` is syntactically HTTP(S);
- no relative `.xml`, relative/query-style, fragment-only, or root-relative target is stored or rendered as an external link; an otherwise valid absolute HTTP(S) URL is not excluded merely because it ends in `.xml` or contains a query;
- known sample absolute targets remain available, while internal-only cases have zero external-reference rows;
- the report explicitly describes omitted internal graph data rather than claiming it was preserved.

**Tests:** absolute HTTP/HTTPS inclusion including query-bearing and `.xml` URLs; relative `.xml`, relative/query-style, root-relative, fragment-only, and non-HTTP exclusion; duplicate URL handling; mixed internal/absolute record; UI/API association regression.

**Baseline measures:** 2,001 stored rows; 2,069 selected source targets, only 459 syntactically HTTP(S); Stage B relation domain of 10 incorrect, 3 omitted, and 2 preserved assertions.

**Post-correction comparison:** Stage A external-reference totals and warnings; all 15 dedicated relation assertions plus the relation half of `417-12`; per-sample absolute/internal categories; API/detail equality with corrected database state. No link-quality rate is calculated.

**Dependencies:** Package 1 is required for complete-corpus totals; otherwise independent.

## 5. Deferred limitations and report-safe wording

The later project report can use the following wording unless later evidence supersedes it:

- **Components/movements:** “The corrected prototype does not equate MEI expressions or component lists with musical movements. Component hierarchy, versions, acts, scenes, and related structures remain unmodelled pending a defensible mapping decision.”
- **Sources/manuscripts:** “Manifestation and held-item hierarchies remain outside the flat source-reference model; file- and record-level traceability does not amount to manuscript/source fidelity.”
- **Responsibilities:** “The corrected importer identifies the direct work composer, but other contributor and performance roles are not represented as structured responsibility records.”
- **Titles:** “The prototype stores one display title and does not preserve the complete multilingual, alternative, uniform, subordinate, or text-source title structure. A preferred-display policy remains to be justified.”
- **Instrumentation:** “Stored instrumentation is a partial flattened summary of resource names and counts; codes, solo flags, grouping, repetition, source order, and expression context remain incomplete.”
- **Internal relations:** “Only absolute HTTP(S) targets are presented as external references. Internal collection/work graphs and local assets are intentionally omitted rather than exposed as external links.”
- **API contract:** “Invalid and inverted year handling, deterministic tie ordering, and a JSON missing-record error contract remain unresolved API-quality limitations.”
- **Deployment and CI:** “The application remains a local prototype: the configured CI workflow, production Action Cable adapter, and optional Solid Queue hook require a separate architecture and reproducibility pass.”
- **Generalization:** “The corrections are evaluated against this 446-file institutional release and the frozen purposive sample; they do not establish general MEI compatibility, complete scholarly validation, usability, accessibility, performance, security, or deployment readiness.”

No candidate is rejected as wholly unsupported. The movement, source, title, and instrumentation changes are withheld because the evidence supports the existence of a gap but not yet a sufficiently precise target mapping.

## 6. Expected implementation files and tests

| Area | Expected implementation files | Expected tests | Migration |
|---|---|---|---|
| Catalogue identity | `app/services/mei/importer.rb`; `app/models/catalogue_identifier.rb`; `app/models/work.rb`; a new catalogue-identifier migration; `db/schema.rb` | `test/services/mei/importer_test.rb`; `test/models/catalogue_identifier_test.rb`; `test/models/work_test.rb`; `test/integration/api_works_test.rb` | yes |
| Direct composer/date | `app/services/mei/importer.rb` | importer selector, fallback, nested-date, and regression tests | no |
| Performances | `app/services/mei/importer.rb` | parent-list type, direct-field, empty/partial event, nested-review exclusion, count/re-import tests | no |
| External reference boundary | `app/services/mei/importer.rb` | scheme/category, mixed-target, de-duplication, API/UI association regression tests | no |

No existing official XML or purpose-built fixture should be edited to force a result. Small authoritative-shaped test inputs may be created specifically for isolated tests, while the unchanged official corpus remains the post-correction evaluation source. Application controllers, views, dependencies, production configuration, and deployment files are outside the approved implementation set unless a later review changes scope.

## 7. Post-correction evaluation plan

1. Preserve the application baseline, protocol, Stage A–D result commits, canonical database, and ignored raw evidence unchanged.
2. Freeze the approved package scope and tests, implement only those packages, and commit the implementation separately from every baseline/evidence commit. Record the resulting correction commit SHA.
3. Run the targeted tests and full direct regression suite under the declared environment. Do not describe CI as green while the separately deferred CI workflow remains unresolved.
4. Prepare a fresh disposable database; do not reuse or modify the canonical baseline database.
5. Re-run the corrected importer once over the same verified 446 XML files and capture the same Stage A measures: technical outcomes, warning/failure categories, nine table totals, per-file reconciliation, orphan checks, and contextual elapsed time.
6. Re-evaluate the same eight primary records from `phase2_sample_manifest.csv`. Preserve all 83 Stage B assertion IDs, 48/35 tier split, 78 eligible denominator, source locators, expected values, classification vocabulary, and row order. Reclassify every row; do not add favorable assertions or remove unchanged limitations.
7. Repeat all seven Stage C probes with the original predictions still visible. Record corrected observations separately. Expected intentional changes—such as successful duplicate-value imports or rejection of the nested bibliography date—must be described as changes from baseline, not as replacement baseline predictions.
8. Repeat the exact 14 Stage D request IDs, inputs, and order against the corrected database, resolving record IDs anew. Rebuild independent database expectations. Interpret D05’s prefixed-CNW change explicitly; do not assume that unrelated D11–D14 behaviour was corrected.
9. Compare baseline and corrected states by technical completion, warnings/failures, nine table totals, per-domain Stage B classifications and fixed denominators, seven probe outcomes, and 14 API transport/shape/database-reconciliation results. Report environmental differences; do not calculate an unjustified overall accuracy percentage.
10. Create `docs/report_evidence/phase2_post_correction_comparison.md`, preserve machine-readable supporting evidence in an ignored location, review the document, and commit it only after approval.
11. Prepare a separate stable demonstration database only after corrected import reconciliation and API comparison are complete.

The three-participant formative usability exercise must occur only after the approved corrections are implemented, regression tests pass, the post-correction corpus import and API comparison is complete, and the stable demonstration database is prepared. This review neither designs nor conducts that exercise.

## 8. Risks, unresolved decisions, stopping conditions, and implementation order

### Genuinely unresolved decisions

- What project display-title rule is defensible when direct untyped, uniform, alternative, subordinate, and multilingual titles coexist?
- Which expression/component structures, if any, are movements rather than versions, arrangements, acts, scenes, or another hierarchy?
- Should source storage represent manifestations, held items, or both, and what hierarchy/provenance is required?
- What future schema should preserve non-composer responsibilities and performance-resource context without overclaiming scholarly completeness?
- What client-error contract should invalid/inverted filters and missing API records use?
- Are Redis/Action Cable and Solid Queue intended production features or unused template configuration?

### Stopping conditions

Stop implementation or evaluation and request review if:

- the identifier migration cannot preserve exact type/value uniqueness without data ambiguity;
- a proposed selector needs descendant searches that can mix work data with bibliography, revision, manifestation, or event subtrees;
- performance mapping cannot distinguish direct event content from nested review metadata;
- any of the eight corrected sample detail responses, especially the 602-event CNW 2 record, cannot complete and reconcile without truncation or an unplanned API/UI redesign; timing remains contextual rather than a performance benchmark;
- an external-reference rule would retain non-HTTP graph/local targets or discard syntactically absolute source HTTP(S) targets without an accountable reason;
- a package requires the deferred movement, source, title, responsibility, instrumentation, deployment, or API-contract redesign;
- any frozen assertion ID, source expectation, denominator, request matrix, baseline commit, or preserved evidence would need to be rewritten;
- regression tests fail, the fresh import aborts, per-file reconciliation is incomplete, or post-processing evidence cannot be preserved without rerunning a no-retry canonical attempt.

### Proposed implementation order

1. Catalogue identifier migration, model invariant, CNW selection, and bounded prefix search.
2. Direct composer and composition-date selectors.
3. Bounded performance-event extraction.
4. HTTP(S)-only external-reference extraction.
5. Targeted and full regression testing.
6. One fresh post-correction corpus import, then the unchanged Stage B, Stage C, and Stage D comparison sequence.
7. Stable demonstration database preparation, followed only then by the separately approved formative usability exercise.
