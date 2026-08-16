# Phase 1A gaps and next evaluation

Audit date: 15 August 2026

This file ranks evidence gaps and recommends Phase 2 evaluation actions. It does not authorize or implement application fixes, features, or dependency changes.

Priority:

- HIGH: materially limits a central project claim or assessment criterion.
- MEDIUM: important but does not invalidate the constrained feasibility result.
- LOW: useful refinement or future-work evidence.

## Priority overview

The most consequential Phase 2 gates are:

1. Evaluate transformation fidelity against a provenance-documented, structurally varied authoritative MEI subset.
2. Exercise importer warning, failure, rollback, changed-value re-import, and edge-path behavior.
3. Define and verify an API contract, including error and invalid-filter behavior.
4. Conduct task-based usability evaluation rather than inferring usability from HTTP 200 responses.
5. Re-run clean-machine/setup/CI evidence after independently resolving the broken importmap step and state-dependent fixture failure.

## 1. Correctness

| ID | Rank | Evidence gap | Why it matters | Recommended Phase 2 evaluation action | Evidence needed for closure |
|---|---|---|---|---|---|
| COR-01 | HIGH | No executed importer warning or failure path | Reliability is a central evaluation question, yet all four fixtures are clean happy paths. | Define controlled fixtures for recoverable parser warnings, missing composer, missing title, invalid child data, and malformed XML; predict the expected result before execution. | Per-case command, status, warning/error/log assertions, database before/after counts, and proof later files continue where intended. |
| COR-02 | HIGH | Transaction rollback after a failed new import or re-import is not demonstrated | A partially updated catalogue would undermine data trust. | Snapshot an imported work and child set, trigger a deterministic child failure, and compare all values, IDs, and logs after rollback. | Exact unchanged prior state plus one correctly classified failure attempt. |
| COR-03 | HIGH | Changed-value re-import is not tested | Current idempotence evidence repeats identical bytes only. | Create an evaluation variant with one changed scalar and one changed child value, import it twice, and compare work identity, updated values, child replacement, and logs. | Work ID stable; intended values updated; unintended duplicates absent; replacement semantics documented. |
| COR-04 | MEDIUM | Six empty model-test classes, one empty Action Cable test class, and no ImportLogTest leave most model rules unverified | Broad “model coverage” wording is unsafe. | Create a Phase 2 coverage matrix before adding/running any evaluation cases, mapping every validation, association, ordering, and dependent behavior to evidence. | Matrix plus isolated results; no unsupported coverage percentage. |
| COR-05 | MEDIUM | Model and database constraints diverge | Direct SQL/bulk operations can admit states the model rejects, such as null movement positions or arbitrary log status. | Execute non-destructive transaction-wrapped constraint probes and roll them back. | Table showing model result versus DB result for each invariant. |
| COR-06 | MEDIUM | ExternalReference label/URL and several child fields lack validation | Invalid or unsafe catalogue values can be stored/presented. | Audit a realistic corpus for missing/invalid values and classify whether each is acceptable, warning-worthy, or invalid. | Frequency table and explicit acceptance rules; no production-security claim. |
| COR-07 | LOW | Association ordering is mostly untested | Presentation may change silently. | Verify movements, instrumentation, and performances with deliberately out-of-order inputs. | Expected deterministic order in model, API, and HTML output. |

## 2. Transformation fidelity

