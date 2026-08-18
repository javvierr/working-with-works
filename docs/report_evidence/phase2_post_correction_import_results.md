# Phase 2 post-correction Stage A summary

## Scope and stopping boundary

This artifact records only the canonical post-correction Stage A authoritative-corpus import. The application was evaluated at commit `c01bd32417dd381c15dfa351f6da8d6d7f5de11d` against the same verified 446-file Carl Nielsen corpus used for the frozen baseline. Post-correction Stages B–D were not started, no API request was made, and no demonstration database was prepared.

The dedicated database is `phase2_post_correction_stage_a_20260817_c01bd32_01`. It is preserved for later read-only post-correction comparison stages.

## Method and preflight

- Application baseline: `8b40722103acb36826a81b7bd1a90983435e9dd7`.
- Correction HEAD: `c01bd32417dd381c15dfa351f6da8d6d7f5de11d`.
- Frozen protocol commit: `548dca16f11f6f5fa82a668898dbe0d326d72f97`.
- Correction-scope commit: `584b6fa201e2d8b5e84b93d007a63204dc6bc664`.
- Frozen harness SHA-256: `1ca2048e4698239e2f44be3daad092010f6adf2d4f022be9a8877d176dfb7bdc`.
- Official archive SHA-256: `fa3ff9e3012a6a9e8d21c098105bea3be9670945bb76aa5ea46391d2c33cf8ec`.
- Sample manifest SHA-256: `210fbe9d2010389332fc620faa60092f765e08dda002ae23c396633137d0d72e`.

The archive passed its integrity check. The archive and extracted corpus each contained exactly 446 intended XML files, with no missing, extra, or byte-mismatched extracted file. All 15 sample-manifest entries retained their declared size and SHA-256.

The fresh database was migrated to schema version `20260817090000` without fixtures, seeds, or corpus data. Two preliminary connection configurations were rejected before any migration was applied; a third configuration connected to the same still-empty dedicated database and applied the committed migrations. Before preflight, all nine evaluated tables were empty, `identifier_type` was non-null, the unique `(work_id, identifier_type, value)` index was present, and the former unique `(work_id, value)` constraint was absent.

Preflight validated all 446 inputs, left all nine tables empty, created no `ImportLog`, instantiated no importer, invoked no importer, and wrote no canonical invocation sentinel. The canonical run then wrote the permanent sentinel and crossed the sole importer boundary exactly once. No retry occurred.

## Canonical technical result

| Measure | Observed |
|---|---:|
| Files seen | 446 |
| Successes | 446 |
| Failures | 0 |
| Success without warning | 0 |
| Success with warning | 446 |
| Logged failure | 0 |
| Unaccounted or aborted | 0 |
| Returned warnings | 1,354 |
| Logged warnings | 1,354 |
| Importer invocations | 1 |
| Retries | 0 |

The importer returned normally. Its elapsed time was 9.360576 seconds in this environment; this is contextual timing only and is not a performance benchmark.

Every input has exactly one accountable classification and one `ImportLog`. Every successful log reconciles to exactly one surviving work. Returned and logged warning multisets are identical. All 18 reconciliation checks passed, and all six child-table orphan checks were zero.

## Table totals and provisional baseline deltas

| Table | Frozen baseline | Post-correction Stage A | Delta |
|---|---:|---:|---:|
| composers | 1 | 1 | 0 |
| works | 441 | 446 | +5 |
| catalogue_identifiers | 1,702 | 1,726 | +24 |
| movements | 0 | 0 | 0 |
| instrumentations | 1,651 | 1,686 | +35 |
| source_references | 0 | 0 | 0 |
| performances | 0 | 4,646 | +4,646 |
| external_references | 2,001 | 458 | -1,543 |
| import_logs | 446 | 446 | 0 |

The technical baseline deltas are: successes +5, failures -5, warnings -37, and works +5. These are import-completion and storage deltas, not an overall semantic-accuracy score. Semantic claims remain subject to the unchanged Stage B assertion IDs and denominator in the later controlled comparison.

## Warning and failure categories

| Stable warning category | Occurrences | Affected files |
|---|---:|---:|
| no_movements | 446 | 446 |
| no_source_references | 446 | 446 |
| skipped_performance_event_no_supported_direct_values | 194 | 194 |
| no_external_references | 138 | 138 |
| no_performance_information | 60 | 60 |
| no_instrumentation | 39 | 39 |
| non_exact_performance_date_not_stored | 22 | 13 |
| missing_composition_date_or_year | 7 | 7 |
| missing_genre_or_category | 2 | 2 |

There were no logged failure categories. No exception class was inferred from log text.

## Correction-specific observations

- All five formerly rolled-back inputs—`cnw0027.xml`, `cnw0064.xml`, `cnw0070.xml`, `cnw0081.xml`, and `cnw0237.xml`—completed successfully, retained a work row, and reconciled as committed.
- The final composer inventory contains one composer, Carl Nielsen, associated with all 446 works.
- The missing-composition-date warning occurred seven times across seven files.
- Performance storage contains 4,646 rows. Together with 194 explicitly skipped empty/unsupported events, this accounts for the 4,840 selected source performance events. Twenty-two non-exact-date warnings affected 13 files.
- External-reference storage contains 458 rows. Independent syntactic validation found 458 HTTP(S)-with-host values and zero invalid stored URLs; no URL was followed. The frozen source scan identified 459 syntactically eligible target nodes, while storage retains 458 rows because exact URLs are de-duplicated per work.
- Catalogue-identifier storage contains 1,726 rows, with zero null or blank identifier types and zero duplicate `(work_id, identifier_type, value)` groups. The corrected composite database constraint remained present.

## Database digest and preservation

The deterministic nine-table database digest is:

`ee61baab1f1032026a32c9e4df9e403847e8c6ad0b3011009be242beb6fe4ce9`

It was calculated from every selected column and row ordered by `id`, using the preserved Stage B algorithm, inside a PostgreSQL repeatable-read, read-only transaction. An independent read-only database audit reproduced the nine table counts, six zero orphan counts, composer inventory, identifier integrity state, and 458/458 external-reference validity result.

The committed Stage A–D reports, preserved ignored Stage A–D raw evidence, official ZIP, and all 446 extracted XML files retained their pre-run fingerprints. The application working tree and index remained clean. Neither canonical baseline database was connected to or queried.

## Interpretation boundary

This stage demonstrates complete technical processing of the 446 files under the corrected importer and records the resulting database state. It does not by itself establish official-source fidelity, general MEI compatibility, usability, accessibility, security, performance, deployment readiness, or production readiness. Movements and source references remain absent because those modeling issues were explicitly deferred. The exact Stage B–D post-correction comparisons remain future work and were not begun here.
