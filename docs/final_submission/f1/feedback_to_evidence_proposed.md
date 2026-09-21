# Working with Works — feedback-to-evidence register

**Version:** initial register, 19 September 2026  
**Status:** planning and traceability seed. No final-iteration implementation or evaluation is marked completed.  
**Authority:** supplied final instructions, individual feedback, project template, August draft and approved September delivery plan.

## 1. How to use this register

Keep feedback, interpretation, corrective action and evidence separate. Update only when an actual activity has occurred. Each closed item needs a source/code/evaluation artifact, the relevant version/date, and a report location. A proposed fix or new test file does not close an item.

Suggested statuses: `OPEN`, `INVESTIGATING`, `IMPLEMENTED_AWAITING_EVALUATION`, `EVALUATED`, `CLOSED`, `DEFERRED_WITH_JUSTIFICATION`, `BLOCKED`. F0 may record observations and proposals, not declare later packages completed. Deferred work remains a limitation; it does not become an achieved objective.

Use stable IDs below. The phase labels F0–F5 are those of the dated plan; the earlier assessment's F00–F20 IDs were a broad backlog, not the active phase numbering.

## 2. Feedback and closure evidence

| ID | Source and concern | Interpretation for this project | Planned response / package | Required evidence before closure | Report location | Initial state |
|---|---|---|---|---|---|---|
| FB01 | Draft feedback: unclear necessity and gaps | A technically justified pipeline does not, by itself, demonstrate an unmet catalogue-access need. | Identify concrete tasks, verify domain evidence and fairly compare existing access methods. F0 frames evidence needs; research/writing runs alongside F1–F3. | Citable domain/previous-work evidence, actual observed comparison, and a requirement-to-design link. No assumed superiority. | Introduction; Literature review; Design audiences | OPEN |
| FB02 | Draft feedback: workflow organisation / musical recommendations ambiguity | The assessed report describes a read-only access layer; the feedback's cause is unknown. Do not pivot to a recommendation system. | Explicitly identify the template and exclusions; Javier may seek tutor clarification. | Consistent framing across introduction, objectives, application and conclusion; any clarification retained as actual correspondence, not invented. | Introduction; scope | OPEN |
| FB03 | Draft feedback: research question and objectives could be better formulated | Final objectives need measurable outcomes without rewriting what earlier evaluation questions originally were. | Review the provisional question/objectives in §3 below and link them to an evaluation protocol. | Dated scope decision, original-vs-refined distinction, evaluation measures and final objective-by-objective findings. | Introduction; Evaluation; Conclusion | OPEN |
| FB04 | Draft feedback: inaccurate schemes; preliminary feedback: more useful visuals | Existing visuals need accurate geometry and meaning, not just more images. | Update model/flow diagrams after F2–F3; inspect final PDF at reading size. | Final code/model comparison, editable figure sources and visual inspection with no overflow/crossing-label ambiguity. | Design; Implementation | OPEN |
| FB05 | Preliminary feedback: deeper code explanation; prototype bugs/flaws | Explain consequential modelling and engineering decisions, and correct misleading behaviour. | Reproduce and repair classification, title-policy and failed-reimport issues; explain chosen alternatives and regressions. F0 investigation; F1 repairs. | Source-located examples, regression evidence, actual implementation diff and rationale. | Design policies; Implementation | OPEN |
| FB06 | Draft feedback: project should be upgraded; template: meaningful model complexity | A useful source/item pathway is the principal bounded feature upgrade. | F0 resolves ownership and minimum schema; F2 implements; F3 exposes it in API/UI. | Real source examples preserve supported relationships, item/repository context and useful user-visible information; source-based checks. | Design model; Implementation; Evaluation | OPEN |
| FB07 | Draft/preliminary feedback: wider technical evaluation, positive/negative/edge cases | Existing evidence is substantial but has domain gaps and an incomplete corrected API comparison. | Keep old matrix; add classification/title/source domains and fresh cases. Complete API contract/evaluation, rollback/input cases and bounded operational checks. F0–F4. | Versioned protocol, independent expectations, actual outcomes with denominators, failed/blocked cases, and tests that distinguish source fidelity from API exposure. | Evaluation | OPEN |
| FB08 | Earlier feedback: thorough usability testing; draft §5.6 records three interface issues | Instrument abbreviations, same-title differentiation and search/filter distinction need an implemented and tested response. | F3 interface work, followed by F4 task evaluation where ethically feasible. | Build-specific task outcomes, independent/assisted dispositions, errors, observations, participant-context limits and actual consent arrangements. | Design interaction; Evaluation | OPEN |
| FB09 | Draft feedback: better presentation and deeper interpretation of results | More metrics help only when they answer the objectives and support the conclusions. | Present historical baseline, August correction and new final release separately; analyse results by domain. | Reconciled tables, explicit sample/denominator/measurement definitions, threats to validity and balanced objective-level conclusions. | Evaluation; Conclusion | OPEN |
| FB10 | Current instructions: proper citations and justified decisions; general class feedback: critical literature | The draft already compares approaches. Strengthen evidence of task gaps and design consequences; do not replace it with source-by-source description. | Verify important original publications, compare alternatives on relevant tasks and explain what follows for design. Parallel report work. | Primary-source verification notes, accurate claim/source links and a consistent reference list. | Literature review; Design | OPEN |
| FB11 | Current instructions: publicly viewable repository; audit: reproduction gaps | A public working-directory ZIP is not a reproducible or privacy-safe release. | Fix setup/quality gates in an approved package; distinguish fixtures/official inputs; maintain scripts and sanitised evidence; clean-clone check. F1/F5. | Actual documented setup/import/test sequence, pinned input identity and authenticated-independent public access check. | Implementation; repository link; README | OPEN |
| FB12 | Preliminary feedback: sped-up, overlong video; current instructions: 3–5 minutes and own voice | The final video is a separate student-produced deliverable. | Javier records and checks it within protected delivery time. No AI-generated video construction material is supplied in this kit. | Actual duration, own spoken explanation, working-program demonstration and consistency with the submitted release. | Submission audit, not a fabricated report result | OPEN |
| FB13 | Current instructions: six chapters and strict limits | Current instructions take precedence over older repository word budgets. | Check chapter and overall word counts, template identity and final completeness. | Actual counts using stated exclusions: maxima 1000/2500/2000/2500/2500/1000; total ≤10500. | Whole report | OPEN |

