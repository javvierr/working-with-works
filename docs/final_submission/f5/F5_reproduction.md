# F5 local reproduction record

Runtime candidate `f5-e152006d650d0a93`:158 explicit files from current accepted working bytes; same byte/mode manifest in candidate_a and candidate_b. Candidate copies at `/private/tmp/www_f5_vr7ayt69/candidate_a` and `/private/tmp/www_f5_vr7ayt69/candidate_b`. The full255path release proposal is separately retained under this run's `release_candidate/`. None is a Git clone or published release.

Ruby 4.0.5, Bundler 4.0.15, PostgreSQL 14.23 and already installed locked gems were used; no installation/network audit was performed. README dependency/setup/demo/test/CI/start commands are the intended portable interface. Actual external wrappers supply the explicit private socket URLs, one worker and RUBYOPT live guard; those machine-specific guards are evaluation instrumentation, not prerequisites for ordinary use.

New socket-only PostgreSQL `/private/tmp/www_f5_pg_gvjk81ac`, port 55441, bootstrap user javier, peer authentication and0700 directories. Fresh verified-absent databases: `www_f5_development_vr7ayt69`, `www_f5_test_vr7ayt69`, `www_f5_official_vr7ayt69`, `www_f5_replay_development_vr7ayt69`, `www_f5_replay_test_vr7ayt69`. Each target descriptor/creation check is in `targets/`; live guard evidence covers every Ruby/schema/test/import child, including refused implicit preparation. No retained prior database was used. Original Rails fixtures do clean up their own newly made fixtures/temp artifacts; that inherited test behaviour is disclosed.

Final direct and CI/replay suites each 164tests/2586 assertions. FocusedCI15tests/297 assertions. Earlier failures remain in the ledger, with observer/launcher corrections and preserved preimages. Raw first-suite output contains four complete table-snapshot diff lines: those are retained locally and replaced in the review projection by explicit byte/digest omission records; selected API bodies are retained in full.

The two app smoke processes used bin/dev with new 127.0.0.1ports and stopped after HTTP requests. No fresh visual/keyboard/zoom observation. Database shutdown is confirmed in `evidence/resource_shutdown.json`; data retained. Do not blindly rerun archived scripts or restart this retained service. A new review invocation must allocate fresh targets and revalidate identities.

The authoritative command ledger includes UTC start/end, exact argv, target/build references and log paths. Guard event wall clocks can follow Rails' test time-travel inside a test; outer command UTC and monotonic event filenames bound the real runs.

