# F0 source model proposal — decision for review

Prepared 19 September 2026 from fresh, independent local XML observations. This is a proposed F1/F2 design, not implemented behaviour, a final evaluation, or a claim of FRBR/general MEI compliance. No original application or historical evidence was changed.

## Recommendation and evidence boundary

Implement a bounded catalogue-document → source-description → held-item pathway, with explicit local source relationships and lightweight expression context. Keep document membership separate from a musically meaningful work association. Correct direct-work titles/classification and import-attempt reporting first. Use six new relational entities at most; do not build a complete expression graph or resolve cross-file links in this sprint.

The useful task is: from a work's catalogue record, inspect a described score/manuscript/other source, distinguish its held copies, find the relevant repository identifier and shelfmark, and understand what the source explicitly says about its scope. This task is justified by observed information distinctions; F0 supplies no new participant evidence or proof that existing catalogue interfaces lack equivalent access. Such comparative claims remain open under FB01/FB10.

Reproducible evidence is in `source/profile_source.py`, `source/source_profile.json`, `source/source_examples.json`, `source/selected_examples.md` and `source/historical_277_04.json`. `m` in all locators is `http://www.music-encoding.org/ns/mei`. Excerpts preserve namespace meaning and attributes through ElementTree reserialization; original file hashes identify unchanged bytes. No Rails extraction helper, model scope, serializer or database generated these observations.

| Fresh structural result | Meaning and limit |
|---|---|
| 446 XML inputs, 26,925,115 bytes; every file parses, declares MEI 4.0.1 and contains one work | Describes this corpus; future wrong-root, no-work or multi-work inputs must not silently take the first work. |
| 2,148 manifestations in 442 files; all directly under `meiHead/manifestationList` | They are document-level descriptions, siblings of `workList`, not descendants whose nearest work can be inferred. |
| 2,105 manifestations with textual descriptive payload; 43 with only labels/links; no fully blank manifestation under the stated payload rule | The broad own-payload count of 2,148 is not 2,148 complete musical sources. Preserve stub status. |
| 1,370 items in 392 files; 1,369 have own payload, one has none | Count empty templates separately; do not invent a held item with an asserted location. |
| Direct item repository text/identifier in 1,364/1,370; direct physLoc identifier in 1,289/1,370; 81 physLoc identifier elements are empty | Shelfmarks are item-level source fields. The corpus's 5,685 repository nodes include documentary bibliography and must not be treated as held-item count. |
| 1,195 expressions; 29 without own payload; 128 componentList nodes, 3 without own payload | A context anchor need not have a usable label. A structural node does not establish a complete expression model. |
| 1,590 direct manifestation relation elements, each with one local-fragment token: 1,499 resolve to expression, 90 to manifestation, 1 unresolved | `isEmbodimentOf`=1,500, `isReproductionOf`=86, `hasReproduction`=4. No duplicate XML IDs within a document. Resolution is by same-document ID, not by label. |
| No source relation directly targets a component expression in this census | CNW 17's source title still narrows a source to “No. 26”; targeting an enclosing expression is not evidence that it contains the whole work. |
| Current source selectors match zero nodes in the corpus | `//sourceDesc//source` and work `.//sourceList//source` omit the observed manifestation/item pathway. This is selector reproduction, not a fresh import result. |
| 310/446 current genre selections originate outside direct work classification | Documentary labels: letter 246, article 48, diary entry 10, book 3, manuscript 2, interview 1. The remaining 136 are not established correct by exclusion. |
| 446 distinct direct CNW values, 70 distinct work XML IDs and 439 document root XML IDs | XML IDs are document-scoped. Globally unique `work.xml:id` or root ID would merge unrelated records. |

The local archive is 234,079,300 bytes, SHA-256 `fa3ff9e3012a6a9e8d21c098105bea3be9670945bb76aa5ea46391d2c33cf8ec`. All 15 committed sample-manifest file hashes match. Corpus path and every per-file hash are recorded in `source_profile.json`; a successful parse is not semantic fidelity.

## Selected development examples

All six have full document/work XML identities, file hashes, namespace-aware locators, excerpts and bounded selected fields in `source/selected_examples.md` and `source/source_examples.json`.

