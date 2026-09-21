# F2-R1 decisions

F2-R1 implements only truthful held-item availability. Existing document counts, arrays, projection state and unsupported disclosure are sufficient; no helper, schema, model, importer, mapping, projection-version, API-shape or data-repair change was needed.

| Persisted condition | Source-detail wording |
|---|---|
| Every source summary | “N represented item nodes” |
| Empty represented array and exact `unsupported_items == 0` | “No held-item nodes are supplied for this description.” |
| Empty represented array and positive integer unsupported count | “No held-item descriptions are represented here. This catalogue record contains unsupported item nodes; see Unsupported or unresolved details.” |
| Empty represented array and missing/null/otherwise unknown count | “No held-item descriptions are represented here. The number of unsupported item nodes in this catalogue record is unknown; supplied-item absence cannot be determined.” |

The unsupported wording belongs to the catalogue record. It does not claim which source owns an omitted item. The view does not derive local unsupported totals or completeness from the issue list. C5 asserts identical neutral messages for an actually empty source and the source containing the omission. C6 has 52 issues: 51 missing-ID source issues followed by the missing-ID item's issue; the first 50 contain no item issue, yet the exact unsupported-item count remains one and no absence claim is shown.

The original extracted review probe and the new C2 are intentionally distinct. The older probe contains two actual unsupported items, one under an unrepresented source and one under the represented stub (record counts 2 actual / 0 represented / 2 unsupported). F2-R1 C2 isolates one missing-ID item under one represented stub (1 / 0 / 1). The retained C2 run failed directly on the original false sentence before the partial changed, then passed after correction. Existing F2 S2-07/E2-02 rows remain historical; the new register supplies the previously missing assertions.

The correction adds `test/integration/f2r1_catalogue_sources_test.rb` and three distinctly named maintained validation files: `script/f2r1_validation/f2r1_guard.rb`, `f2r1_source_api_check.rb` and `f2r1_sql_probe_support.rb`. Existing F2 tests, tools and reports remain unchanged. The new source validator retains the original deep comparison and source facts, adding only guarded target adaptation and source-scoped availability assertions. The negative control changes an expected item-parent identifier, leaves the response and database untouched, and is rejected by the same comparator used for real requests.

All runtime execution used selective external copies. The frozen baseline copied 143 explicit files; corrected build manifests identify 147 files, including the four new test/tool files. `validation/c2_red_build.json` identifies the old partial; `validation/c2_green_build.json`, `validation/revised_suite_build.json`, `validation/six_record_check_build.json` and `validation/build_1.json` identify the corrected executions. `evidence/commands.jsonl` records actual commands, UTC times and exits. The intended correction-only file inventory and patch are `evidence/F2R1_intended_files.json` and `evidence/F2R1_only.patch`.

The new guard requires an external F2-R1 application copy, explicit newly created target/creation evidence, test environment, one worker, exact local PostgreSQL 14.23 socket/database/user/data identity and no inherited PostgreSQL overrides. It checks live identity before ordinary SQL and real work requests; rollback cleanup avoids injecting a new query into an aborted transaction. Wrong-identity controls refused both synthetic and live-wrong-expected targets with zero write-callback calls. No existing database, retained F1/F2 server, service registration, dependency or role change was used.

Reproduction is evidence-driven, not an instruction to restart retained resources or blindly rerun archived scripts. The reviewed coordinator is `scripts/run_revision.py`; its recorded source check invocation is `revised_api source_api six_record_check`. It launches the copied `script/f2r1_validation/f2r1_source_api_check.rb` with explicit `F2R1_APP_ROOT`, `F2R1_TARGET_JSON`, `F2R1_GUARD_LOG`, `F2R1_BUILD_ID`, `F2R1_VALIDATION_OUTPUT`, `F2R1_EXPECTATIONS_JSON`, `F2R1_FIELD_CONTRACT_JSON`, `F2R1_F1_EXPECTATIONS_JSON` and `F2R1_SOURCE_DIR`, plus a declared `DATABASE_URL`, `RAILS_ENV=test`, `RACK_ENV=test` and `PARALLEL_WORKERS=1`. Its source/oracle locations within this retained run are:

| Input | Location | SHA-256 |
|---|---|---|
| Frozen F2 source oracle | `prior/F2/acceptance/f2_source_expectations_v1.json` | `991037f3dd3e34df7a4dfc2d89b34dddb31dab260807018c8ad25d89ca6f9425` |
| Frozen F2 selected-field contract | `prior/F2/acceptance/f2_selected_fields_v1.json` | `226bd7794098a608ad2a7f5e15a6debe6754e61f983cb6f4dae641af8db02ec6` |
| Frozen F1 regression oracle | `acceptance/f1_expectations_v1.json` | `1874d9b9488a38354240f884b2a42c746559965e5e0a78dce54668fe57d9f792` |
| Six allowed source paths/hashes | `prior/F2/acceptance/input_manifest.json`; copied inputs at `six_inputs/` | Individual hashes retained in `validation/six_record_check/result.json` |

The six copied corpus files and whole application copies remain external retained execution material, not ZIP payload. A later authorized rerun must create a fresh isolated instance/targets, reconstruct only those six inputs from the manifest, and supply new evidence/output locations. A nonempty API target cannot be silently re-imported; observation-only continuation requires an explicit matching F2-R1 import proof. The suite coordinator uses `harness/run_revision_suite.rb`; its focused C2 selection was `/missing_id_only/`. The installed Minitest emitted a name-option deprecation notice without affecting the expected red/green outcomes; logs retain it.

Every new F2-R1 synthetic blueprint and imported test copy is retained. Inherited tests may clean up their own newly generated temporary fixtures; their behavior was neither changed nor described as complete retention. The focused GET regression guards the current XML constructor and retained-source `File.read`, `File.binread` and `File.open` paths, supported by static review; it is not a universal operating-system file-access monitor.

Final preservation and archive validation occur after documents are written. `evidence/preservation_comparison.json` and the adjacent review-ZIP validation are authoritative for those final checks. No new upgrade experiment or F3 work is part of this correction.