| Command ID | Exit | Recorded result | Evidence |
|---|---:|---|---|
| f5_initdb_01 | 1 | FAIL | logs/f5_initdb_01.log |
| f5_initdb_02 | 0 | PASS | logs/f5_initdb_02.log |
| f5_pg_start_02 | 0 | PASS | logs/f5_pg_start_02.log |
| f5_creation_01_admin_identity | 2 | FAIL | logs/f5_creation_01_admin_identity.log |
| f5_creation_02_admin_identity | 0 | PASS | logs/f5_creation_02_admin_identity.log |
| www_f5_development_vr7ayt69_absent | 0 | PASS | logs/www_f5_development_vr7ayt69_absent.log |
| www_f5_development_vr7ayt69_create | 0 | PASS | logs/www_f5_development_vr7ayt69_create.log |
| www_f5_development_vr7ayt69_identity | 0 | PASS | logs/www_f5_development_vr7ayt69_identity.log |
| www_f5_development_vr7ayt69_empty | 0 | PASS | logs/www_f5_development_vr7ayt69_empty.log |
| www_f5_test_vr7ayt69_absent | 0 | PASS | logs/www_f5_test_vr7ayt69_absent.log |
| www_f5_test_vr7ayt69_create | 0 | PASS | logs/www_f5_test_vr7ayt69_create.log |
| www_f5_test_vr7ayt69_identity | 0 | PASS | logs/www_f5_test_vr7ayt69_identity.log |
| www_f5_test_vr7ayt69_empty | 0 | PASS | logs/www_f5_test_vr7ayt69_empty.log |
| www_f5_official_vr7ayt69_absent | 0 | PASS | logs/www_f5_official_vr7ayt69_absent.log |
| www_f5_official_vr7ayt69_create | 0 | PASS | logs/www_f5_official_vr7ayt69_create.log |
| www_f5_official_vr7ayt69_identity | 0 | PASS | logs/www_f5_official_vr7ayt69_identity.log |
| www_f5_official_vr7ayt69_empty | 0 | PASS | logs/www_f5_official_vr7ayt69_empty.log |
| www_f5_replay_development_vr7ayt69_absent | 0 | PASS | logs/www_f5_replay_development_vr7ayt69_absent.log |
| www_f5_replay_development_vr7ayt69_create | 0 | PASS | logs/www_f5_replay_development_vr7ayt69_create.log |
| www_f5_replay_development_vr7ayt69_identity | 0 | PASS | logs/www_f5_replay_development_vr7ayt69_identity.log |
| www_f5_replay_development_vr7ayt69_empty | 0 | PASS | logs/www_f5_replay_development_vr7ayt69_empty.log |
| www_f5_replay_test_vr7ayt69_absent | 0 | PASS | logs/www_f5_replay_test_vr7ayt69_absent.log |
| www_f5_replay_test_vr7ayt69_create | 0 | PASS | logs/www_f5_replay_test_vr7ayt69_create.log |
| www_f5_replay_test_vr7ayt69_identity | 0 | PASS | logs/www_f5_replay_test_vr7ayt69_identity.log |
| www_f5_replay_test_vr7ayt69_empty | 0 | PASS | logs/www_f5_replay_test_vr7ayt69_empty.log |
| f5_guard_probe | 0 | PASS | logs/f5_guard_probe.log |
| f5_setup_development | 1 | FAIL | logs/f5_setup_development.log |
| f5_guard_probe_02 | 0 | PASS | logs/f5_guard_probe_02.log |
| f5_setup_development_02 | 0 | PASS | logs/f5_setup_development_02.log |
| f5_setup_official | 0 | PASS | logs/f5_setup_official.log |
| f5_demo_import | 0 | PASS | logs/f5_demo_import.log |
| official_empty_01 | 0 | PASS | logs/official_empty_01.log |
| f5_demo_first | 0 | PASS | logs/f5_demo_first.log |
| official_import_01 | 0 | PASS | logs/official_import_01.log |
| official_observe_01 | 0 | PASS | logs/official_observe_01.log |
| f5_setup_development_repeat | 0 | PASS | logs/f5_setup_development_repeat.log |
| f5_demo_after_setup | 0 | PASS | logs/f5_demo_after_setup.log |
| f5_demo_reimport | 0 | PASS | logs/f5_demo_reimport.log |
| f5_demo_after_repeat | 0 | PASS | logs/f5_demo_after_repeat.log |
| f5_setup_test | 0 | PASS | logs/f5_setup_test.log |
| f5_suite | 1 | FAIL | logs/f5_suite.log |
| f5_transaction_guard_diagnostic_01 | 0 | PASS | logs/f5_transaction_guard_diagnostic_01.log |
| f5_transaction_guard_diagnostic_02 | 0 | PASS | logs/f5_transaction_guard_diagnostic_02.log |
| f5_guard_probe_03 | 0 | PASS | logs/f5_guard_probe_03.log |
| f5_setup_development_03 | 1 | FAIL | logs/f5_setup_development_03.log |
| f5_schema_comparison_01 | 0 | PASS | logs/f5_schema_comparison_01.log |
| f5_schema_cast_proof_01 | 0 | PASS | logs/f5_schema_cast_proof_01.log |
| f5_setup_development_04 | 0 | PASS | logs/f5_setup_development_04.log |
| f5_setup_test_02 | 0 | PASS | logs/f5_setup_test_02.log |
| f5_suite_02 | 0 | PASS | logs/f5_suite_02.log |
| f5_demo_before_ci_final | 0 | PASS | logs/f5_demo_before_ci_final.log |
| f5_ci | 0 | PASS | logs/f5_ci.log |
| f5_demo_after_ci_final | 0 | PASS | logs/f5_demo_after_ci_final.log |
| f5_replay_setup_development | 0 | PASS | logs/f5_replay_setup_development.log |
| f5_replay_setup_test | 0 | PASS | logs/f5_replay_setup_test.log |
| f5_replay_demo_import | 0 | PASS | logs/f5_replay_demo_import.log |
| f5_replay_suite | 0 | PASS | logs/f5_replay_suite.log |
| f5_replay_demo_state | 0 | PASS | logs/f5_replay_demo_state.log |
| f5_setup_development_repeat_final | 0 | PASS | logs/f5_setup_development_repeat_final.log |
| f5_demo_after_setup_final | 0 | PASS | logs/f5_demo_after_setup_final.log |
| f5_demo_reimport_final | 0 | PASS | logs/f5_demo_reimport_final.log |
| f5_demo_after_repeat_final | 0 | PASS | logs/f5_demo_after_repeat_final.log |
| official_observe_02 | 0 | PASS | logs/official_observe_02.log |
| f5_demo_http_smoke_01 | 0 | FAIL | validation/demo_http_smoke_01/result.json |
| f5_demo_http_smoke_02 | 0 | PASS | validation/demo_http_smoke_02/result.json |
| f5_setup_official_02 | 0 | PASS | logs/f5_setup_official_02.log |
| f5_guard_probe_04 | 0 | PASS | logs/f5_guard_probe_04.log |
| f5_demo_after_http_final | 0 | PASS | logs/f5_demo_after_http_final.log |
| f5_owned_pg_identity_before_stop | 0 | PASS | logs/f5_owned_pg_identity_before_stop.log |
| f5_owned_pg_stop | 0 | PASS | logs/f5_owned_pg_stop.log |

A zero diagnostic exit only means the observation was captured: `f5_transaction_guard_diagnostic_01` recorded the instrumentation defect (F5PGGuard::Refusal instead of the expected uniqueness exception), not a semantic PASS. Its corrected second diagnostic returned the expected ActiveRecord exception. The ledger preserves original process exits; the substantive interpretation is separate. CI’s child exit 23 is the deliberate failure-propagation test; optional Minitest gdiff probes exited 127 before the available diff fallback. None is hidden or counted as a required failed suite.
