# Phase 2 baseline-to-post-correction evaluation

## Technical summary

The unchanged baseline accounted for all 446 Royal Danish Library files, but committed 441 works and rolled back five records with cross-type identifier conflicts. The corrected import committed all 446 works with zero failures. In the unchanged 83-assertion Stage B comparison, `incorrect` classifications decreased from 15 to 1. This bounded improvement combines five assertions that gained preserved or defensibly transformed representation with the deliberate removal of contradictory mappings; many richer source structures remain omitted.

Six focused probes changed as intended: five former identifier rollbacks became committed works with both typed values, and CNW 67 no longer adopted a nested bibliography date. CNW 10's bounded namespace-removal behavior remained unchanged. Baseline API behavior was characterized through 14 completed GET requests, but the post-correction API comparison is incomplete because the evaluation harness could not safely resolve the request-context connection pool. RQ5 is therefore answered for technical import, source/database fidelity, and focused probes, but not for before/after API behavior.

These results do not establish that the prototype is fully correct, complete, production-ready, or generally MEI-compatible. Technical completion, semantic fidelity, API behavior, and later usability evidence remain separate claims.

## Fixed comparison design

The comparison preserves the frozen design: the same 446-file institutional corpus and archive checksum; the same purposive eight-record sample; the same 83 Stage B rows in the same order; a fixed denominator of 78 semantically eligible assertions plus five technical rows; and the same seven Stage C probes. Four records receive detailed review and four boundary/stress review, producing 48 detailed and 35 boundary/stress assertions. The sample is not statistically representative.

Baseline and correction executions used separate commits and fresh dedicated databases. Each state remains authoritative for its own observations. The contextual elapsed times belong to different controlled runs and are not compared as performance results. Exact tables are used instead of a chart because the measures mix files, database rows, classification states, and warning categories.

The six Stage B labels keep distinct questions separate. `Preserved` means the bounded asserted meaning remains available; `transformed as intended` means a declared normalization retains that meaning; `omitted` means non-contradictory information is absent; and `incorrect` means retained data contradicts or materially mislabels the source meaning. `Not applicable` is reserved for the five technical rows, while `blocked by import failure` remains available but unused in both matrices. Every comparison below keeps the same source locator, expected value, domain, tier, eligibility flag, and assertion order, so classification movement is not produced by changing the test.

| Evidence role | Stable evidence and identity |
|---|---|
| Frozen design | `phase2_evaluation_protocol.md`; protocol commit `548dca16f11f6f5fa82a668898dbe0d326d72f97` |
| Corpus | 446 Carl Nielsen files; archive SHA-256 `fa3ff9e3012a6a9e8d21c098105bea3be9670945bb76aa5ea46391d2c33cf8ec` |
| Baseline application and results | baseline `8b40722103acb36826a81b7bd1a90983435e9dd7`; `phase2_baseline_import_results.md`, `phase2_fidelity_matrix.csv`, `phase2_focused_probe_results.md`, `phase2_api_results.md` |
| Correction boundary | `phase2_correction_scope.md`; scope commit `584b6fa201e2d8b5e84b93d007a63204dc6bc664` |
| Corrected application and results | correction `c01bd32417dd381c15dfa351f6da8d6d7f5de11d`; `phase2_post_correction_import_results.md`, `phase2_post_correction_fidelity_matrix.csv`, `phase2_post_correction_fidelity_results.md`, `phase2_post_correction_focused_probe_results.md` |
| Consolidated evidence state | evidence HEAD `36a85ffffa51ee1f38b76bdeddcb2074e7f606d4` |

## Four bounded correction packages

The four packages address defects that could be corrected within the existing prototype while explicitly retaining deferred model boundaries.

| Package | Intended defect addressed | Observable post-correction evidence | Deliberately excluded structures |
|---|---|---|---|
| 1. Catalogue-identifier uniqueness, direct CNW selection, and bounded prefixed search | Value-only uniqueness rolled back five works; `catalogue_number` did not reliably select direct CNW identity; bounded prefixed lookup was included in scope | All five works commit; typed equal values survive without exact typed duplicates; direct CNW supplies the stored catalogue number in the five focused probes; post-correction prefixed-search behavior remains unevaluated | Arbitrary secondary-identifier search, entity resolution, filename identity, multi-work files, title display policy |
| 2. Direct attribution and date | Header editor could become composer; descendant dates could contaminate work dates | Carl Nielsen is the sole composer across 446 works; CNW 67 stores null date/year and a truthful warning | Non-composer responsibilities, provenance, structured uncertainty/bounds, title policy |
| 3. Performance events | Parent-typed performance lists produced no stored events | 4,646 bounded performance rows plus 194 explicit unsupported/empty skips reconcile all 4,840 candidates | Full participant entities and roles, uncertain-date semantics, general event ontology, benchmarking |
| 4. External-reference boundary | Internal graph/local targets were presented as external links | 458 stored targets all satisfy HTTP(S)-with-host; relation-target contradictions become omissions | Internal work/collection graph, local assets, graphics, authority or availability checks, URL dereferencing |