| ID | Rank | Evidence gap | Why it matters | Recommended Phase 2 evaluation action | Evidence needed for closure |
|---|---|---|---|---|---|
| FID-01 | HIGH | All four inputs are purpose-built and non-authoritative | Internal fixture correctness cannot establish external validity. | Obtain a rights- and provenance-documented subset of authoritative or institutionally published Carl Nielsen MEI, without replacing current fixtures, and record source/version/checksum metadata for the evaluation set. | Traceable corpus manifest and permitted-use statement. |
| FID-02 | HIGH | No manual source-to-output fidelity comparison | Record counts do not show whether meaning was preserved. | For a varied stratified subset, define a field-level oracle from source XML and compare every selected target field, including omissions and transformations. | Per-record source locator, expected value, actual value, match/mismatch reason, and aggregate error categories. |
| FID-03 | HIGH | One work per file and one composer per work are hard boundaries | Real catalogues can encode compound records or multiple responsibilities. | Include at least one multi-work file and one multi-responsibility/multi-composer example in a static mapping analysis and controlled import attempt. | Explicit observed behavior and a justified supported/unsupported decision. |
| FID-04 | HIGH | Uncertain, ranged, partial, and conflicting dates are reduced or lost | Scholarly date semantics are material catalogue information. | Build a date-case corpus covering isodate, notbefore/notafter, year-only, ranges, uncertainty, conflicts, and invalid text; compare source meaning to stored/API values. | Case table with preservation/loss classification and report wording. |
| FID-05 | HIGH | Namespace removal plus recovery parsing is not schema validation | Malformed or mixed-namespace documents can appear to succeed while losing meaning. | Validate evaluation inputs independently against the relevant MEI schema/version, then compare strict-validation results with importer results. | Valid/invalid classification, parser warnings, and any false acceptance/rejection. |
| FID-06 | HIGH | Alternate titles/languages, responsibility statements, manuscript hierarchies, and detailed forces are omitted or simplified | The project template rewards meaningful catalogue complexity. | Sample authoritative records containing each structure and create a preserved/transformed/omitted matrix. | Coverage matrix linked to exact source structures and target decisions. |
| FID-07 | MEDIUM | XPath fallback precedence can silently select the wrong first value | First-match behavior may be ambiguous in real records. | Construct records with multiple candidate composer/title/date/genre nodes and document which candidate is chosen and why. | Deterministic precedence results and ambiguity classification. |
| FID-08 | MEDIUM | De-duplication ignores some dimensions | Instrumentation section, source repository/type, or duplicate labels can be lost. | Evaluate paired values that differ only in ignored dimensions and compare intended versus actual rows. | Loss/merge table and impact assessment. |
| FID-09 | MEDIUM | Performance dates silently become nil when not exact YYYY-MM-DD | Valid catalogue events can lose dates without warning. | Test partial, textual, ranged, uncertain, and invalid performance dates and inspect logs. | Explicit preservation/loss/warning outcomes. |
| FID-10 | LOW | Whole-file reads have no size boundary | Large MEI could affect reliability/performance. | Select non-sensitive synthetic files at increasing sizes and record memory, time, and failure behavior under controlled conditions. | Reproducible size/time/memory table; no extrapolation beyond tested range. |

## 3. Negative paths

| ID | Rank | Evidence gap | Why it matters | Recommended Phase 2 evaluation action | Evidence needed for closure |
|---|---|---|---|---|---|
| NEG-01 | HIGH | Malformed XML behavior is untested | recover mode may warn, partially import, or fail unpredictably. | Run a matrix of truncated, mismatched-tag, invalid-encoding, and external-entity cases with nonet retained. | Result/log/database outcome for each malformed case. |
| NEG-02 | HIGH | Required title failure and unknown-composer fallback are not exercised through the importer | These paths affect whether incomplete records are rejected or silently generalized. | Import controlled missing-title and missing-composer cases separately. | Failure versus success status, warnings, work/composer changes, and rollback evidence. |
| NEG-03 | HIGH | Failure logging itself can raise without a second rescue | A logging failure could abort the whole directory pass. | In a controlled test harness, force failure-log validation/persistence failure after an import exception. | Whether call continues/aborts and which evidence survives. |
| NEG-04 | MEDIUM | Rake abort behavior after mixed file outcomes is unverified | Operators need truthful exit status without losing completed evidence. | Use a directory with one valid and one deterministic invalid file; capture console output, exit status, counts, and logs. | Proof of successful-file retention, failure count, and nonzero task exit. |
| NEG-05 | MEDIUM | API missing-ID and malformed-parameter behavior is unknown | Predictable errors are part of API correctness. | Request nonexistent IDs, invalid year strings, inverted ranges, unexpected arrays/objects, and unsupported formats. | Exact status, content type, body shape, log behavior, and absence of server exceptions. |
| NEG-06 | MEDIUM | Wildcard and escaping behavior is incompletely evaluated | Percent/underscore inputs can broaden matches unexpectedly. | Query literal %, _, backslash, Unicode, mixed case, and whitespace inputs. | Expected/actual result sets and SQL-safety confirmation. |
| NEG-07 | LOW | Empty/missing directory only has static support | Operator messaging and exit semantics are not fresh evidence. | Run `mei:import` with an empty and a nonexistent import directory. | Files/warnings/failures/exit status and unchanged DB counts. |

