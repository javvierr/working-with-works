# F4 API results

The accepted F3 application completed this new F4 API round without a production correction. The fresh synthetic run passed all 234 unchanged frozen cases plus one explicitly separate repeat. The canonical run passed 272 cases: 149 successful index requests, 14 full-detail requests and 109 canonical replays of the frozen error templates. Another 175 canonical requests supplied the separate descriptive timing round; every response also passed its independent correctness comparison. These are API/SQL agreement results, not source-fidelity, usability or release-readiness claims.

## Build, inputs and independence

The tested application is the accepted 154-file build `f3-1602645a261ed754`, in the new selective external copy, with PostgreSQL 14.23, Rails 8.1.3, Ruby 4.0.5 and one worker. The separate targets are `www_f4_synthetic_api_ose8xy9` and `www_f4_corpus_ose8xy9` on the owned private-socket instance. Exact target/connection guards and executable hashes accompany `validation/api_synthetic_01_invocation.json` and `validation/api_corpus_01_invocation.json`; original creation evidence is under `targets/`. Both targets use `C` collation and `C` character classification.

`acceptance/api_freeze_manifest_v1.json` freezes the corpus selection/query/comparison rules and timing rules before the canonical import. The unchanged 234 cases, 48-row truth and traversal boundaries are in `acceptance/api_f3_frozen/`; their input hashes are recorded in `validation/api_synthetic_summary.json`. No F4 response, production filter, parser, serializer or importer helper was used to construct an expected result.

The original historical 83 assertions identify eight records; four fall outside the ten-record semantic extension. Their identities and the master protocol were frozen before the canonical import. The adapter's explicit enumeration of these four additional details at 00:52:55 UTC followed import start at 00:52:30.918259 UTC. It applied the unchanged historical case selection without using corpus or API observations. This timing is preserved in `acceptance/api_historical_detail_freeze_v1.json`, `acceptance/api_historical_detail_supplement_v1.json` and the adapter preimage/diff; it is not represented as a new pre-import freeze. The 109 canonical error-case enumeration likewise applies the already frozen non-success contract cases after import, before any canonical API observation, as disclosed in `acceptance/api_canonical_error_enumeration.json`. Three valid-ID role placeholders resolve independently to CNW 417; exact error payload/query rules remain unchanged. The synthetic 234 cases themselves were not altered.

The explicit second freeze at **00:57:21.209132 UTC** resolves generated IDs, actual collation, ordered membership/counts and all expected SQL detail fields before canonical API request 1. See `validation/api_corpus_01/second_freeze_manifest.json`, `independent_SQL_frozen_expectations.json` and `independent_sql_statements.json`. The full canonical run started at 00:57:19.714943 UTC and ended at 00:57:37.762970 UTC on 21 September 2026.

## Actual results and denominators

| Round | Cases / observations | Actual result |
|---|---:|---|
| Frozen synthetic | 234 | 234 PASS: 125 HTTP 200, 74 HTTP 400, 10 HTTP 404, 25 HTTP 406 |
| Additional synthetic repeat | 1 | PASS; unchanged default response |
| Synthetic complete traversals | 23 | 23 PASS against frozen external-key sequences |
| Synthetic expected-only negative controls | 3 | Wrong member/order/total each detected |
| Canonical index requests | 149 | 149 PASS: exact ordered summaries and navigation |
| Canonical full details | 14 | 14 PASS: complete declared SQL/API fields |
| Canonical frozen error replays | 109 | 109 PASS: 74 HTTP 400, 10 HTTP 404, 25 HTTP 406 |
| Canonical complete traversals | 3 | Sizes 20, 7 and 100 each recover all 446 unique works in exact order |
| Canonical expected-only negative controls | 3 | Wrong member/order/total each detected |
| Timing responses, separate from the 272 cases | 175 | All 25 warm-ups and 150 measured requests correct |

Sizes 20, 7 and 100 required 23, 64 and 5 pages respectively. Each complete sequence equals the independent SQL `ORDER BY title,id`; no missing or duplicate work occurred. Seven real tied-title groups were present, with 16 members in total, and their ID tie order was checked through the complete traversals. The exact groups, IDs and collation are retained in `independent_SQL_frozen_expectations.json`. This real-data result is distinct from the frozen synthetic fixture's 16 three-work title ties.

Twenty prospectively defined filter groups cover every advertised filter, retained variants and classifications, meaningful combinations, literal wildcard characters, blanks, no matches, normalization and first/middle/last/beyond-last recovery. Coincident page positions were deduplicated. An additional actual no-query default request confirmed implicit page/size defaults. Full request bodies, status, headers and query strings are retained under `validation/api_corpus_01/`.