None of these packages claims to solve multilingual or typed titles, expression/component hierarchy, manifestation and held-item sources, richer responsibilities, or the flattened instrumentation model.

The table reports observed outcomes, not implementation intent as evidence. Package 1 changes the population available to later checks because the five formerly absent works now exist. Package 2 narrows two selectors rather than introducing a general responsibility or date model. Packages 3 and 4 add bounded rows only where the existing schema can represent them without relabelling deferred structures. This sequencing explains why complete import, fidelity changes, and continued omissions can coexist.

## Complete technical processing replaced five rollbacks

The corrected importer changed the corpus-level result from accountable but incomplete processing to 446 committed works. All five former identifier failures now commit. Storage changes must be interpreted by domain rather than treated as uniformly positive or negative.

| Measure | Baseline | Post-correction | Delta |
|---|---:|---:|---:|
| Files seen | 446 | 446 | 0 |
| Successes | 441 | 446 | +5 |
| Failures | 5 | 0 | -5 |
| Warnings | 1,391 | 1,354 | -37 |
| Composers | 1 | 1 | 0 |
| Works | 441 | 446 | +5 |
| Catalogue identifiers | 1,702 | 1,726 | +24 |
| Movements | 0 | 0 | 0 |
| Instrumentations | 1,651 | 1,686 | +35 |
| Source references | 0 | 0 | 0 |
| Performances | 0 | 4,646 | +4,646 |
| External references | 2,001 | 458 | -1,543 |
| Import logs | 446 | 446 | 0 |

Reconciliation remained complete in both states: every file has one accountable log, every success has one surviving work, failures leave no work, and checked child tables have no orphans. The five-work increase is exactly the removal of the five identifier rollbacks rather than a change in corpus size. The additional 24 identifiers and 35 instrumentations include data from those newly committed records, so their deltas should not be read as isolated schema-quality measures.

Composer attribution moved from the baseline's sampled header-editor misattribution to a corrected inventory containing Carl Nielsen across all 446 works. Performance accounting reconciles 4,840 selected candidates to 4,646 stored rows and 194 explicitly skipped empty or unsupported events. The 22 non-exact-date warnings concern retained events across 13 files; they are not additional skipped events and do not change the event denominator.

External-reference storage fell from 2,001 to 458 because the category boundary became HTTP(S)-with-host rather than every targeted relation/ref/ptr. The source contains 459 eligible HTTP(S) nodes and storage contains 458 rows after one per-work exact-URL duplicate is removed. This is not evidence that 1,543 valid external links were lost. Movements and source references remain zero because those mappings were deliberately deferred.

| Warning category | Baseline occurrences | Post-correction occurrences | Interpretation |
|---|---:|---:|---|
| `no_movements` | 446 | 446 | unchanged deferred domain |
| `no_source_references` | 446 | 446 | unchanged deferred domain |
| `no_performance_information` | 446 | 60 | now limited to true no-event files |
| `no_instrumentation` | 39 | 39 | unchanged |
| `missing_composition_date_or_year` | 6 | 7 | +1 after rejecting CNW 67's nested date |
| `no_external_references` | 6 | 138 | stricter external-link definition |
| `missing_genre_or_category` | 2 | 2 | unchanged |
| `skipped_performance_event_no_supported_direct_values` | — | 194 | not present as a baseline category |
| `non_exact_performance_date_not_stored` | — | 22 across 13 files | not present as a baseline category; event retained |

The net warning change is -37, not a count of independently corrected semantic defects. The extra missing-date warning is expected because CNW 67 no longer borrows a bibliography date; the rise in `no_external_references` reflects the narrower link definition.

## Fidelity improved in bounded areas while omissions remain

The fixed matrix records 18 changed and 65 unchanged classifications. `Incorrect` fell by 14, while `omitted` rose by nine because 13 contradictory mappings became explicit omissions and four former omissions gained preserved or transformed representation. The increase in omission is therefore not automatically deterioration, and the decrease in incorrect mappings is not an overall accuracy score.

