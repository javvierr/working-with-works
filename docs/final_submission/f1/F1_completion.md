# F1 completion — COMPLETE_FOR_REVIEW

Recorded 2026-09-19T19:33:19.461613+00:00. The bounded F1 implementation is complete. All 25 mandatory cases pass; final archive integrity is recorded in the adjacent validation file. No F2 work, staging, commit, push, Git index/ref change or original setup/CI/cleanup command was performed.

## Result and evidence

CatalogueDocument supplies validated document identity and bounded conflict rules. WorkTitle preserves ordered typed/language variants and the declared heading policy; WorkClassificationTerm retains direct-work classifications with metadata. Import replacement is atomic and failed attempts remain visible beside the last successful data version. Existing HTML and additive detail JSON expose these corrections. The maintained isolated validation entrypoint is `script/final_submission/f1_validate.rb`.

CNW 417 now has Vocal music and Music for vocal soloists and instruments with or without choir; CNW 63 has Instrumental music and Chamber music. Nested documentary manuscript/letter values are excluded. CNW 277 displays Serenade and retains all five title rows; all three alternative/uniform texts find the work once through API and HTML. Official/demo profiles, duplicate-batch rejection, known-path ownership, relocation/version conflicts, scoped XML IDs, malformed input, rollback, recovery, equal-time ordering and legacy compatibility are covered by actual observed checks.

| Gate | Actual outcome |
|---|---|
| P0 isolation/baseline/harness | PASS before implementation at 17:54:22 UTC; unchanged suite 58 tests, 269 assertions, zero failures/errors/skips; exactly four API requests |
| Identity/input policy | PASS; explicit official/demo distinction and frozen negative/conflict cases |
| Title/classification fidelity and exposure | PASS; six development inputs, 222 independent checks, 21 JSON/HTML requests |
| Atomicity/latest attempt | PASS; unchanged old defect reproduced first, meaningful revised rollback and history cases pass |
| Full regression suite | PASS; 96 tests, 781 assertions, zero failures/errors/skips; seed 190926, one worker, exit 0 |
| Preservation/handoff | PASS; bounded originals comparison passes; ZIP readback/hash outcome in adjacent validation record |

Use `F1_acceptance_results.csv` for the 25-case disposition by evidence class; multiple evidence-class rows do not increase the 25-case denominator. `acceptance/acceptance_evidence_map.json` retains 59 exact observed test references and validated JSON pointers. Old behavior, regression tests, source-to-database checks, database-to-API checks and HTML evidence remain distinguishable. Intentional comparator mismatches are successful controls, not application failures.

## What ran

The actual root is `$REPO`; HEAD remains b0142488fd5609e86d93c84978134a7d849d1882 on main. No applicable AGENTS.md was found in the checked root/ancestors/nested paths. The supplied external F1 package and required context were read directly; all 102 supplied payload hashes verified. The package was not copied into the repository. Existing installed Ruby 4.0.5, Bundler 4.0.15, Rails 8.1.3, PG 1.6.3 and Nokogiri 1.19.4 were used without dependency changes.

P0 ran in an external selective, byte/mode-identical application copy. Initial endpoint discovery did not establish an existing server; this is not evidence that PostgreSQL was absent. The user's narrow amendment authorized the new isolated instance. Each database name was verified absent, created collision-safely and verified empty. Effective configuration and live local database/user identity guarded writes and request connections. Wrong-target controls refused before write callbacks. Transaction-error cleanup allowed ROLLBACK before fresh live identity validation.

P0's first harness attempt failed before SQL on a malformed database URL. Its sole permitted revision passed. The baseline imported only CNW 417/277/63 once; the missing-detail request returned HTML 404 and remains a documented F3 limitation. R-01 separately reproduced the old genre/title and hidden failed-reimport defects using retained SQL/HTML and labelled synthetic input. See `evidence/p0_verdict.json`, `p0/attempt_2/`, `p0/r01/` and `p0/P0_guard_independent_review.md`.