## 4. Edge cases

| ID | Rank | Evidence gap | Why it matters | Recommended Phase 2 evaluation action | Evidence needed for closure |
|---|---|---|---|---|---|
| EDG-01 | HIGH | Identity depends on source-file path text | Renames and alternate path representations can duplicate works or expose implementation paths in JSON/HTML. | Import identical bytes under renamed and alternate path representations; inspect the stored and exposed values. | Work/log counts, path-disclosure findings, and a documented identity/traceability rule. |
| EDG-02 | HIGH | Removed source files do not prune or flag stale works | Database can diverge from its corpus silently. | Import an evaluation corpus, remove one file, re-import, and inspect retained rows and logs. | Explicit stale-record behavior and operator-visible evidence. |
| EDG-03 | MEDIUM | Only lowercase .xml/.mei extensions are discovered | Cross-platform/source naming variations may be skipped silently. | Evaluate uppercase/mixed-case extensions and nested directories. | Discovery/result table and no-files/skipped-file messaging. |
| EDG-04 | MEDIUM | Multiple identical or near-duplicate identifiers/forces/sources may conflict or merge | Real catalogue repetition can trigger constraints or data loss. | Use duplicate pairs differing in type, case, section, repository, or whitespace. | Expected/actual de-duplication and failure results. |
| EDG-05 | MEDIUM | Nonnumeric movement positions become 0 and then fail | Common roman numerals or labels can reject a whole file. | Test roman numerals, decimals, missing n, duplicated n, and out-of-order movements. | Import/log/rollback/order matrix. |
| EDG-06 | MEDIUM | Invalid and inverted year filters silently coerce through to_i | API can return misleading results instead of an explicit client error. | Exercise text, decimals, very large values, year_from > year_to, and blanks. | Exact response behavior and a product-level accept/reject decision. |
| EDG-07 | LOW | Concurrent imports can race on unique source_file | Duplicate operators/jobs could create failures or inconsistent logs. | Run a bounded two-process import and inspect locks and results. | Both exit statuses and final work/child/log counts. |
| EDG-08 | LOW | Unicode normalization/collation is not evaluated | Composer/title equality and search may vary across composed forms. | Test accented names in NFC/NFD and locale-sensitive case pairs. | Stored values, uniqueness, and search-result comparison. |

## 5. Authoritative-data validity

