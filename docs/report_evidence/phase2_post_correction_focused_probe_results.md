# Phase 2 post-correction Stage C focused-probe results

## Result in brief

Six probes **changed as intended** after Packages 1–4: all five cross-type identifier conflicts now commit with both typed values retained, and CNW 67 no longer stores a nested bibliographic date as a work-composition date. The bounded CNW 10 namespace-removal behavior was **unchanged within probe scope**.

No importer was rerun. The corrected canonical database remained read-only and unchanged, baseline evidence remains preserved, and no API behavior was evaluated. These seven focused probes are not a general correctness or accuracy measure; no overall accuracy percentage was calculated.

## Method and evidence lineage

The comparison retained five distinct concepts for each probe: the original frozen prediction, the confirmed baseline observation, the post-correction expectation, the observed post-correction outcome, and a factual change assessment. Expected directions were treated as hypotheses rather than required results.

| Item | Identity |
| --- | --- |
| Application HEAD | `88768c9a94352346a31d4d1a922aab8819eb3275` |
| Package-4 parent | `c01bd32417dd381c15dfa351f6da8d6d7f5de11d` |
| Frozen protocol SHA-256 | `117f4cb568a1b214ae78debc9569ade44ddad3d8aacaa2ba24f44ff2ffcf293f` |
| Sample manifest SHA-256 | `210fbe9d2010389332fc620faa60092f765e08dda002ae23c396633137d0d72e` |
| Confirmed baseline Stage C report SHA-256 | `cbfbc5c7a22b71981d27f394d64705d5d3f96e15ef75d5422cc3848900213a70` |
| Frozen post-correction method SHA-256 | `b637e95345be68ae7e86a5a14a3759eb2f91f2a23508c2e2dc8ab13d6c3613b1` |
| Canonical collector SHA-256 | `0f69ea0c7aa1b2fb19457ab342bf23ba456adb4972c18b96423669072530ab24` |
| Preserved corrected database | `phase2_post_correction_stage_a_20260817_c01bd32_01` |
| Before and after database digest | `ee61baab1f1032026a32c9e4df9e403847e8c6ad0b3011009be242beb6fe4ce9` |

Before semantic observation, the seven source files matched the frozen manifest and the method was serialized and hashed. The sole canonical collection used namespace-aware, no-network Nokogiri parsing; static importer inspection without instantiation; and repeatable-read, read-only database transactions with `transaction_read_only=on`. CNW 10's namespace removal occurred only on an in-memory parse and was not written to disk.

A preliminary launcher selected an incompatible operating-system Ruby and stopped before the collector loaded; it performed zero XML parses and zero database connections. The canonical collector then ran once with the reviewed frozen Ruby toolchain and was not retried.

## Baseline versus corrected observations

