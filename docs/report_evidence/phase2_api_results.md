# Phase 2 Stage D: controlled API characterization

## Result summary

The frozen 14-request matrix completed once, in order, with zero retries. D01–D13 returned HTTP 200; the confirmed-missing D14 returned HTTP 404 as a non-JSON HTML response. All 12 list endpoints returned exactly the independently derived database row counts and ordered work-ID sequences, and CNW 417 detail returned all exposed database fields and child counts unchanged.

One bounded response-order discrepancy occurred: D03 (`q=Duet`) returned CNW 417 instrumentation as `["2 voices", "1 pf."]`, while the independently ordered database expectation was `["1 pf.", "2 voices"]`. The two-name multiset, work IDs, counts, and every other exposed D03 value matched. This is a child-array ordering inconsistency, not evidence of official-source fidelity or a value-set loss.

Database equality is not equality with the official XML. Stage B already established material omissions and incorrect mappings in the canonical imported state; this stage characterizes how the unchanged API exposes that state.

## Method and evidence lineage

- Current Stage C evidence commit: `f8728f3bf313abd5c4701427b2ed0bb40dad408d`.
- Application baseline: `8b40722103acb36826a81b7bd1a90983435e9dd7`.
- Protocol SHA-256: `117f4cb568a1b214ae78debc9569ade44ddad3d8aacaa2ba24f44ff2ffcf293f`.
- Frozen Stage D method SHA-256: `118c639598ee1a76f82defb6f9a5780432cfdf03bb558f9ab706ecc568294ae0`.
- Resolved request-plan SHA-256: `151ffb2acbaead9c268ee75cc184107f814f6ba0372679919a7c386ab69362db`.
- Independent database-expectations SHA-256: `aad347f464e63c603320eaaaadf8ccf1eabac040615c541fb954606dca0c44a5`.
- API request-results SHA-256: `3c4f26e703db439d3c51b1912857a38b5a1101af4ba0fb1629c4c8f192b1acc0`.
- API reconciliation SHA-256: `a5ce8fb92300896c5dd8b9e40eab48f1683e42b3b7cadc2a360f99b1362ec944`.
- Canonical database label: `phase2_stage_a_20260816_548dca1_02`.
- Canonical database digest before and after: `05b783204073e38dc5a5418abda9f50ebc721c08b99313b3aa6c7bb2e9395a3d`.
- Execution date: 2026-08-16 in the project timezone; raw timestamps are UTC.

The request plan was frozen before request 1. CNW 417 resolved uniquely by stable source suffix and was corroborated by CNW identifier and title as database ID `21`; `MAX(works.id) + 1` resolved to confirmed-absent ID `447`. Independent expectations used parameterized direct SQL rather than the Work scopes. The API ran through one in-process Rails integration session, with no network-facing server or external network request. PostgreSQL default and active transactions were read-only before and after execution, and the harness also blocked application writes and counted write-like SQL.

The final checklist describes seven ordinary search/filter requests although D03–D10 contains eight calls. The exact 14-request matrix remained authoritative: D09 is reported separately as the equal-bounds check, leaving seven requests in the ordinary-filter category without omitting a call.

## Fixed request matrix and observed outcomes

