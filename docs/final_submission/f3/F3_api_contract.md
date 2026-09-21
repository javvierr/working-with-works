# F3 read-only API contract — frozen prospective v1

This document freezes intended behavior before production implementation. All application cases are NOT_RUN until independently observed. The framework probe is a separate preimplementation observation of installed Ruby 4.0.5, Rack 3.2.6 and Action Pack 8.1.3. The accompanying manifest records the prospective freeze; implementation additionally requires the unchanged baseline gate.

## Compatibility and identity

`GET /api/works` remains a bare JSON array. Summary fields remain `id`, `title`, `composer` (`id`, `name`), `catalogue_number`, `composition_date`, `composition_year`, `genre`, `instrumentation` and `source_file`. `GET /api/works/:id` retains all summary and existing detail fields: `source_identifier`, `catalogue_identifiers`, `movements`, `sources`, `performances`, `external_references`, `titles`, `classification_terms`, `display_title_policy`, `latest_import_attempt`, `last_successful_import`, `availability`, and `catalogue_sources`. All existing nested semantics remain unchanged. The historical six-source oracle remains the detail semantic reference.

Index pagination is an intentional compatibility change: clients must traverse pages for complete results. Stability means a fixed dataset; concurrent changes are not a snapshot guarantee. Synthetic records are marked explicitly and are not official catalogue evidence.

## Parameters and normalization

The index accepts `page`, `per_page`, `q`, `catalogue_number`, `instrumentation`, `genre`, `year_from`, and `year_to`. `format` is negotiation metadata. Validate the raw framework query hash before permitted-parameter filtering. User-supplied `controller`, `action`, and `id` query keys are unknown; route metadata is not a query filter. Detail accepts only `format` as query metadata; other query keys return 400 before checking the path identity.

`page` defaults to 1 and `per_page` to 20. Both must be scalar strings containing ASCII decimal digits after outer whitespace is stripped, then normalize leading zeros to ordinary integers. Their inclusive ranges are 1–1,000,000 and 1–100. Explicit blank, null, array, hash, sign, fraction, exponent, nondecimal, and above-cap input is invalid. For example `page=0002&per_page=0007` and `page=+2+&per_page=%097%09` normalize to page 2, size 7. A plus sign encoded as `%2B` is not a digit and is invalid.

The six existing filters must be scalar strings. Strip outer whitespace; blank values are unset. Preserve interior whitespace in normalized values and navigation. `q`, `catalogue_number`, `instrumentation` and `genre` allow at most 200 Unicode characters after trimming. Do not truncate. Years contain only ASCII decimal digits, normalize leading zeros, and lie in 1–9999 inclusive. Blank years are unset. `year_from` must be at most `year_to` when both are valid and present.

General search retains title-variant, composer-name and stored catalogue-text matching, plus legacy heading matching. It does not become an instrumentation or arbitrary identifier search. Retained classifications and legacy genre fallback retain their existing meanings. Instrumentation matches exact stored source wording by case-insensitive substring. Bare catalogue input matches stored catalogue text by substring. The existing case-insensitive `CNW <value>` interpretation squishes whitespace internally and matches the entire typed CNW identifier, accepting retained values with or without their CNW label. Thus `CNW 29` matches typed 29 and typed `CNW 29`, and excludes FS 29, untyped 29, CNW 129, CNW 29a and CNW 0029. `CNW 0029` is a separate exact identifier. All filters combine. SQL `%`, `_` and backslash are literal user content; quotes stay bound values. Matching records must occur once even if multiple title, instrumentation or identifier rows match.

The installed framework resolves repeated scalar keys to the last scalar: `q=lunar&q=solar` means `q=solar`. It rejects scalar followed by array/hash (`q=a&q[]=b`, `q=a&q[x]=b`) as `ActionController::BadRequest`. It permits an array/hash followed by a scalar (`q[]=b&q=a`, `q[x]=b&q=a`) and retains the final scalar. These observed parsing semantics are retained without a bespoke duplicate parser. A bare `?q` becomes null and receives a scalar-shape error; `?q=` is an unset blank string.

## Ordering, headers and relative navigation

Order by `works.title ASC, works.id ASC` using the recorded runtime database collation. The synthetic fixture uses padded ASCII titles and contains 16 titles with three works each; frozen insertion order and independently mapped IDs establish each tie. The runtime observation must record actual database collation and independently verify the frozen order.

Each successful index includes decimal `X-Total-Count`, `X-Page`, `X-Per-Page`, and `X-Total-Pages`. Total is after filtering and before pagination. Total pages is `ceil(total/per_page)`, including zero when there are no matches. Requested page metadata remains the requested normalized page even when beyond the end.

Link targets are relative `/api/works` URLs, percent encoded with form-style `+` spaces and alphabetically sorted query keys. Include normalized active filters and explicit `page` and `per_page`; omit blank filters, route metadata and `format`. Link relation order is `first`, `prev`, `next`, `last` among those present. In-range pages greater than 1 include `first` and `prev`; pages before the last include `next` and `last`. Different relations may target the same valid page. The sole page has no links. A beyond-last page returns 200 `[]` with `first` and `last` recovery links only. Zero results return 200 `[]` with no Link header, even for a beyond-default requested page. No relation points to an invalid or nonexistent page.

For the 48-row default fixture, page counts are 20, 20 and 8. Page 4 is empty with count 48 and total pages 3, and has only first=1 and last=3 recovery links. At size 7 there are seven pages (7,7,7,7,7,7,6); at size 100 there is one 48-row page. `f3_traversal_boundaries_v1.json` freezes every exact external-key boundary.