| Record and purpose | Independent observation | Design consequence |
|---|---|---|
| CNW 417, `712a43e2-d3d6-463a-88fa-0b7e88e4dbf8.xml`; absence and contamination control | Zero manifestations/items. Current `.//genre` selects `manuscript`, node `idm62`, under bibliography `bibl_13305d3d`; direct classification is `Vocal music` and `Music for vocal soloists and instruments with or without choir`. | Do not create sources from documentary genre labels; show true source absence. |
| CNW 277, `cnw0277.xml`; typed/language titles | Five direct titles; two descriptions and one held item. `source_d1e41` is “Score, autograph, fair copy”; `source_209e1864` is “Text, print”. Both target `#expression_1`. | Preserve title distinctions and source classification; do not label every manifestation a manuscript or even notated music. |
| CNW 63, `cnw0063.xml`; multiple held items | Six descriptions, seven items, four expressions. All six source embodiment edges target `expression_1`; three component expressions lie below it. `source_d1e231` has two items, `item_d1e644632` and `item_d1e879862`, with shelfmarks `CNS 24d` and `DFM 29, nr. 33, 6`. | Separate source description and held copy. Do not fan the source out as an asserted embodiment of each component. |
| CNW 17, `cnw0017.xml`; dense context | 15 descriptions, 13 items, 57 expressions. Three selected source descriptions were read in detail. `source_d1e136`, “Score, draft (No. 26)”, targets `#expression_1`; held item `item_d1e408400` has `DK-Kk`, `CNS 332c`. | Preserve the source's scope wording and expression anchor simultaneously. No automated No. 26 component match from free text. |
| CNW 45, `cnw0045.xml`; fresh small control | One description `source_d1e34`, “Score, autograph, draft”, targets `#expression_1`. Item `item_58fe3264`: `DK-Kk`, `Agnes Bauditz' stambog, Acc. 2001/21`. | Provides a small end-to-end acceptance case outside the historical 15. It is now development evidence. |
| CNW Coll. 27, `a601140e-d48d-48c3-b103-bc0c365082d4.xml`; fresh document-only contrast | One description `source_76c47220`, “Score, print”; zero held items and no source relation. | Retain document membership; work association is unspecified. Collection work links do not authorize inventing source ownership. |

CNW 17 was selected instead of the largest CNW 2 because its known high component density directly tests context without exhaustively reading a 1.5MB record. The two fresh choices use deterministic structural rules recorded in the script. An initial blank-manifestation selection returned no candidates; it was changed to one-source/no-items/no-source-relations using structure before examining detail. Both exploratory failures are retained as scratch-script failures, not application failures.

## Recommended minimal entities and ownership

These are conceptual fields and constraints for review, not migrations or an implemented API shape. Nullable values mean not supplied/unknown, never a fabricated default. Persist normalized display text alongside original type/language/attributes, document hash and precise source locator.

| Entity | Minimum fields, key and parent |
|---|---|
| `CatalogueDocument` | Existing catalogue namespace `CNW`; canonical record key = exact direct CNW identifier string (including `Coll. `); imported SHA-256; original root XML ID; MEI namespace/version; canonical origin-relative name and observed ingest location; imported timestamp/status. Unique `(catalogue, record_key)` after validation. Origin and ingest paths are provenance, not sole identity. |
| Existing `Work` | Belongs to document, exactly one in this supported profile. Preserve work XML ID as document-scoped provenance; unique `(document, work_xml_id)` plus the one-work constraint. Retain current compatibility fields while adding explicit supported semantics. |
| `WorkTitle` | Parent work; full text; source `type` nullable; `xml:lang` nullable; XML ID nullable; source order; locator; optional display-role selection reason. Key document-scoped XML ID when present, otherwise locator under this version. Never deduplicate equal text across languages/types. |
| `WorkClassificationTerm` | Parent work; text, type/class/authority attributes when present, including scheme/authority metadata on the parent classification and termList; XML ID, source order and locator. Only terms under the work's direct `classification`. Multiple terms survive; an optional compatibility scalar is visibly derived. |
| `SourceDescription` | Parent document; XML ID; locator/order; label; all direct title rows with types/languages/order; direct classification terms/attributes; bounded publication/physical-description text; `description_state` such as descriptive, label/link stub, empty or unsupported. Key `(document, xml_id)`; a missing ID yields explicit unsupported-node evidence with locator, not an invented stable ID. |
| `HeldItem` | Parent source description and same document; XML ID, locator/order; label; direct identifier rows; repository identifier/name/authority fields; direct physLoc identifier rows (shelfmark candidates) separate from repository identifiers; bounded physical-description text. Key `(document, xml_id)`. Preserve multiple repository/identifier values in ordered structured fields if encountered; do not invent a single authority entity or geocode. |
| `SourceRelation` | Parent source description; relation XML ID/locator/order; exact `rel`; raw target/token; resolution state; optional target source foreign key, or same-document expression XML ID/locator, containing work reference and ancestor expression IDs/labels. Only one typed target kind may resolve. Preserve a reason when unresolved/ambiguous/unsupported. |

