# Phase 2B authoritative-corpus evaluation protocol

## Technical summary

This protocol is frozen before importer execution. The first run must use the unchanged Phase 1 baseline and all 446 official Carl Nielsen XML files in a disposable database. It separates technical completion from semantic fidelity, evaluates the eight-record purposive sample at two declared depths, tests seven focused selector/schema predictions, and characterizes the API against the database state actually produced. No result in this document is an observed import result.

## Evidence base

| Evidence item | Predeclared value |
|---|---|
| Baseline commit | `8b40722103acb36826a81b7bd1a90983435e9dd7` |
| Institution | Royal Danish Library |
| Official archive title | *Thematic Catalogues of Works by Carl Nielsen, Johann Adolph Scheibe, Niels W. Gade and J.P.E. Hartmann* |
| Repository record | `https://loar.kb.dk/handle/1902/49096` |
| Official archive URL | `https://loar.kb.dk/bitstreams/ff8e95c9-c1e8-4d65-8a51-59daa4572dee/download` |
| Access date | 2026-08-16 |
| Archive filename | `dcm-catalogue-data.zip` |
| Archive SHA-256 | `fa3ff9e3012a6a9e8d21c098105bea3be9670945bb76aa5ea46391d2c33cf8ec` |
| Licence | CC0 1.0 Universal (`http://creativecommons.org/publicdomain/zero/1.0/`) |
| Official Carl Nielsen XML corpus | 446 files under `dcm-catalogue-data/cnw/data-cnw/` |
| Primary/probe manifest | `docs/report_evidence/phase2_sample_manifest.csv`: eight primary records plus seven focused probes |

Manifest titles are the normalized first immediate `<work>/<title>` values, and source identifiers combine the immediate `<work>/<identifier label="CNW">` label and value. Every manifest file SHA-256 was calculated from the named member in the cached official ZIP and byte-compared with the corresponding extracted XML.

The official XML records are the source evidence for this evaluation. The four Phase 1 MEI-like fixtures remain purpose-built, non-authoritative prototype fixtures informed by Carl Nielsen catalogue data and MEI structures. They are useful for prototype tests but are not catalogue ground truth. In particular, the official archive identifies `cnw0002.xml` as CNW 2, *Maskarade*, and `cnw0018.xml` as CNW 18, *Moderen*, while the existing prototype fixtures associate those identifiers with different titles.

## Evaluation questions

- **RQ1.** Can the baseline importer technically process the institutional 446-file corpus?
- **RQ2.** For the eight-record purposive sample, which intended catalogue fields are preserved, transformed, omitted, or imported incorrectly?
- **RQ3.** Do the identified duplicate-identifier, nested-date, and namespace cases behave as predicted?
- **RQ4.** Does the API faithfully expose the database state produced by the importer, including limitations and missing structures?
- **RQ5.** After later evidence-driven corrections, how do technical completion and semantic-fidelity results change?

Usability will be evaluated separately after the application has a stable authoritative-data state. API availability or an HTTP success response is not usability evidence.

## Fixed sample and measurement rules

All eight primary records remain one purposive, non-statistically-representative sample. Tiering changes manual review depth, not membership or whether a record is imported.

| Tier | Records | Review depth |
|---|---|---|
| Detailed fidelity | CNW 417, CNW 277, CNW 63, CNW 18 | Twelve bounded, source-located assertions per record across selected fields, counts, and representative nested values |
| Boundary/stress | CNW 53, CNW Coll. 18, CNW 17, CNW 2 | Predeclared technical outcome, aggregate counts, structural presence/absence, and selected representative assertions |
| Focused probes | CNW 27, CNW 64, CNW 70, CNW 81, CNW 237, CNW 67, CNW 10 | One identified identifier/date/namespace prediction per file, evaluated separately from the primary sample |

For this protocol:

- **Technical completion** means the importer attempted the declared input and returned or logged an accountable outcome. It does not imply correct meaning.
- **Semantic fidelity** means agreement with a predeclared, source-located assertion under the classification rubric below.
- **Count** means a declared element or stored-row count at the stated scope; document-wide and work-subtree counts must not be interchanged.
- **Representative value** means a deliberately selected nested value, not an exhaustive transcription of that structure.

## Stage A — unchanged baseline execution

### Procedure

