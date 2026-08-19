# Phase 2 formative usability results

## Result and scope

The predeclared formative benchmark was met, but the small exercise also exposed three bounded usability issues. Seven of the nine planned task attempts were completed independently. The other two were completed: one after the permitted neutral prompt and one after task-specific help. There were no non-completions, technical interruptions, withdrawals or missing ease ratings.

Each task met the task-level rule of at least two independent completions: U01 general search had two of three, U02 catalogue filtering had three of three, and U03 work-detail interpretation had two of three. The overall rule of at least six independent completions across nine planned attempts was also met, with seven. These are predeclared formative reporting thresholds, not population estimates or evidence of general usability.

The assisted outcomes matter alongside the benchmark. In U01, one participant needed the neutral prompt after difficulty distinguishing two works titled `Duet`. In U03, one participant needed a clarification to interpret the instrumentation abbreviations. The results therefore support local readiness for the three bounded workflows while identifying interface language and result-comparison points for further design review.

This report aggregates three pseudonymous convenience-sample participants (`P1`–`P3`). It evaluates only the verified local HTML workflows on the fixed demonstration dataset. It does not reopen or complete the frozen post-correction API comparison, and it does not establish accessibility, scholarly fidelity, security, performance, deployment readiness, production readiness or general usability.

## Method and evidence completeness

The committed `phase2_usability_protocol.md` defined three participants, three rotated tasks and nine planned participant-task pairings. Each private form passed the predeclared privacy, consent, enrollment, rotation and field-consistency gates before aggregation. All three adults confirmed consent, enrolled, completed all three task attempts and permitted retention by having no withdrawal. The three private forms remained ignored and were not copied into the review bundle.

All nine dispositions were `attempted`; none was `not_attempted_after_withdrawal`, and no pairing was unavailable because of withdrawal without retention. The five mutually exclusive completion statuses reconcile exactly to the nine attempts. All active times were between 0 and 180 seconds, all count fields were non-negative integers, and all nine ease ratings were obtained. U03 contained five participant-reported values on every form; these matched the observer key without substituting an observer conclusion for a missing response.

The analysis is descriptive. Active time includes reading and think-aloud behavior but excludes technical-pause time; no technical-pause seconds occurred. Medians use the central sorted value because every reported set contains an odd number of observations. No time or ease value was excluded or imputed. Issue frequency is the number of distinct participants whose retained record contained the normalized issue label, not the number of comments or actions.

## Participant sample

The sample comprised three consenting adults who had not developed or technically evaluated the application. Two sessions were remote and one was in person. Only marginal counts for the optional broad categories are reported; combining these categories into participant-level profiles would add identification risk without analytical value.

| Broad category | Reported values across three participants |
|---|---|
| Web search/filter use | frequent: 2; occasional: 1; infrequent: 0; prefer not to say: 0 |
| Music/catalogue familiarity | none: 1; some: 1; substantial: 1; prefer not to say: 0 |
| Technical web-application experience | none: 1; some: 1; substantial: 1; prefer not to say: 0 |

This category spread gives limited formative contrast, but three participants cannot support subgroup comparisons. The categories are context for interpretation rather than explanatory variables.

## Task-level outcomes

All participants reached a valid completion, but two outcomes required support. The table preserves all nine observations, including the neutral-prompt and task-specific-help cases. Active seconds are contextual observations rather than comparative performance measures.

| Participant | Order | Task | Disposition | Completion status | Active seconds | Pause seconds | Wrong turns | Neutral prompts | Task-specific help | Ease (1–5) | Sanitized issue |
|---|---:|---|---|---|---:|---:|---:|---:|---:|---:|---|
| P1 | 1 | U01 | attempted | completed independently | 61 | 0 | 1 | 0 | 0 | 4 | Same-title result differentiation |
| P1 | 2 | U02 | attempted | completed independently | 26 | 0 | 0 | 0 | 0 | 5 | — |
| P1 | 3 | U03 | attempted | completed with task-specific help | 112 | 0 | 0 | 0 | 1 | 3 | Instrumentation abbreviations |
| P2 | 1 | U02 | attempted | completed independently | 54 | 0 | 1 | 0 | 0 | 3 | Search/filter distinction |
| P2 | 2 | U03 | attempted | completed independently | 86 | 0 | 0 | 0 | 0 | 3 | Instrumentation abbreviations |
| P2 | 3 | U01 | attempted | completed independently | 34 | 0 | 0 | 0 | 0 | 4 | — |
| P3 | 1 | U03 | attempted | completed independently | 31 | 0 | 0 | 0 | 0 | 5 | — |
| P3 | 2 | U01 | attempted | completed with neutral prompt | 78 | 0 | 1 | 1 | 0 | 3 | Same-title result differentiation |
| P3 | 3 | U02 | attempted | completed independently | 19 | 0 | 0 | 0 | 0 | 5 | — |

The completion-status totals were seven `completed_independently`, one `completed_with_neutral_prompt`, one `completed_with_task_specific_help`, zero `not_completed`, and zero `technical_interruption`. U01 accounted for the sole neutral prompt and two of the three wrong turns. U02 accounted for one wrong turn. U03 accounted for the sole task-specific-help instance. No participant requested a task-wording repetition.

## Timing and ease results

U02 had the shortest median active time and highest median ease rating in this sample; U03 had the longest median and the lowest. These observations are not controlled performance comparisons. U01 and U02 reused CNW 417, task order rotated, and prior exposure could make a later task easier.