| ID | Rank | Evidence gap | Why it matters | Recommended Phase 2 evaluation action | Evidence needed for closure |
|---|---|---|---|---|---|
| AUTH-01 | HIGH | No authoritative corpus provenance | The report must not imply real Carl Nielsen catalogue coverage. | Establish a corpus manifest with institution, stable URL/identifier, acquisition date, licence/permission, MEI version, and checksum. | Auditable manifest cited by every Phase 2 result. |
| AUTH-02 | HIGH | Sample selection is not justified | Four homogeneous files cannot represent catalogue variability. | Profile the available authoritative corpus, define strata by structure/complexity/missingness, and select cases transparently. | Population profile, inclusion criteria, sample table, and acknowledged sampling bias. |
| AUTH-03 | HIGH | No domain-expert or source-document validation of transformed meaning | Syntactic extraction can still be semantically wrong. | Have a qualified reviewer or documented catalogue reference validate a bounded set of mappings using a predefined rubric. | Review protocol, disagreements, adjudication, and corrected claim boundaries. |
| AUTH-04 | HIGH | Field-level source provenance is absent | Users cannot audit a displayed value back to its XML location/version. | During evaluation, maintain an external mapping sheet from every checked target value to source file, work ID, XPath or element locator, and source version. | Complete mapping for the evaluation sample; classify application limitation separately. |
| AUTH-05 | MEDIUM | External-reference targets occur only in purpose-built fixtures and remain unverified | A link row is not proof of useful scholarly linkage. | Validate target existence, identity match, authority, persistence, and scheme for a sample. | Link-quality table and failure rate. |
| AUTH-06 | MEDIUM | Domain claims about MerMEId/MEI/LOAR rely on earlier literature prose | Repository evidence cannot verify external historical claims. | Re-check every external claim against current primary or authoritative sources and update citations separately from code evidence. | Citation audit with claim/source/date/quotation limits. |

## 6. API behaviour

| ID | Rank | Evidence gap | Why it matters | Recommended Phase 2 evaluation action | Evidence needed for closure |
|---|---|---|---|---|---|
| API-01 | HIGH | No explicit versioned response contract | Passing sample JSON can change without detection. | Derive a field/type/nullability/order contract from current output and validate it against representative populated/missing-value records. | Machine-readable or tabular contract plus conformance results. |
| API-02 | HIGH | API usefulness/predictability is not evaluated with developer tasks | Correct sample filters do not prove a usable research interface. | Define developer tasks such as identify a work, enumerate movements, filter forces/years, and follow provenance; have participants or an independent evaluator use only the API documentation. | Completion, errors, time, ambiguities, and qualitative feedback. |
| API-03 | MEDIUM | Error behavior is untested | Clients need stable status/content type/body for missing or invalid requests. | Execute the NEG-05 matrix and compare with a predeclared contract. | Error-case table and inconsistencies. |
| API-04 | MEDIUM | No pagination or response metadata | Full materialization can become unusable on a real corpus. | Load a bounded synthetic or authoritative-sized dataset and measure response size, time, and memory at several result counts. | Observed thresholds and report-safe scalability boundary. |
| API-05 | MEDIUM | Secondary identifiers are excluded from catalogue/search filters | Users may search by an identifier that exists only in child rows. | Define test cases for primary and secondary catalogue values and compare expected discoverability. | Search-recall table by identifier type. |
| API-06 | MEDIUM | Instrumentation test in the automated suite is confounded by year | A regression in the instrumentation scope could pass. | Evaluate each filter independently, then in pairwise combinations, with data that makes each predicate necessary. | Result-set truth table. |
| API-07 | MEDIUM | Sorting is fixed and undocumented; no relevance ranking | Result predictability/usefulness may suffer. | Record ordering for case variants, duplicate titles, and blank values; compare with user/developer expectations. | Ordering examples and explicit contract decision. |
| API-08 | LOW | Index/detail omit import evidence and instrumentation sections | Consumers cannot inspect some stored context. | Interview/evaluate developer tasks to determine whether omitted fields are required before proposing changes. | Task-based need, not an assumed feature request. |

## 7. Web-interface behaviour