1. Verify the application commit is the baseline above and preserve the commit identifier with the results.
2. Prepare a fresh, dedicated disposable PostgreSQL database using the existing isolated-database approach.
3. Point the unchanged baseline importer at an ignored copy of all 446 official XML files. Do not mix prototype fixtures into this corpus.
4. Capture database counts immediately before the run.
5. Run the unchanged importer once over the corpus and preserve its returned result, logs, warnings, failures, and database state before changing code.
6. Capture database counts immediately afterward and reconcile every input path with its result/log status.

### Measures to record

- files seen;
- successes and failures;
- warnings grouped by stable category; retain exact messages only after removing personal or temporary paths and sensitive context, otherwise preserve a redacted message together with its category;
- elapsed wall-clock time for this one recorded run, labelled contextual rather than a general performance benchmark;
- pre-run and post-run counts for composers, works, catalogue identifiers, movements, instrumentations, source references, performances, external references, and import logs;
- one per-file classification: success without warning, success with warning, logged failure, or unaccounted/aborted;
- failure category and affected source file for every failure; record an exception class only when it is directly observable during unchanged-baseline execution, and do not infer or invent one from message text;
- reconciliation of 446 input files against successes, failures, and logs.

If the batch aborts before producing a normal result, preserve the exception and database state rather than silently restarting. Import completion, XML parsing, and database writes must not be reported as semantic correctness.

## Stage B — primary sample fidelity

### Measures for all eight records

For every primary record, record:

- technical import result and failure classification, if any;
- stored composer and work identity;
- selected title and `catalogue_number`;
- stored catalogue-identifier count, types, and values;
- stored composition date and year;
- stored movement, instrumentation, source, performance, and external-reference counts;
- warning categories;
- API index presence and detail availability.

### Detailed-fidelity source oracle

The following 12 assertions per record are intentionally bounded. They cover selected work facts, counts, and representative nested values without transcribing every event, item, contributor, or target.

#### CNW 417 — simple control

| Assertion | Official-source expectation |
|---|---|
| `417-01` | One work with direct identifier `CNW = 417` |
| `417-02` | Direct contributor is Carl Nielsen with role `composer` |
| `417-03` | Exactly one direct identifier, labelled `CNW` |
| `417-04` | Four direct titles; first untyped title is Danish `Duet` |
| `417-05` | Direct title languages are `da` and `en`; two titles are `subordinate` |
| `417-06` | Direct creation text and `isodate` are `1889-02-04` |
| `417-07` | One expression and zero component lists |
| `417-08` | Two populated performance resources |
| `417-09` | Representative resource: `voices`, code `vu`, count `2`, `solo="false"` |
| `417-10` | Representative resource: `pf.`, code `ka`, count `1`, `solo="false"` |
| `417-11` | Zero manifestations and zero manifestation-held items |
| `417-12` | Zero performance events and zero target-bearing relation/ref/ptr nodes in the work subtree |

#### CNW 277 — multilingual titles, responsibilities, and uncertain date

| Assertion | Official-source expectation |
|---|---|
| `277-01` | One work with direct identifier `CNW = 277` |
| `277-02` | Direct contributors are Carl Nielsen/composer, Jeremiah Joseph Callanan/author, and `Caralis [Christian Preetzmann]`/translator |
| `277-03` | Four identifiers: CNW, CNU, CNS, and FS |
| `277-04` | Five direct titles; first untyped Danish title is `Serenade` |
| `277-05` | Title types include two `alternative` and one `uniform`; language codes are `da` and `en` |
| `277-06` | Creation text is `Between c. 1886 and 1888`, with `notbefore="1886"` and `notafter="1888"` |
| `277-07` | One expression and zero component lists |
| `277-08` | Two resources: `voice`/`vn`/count 1 and `pf.`/`ka`/count 1 |
| `277-09` | Two manifestations and one manifestation-held item |
| `277-10` | Representative manifestation is `Score, autograph, fair copy`; repository is `DK-Kk` |
| `277-11` | One event exists, but it has no direct date, location, person, corporation, or description value |
| `277-12` | Seven target-bearing relation/ref/ptr nodes: six internal/relative and one HTTP relation; representatives are `document.xq?doc=cnw0276.xml` and the `hasReproduction` Carl Nielsen Edition PDF target |

#### CNW 63 — components, manifestations, manuscripts, and performances

