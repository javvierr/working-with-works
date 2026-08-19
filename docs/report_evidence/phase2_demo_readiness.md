# Phase 2 demonstration readiness

## Readiness result

The local Phase 2 demonstration state is ready for the later three-participant formative usability exercise. The existing locked Ruby environment was recovered without installing or changing dependencies, the direct suite passed with 58 tests and 269 assertions, the dedicated demonstration database imported all 446 official records successfully, and all seven authorized HTML-interface checks matched database-derived expectations.

The retained state is operational evidence only. It neither resumes nor revises the frozen post-correction API evaluation, and it does not establish usability outcomes. No participant session has begun.

## Scope and evidence separation

Preparation used `main` at commit `70ddc085bc81a73800c594aee89e02cf64a8075b`. Application scopes remained identical to correction commit `c01bd32417dd381c15dfa351f6da8d6d7f5de11d`. The dedicated database is `phase2_usability_demo_20260818_70ddc08_01`; it is separate from every preserved evaluation database and is retained for the later sessions.

The official Royal Danish Library archive retained SHA-256 `fa3ff9e3012a6a9e8d21c098105bea3be9670945bb76aa5ea46391d2c33cf8ec`. Its 446 Carl Nielsen XML members matched the 446 extracted XML files with no missing, extra, or byte-different file. No archive download or XML write occurred.

## Environment recovery and direct tests

The initial readiness attempt selected environments that could not resolve the locked bundle: first the system Ruby, then Ruby 4.0.5 without the application gem-store mapping. A dependency-only diagnosis subsequently identified an existing complete Ruby 4.0.5 / RubyGems 4.0.15 / Bundler 4.0.15 environment with zero missing locked gems and all 15 native extensions complete. Selecting that existing environment required no installation, compilation, copy, update, or lockfile change.

A later mapped direct-suite process exited with status 1 but retained no output because its launcher discarded captured stdout and stderr when it found no test summary. Its precise cause therefore remains unresolved; it is not treated as an application-test failure. The operational recovery retained the ordinary shell environment around the approved Ruby and gem-store mapping and captured both streams privately. A read-only probe first reached exactly `UoL_final_project_test` at schema version `20260817090000`, so no `db:test:prepare` or other remediation was needed.

The one fully captured suite in this operational attempt then completed as follows:

| Measure | Result |
|---|---:|
| Tests | 58 |
| Assertions | 269 |
| Failures | 0 |
| Errors | 0 |
| Skips | 0 |

Across readiness history, two direct-suite launcher processes were invoked: the earlier opaque exit-status-1 process and this captured passing process. The successful operational attempt used one test launch with no retry. `bin/ci` was not used.

## Dedicated demonstration database

The approved database name did not exist at the collision gate. It was created once, migrated to schema version `20260817090000`, and verified to have zero rows in all nine domain tables before import. No seed was run and no persistent database configuration was changed.

The corrected importer was invoked exactly once against the verified official corpus, with no retry:

| Import measure | Result |
|---|---:|
| Files seen | 446 |
| Successes | 446 |
| Failures | 0 |
| Returned warnings | 1,354 |
| Logged warnings | 1,354 |

The returned and logged warning multisets matched. Post-import table counts were:

| Table | Rows |
|---|---:|
| composers | 1 |
| works | 446 |
| catalogue_identifiers | 1,726 |
| movements | 0 |
| instrumentations | 1,686 |
| source_references | 0 |
| performances | 4,646 |
| external_references | 458 |
| import_logs | 446 |

Carl Nielsen was the sole composer and was associated with all 446 works. The five former identifier-conflict files each had one successful log and one surviving, correctly linked work. Identifier types had no null or blank value; no duplicate `(work_id, identifier_type, value)` group existed; and all eight applicable orphan checks were zero. The 4,646 stored performance rows plus 194 explicit unsupported-direct-value skips reconciled all 4,840 selected candidates. All 458 external references satisfied the HTTP(S)-with-host rule without being followed. CNW 67 retained null composition date and year plus the truthful missing-date warning.

## Local HTML-interface checks

The development server ran only on loopback port 3100 against the dedicated demonstration database. Seven primary HTML GETs were made. The browser also requested one local static stylesheet automatically; that request was neither an API endpoint nor external network activity. No `/api/...` route or external-reference URL was requested.

| Check | Observed result |
|---|---|
| `/` | HTTP 200 `text/html`; 446 works displayed |
| `/works` | HTTP 200 `text/html`; 446 works displayed with detail navigation |
| General search `Duet` | HTTP 200 `text/html`; two database-expected works displayed |
| Catalogue filter `CNW 417` | HTTP 200 `text/html`; the unique Duet result displayed |
| Database-derived genre filter `manuscript` | HTTP 200 `text/html`; Duet and Impromptu displayed |
| CNW 417 detail | HTTP 200 `text/html`; title, Carl Nielsen, catalogue 417, date, genre and instrumentation matched the database |
| CNW 63 detail | HTTP 200 `text/html`; title, composer, catalogue, date, genre and instrumentation matched, and the performance section displayed all 38 stored rows |

These checks establish local HTML readiness only. In particular, the CNW 63 performance section is a bounded flattened prototype representation, not complete MEI fidelity. The Rails server was stopped after the checks, and the retained database was reverified through a read-only transaction with unchanged counts.

## Candidate usability workflows

The following candidates are grounded only in the verified HTML behavior:

1. **General search:** start at `/works`, search for `Duet`, and complete the task when the intended work is distinguished in the two-result list and its detail link is available. The interface must display title, catalogue information and a detail link; the limitation is that substring search can produce more than one plausible result.
2. **Catalogue filtering:** start at `/works`, enter `CNW 417`, and complete the task when the unique Duet result is found and opened. This demonstrates the bounded catalogue filter used here, not every prefix or tie-order case.
3. **Work-detail interpretation:** open the CNW 63 detail page and identify the title, composer, catalogue number, instrumentation and presence of performance information. The displayed child information is a bounded flattened representation and should not be interpreted as complete source fidelity.

None of the candidates requires the JSON API, source-code inspection, external-link navigation, or an unsupported source structure. Participant instructions, consent material, questionnaires, scoring and the final usability protocol have not yet been created.

## Starting the retained local state

From the repository root, run the ignored private launcher:

```text
python3 tmp/phase2_usability/demo_state_operational_attempt_02/start_demo.private.py
```

The launcher performs read-only application, lockfile and database identity gates, then starts the existing state at `http://127.0.0.1:3100` in the foreground. It does not install dependencies, create or migrate a database, seed, or import. Stop it with Ctrl-C.

## Limitations and preservation

This readiness result does not supply post-correction API evidence, complete MEI fidelity, usability findings, accessibility, security, performance or deployment evidence. The frozen Phase 2 evaluation remains unchanged and closed. No external network request, API request, dependency modification, application change, or XML write occurred.

`Gemfile.lock`, application scopes, committed report evidence, ignored Phase 2 evaluation evidence, prior readiness/diagnostic attempts, the official archive and all extracted XML bytes retained their approved identities. The demonstration database remains available, the server is stopped, nothing is staged or committed, and usability sessions have not begun.
