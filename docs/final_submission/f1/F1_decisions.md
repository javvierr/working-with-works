# F1 decisions — frozen before implementation

Recorded 19 September 2026 after the explicit P0/R-01 verdict at 17:54:22 UTC. Authority: supplied F1 specification and acceptance protocol v1.0, read directly from the external package. The user amended only the database-service prerequisite to allow this run's new private peer-authenticated, Unix-socket-only PostgreSQL 14.23 instance. Existing databases and services remain outside scope.

P0 passed in the single permitted revised harness attempt: fresh unchanged suite 58 tests / 269 assertions / zero failures, errors or skips; one three-record import; four requests with live connection identities, independent SQL comparisons, unchanged measured state and a successful intentional comparator mismatch. R-01 then reproduced the old classification/title and hidden failed-reimport defects on the unchanged copy. Evidence is in `evidence/p0_verdict.json`, `p0/attempt_2/` and `p0/r01/` in the review artifact. The initial malformed harness URL and its correction remain recorded.

## Frozen scope and contract

Only CatalogueDocument, WorkTitle and WorkClassificationTerm are added. SourceDescription, HeldItem and SourceRelation remain F2. Existing routes, index array, other compatibility fields and source/item limitations stay in place. No pagination, general API-error redesign or broader UI work is included. Existing setup/CI remains F5 work.

The additive detail fields are `titles`, `classification_terms`, `display_title_policy`, `latest_import_attempt` and `last_successful_import`, with `availability` distinguishing official, explicit non-authoritative demo and `legacy_unvalidated` states. Title and term arrays retain source order with ID as a stable secondary ordering. Public metadata includes XML IDs and namespace-aware source locators. Newly exposed diagnostics omit absolute paths, whole XML and exception traces. Existing `source_file` is an inherited compatibility limitation for F3.

The title policy is `main_untyped_uniform_alternative_subordinate_v1`: nonblank direct titles rank main, untyped, uniform, alternative, subordinate. Absent/XML-whitespace-only type is untyped; other recognized tokens match exactly, without inventing case or padding normalization. Raw type metadata is retained. Source order breaks ties, with no preferred language. Unknown types (including text_source) remain stored/searchable but cannot supply a heading. Subordinate fallback is explicitly labelled. No eligible heading is a file failure. CNW 277 displays Serenade and retains all five rows.

All nonblank terms owned by a direct work classification are retained, including duplicates and multiple termLists, with term and parent metadata. Nested work/documentary/bibliographic ownership is excluded. Classification source_order counts retained nonblank terms; title source_order retains the direct-title ordinal. These prospective conventions are recorded in the frozen oracle. Genre is the first retained term or null. Search/filter use all appropriate rows and literal wildcard escaping without multiplying Work results. Legacy scalar searches remain available without fabricated provenance.

## Identity, input and history

Official input defaults to `official_cnw_v401`: strict XML, MEI namespace/root/version 4.0.1, exactly one direct work and exactly one nonblank direct CNW identifier. Type/label markers are trimmed and matched case-insensitively for the identifier family only; contradictory populated markers or multiple matching nodes reject. Duplicate document XML IDs, DTD/entities, wrong shape/version and malformed XML reject. Namespaces are preserved. This is bounded input validation, not full schema validation.

Logical identity is `(input_profile, catalogue, record_key)`. Official CNW keys collapse XML whitespace only and preserve punctuation, prefixes and leading zeros. Root/work XML IDs are document-scoped provenance, never global identity. Demo requires explicit invocation and a caller-provided stable fixture key/map; it supports the inspected direct sample structure with omitted version and optionally omitted namespace, never fallback from rejected official input.

Preinventory rejects every member of a duplicate-key batch group before any member writes. Successful historical path ownership is checked before key/hash reuse. Identical bytes at an unclaimed relocated path reuse identity/facts and append provenance. Changed bytes are accepted only at a previously successful path for that same identity. Competing changed bytes, changed key at an owned path and B's bytes at A's owned path conflict without transfer. Failed attempts never claim paths. Malformed known-path failures associate only through unambiguous successful history; unknown failures remain unassociated.

Failure association is resolved before persistence: B's valid bytes on A's known path create an attempt associated with A, retaining attempted B identity without adding an attempt to B. A valid existing key at an unknown competing changed-byte path can associate the rejected attempt with that key's existing document, but never acquires path ownership. Unknown key plus unknown path remains unassociated. This path-owner-first rule was settled before importer conflict implementation.

Document/work/all owned children/success attempt update atomically. Failure after a semantic write must restore all facts, committed hashes, provenance and timestamps, then append exactly one failure outside rollback. Attempt order is imported_at DESC, id DESC; latest attempt and last successful data version are distinct. Empty/missing directories return an explicit run error, nonzero task exit and zero honest file counts.

## Shared implementation interface

CatalogueDocument stores input_profile, catalogue, record_key, raw_record_identifier, identifier_attributes, root_xml_id, mei_namespace, mei_version, committed_sha256, origin_relative_name, latest_successful_path and last_successful_at. Work has a nullable unique catalogue_document association, display_title_reason and display_title_order. No legacy identity backfill is permitted.

WorkTitle stores work_id, text, raw_text, source_type, language, xml_id, source_order, locator and source_attributes. WorkClassificationTerm stores work_id, text, raw_text, xml_id, source_order, locator, source_attributes, classification_metadata and term_list_metadata. JSON exposes source_attributes as attributes.

ImportLog gains nullable catalogue_document, attempted_profile, attempted_catalogue, attempted_record_key, attempted_sha256, previous_committed_sha256, observed_path and provenance. Internal observed_path/latest_successful_path are canonical absolute ingest observations for collision checks; origin_relative_name and existing source_file remain relative representations. Internal absolute paths are never included in new detail fields. Successful attempts retain old/new root/work XML IDs in bounded provenance. Legacy log association remains supported.

Use additive migrations only. Generate schema from a verified new migrated database. Application execution stays in a fresh external selective copy with explicit guarded targets and fixed seed 190926. No existing database migration or automatic cleanup occurs.

## Frozen expectations and evidence limits

`acceptance/f1_expectations_v1.json` SHA-256: `1874d9b9488a38354240f884b2a42c746559965e5e0a78dce54668fe57d9f792`. Six approved development inputs and 94 source-only checks support preparation; they are not runtime acceptance. Original matrices, including 277-04, remain immutable. Reserved detailed records remain outside this run. Any later correction to an expectation requires a retained version and independent reason.