Implementation ran only after that gate. The final application manifest is `validation/build_5.json` (acd5d1d3cc7d430fa695afa943b266697e10ecc6182df55157c7aef96faff3d8); it records 125 selective-copy files. The unchanged baseline schema was loaded into separate fresh revised targets, then the additive migration applied. Synthetic legacy fields/timestamps remained unchanged. Two observed schema dumps agreed before the generated schema was copied back. No development/historical database was used.

The six-record revised import succeeded once in build 3. The final build 5 source/API run performed observations only against that retained import, with its provenance/hash recorded; it did not import again. After correcting harness parsing/SQL result typing and one API instrumentation ordering issue, all 222 checks and 21 requests passed. Request snapshots of all 12 measured tables, sequences and schema metadata were unchanged. The legacy projection comparison independently covers 417/277/63 only; no equivalent old/new claim is made for the other three. Empty/missing task invocations each returned exit 1 with zero files, successes and file failures, and explicit run errors. Final schema/eager-load verification passed. All failed attempts and fixes remain in `evidence/failure_dispositions.md` and their original logs.

## Preservation and retained resources

The bounded comparison has 5,974 redacted baseline entries: 5,961 unchanged, 11 intended modified files and two missing Codex temporary refs. All 446 source XML files, 22 historical report-evidence files, 719 nonprivate historical phase2 files, 20 F0/register files and five pre-existing untracked user documents are unchanged. HEAD, index and main ref hashes match. No cause is attributed to the two temporary-ref changes. There are 14 new source files and six new F1 documents. The actual combined patch includes intended new files, excluding the five pre-existing untracked documents.

The initial collector incorrectly read and hashed `tmp/development_secret.txt` and `tmp/local_secret.txt`. Their values were not printed or copied. Their two entries, including hashes, are excluded from the review baseline and ZIP; no subsequent contents were read. The original manifest is retained privately outside the archive with mode 0600. Private participant contents, other credentials/secrets, dependencies/tool internals and outward symlinks are excluded. This is a disclosed execution error and a bounded preservation claim, not a claim that every file was read safely from the outset.

Scratch remains `/private/tmp/www_f1_20260919_yb5352lj`. New PostgreSQL data remains `/private/tmp/www_f1_pg_20260919_ausd0td1/data`, with private socket directory `/private/tmp/www_f1_pg_20260919_ausd0td1/socket`, port 55432, local user javier, original postmaster PID 40790. TCP listening was disabled and local authentication was peer. Only this instance was stopped successfully at 2026-09-19T19:23:14.508362+00:00; data/evidence remain and no automatic deletion occurred. The four retained databases are `www_f1_baseline_tests_20260919_yb5352lj`, `www_f1_baseline_api_20260919_yb5352lj`, `www_f1_revised_tests_20260919_yb5352lj`, and `www_f1_revised_api_20260919_yb5352lj`. Exact creation/configuration/live identity/stop evidence is included, but no database files or dumps are in the ZIP.

## Review and limits

The allowlisted review ZIP contains the six documents, exact intended source files, combined patch, reviewed scripts, frozen expectations, input hashes, command records, observations and bounded before/after preservation evidence. `payload_sha256.json` covers every payload member except itself; the adjacent validation file records ZIP hash/size/member counts and readback results. The archive includes no credentials, private participant material, Git objects, corpus XML, application copies, dependencies, caches or database dumps. Path aliases in review evidence are documented separately from exact source bytes.

This is a review artifact, not a release or a full-corpus evaluation. SourceDescription, HeldItem, SourceRelation, whole/component source ownership and source screens remain F2. Pagination/general API errors and existing source_file exposure remain later work. The original setup/CI hazards remain F5. No existing user database has the new migration. Legacy records remain explicitly unvalidated until a separately authorized rebuild. FB05/FB07/FB11 receive proposed implemented/awaiting-wider-evaluation updates, not automatic closure. F2 was not started.