| Probe | Original frozen prediction | Confirmed baseline observation | Post-correction expectation | Observed post-correction outcome | Change assessment |
| --- | --- | --- | --- | --- | --- |
| `cnw0027.xml` | Duplicate value `27` under Opus and CNW violates the per-work/value unique constraint; transaction fails | Namespace-aware source inspection found `27` under Opus and CNW. The canonical log is a failure in the per-work/value uniqueness category; `work_id` is null, no work or child row survives, and the transaction outcome is `rolled_back/no work remains`. Exception class: `exception class not directly observable`. | Successful committed import; both typed identifiers survive; direct CNW `27` supplies `Work.catalogue_number`. | Source value `27` occurs under Opus/CNW. The corrected log is `success`, its work link is non-null, one work committed, catalogue number `27` is stored, and the equal value survives under CNW/Opus. No exact typed duplicate or rollback remains. Children: identifiers 5; movements 0; instrumentations 20; sources 0; performances 36; external references 3. Warnings: `no_movements`, `no_source_references`. | `changed_as_intended` |
| `cnw0064.xml` | Duplicate value `64` under CNW and FS violates the same constraint; transaction fails | Namespace-aware source inspection found `64` under CNW and FS. The canonical log is a failure in the same category; `work_id` is null, no work or child row survives, and the transaction outcome is `rolled_back/no work remains`. Exception class: `exception class not directly observable`. | Successful committed import; both typed identifiers survive; direct CNW `64` supplies `Work.catalogue_number`. | Source value `64` occurs under CNW/FS. The corrected log is `success`, its work link is non-null, one work committed, catalogue number `64` is stored, and the equal value survives under CNW/FS. No exact typed duplicate or rollback remains. Children: identifiers 5; movements 0; instrumentations 2; sources 0; performances 39; external references 0. Warnings: `no_movements`, `no_source_references`, `no_external_references`. | `changed_as_intended` |
| `cnw0070.xml` | Duplicate value `43` under Opus and CNS violates the same constraint; transaction fails | Namespace-aware source inspection found `43` under Opus and CNS. The canonical log is a failure in the same category; `work_id` is null, no work or child row survives, and the transaction outcome is `rolled_back/no work remains`. Exception class: `exception class not directly observable`. | Successful committed import; both typed identifiers survive; direct CNW `70` supplies `Work.catalogue_number`. | Source value `43` occurs under Opus/CNS. The corrected log is `success`, its work link is non-null, one work committed, catalogue number `70` is stored, and the equal value survives under CNS/Opus. No exact typed duplicate or rollback remains. Children: identifiers 5; movements 0; instrumentations 5; sources 0; performances 22; external references 1. Warnings: `no_movements`, `no_source_references`. | `changed_as_intended` |
| `cnw0081.xml` | Duplicate value `10` under CNS and FS violates the same constraint; transaction fails | Namespace-aware source inspection found `10` under CNS and FS. The canonical log is a failure in the same category; `work_id` is null, no work or child row survives, and the transaction outcome is `rolled_back/no work remains`. Exception class: `exception class not directly observable`. | Successful committed import; both typed identifiers survive; direct CNW `81` supplies `Work.catalogue_number`. | Source value `10` occurs under CNS/FS. The corrected log is `success`, its work link is non-null, one work committed, catalogue number `81` is stored, and the equal value survives under CNS/FS. No exact typed duplicate or rollback remains. Children: identifiers 5; movements 0; instrumentations 1; sources 0; performances 8; external references 1. Warnings: `no_movements`, `no_source_references`. | `changed_as_intended` |
| `cnw0237.xml` | Duplicate value `237` under CNW and CNS violates the same constraint; transaction fails | Namespace-aware source inspection found `237` under CNW and CNS. The canonical log is a failure in the same category; `work_id` is null, no work or child row survives, and the transaction outcome is `rolled_back/no work remains`. Exception class: `exception class not directly observable`. | Successful committed import; both typed identifiers survive; direct CNW `237` supplies `Work.catalogue_number`. | Source value `237` occurs under CNW/CNS. The corrected log is `success`, its work link is non-null, one work committed, catalogue number `237` is stored, and the equal value survives under CNS/CNW. No exact typed duplicate or rollback remains. Children: identifiers 4; movements 0; instrumentations 7; sources 0; performances 39; external references 4. Warnings: `no_movements`, `no_source_references`, `non_exact_performance_date_not_stored`. | `changed_as_intended` |
| `cnw0067.xml` | With no direct work date, the descendant selector chooses the first nested bibliographic creation date, `1913-04-29`, and stores 1913 as if it were the work composition year | The official work has no direct `creation/date`. Its first descendant creation date is `1913-04-29` inside a bibliography entry. The unchanged baseline importer prioritizes `.//creation//date`; the committed baseline work stores `composition_date=1913-04-29` and `composition_year=1913`. | Import still succeeds, but composition date and year remain null because no supported direct work-composition date exists; the missing-date warning is recorded. | The direct work-date locator returns 0 nodes; descendant candidates remain `1913-04-29` (work bibliography entry creation date), `1930-02-05` (work bibliography entry creation date), `1913` (work expression creation date), `1916` (work expression creation date). The corrected log is `success` and committed one work, but `composition_date` and `composition_year` are null. The missing-date warning is present, and no bibliography or expression date was selected. | `changed_as_intended` |
| `cnw0010.xml` | Namespace removal permits technical processing of elements using the explicit `m:` prefix, while discarding namespace identity | The source binds `m` to the MEI namespace and contains 335 explicitly `m:`-prefixed elements. In memory, `remove_namespaces!` reduced elements retaining a namespace URI or `m` prefix to zero while representative title, resource, and relation values remained available to unqualified XPath. The baseline canonical run committed the record and bounded child data. | This bounded technical behavior remains unchanged because namespace processing was not part of Packages 1–4. | The source binds `m` to `http://www.music-encoding.org/ns/mei` and contains 335 explicitly prefixed elements. Before removal, namespace-aware/unqualified work counts are 1/0; after the in-memory operation, namespace-URI and `m`-prefix counts are 0/0, and the representative title, resource, and relation remain selectable. The corrected log is `success`; the stored bounded record retains title `Musik til Ludvig Holsteins skuespil "Tove"`, catalogue number `10`, and children: identifiers 4; movements 0; instrumentations 16; sources 0; performances 10; external references 0. | `unchanged_within_probe_scope` |