| ID | GET path and parameters | HTTP / content type | Shape | Expected / returned rows | Database reconciliation |
|---|---|---|---|---:|---|
| `D01_INDEX` | `/api/works`; `{}` | 200 / `application/json; charset=utf-8` | array | 441 / 441 | ordered IDs and exposed items equal |
| `D02_DETAIL` | `/api/works/21`; `{}` | 200 / `application/json; charset=utf-8` | object | 1 / 1 | all fields and child counts equal |
| `D03_Q_TITLE` | `/api/works`; `{"q":"Duet"}` | 200 / `application/json; charset=utf-8` | array | 2 / 2 | ordered IDs equal; instrumentation order differs |
| `D04_CATALOGUE_BARE` | `/api/works`; `{"catalogue_number":"417"}` | 200 / `application/json; charset=utf-8` | array | 1 / 1 | ordered IDs and exposed items equal |
| `D05_CATALOGUE_PREFIXED` | `/api/works`; `{"catalogue_number":"CNW 417"}` | 200 / `application/json; charset=utf-8` | array | 0 / 0 | ordered IDs and exposed items equal |
| `D06_INSTRUMENTATION` | `/api/works`; `{"instrumentation":"voices"}` | 200 / `application/json; charset=utf-8` | array | 7 / 7 | ordered IDs and exposed items equal |
| `D07_YEAR_FROM` | `/api/works`; `{"year_from":"1889"}` | 200 / `application/json; charset=utf-8` | array | 397 / 397 | ordered IDs and exposed items equal |
| `D08_YEAR_TO` | `/api/works`; `{"year_to":"1889"}` | 200 / `application/json; charset=utf-8` | array | 43 / 43 | ordered IDs and exposed items equal |
| `D09_YEAR_EQUAL_BOUNDS` | `/api/works`; `{"year_from":"1889","year_to":"1889"}` | 200 / `application/json; charset=utf-8` | array | 5 / 5 | ordered IDs and exposed items equal |
| `D10_GENRE` | `/api/works`; `{"genre":"manuscript"}` | 200 / `application/json; charset=utf-8` | array | 2 / 2 | ordered IDs and exposed items equal |
| `D11_INVALID_YEAR_FROM` | `/api/works`; `{"year_from":"not-a-year"}` | 200 / `application/json; charset=utf-8` | array | 435 / 435 | ordered IDs and exposed items equal |
| `D12_INVALID_YEAR_TO` | `/api/works`; `{"year_to":"not-a-year"}` | 200 / `application/json; charset=utf-8` | array | 0 / 0 | ordered IDs and exposed items equal |
| `D13_INVERTED_YEARS` | `/api/works`; `{"year_from":"1900","year_to":"1899"}` | 200 / `application/json; charset=utf-8` | array | 0 / 0 | ordered IDs and exposed items equal |
| `D14_MISSING_DETAIL` | `/api/works/447`; `{}` | 404 / `text/html; charset=UTF-8` | non-JSON response | absent / n/a | ID 447 confirmed absent; 404 returned |

Transport and shape are distinct from data fidelity: 13 responses were JSON-parseable (12 arrays and one object); D14 was a non-JSON 404 whose raw body was excluded. No HTTP success in this table is treated as usability or official-catalogue evidence.

## Index characterization

D01 returned HTTP 200 with `application/json; charset=utf-8`, a bare JSON array, and 441 rows. The returned ordered ID sequence, every exposed item, and the title sequence matched the direct database expectation. The summary shape used exactly these keys: `id`, `title`, `composer`, `catalogue_number`, `composition_date`, `composition_year`, `genre`, `instrumentation`, and sanitized `source_file`; `composer` contained `id` and `name`.

The database contained seven tied-title groups. This run's exact ID sequence matched the independent database query, but `order(:title)` has no explicit tie-breaker, so ordering among equal titles is not guaranteed in another run.

## CNW 417 detail characterization

D02 requested database ID `21` and returned HTTP 200 with a bare JSON object. The exact 15-key top-level shape matched the unchanged controller: the nine summary keys plus `source_identifier`, `catalogue_identifiers`, `movements`, `sources`, `performances`, and `external_references`. Every exposed scalar/collection value matched the canonical database after treating the three database-unordered child collections as multisets.

| Child collection | Database rows | API rows | Equal |
|---|---:|---:|---|
| `instrumentation` | 2 | 2 | yes |
| `catalogue_identifiers` | 1 | 1 | yes |
| `movements` | 0 | 0 | yes |
| `sources` | 0 | 0 | yes |
| `performances` | 0 | 0 | yes |
| `external_references` | 0 | 0 | yes |

The raw database/API `source_file` value was compared only in memory, matched, and was replaced with its stable archive-relative value before evidence serialization. This detail equality describes the API's exposure of the canonical database; it does not supersede Stage B's source-fidelity findings.

## Search, filter, and boundary results

### Exact ordered result IDs

