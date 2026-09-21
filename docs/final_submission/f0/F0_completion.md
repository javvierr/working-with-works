# F0 completion — baseline and source reconnaissance

**19 September 2026 · recommendation: READY_WITH_BLOCKERS.** F0 establishes a preserved baseline, source-backed modelling decision and usable local Ruby environment. It does **not** complete the existing Rails suite or the API feasibility experiment because a safe local database connection could not be established. No F1 implementation has begun.

## Authority, baseline and scope

The requested prompt is actually at `codex_context/f0/Working_with_Works_F0_Start/F0_Codex_Prompt.txt`; its F0 specification, seed register and every supplied context file were read. The supplied kit SHA-256 manifest passes. No applicable repository/parent `AGENTS.md` was found. Work used the existing local repository, with no scaffold, branch, worktree or Git write.

Branch is `main`; full HEAD is `b0142488fd5609e86d93c84978134a7d849d1882`, exactly the assessed commit, which exists locally. Initial tracked/staged/untracked status and diff summaries were empty. All 13 current files named in the assessed snapshot manifest match its recorded hashes. Ignored historical/source materials were present and preserved separately; a clean Git status does not describe them as absent.

The four F0 document candidates and initial feedback-register copy are the only authorized repository additions. A new `codex_context/f0/.DS_Store` also appeared during execution; its producer is not established. It was retained and reported separately as incidental macOS metadata. The application, configuration, dependencies, database schema, tests, fixtures, README, original XML and historical evidence were not edited. No staging, committing, pushing, tagging, history/index operation, installation, upgrade, network retrieval, publishing or participant contact occurred. Original setup/CI and every database reset/drop/replant/clear action were avoided.

## Results and limits

| Activity | Actual outcome | Evidence in review archive |
|---|---|---|
| Runtime declarations | `.ruby-version`/Gemfile specify Ruby 4.0.5; lockfile Rails 8.1.3/Bundler 4.0.15. Shell default Ruby is 2.6.10. An installed Ruby 4.0.5 and matching Bundler work. | `F0_checks.json`; runtime logs |
| Dependencies | Initial unconfigured gem lookup fails. Selecting existing `$USER_HOME/.gem/ruby/4.0.5` and the declared Ruby's standard gem path makes `bundle check` pass. No install or lockfile rewrite. | `logs/bundle_check.txt`, `logs/bundle_check_configured.txt` |
| Disposable application | 111 selected application files copied outside the repository and verified for byte/mode identity. Credentials, Git metadata, historic logs/evidence and unrelated materials excluded. Fresh log/tmp/cache only; three official subset XML copies separately verified. | `evidence/copy_manifest.json`, `evidence/subset_copy_manifest.json` |
| No-database runtime checks | 64 Ruby files have no syntax failures; Rails 8.1.3, PG 1.6.3 and Nokogiri 1.19.4 load; Rails test configuration resolves the planned unique target; Zeitwerk eager loading passes. | `evidence/runtime_outcome.json`; corresponding command logs |
| Database prerequisite | `/tmp/.s.PGSQL.5432` does not exist. TCP `127.0.0.1:5432` is denied by the sandbox (`Operation not permitted`). Process inventory is also unavailable. These observations do not establish that no PostgreSQL service exists elsewhere. | `logs/postgres_readonly_identity.txt`, `logs/postgres_tcp_identity.txt`, `logs/postgres_process.txt` |
| Existing suite / subset import / API | **BLOCKED, not executed.** No current seed/test/assertion counts, import counts, responses, comparator negative control or server-identity guard result exists. Zero databases created, zero writes, zero API attempts. Configuration resolution is not server identity. | `evidence/runtime_outcome.json`; `api_plan/API_feasibility_blocker_and_next_diagnostic.md` |
| Original preservation | Before/after content and mode comparison, including original app/config/tests, public evidence, corpus/archive, historical scratch and Git HEAD/index/refs. Private historical files are represented only by an opaque aggregate. All 5,967 baseline entries match content/mode, and all 111 copied application files match. One incidental new `.DS_Store` is reported separately. The initial strict comparison flagged that addition and is retained; no original content changed. Credential/key contents were deliberately excluded. | `evidence/preservation_before.json`, `evidence/preservation_after.json`, `evidence/preservation_comparison.json` |

The old 58 tests/269 assertions and 446 successful corrected imports remain historical evidence. Static code still declares 58 tests; that is not an executed suite. Both old 83-row matrices and the incomplete corrected API attempts remain unchanged.

## Main source and implementation findings

The exact local CNW corpus contains **446 XML files, 26,925,115 bytes**; all declare the MEI namespace and version 4.0.1, with one work element each. This is not schema-conformance certification. All 15 sample-manifest hashes match. The existing 234,079,300-byte corpus archive matches historical SHA-256 `fa3ff9e3012a6a9e8d21c098105bea3be9670945bb76aa5ea46391d2c33cf8ec`.

Independent parsing finds **2,148 manifestations and 1,370 items**; the current `source_references` selectors match zero candidate elements. Structural totals do not imply that every node is a meaningful source/item or that all can safely be assigned to the whole work. The profile distinguishes descriptive payload, empty placeholders, expression context, direct item fields and relationship targets.

The exact current genre-selector reproduction selects outside direct work classification in **310/446 files**. CNW 417 chooses bibliography `manuscript`; CNW 63 chooses bibliography `letter`. These are fresh source-selector observations, not Rails imports, and the other 136 records are not proven correct by exclusion. Direct work classification terms must be retained independently of documentary bibliography.