For the six changed probes, the original predictions were confirmed in the baseline and no longer reproduce after the correction. The CNW 10 behavior remains the same only within this bounded parser-and-record probe.

## Equal values now survive under distinct identifier types

The corrected schema and importer retain exact `(identifier_type, value)` uniqueness while permitting the same value under different types. Stored inventories below use a stable database ordering by case-folded type, exact type, value, and database id only as a tie-breaker; this is **not** a source-order claim.

| Probe | Repeated source value and types | Stored catalogue number | Stored matching types | Complete stable-order identifier inventory | Child counts | Warnings |
| --- | --- | --- | --- | --- | --- | --- |
| `cnw0027.xml` | `27` under Opus / CNW | `27` | CNW / Opus | CNS `64`; CNU `II/3`; CNW `27`; FS `60`; Opus `27` | identifiers 5; movements 0; instrumentations 20; sources 0; performances 36; external references 3 | `no_movements`, `no_source_references` |
| `cnw0064.xml` | `64` under CNW / FS | `64` | CNW / FS | CNS `25`; CNU `II/11`; CNW `64`; FS `64`; Opus `35` | identifiers 5; movements 0; instrumentations 2; sources 0; performances 39; external references 0 | `no_movements`, `no_source_references`, `no_external_references` |
| `cnw0070.xml` | `43` under Opus / CNS | `70` | CNS / Opus | CNS `43`; CNU `II/11`; CNW `70`; FS `100`; Opus `43` | identifiers 5; movements 0; instrumentations 5; sources 0; performances 22; external references 1 | `no_movements`, `no_source_references` |
| `cnw0081.xml` | `10` under CNS / FS | `81` | CNS / FS | CNS `10`; CNU `II/12`; CNW `81`; FS `10`; Opus `3` | identifiers 5; movements 0; instrumentations 1; sources 0; performances 8; external references 1 | `no_movements`, `no_source_references` |
| `cnw0237.xml` | `237` under CNW / CNS | `237` | CNS / CNW | CNS `237`; CNU `III/4, 124; III/5, 177; III/6, 306, 342`; CNW `237`; FS `94, 103, 111` | identifiers 4; movements 0; instrumentations 7; sources 0; performances 39; external references 4 | `no_movements`, `no_source_references`, `non_exact_performance_date_not_stored` |

All five have one successful `ImportLog`, a non-null work link, exactly one surviving work, both cross-type equal values, zero exact typed duplicates, and no remaining failure or rollback. Their direct CNW value supplies `Work.catalogue_number`.

## CNW 67 no longer adopts a nested bibliography date

The namespace-aware direct locator `/mei:mei/mei:meiHead/mei:workList/mei:work[1]/mei:creation/mei:date` still returns zero nodes. The unchanged official source contains four descendant candidates:

| Position | Value | Structural context | Direct work-composition date? |
| ---: | --- | --- | --- |
| 1 | `1913-04-29` | work bibliography entry creation date | no |
| 2 | `1930-02-05` | work bibliography entry creation date | no |
| 3 | `1913` | work expression creation date | no |
| 4 | `1916` | work expression creation date | no |

At baseline, the first nested bibliographic candidate `1913-04-29` was stored with year `1913`. In the corrected database, the work still imports successfully, but `composition_date` and `composition_year` are both null, the warning category is `missing_composition_date_or_year`, and no bibliography or expression date is selected. This is `changed_as_intended`.

## CNW 10 retains the bounded namespace-removal behavior

The document uses MEI namespace URI `http://www.music-encoding.org/ns/mei` and contains 335 explicitly `m:`-prefixed elements. Before namespace removal, namespace-aware XPath found one work while unqualified XPath found zero; namespace-aware/unqualified counts were 44/0 titles, 36/0 performance resources, and 1/0 target-bearing relations.

Representative prefixed values were title `Forspil`, resource `fl.` (`codedval=wa`, `count=1`), and relation `hasArrangement` targeting `aa9d5567-7e44-407a-8e34-1e002cd680fa.xml`.

After the bounded in-memory `remove_namespaces!` operation, 0 elements retained a namespace URI and 0 retained the `m` prefix. Unqualified XPath then found 1 work, 44 titles, 36 performance resources, and 1 target-bearing relation; all three representative values remained selectable.

The corrected Stage A record committed successfully with title `Musik til Ludvig Holsteins skuespil "Tove"`, catalogue number `10`, composition date `1907–08`, year `1907`, four identifiers, and identifiers 4; movements 0; instrumentations 16; sources 0; performances 10; external references 0. This is `unchanged_within_probe_scope` relative to baseline.

## Database and source preservation checks

The before and after deterministic nine-table digest was `ee61baab1f1032026a32c9e4df9e403847e8c6ad0b3011009be242beb6fe4ce9`. Every table count and per-table digest was identical. The corrected schema remained at `20260817090000`, `identifier_type` remained non-null, the unique `(work_id, identifier_type, value)` index remained present, the obsolete `(work_id, value)` uniqueness index remained absent, and all eight orphan checks remained zero.

| Table | Before | After |
| --- | ---: | ---: |
| composers | 1 | 1 |
| works | 446 | 446 |
| catalogue_identifiers | 1,726 | 1,726 |
| movements | 0 | 0 |
| instrumentations | 1,686 | 1,686 |
| source_references | 0 | 0 |
| performances | 4,646 | 4,646 |
| external_references | 458 | 458 |
| import_logs | 446 | 446 |

The sanitized SQL audit observed 135 statements: 125 read queries, 6 transaction-control statements, and 4 safe session-configuration statements. It observed zero data/schema/privilege mutations, zero unknown statements, and zero unsafe session changes.

All seven XML files were rehashed after collection and still matched their manifest entries. `Gemfile.lock`, the committed importer, existing baseline evidence, and the preserved Stage A importer-invocation total remained unchanged. Stage C added zero importer invocations, zero database writes, zero API/Rack requests, zero external-network requests, and wrote zero XML files.

## Limitations

- No API behavior was evaluated in Stage C; database observations must not be treated as API exposure evidence.
- The CNW 10 namespace result concerns one bounded record and does not establish general MEI compatibility or complete field fidelity.
- Seven focused probes are not a general correctness or accuracy measure, and no overall accuracy percentage was calculated.
- The identifier inventories are presented in a declared stable database order, not inferred source order.
- The CNW 67 result establishes structural selector behavior; it does not adjudicate the scholarly meaning of every date elsewhere in the record.
- The preliminary Ruby launcher stop occurred before the collector loaded and is retained only as execution-lineage evidence; it produced no semantic or database observation.