<details>
<summary><code>D03_Q_TITLE</code> — 2 expected and 2 returned</summary>

- Input: `{"q":"Duet"}`
- Expected ordered IDs: `[21, 80]`
- Returned ordered IDs: `[21, 80]`
- CNW 417 expected/returned: yes / yes.

</details>

<details>
<summary><code>D04_CATALOGUE_BARE</code> — 1 expected and 1 returned</summary>

- Input: `{"catalogue_number":"417"}`
- Expected ordered IDs: `[21]`
- Returned ordered IDs: `[21]`
- CNW 417 expected/returned: yes / yes.

</details>

<details>
<summary><code>D05_CATALOGUE_PREFIXED</code> — 0 expected and 0 returned</summary>

- Input: `{"catalogue_number":"CNW 417"}`
- Expected ordered IDs: `[]`
- Returned ordered IDs: `[]`
- CNW 417 expected/returned: no / no.

</details>

<details>
<summary><code>D06_INSTRUMENTATION</code> — 7 expected and 7 returned</summary>

- Input: `{"instrumentation":"voices"}`
- Expected ordered IDs: `[395, 399, 21, 398, 400, 396, 397]`
- Returned ordered IDs: `[395, 399, 21, 398, 400, 396, 397]`
- CNW 417 expected/returned: yes / yes.

</details>

<details>
<summary><code>D07_YEAR_FROM</code> — 397 expected and 397 returned</summary>