| Classification | Baseline | Post-correction | Net change |
|---|---:|---:|---:|
| Preserved | 18 | 21 | +3 |
| Transformed as intended | 4 | 6 | +2 |
| Omitted | 41 | 50 | +9 |
| Incorrect | 15 | 1 | -14 |
| Not applicable | 5 | 5 | 0 |

| Baseline → post-correction | Assertions |
|---|---:|
| Preserved → preserved | 18 |
| Transformed → transformed | 4 |
| Omitted → preserved | 2 |
| Omitted → transformed | 2 |
| Omitted → omitted | 37 |
| Incorrect → preserved | 1 |
| Incorrect → omitted | 13 |
| Incorrect → incorrect | 1 |
| Not applicable → not applicable | 5 |

Five assertions gained preserved or defensibly transformed representation. The 13 `incorrect → omitted` transitions primarily remove false external-link mappings and non-composer responsibility claims; the internal graph and richer responsibility structures remain unmodelled.

`P`, `T`, `O`, `I`, and `N/A` below denote preserved, transformed as intended, omitted, incorrect, and not applicable.

| Frozen domain | Rows | Baseline | Post-correction | Observed change |
|---|---:|---|---|---|
| `catalogue_identifier` | 4 | P4 | P4 | unchanged preservation |
| `component_structure` | 9 | O9 | O9 | hierarchy still omitted |
| `composition_date` | 5 | P1, T4 | P1, T4 | defensible date transformations retained |
| `instrumentation` | 9 | P2, O7 | P2, O7 | partial flattened representation unchanged |
| `performance_and_relation_absence` | 1 | P1 | P1 | asserted absence retained |
| `performance_event` | 7 | P2, O5 | P4, T2, O1 | two O→P and two O→T |
| `relation_target` | 15 | P2, O3, I10 | P2, O13 | ten contradictory mappings removed |
| `responsibility` | 4 | I4 | P1, O3 | composer corrected; other roles omitted |
| `source_description` | 13 | P1, O12 | P1, O12 | manifestation/item structures still omitted |
| `technical_import` | 5 | N/A5 | N/A5 | fixed technical rows unchanged |
| `title` | 6 | O5, I1 | O5, I1 | title policy unresolved |
| `work_identity` | 5 | P5 | P5 | identity preserved |

Work identity and catalogue identifiers remain preserved. Direct composer selection corrected the bounded composer defect, but other contributor roles remain omitted. Direct work-date selection avoids nested contamination while retaining the frozen defensible date transformations. Performance representation improved materially in the sample. Internal relation targets are no longer mislabelled as external links, but their graph remains omitted.

The transition concentration clarifies the change. Four performance-event rows moved out of omission: two became preserved and two transformed. Ten relation-target rows moved from incorrect to omitted because internal targets are no longer presented as external resources. Four responsibility rows changed: the simple composer assertion became preserved, while three compound assertions became omitted because their author, dedicatee, or translator meaning still has no structured representation. Catalogue identity, work identity, component structure, source descriptions, instrumentation, and the five technical rows did not change classification.

Multilingual and typed title structure, component/expression hierarchy, and manifestation/held-item sources remain incomplete or absent. Instrumentation remains a partial flattened summary. The sole remaining incorrect assertion is CNW 277 title row `277-04`, where the selected title contradicts the frozen expected display-title meaning. Preserved and transformed counts are not combined into an accuracy numerator.

## Six focused defects changed and one bounded behavior remained stable

All seven original predictions remain valid descriptions of the baseline. Six no longer reproduce after correction; the bounded CNW 10 behavior remains stable.

| Probe | Confirmed baseline | Post-correction observation | Assessment |
|---|---|---|---|
| CNW 27 | rollback on Opus/CNW value `27` | committed work; both typed values retained | `changed_as_intended` |
| CNW 64 | rollback on CNW/FS value `64` | committed work; both typed values retained | `changed_as_intended` |
| CNW 70 | rollback on Opus/CNS value `43` | committed work; both typed values retained | `changed_as_intended` |
| CNW 81 | rollback on CNS/FS value `10` | committed work; both typed values retained | `changed_as_intended` |
| CNW 237 | rollback on CNW/CNS value `237` | committed work; both typed values retained | `changed_as_intended` |
| CNW 67 | nested `1913-04-29` / year 1913 selected | null date/year plus truthful warning | `changed_as_intended` |
| CNW 10 | namespace identity removed in bounded in-memory parse | same bounded parser behavior | `unchanged_within_probe_scope` |

CNW 10 concerns one parser-and-record observation and does not establish general MEI compatibility. Seven purposive probes are not a general correctness measure.