## Safe errors and deterministic order

A handled failure is JSON with a single `error` object containing `code`, `message` and `details`. No input value, unknown key name, SQL, local path or exception trace is echoed. Error responses omit pagination headers and page links.

A parameter failure is 400 with code `invalid_parameters` and message `Invalid request parameters.`. Each detail contains only `parameter` and `message`. Known-field detail order is `page`, `per_page`, `q`, `catalogue_number`, `instrumentation`, `genre`, `year_from`, `year_to`, followed by at most one generic `query` error for any unknown keys. A field has at most one primary error; malformed fields do not also receive range errors. Exact strings are:

| Condition | Message |
|---|---|
| Non-string field | `must be a scalar string.` |
| Invalid page | `must be a positive decimal integer between 1 and 1000000.` |
| Invalid page size | `must be a positive decimal integer between 1 and 100.` |
| Overlong text | `must be at most 200 characters.` |
| Invalid year | `must be a decimal integer between 1 and 9999.` |
| Reversed valid year range, on `year_to` | `must be greater than or equal to year_from.` |
| Unknown query keys, on `query` | `contains unsupported parameters.` |
| Handled malformed query boundary, on `query` | `could not be parsed.` |

Rails interprets a period suffix as the response format: `/api/works/1.5` captures ID `1` and format `5`, so returns 406. This is explicitly a format failure, not numeric-ID coercion. Valid captured path IDs are ASCII positive decimal integers no greater than 9223372036854775807. Leading zeros normalize. Path-ID whitespace is not stripped. Missing, malformed, partial-numeric, nonpositive, above-range and nonexistent IDs produce the same 404 JSON error: code `not_found`, message `Resource not found.`, details `[]`. Unknown GET routes beneath `/api/` produce that same 404, including unknown paths with incompatible format suffixes.

## Format and request-boundary behavior

A recognized endpoint negotiates format first, validates query next, and checks detail identity last. Default or JSON format succeeds. The only accepted explicit path/query format is the exact lowercase string `json`, with no trimming. Any explicit non-JSON value, including `JSON`, whitespace, blank, or array/hash/null format, yields 406 JSON with code `not_acceptable`, message `Only JSON responses are supported.`, and details `[]`. It takes precedence over bad parameters or IDs. An Accept header that does not permit JSON likewise yields 406; ordinary browser lists with a positive compatible wildcard remain usable. An empty/absent Accept header behaves as default. For a nonempty header, use framework `Rack::Utils.q_values` and normalized media names from `Rack::MediaType.type(...).downcase`. Supported matching ranges are `application/json` (specificity 2), `application/*` (1), and `*/*` (0). Select the highest matching specificity, then highest quality within that specificity; accept only quality greater than 0 and no greater than 1. Thus `application/json;q=0,*/*;q=1` is rejected, while `application/json;q=0.5,*/*;q=0` succeeds. JSON with a charset parameter succeeds. `application/problem+json` alone is not a supported representation and returns 406. Any explicit non-JSON path format is rejected even if query format is JSON, and any non-JSON query format is rejected even if the path suffix is `.json`.

The framework probe shows that Rails MIME negotiation applies a browser heuristic and retains zero-quality ranges; direct `negotiate_mime` therefore does not by itself satisfy this contract. Rack `q_values` preserves quality values and may be used for bounded JSON acceptability without reimplementing query parsing. The frozen cases explicitly account for quality, specificity and supported media types.

Handled malformed query encodings (`q=%ZZ`, invalid UTF-8 `q=%FF`) and scalar-to-container collisions normalize to 400 JSON at the tested Action Dispatch boundary. If an incompatible Accept header or explicit incompatible path format is already known, return 406 before attempting malformed query parsing. If query format cannot be read because parsing fails, 400 is the boundary result. These are precise tested request cases, not a claim about every upstream HTTP server or infrastructure failure. Unexpected programming exceptions are not broadly rescued.

## Independent verification plan

Use a separate new guarded synthetic experiment database containing exactly the 48 frozen records. Insert records by declared insertion rank and verify every stored fixture field through independent SQL; map IDs by exact synthetic `source_file`. Verify actual collation and independent `ORDER BY title,id` against the frozen external-key order. Store all request status, headers and body, then compare membership, order, counts and exact relative links to the frozen cases. Traverse every page at 20, 7 and 100 and compare each complete unique sequence. Run the same comparator against unchanged captured responses with deliberately wrong expected member, order and total; each must fail. The comparator must never call production filters, parser, serializer or pagination.

Record before/after complete domain tables, sequences and schema for the GET experiment, live guards on SQL and explicit no-SQL rejected requests. Repeat the six-record source→SQL→detail semantics separately with the unchanged historical source oracle. Exercise HTML errors, combined filtering, page reset/retention, Clear, same-title cues, known/unknown raw instrumentation and existing provenance in integration tests and real browser observations. Keep all new failed attempts and dispositions. Current status remains NOT_RUN until executed; expected outcomes are not results.

## Frozen artifacts

`f3_api_cases_v1.json` contains 234 exact prospective cases; `f3_synthetic_truth_v1.json` and CSV contain all 48 synthetic row definitions; `f3_traversal_boundaries_v1.json` contains complete independent page identities. `f3_prospective_freeze_manifest.json` gives hashes and the freeze time. No application response or query implementation was used to create these expectations.
