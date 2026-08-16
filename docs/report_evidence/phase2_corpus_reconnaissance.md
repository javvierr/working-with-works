# Phase 2A: authoritative Carl Nielsen MEI corpus reconnaissance

**Reconnaissance date:** 16 August 2026

**Comparison baseline:** `8b40722103acb36826a81b7bd1a90983435e9dd7`

**Scope:** official-source acquisition, mechanical corpus profiling, static comparison with the current importer, and purposive sample design. No corpus record was imported and no database was changed.

## Technical summary

- The official Royal Danish Library Open Access Repository (LOAR) archive was acquired from the institutional bitstream, not a mirror. Its downloaded size is 234,079,300 bytes and its SHA-256 is `fa3ff9e3012a6a9e8d21c098105bea3be9670945bb76aa5ea46391d2c33cf8ec`. The locally calculated MD5 also matches LOAR's bitstream metadata.
- The archive contains four composer catalogues plus macOS packaging metadata. The substantive Carl Nielsen subtree contains 446 XML catalogue files and 2,008 PNG incipits. Only the 446 XML files were extracted for profiling.
- All 446 XML files are well-formed, declare the MEI namespace and `meiversion="4.0.1"`, and contain exactly one `<work>` element in this release. No multi-work file was observed. Collection and part structure is instead expressed extensively through cross-file relations.
- The corpus is structurally incompatible with several current importer assumptions. Static inspection predicts deterministic composer misattribution, no imported movements, sources, or performances, flattened titles/dates/instrumentation, and many internal relations being labelled as external references.
- An eight-record purposive maximum-variation sample is recommended. It is not statistically representative; it is designed to exercise the most consequential structures and failure modes found during this reconnaissance.

## 1. Source and rights record