## 3. Working question and measurable objectives — provisional

These refine the already approved catalogue-exploration direction. They are not claims that these words appeared in the original proposal, nor that the final outcomes are known.

**Working main question:** To what extent can a source-traceable relational representation support identified thematic-catalogue exploration tasks while preserving the selected distinctions needed to interpret the results correctly?

| Objective | Proposed final outcome | Evidence needed | Unresolved before final protocol |
|---|---|---|---|
| O1 — justified access tasks | Establish a small set of catalogue tasks and explain why the selected access layer is worth building. | Domain/previous-work evidence, a fair task-based comparison and explicit limits of any late-stage participant input. | Which audience/task has the strongest support? What can the comparator actually do? |
| O2 — accountable transformation | Account for each selected corpus input, retain stable supported identities, and show failures without corrupting the last valid data. | Full input reconciliation, identity/re-import/rollback checks and latest-attempt visibility. | Exact identity and unsupported-input policy; historical-data migration implications. |
| O3 — meaningful selected semantics | Correct work classification/title handling and expose a bounded source-description/item pathway with appropriate context. | Source assertions with locators, typed-title/classification tests, relationship integrity and final domain-level fidelity results. | F0 source model, supported patterns, title display rule and fallback. |
| O4 — predictable access | Expose the declared information through a documented, consistently validated, ordered and paginated read-only API and usable HTML workflows. | Independent API/DB comparisons, route/parameter/error tests, all-page accounting and HTML checks. | Final contract and ordering/validation rules, set before final measurement. |
| O5 — evaluated user workflows | Assess whether people can find/disambiguate works and interpret the implemented musical/source information. | Consented task-based results, errors/assistance, descriptive timing/ratings, observations and limitations. | Feasible sample, task wording, assistance rules, success criteria and comparator arrangement. |
| O6 — reproducible handover | Deliver a report and public repository that describe and reproduce the identified release. | Clean-clone check, current README, maintained scripts, sanitised evidence, accurate figures and claim audit. | Exact public repository URL, corpus-distribution approach and portal cutoff/time zone. |

Set reasonable success criteria before final evaluation, after reviewing the actual supported scope. Do not select thresholds after observing results. Do not infer overall fidelity from a small uneven purposive assertion matrix, performance from one elapsed run, or broad usability from a convenience sample.

## 4. Evidence still needed for the argument

