# F5-R1 reproduction and execution record

Final runtime: `f5r1-667192fea216a940`, 158 files, external candidate `/private/tmp/www_f5r1_zgkq_pho/runtime/candidate`. Ruby 4.0.5, Bundler 4.0.15, PostgreSQL 14.23 and already installed locked dependencies were reused. This is not a cold dependency installation or public-clone test. No original setup/CI script was executed in the application repository.

`offline/contract_cases.json` freezes 131 synthetic environment/URL cases before the correction. Original and corrected probe records include expected/actual outcomes, dependency/child counts and connection/SQL counters. The seven supported URL controls also agree with the installed Rails resolver without application boot or endpoint contact. The old helper's 34 violations and three failing expanded focused groups are retained. The first standalone observer error is separate from those reproduced defects.

Real sequence: verify new server and unused names; create development/test databases; verify empty identities; guard probe; finite development setup; four-record demo import; capture development state/sentinels; bin/ci under inherited development settings; capture state; repeat development setup; capture state; stop owned PostgreSQL; independently verify process/socket absence. Complete selectors, including MEI_DIR, MEI_PROFILE and MEI_FIXTURE_KEYS_JSON, are directly retained in `validation/demo_import/invocation.json`. All runtime/schema/import/test Ruby subprocesses load the external exact-target guard via RUBYOPT. Maintenance access is confined to provisioning this new instance; application connections are limited to the declared target.

The CI log contains 19 focused tests / 2,462 assertions followed by 164 application tests / 2,586 assertions, all passing. The deliberate harmless child exit 23 tests propagation; optional gdiff absence is a fallback probe, not a failed required suite. Outer command UTC timestamps bound actual runs; Rails time-travel tests can change internal guard wall-clock timestamps. No further full suite followed the passing exact build.

Full development snapshots are retained only at `validation/before_ci/state_local_only.json`, `validation/after_ci/state_local_only.json` and `validation/after_setup/state_local_only.json` under the external run. `evidence/development_preservation.json` records their hashes, complete equality, counts and selected four-record facts. Snapshot data is excluded from the ZIP; an independent validator recomputes equality locally and verifies archive summaries. Owned log/temp sentinels remain in the external candidate.

The command ledger is authoritative for arguments, exits, build and target context; preliminary Git/observer failures are also retained in `evidence/`. Scripts are evidence and require fresh scoped authorization before reuse; do not restart retained instances.

| Command | Exit | Recorded result | Evidence |
|---|---:|---|---|
| before_matrix | 1 | FAIL | logs/before_matrix.log |
| before_focused | 1 | FAIL | logs/before_focused.log |
| before_matrix_02 | 1 | FAIL | logs/before_matrix_02.log |
| after_matrix | 1 | FAIL | logs/after_matrix.log |
| after_focused | 1 | FAIL | logs/after_focused.log |
| after_matrix_02 | 0 | PASS | logs/after_matrix_02.log |
| after_focused_02 | 0 | PASS | logs/after_focused_02.log |
| postgres_version | 0 | PASS | logs/postgres_version.log |
| initdb | 0 | PASS | logs/initdb.log |
| postgres_start | 0 | PASS | logs/postgres_start.log |
| f5r1_creation_admin_identity | 0 | PASS | logs/f5r1_creation_admin_identity.log |
| www_f5r1_development_zgkq_pho_absent | 0 | PASS | logs/www_f5r1_development_zgkq_pho_absent.log |
| www_f5r1_development_zgkq_pho_create | 0 | PASS | logs/www_f5r1_development_zgkq_pho_create.log |
| www_f5r1_development_zgkq_pho_identity | 0 | PASS | logs/www_f5r1_development_zgkq_pho_identity.log |
| www_f5r1_development_zgkq_pho_empty | 0 | PASS | logs/www_f5r1_development_zgkq_pho_empty.log |
| www_f5r1_test_zgkq_pho_absent | 0 | PASS | logs/www_f5r1_test_zgkq_pho_absent.log |
| www_f5r1_test_zgkq_pho_create | 0 | PASS | logs/www_f5r1_test_zgkq_pho_create.log |
| www_f5r1_test_zgkq_pho_identity | 0 | PASS | logs/www_f5r1_test_zgkq_pho_identity.log |
| www_f5r1_test_zgkq_pho_empty | 0 | PASS | logs/www_f5r1_test_zgkq_pho_empty.log |
| guard_probe | 0 | PASS | logs/guard_probe.log |
| setup_development | 0 | PASS | logs/setup_development.log |
| demo_import | 0 | PASS | logs/demo_import.log |
| before_ci | 0 | PASS | logs/before_ci.log |
| ci | 0 | PASS | logs/ci.log |
| after_ci | 0 | PASS | logs/after_ci.log |
| repeat_setup | 0 | PASS | logs/repeat_setup.log |
| after_setup | 0 | PASS | logs/after_setup.log |
| owned_process_before_stop | 0 | PASS | logs/owned_process_before_stop.log |
| postgres_stop | 0 | PASS | logs/postgres_stop.log |
