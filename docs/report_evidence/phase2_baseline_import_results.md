# Phase 2B Stage A authoritative-corpus import

## Technical summary

The unchanged baseline importer completed one canonical batch call and accounted for all 446 official Carl Nielsen XML files. 441 files (98.88%) committed successfully and 5 (1.12%) produced logged, rolled-back failures. No file was unaccounted, no path was unmapped, and the process returned normally without a retry.

RQ1 therefore has a qualified answer: the baseline can traverse and account for the full institutional corpus in one batch, but it cannot import every file successfully. All 441 successful files carried at least one warning, and the five failures arose from the per-work catalogue-identifier value uniqueness constraint. This establishes technical batch behavior only; it does not establish semantic fidelity.

The importer returned 1,391 warnings in 6.811527 contextual seconds. Returned and logged warning multisets agree exactly. The database contains zero movements, source references, and performances after the run, with corresponding warnings on all 446 inputs; this is a material baseline limitation for later fidelity review, not a completed Stage B assessment.

## Evaluation identity and scope

| Item | Value |
|---|---|
| Application baseline | `8b40722103acb36826a81b7bd1a90983435e9dd7` |
| Frozen protocol commit | `548dca16f11f6f5fa82a668898dbe0d326d72f97` |
| Official archive SHA-256 | `fa3ff9e3012a6a9e8d21c098105bea3be9670945bb76aa5ea46391d2c33cf8ec` |
| Corrected harness SHA-256 | `7d2293a7abd1bef70edef7189a49b167f404d4dc43ea1c734734a71994a0de12` |
| Canonical-results SHA-256 | `28a54133b40323446b3377e42f71a16dfd57db9740e2478cc863fcf53df9c581` |
| Official corpus | 446 XML files under `dcm-catalogue-data/cnw/data-cnw/` |
| Canonical database | `phase2_stage_a_20260816_548dca1_02` |
| Execution window | `2026-08-16T19:03:12.641531Z` to `2026-08-16T19:03:19.453048Z` |
| Minimal environment | Rails test environment; Ruby 4.0.5; Rails 8.1.3; PostgreSQL 14.23 |

The environment record intentionally excludes personal paths, users, hosts, sockets, credentials, connection strings, and other machine-specific details. The elapsed time is contextual for this run and is not a general performance benchmark.

## Frozen predictions remained separate from observation

Before execution, the protocol predicted successful technical processing for the four boundary/stress records and predicted per-work identifier-value failures for `cnw0027.xml`, `cnw0064.xml`, `cnw0070.xml`, `cnw0081.xml`, and `cnw0237.xml`. It also froze nested-date and namespace-prefix predictions for later Stage C work.

The canonical batch observed logged failures for exactly those five identifier files, but no focused probe was independently rerun. The date and namespace predictions remain unevaluated. No predicted aggregate total has been converted into a finding.

## Execution history

### Attempt 0 — pre-import harness-load abort

The first Rails-runner process stopped at `require "csv"` with a directly observed `LoadError` before the ignored harness executed. `Mei::Importer` invocation count was 0, no invocation sentinel or import transaction existed, and every evaluated table in database `phase2_stage_a_20260816_548dca1_01` remained empty. No importer timing or result was available, so RQ1 remained unanswered.

Attempt 0 remains preserved under `tmp/phase2_evaluation/baseline/`, including the original failed harness, `process_abort.json`, `database_state.json`, `sanitized_runner_output.txt`, and the original 446-row `unaccounted/aborted` reconciliation. It is not counted as a canonical importer attempt or importer failure.

### Attempt 1 — canonical unchanged-baseline import

A JSON-only harness was frozen at SHA-256 `7d2293a7abd1bef70edef7189a49b167f404d4dc43ea1c734734a71994a0de12`. Preflight loaded Rails, the importer constant, and all nine evaluated model constants; validated 446 unique XML inputs; exercised JSON writing; and confirmed all nine tables empty. Preflight instantiated no importer, invoked it 0 times, and wrote no invocation sentinel.

Canonical mode required that exact preflight marker and harness hash, reconfirmed the empty database and input set, wrote the permanent invocation sentinel, recorded UTC and monotonic starts, and entered the sole call expression:

```ruby
result = Mei::Importer.new(directory: CORPUS_DIR).call
```

The call returned normally. `importer_return.json` was persisted before database reconciliation, the importer invocation count remained exactly 1, and no retry occurred. No application, dependency, protocol, manifest, configuration, migration, schema, fixture, or test file changed.

## Attempt 1 technical result

| Measure | Observed value |
|---|---:|
| Importer invocation count | 1 |
| Files seen | 446 |
| Successes | 441 |
| Failures | 5 |
| Success without warning | 0 |
| Success with warning | 441 |
| Logged failure | 5 |
| Unaccounted/aborted | 0 |
| Returned warnings | 1,391 |
| Logged warnings | 1,391 |
| Contextual elapsed seconds | 6.811527 |
| Process outcome | `normal_return` |
| Retry performed | no |

## Database counts after the canonical call

| Table | Pre-import | Post-import | Change |
|---|---:|---:|---:|
| `composers` | 0 | 1 | 1 |
| `works` | 0 | 441 | 441 |
| `catalogue_identifiers` | 0 | 1,702 | 1,702 |
| `movements` | 0 | 0 | 0 |
| `instrumentations` | 0 | 1,651 | 1,651 |
| `source_references` | 0 | 0 | 0 |
| `performances` | 0 | 0 | 0 |
| `external_references` | 0 | 2,001 | 2,001 |
| `import_logs` | 0 | 446 | 446 |

The 441 success logs reconcile to 441 stored works. All 5 failure logs have no work ID and no surviving work row. No evaluated child table contains an orphan row.

## Warning categories

| Category | Affected files | Occurrences | Sanitized representative message |
|---|---:|---:|---|
| `no_movements` | 446 | 446 | No movements found |
| `no_performance_information` | 446 | 446 | No performance information found |
| `no_source_references` | 446 | 446 | No source references found |
| `no_instrumentation` | 39 | 39 | No instrumentation found |
| `missing_composition_date_or_year` | 6 | 6 | Missing composition date or year |
| `no_external_references` | 6 | 6 | No external references found |
| `missing_genre_or_category` | 2 | 2 | Missing genre/category |

The category occurrence counts sum to 1,391. Every input has at least the movement, source-reference, and performance warning; therefore every committed success is classified as success with warning.

## Failure category and transaction outcome

| Category | Affected files | Stored database evidence | Exception class | Transaction outcome |
|---|---:|---|---|---|
| `catalogue_identifier_per_work_value_uniqueness` | 5: `dcm-catalogue-data/cnw/data-cnw/cnw0027.xml`, `dcm-catalogue-data/cnw/data-cnw/cnw0064.xml`, `dcm-catalogue-data/cnw/data-cnw/cnw0070.xml`, `dcm-catalogue-data/cnw/data-cnw/cnw0081.xml`, `dcm-catalogue-data/cnw/data-cnw/cnw0237.xml` | Duplicate key value reported against `index_catalogue_identifiers_on_work_id_and_value` | exception class not directly observable | 5 rolled_back/no work remains |

The importer catches per-file errors and stores only their messages. Consequently, the exception class for these logged failures is `exception class not directly observable`; no class is inferred from the stored message text.

## Reconciliation checks all passed

| Check | Result |
|---|---|
| `files_seen_equals_446` | pass |
| `successes_plus_failures_equals_files_seen` | pass |
| `import_log_count_equals_files_seen` | pass |
| `success_log_count_equals_successes` | pass |
| `failure_log_count_equals_failures` | pass |
| `stored_work_count_equals_successes` | pass |
| `returned_warning_count_equals_logged_warning_count` | pass |
| `returned_warning_multiset_equals_logged_warning_multiset` | pass |
| `every_input_has_exactly_one_import_log` | pass |
| `every_success_has_exactly_one_work` | pass |
| `every_failure_leaves_no_work` | pass |
| `success_log_work_ids_match_same_source_work` | pass |
| `failure_logs_have_nil_work_id` | pass |
| `no_orphan_child_rows` | pass |
| `no_unmapped_log_paths` | pass |
| `no_unmapped_work_paths` | pass |
| `no_file_has_duplicate_outcomes` | pass |
| `no_file_remains_unaccounted` | pass |

