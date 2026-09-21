# F5-R1 evidence index

Archive-relative evidence is listed below. Existing repository links point to immutable historical documents.

| Subject | Evidence |
|---|---|
| Current bounded contract | input_contract/F5R1_Specification.md, F5R1_Acceptance.md and context/F5R1_target_contract.md |
| Reviewer findings and historical limits | input_contract/F5_Review.md; [original F5 completion](../f5/F5_completion.md); [original F5 decisions](../f5/F5_decisions.md) |
| Starting 981 safe identities | baseline/safe_inventory_before.json, preservation_before.json, result.json and git_before.json |
| Exact correction | preservation/F5R1_only.patch, preimages/, files/; three old files and nine additive documents |
| Prospective offline cases | offline/contract_cases.json; before_matrix.json; after_matrix_02.json; logs/before_focused.log and after_focused_02.log |
| Final runtime and guarded CI | evidence/runtime_manifest.json; evidence/runtime_audit.json; validation/ci/ and logs/ci.log |
| Demo selectors and facts | input_contract/context/F5_demo_expectations.json; validation/demo_import/invocation.json; evidence/development_preservation.json |
| Target creation and live guards | targets/; evidence/postgres_resource.json; validation/*/guard_*.jsonl; guard probe is separated from normal execution |
| Preservation and proposed tree | preservation/result.json; release/candidate_manifest.json; release/candidate_validation.json |
| Closure | evidence/resource_shutdown.json; evidence/shutdown_independent.json |
| Review integrity | MANIFEST.sha256, packaging/ALLOWLIST.json, adjacent producer and independent validations |

F5's original process failure remains FAIL/NONCOMPLIANT. Its recorded positive runtime observations remain historical, while R5-C1/R5-C2 supersede the old unconditional target-isolation claim. F5-R1's independent validation is a separate algorithm authored in this task; it does not replace the user's external review.

F4 source-fidelity, SQL/API, omissions and timing denominators remain distinct. Historical F3/F3-Z1 UI/actual-zoom evidence is carried forward under unchanged application files; there is no new browser/participant result here.