| Field | Verified value |
|---|---|
| Institution | Royal Danish Library |
| Institutional guide | [Carl Nielsen's works](https://www.kb.dk/en/services/cultural-heritage-research-and-study/cultural-heritage-data-and-datasets/carl-nielsens-works) |
| Exact LOAR dataset title | *Thematic Catalogues of Works by Carl Nielsen, Johann Adolph Scheibe, Niels W. Gade and J.P.E. Hartmann* |
| Contributor/author in LOAR | Danish Centre for Music Editing |
| Dataset type | Dataset |
| Permanent repository record | [https://loar.kb.dk/handle/1902/49096](https://loar.kb.dk/handle/1902/49096) |
| Full official metadata | [LOAR full item record](https://loar.kb.dk/items/7095cffa-6c9c-42c5-b1a7-44deae920871/full) |
| Direct official download | [LOAR bitstream download](https://loar.kb.dk/bitstreams/ff8e95c9-c1e8-4d65-8a51-59daa4572dee/download) |
| Official bitstream metadata | [LOAR bitstream API record](https://loar.kb.dk/server/api/core/bitstreams/ff8e95c9-c1e8-4d65-8a51-59daa4572dee) |
| Licence | CC0 1.0 Universal |
| Licence URI recorded by LOAR | [http://creativecommons.org/publicdomain/zero/1.0/](http://creativecommons.org/publicdomain/zero/1.0/) |
| Issue date | 27 June 2024 |
| Accessioned/available | 27 June 2024 at 09:05:24 UTC |
| LOAR item `lastModified` | 1 September 2025 at 11:57:08.269 UTC, from the [official item API](https://loar.kb.dk/server/api/core/items/7095cffa-6c9c-42c5-b1a7-44deae920871) |
| Access date | 16 August 2026 |

The Royal Danish Library guide describes the dataset as an extract of the MEI-encoded raw catalogue data, states that it contains metadata rather than musical scores, and describes it as public-domain material. The precise CC0 designation and licence URI above come from the LOAR metadata record. The LOAR item title covers four composers; *Carl Nielsen's works* is the title and focus of the institutional guide, not the title of the deposited item.

The item-level `lastModified` timestamp is repository metadata. It does not by itself establish that the archive bytes changed on that date, because the bitstream record exposes no separate modification date.

## 2. Acquisition and integrity facts

| Fact | Mechanically observed value |
|---|---|
| Archive filename | `dcm-catalogue-data.zip` |
| LOAR advertised size | 223.24 MB |
| Downloaded size | 234,079,300 bytes |
| SHA-256 | `fa3ff9e3012a6a9e8d21c098105bea3be9670945bb76aa5ea46391d2c33cf8ec` |
| Local MD5 | `25f776081b1dad7965128b1dc8cdf1bc` |
| LOAR-recorded MD5 | `25f776081b1dad7965128b1dc8cdf1bc` — exact match |
| ZIP integrity | Full archive test passed with no compressed-data errors |
| Central-directory totals | 19,065 entries: 19,044 files and 21 directories |
| Uncompressed entry bytes | 300,443,116 |
| Compressed entry bytes | 228,864,332; overall expansion ratio approximately 1.313:1 |
| Listing safety scan | Zero absolute paths, drive paths, `..` components, backslashes, control characters, encrypted entries, symlinks, devices, FIFOs, sockets, duplicate filenames, or case-collision groups |
| Extraction boundary | Only `dcm-catalogue-data/cnw/data-cnw/*.xml` was extracted; the full dataset and PNG incipits were not extracted |

The archive listing and entry metadata were inspected before extraction. No archived content was executed. The only archive-hygiene anomaly was macOS packaging debris: a `__MACOSX/` mirror and `.DS_Store` files. The largest substantive entry is `dcm-catalogue-data/cnw/data-cnw/cnw0002.xml` at 1,539,005 bytes; neither the overall nor maximum per-entry expansion ratio showed an obvious archive-expansion anomaly.

## 3. Archive and corpus profile

### 3.1 Archive structure and file counts

Counts in this subsection are central-directory observations. “Substantive” excludes the `__MACOSX/` mirror but does not silently remove `.DS_Store` files.

| Scope | Files/directories | Relevant extensions and structure |
|---|---:|---|
| Entire ZIP | 19,044 files; 21 directories | 15,166 `.png`, 3,840 `.xml`, 2 `.txt`, and 36 metadata or no-conventional-extension entries |
| `dcm-catalogue-data/` payload | 9,512 files; 21 directories | 7,583 `.png`, 1,920 `.xml`, 1 `.txt`, and 8 `.DS_Store` files |
| `__MACOSX/` metadata mirror | 9,532 files; no explicit directory records | AppleDouble metadata mirroring the data tree |
| `dcm-catalogue-data/cnw/` | 2,456 files; 5 directories | 446 catalogue XML files, 2,008 PNG incipits, and 2 `.DS_Store` files |
| `dcm-catalogue-data/cnw/data-cnw/` | 446 XML files; 1 directory record | The complete XML set profiled below |
| `dcm-catalogue-data/cnw/incipits/` | 2,009 files; 3 directories | 1,002 high-resolution PNGs, 1,006 low-resolution PNGs, and 1 `.DS_Store` file |

The substantive top-level composer-entry counts are: `hartw/` 3,247, `cnw/` 2,461, `nwgw/` 2,202, and `schw/` 1,620. These are entry counts, so they include each subtree's directory records and incidental metadata.

### 3.2 Profiling method and definitions

- All 446 direct `.xml` files in `dcm-catalogue-data/cnw/data-cnw/` were parsed with Python's `xml.etree.ElementTree`; a separate `xmllint --noout` pass also succeeded for every file.
- Counts use element local names while namespace declarations are recorded separately. No MEI schema or Schematron validation was performed.
- “Direct work title” means a `<title>` that is an immediate child of `<work>`. This prevents manifestation, bibliography, component, and revision titles from being counted as work titles.
- Date categories apply only to the direct `<work>/<creation>/<date>` node. `exact day` means a normalized `YYYY-MM-DD` value; `partial` means that at least one value in `isodate`, `startdate`, `enddate`, `notbefore`, or `notafter` contains only a year or year-month; `bounded/ranged` means at least one `startdate`, `enddate`, `notbefore`, or `notafter`; and `uncertainty marker` means an explicit uncertainty/bound marker. Categories overlap.
- “Absolute work URL” means a work-descendant `target` beginning with an HTTP or HTTPS scheme. Targets were classified syntactically and were not dereferenced or validated.
- Mechanical counts establish the shape of this archive release. They do not establish semantic correctness, completeness against another catalogue edition, or general compatibility with all MEI.

### 3.3 Mechanically observed corpus characteristics

| Concern | Mechanically observed counts/distribution | Interpretation and relevance |
|---|---|---|
| Files and works | 446 XML files; 446 `<work>` elements; every file has exactly one work; zero multi-work files | The current release happens to fit one-work-per-file processing. This must not be generalized beyond the inspected release. |
| Cross-record work structure | 396 direct work-level `hasPart` relations in 30 files; 393 `isPartOf` relations in 206 files; 865 work-level relations target XML files | Collections and parts are primarily a graph across files, not multiple `<work>` elements in one file. |
| XML namespace/version | All 446 roots use `http://www.music-encoding.org/ns/mei`; all declare `meiversion="4.0.1"` | This is an apparent version declaration, not schema-validation evidence. One file, `dcm-catalogue-data/cnw/data-cnw/cnw0010.xml`, also uses an explicit `m:` prefix bound to the same URI. |
| XML well-formedness | 446/446 parsed; zero parser failures | The corpus is mechanically inspectable with XML tooling. |
| File sizes | Total 26,925,115 bytes; minimum 10,355; p25 24,794; median 34,383; p75 59,626; p90 118,265; p95 172,279; p99 380,143; maximum 1,539,005 | The long upper tail justifies including a very large record in evaluation. |
| Filename forms | 408 `cnwNNNN.xml`, 29 UUID filenames, and 9 numeric filenames | File naming is not a reliable catalogue identifier. |
| Catalogue identifiers | 446 distinct direct `CNW` identifiers; direct work identifiers also include `CNU` in 438 files, `FS` in 407, `CNS` in 365, and `Opus` in 70 | Identifier type and ordering must be retained; the filename and first identifier are not sufficient substitutes. |
| Direct work titles and types | 1,238 direct work titles, all language-tagged. Title counts per file: one in 1 file, two in 256, three in 70, four in 83, five in 33, and six in 3. Types include 181 `alternative` titles in 91 files, 102 `uniform` titles in 101 files, 64 `subordinate` titles in 33 files, and 4 `text_source` titles | A single title column loses title type and language relationships. “Multiple title” is observed; “preferred display title” still requires a mapping rule. |
| Title languages | 665 direct Danish titles, 569 English, 3 Latin, and 1 German. Outside the direct title set, raw `xml:lang` codes include `sv`, `ht`, and `it`; their intended catalogue semantics were not independently validated | Language-bearing content extends beyond a simple Danish/English pair, but unusual raw codes must not be treated as verified natural-language classifications without further review. |
| Direct work responsibilities | 829 role-bearing direct contributor names: composer 446, author 329, dedicatee 42, translator 11, and attributed name 1. Some 352 files have more than one direct contributor and more than one role | Every direct work composer is Carl Nielsen, but other people and role semantics are material catalogue data. |
| People in deeper work structures | 5,006 performer, 1,754 conductor, 52 singer, 12 instrumentalist, 5 director, and 2 arranger name occurrences, in addition to contributor roles | These are name occurrences, not distinct people. They show that performance and expression responsibility cannot be represented as one composer string. |
| Direct creation dates | 439 files have a direct work creation date; 7 do not. Overlapping file classifications: 380 contain at least one partial year or year-month value in a date attribute, 153 are bounded/ranged, 136 have uncertainty markers, and 58 contain an exact-day value. Attribute occurrences: `isodate` 286, `notbefore` 130, `notafter` 131, `startdate` 23, `enddate` 21 | A single year cannot preserve bounds, precision, or uncertainty. Missing dates are genuine evaluation cases. |
| Expressions/components | 602 top-level expressions; 93 files have multiple top-level expressions. There are 128 `<componentList>` nodes document-wide; 126 are work descendants in 70 files and contain 593 direct component expressions, including nested lists. No `<mdiv>`, `<movement>`, or `<section>` elements occur | Movement-like and version structure is carried by expression/component hierarchies rather than the current importer's movement selectors. |
| Component detail | Among the 593 direct component expressions, 456 have `n`, 802 titles occur beneath them, 548 have tempo, 549 meter, and all 593 have `perfMedium` | Component order, multilingual titles, musical attributes, and nested structure should be evaluated together. |
| Instrumentation/performance medium | 1,195 `perfMedium` nodes in all 446 files; 1,994 `perfRes` nodes in 407 files. Of the resources, 1,984 have `codedval`, 1,948 `count`, and 1,555 `solo`; 39 files have no `perfRes` | The current flat name model can capture some labels but not hierarchy, codes, counts, solo status, or expression context. |
| Sources/manuscripts | 2,148 `<manifestation>` records in 442 files; 4 files have none. There are 2,105 manifestation titles and 1,370 manifestation-held `<item>` nodes in 392 files, with repository structures. The corpus contains 12,219 `<bibl>` nodes in 310 files. It contains zero `<sourceDesc>/<source>` structures | Authoritative source evidence is represented as sibling manifestation/item hierarchies, not as the current importer's expected source nodes. |
| Performance events | 477 `eventList` nodes in 386 files; every list is `type="performances"`. They contain 4,840 untyped `<event>` nodes; 60 files have none. Observed event detail includes 4,647 direct dates, 4,603 venue names, 4,640 place names, 6,862 person names, and 1,679 corporate/ensemble names | The list carries the performance type; requiring `@type` on each event misses all observed events. Venue/place and person/ensemble roles are distinct. |
| Link and relation targets | Work subtrees contain 4,123 `target` values: 459 absolute HTTP(S) URLs and 3,664 relative or identifier-like targets. The current relation/ref/ptr selector would see 2,069 targets, of which only 459 are HTTP(S); the other 1,610 are internal, root-relative, or query-style. The remaining 2,054 targets belong to graphics | “Has a target” is not equivalent to “external URL.” Semantic work relations, catalogue UI links, authority URIs, and graphics need separate treatment. |
| Work-level absolute URLs | 308 files have at least one; 84 have more than one; 138 have none. Absolute targets occur on 416 relations, 42 pointers, and 1 reference | Counts do not establish that a URL resolves or is an authoritative linkage. |
| Other reference structures | 212 `<ref>` targets occur in 136 files, mostly `document.xq?doc=…xml`; 914 relations in 274 files target XML records. Across the full document set, 944 HTTP(S) pointer targets occur, including a common Royal Danish Library pointer, and 5,372 `auth.uri` values point to RISM URL variants | External-link evaluation must define which categories are in scope and exclude boilerplate or internal navigation from any quality rate. |
| Missing optional structures | 7 files lack a direct creation date; 39 lack `perfRes`; 4 lack manifestations; 60 lack performance events; 138 lack a work-level absolute URL. No file lacks a direct CNW identifier or direct work title | Missingness is structured and useful for a deliberate negative-case sample; it should not automatically be treated as defective data. |

### 3.4 Static comparison with the current importer

No import was run. The outcomes below are static predictions from `app/services/mei/importer.rb` at the baseline commit compared with the observed XML structures.

| Current importer behaviour | Corpus observation | Predicted consequence |
|---|---|---|
| Discovers lowercase `.xml` and `.mei` recursively | All 446 catalogue files use lowercase `.xml` | File discovery is compatible with this release. |
| Searches `<composer>` elements, then falls back to the first `respStmt/persName` | The corpus has zero `<composer>` elements; composer is `work/contributor/persName[@role='composer']`. In every file the fallback person is header editor Niels Bo Foltmann, while every direct work composer is Carl Nielsen | Deterministic composer misattribution for all 446 records if imported unchanged. Other contributor roles are omitted. |
| Selects one title, preferring `main`, then `uniform`, then the first title | There are no direct `main` titles, but 445 files have multiple language-tagged titles and 101 have a uniform title | Alternate, language, subordinate, and text-source title semantics are lost; a uniform title can displace the first title. |
| Uses the first identifier as `catalogue_number` | Direct identifier order varies; in 70 files Opus is first. Five files repeat one value under different labels | Some works would receive an Opus value instead of CNW. Static schema comparison predicts uniqueness failures for `cnw0027.xml`, `cnw0064.xml`, `cnw0070.xml`, `cnw0081.xml`, and `cnw0237.xml`. |
| Selects the first descendant creation date and stores text plus one year | Seven works lack a direct date. Of those, only `cnw0067.xml` has a descendant expression-creation date that this selector would match; the other six have no matching descendant creation date. Bounded and ranged encodings are common | For `cnw0067.xml`, the nested expression date can be mistaken for composition; the other six remain undated. Range, precision, and uncertainty semantics are flattened. |
| Looks for `contents/mdiv` or `<movement>` | Neither structure occurs; components are nested expressions in `componentList` | Zero Movement rows would be created, including for all 70 component-bearing files. |
| Flattens every `perfRes`, deduplicating by lowercased name | Resources carry codes, counts, solo status, nested groups, and expression context | Some labels import, but hierarchy and qualifiers are lost; equal labels from distinct contexts can collapse. |
| Looks for `sourceDesc/source` or work-level `sourceList/source` | Both selectors match zero; sources are sibling `manifestationList/manifestation` structures | Every record would report no source references and omit the complete source/manuscript hierarchy. |
| Requires `@type` on each event or a `<performance>` element | All 4,840 events are untyped children of `eventList type="performances"` | Zero Performance rows would be created. Venue/place and participant roles would also need a richer mapping. |
| Treats every relation/ref/ptr with `target` as an external reference | Only 459 of the 2,069 selected targets are HTTP(S) | At least 1,610 internal or query-style targets are liable to semantic misclassification; relation labels and cross-record graph meaning are not preserved. |
| Searches descendant genre before falling back to work classification | Bibliographic genres appear deeply in 310 files | A bibliography genre such as `letter` or `article` can be selected instead of the work's classification. |
| Removes namespaces before using namespace-free XPath | All records share one MEI URI; one also uses an explicit prefix for the same URI | Current parsing will usually find local names, but namespace identity is discarded and no schema compatibility is established. |

## 4. Candidate maximum-variation sample

This is a purposive evaluation design, not a statistically representative sample. Counts describe the observed record and do not imply that its catalogue interpretation has been independently verified.

| Archive-relative path | Source identifier and title | Size | Observed structural characteristics | Selection reason | Expected incompatibilities/risks |
|---|---|---:|---|---|---|
| `dcm-catalogue-data/cnw/data-cnw/712a43e2-d3d6-463a-88fa-0b7e88e4dbf8.xml` | CNW 417 — *Duet* | 11,464 bytes | One work; exact date `1889-02-04`; four Danish/English untyped and subordinate titles; one expression; two `perfRes`; no manifestation, performance event, or work URL | Relatively simple positive/negative boundary case and near-minimum file size | Composer fallback is wrong; only one title survives; no source/performance is expected; subordinate and language semantics are lost |
| `dcm-catalogue-data/cnw/data-cnw/1292525519.xml` | CNW 53 — *Trauermarsch* | 16,623 bytes | Numeric filename; four Danish/English untyped and subordinate titles; no direct creation date; one manifestation/item; two resource lists but zero `perfRes`; no events or work URL | Missing optional data and non-CNW filename form | Missing-date and instrumentation warnings; manifestation ignored; internal targets risk external-reference classification |
| `dcm-catalogue-data/cnw/data-cnw/cnw0277.xml` | CNW 277 — *Serenade* | 23,641 bytes | Five Danish/English titles including alternative and uniform forms; composer, author, and translator; bounded/uncertain 1886–1888 date; two manifestations; one event; one absolute work URL | Alternate-title, language, responsibility, date, and light source/event variation in one compact record | Uniform title can displace the first untyped title; translator/author roles are lost; composer is misattributed; date bounds, source, and event semantics are flattened or omitted |
| `dcm-catalogue-data/cnw/data-cnw/03f4c141-9dab-46d7-b8c1-9d0000cc997a.xml` | CNW Coll. 18 — *Bidrag til “Folkehøjskolens Melodibog” (ca. 1923)* | 29,171 bytes | UUID filename; bounded 1921–1923 date; one manifestation; 40 relations including 38 `hasPart`; no performance events or absolute work URL | Cross-file collection/part graph, the corpus's practical alternative to a multi-work file | Part links are liable to become generic external references; collection graph is not modelled; resource/event absence must not be treated as a parse failure |
| `dcm-catalogue-data/cnw/data-cnw/cnw0063.xml` | CNW 63 — *Sonate nr. 1 for violin og klaver, opus 9* | 171,164 bytes | One `componentList`; four expression nodes; six manifestations and seven items; the corpus's only `handList`; 38 performance events; composer and dedicatee | Movement-like component hierarchy plus distinctive manuscript/source evidence | Components produce no movements; manifestations and events are omitted; person/source roles and repository hierarchy are flattened |
| `dcm-catalogue-data/cnw/data-cnw/cnw0017.xml` | CNW 17 — *Musik til Adam Oehlenschlägers skuespil “Aladdin eller Den forunderlige Lampe”, opus 34* | 583,753 bytes | 11 component lists; 57 expressions; 62 `perfRes`; 14 cast lists; 15 manifestations, 13 items, and 211 events; 92 relative/identifier targets and no absolute work URL | Highest expression and instrumentation counts; dense components, cast, sources, and performances | Zero movements; instrumentation contexts collapse; sources/events are omitted; internal relations can be mislabelled as external references |
| `dcm-catalogue-data/cnw/data-cnw/cnw0002.xml` | CNW 2 — *Maskarade* | 1,539,005 bytes | Largest file; 16,825 elements; 54 expressions; 50 `perfRes`; 39 manifestations, 38 items, and 602 events; 106 work targets but only one absolute URL | Unusually large and structurally complex record; maximum event and source volume | High-volume stress case; composer is wrong; components, sources, and performances are omitted; internal relation targets and role-rich participants are flattened |
| `dcm-catalogue-data/cnw/data-cnw/cnw0018.xml` | CNW 18 — *Musik til Helge Rodes skuespil “Moderen”, opus 41* | 329,160 bytes | Bounded/uncertain 1920–1921 date; 49 expressions; 31 `perfRes`; 33 manifestations, 27 items, and 92 events; 117 work targets including the corpus maximum of nine absolute URLs; arranger roles occur in deeper structures | Multiple absolute references together with complex components, sources, performances, and responsibilities | URL and internal-target categories are conflated; arranger and event roles are lost; movement/source/performance structures are omitted; date uncertainty is flattened |

**Evidence note — official records and prototype fixtures.** The official archive identifies `cnw0002.xml` as CNW 2, *Maskarade*, and `cnw0018.xml` as CNW 18, *Moderen*. The existing prototype fixtures associate CNW 2 with *Fynsk Foraar* and CNW 18 with *Maskarade*. This directly observed discrepancy supports their existing classification as purpose-built, non-authoritative prototype fixtures: they must not be used as catalogue ground truth or matched to official records by local filenames alone. No additional catalogue discrepancy is inferred here.

No candidate for “multiple works in one file” is proposed because none exists in the 446-file corpus. The collection record is included instead to exercise the observed cross-file part graph without pretending it is a multi-work file.

## 5. Recommended final sample size and rationale

Retain all **eight** candidates as the primary purposive sample, but split review depth into two tiers:

| Evaluation tier | Records | Predeclared review depth |
|---|---|---|
| Detailed fidelity | CNW 417, CNW 277, CNW 63, and CNW 18 | Exactly 12 source-located assertions per record, forming a bounded field-level oracle across selected work-level fields, counts, and representative nested values |
| Boundary/stress | CNW 53, CNW Coll. 18, CNW 17, and CNW 2 | Predeclared import outcomes, aggregate counts, structural presence/absence checks, and selected representative assertions tied to each record's selection purpose |

The tier changes review depth, not sample membership. The detailed oracle is not an exhaustive catalogue transcription: it must not manually transcribe every nested event, item, contributor, or target. Boundary/stress review is likewise non-exhaustive and must not become an unbounded field-by-field transcription.

This design retains the simple, missing-data, multilingual/responsibility, collection-graph, manuscript, dense-component, largest-record, and link-category cases as distinct concerns. It maximizes structural contrast; it provides no prevalence estimate and should never be described as statistically representative of the catalogue.

The eight-record sample does not cover every static selector edge case. Focused characterization outside the sample should cover the predicted identifier-uniqueness cases (`cnw0027.xml`, `cnw0064.xml`, `cnw0070.xml`, `cnw0081.xml`, and `cnw0237.xml`), the nested-date case (`cnw0067.xml`), and the explicit-prefix case (`cnw0010.xml`). These are targeted checks, not additions to the recommended purposive sample unless Phase 2B explicitly broadens its scope.

## 6. Known limitations of the profiling method

- XML well-formedness and an MEI version declaration were checked, but the records were not validated against an MEI 4.0.1 schema, project customization, or catalogue-specific rules.
- Element/tag/attribute counts are mechanical. They do not establish whether a date, title, contributor, source, performance, or relation is catalogued correctly.
- Date categories are syntax-based and overlapping. Textual phrases in multiple languages were not exhaustively interpreted.
- URLs, authority identifiers, and cross-record targets were classified by syntax only. No target was dereferenced; availability, identity match, persistence, and authoritative linkage remain untested.
- `persName` counts are occurrences, not entity-resolved people. Repeated people across performances and files are not deduplicated.
- Component expressions were identified structurally. Calling an expression a movement, version, arrangement, act, scene, or other scholarly unit requires a mapping decision and, where necessary, domain review.
- Source/manuscript depth was approximated through manifestation, item, physical-description, repository, and hand-list structures. Their scholarly hierarchy was not independently adjudicated.
- Only the Carl Nielsen XML subtree was profiled. PNG incipits, the other composers, and archive metadata files were inventoried but not analysed for content.
- Static importer outcomes were not confirmed by executing an import. They identify high-confidence selector/schema mismatches and likely transaction failures, not measured runtime results.
- The eight proposed cases are purposefully selected extremes and negative cases, not a random or representative sample.

## 7. Unresolved questions and acquisition problems

There is no current acquisition blocker: the official archive downloaded successfully, its ZIP integrity passed, and its local MD5 matched the official LOAR bitstream metadata.

Questions that remain open are:

1. Does the LOAR item `lastModified` timestamp reflect a metadata-only update or a change to the deposited archive? The bitstream API provides no independent modification timestamp.
2. Which project-specific MEI customization or validation schema, if any, was used for this release beyond the root `meiversion="4.0.1"` declaration?
3. Which expression/component structures should become movements, versions, arrangements, acts, scenes, or another model, and which should remain nested?
4. What is the intended application-level unit for `Coll.` records and their `hasPart`/`isPartOf` graph?
5. Which relation, reference, pointer, graphic, and authority-URI categories should be exposed as user-facing external links, and what authority/link-validation rubric should apply?
6. Which catalogue identifier should be the display/lookup default when CNW, CNU, CNS, FS, and Opus values coexist, and how should identical values under different identifier types be constrained?
7. What bounded protocol and qualified reviewer are available to validate transformed meaning against the catalogue or source documentation?

The archive's `__MACOSX` and `.DS_Store` debris is a packaging-quality issue but did not prevent safe extraction of the minimum XML subtree.

## 8. Proposed next evaluation step

Phase 2B should follow the separate predeclared evaluation protocol before any importer correction:

1. Freeze the archive checksum, the 15-row sample/probe manifest, predictions, assertion rubric, and source locators before execution.
2. In Stage A, run the unchanged Phase 1 importer over all 446 official XML files in a disposable database and preserve technical completion, warning, failure, timing, and aggregate database evidence before any code change.
3. In Stage B, evaluate all eight primary records. Apply the bounded 12-assertion field-level oracle to CNW 417, CNW 277, CNW 63, and CNW 18, covering selected identifiers, titles/languages, contributors, dates, components, instrumentation, manifestations/items, performances, and link categories. Apply predeclared outcomes, aggregate counts, presence/absence checks, and selected representative assertions to CNW 53, CNW Coll. 18, CNW 17, and CNW 2.
4. Resolve the mapping basis for components, collections, sources, and link categories with documentary or domain evidence, without expanding either tier into exhaustive transcription.
5. In Stage C, record predicted and observed outcomes separately for the five identifier-uniqueness files, `cnw0067.xml`, and `cnw0010.xml`.
6. Compare every primary record against its applicable detailed oracle or boundary/stress checklist using the shared classification rubric. Mark fields outside the predeclared checks as not evaluated, and treat XML parsing/import completion separately from semantic fidelity.
7. In Stage D, characterize API responses against the authoritative-data database state while separating HTTP success, data fidelity, and later usability evidence.
8. Validate selected external targets only in a separate, rate-limited link-quality check; do not infer authority from URL presence.

The first implementation priorities suggested by the reconnaissance are composer selection, identifier precedence/uniqueness, direct creation-date handling, component expressions, manifestation sources, performance event lists, and strict separation of semantic/internal targets from external URLs. No such implementation change is made in Phase 2A.