| Task | Individual active seconds (P1, P2, P3) | Median | Range | Individual ease ratings (P1, P2, P3) | Ease median | Ease range |
|---|---|---:|---|---|---:|---|
| U01 | 61, 34, 78 | 61 | 34–78 | 4, 4, 3 | 4 | 3–4 |
| U02 | 26, 54, 19 | 26 | 19–54 | 5, 3, 5 | 5 | 3–5 |
| U03 | 112, 86, 31 | 86 | 31–112 | 3, 3, 5 | 3 | 3–5 |
| Overall | nine values | 54 | 19–112 | nine values | 4 | 3–5 |

The overall medians summarize heterogeneous tasks and are labelled contextual only. All nine numeric time and ease observations are included; there are no missing-rating exclusions. Think-aloud, reading, participant experience and carry-over can all affect these values.

## Observed issues and severity

Three normalized issue types were retained: one `major` and two `minor`. Instrumentation-abbreviation confusion recurred across two distinct participants and therefore met the predeclared `major` rule. No issue met the `critical` rule of preventing at least two participants from completing a task.

| Issue | Task | Distinct participants | Severity | Observed basis |
|---|---|---:|---|---|
| Same-title result differentiation | U01 | 2 | minor | Two participants took a wrong turn when distinguishing the two `Duet` results; both recovered and completed. One used the neutral prompt. |
| Instrumentation abbreviations | U03 | 2 | major | Two participants showed uncertainty around `pf.` and `vl.`. One completed after task-specific clarification; the other completed independently. |
| Search/filter distinction | U02 | 1 | minor | One participant initially used the general-search control, then recovered independently and used the catalogue filter. |

The instrumentation issue reached `major` because abbreviation-related confusion recurred across two distinct participants. The protocol operationalizes recurrence by distinct affected participants and defines no separate within-participant confusion-episode measure. One participant required task-specific help and the other completed independently; the issue was not `critical` because it prevented neither participant from completing U03. Same-title result differentiation remained `minor`: only one associated sanitized task row explicitly recorded confusion, while the other recorded delay and a wrong turn. Search/filter distinction remained `minor` because it affected one participant. Severity describes this observed sample only and must not be generalized to other users or tasks.

## Post-session feedback themes

Paraphrased feedback reinforced the task observations without adding new measured outcomes:

- Perceived ease depended on narrowing cues, familiarity with catalogue information and task order. One participant explicitly found a later task easier after becoming familiar with the same target, which is consistent with the declared carry-over risk.
- Two participants found the instrumentation abbreviations unclear. The bounded improvement theme was to pair abbreviations with plain-language wording.
- Two participants highlighted the difficulty of comparing identically titled search results. Their feedback pointed toward making catalogue information more visually prominent in result rows.
- One participant suggested clearer examples or cues to distinguish general search from catalogue-number filtering.

These are short qualitative themes derived from paraphrased responses. They are not attributable quotations, frequency-weighted attitudes or evidence that every participant preferred the same change.

## Predeclared benchmark

The benchmark was fully evaluable and met.

| Benchmark component | Observed independent completions | Required | Result |
|---|---:|---:|---|
| U01 | 2 of 3 | at least 2 | met |
| U02 | 3 of 3 | at least 2 | met |
| U03 | 2 of 3 | at least 2 | met |
| Overall | 7 of 9 planned attempts | at least 6 | met |

There was no withdrawal or technical interruption to alter evaluability. The denominator remains the predeclared nine planned pairings. Meeting the threshold means only that this convenience sample satisfied the project’s bounded formative criterion; it is not an overall usability score or a population estimate.

## Critical evaluation and limitations

The result supports a narrow operational conclusion: the three tested workflows were completable in the retained demonstration state, and most attempts were independent. It does not show that the interface is generally usable. Three convenience-sample adults provide too little evidence for statistical generalization, subgroup inference or reliable issue prevalence.

The rotation reduced a fixed-order bias but could not eliminate learning effects. U01 and U02 used CNW 417, so experience from the first encountered workflow could affect the second. The observed timing also includes concurrent think-aloud and reading; differences must not be attributed causally to search versus filtering. The overall time median combines different task types and is descriptive only.

The exercise used one local deployment and a fixed 446-work demonstration dataset. It did not test other datasets, devices, browsers, assistive technologies, interrupted connectivity or concurrent use. U03 assessed interpretation of the displayed flattened prototype fields, not scholarly correctness or complete MEI fidelity. No API task was included, so these sessions do not complete or revise the incomplete frozen post-correction API comparison.

The exercise did not evaluate accessibility, security, performance, deployment or production readiness. Ease ratings used a custom five-point item rather than a standardized instrument. Issue severity follows the predeclared formative rules and is sensitive to this very small sample.

## Implications and bounded future improvements

The evidence supports three design questions for a later bounded iteration, not immediate claims that application changes are proven necessary:

1. Explore whether catalogue number and prefix can be made easier to compare when search results share a title, then retest the same-title selection task.
2. Explore plain-language expansions or accessible explanations for instrumentation abbreviations, while preserving the catalogue notation needed by knowledgeable users.
3. Review examples, labels or supporting cues that distinguish general search from catalogue-number filtering, then verify that any change does not make either workflow less clear.

Any implementation should be evaluated separately against the same fixed tasks and the broader technical boundaries already documented. The present evidence is sufficient to report the observed successes and friction, but not to claim a universal interface solution.
