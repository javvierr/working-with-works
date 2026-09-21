# F0 report notes

19 September 2026. These are evidence-linked inputs for a later report revision, not final report results. No new participant study, literature search, interface comparison, full-corpus import, migration or implementation was performed in F0.

## Framing and feedback continuity

The supplied template identifies **CM3010 Databases and Advanced Data Techniques, section 2.1, Project Idea 1: Working with works — a new approach to music cataloguing**. It calls for a catalogue-exploration portal and web API, permits relational transformation, and expects engagement with selected model complexity. The approved September plan retains that direction. It does not create a workflow-management or recommendation-engine requirement. The draft feedback's ambiguity remains an open clarification/framing issue (FB02), not a reason to change the product.

Preserve the feedback's acknowledged strengths: required report parts, supported visuals/tables, stated goal/question/objectives/template, discussed data/conversions, justified architecture, testing, and formatted citations. The preliminary feedback also describes the literature review as comprehensive. Requested improvements concern sharper need/gap justification, formulation, accurate diagrams, deeper explanation and broader evaluation. These are not evidence that every general class criticism applies to this project.

Authority: supplied `context/template_scope_excerpt.txt`, `context/draft report project feedback.txt`, `context/preliminary report feedback.txt`, and `Feedback_to_Evidence_Register.md`; the F0 completion report resolves the actual local kit path. No tutor correspondence was requested or invented.

## Verified current observations for later use

| Report issue / proposed objective | Fresh F0 observation | Evidence and limit |
|---|---|---|
| Accountable transformation, O2 | Import identity is `source_file` path, with XML ID stored separately; first-work/root fallback and namespace removal do not validate the declared supported document shape. Empty input records a warning but zero failures. | `audit/static_audit.md`; importer lines 18–33, 47, 77–90, 134, 407–410; current schema unique path index. Effects on relocation and malformed/multi-work input are static predictions, not executed results. |
| Last committed data versus latest attempt, O2 | Success logging occurs inside the per-file transaction and has a work association; failure logging occurs outside and omits it. The detail page reads only associated logs. | Importer lines 41–74; detail view line 103. Predicted stale-success visibility after failed re-import requires an isolated regression in a later package. |
| Selected semantics, O3 | Current title is one scalar with uniform-before-first priority; classification can select arbitrary descendant documentary genre; current source mapper targets legacy source elements rather than manifestation/item structures. | `audit/static_audit.md`; importer lines 97–122, 236–251. `F0_source_model_proposal.md` and its source observations supply independently inspected examples/locators. No F0 source-selector diagnostic is a Rails import. |
| Predictable access, O4 | API index maps all filtered works with title-only order; no pagination or secondary order key is declared. Years use integer coercion. Current prefixed-CNW filtering already has a typed-identifier branch. | `app/controllers/api/works_controller.rb:3–8`; `app/models/work.rb:26–46,62–76`. Preserve distinction from the older baseline API findings. |
| Provenance and honest absence, O3/O4 | The UI prints a local source path; source rows have no item/expression identity and empty sources render as an empty list. | `app/views/works/show.html.erb:20–25,61–76`; `db/schema.rb:97–107`. This is current code evidence, not a user response or verified authoritative-source link. |
| Reproduction, O6 | Setup may install, prepares/resets a database and clears tmp/logs; CI invokes setup, an absent importmap executable and seed replant. Test hooks delete/import data and require an isolated target. | `audit/static_audit.md`; `bin/setup`, `config/ci.rb`, `test/test_helper.rb`, importer/integration tests. No repair occurred in F0. |

The source-model proposal is a **proposed** implementation scope. Its minimal design, smaller fallback, ownership rules and estimate must not be described as implemented features. Preserve XML document membership separately from a source's association to a work/expression/component. A one-work file does not prove that each descendant manifestation describes the entire work.

Fresh independent source profiling (`source/source_profile.json`) identifies 446 XML inputs, 26,925,115 bytes, all declaring MEI 4.0.1 with one work per file; this is not a schema-conformance result. It counts 2,148 manifestations and 1,370 items, with populated/placeholder cases distinguished under its disclosed payload rule. The current legacy source selectors find zero candidate nodes. The exact current genre-selector reproduction selects documentary terms outside direct work classification in 310 files; that is a selector result, not 310 newly imported rows, and it does not prove the other 136 correct. CNW 417 chooses bibliography `manuscript` instead of its work terms; CNW 63 chooses bibliography `letter` instead of its work terms. Selected examples, owners, hashes and namespace-aware locators are in `source/selected_examples.md` / `source/source_examples.json`.

The main F0 execution records verify assessed HEAD `b0142488fd5609e86d93c84978134a7d849d1882`, installed Ruby 4.0.5/Bundler 4.0.15 and available dependencies using a process-local gem configuration. Fresh checks also passed 64 Ruby syntax checks, framework-version loading, a test-environment primary configuration check for the intended disposable target, and Zeitwerk loading. These do not establish database connectivity or replace the Rails test suite. Database prerequisites were blocked: no PostgreSQL socket at the checked local socket endpoint, and the checked localhost TCP connection was denied by the execution sandbox. Consequently the Rails suite, three-record import and API request/comparator experiment have **no fresh execution result**; see `F0_checks.json` for exact commands and blockers. This does not establish that the application tests fail or that no PostgreSQL service exists elsewhere. No new database was created.

