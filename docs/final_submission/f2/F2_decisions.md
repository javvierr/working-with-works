# F2 decisions — frozen before projection implementation

Recorded 19 September 2026 after the fresh current-F1 baseline passed at 23:25:52 UTC. This is the full bounded F2 contract, not the fallback. The package specification/acceptance v1.0 and the user's invocation authorize it. No F3 work is included. Current F1 files and all prior evidence remain preserved.

## Prerequisite and scope

The actual repository root and main HEAD b0142488fd5609e86d93c84978134a7d849d1882 match the reviewed state. All 25 F1 source payloads and six F1 documents match their reviewed bytes. An explicit 886-path safe inventory was filtered before file opens/hashes; no arbitrary tmp/private/cache scan was used. The selective external copy contains 126 exact files, including the current unstaged/untracked application and README. The unchanged suite freshly passed 96 tests / 781 assertions / no failures, errors or skips, seed 190926, one worker. See `baseline/gate_verdict.json` and `evidence/F1_reconciliation.json` in the new review artifact.

Validation uses only a new user-authorized PostgreSQL14.23 instance under `/private/tmp/www_f2_pg_6ncibanc`, private 0700 Unix socket, local peer authentication and TCP disabled. Its four new F2 targets have separate purposes; each requires unused-name, empty-target, configuration and live server/database/user identity proof. Retained F1 data is outside this run. Only this new instance will be stopped at completion, without deletion. No setup/CI, installation, dependency change, Git mutation or existing-database operation is authorized.

Add exactly SourceDescription, HeldItem and SourceRelation. Descriptions belong to CatalogueDocument, items belong to a description and the same document, and relation rows retain explicit document-local targets. Document membership never implies a whole-work source, a particular component, a verified held copy, or a public authoritative link. Existing legacy SourceReference data and JSON remain distinguishable and compatible.

## Independent frozen fields and oracle

The independent source-only extraction inspected just CNW 417, 277, 63, 17, 45 and Coll. 27, with pinned original hashes and namespace-aware locators. It did not use application importer/model/serializer helpers. Frozen files:

- `acceptance/f2_selected_fields_v1.json`, SHA256 `226bd7794098a608ad2a7f5e15a6debe6754e61f983cb6f4dae641af8db02ec6`.
- `acceptance/f2_source_expectations_v1.json`, SHA256 `991037f3dd3e34df7a4dfc2d89b34dddb31dab260807018c8ad25d89ca6f9425`.

These define exact selected paths, types, ordering and metadata. Totals are 25 source descriptions, 22 items and 24 relation nodes/tokens. They include 25 source title rows and 150 classification nodes (143 nonblank); blank selected nodes remain stored with null display text and raw attributes/text. CNW 17's relations target expression_1 twelve times, expression_32358bfa once and expression_77d25081 twice. No blanket expression_1 assumption is valid.

Select direct manifestationList/manifestation nodes, direct itemList/item children and direct relationList/relation children. Source arrays are identifiers, titles, classification_terms, publication, physical_description, notes and links. Titles come only from direct titleStmt/title; classification terms retain their owned direct classification/termList chain, excluding intervening entity owners. Publication selects publisher/pubPlace/date; source physical description selects titlePage/plateNum; notes select direct notesStmt/annot; links select direct ptr/ref. Item arrays are identifiers, physical_locations, physical_description and links. Physical locations retain each direct repository (identifier, corpName, ptr/ref arrays) and each direct location identifier separately. Item physical description selects physMedium and handList/hand. Values in unions follow XML document order, retaining duplicates and blank nodes.

Every selected value retains element, nullable normalized text, raw_text, nullable source_type/language/XML ID, positive source_order, locator, exact attributes and parent_metadata. Titles also retain titleStmt metadata; classification terms retain classification and ordered termList metadata. Normalization collapses XML space/tab/CR/LF only; raw means parsed character data, not a lexical XML serialization. Namespaced attributes use Clark names. No language, authority, punctuation or scope rewriting occurs. Untyped physLoc identifiers are always labelled Location identifier in this contract; no Shelfmark convention is invented.

## Persistence and state

SourceDescription and HeldItem store the above arrays as JSONB, plus their parent keys, XML ID, locator/order, label, source_attributes, parent_metadata, state and availability. SourceDescription has no mandatory Work key. SourceRelation stores owner/document keys; nullable node XML ID; locator, relation_order, token_order; rel, raw_target, target_token; source_attributes and parent_metadata; resolution_state/reason; nullable target_source_description_id or target_work_id plus expression_context JSON. Public attributes map source_attributes to `attributes`; public target_source_xml_id is derived from its constrained target row. Expression context retains XML ID/locator/label/attributes/direct title rows, ordered ancestor expression snapshots and containing work XML ID/locator. No expression entity is added.