The canonical reconciliation contains 446 unique archive-relative paths matching the verified corpus exactly. It contains 441 success logs, 5 failure logs, zero duplicate outcomes, zero unmapped log/work paths, and zero unaccounted files. Returned and logged warning multisets are identical.

## Stage A conclusion for RQ1

The unchanged baseline technically completes the corpus-wide batch and produces one accountable database/log outcome for every official input. It does not achieve a completely successful import: five files fail and roll back because different identifier types share the same value under a per-work value-only uniqueness constraint.

The run also leaves three evaluated domains empty—movements, source references, and performances—despite processing the corpus. Those observed row counts and warnings identify material baseline limitations, but Stage A alone does not determine the exact source-to-database fidelity of individual fields. That remains the bounded purpose of later Stage B work.

## Limitations and stopping point

- Technical completion is not semantic correctness.
- No Stage B detailed-fidelity assertion was classified.
- No Stage C focused probe was independently rerun; agreement between the five batch failures and frozen predictions is not a separate probe result.
- No Stage D API request was made.
- No usability, accessibility, general performance, production security, or deployment conclusion is supported.
- The 6.811527-second duration is contextual for this machine and run only.
- The official corpus and importer support a particular institutional XML structure; these results do not establish general MEI compatibility.

Review is required before later stages for the five identifier-constraint failures and the corpus-wide absence of stored movements, source references, and performances. No correction is made in this Stage A evidence pass.

## Preserved evidence

- Attempt 0 database: `phase2_stage_a_20260816_548dca1_01`; raw evidence: `tmp/phase2_evaluation/baseline/`.
- Attempt 1 database: `phase2_stage_a_20260816_548dca1_02`; raw evidence: `tmp/phase2_evaluation/baseline/canonical_attempt_01/`.
- Primary canonical result: `canonical_results.json`; immediate return record: `importer_return.json`; full machine-readable reconciliation: `reconciliation.json`.
- Both databases and both ignored evidence sets remain preserved for review.

## Appendix: canonical 446-file reconciliation