This is six new entities beside existing Work/ImportLog. Ordered, provenance-bearing value arrays inside SourceDescription/HeldItem keep title/classification/location metadata bounded without introducing another general authority model. WorkTitle and WorkClassificationTerm are relational because title search and work-category filtering are declared user operations. Expression context is a source-located snapshot, not a new expression hierarchy.

Document membership is certain from physical XML containment. A work association is asserted only through a successfully resolved, supported relation to an expression structurally contained by that work. SourceDescription therefore should not simply have a mandatory work foreign key. The work detail can reach all document descriptions while separating explicit work associations from descriptions whose work relation is unspecified. A unique work in a file does not erase that distinction.

All null/missing values need a separate availability/state explanation where material: no item elements, empty item placeholder, missing repository text, unsupported multiple values, source link stub, and unresolved relation are different observations. Keep the source label/physical text when it limits scope (CNW 17). Do not invent completeness or assign a source to every component descendant.

## Supported relationships and unsupported boundary

Build one in-memory XML-ID index per validated document. Match namespace-qualified nodes, require a unique match and preserve the original target token. Resolve local `isEmbodimentOf` to an expression only when that target's containment chain reaches the supported work. Store the expression ID/locator and ancestor context; leave title/label null if absent. Do not infer a semantic preferred expression from order.

Resolve local `isReproductionOf`/`hasReproduction` to another source description as a typed link if both IDs are present. Do not traverse this relation to manufacture a work association, infer chronology, or implement a graph explorer. If the same relation targets an unexpected element type, mark it unsupported. Duplicate IDs are ambiguous, a missing fragment is unresolved, and cross-file/URL/query targets remain opaque documented links. No file fetching or cross-file joins are required.

The corpus has one unresolved same-document embodiment token; F0 counted it but has not tuned a correction against its detailed target. Preserve it as evidence of an input limitation. All source relation tokens observed here are local, but link-only descriptions and work/bibliography pointers can use other forms. Inspecting an absolute URL is not evidence it is live; a local or relative target is not an accessible authoritative record.

Expose supported content in HTML and API through the same persisted facts, not by letting views reparse XML with different ownership rules. Detail must show source title/classification, explicit relation/context, item label/repository/shelfmark and provenance. API must retain identifiers, relation state and availability distinctions. A precise local origin+XML locator can be labelled “source locator”; only a verified or explicitly configured authoritative public URL becomes a navigable public-source link. Do not promise online facsimiles merely because a `target` string exists.

## Title and work-classification policy

CNW 277 direct work titles, in source order:

| Order / XML ID | Text | Type | Language |
|---|---|---|---|
| 1 `title_168N200AB` | Serenade | absent | da |
| 2 `title_168N200AF` | Serenade | absent | en |
| 3 `title_168N200B4` | See! Luften er stille | alternative | da |
| 4 `title_168N200B9` | The blue waves are sleeping | alternative | en |
| 5 `title_01767f87` | Se! Luften er stille | uniform | da |

All are at `/m:mei[1]/m:meiHead[1]/m:workList[1]/m:work[1]/m:title[order]`; work XML ID is `work_d1e191187`. Current code chooses direct main, then uniform, then first direct title. Its `first_text` stops at the first existing element before text normalization, so a blank preferred element can block later useful values. This source-only observation predicts selection of title 5; historical row 277-04 separately recorded it in the database. No fresh database observation is claimed here.

The frozen historical 277-04 expectation combined all five title distinctions with a first-untyped display meaning (“Serenade”), while the observed database stored only the uniform title. Keep both historical matrices and their incorrect result intact. A prospective policy can be better justified but cannot retroactively repair that result.

