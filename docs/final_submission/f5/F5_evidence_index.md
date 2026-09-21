# F5 evidence index

Paths below are review-archive relative unless linked into the proposed repository. Runtime/source expectations and results are separate; no aggregate accuracy percentage is inferred.

| Evidence | Location / meaning |
|---|---|
| Accepted history | [F4 completion](../f4/F4_completion.md), [F4 checks](../f4/F4_checks.json), [F3APIcontract](../f3/F3_api_contract.md), F1/F2/F2-R1/F3 documents unchanged |
| Baseline/preservation | preservation/baseline/ and preservation/final/;968 safe starting files, exact preimages/patch, user Git vs internal checkpoint distinction |
| Scope incident | preservation/read_scope_incident.json; P5-01FAIL; no secret fingerprint/content copied |
| Runtime identities | evidence/candidate_a_manifest_v4.json, evidence/candidate_b_manifest.json, targets/, evidence/postgres_resource.json |
| Full release proposal | release/candidate_manifest.json, release/candidate_verification.json;255 positive paths, separate from158runtime build |
| Commands and failures | evidence/commands.jsonl, logs/, evidence/release_implementation_manifest_v*.json, schema/transaction/HTTP observer corrections |
| Frozen source expectations | acceptance/f5_smoke/official_smoke_expectations.json and demo_expectations.json; pinned sixrecord hashes and independent source-derived selected objects |
| Official observations | validation/official_observe_02/;14 API+3 HTML, exactsource/SQL/API comparison, final candidate; observe01historical attempt retained |
| Demo HTTP observations | validation/demo_http_smoke_02/; fiveAPI/fiveHTML, actualownedlauncher, selectedbodies; attempt01failure retained |
| Full suites / CI | logs/f5_suite_02.log, logs/f5_ci.log, logs/f5_replay_suite.log; each 164/2586, focused15/297 |
| Data preservation | evidence/final_demo_ci_replay_comparison_v2.json; fulltablesnapshots staylocalonly |
| Guard coverage / shutdown | evidence/final_guard_coverage_v3.json, per-run guardJSONL, evidence/resource_shutdown.json |
| Original F4 reviewer supplement | acceptance/f5_smoke/historical_supplement/restored/validation/api_corpus_01/independent_SQL_frozen_expectations.json preserves17expectedobjects; baseline independent supplement audit and original archive hashes remain alongside |
| Archive validation | Adjacent producer validation and separate independent validation; CRC/manifest/exactpayload readback, not a technical gate override |

Historical findings retain34omissions, one nested-item exclusion, one unresolved relation, purposive1,800-unit semantic sampling, serial warm-cache in-process timing with guard overhead and developer-only walkthrough/zoom limits. The original F3PARTIAL documents remain history; F3-Z1 closed actualzoom without application changes. F4's original archive omission is visible and repaired only through its additive accepted supplement. No F4 runtime rerun here.

Follow-up participant evaluation is **NOT_EVALUATED_BY_USER_DECISION**. Local release preparation remains **PARTIAL** due the read-scope incident; public release and unauthenticated fresh-clone checks remain pending.