| ID | Rank | Evidence gap | Why it matters | Recommended Phase 2 evaluation action | Evidence needed for closure |
|---|---|---|---|---|---|
| WEB-01 | HIGH | No automated HTML/controller/system regression tests | Fresh smoke does not prevent silent view breakage. | Define critical-page assertions for root, list, filtered list, detail, no results, missing ID, and missing optional data; execute them against a defined fixture state. | Status/content/semantic-element results. |
| WEB-02 | HIGH | Latest attached log can hide a failed re-import | Interface may communicate stale success after an actual failure. | Import a work successfully, force a failed re-import, then inspect the detail page and underlying logs. | Screenshot/content comparison documenting whether the displayed status is truthful. |
| WEB-03 | MEDIUM | Empty child collections render empty lists | Users may interpret absence as a rendering fault. | Evaluate detail pages with each optional collection absent using a content-comprehension checklist. | Observed page text and evaluator interpretation. |
| WEB-04 | MEDIUM | Imported external URLs are rendered without format/scheme validation | Unsafe or broken values may become clickable. | Use benign controlled invalid schemes and URLs in an evaluation fixture and inspect rendered attributes and behavior; do not use live malicious content. | URL/scheme/rendering table and security-review referral. |
| WEB-05 | MEDIUM | Search/filter boundaries and preserved form state lack systematic checks | Operator/user confidence depends on predictable interaction. | Run a browser-based task matrix for combined filters, clear, back navigation, zero results, and repeated queries. | Task result and screenshots for each state. |
| WEB-06 | LOW | Responsive behavior is asserted only by CSS inspection | Layout may fail on actual viewport/content extremes. | Capture key pages at phone/tablet/desktop widths with long titles and instrumentation. | Visual QA sheet with clipping/overflow findings. |
| WEB-07 | MEDIUM | The repository has no screenshot, graph, or diagram artifact tied to the fresh implementation state | The implementation brief requests screenshots and feedback requests more visuals/data-flow schemes. | Capture fresh core pages against a recorded fixture/database state and prepare evidence-linked schema/data-flow visuals for the report. | Captioned visuals tied to exact commands/data; screenshots must not be presented as usability proof. |

## 8. Usability

| ID | Rank | Evidence gap | Why it matters | Recommended Phase 2 evaluation action | Evidence needed for closure |
|---|---|---|---|---|---|
| USA-01 | HIGH | No user or peer task study | The project template explicitly emphasizes user-friendly exploration. | Recruit the planned 3-5 relevant peers, obtain consent as required, and run a fixed task protocol without coaching. | Participant characteristics, task success, time, errors, assistance, and observations. |
| USA-02 | HIGH | No comparison with raw XML or an existing catalogue view | “Improves exploration” is a comparative claim. | Use a counterbalanced within-subject comparison for a bounded set of discovery/provenance tasks. | Completion/time/error comparison and participant preference with limitations. |
| USA-03 | HIGH | User groups are proposed but not validated | Musicologist, performer/student, and developer needs may differ. | Map each evaluation task to one proposed user group and recruit/report accordingly, or narrow the claim to the participants actually studied. | User-task matrix and explicit generalizability boundary. |
| USA-04 | MEDIUM | Accessibility is unevaluated | A portal cannot be called user-friendly without inclusive interaction evidence. | Run automated checks plus keyboard, focus, labels/headings, contrast, zoom, and screen-reader spot checks on core pages. | Tool output and manual checklist with severity. |
| USA-05 | MEDIUM | Search terminology and result presentation are unvalidated | Labels such as catalogue number, source, or instrumentation may not match user expectations. | Use think-aloud tasks and short post-task questions focused on labels, filters, and result interpretation. | Thematic findings tied to exact UI states. |
| USA-06 | LOW | No satisfaction metric or qualitative coding plan | Anecdotes are difficult to analyse critically. | Predefine a lightweight instrument and coding approach appropriate to the small sample; report raw counts and quotes within consent/copyright rules. | Transparent instrument, coding, and limitations. |

## 9. Reproducibility and CI