**Need rather than implementation preference.** Extract what the existing cited work actually says about catalogue tasks. Claims about current interfaces require a recorded current inspection; they are not established by the template's historical description. The F0 package does not perform that external comparison.

**Alternative rather than strawman.** Compare a fair existing access method or a transparent baseline. “Uses XML” is not evidence that it has no usable interface. “Our database returns JSON” is not evidence that another tool lacks an API.

**Selected complexity rather than table count.** Show why a source description and held item need separate identities/relationships and what the user can do with them. The F0 model proposal should supply concrete evidence for this argument.

**Achievement rather than a plan.** For every objective, final reporting needs actual findings and limits. If a follow-up study or technical check is not performed, state that; keep earlier findings associated with the version originally tested.

## 5. Human-dependent items — not executed by this package

| Item | Current status | Immediate owner action |
|---|---|---|
| Exact 28 September cutoff and time zone | NOT CONFIRMED in the supplied deadline message | Javier checks the submission portal and records the actual cutoff. |
| Availability for 24–25 September user sessions | NOT CONFIRMED | Javier begins outreach for approximately 4–6 adults; this is a recruitment target, not a course minimum. |
| Applicable ethics/consent arrangements | NOT VERIFIED for the proposed new sessions | Javier confirms applicable arrangements and obtains informed written consent before sessions; private records stay out of public artifacts. |
| Tutor clarification of the workflow/recommendation comment | NOT REQUESTED by this package | Clarify if feasible without pausing independent technical work. |
| Public code repository and logged-out accessibility | NOT VERIFIED | Establish the exact intended repository and review privacy/reproducibility before release. |

## 6. Update log

| Date | Item | Observation/action | Evidence and version | Status change |
|---|---|---|---|---|
| 2026-09-19 | Register initialisation | Created a traceability seed from supplied feedback, instructions, draft and approved plan. No final-iteration results supplied. | This package v1.0 | All final-iteration feedback rows OPEN |

Append actual F0 findings here or in the reviewed F0 copy. Never replace this initialisation row with invented execution results.

## Source pointers

- `draft report project feedback.txt`: strengths, then gap/necessity/objective/diagram criticism and wider/deeper evaluation request.
- `preliminary report feedback.txt`: video constraint failure, code/visual explanation, edge scenarios, spike stories and technical/usability testing.
- `Working_with_Works_Final_Report_Draft.pdf`: §§3.3–3.5, 4.4–4.5, 5.1–5.6 distinguish current capability and evidence gaps.
- `project template.pdf`: PDF pages 1–3, printed pages 10–12; portal, model choice, exploration, API and meaningful catalogue complexity.
- `instructions.txt`: chapter/total limits, public repository, working video and review criteria.
- `all_course_materials.txt`: consent/privacy, writing throughout development, critical comparison, and final evaluation of achieved aims.
- Approved `Working_with_Works_September_19_28_Delivery_Plan.md`: narrowed sprint and phase sequencing.


## 7. F0 observation appendix — 19 September 2026

This reviewed-copy candidate preserves the complete initial seed above byte for byte. The observations below append evidence; they do not revise earlier findings or close any feedback item. Static/source inspection, historical summary reads, runtime prerequisite checks and future work remain distinct. Paths beginning `audit/` and `source/` refer to the allowlisted F0 review evidence; `F0_completion.md`, `F0_checks.json`, `F0_source_model_proposal.md` and `F0_report_notes.md` are the accompanying new F0 documents.

The draft feedback acknowledges clear goals, template, justification, research question/objectives, format/conversion discussion, architecture, testing and citations; preliminary feedback calls the literature review comprehensive. These strengths remain part of the record. The requested improvements below must not be rewritten as a claim that no justification, research or testing previously existed.