| Archive-relative path | Classification | Log status | Warnings | Warning categories | Failure category | Stored work ID | Work remains | Log rows | Transaction |
|---|---|---|---:|---|---|---:|---|---:|---|
| `dcm-catalogue-data/cnw/data-cnw/03f4c141-9dab-46d7-b8c1-9d0000cc997a.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `1` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/0f697747-fb0a-4238-812a-80ef66403513.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `2` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/1292525519.xml` | `success with warning` | `success` | 5 | missing_composition_date_or_year, no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `3` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/1e8927e2-8d44-48cc-ac90-8b654ece935b.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `4` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/1f6c24d6-e41f-4647-8526-f33efc08faeb.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `5` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/22131671612451.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `6` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/22157659832449.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `7` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/22225400586721.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `8` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/22225579311185.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `9` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/22228336520259.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `10` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/22228347081665.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `11` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/22228421720417.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `12` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/22228475173875.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `13` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/241295ab-c694-42de-8023-2776e7401166.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `14` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/29ed9322-a12d-4efe-bb1a-513797128bfe.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `15` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/46c22e1e-500d-40f9-ba0c-2022e6ca974d.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `16` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/4cb50e5e-ff57-4486-b24c-ba5a236fe735.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `17` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/4f9611bd-683f-4da6-b81d-86d86522ef4e.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `18` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/50911efc-3712-40bf-8695-bf4614e722c4.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `19` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/6b2ccb5d-2b5d-42be-98ec-3ebfe5ee6fdd.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `20` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/712a43e2-d3d6-463a-88fa-0b7e88e4dbf8.xml` | `success with warning` | `success` | 4 | no_movements, no_source_references, no_performance_information, no_external_references | `not_applicable` | `21` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/80cd1305-3df6-4253-936d-25b73a91fb5d.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `22` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/8bf1d20f-4d9b-41a7-a00b-1bcd41c7448f.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `23` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/9cc39f99-2d56-404b-bc95-ec21dfa136dc.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `24` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/a601140e-d48d-48c3-b103-bc0c365082d4.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `25` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/aa9d5567-7e44-407a-8e34-1e002cd680fa.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `26` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/c4216cb5-c53b-4375-a779-d708e419eec0.xml` | `success with warning` | `success` | 4 | no_movements, no_source_references, no_performance_information, no_external_references | `not_applicable` | `27` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/c473b2ec-0cd5-40cd-ae07-e3e620c5ed59.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `28` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/c61e8ee2-7445-43fb-a5d3-c011e43130af.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `29` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/c6e3b565-5e1b-4ff0-b796-a2e1ffc7a8ef.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `30` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/ca2b530c-60fd-447a-9b3d-b5aa9cfda1f5.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `31` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cdf45953-c507-4047-a1e1-7def707a4885.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `32` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0001.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `33` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0002.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `34` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0003.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `35` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0004.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `36` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0005.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `37` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0006.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `38` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0007.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `39` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0008.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `40` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0009.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `41` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0010.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `42` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0011.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `43` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0012.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `44` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0013.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `45` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0014.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `46` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0015.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `47` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0016.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `48` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0017.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `49` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0018.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `50` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0019.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `51` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0020.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `52` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0021.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `53` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0022.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `54` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0023.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `55` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0024.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `56` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0025.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `57` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0026.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `58` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0027.xml` | `logged failure` | `failure` | 3 | no_movements, no_source_references, no_performance_information | `catalogue_identifier_per_work_value_uniqueness` | `not_stored` | no | 1 | rolled_back/no work remains |
| `dcm-catalogue-data/cnw/data-cnw/cnw0028.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `60` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0029.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `61` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0030.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `62` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0031.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `63` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0032.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `64` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0033.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `65` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0034.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `66` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0035.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `67` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0036.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `68` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0037.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `69` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0038.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `70` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0039.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `71` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0040.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `72` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0041.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `73` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0042.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `74` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0043.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `75` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0044.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `76` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0045.xml` | `success with warning` | `success` | 4 | no_movements, no_source_references, no_performance_information, no_external_references | `not_applicable` | `77` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0046.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `78` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0047.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `79` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0048.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `80` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0049.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `81` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0050.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `82` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0052.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `83` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0053.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `84` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0054.xml` | `success with warning` | `success` | 5 | missing_composition_date_or_year, no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `85` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0055.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `86` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0056.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `87` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0057.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `88` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0058.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `89` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0059.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `90` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0060.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `91` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0061.xml` | `success with warning` | `success` | 5 | missing_composition_date_or_year, missing_genre_or_category, no_movements, no_source_references, no_performance_information | `not_applicable` | `92` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0062.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `93` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0063.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `94` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0064.xml` | `logged failure` | `failure` | 3 | no_movements, no_source_references, no_performance_information | `catalogue_identifier_per_work_value_uniqueness` | `not_stored` | no | 1 | rolled_back/no work remains |
| `dcm-catalogue-data/cnw/data-cnw/cnw0065.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `96` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0066.xml` | `success with warning` | `success` | 4 | no_movements, no_source_references, no_performance_information, no_external_references | `not_applicable` | `97` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0067.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `98` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0068.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `99` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0069.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `100` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0070.xml` | `logged failure` | `failure` | 3 | no_movements, no_source_references, no_performance_information | `catalogue_identifier_per_work_value_uniqueness` | `not_stored` | no | 1 | rolled_back/no work remains |
| `dcm-catalogue-data/cnw/data-cnw/cnw0071.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `102` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0072.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `103` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0073.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `104` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0074.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `105` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0075.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `106` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0076.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `107` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0077.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `108` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0078.xml` | `success with warning` | `success` | 4 | missing_composition_date_or_year, no_movements, no_source_references, no_performance_information | `not_applicable` | `109` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0079.xml` | `success with warning` | `success` | 4 | missing_composition_date_or_year, no_movements, no_source_references, no_performance_information | `not_applicable` | `110` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0080.xml` | `success with warning` | `success` | 4 | missing_composition_date_or_year, no_movements, no_source_references, no_performance_information | `not_applicable` | `111` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0081.xml` | `logged failure` | `failure` | 3 | no_movements, no_source_references, no_performance_information | `catalogue_identifier_per_work_value_uniqueness` | `not_stored` | no | 1 | rolled_back/no work remains |
| `dcm-catalogue-data/cnw/data-cnw/cnw0082.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `113` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0083.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `114` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0084.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `115` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0085.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `116` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0086.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `117` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0087.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `118` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0088.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `119` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0089.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `120` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0090.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `121` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0091.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `122` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0092.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `123` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0093.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `124` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0094.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `125` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0095.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `126` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0096.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `127` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0097.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `128` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0098.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `129` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0099.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `130` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0100.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `131` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0101.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `132` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0102.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `133` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0103.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `134` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0104.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `135` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0105.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `136` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0106.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `137` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0107.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `138` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0108.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `139` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0109.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `140` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0110.xml` | `success with warning` | `success` | 4 | no_movements, no_source_references, no_performance_information, no_external_references | `not_applicable` | `141` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0111.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `142` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0112.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `143` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0113.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `144` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0114.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `145` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0115.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `146` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0116.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `147` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0117.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `148` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0118.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `149` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0119.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `150` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0120.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `151` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0121.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `152` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0122.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `153` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0123.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `154` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0124.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `155` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0125.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `156` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0126.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `157` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0127.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `158` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0128.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `159` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0129.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `160` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0130.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `161` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0131.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `162` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0132.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `163` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0133.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `164` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0134.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `165` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0135.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `166` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0136.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `167` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0137.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `168` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0138.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `169` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0139.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `170` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0140.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `171` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0141.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `172` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0142.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `173` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0143.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `174` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0144.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `175` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0145.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `176` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0146.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `177` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0147.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `178` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0148.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `179` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0149.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `180` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0150.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `181` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0151.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `182` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0152.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `183` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0153.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `184` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0154.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `185` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0155.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `186` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0156.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `187` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0157.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `188` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0158.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `189` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0159.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `190` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0160.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `191` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0161.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `192` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0162.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `193` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0163.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `194` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0164.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `195` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0165.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `196` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0166.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `197` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0167.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `198` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0168.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `199` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0169.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `200` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0170.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `201` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0171.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `202` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0172.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `203` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0173.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `204` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0174.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `205` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0175.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `206` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0176.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `207` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0177.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `208` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0178.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `209` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0179.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `210` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0180.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `211` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0181.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `212` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0182.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `213` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0183.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `214` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0184.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `215` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0185.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `216` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0186.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `217` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0187.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `218` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0188.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `219` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0189.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `220` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0190.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `221` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0191.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `222` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0192.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `223` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0193.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `224` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0194.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `225` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0195.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `226` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0196.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `227` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0197.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `228` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0198.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `229` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0199.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `230` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0200.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `231` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0201.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `232` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0202.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `233` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0203.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `234` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0204.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `235` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0205.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `236` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0206.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `237` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0207.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `238` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0208.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `239` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0209.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `240` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0210.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `241` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0211.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `242` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0212.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `243` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0213.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `244` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0214.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `245` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0215.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `246` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0216.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `247` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0217.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `248` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0218.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `249` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0219.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `250` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0220.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `251` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0221.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `252` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0222.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `253` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0223.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `254` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0224.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `255` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0225.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `256` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0226.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `257` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0227.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `258` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0228.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `259` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0229.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `260` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0230.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `261` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0231.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `262` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0232.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `263` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0233.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `264` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0234.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `265` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0235.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `266` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0236.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `267` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0237.xml` | `logged failure` | `failure` | 3 | no_movements, no_source_references, no_performance_information | `catalogue_identifier_per_work_value_uniqueness` | `not_stored` | no | 1 | rolled_back/no work remains |
| `dcm-catalogue-data/cnw/data-cnw/cnw0238.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `269` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0239.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `270` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0240.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `271` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0241.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `272` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0242.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `273` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0243.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `274` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0244.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `275` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0245.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `276` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0246.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `277` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0247.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `278` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0248.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `279` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0249.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `280` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0250.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `281` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0251.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `282` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0252.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `283` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0253.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `284` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0254.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `285` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0255.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `286` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0256.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `287` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0257.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `288` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0258.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `289` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0259.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `290` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0260.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `291` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0261.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `292` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0262.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `293` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0263.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `294` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0264.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `295` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0265.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `296` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0266.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `297` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0267.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `298` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0268.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `299` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0269.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `300` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0270.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `301` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0271.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `302` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0272.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `303` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0273.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `304` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0274.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `305` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0275.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `306` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0276.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `307` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0277.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `308` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0278.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `309` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0279.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `310` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0280.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `311` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0281.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `312` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0282.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `313` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0283.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `314` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0284.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `315` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0285.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `316` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0286.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `317` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0287.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `318` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0288.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `319` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0289.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `320` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0290.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `321` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0291.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `322` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0292.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `323` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0293.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `324` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0294.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `325` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0295.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `326` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0296.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `327` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0297.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `328` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0298.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `329` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0299.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `330` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0300.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `331` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0301.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `332` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0302.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `333` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0303.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `334` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0304.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `335` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0305.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `336` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0306.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `337` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0307.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `338` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0308.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `339` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0309.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `340` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0310.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `341` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0311.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `342` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0312.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `343` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0313.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `344` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0314.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `345` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0315.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `346` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0316.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `347` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0317.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `348` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0318.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `349` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0319.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `350` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0320.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `351` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0321.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `352` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0322.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `353` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0323.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `354` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0324.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `355` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0325.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `356` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0326.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `357` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0327.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `358` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0328.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `359` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0329.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `360` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0330.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `361` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0331.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `362` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0332.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `363` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0333.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `364` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0334.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `365` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0335.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `366` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0336.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `367` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0337.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `368` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0338.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `369` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0342.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `370` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0343.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `371` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0344.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `372` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0345.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `373` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0346.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `374` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0347.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `375` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0348.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `376` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0349.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `377` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0350.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `378` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0351.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `379` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0352.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `380` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0353.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `381` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0354.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `382` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0355.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `383` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0356.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `384` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0358.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `385` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0359.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `386` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0360.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `387` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0361.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `388` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0362.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `389` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0363.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `390` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0364.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `391` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0365.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `392` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0366.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `393` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0367.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `394` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0368.xml` | `success with warning` | `success` | 4 | missing_genre_or_category, no_movements, no_source_references, no_performance_information | `not_applicable` | `395` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0369.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `396` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0370.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `397` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0371.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `398` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0372.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `399` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0373.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `400` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0374.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `401` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0375.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `402` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0376.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `403` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0377.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `404` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0378.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `405` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0379.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `406` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0380.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `407` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0381.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `408` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0382.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `409` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0383.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `410` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0384.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `411` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0385.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `412` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0386.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `413` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0387.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `414` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0388.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `415` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0389.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `416` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0390.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `417` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0391.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `418` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0392.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `419` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0394.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `420` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0395.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `421` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0396.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `422` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0397.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `423` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0398.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `424` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0399.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `425` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0400.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `426` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0401.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `427` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0402.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `428` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0403.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `429` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0404.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `430` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0405.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `431` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0406.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `432` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0407.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `433` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0408.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `434` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0409.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `435` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0410.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `436` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0411.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `437` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0412.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `438` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0413.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `439` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/cnw0415.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `440` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/d01672a1-0c3c-46da-85f9-6616fa6d4163.xml` | `success with warning` | `success` | 5 | no_movements, no_instrumentation, no_source_references, no_performance_information, no_external_references | `not_applicable` | `441` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/d6f46070-85df-4dda-b1f2-4e90530cf511.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `442` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/e5aed570-9caa-42f1-bc21-259a801f8d83.xml` | `success with warning` | `success` | 3 | no_movements, no_source_references, no_performance_information | `not_applicable` | `443` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/ec6dec55-b2a4-4b7f-a0c1-aba93dbeda62.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `444` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/ef9c5b1c-889e-47bd-80c8-37902eb9e1a6.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `445` | yes | 1 | committed |
| `dcm-catalogue-data/cnw/data-cnw/f8731077-58f9-4621-9d6c-1dc30b817c33.xml` | `success with warning` | `success` | 4 | no_movements, no_instrumentation, no_source_references, no_performance_information | `not_applicable` | `446` | yes | 1 | committed |