| ID | Rank | Evidence gap | Why it matters | Recommended Phase 2 evaluation action | Evidence needed for closure |
|---|---|---|---|---|---|
| REP-01 | HIGH | The clean-state `bin/ci` workflow cannot complete because `bin/importmap` is absent | The configured quality gate is not green. | After the issue is resolved outside Phase 1A, run the resulting CI from a clean setup with a defined application-data state and retain full output. | Exit 0 with every configured step present and passing, or an explicitly justified revised workflow. |
| REP-02 | HIGH | CI tests fail after prior imports because setup leaves residual ImportLogs | Setup claims idempotence but is state-dependent. | Evaluate CI from empty, fixture-populated, and imported test-data states. | State/result matrix and a documented precondition. |
| REP-03 | HIGH | Fresh setup required explicit selection of the declared Ruby 4.0.5 rather than the system interpreter | A new evaluator may fail before setup. | Follow the README setup instructions exactly, record interpreter-selection steps, and distinguish required version-manager configuration. | Clean-room transcript with versions and exit codes. |
| REP-04 | MEDIUM | Bundler 4 installation removed its checksum line from `Gemfile.lock` | Setup may alter an otherwise clean project copy. | Repeat dependency installation on each supported platform and compare `Gemfile.lock` before and after. | Byte-level diff and platform matrix. |
| REP-05 | MEDIUM | The fresh dependency install required network access, and no offline/cache path is established | This observed rebuild depended on external availability. | Record gem source access requirements and test a documented cached/offline procedure only if one is intended. | Successful clean-room install or explicit online prerequisite. |
| REP-06 | MEDIUM | Rails 8.1 gems run with Rails 7.0 defaults/migration version | Compatibility behavior may be misunderstood. | Record effective framework defaults and run targeted regression checks around relevant changed defaults; do not imply upgrade completion. | Configuration inventory and targeted results. |
| REP-07 | MEDIUM | Production Cable selects Redis while Redis is not declared | Production configuration is not self-contained. | Exercise each intended production subsystem under controlled conditions and record dependency failures without deploying. | Boot matrix and explicit supported deployment scope. |
| REP-08 | LOW | Seed CI step is a no-op | Green output can be misread as data verification. | Document that db/seeds.rb has no domain seeds and exclude this step from catalogue-evidence claims. | Clear report wording and CI interpretation. |
| REP-09 | MEDIUM | Security is unevaluated beyond static configuration observations | Read-only routes and Rails defaults do not establish application or dependency safety. | Run a bounded Phase 2 threat/configuration/dependency review covering authentication assumptions, input/output risks, headers/CSP/SSL settings, dependency audit availability, and benign XML/URL cases. | Scope, tool versions, findings/severity, and explicit limits; no production-safety claim from a clean result. |
| REP-10 | MEDIUM | Maintainability is inferred from conventional structure rather than evaluated | Architecture alone does not show whether another developer can understand, change, diagnose, or rebuild the system. | Use a bounded comprehension/change-impact exercise, dependency/configuration review, and clean diagnostic transcript with an independent reviewer if feasible. | Task completion, time/ambiguities, dependency risks, and reproducible notes; avoid a blanket maintainable label. |
| REP-11 | MEDIUM | Existing logs include unrelated `/api/v2` request starts | Historical counts can be overstated. | Base report claims on fresh, reproducible commands and exclude unrelated log traffic from result counts. | Curated evidence table tied to the commands that produced each result. |
| REP-12 | LOW | No persistent machine-readable execution artifact accompanies this audit | Markdown summaries require trust in transcription. | In Phase 2, retain sanitized command transcripts or equivalent machine-readable results if institutional policy permits. | Reviewable execution evidence with sensitive values omitted. |

## Suggested Phase 2 evaluation sequence

1. Define the evaluation scope, corpus manifest, field-level transformation oracle, and stratified authoritative sample.
2. Run correctness, negative-path, and edge-case importer matrices against defined application-data states.
3. Define and test API success/error contracts and realistic-corpus behavior.
4. Run HTML regression, accessibility, and task-based usability evaluation.
5. Reproduce setup and CI from clean and pre-populated states.
6. Reconcile all results back into `claim_evidence_register.md` and use only surviving wording in the final report.

Phase 2 should report failures as results. It should not infer broad compatibility, usability, performance, security, or production readiness from the current four-fixture success.