- Input: `{"year_from":"1889"}`
- Expected ordered IDs: `[127, 375, 321, 388, 391, 184, 317, 103, 260, 185, 122, 359, 346, 377, 285, 31, 28, 7, 6, 8, 445, 1, 442, 5, 446, 9, 373, 336, 395, 108, 414, 72, 98, 117, 258, 130, 349, 338, 20, 372, 257, 367, 432, 356, 233, 279, 322, 434, 302, 170, 429, 305, 410, 297, 274, 187, 357, 267, 263, 186, 255, 253, 189, 188, 354, 381, 439, 364, 275, 182, 270, 155, 283, 190, 191, 347, 366, 192, 146, 438, 376, 193, 116, 342, 408, 399, 21, 194, 277, 402, 428, 315, 25, 413, 158, 331, 195, 125, 96, 242, 23, 115, 19, 26, 196, 140, 197, 198, 326, 365, 286, 199, 133, 173, 319, 341, 175, 368, 379, 200, 172, 339, 401, 299, 77, 203, 201, 421, 202, 360, 323, 151, 435, 204, 205, 177, 66, 163, 206, 207, 392, 162, 345, 363, 327, 236, 165, 164, 114, 249, 171, 291, 168, 430, 208, 246, 144, 405, 141, 131, 167, 250, 254, 161, 316, 148, 427, 370, 179, 160, 398, 437, 424, 369, 29, 174, 243, 433, 209, 358, 406, 431, 300, 176, 210, 320, 271, 293, 211, 303, 273, 344, 343, 181, 351, 134, 139, 137, 145, 143, 135, 136, 142, 138, 325, 123, 126, 403, 380, 332, 74, 75, 73, 337, 212, 48, 394, 88, 89, 87, 409, 256, 407, 30, 213, 289, 214, 34, 128, 215, 248, 262, 353, 272, 423, 404, 56, 49, 44, 45, 35, 46, 52, 53, 47, 50, 39, 36, 43, 40, 42, 41, 55, 280, 217, 244, 245, 374, 287, 418, 292, 425, 251, 237, 216, 298, 278, 69, 221, 219, 220, 329, 218, 301, 224, 335, 355, 222, 223, 152, 70, 235, 79, 78, 225, 269, 390, 71, 240, 183, 67, 22, 384, 38, 37, 54, 51, 290, 33, 252, 150, 12, 333, 153, 100, 378, 154, 382, 166, 371, 340, 411, 294, 334, 318, 226, 330, 282, 159, 94, 241, 417, 296, 276, 400, 328, 13, 420, 119, 147, 57, 58, 60, 61, 62, 113, 288, 266, 169, 412, 132, 362, 118, 24, 265, 149, 389, 393, 247, 444, 14, 129, 227, 180, 4, 121, 15, 102, 396, 281, 295, 32, 234, 284, 228, 229, 426, 230, 264, 68, 436, 443, 238, 231, 361, 178, 324, 18, 415, 350, 261, 352, 156, 11, 259, 348, 232, 239, 383, 422, 397, 416, 304, 120, 124, 306, 157]`
- Returned ordered IDs: `[127, 375, 321, 388, 391, 184, 317, 103, 260, 185, 122, 359, 346, 377, 285, 31, 28, 7, 6, 8, 445, 1, 442, 5, 446, 9, 373, 336, 395, 108, 414, 72, 98, 117, 258, 130, 349, 338, 20, 372, 257, 367, 432, 356, 233, 279, 322, 434, 302, 170, 429, 305, 410, 297, 274, 187, 357, 267, 263, 186, 255, 253, 189, 188, 354, 381, 439, 364, 275, 182, 270, 155, 283, 190, 191, 347, 366, 192, 146, 438, 376, 193, 116, 342, 408, 399, 21, 194, 277, 402, 428, 315, 25, 413, 158, 331, 195, 125, 96, 242, 23, 115, 19, 26, 196, 140, 197, 198, 326, 365, 286, 199, 133, 173, 319, 341, 175, 368, 379, 200, 172, 339, 401, 299, 77, 203, 201, 421, 202, 360, 323, 151, 435, 204, 205, 177, 66, 163, 206, 207, 392, 162, 345, 363, 327, 236, 165, 164, 114, 249, 171, 291, 168, 430, 208, 246, 144, 405, 141, 131, 167, 250, 254, 161, 316, 148, 427, 370, 179, 160, 398, 437, 424, 369, 29, 174, 243, 433, 209, 358, 406, 431, 300, 176, 210, 320, 271, 293, 211, 303, 273, 344, 343, 181, 351, 134, 139, 137, 145, 143, 135, 136, 142, 138, 325, 123, 126, 403, 380, 332, 74, 75, 73, 337, 212, 48, 394, 88, 89, 87, 409, 256, 407, 30, 213, 289, 214, 34, 128, 215, 248, 262, 353, 272, 423, 404, 56, 49, 44, 45, 35, 46, 52, 53, 47, 50, 39, 36, 43, 40, 42, 41, 55, 280, 217, 244, 245, 374, 287, 418, 292, 425, 251, 237, 216, 298, 278, 69, 221, 219, 220, 329, 218, 301, 224, 335, 355, 222, 223, 152, 70, 235, 79, 78, 225, 269, 390, 71, 240, 183, 67, 22, 384, 38, 37, 54, 51, 290, 33, 252, 150, 12, 333, 153, 100, 378, 154, 382, 166, 371, 340, 411, 294, 334, 318, 226, 330, 282, 159, 94, 241, 417, 296, 276, 400, 328, 13, 420, 119, 147, 57, 58, 60, 61, 62, 113, 288, 266, 169, 412, 132, 362, 118, 24, 265, 149, 389, 393, 247, 444, 14, 129, 227, 180, 4, 121, 15, 102, 396, 281, 295, 32, 234, 284, 228, 229, 426, 230, 264, 68, 436, 443, 238, 231, 361, 178, 324, 18, 415, 350, 261, 352, 156, 11, 259, 348, 232, 239, 383, 422, 397, 416, 304, 120, 124, 306, 157]`
- CNW 417 expected/returned: yes / yes.

</details>

<details>
<summary><code>D08_YEAR_TO</code> — 43 expected and 43 returned</summary>

- Input: `{"year_to":"1889"}`
- Expected ordered IDs: `[313, 106, 63, 314, 16, 312, 386, 21, 80, 97, 96, 440, 17, 2, 385, 437, 107, 81, 86, 90, 310, 35, 10, 105, 76, 91, 84, 83, 82, 308, 93, 64, 57, 65, 309, 27, 387, 311, 307, 104, 441, 99, 419]`
- Returned ordered IDs: `[313, 106, 63, 314, 16, 312, 386, 21, 80, 97, 96, 440, 17, 2, 385, 437, 107, 81, 86, 90, 310, 35, 10, 105, 76, 91, 84, 83, 82, 308, 93, 64, 57, 65, 309, 27, 387, 311, 307, 104, 441, 99, 419]`
- CNW 417 expected/returned: yes / yes.