| Filter group | Normalized active filters | SQL/API total | Result |
|---|---|---:|---|
| F4-CAPI-default-p1 | (none / normalized blank) | 446 | PASS |
| F4-CAPI-q-title-p1 | q='Duet' | 2 | PASS |
| F4-CAPI-q-composer-p1 | q='Nielsen' | 446 | PASS |
| F4-CAPI-q-variant-p1 | q='The blue waves are sleeping' | 1 | PASS |
| F4-CAPI-catalogue-bare-p1 | catalogue_number='417' | 1 | PASS |
| F4-CAPI-catalogue-typed-p1 | catalogue_number='CNW 417' | 1 | PASS |
| F4-CAPI-instrumentation-p1 | instrumentation='voices' | 7 | PASS |
| F4-CAPI-genre-p1 | genre='Vocal music' | 343 | PASS |
| F4-CAPI-second-term-p1 | genre='Song' | 281 | PASS |
| F4-CAPI-year-from-p1 | year_from='1889' | 400 | PASS |
| F4-CAPI-year-to-p1 | year_to='1889' | 44 | PASS |
| F4-CAPI-year-equal-p1 | year_from='1889', year_to='1889' | 5 | PASS |
| F4-CAPI-combined-p1 | q='Duet', catalogue_number='CNW 417', instrumentation='voices', genre='Vocal music', year_from='1889', year_to='1889' | 1 | PASS |
| F4-CAPI-combined-broad-p1 | q='Nielsen', genre='Vocal music', year_from='1889', year_to='1931' | 328 | PASS |
| F4-CAPI-blank-p1 | (none / normalized blank) | 446 | PASS |
| F4-CAPI-zero-p1 | q='F4_UNMATCHED_7caae942' | 0 | PASS |
| F4-CAPI-literal-percent-p1 | q='%' | 0 | PASS |
| F4-CAPI-literal-underscore-p1 | q='_' | 0 | PASS |
| F4-CAPI-literal-backslash-p1 | q='\\' | 0 | PASS |
| F4-CAPI-normalization-p1 | catalogue_number='cNw   417', year_from='1889', year_to='1889' | 1 | PASS |

The 14 detail records are CNW 417, 277, 63, 17, 45, 48, 1, 202, 18, 2, 53, Coll. 27, Coll. 21 and Coll. 18. The first ten remain the semantic extension denominator, separated into six development and four reserved records. The four extra requests serve historical continuity, not a retroactively expanded semantic sample. `validation/api_corpus_detail_bodies.json` indexes the exact full responses and source evidence references. Source-based semantic judgments are reported separately in the semantic results.

## Error boundaries, GET preservation and independent readback

All canonical and synthetic HTTP 400/406 responses required zero application SQL. Nine of each round's ten HTTP 404 responses also required zero SQL. The remaining 404 uses the valid maximum bigint ID, independently verified absent on the corpus, and performs the guarded lookup. No query event was invented for requests rejected before SQL. The original cases map malformed IDs, query shapes/encodings, unknown API routes and format/Accept precedence individually to raw observations.

All fifteen relevant tables, fifteen sequences and structural schema were captured before/after the GET rounds and remained exactly equal. The canonical snapshot includes both full-corpus import attempts (892 import-log rows). No write-like SQL was attempted during either GET round. The GET session was explicitly read-only, in addition to exact live identity/configuration guards. Full canonical state is retained locally; each snapshot is 51,686,596 bytes and excluded from the review ZIP as a database-like whole-state payload. `validation/api_corpus_state_summary.json` contains the exact retained file identities, every table count/hash, sequence states and structural-schema comparison. The synthetic summary and retained state evidence are separate.

`validation/api_synthetic_independent_audit.json` and `validation/api_corpus_independent_audit.json` independently re-read the actual observations against the frozen expectations using Python comparisons, rather than trusting the Ruby producer's PASS flag. The canonical audit passed 3,313 checks, including full detail values under the declared collection-order rules, relative links, guard-event references, state equality and timing-summary recomputation. The same unchanged captured observations reject deliberately wrong expected member, order and total in each round; no production or database mutation supplies those controls.

## Retained failures and limits

`logs/synthetic_schema_01.log` records an initial launcher configuration refusal: a query parameter named `user` did not supply Rails' configured `username`. The live guard stopped before any SQL. Only the new external launcher was corrected to `username`; preimages, diff and disposition are retained in `api_tools/attempt_01/`. Schema attempt 02 and the subsequent guarded synthetic round passed on that same new target. The adapter's unknown-OID-2206 schema-metadata diagnostic is retained; it decodes that field as a String and does not affect the equal snapshots.

Raw `source_file` values are compared exactly in memory and in retained local evidence. Because original XML was imported directly from the existing corpus into an external application copy, this field contains a relative path back to the repository (including `../../../../Users/...`). It is not claimed to be archive-relative. Review copies must sanitize only the explicitly known repository/run prefixes and disclose that evidence transform; no secret/private paths were searched to construct it. This provenance-path artifact is separate from supported source meaning.

The round uses fixed datasets and in-process Rails/Rack calls; it does not establish concurrent pagination snapshot semantics, upstream server behavior, arbitrary input security, semantic completeness across the whole corpus, user benefit, performance in deployment or final public-clone readiness. Public historical API results remain attached to their earlier build and are not overwritten or pooled with this round. Follow-up participant evaluation remains `NOT_EVALUATED_BY_USER_DECISION`; F5 has not begun.