CNW 277 has five direct title nodes. The current uniform-before-first rule explains the mismatch with historical assertion `277-04`; title type/language/order are also lost. Preserve the old assertion and results; agree a prospective display policy and independent expected values before a later correction.

The failed-reimport issue is a **static prediction**: the failed attempt lacks the surviving work association, while the detail page reads only associated logs. The per-file transaction suggests preservation of the prior domain state, but no new runtime rollback/display demonstration was possible. Current path-based identity, namespace removal, first-work/root fallback and zero-input success-like reporting also need a bounded policy before implementation.

The source profiler retained two failed structural-selection diagnostics before replacing an empty candidate rule; these are scratch-script failures, not application failures or API attempts. Final source QA verifies all 446 file hashes and 249 selected XML locators.

Six development examples are CNW **417, 277, 63, 17, 45 and Coll. 27**. The fresh contrasts are now development data. Reserved records are chosen by declared structural rules with profiling/selector exposure disclosed; no detailed reserved assertion values were opened. `F0_source_model_proposal.md` supplies exact identities, namespace-aware locators, proposed keys, recommended minimal design, smaller fallback, independent acceptance cases and effort estimates. `source/selected_examples.md` supplies source evidence; `audit/static_audit.md` supplies code locators and historical reconciliation.

## Next scope and unresolved decisions

1. Resolve access to an **already available local PostgreSQL service** under the F0 guard procedure; no stack downgrade or dependency install is indicated. A service start/provision or additional permission must be separately reviewed if required. Verify actual server database/user identity, unused names and every effective test connection before writes. Then run the existing suite and one three-record API probe; the plan preserves the one-revision limit and distinguishes source fidelity, API exposure and comparator controls.
2. Review the source proposal's minimum boundary and fallback: XML-document membership, catalogue source description, held item, and explicit expression/source relationships must remain distinct. The presence of one work per file does not justify whole-work ownership. Accept the supported relation/ambiguity policy before building the source pathway.
3. Approve typed-title display/search and multi-term work-classification policies; do not silently rewrite historical `277-04`. Agree stable identity and duplicate/missing/unsupported-shape behavior, including document-scoped XML IDs and fresh-database rebuild implications.
4. Proposed **F1 only**: reproduce and correct classification, typed-title policy and failed-reimport visibility; add focused independent regressions and input/identity safeguards to the approved boundary. Review safe setup/quality-check repair scope. F2 source persistence and F3 API/UI remain subsequent packages. This document does not authorize or start any of them.
5. At the **21 September checkpoint**, reduce to the proposal's smaller source/item slice if correct end-to-end ownership, re-import and API/HTML acceptance cannot be demonstrated. Protect the 23 September feature freeze and later evaluation/report time.

Human-dependent items remain open: portal cutoff/time zone, ethics/consent and participant availability, any tutor clarification, justified access tasks and a fair comparator, and public repository accessibility. No research, participant or final-report result was invented. All feedback items remain open/investigating or otherwise explicitly incomplete in the new register.

## Gates

| Gate | Result | Reason |
|---|---|---|
| G0 — preservation | PASS | Original manifest comparison and copied application identity pass; only authorized F0 documentation plus one disclosed incidental `.DS_Store` appeared. Sensitive file exclusions and private-digest method are explicit. |
| G1 — baseline | PARTIAL | Exact HEAD/state/runtime/dependencies and no-DB checks verified; existing Rails suite blocked by database isolation prerequisite. |
| G2 — source understanding | PASS | Corpus identity/hashes, independent reproducible census, six varied located examples and unresolved relationships documented. |
| G3 — implementation decision | PASS | One bounded recommendation plus smaller fallback, title/classification/identity policies, acceptance examples and estimate supplied for review; no implementation. |
| G4 — API-harness feasibility | BLOCKED | No verified database/request/comparison path or negative control could execute. Concrete guarded next diagnostic supplied. |
| G5 — feedback/report continuity | PASS | Preserved feedback strengths/concerns linked to F0 evidence and outstanding objectives; no future work closed. |
| G6 — review handoff | PASS | One explicit-allowlist archive with SHA-256 payload manifest, CRC/readability checks, command evidence and exclusions; validation details accompany it. |

**READY_WITH_BLOCKERS** means ready to review the proposed F1 scope, not a claim that runtime/API feasibility or submission readiness has passed. Stop here for review.

## Handoff and resource locations

Repository additions: `docs/final_submission/f0/F0_completion.md`, `F0_source_model_proposal.md`, `F0_checks.json`, `F0_report_notes.md`, plus `docs/final_submission/feedback_to_evidence.md`. Evidence references in these documents are relative to the review ZIP; raw F0 observations/scripts remain in the new external scratch directory.

`$F0_RUN` denotes the run-specific scratch directory containing the review ZIP. `$REPO` denotes the actual project root; `$USER_HOME` and `$RUBY_4_0_5` are sanitized local aliases. The exact scratch/copy and two Bundler-created temporary directories are recorded in `private_resource_locations.json` beside the archive, excluded from review contents. These are cleanup candidates for Javier to review; nothing was automatically deleted. Planned names `www_f0_tests_20260919_jzkmvw` and `www_f0_api_20260919_jzkmvw` were **not created and not verified unused**; they are not database cleanup candidates.

The final response identifies the archive's exact local path and size. No upload or publication occurred.
