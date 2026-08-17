# Phase 2 Stage C focused-probe results

## Result in brief

All seven predeclared Stage C predictions were **confirmed within their stated bounds**. The five identifier-conflict results reuse and reconcile the canonical Stage A execution; none was re-imported. The CNW 67 and CNW 10 results combine namespace-aware source inspection, static inspection of the unchanged importer, and transactionally read-only observations of the preserved canonical database. The CNW 10 parser check operated only on an in-memory document.

Stage C added zero importer invocations and made zero API requests. The preserved canonical importer-invocation total remains one. Before and after Stage C database digests are identical, so this evaluation did not change the canonical database.

## Method and evidence lineage

| Item | Identity |
| --- | --- |
| Application baseline | `8b40722103acb36826a81b7bd1a90983435e9dd7` |
| Stage B evidence commit evaluated | `7e9196948936a0fafe1154f79ab067d806ab9db2` |
| Frozen protocol SHA-256 | `117f4cb568a1b214ae78debc9569ade44ddad3d8aacaa2ba24f44ff2ffcf293f` |
| Sample manifest SHA-256 | `210fbe9d2010389332fc620faa60092f765e08dda002ae23c396633137d0d72e` |
| Stage C method SHA-256 | `5cd3dc6886b018d26e08361473fce10de9b1009e38bff0d71d62ccba373479e0` |
| Canonical Stage A database | `phase2_stage_a_20260816_548dca1_02` |
| Expected and observed database digest | `05b783204073e38dc5a5418abda9f50ebc721c08b99313b3aa6c7bb2e9395a3d` |
| Evaluation date | 2026-08-16 |

The Stage C method was written and serialized successfully before any target XML or database value was read. Its predictions remain verbatim from the frozen protocol, in fields separate from observations and outcomes. All seven extracted source files matched the manifest size and SHA-256 before inspection.

The evidence sources were:

- namespace-aware, no-network parsing of the seven official XML files;
- static inspection of `Mei::Importer` at `app/services/mei/importer.rb` without instantiation or execution;
- the preserved Stage A reconciliation and canonical-results evidence;
- bounded direct database observations inside a repeatable-read, read-only transaction with `transaction_read_only=on`;
- for CNW 10 only, Nokogiri's `remove_namespaces!` operation on an in-memory document, without writing the source back to disk.

Raw, sanitized evidence is preserved under `tmp/phase2_evaluation/stage_c/`. Its principal artifact hashes are:

| Artifact | SHA-256 |
| --- | --- |
| `source_observations.json` | `361df659936f693cec1e170e114a9b397bec4c4e76f73e57f0f783af8db8bd3c` |
| `parser_namespace_observation.json` | `4235076058002a8e43b8298b3b4977c712a75d6f888f0960a5ff9ec021b9d793` |
| `static_importer_observations.json` | `b48bc3d47d89666f86a4858ce44aef34fc44f12cbd6f232e28e8765ed4d01629` |
| `database_digest_before.json` | `2af5819d0d0f2c33de5b1cb97c47d51c6142da9c4349c1336540ff283c2c0a6f` |
| `database_observations.json` | `07239503499e7aa73df2af9ddc9536bdbecdf48b3c2249e236dc308d85d21d10` |
| `database_digest_after.json` | `9c7cf3fe153dc9bcd92d489d564e517d0806cb637bc2a4c2f8bf71f5e6c1371a` |
| `focused_probe_results.json` | `58b259c856b8f8e1cb39534242b4bb87f84d2f66020cb3472b00a402cf3390cb` |

## Prediction versus observation