| Assertion | Official-source expectation |
|---|---|
| `63-01` | One work with direct identifier `CNW = 63` |
| `63-02` | Direct contributors are Carl Nielsen/composer and Henri Marteau/dedicatee |
| `63-03` | Five identifiers in source order: Opus 9, CNW 63, CNU II/11, CNS 24, FS 20 |
| `63-04` | Two untyped direct titles in `da` and `en`; Danish title is `Sonate nr. 1 for violin og klaver, opus 9` |
| `63-05` | Direct creation text and `isodate` are `1895` |
| `63-06` | Four expressions: one top-level expression and three direct component expressions in one component list |
| `63-07` | Component tempos are `Allegro glorioso`, `Andante`, and `Allegro piacevole e giovanile` in positions 1–3 |
| `63-08` | Two populated resources: `vl.`/`sa`/count 1 and `pf.`/`ka`/count 1 |
| `63-09` | Six manifestations and seven manifestation-held items |
| `63-10` | One hand list; representative manifestation is `Score, sketch`, item `D`, repository `DK-Kk`, location `CNS 24c` |
| `63-11` | Thirty-eight events; first has date `1896-01-15`, venue `Koncertpalæet`, place `Copenhagen`, and two named performers |
| `63-12` | Two target-bearing relation/ref/ptr nodes, both internal/relative: `document.xq?doc=cnw0025.xml` and `/dcm/assets/cnu/pdf/CNU_II_11_chamber_music_2.pdf` |

#### CNW 18 — link categories and structurally complex responsibilities

| Assertion | Official-source expectation |
|---|---|
| `18-01` | One work with direct identifier `CNW = 18` |
| `18-02` | Direct contributors are Carl Nielsen/composer and Helge Rode/author |
| `18-03` | Five identifiers in source order: Opus 41, CNW 18, CNU, CNS 345, FS 94 |
| `18-04` | Four direct titles in `da` and `en`, including two subordinate titles; first Danish title names *Moderen* |
| `18-05` | Creation text is `1920–21`, with `notbefore="1920"` and `notafter="1921"` |
| `18-06` | Forty-nine work-subtree expressions: two top-level and 47 direct component expressions in ten work-subtree component lists |
| `18-07` | Representative component is `Prolog`/`Prologue`; nested `Marsch`/`March` has `n="1"` and tempo `Tempo giusto` |
| `18-08` | Thirty-one populated resources; representatives include `fl.`/`wa`/count 3 and `cor.`/`ba`/count 4 |
| `18-09` | Thirty-three manifestations and 27 manifestation-held items |
| `18-10` | Representative manifestation is `Sketch (Nos. 20, 22)`, item `Ie`, repository `DK-Kk`, location `CNS 345g` |
| `18-11` | Ninety-two events; first has date `1921-01-30`, Royal Theatre venue, Copenhagen place, conductor Ebbe Hamerik, and named performers |
| `18-12` | Thirty-nine target-bearing relation/ref/ptr nodes: nine HTTP(S) and 30 internal/relative; representatives are internal `cnw0035.xml` and the Carl Nielsen Edition PDF ending `CNU_I_09_incidental_music_2.pdf` |

### Boundary/stress predeclarations

| Record | Predicted technical outcome before execution | Bounded checks |
|---|---|---|
| CNW 53 | Import completes because no identifier-value collision is known | No direct work creation date; zero `perfRes`; one manifestation/item; zero performance events; record warnings, stored counts, and selected title/identifier |
| CNW Coll. 18 | Import completes because no identifier-value collision is known | Preserve the record as one collection work; check 38 `hasPart` relations within 40 relations, absence of events/absolute work URLs, and whether graph targets are misclassified |
| CNW 17 | Import completes because no identifier-value collision is known | Check 57 expressions, 11 component lists, 62 `perfRes`, 15 manifestations, 13 items, 211 events, and 92 work-subtree target attributes, all non-absolute: 84 graphic targets and eight relation targets; also check stored aggregate rows and warnings |
| CNW 2 | Import completes because no identifier-value collision is known | Check largest-file handling, 54 expressions, 50 `perfRes`, 39 manifestations, 38 items, 602 events, and 106 work-subtree target attributes: 100 graphic targets and six relation/ref/ptr targets, with one absolute URL; also check stored aggregate rows and warnings |

### Assertion classification

Classify every predeclared assertion as exactly one of:

- `preserved`;
- `transformed as intended`;
- `omitted`;
- `incorrect`;
- `not applicable`;
- `blocked by import failure`.

For every classification, retain the assertion ID, official-source locator/value, expected mapped meaning, stored/API value, and brief rationale. Report per-domain counts and proportions with explicit denominators. Do not calculate one catalogue “accuracy” percentage unless the denominator and unequal assertion coverage are explicitly justified. Anything outside the declared assertions is `not evaluated`, not assumed correct.