The five identifier probes also verify the intended invariant boundary: equal values can survive under different identifier types, while no exact `(identifier_type, value)` duplicate remains. CNW 67 establishes only that unsupported nested dates are no longer promoted to work-level fields; its null result and added warning are more truthful within the frozen mapping, not a claim that every date in the record has been scholarly adjudicated.

## API evidence is asymmetric

Baseline API evidence is complete for the frozen 14-request characterization. The index returned 441 works. All 12 list counts and ordered work-ID sequences matched independently derived database expectations, while exact list-item equality was 11/12. D03's sole mismatch was CNW 417 instrumentation order; the two-value multiset was unchanged. CNW 417 detail matched the exposed database state.

Bare catalogue search `417` matched CNW 417, while prefixed `CNW 417` returned no row. Invalid years were silently coerced rather than validated; inverted bounds returned an empty HTTP 200 result without reporting the inversion. A confirmed missing detail returned HTTP 404 HTML, and no exception escaped. These are database-exposure and API-contract observations, not official-source fidelity or usability evidence.

Post-correction evidence is incomplete. Attempts 01–03 each entered one B01 boundary, used zero within-attempt retries, and returned HTTP 200 JSON. Attempt 01 retained no finalized index count; attempts 02 and 03 retained sanitized 446-row arrays. No index reconciliation was finalized, zero detail requests were made, and no row-level API value or API/database equality was established. Collection ended because the evaluation harness could not safely identify the request-context connection pool. This is an evaluation-harness limitation, not evidence of an application or API failure. All 83 post-correction API-observation cells remain `not_evaluated`.

The retained 446-row response shapes from attempts 02 and 03 are deliberately not projected into Stage B rows. Without a finalized sample-presence, field, child-collection, and database reconciliation, they cannot support claims about corrected ordering, filtering, detail completeness, or semantic exposure. Preserving the failed harness attempts and terminating collection is therefore a limitation of the evidence, not a negative API test result.

Consequently, the corrected evaluation does not confirm prefixed CNW search, child ordering, or detail exposure. The baseline and post-correction API states must not be presented as a completed before/after comparison.

## Answers to the frozen research questions

**RQ1 — technical corpus processing.** At baseline the answer is qualified: all 446 inputs were accounted for, but five rolled back. After correction, all 446 files committed with one work and one accountable log each, so technical processing is complete for this corpus release. This does not establish semantic completeness.

**RQ2 — fixed-sample semantic fidelity.** The six-category rubric answers RQ2 for the purposive eight-record, 83-assertion sample: 21 preserved, six transformed as intended, 50 omitted, one incorrect, and five technical/not-applicable rows after correction. The domain table retains the omissions and fixed denominator rather than generalizing beyond the sample.

**RQ3 — focused predictions.** All seven frozen predictions were confirmed at baseline. Post-correction observation found six intended changes and one unchanged bounded namespace behavior; the original predictions were not rewritten.

**RQ4 — API exposure.** Baseline API/database behavior was characterized through 14 requests, including ordering, filtering, coercion, and error-shape limitations. Post-correction API exposure was not successfully reconciled and remains incomplete.

**RQ5 — change after correction.** RQ5 is answered for corpus completion, fixed-sample source/database fidelity, and the seven focused probes. It is not answered for before/after API behavior because no corrected index or detail reconciliation was finalized.

## Remaining limitations and next boundary

The evidence remains bounded: the sample is not statistically representative; no overall accuracy percentage is calculated; and the work does not establish general MEI compatibility or complete scholarly validation. Movements/components, manifestation and held-item hierarchies, non-composer responsibilities, and internal catalogue graphs remain unmodelled. Title policy remains unresolved, and instrumentation remains flattened and incomplete.

API validation, deterministic tie ordering, and JSON error contracts remain unresolved, while the post-correction API comparison is incomplete. Configured CI and production Redis/Action Cable and Solid Queue concerns remain separate. Usability, accessibility, security, performance, and deployment readiness have not been evaluated.

The comparison is descriptive and bounded to one institutional corpus release and the frozen purposive samples. It does not validate every URL, every nested catalogue value, PNG incipits, other composer subtrees in the archive, or the scholarly adequacy of every normalization. Database-row presence is not equivalent to user comprehension, discoverability, or catalogue authority.

The next evidence boundary is future work, in order:

1. Prepare a stable demonstration state while retaining the incomplete API-comparison limitation.
2. Design and conduct the separate three-participant formative usability exercise.
3. Preserve the usability evidence separately from importer and fidelity evidence.
4. Only then begin the six-chapter course-report draft.

None of these future activities is reported as completed here.
