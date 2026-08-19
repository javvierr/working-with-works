# Phase 2 formative usability protocol

## Status and purpose

This protocol is predeclared before any participant session. It defines a small task-based formative exercise with exactly three adults to examine whether users can search, filter and interpret the verified local HTML interface. The preliminary criterion is that most tasks should be completed without explanation and that confusing labels or controls should be identified.

This is a convenience sample, not a representative or statistically generalizable study. The exercise is separate from the frozen Phase 2 technical and API evaluation: it does not reopen that evidence, complete the post-correction API comparison, or establish accessibility, scholarly fidelity, security, performance, deployment readiness or production readiness. HTML readiness is not itself a usability result. No usability session has begun.

## Evidence basis and boundaries

The task states and observer keys below are bounded to the verified behavior in `phase2_demo_readiness.md`:

- general search for `Duet` displayed two database-expected works with working detail navigation;
- the catalogue-number filter `CNW 417` displayed the unique intended `Duet` result with working detail navigation;
- the CNW 63 detail page displayed the verified title, composer, catalogue number, instrumentation and substantive performance content.

The post-correction API comparison remains incomplete because of the documented evaluation-harness limitation. No task uses the JSON API, source code, external links, or an unsupported source structure. The CNW 63 performance content is a bounded flattened prototype representation and is not treated as complete MEI fidelity.

## Participants and privacy

The convenience sample contains exactly three consenting adults, identified only as `P1`, `P2` and `P3`. Participants must be able to read the interface language and use an ordinary web browser. They must not have been involved in developing or technically evaluating the application. Specialist musical, catalogue or technical expertise is not required, and varied experience is acceptable.

Only broad, optional experience categories are recorded:

- familiarity with web search and filter interfaces: `infrequent`, `occasional`, `frequent` or `prefer_not_to_say`;
- familiarity with music or catalogue interfaces: `none`, `some`, `substantial` or `prefer_not_to_say`;
- technical experience with web applications: `none`, `some`, `substantial` or `prefer_not_to_say`.

Names, contact details, employer names and other direct identifying information must not be collected. Participation is voluntary; a participant may decline a question or stop at any time. The exercise evaluates the interface, not the participant. No sensitive information is requested. No audio, video or screen recording occurs by default, and this protocol authorizes no recording. Consent is recorded only as `confirmed` or `not_confirmed`. This protocol makes no claim of formal ethical approval.

If consent is not confirmed, the session stops before background questions or tasks and that person is not enrolled as one of the three participants. No reason for declining is requested, and another prospective participant may be invited in their place. Enrollment begins when the first task instruction is read. A prospective participant who stops after confirming consent but before that instruction is read is likewise not enrolled: stop without asking for a reason, destroy the prospective private form and invite another prospective participant if needed.

An enrolled participant may withdraw at any time. The moderator stops immediately, does not ask for a reason, and asks only whether the participant permits the anonymous observations already recorded to be retained. If permission is confirmed, observations collected before withdrawal are retained. If permission is declined or unclear, the participant's private raw observation form is destroyed and only a non-identifying aggregate note is retained stating that one enrolled participant withdrew and did not permit data retention. An enrolled participant is not replaced after their first task begins; the resulting incomplete evidence is reported honestly.

## Session structure

Each session targets approximately 15–20 minutes:

| Stage | Indicative duration | Procedure |
|---|---:|---|
| Information and consent | 2 minutes | Provide the short information statement, answer procedural questions and record consent as confirmed/not confirmed. |
| Optional background categories | 1 minute | Offer the three broad categories; allow `prefer_not_to_say`. |
| Three task attempts | 9–12 minutes | Reveal one task at a time, use concurrent think-aloud, apply the three-minute ceiling and collect an ease rating immediately after each attempt. |
| Post-session questions | 3–5 minutes | Ask the three predeclared questions and record paraphrased responses. |

Concurrent think-aloud means asking the participant to say what they are looking for, expecting or finding confusing while acting. Silence is not itself a failure and is not a wrong turn.

## Moderator procedure

Before a session block, the moderator must start or verify the retained demonstration state using the ignored private launcher documented in `phase2_demo_readiness.md`. The moderator must not migrate, seed, import, change the application, or use an API endpoint. After the session block, the moderator stops the server.

For every task, the moderator must:

1. reset the interface to the stated starting state, with no filter or browser-history residue that reveals the answer;
2. reveal only the current task and read its instruction verbatim;
3. avoid explaining labels, controls, search behavior or expected results;
4. repeat the task wording verbatim if requested, without counting that repetition as assistance;
5. when necessary, use only the neutral prompt `“Please continue in the way that seems most natural”` and record each use;
6. record any further directional or task-specific assistance separately;
7. pause timing during a technical interruption and record the interruption separately from participant difficulty;
8. avoid following external links or opening API routes.