</details>

<details>
<summary><code>D09_YEAR_EQUAL_BOUNDS</code> — 5 expected and 5 returned</summary>

- Input: `{"year_from":"1889","year_to":"1889"}`
- Expected ordered IDs: `[21, 96, 437, 35, 57]`
- Returned ordered IDs: `[21, 96, 437, 35, 57]`
- CNW 417 expected/returned: yes / yes.

</details>

<details>
<summary><code>D10_GENRE</code> — 2 expected and 2 returned</summary>

- Input: `{"genre":"manuscript"}`
- Expected ordered IDs: `[21, 437]`
- Returned ordered IDs: `[21, 437]`
- CNW 417 expected/returned: yes / yes.

</details>

<details>
<summary><code>D11_INVALID_YEAR_FROM</code> — 435 expected and 435 returned</summary>

- Input: `{"year_from":"not-a-year"}`
- Expected ordered IDs: `[127, 375, 321, 388, 391, 184, 317, 313, 103, 260, 185, 106, 63, 122, 314, 359, 346, 377, 285, 31, 28, 7, 6, 8, 445, 1, 442, 5, 446, 9, 373, 336, 395, 108, 16, 414, 72, 98, 117, 258, 130, 349, 338, 20, 372, 257, 367, 432, 356, 233, 279, 322, 434, 302, 170, 429, 312, 305, 410, 297, 274, 187, 357, 267, 263, 186, 255, 253, 189, 188, 354, 381, 439, 364, 275, 182, 270, 155, 386, 283, 190, 191, 347, 366, 192, 146, 438, 376, 193, 116, 342, 408, 399, 21, 80, 194, 277, 402, 428, 315, 25, 413, 158, 331, 195, 125, 97, 96, 242, 23, 115, 19, 26, 196, 140, 197, 198, 326, 365, 286, 199, 133, 173, 319, 341, 175, 440, 368, 379, 200, 172, 339, 401, 299, 77, 203, 201, 421, 202, 360, 323, 151, 435, 204, 205, 177, 66, 163, 206, 207, 392, 162, 345, 363, 236, 327, 165, 164, 114, 249, 171, 291, 168, 430, 208, 246, 144, 405, 141, 131, 17, 167, 250, 254, 161, 316, 2, 148, 385, 427, 370, 179, 160, 398, 437, 424, 369, 29, 174, 243, 433, 209, 358, 406, 431, 300, 176, 210, 320, 271, 293, 211, 303, 273, 344, 343, 181, 351, 134, 139, 137, 145, 143, 135, 136, 142, 138, 325, 123, 126, 107, 403, 380, 332, 74, 75, 73, 337, 212, 48, 394, 81, 86, 88, 89, 87, 90, 409, 256, 407, 30, 213, 289, 214, 34, 128, 215, 310, 248, 262, 353, 272, 423, 404, 56, 49, 44, 45, 35, 46, 52, 53, 47, 50, 39, 36, 43, 40, 42, 41, 55, 10, 280, 105, 217, 244, 245, 374, 287, 418, 292, 425, 251, 237, 216, 298, 278, 69, 221, 219, 220, 329, 218, 301, 224, 335, 355, 222, 223, 152, 70, 235, 76, 79, 78, 225, 269, 390, 71, 91, 240, 183, 67, 22, 384, 38, 37, 54, 51, 290, 82, 83, 84, 33, 252, 308, 150, 12, 333, 153, 100, 378, 154, 382, 166, 371, 340, 411, 294, 334, 318, 226, 330, 282, 159, 93, 94, 241, 417, 296, 276, 400, 328, 13, 420, 64, 119, 147, 57, 58, 60, 61, 62, 65, 113, 288, 266, 169, 412, 132, 309, 362, 118, 24, 27, 265, 387, 149, 389, 311, 393, 307, 247, 444, 14, 104, 129, 227, 180, 4, 121, 441, 15, 102, 99, 396, 281, 295, 32, 234, 284, 228, 229, 426, 230, 264, 68, 436, 443, 238, 231, 361, 178, 324, 18, 415, 350, 261, 352, 156, 11, 259, 348, 232, 239, 419, 383, 422, 397, 416, 304, 120, 124, 306, 157]`
- Returned ordered IDs: `[127, 375, 321, 388, 391, 184, 317, 313, 103, 260, 185, 106, 63, 122, 314, 359, 346, 377, 285, 31, 28, 7, 6, 8, 445, 1, 442, 5, 446, 9, 373, 336, 395, 108, 16, 414, 72, 98, 117, 258, 130, 349, 338, 20, 372, 257, 367, 432, 356, 233, 279, 322, 434, 302, 170, 429, 312, 305, 410, 297, 274, 187, 357, 267, 263, 186, 255, 253, 189, 188, 354, 381, 439, 364, 275, 182, 270, 155, 386, 283, 190, 191, 347, 366, 192, 146, 438, 376, 193, 116, 342, 408, 399, 21, 80, 194, 277, 402, 428, 315, 25, 413, 158, 331, 195, 125, 97, 96, 242, 23, 115, 19, 26, 196, 140, 197, 198, 326, 365, 286, 199, 133, 173, 319, 341, 175, 440, 368, 379, 200, 172, 339, 401, 299, 77, 203, 201, 421, 202, 360, 323, 151, 435, 204, 205, 177, 66, 163, 206, 207, 392, 162, 345, 363, 236, 327, 165, 164, 114, 249, 171, 291, 168, 430, 208, 246, 144, 405, 141, 131, 17, 167, 250, 254, 161, 316, 2, 148, 385, 427, 370, 179, 160, 398, 437, 424, 369, 29, 174, 243, 433, 209, 358, 406, 431, 300, 176, 210, 320, 271, 293, 211, 303, 273, 344, 343, 181, 351, 134, 139, 137, 145, 143, 135, 136, 142, 138, 325, 123, 126, 107, 403, 380, 332, 74, 75, 73, 337, 212, 48, 394, 81, 86, 88, 89, 87, 90, 409, 256, 407, 30, 213, 289, 214, 34, 128, 215, 310, 248, 262, 353, 272, 423, 404, 56, 49, 44, 45, 35, 46, 52, 53, 47, 50, 39, 36, 43, 40, 42, 41, 55, 10, 280, 105, 217, 244, 245, 374, 287, 418, 292, 425, 251, 237, 216, 298, 278, 69, 221, 219, 220, 329, 218, 301, 224, 335, 355, 222, 223, 152, 70, 235, 76, 79, 78, 225, 269, 390, 71, 91, 240, 183, 67, 22, 384, 38, 37, 54, 51, 290, 82, 83, 84, 33, 252, 308, 150, 12, 333, 153, 100, 378, 154, 382, 166, 371, 340, 411, 294, 334, 318, 226, 330, 282, 159, 93, 94, 241, 417, 296, 276, 400, 328, 13, 420, 64, 119, 147, 57, 58, 60, 61, 62, 65, 113, 288, 266, 169, 412, 132, 309, 362, 118, 24, 27, 265, 387, 149, 389, 311, 393, 307, 247, 444, 14, 104, 129, 227, 180, 4, 121, 441, 15, 102, 99, 396, 281, 295, 32, 234, 284, 228, 229, 426, 230, 264, 68, 436, 443, 238, 231, 361, 178, 324, 18, 415, 350, 261, 352, 156, 11, 259, 348, 232, 239, 419, 383, 422, 397, 416, 304, 120, 124, 306, 157]`
- CNW 417 expected/returned: yes / yes.