Recommended display policy: retain/search every nonblank direct work title; prefer an explicitly typed main title, then untyped title, then uniform, then alternative. Use subordinate only as an explicitly labelled last resort. Consider all nonblank candidates at each rank rather than stopping on an empty element. No language is intrinsically preferred: show equal-rank distinct language variants together in detail, with language/type labels and optional user-selected language. For the existing scalar title/list compatibility, use source order solely as a deterministic tie-break and label the policy as an application display convention, not an inference that the first title is universally canonical. CNW 277's display is Serenade; its uniform and alternative titles remain visible/searchable. Equal text in da/en is two stored rows, even if a compact display merges the visible text and lists both language tags.

Alternative: retain the uniform-first heading as an explicitly labelled “Uniform title” and show all title variants prominently. This minimizes headline change but requires a new prospective acceptance definition and user-facing explanation; preserve historical 277-04 as incorrect for its original contract. Choose this only for a supported catalogue task, not to make the old observation pass.

Work classification comes only from `work/ classification` direct ownership, preserving every nonblank term, its order, type/class attributes, parent classification/termList scheme or authority metadata, and locator. CNW 417 must never derive genre from its bibliography manuscript entry; CNW 63 must retain both Instrumental music and Chamber music. A compatibility `genre` scalar may be the first nonblank direct term under a documented display rule, but full terms must reach API/UI and filtering should match declared work-level terms. Missing classification remains unknown; documentary or source-description classifications must stay in their own owners. The scalar is not evidence that the terms form an inferred hierarchical genre taxonomy.

## Identity, re-import and migration

Reject unsupported root/namespace/version, malformed XML, no direct work or more than one direct work before persistence. Exactly-one here means `/m:mei/m:meiHead/m:workList/m:work`, not the first arbitrary descendant. Define fixture/non-namespaced compatibility separately; do not silently weaken official-input validation. An empty/missing input directory must produce an explicit non-success import outcome, not a success-looking zero count. No redesign or repair is performed in F0.

Use the validated CNW catalogue identity as the logical record key and keep XML IDs scoped to that record. The census establishes uniqueness within this pinned corpus, not immutability in future releases. If the same logical key is encountered twice in one import run, reject the collision; if root/work IDs or content change on a later authorized re-import, retain previous hash/version and record the replacement. A changed CNW identity or competing file is a reviewable conflict, not an automatic merge. Do not derive catalogue identity from the basename: several corpus names differ from their direct CNW identity.

Execute extraction, validation, parent update, child replacement and success-log insertion in a per-document transaction. Re-importing identical bytes must not duplicate descriptions/items/titles/terms/relations. Reuse stable external/document-scoped IDs; database row IDs may change if child replacement remains the implementation strategy, so they must not be advertised as immutable source identities. Validate references against the complete extracted document before replacing old children. Any failure rolls back all persisted semantic changes and leaves the last valid data intact.

Create the failed attempt outside the rolled-back transaction with the logical document/import identity and, when known, the existing work association. Query latest attempt by that identity rather than only the success-associated `work.import_logs` collection. The current rescue path omits `work`, while the HTML detail reads `@work.import_logs`; stale-success visibility is a static prediction until separately reproduced. Success, fidelity and latest-attempt status remain separate fields/claims.

Prefer a new final-iteration database/rebuild from the pinned official corpus after approval. Add schema/mapping changes in their authorized package, keep historical evaluation databases and 83-row evidence unchanged, and document any ID changes. If a live development DB must migrate, first map existing source paths to validated corpus hashes+CNW keys and flag collisions; do not merge by repeated XML ID. A rebuild is lower risk than pretending changed child identity/shape is a no-op migration.

## Smaller fallback

If the recommended relation/context slice cannot be demonstrated by the 21 September checkpoint, keep CatalogueDocument, SourceDescription, HeldItem, WorkTitle and WorkClassificationTerm; store the supported single embodiment target and provenance-bearing unresolved target list on the source record rather than adding SourceRelation. Support only direct top-level manifestations with direct held items and exactly one unambiguous local `isEmbodimentOf` target to a top-level expression in the supported work. Keep document-only descriptions visible with relationship unspecified. Preserve relation text/type/status as opaque metadata for other cases; do not claim they are resolved.

The fallback still separates document, source and item, still preserves title/classification semantics, still provides repository/shelfmark and source scope wording in both HTML/API, and still validates identity/re-import/rollback. It omits navigable reproduction links, multiple-target association and nested expression mapping. CNW 17's No. 26 scope remains source text; unsupported context is labelled. It is useful only if the same real-data pathway and error states reach both interfaces—unused tables or a silently partial “all sources” list do not meet the fallback.