Database constraints enforce non-null required ownership/provenance, positive order, source/item document-local XML-ID uniqueness, source/item order uniqueness, relation owner/node/token order uniqueness, JSON shapes and mutually exclusive resolved target kinds. Composite foreign keys enforce same-document source/item and source-target/work-target ownership. Relation XML IDs may repeat across token rows from one XML node. No global XML-ID identity or cross-file lookup is introduced.

Node states are descriptive, label_or_link_stub and empty_placeholder, using the frozen own-field rule. Child item text cannot make its parent description descriptive. Empty placeholders do not establish a held copy or location. Missing XML IDs produce unsupported issues with locators; omitted nested item/relation counts remain truthful. Duplicate document XML IDs still reject the whole input through F1 validation.

CatalogueDocument gains nullable source_projection_version and source_projection_summary. Required version is `cnw_sources_v1`. Projected summaries use the frozen counters/state counts, total issue_count, first 50 bounded issues and issues_truncated flag. No manifestation nodes means absent_in_source; omitted nodes or unresolved relations mean partial. Complete does not erase per-node placeholder states. Clarification for legacy/unprojected display: summary is exactly `{state: "not_projected"}` and version is null or the stored older marker; unknown counts are omitted, never represented as zero. Migrations do not backfill a projection or infer absence from legacy SourceReference rows.

## Relations and atomic replacement

Build a document-local XML-ID index after F1 validation. Preserve raw rel/target and create one row per XML-whitespace token; missing/blank target creates one unresolved row. Exact isEmbodimentOf resolves only a unique same-document expression contained in the supported Work, retaining nested ancestor context. Exact isReproductionOf/hasReproduction resolves only a represented direct description in the same document, retaining direction, self/cyclic edges and no inferred inverse/transitive association. Other forms stay unresolved with the frozen reason precedence. No remote retrieval, URI decoding, cross-file path/query/URL resolution, title matching or preferred-token selection occurs.

Preserve “Score, draft (No. 26)” literally while retaining its actual expression_1 target. Do not infer the numbered component or complete-work coverage. A source without a supported expression relation displays relationship unspecified, even if it has an explicit reproduction relation to another source.

The same-byte fast path requires the current projection version as well as the committed hash. A valid same-byte F1 record at its allowed path must gain the F2 projection without replacing the document/work or existing F1 child facts. Record old/new projection versions in successful attempt provenance. Same bytes/current version retain domain rows/counts and append only allowed attempt/path provenance. F1 path/key conflict policies remain unchanged.

Prepare/validate the entire selected projection and target references before persistence. Within one per-document transaction, remove old relation edges before replacing targets; preserve surviving source/item XML identities by upsert, reconcile removed nodes only within their document, and create all sources before source-target edges. Reordering may temporarily move existing positive ordinals inside that same transaction to avoid immediate unique-index collisions. Persist marker/summary, semantic facts and success attempt atomically. A partial persistence/constraint failure must roll everything back, then append one properly associated failure outside rollback. Sequence advancement is separate from semantic rollback; attempts remain append-only. Imports remain sequential.

## Exact additive detail and narrow interface

Add only `catalogue_sources` to detail JSON. It contains:

- `document`: null or input_profile, catalogue, record_key, root_xml_id and committed_sha256.
- `projection`: version (string/null) and summary (the projected contract or the unprojected state-only object).
- `descriptions`: ordered description objects from the frozen contract, each containing ordered relations and held_items. Internal numeric parent/target keys and absolute ingest paths are excluded.

The existing detail page gets “Source descriptions in this catalogue record”, using the same persisted projection. Show selected titles/type/language, scope terms, relationships/context, item grouping, repository/location identifiers, availability and locators. Dense CNW 17 may use ordinary accessible native disclosures. Internal reproduction links are anchors only when a target exists in this document's rendered section. Raw pointers are escaped plain text. No new endpoint/index payload, pagination, source screen, graph, general API redesign, styling framework or broad UI work is included. GETs never reparse XML or persist projection data.

The only F1 follow-ups are the no-database-reproduced inert DOCTYPE/ENTITY literal false positive (remove indiscriminate byte matching while retaining strict NONET/no-expansion/no-loading and actual parsed-DTD rejection) and the existing README demo example's explicit stable fixture-key map. Sample XML and F1 documents remain unchanged.

## Validation and checkpoint

Keep independent source→SQL, SQL→API, HTML grouping/presentation, browser checks, meaningful regression tests and comparator controls separate. Demonstrate both a fresh F2 import and identical-input F1→F2 migration/projection in distinct new targets. Check the dense page in a running isolated copy and all five required browser examples. Source expectations must not change to fit results; retain failed attempts and justified tooling corrections. No full-corpus import or reserved detailed-record inspection occurs.

At the specified timebox/checkpoint, the package's narrower fallback may be declared explicitly only if its replacement raw-target/state and all mandatory ownership/version/rollback/interface checks pass. Otherwise return PARTIAL. Neither fallback nor partial may claim omitted resolution features passed. Stop after F2 for review, without F3, staging, commit or push.