A brief technical interruption may be resolved and the same attempt resumed, with paused seconds excluded from elapsed task time. If the interruption prevents a valid outcome, the attempt is retained as `technical_interruption`; it must not be relabelled as user failure or silently deleted.

## Tasks and observer-only completion rules

### U01 — General search

**Starting state:** `/works` with all filters empty.

**Participant instruction:**

> “Using the general search, find and open the work titled ‘Duet’ with catalogue number CNW 417.”

**Independent completion:** the participant reaches the correct `Duet` detail page without a neutral prompt or task-specific help. Repeating the task wording is permitted. The observer records whether the participant distinguishes the target from the other `Duet` result. The observer key is the detail page for `Duet` with stored catalogue number `417`; the two-result expectation is not disclosed in advance.

### U02 — Catalogue filtering

**Starting state:** `/works` with all filters empty.

**Participant instruction:**

> “Using the catalogue-number filter, find CNW 417 and open the work.”

**Independent completion:** the participant obtains the unique CNW 417 result and opens its `Duet` detail page without a neutral prompt or task-specific help. Repeating the task wording is permitted. The result table may display stored catalogue value `417` without the `CNW` prefix.

### U03 — Work-detail interpretation

**Starting state:** the verified CNW 63 detail page, loaded by the moderator before the task is revealed.

**Participant instruction:**

> “Using this page, identify the work’s title, composer, catalogue number and instrumentation, and determine whether performance information is available.”

**Independent completion:** without a neutral prompt or task-specific help, the participant reports the following observer-key facts from the page:

- title: `Sonate nr. 1 for violin og klaver, opus 9`;
- composer: `Carl Nielsen`;
- catalogue number: `63`;
- instrumentation: `1 pf.` and `1 vl.`, accepted in either order; semantically equivalent spoken expansions such as one piano and one violin are also accepted because specialist terminology is not required;
- performance information: present, evidenced by visible performance entries rather than the section heading alone.

The task does not ask the participant to assess scholarly accuracy or completeness. The verified 38 stored performance rows corroborate readiness but are not a required participant answer.

## Task-order rotation

| Participant | First | Second | Third |
|---|---|---|---|
| `P1` | `U01` | `U02` | `U03` |
| `P2` | `U02` | `U03` | `U01` |
| `P3` | `U03` | `U01` | `U02` |

This three-order rotation reduces a fixed ordering bias but cannot eliminate learning or carry-over effects in a sample of three. In particular, U01 and U02 use the same target record. Differences in task time must not be attributed solely to the interface control used.

## Per-attempt observation definitions

Each retained task-level record among the nine planned participant-task pairings records exactly one attempt disposition:

- `attempted`: the task instruction was read and the attempt began;
- `not_attempted_after_withdrawal`: the task never began because the enrolled participant had already withdrawn.

If retention permission is declined or unclear, the raw form is destroyed and no task-level disposition or measurement for that participant is retained. The non-identifying aggregate withdrawal note supports accounting for that participant's three predeclared pairings only as unavailable observations within the fixed denominator. Unavailable observations are not a third attempt disposition, a completion status or a usability outcome; do not retain task order, withdrawal point or task measurements from the destroyed form.

Enrollment and the first task's `attempted` disposition begin together when the first task instruction is read. A task that was already under way when the participant withdrew remains `attempted`. If retention is permitted, record only measurements actually observed before withdrawal; when the task stopped before completion, use `not_completed` and state that withdrawal—not interface difficulty—ended the task. Every remaining planned task is marked `not_attempted_after_withdrawal`, with completion status, elapsed time, rating, assistance, wrong turns and other task measurements left blank.

The five completion statuses below apply only when disposition is `attempted`. An attempted task records the task ID, order position and exactly one completion status:

- `completed_independently`: completed with no neutral prompt or task-specific help; verbatim repetition of the task is allowed;
- `completed_with_neutral_prompt`: completed after one or more uses of the predeclared neutral prompt, with no task-specific help;
- `completed_with_task_specific_help`: completed after any directional or task-specific help, whether or not a neutral prompt was also used;
- `not_completed`: not completed within the active three-minute ceiling or stopped for a non-technical reason;
- `technical_interruption`: no valid completion outcome because a technical problem prevented or invalidated the attempt.

The status precedence for a completed task is task-specific help, then neutral prompt, then independent. A technical interruption that prevents a valid outcome takes the technical status rather than `not_completed`.