Expected effort after working runtime prerequisites: correctness/title/classification/import-attempt/identity package approximately 6–9 hours; recommended source persistence+extraction+local relations and regression checks 8–12 hours; bounded HTML/API exposure+integration 4–6 hours (total 18–27). Fallback source slice 6–8 plus interface 3–4, with the same correctness work (total 15–21). These are estimates, not executed hours or guarantees; API pagination/contract completion and final evaluation have additional allocations in the approved plan. If runtime restoration consumes the buffer, prioritize the fallback rather than carrying hidden omissions past feature freeze.

## Acceptance cases and independent expectations

These are proposed future checks; none is marked passed by existing F0 static evidence. Freeze a new versioned protocol before implementation/evaluation. Expected values below come from XML locators independently of Rails extraction and are now development assertions.

| Case | Required future result |
|---|---|
| CNW 417 | Work terms exactly the two observed direct terms; no musical source/items; manuscript bibliography does not contaminate either. |
| CNW 277 | Preserve all five direct title rows including language/type/order/XML ID; recommended heading Serenade; search each alternative/uniform text returns its work. Both descriptive source kinds remain distinguished. `item_aa82b375` has DK-Kk and `CNS 226 (in CNS 250a)` under source_d1e41. |
| CNW 63 | Six sources and seven held items with explicit source parents. The two copies under source_d1e231 retain distinct IDs, labels and shelfmarks. All six embodiment links resolve to expression_1; component count does not manufacture 18 work/source edges. |
| CNW 17 | Preserve “Score, draft (No. 26)”, its expression_1 target and item DK-Kk/CNS 332c; UI/API neither claim full-work completeness nor invent a No. 26 component link. |
| Fresh CNW 45 | One source and one item, explicit expression_1 link, exact source IDs and DK-Kk / Agnes Bauditz' stambog, Acc. 2001/21 provenance, visible in HTML/API. |
| Fresh Coll. 27 | One document source, no held items; source/work relation unspecified, not fabricated. This is distinct from CNW 417's source absence. |
| Same input under relocated ingest directory | Same logical document/work and child source identities; provenance records location change; no duplicate works because the relative Rails path changed. |
| Re-import identical bytes, then failing replacement | No count growth/duplicate relations on repeat; failure leaves previous committed facts/hash intact and latest failed attempt is visible. Use a disposable fixture copy for malformed input. |
| Input/collision edges | No-work, multi-work, wrong namespace, unsupported version, duplicate same-document XML ID, duplicate CNW identity and empty directory produce explicit supported failure/unsupported outcomes without stale partial replacement. |
| Relation/empty-state edges | Unique local target resolves; missing/ambiguous/unexpected/cross-file target retains raw value+reason. Blank item/repository/shelfmark is reported missing, not converted to an asserted held copy/location. |
| End-to-end contract | Compare source→database independently, then database→API; HTML shows the same source/item parents, context, title/classification distinctions and provenance. Do not let DB/API equality alone establish source fidelity. |

Reserve CNW 48 (`cnw0048.xml`), CNW 1 (`cnw0001.xml`), Coll. 21 (`1f6c24d6-e41f-4647-8526-f33efc08faeb.xml`) and CNW 202 (`cnw0202.xml`) for final protocol selection. Selection rules respectively target a simple source/item association, dense expression/source context, document-only/no-item source, and a source-to-source relation case. Exact filenames/hashes and deterministic rules are in the profile. Their detailed title/location/relationship expected values have not been inspected. Their identities, structural counts and corpus-wide genre-selector observations were profiled, so call them fresh detailed final cases, not completely unseen or statistically representative tests.

The unresolved semantic questions are which display-title convention best supports the task, whether untyped physLoc identifiers should be labelled “shelfmark” or conservatively “location identifier”, how much physical-description text to expose, and which authoritative URL base (if any) can be verified later. None authorizes guessed ownership, external retrieval, or schema changes during F0.

By the end of 21 September require a real-data demonstration of CNW 45 + CNW 63 + CNW 17 + Coll. 27 through persistence/API/HTML, correct title/classification cases, re-import and failure visibility. Reduce to the fallback immediately if source ownership or target resolution remains unexplained, either interface is absent, or the estimate no longer protects 23 September feature freeze. Any omitted pattern remains an explicit limitation and separately counted unsupported input. Stop here for review; F1 is not authorized by this proposal.