</details>

<details>
<summary><code>D12_INVALID_YEAR_TO</code> — 0 expected and 0 returned</summary>

- Input: `{"year_to":"not-a-year"}`
- Expected ordered IDs: `[]`
- Returned ordered IDs: `[]`
- CNW 417 expected/returned: no / no.

</details>

<details>
<summary><code>D13_INVERTED_YEARS</code> — 0 expected and 0 returned</summary>

- Input: `{"year_from":"1900","year_to":"1899"}`
- Expected ordered IDs: `[]`
- Returned ordered IDs: `[]`
- CNW 417 expected/returned: no / no.

</details>

### Interpretation of bounded behaviors

- Title query: D03 returned IDs `[21, 80]`. The ID sequence and values matched, except that CNW 417's instrumentation names were reversed relative to the independently ordered database expectation.
- Catalogue number: bare `417` returned CNW 417 alone; prefixed `CNW 417` returned zero rows. The API searches the stored `Work.catalogue_number` substring only, where this record stores bare `417`; it does not search the labelled identifier representation.
- Instrumentation: `voices` returned seven works and included CNW 417, matching the database-derived ID set. This tests stored names, not authoritative performance-medium semantics.
- Inclusive years: `year_from=1889` included CNW 417; `year_to=1889` included it; equal bounds `1889..1889` returned five works including it. These observations confirm inclusive database predicates in this bounded run.
- Genre: `manuscript` returned two works including CNW 417, matching stored genre values.
- Invalid lower year: `not-a-year` was silently coerced by `.to_i` to effective integer `0`, returned HTTP 200 and 435 rows, and produced no validation response.
- Invalid upper year: the same silent coercion produced effective `year_to=0`, HTTP 200, and zero rows. This is coercion, not validation.
- Inverted bounds: `1900..1899` returned HTTP 200 with an empty array. The inversion was silently accepted and not reported.
- Missing detail: confirmed-absent ID `447` returned HTTP 404 with `text/html; charset=UTF-8`; the body was not retained, and no exception escaped the in-process request.