| Probe | Frozen prediction | Observed outcome | Evidence source | Result |
| --- | --- | --- | --- | --- |
| `cnw0027.xml` | Duplicate value `27` under Opus and CNW violates the per-work/value unique constraint; transaction fails | Namespace-aware source inspection found `27` under Opus and CNW. The canonical log is a failure in the per-work/value uniqueness category; `work_id` is null, no work or child row survives, and the transaction outcome is `rolled_back/no work remains`. Exception class: `exception class not directly observable`. | Official XML observation; canonical Stage A reconciliation; read-only database observation | **confirmed** |
| `cnw0064.xml` | Duplicate value `64` under CNW and FS violates the same constraint; transaction fails | Namespace-aware source inspection found `64` under CNW and FS. The canonical log is a failure in the same category; `work_id` is null, no work or child row survives, and the transaction outcome is `rolled_back/no work remains`. Exception class: `exception class not directly observable`. | Official XML observation; canonical Stage A reconciliation; read-only database observation | **confirmed** |
| `cnw0070.xml` | Duplicate value `43` under Opus and CNS violates the same constraint; transaction fails | Namespace-aware source inspection found `43` under Opus and CNS. The canonical log is a failure in the same category; `work_id` is null, no work or child row survives, and the transaction outcome is `rolled_back/no work remains`. Exception class: `exception class not directly observable`. | Official XML observation; canonical Stage A reconciliation; read-only database observation | **confirmed** |
| `cnw0081.xml` | Duplicate value `10` under CNS and FS violates the same constraint; transaction fails | Namespace-aware source inspection found `10` under CNS and FS. The canonical log is a failure in the same category; `work_id` is null, no work or child row survives, and the transaction outcome is `rolled_back/no work remains`. Exception class: `exception class not directly observable`. | Official XML observation; canonical Stage A reconciliation; read-only database observation | **confirmed** |
| `cnw0237.xml` | Duplicate value `237` under CNW and CNS violates the same constraint; transaction fails | Namespace-aware source inspection found `237` under CNW and CNS. The canonical log is a failure in the same category; `work_id` is null, no work or child row survives, and the transaction outcome is `rolled_back/no work remains`. Exception class: `exception class not directly observable`. | Official XML observation; canonical Stage A reconciliation; read-only database observation | **confirmed** |
| `cnw0067.xml` | With no direct work date, the descendant selector chooses the first nested bibliographic creation date, `1913-04-29`, and stores 1913 as if it were the work composition year | The official work has no direct `creation/date`. Its first descendant creation date is `1913-04-29` inside a bibliography entry. The unchanged importer prioritizes `.//creation//date`; the committed canonical work stores `composition_date=1913-04-29` and `composition_year=1913`. | Official XML observation; static importer inspection; canonical Stage A reconciliation; read-only database observation | **confirmed** |
| `cnw0010.xml` | Namespace removal permits technical processing of elements using the explicit `m:` prefix, while discarding namespace identity | The source binds `m` to the MEI namespace and contains 335 explicitly `m:`-prefixed elements. In memory, `remove_namespaces!` reduced elements retaining a namespace URI or `m` prefix to zero while representative title, resource, and relation values remained available to unqualified XPath. The canonical run committed the record and bounded child data. | Official XML observation; in-memory parser observation; static importer inspection; canonical Stage A reconciliation; read-only database observation | **confirmed** |

The five failed records each have one surviving failure `ImportLog`, but no work and no catalogue-identifier, movement, instrumentation, source-reference, performance, or external-reference rows. Their warning categories are `no_movements`, `no_source_references`, and `no_performance_information`. Static inspection explains the bounded mechanism: the importer de-duplicates identifiers by `(identifier_type, value)`, whereas the database requires `(work_id, value)` to be unique. Values repeated under different labels therefore survive extraction but conflict when child rows are persisted. Work and children are inside the file transaction; the failure log is written after rollback.

## CNW 67: nested-date selection

The official source locator for a direct work date is:

`/mei:mei/mei:meiHead/mei:workList/mei:work[1]/mei:creation/mei:date`

It selects zero nodes. The descendant candidates under the work, in document order, are:

| Position | Value | Structural context | Direct work-composition date? |
| ---: | --- | --- | --- |
| 1 | `1913-04-29` | bibliography-entry creation date | no |
| 2 | `1930-02-05` | bibliography-entry creation date | no |
| 3 | `1913` | expression creation date | no |
| 4 | `1916` | expression creation date | no |