## Historical evidence stays historical

Fresh reads confirm that both committed fidelity matrices still contain 83 rows. The baseline labels are 18 preserved, 4 transformed as intended, 41 omitted, 15 incorrect and 5 not applicable. The corrected labels are 21 preserved, 6 transformed as intended, 50 omitted, 1 incorrect and 5 not applicable. These are counts of preserved historical results, not a repeated F0 source/database evaluation. The purposive and uneven 78 semantic / 5 technical assertion design does not establish corpus-wide accuracy.

The corrected public summary reports 446 successfully imported works and 58 tests/269 assertions for its historical build. The current source contains 58 active test declarations; static enumeration does not rerun those tests and supplies no current assertion count. Do not substitute the historical numbers for the blocked F0 suite result.

Historical row `277-04` asserts retention of five direct titles and a selected first untyped display title (`Serenade`), while the stored uniform title was `Se! Luften er stille`; it remains `incorrect`. Keep this row/oracle untouched. A new, explicit display policy and all-title search can be evaluated prospectively in a separate matrix, with the policy rationale and difference from the older expectation stated.

The older baseline API characterized fourteen requests. The corrected API attempts did not finalize reconciliation, and all corrected row-level API values remain `not_evaluated` owing to the recorded request-context connection problem. F0 did not complete a request run, so it neither validates nor supersedes those attempts. Guards and comparator negative controls remain work to execute once the local isolated target is available.

The public formative usability summary reports three consenting adult participants and nine attempts, seven independent and two assisted, with issues in same-title differentiation, instrumentation abbreviations and search/filter distinction. F0 read only the public summary. No private form, identity, consent document or raw session was used. These observations remain formative evidence for the old identified build; they cannot be relabelled as final evaluation of future source/item screens.

Historical pointers: `docs/report_evidence/phase2_post_correction_comparison.md`, `phase2_post_correction_fidelity_results.md`, both `phase2_*fidelity_matrix.csv` files, `phase2_api_results.md`, and `phase2_usability_results.md`. The compact extracted title row and label counts are in `audit/static_facts.json`.

## Design reasoning to justify prospectively

O2/O3: a document key, source-description key and held-item key answer different questions. Retain nullable/unknown source fields and precise locators instead of fabricating source ownership from proximity. Require explicit same-document relation resolution where supported; retain raw unresolved/cross-file targets with status. Stable idempotency must use the approved identity boundary, while a content hash records a version. A rebuild/new evaluation database can preserve historical databases unchanged.

O3/O4: retaining typed/language-tagged titles supports search and explains display alternatives; XML order supplies provenance, not an inherently preferred language. Multiple work classifications should survive as terms, even if a compatibility genre field is retained. Documentary bibliography genres must not be promoted into work genre or counted as manuscript-source descriptions merely because their text says “manuscript”.

O4/O6: define API ordering, pagination, parameter validation, errors and unsupported states before final measurement. Separate source-to-database assertions from database-to-API comparisons, derive expectations without the implementation's filtering/serializer, and use mutation of an expected observation as an explicitly labelled comparator negative control. A database guard pass would establish target safety only, not API correctness.

## Evidence still needed

O1 / FB01 / FB10: verify citable primary domain/previous-work claims and record a fair task-based comparison with an actual existing access method. The template and engineering preferences do not prove an unmet need, lack of an alternative API, or better task performance. Any late domain research must be dated as late-stage validation, not retrospectively attributed to the original design.

O3 / FB05 / FB06: approve the bounded model and title/classification/identity policies, resolve the listed semantic ambiguities, implement in an authorised later package, then exercise real-source acceptance cases plus rollback/collision/absent/unsupported cases. F0 development examples are no longer unseen final-evaluation records.

O4 / FB07: obtain a safely reachable local PostgreSQL target under the declared isolation guards, run the existing suite, and complete the one small API feasibility run before a larger final protocol depends on it. Do not copy historical pool-object identity assumptions; verify server database/user identity from the actual request connection.

O5 / FB08: Javier must confirm ethics/consent arrangements and feasible recruitment, then run build-specific independent/assisted tasks. No new participant findings or accessibility/performance/security certification is supplied by F0.

O6 / FB04 / FB11–FB13: update figures only after the model stabilises; review public-release reproducibility/privacy; verify logged-out repository access and actual portal cutoff/time zone; count the six chapter limits (1000/2500/2000/2500/2500/1000) and total ≤10500. The student-produced 3–5 minute own-voice, non-sped-up video remains separate; no video construction material is produced here.

No feedback item is closed by these notes. `feedback_to_evidence.md` preserves the initial register and adds only F0 observations and remaining evidence needs.