| ID | Actual F0 observation / evidence pointer | Current F0 status; remaining evidence before closure |
|---|---|---|
| FB01 | The supplied template and approved scope describe catalogue exploration and a web API. F0 inspected implementation/source evidence, not a current external-access comparator or domain need. `F0_report_notes.md`, framing / evidence still needed. | OPEN. Verify citable domain evidence and a fair task comparison; do not infer superiority from relational tables or JSON output. |
| FB02 | Routes expose index/show only; the template/approved plan define a read-only catalogue portal. Nothing inspected establishes a recommendation requirement or explains the tutor's wording. `config/routes.rb:4–8`; `F0_report_notes.md`. | INVESTIGATING. Keep consistent framing and retain actual clarification if sought. No tutor message was sent. |
| FB03 | F0 links specific gaps to provisional O2–O4/O6 and preserves O1/O5 evidence needs. These are refined measurable directions, not the original wording or achieved final outcomes. `F0_report_notes.md`. | INVESTIGATING. Approve final measurable objectives/protocol prospectively, then report actual objective-level results. |
| FB04 | Current flat `SourceReference` and source/item proposal are different model states; creating a final diagram now would risk describing unimplemented relations. `audit/static_audit.md`; `F0_source_model_proposal.md`. | OPEN. Update figures after implementation stabilises and visually inspect final output. No F0 diagram/render result is claimed. |
| FB05 | Source-located classification contamination and CNW 277 policy mismatch are independently inspected; path/shape and failed-reimport behavior have code traces. Historical 277-04 remains unchanged. `audit/static_audit.md`; `audit/static_facts.json`; `source/selected_examples.md`. | INVESTIGATING. Approve policies, implement F1 fixes and targeted regressions, then explain actual decisions. Static failed-reimport prediction is not a runtime reproduction. |
| FB06 | Fresh census has 2,148 manifestation / 1,370 item nodes; current source selectors find zero candidates. Separate descriptions/items and explicit context are justified by inspected source patterns, not by table counts alone. `source/source_profile.json`; `F0_source_model_proposal.md`. | INVESTIGATING. Recommended scope/fallback awaits review and end-to-end implementation/evaluation. Structural presence is not semantic completeness. |
| FB07 | Existing source has 58 active test declarations; historical matrices retain 83 rows each and corrected API cells remain not evaluated. F0 runtime prerequisites allow declared Ruby/Bundler/dependencies, but local DB guards are blocked; no fresh Rails/import/API run. `F0_checks.json`; `audit/static_audit.md`; `audit/static_facts.json`. | INVESTIGATING, with runtime execution BLOCKED. Resolve safe local database access, run guarded existing suite and small API experiment, then complete independent final protocol. Do not recycle 58/269 as a fresh result. |
| FB08 | Public historical summary describes same-title, abbreviation and search/filter issues. Current HTML has catalogue columns, stored instrumentation strings and separate search/filter fields; their presence does not establish that the issues are resolved. `docs/report_evidence/phase2_usability_results.md`; `audit/static_audit.md`. | OPEN. F3 implementation and ethically conducted build-specific F4 tasks remain. No private participant data was read and no new findings are claimed. |
| FB09 | Historical counts remain differentiated from current static observations and blocked runtime. The old compound title assertion remains incorrect under its frozen policy. `F0_report_notes.md`; `audit/static_facts.json`. | INVESTIGATING. Later presentation must keep versions, domains/denominators, omissions and threats to validity explicit; no overall catalogue-accuracy percentage follows from the purposive matrix. |
| FB10 | F0 creates explicit unresolved task-gap, display-policy and ownership questions. No external literature retrieval or verification occurred under this package's local-only boundary. `F0_report_notes.md`, evidence still needed. | OPEN. Verify primary-source claims and explain design consequences in later authorised work; do not backdate late research. |
| FB11 | `bin/setup` can install and clears tmp/logs; CI invokes setup, missing `bin/importmap` and seed replant. Tests delete/import data on their selected target. A selective exact application copy was prepared, but guarded DB prerequisites blocked execution. `audit/static_audit.md`; `F0_checks.json`; `F0_completion.md`. | INVESTIGATING. Fix reproduction in a later approved package; complete actual fresh-clone/import/test/access checks. F0 archive is a review artifact, not a public release. |
| FB12 | Current instructions require a 3–5 minute non-sped-up working-project video with the student's spoken explanations; course excerpt excludes AI video construction material. No video work occurred. Supplied `context/instructions.txt`, `context/course_guardrails_excerpt.txt`. | OPEN. Javier records and verifies the final deliverable. No script, slide or narration asset supplied by F0. |
| FB13 | Six chapter maxima and strict total are retained (1000/2500/2000/2500/2500/1000; total 10500). No final report word-count audit occurred. Supplied `context/instructions.txt`. | OPEN. Count the actual final report under the stated exclusions and check completeness. |

### F0 objective links and important unresolved choices