`Mei::Importer#extract` passes `.//creation//date` first to `Mei::Importer#first_node`; `at_xpath` therefore returns the first descendant match. `Mei::Importer#extract_year` then checks `isodate`, `notbefore`, `notafter`, and text in that order.

The canonical record imported successfully with stable source identifier `work_d1e10691050`, title `Canto serioso`, stored composition date `1913-04-29`, and stored composition year `1913`. Its warnings were `no_movements`, `no_source_references`, and `no_performance_information`. Stored child counts were four catalogue identifiers, zero movements, three instrumentations, zero source references, zero performances, and one external reference.

This confirms the predicted selector behavior. It does not establish that the selected bibliographic date is a scholarly composition date; the structural context shows that it is not a direct work-composition date.

## CNW 10: namespace-prefix handling

The original root is `{http://www.music-encoding.org/ns/mei}mei`, using the MEI URI as its default namespace. Nodes within the record also bind the explicit `m` prefix to that same URI. Namespace-aware inspection counted 335 explicitly `m:`-prefixed elements. Bounded relevant counts were:

| Local name | Explicitly `m:`-prefixed elements |
| --- | ---: |
| `biblList` | 2 |
| `title` | 17 |
| `perfMedium` | 14 |
| `perfRes` | 36 |
| `castList` | 1 |
| `relation` | 1 |
| `change` | 31 |

Representative prefixed values included title `Forspil`, performance resource `fl.` with `codedval=wa` and `count=1`, and a relative `hasArrangement` target. Before removal, namespace-aware XPath found one work while unqualified `//work` found none. After applying the same in-memory `remove_namespaces!` operation used by `Mei::Importer#parse_document`, zero elements retained a namespace URI or `m` prefix, unqualified XPath found the work, and the representative title, resource, and relation values remained selectable. The source file was not written.

The canonical Stage A record imported successfully with:

- stable source identifier: `work_d1e589579`;
- selected title: `Musik til Ludvig Holsteins skuespil "Tove"`;
- catalogue number: `10`;
- four identifiers in database primary-key order, without a source-order claim: CNW `10`, CNU `I/6`, CNS `348`, and FS `43`;
- composition date `1907–08` and year `1907`;
- child counts: four catalogue identifiers, zero movements, 16 instrumentations, zero source references, zero performances, and two external references;
- warning categories: `no_movements`, `no_source_references`, and `no_performance_information`.

This confirms that namespace removal allowed bounded technical processing of this one prefixed record while discarding namespace identity. It does not establish general MEI compatibility or semantic fidelity for every extracted field.

## Database preservation checks

All three Stage C database processes used repeatable-read, read-only transactions and verified `transaction_read_only=on`. The before and after digests both equal the frozen canonical digest:

`05b783204073e38dc5a5418abda9f50ebc721c08b99313b3aa6c7bb2e9395a3d`

| Table | Before | After |
| --- | ---: | ---: |
| composers | 1 | 1 |
| works | 441 | 441 |
| catalogue_identifiers | 1,702 | 1,702 |
| movements | 0 | 0 |
| instrumentations | 1,651 | 1,651 |
| source_references | 0 | 0 |
| performances | 0 | 0 |
| external_references | 2,001 | 2,001 |
| import_logs | 446 | 446 |

All checked orphan counts were zero. The preserved Stage A evidence still records one canonical importer invocation and no retry; Stage C added zero importer invocations. Stage C made zero API requests and attempted no database write.

## Limitations

- Exception classes were not directly observable for the five internally logged failures, so none was inferred from message text.
- No API behavior was tested in Stage C.
- No importer or application correction was made.
- Successful handling of the namespace prefix in one record does not establish general compatibility with MEI.
- Agreement between seven predeclared predictions and observations is not a general accuracy measure; no overall accuracy percentage was calculated.
- The nested-date result establishes the baseline selector's technical behavior, not the scholarly meaning or correctness of the chosen date.