## Stage C — focused probes

Record the prediction below before execution and the observed outcome afterward. Keep prediction and observation in separate fields.

| Probe | Pre-execution prediction | Measures |
|---|---|---|
| `cnw0027.xml` | Duplicate value `27` under Opus and CNW violates the per-work/value unique constraint; transaction fails | Failure/log status, database rollback, error class, stored rows |
| `cnw0064.xml` | Duplicate value `64` under CNW and FS violates the same constraint; transaction fails | Same measures |
| `cnw0070.xml` | Duplicate value `43` under Opus and CNS violates the same constraint; transaction fails | Same measures |
| `cnw0081.xml` | Duplicate value `10` under CNS and FS violates the same constraint; transaction fails | Same measures |
| `cnw0237.xml` | Duplicate value `237` under CNW and CNS violates the same constraint; transaction fails | Same measures |
| `cnw0067.xml` | With no direct work date, the descendant selector chooses the first nested bibliographic creation date, `1913-04-29`, and stores 1913 as if it were the work composition year | Selected node context, stored date/year, warning, prediction agreement |
| `cnw0010.xml` | Namespace removal permits technical processing of elements using the explicit `m:` prefix, while discarding namespace identity | Technical status, selected fields/counts, parser warnings, prediction agreement |

If a canonical Stage A result is ambiguous, run the individual probe only in another disposable database and label it a focused re-probe. Do not replace the Stage A evidence.

## Stage D — API characterization

Use the authoritative-data database state created by Stage A. Resolve database IDs from that run rather than assuming stable numeric IDs.

| Check | Predeclared request/input | Record |
|---|---|---|
| Index | `GET /api/works` | HTTP status, content type, response shape, row count, ordering, and reconciliation with stored works |
| Detail | `GET /api/works/:id` for a successfully imported detailed record | HTTP status and equality of exposed fields/child counts to database state |
| Free-text search | `GET /api/works?q=<known stored title fragment>` | Returned IDs and agreement with the baseline search scope |
| CNW search | `GET /api/works?catalogue_number=<known stored value>` and a `CNW`-prefixed variant | Returned IDs and evidence of first-identifier selection limitations |
| Instrumentation | `GET /api/works?instrumentation=<known stored resource fragment>` | Returned IDs and agreement with stored instrumentation rows |
| Year boundaries | Inclusive `year_from`, `year_to`, and equal-bound requests around known stored years | Returned IDs and boundary behavior |
| Genre | `GET /api/works?genre=<known stored genre fragment>` | Returned IDs and agreement with stored genre values |
| Missing ID | `GET /api/works/:id` with a confirmed absent ID | Status and error behavior |
| Invalid years | Non-numeric `year_from` and `year_to` values | Status, interpretation, result count, and any validation/error response |
| Inverted years | `year_from` greater than `year_to` | Status, result count, and whether inversion is reported or silently accepted |

For every request, distinguish HTTP success, response-shape correctness, database-state fidelity, and semantic limitations. This stage does not measure usability, accessibility, or production readiness.

## Comparison rule

The first execution must use the unchanged baseline commit. Preserve all baseline results before any importer correction. Do not silently replace a failed or incomplete baseline run with corrected results.

Any later implementation correction must be made in a separate commit. Re-run the same corpus, manifest, predictions, assertions, rubric, database initialization, and API checks in a fresh disposable database. Compare baseline and post-correction states for:

- technical import completion;
- warning and failure categories;
- per-domain fidelity classifications and explicit denominators;
- stored aggregate counts;
- focused-probe prediction agreement;
- API behavior and database-state fidelity.

The comparison must cite both states and explain environmental differences. Elapsed time remains contextual unless a separate performance design is approved.

## Scope exclusions

This protocol does not establish:

- statistical representativeness;
- complete scholarly validation of the catalogue;
- general compatibility with all MEI versions or customizations;
- production performance;
- production security;
- deployment readiness;
- usability or accessibility.

It also does not validate every external URL, every nested catalogue value, PNG incipits, or the other composer subtrees in the archive.

## Evidence outputs planned

The following sanitized outputs will be created only after the corresponding execution and review. They do not exist and contain no result values at protocol freeze time:

- `docs/report_evidence/phase2_baseline_import_results.md`;
- `docs/report_evidence/phase2_fidelity_matrix.csv`;
- `docs/report_evidence/phase2_api_results.md`;
- `docs/report_evidence/phase2_post_correction_comparison.md`.