## Database reconciliation and preservation

- List result counts equal independent database expectations: 12/12.
- Exact ordered work-ID sequences equal: 12/12.
- Exact exposed list-item equality: 11/12; D03 is the sole ordering discrepancy.
- Database-value equality after normalizing only instrumentation array order: 12/12.
- CNW 417 detail exposed-field and child-count equality: yes.
- Raw `source_file` comparisons: 1334/1334 matched; zero mismatches and no local prefixes were persisted.
- API GET calls: 14; retries: 0; direct request exceptions: 0; external-network requests: 0.
- Stage D importer invocations: 0; preserved canonical importer invocation total: 1.

| Evaluated table | Before | After |
|---|---:|---:|
| `composers` | 1 | 1 |
| `works` | 441 | 441 |
| `catalogue_identifiers` | 1702 | 1702 |
| `movements` | 0 | 0 |
| `instrumentations` | 1651 | 1651 |
| `source_references` | 0 | 0 |
| `performances` | 0 | 0 |
| `external_references` | 2001 | 2001 |
| `import_logs` | 446 | 446 |

The before/after overall digest was identical (`05b783204073e38dc5a5418abda9f50ebc721c08b99313b3aa6c7bb2e9395a3d`), every per-table digest matched, all eight orphan checks were zero, and the API harness observed zero write-like SQL attempts. Principal Stage A–C raw artifacts and all committed evidence/implementation hashes remained unchanged.

## Limitations

- Database equality is not official-source fidelity; the database contains the importer's transformations, omissions, and incorrect mappings.
- Stage B found material omissions and incorrect mappings, so a response can agree perfectly with the database while remaining incomplete or semantically wrong relative to the official XML.
- The bounded matrix does not establish usability, accessibility, general performance, security, deployment readiness, or production readiness.
- No external-reference URL was followed or validated.
- The 14 requests are predeclared and useful for characterization, but they are not exhaustive of routes, parameter combinations, data states, or MEI structures.
- HTTP 200 confirms transport success only; it does not establish semantic fidelity or a satisfactory user experience.
- Tied-title ordering remains run-specific because the controller has no explicit secondary sort key.