| Objective | F0 contribution | Not established by F0 |
|---|---|---|
| O1 | Clarifies catalogue-exploration framing and need for fair task/domain evidence. | Unmet need, superiority over another interface or current external feature comparison. |
| O2 | Traces path identity, rollback/log visibility and zero-input behavior; proposes scoped identity/shape policy. | Executed idempotency/rollback under the new policy, full input accounting or a changed importer. |
| O3 | Profiles current official input, inspects six varied development examples, distinguishes classification/title/source/item defects and proposes a bounded model/fallback. | Implemented source semantics, general MEI/FRBR compliance or final-evaluation fidelity. |
| O4 | Inspects current API/UI; preserves independent expectation and database-guard requirements. | Completed F0 request/comparator/negative-control run, pagination/error contract or usability of a future source screen. |
| O5 | Uses the already public historical summary to retain known design issues. | Recruitment, ethics confirmation, new sessions or final participant outcomes. |
| O6 | Establishes F0 checks/preservation/review documents and identifies unsafe setup assumptions. | A corrected release process, public access verification, final report audit or verified submission cutoff. |

The unresolved implementation choices are the scoped document/work identity and collision policy; title display/search rule; supported work-classification representation; source-to-expression association boundary and fallback; truthful missing/unsupported/unresolved presentation; and database prerequisites for executing the isolated suite/harness. Exact proposed policies, effort and the 21 September scope-reduction trigger are in `F0_source_model_proposal.md`. Global work `xml:id` alone is unsafe because it repeats across documents. Neither planned fix nor schema proposal closes a feedback item.

### Appended update log

| Date | Item | Actual observation/action | Evidence/version | Status change |
|---|---|---|---|---|
| 2026-09-19 | F0 local static/source investigation | Inspected current implementation and official XML using scratch read-only diagnostics; retained historical evidence and all original feedback. | `audit/static_audit.md`, `audit/static_facts.json`, `source/source_profile.json`, `source/selected_examples.md`; actual HEAD and preservation in `F0_completion.md`. | FB02/03/05/06/07/09/11 INVESTIGATING; none CLOSED. |
| 2026-09-19 | F0 runtime prerequisite boundary | Declared runtime/dependencies available; local DB prerequisite probes blocked. Suite/import/API experiment did not run and no new DB was created. | `F0_checks.json` actual commands/outcomes. | Runtime execution for FB07/11 BLOCKED; no application-failure or API-success claim. |
| 2026-09-19 | F0 report continuity | Added provisional design reasoning, evidence links and explicit remaining domain/literature/participant/release requirements. | `F0_report_notes.md`, `F0_source_model_proposal.md`. | All future implementation/evaluation closure remains open. |


## 8. Proposed F1 update — not applied to the original register

This file preserves the current original register above and proposes the following new observations. It does not close feedback automatically or rewrite the F0 observations.

| Item | New observed evidence | Proposed status and remaining work |
|---|---|---|
| FB05 | Old classification/title/hidden-failure defects reproduced in p0/r01; corrected direct classifications, typed titles and transactional history validated in the revised suite and independent six-source SQL/API/HTML observations. F1_decisions.md and the actual patch explain identity, source ownership and policy choices. | IMPLEMENTED / AWAITING WIDER EVALUATION. Incorporate reasoned explanation and evaluate broader records; source descriptions/items remain F2. |
| FB07 | Fresh unchanged 58/269 and revised 96/781 suites; frozen 25-case protocol; six-record smoke, 222 checks and 21 requests; meaningful rollback/input/identity/HTML cases; independent comparator controls. Old 83-row matrices and 277-04 remain immutable. | PARTLY IMPLEMENTED / AWAITING WIDER EVALUATION. This is a bounded F1 regression set, not full final source/API evaluation, reserved records, full corpus or usability validation. |
| FB11 | Maintained explicit isolated validation runner; official/demo profiles; guarded new databases and source/hash manifests; allowlisted private review ZIP with readback checks. Disposable user-authorized PostgreSQL instance stopped and retained. | PARTLY IMPLEMENTED / AWAITING F5. Original setup/CI hazards, clean-clone reproduction and authenticated-independent public-access check remain open. No publication occurred. |

| Date | Scope | Actual outcome | Evidence | Status implication |
|---|---|---|---|---|
| 2026-09-19 | F1 foundation/correctness | Fresh prerequisite gate passed before implementation. Final source build passes all runtime cases; preservation and archive result are recorded in F1_checks.json and the adjacent ZIP validation. Earlier nonpassing attempts remain retained. | F1_acceptance_results.csv; evidence/commands.jsonl; evidence/failure_dispositions.md; validation/build_5.json | No feedback item automatically closed; F2/F3/F4/F5 remaining work is unchanged. |