Never code a task with disposition `not_attempted_after_withdrawal` as `not_completed`, `technical_interruption` or any other completion status. Withdrawal itself is not a usability failure and must not receive an issue-severity classification. The existing technical-interruption rules remain unchanged and apply only when a task was attempted.

If withdrawal and a technical problem occur together, use `technical_interruption` only when the technical problem independently prevented or invalidated the attempted outcome. Otherwise, when withdrawal ended an attempted task before completion, use `not_completed`, record withdrawal as the cause and do not interpret it as interface failure.

Timing starts immediately after the task instruction is read and ends on completion or at 180 active seconds. Technical-pause seconds are excluded and recorded separately. Think-aloud and reading time remain included, so elapsed time is contextual rather than a performance benchmark.

For every attempt, record:

- elapsed active seconds and technical-pause seconds;
- wrong-turn count;
- neutral-prompt count;
- task-specific-help count;
- ease rating from 1 (`very difficult`) to 5 (`very easy`);
- confusing labels or controls;
- concise, sanitized observer notes.

A wrong turn is a deliberate action that moves away from the task goal and requires reversal. Reading, pausing or scrolling alone is not a wrong turn.

The ease question is asked after every attempt. If a participant declines or cannot provide a rating, record it as not obtained with a reason; do not infer or impute a value.

## Post-session questions

Ask exactly:

1. “Which task felt easiest, and why?”
2. “Was any label, filter or part of a work page confusing?”
3. “What is the single most useful improvement you would make?”

Responses are paraphrased by default. Do not retain attributable quotations or identifying anecdotes.

## Predeclared descriptive analysis

Analysis is descriptive only. The predeclared denominator remains three enrolled participants and nine planned participant-task pairings; withdrawal does not renormalize it. Only observations that the participant permitted to be retained are summarized:

- attempt-disposition counts by task and overall for retained task-level records, with planned pairings unavailable after withdrawal without retention shown separately;
- completion-status counts by task and overall for dispositions marked `attempted`;
- each observed task time, plus median and range by task and overall where meaningful;
- ease-rating median and range by task and overall, with missing ratings shown rather than imputed;
- wrong-turn, neutral-prompt and task-specific-help counts;
- the number of distinct participants encountering each issue;
- short qualitative themes from the three post-session questions.

No inferential statistics will be performed. Percentages will not be presented as population estimates, and no overall accuracy or general-usability percentage will be calculated.

The preliminary “most tasks” criterion is operationalized as a bounded descriptive benchmark. Both conditions must be reported separately:

- at least two of three participants complete each task with status `completed_independently`; and
- at least six of the nine total attempts have status `completed_independently`.

Technical interruptions remain in the declared nine-attempt record and are reported separately; they are not silently removed to improve the benchmark. These thresholds are formative reporting rules, not evidence of general usability.

If withdrawal leaves one or more planned tasks without a retained valid completion outcome—including an attempted task ended by withdrawal, a later unattempted task, or a pairing made unavailable by declined or unclear retention permission—the affected per-task benchmark and the overall benchmark are reported as `not fully evaluable as predeclared`. All retained descriptive observations are still reported, and the planned nine-attempt denominator is not reduced. Withdrawal is reported as a study-disposition fact, not as task failure, interface evidence or an issue-severity event.

Issues are categorized using these predeclared rules:

- `critical`: prevents at least two participants from completing a task;
- `major`: causes failure, task-specific help or repeated confusion for at least two participants;
- `minor`: causes delay or confusion but does not prevent completion.

When an issue could satisfy more than one category, apply the highest applicable category (`critical` before `major` before `minor`) and do not double-count it. Any critical issue is reported regardless of whether the completion benchmark is met.

## Evidence handling

Before each session, make a private copy of `phase2_usability_observation_template.md` under `tmp/phase2_usability/sessions/`. Name records only with `P1`, `P2` or `P3`; completed raw forms remain ignored and uncommitted. The participant materials are displayed or read without collecting annotations in the tracked source; consent, optional categories, ratings and responses are recorded in the private observation copy. Do not add names, contact details, employer names or identifying anecdotes.

Unsuccessful and technically interrupted sessions and attempts must be retained rather than deleted or replaced when the participant permits retention. Missing observations must remain missing with a reason; they must never be invented. If an enrolled participant withdraws and retention permission is declined or unclear, destroy that participant's private raw form and retain only the required non-identifying aggregate withdrawal note. After the three sessions, create a sanitized aggregate results report under `docs/report_evidence/`, but keep retained raw forms private and out of commits and review bundles.

The later report must distinguish observed task behavior from technical interruption and from moderator assistance. Neither HTML readiness, task completion nor three participants can establish accessibility, scholarly fidelity, production readiness or general usability.
