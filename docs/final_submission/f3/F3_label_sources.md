# F3 label sources and limits

Initial implementation status: IMPLEMENTED_AWAITING_VALIDATION, 20 September 2026; superseded by the actual developer-validation entry below. The exact glossary/source decision was prepared before application edits; its immutable prospective copy is retained in the external F3 acceptance evidence. Runtime/interface results remain NOT_RUN until the F3 check records report actual outcomes. The glossary is a bounded explanatory aid; exact stored instrumentation remains the source wording and the instrumentation filter still searches that wording.

## Source authority

The supplied public formative protocol is the authority for this intentionally narrow local convention, not a universal MEI or instrument dictionary:

- `/Users/javier/Documents/Codex/2026-09-19/referenced-chatgpt-conversation-this-is-an/outputs/Working_with_Works_F3_Start/context/phase2_usability_protocol.md`, lines 95–103, especially line 100: the CNW 63 observer key accepts `1 pf.` and `1 vl.` and semantically equivalent spoken expansions “one piano” and “one violin”. Lines 97–99 give the bounded work identity. Line 103 explicitly excludes a scholarly-completeness assessment.
- `/Users/javier/Documents/Codex/2026-09-19/referenced-chatgpt-conversation-this-is-an/outputs/Working_with_Works_F3_Start/context/feedback_to_evidence.md`, lines 24–26: FB06 retains source/item context, FB07 requires separately supported technical evidence, and FB08 identifies instrumentation abbreviations, same-title differentiation and search/filter distinction as interface work requiring build-specific evaluation.
- `/Users/javier/Documents/Codex/2026-09-19/referenced-chatgpt-conversation-this-is-an/outputs/Working_with_Works_F3_Start/context/Working_with_Works_September_19_28_Delivery_Plan.md`, lines 53–57: the API/interface scope includes these issues and preserves source terms alongside verified explanations. Lines 96–104 bound the feature/results freezes; lines 114–126 distinguish technical/developer checks from participant evidence.

No external dictionary was fetched or silently treated as verified. This register does not claim CNW 63 was newly imported or evaluated in F3.

## Exact supported map

| Exact stored string | Visible explanation | Support and boundary |
|---|---|---|
| `1 pf.` | one piano | Supplied public protocol, line 100. Exact whole-string lookup only. |
| `1 vl.` | one violin | Supplied public protocol, line 100. Exact whole-string lookup only. |

No case folding, whitespace normalization, count inference, token splitting, prefix substitution or substring expansion is used to decide whether a stored instrumentation value has an explanation. The filter's own case-insensitive substring behavior is separate from glossary lookup.

## Unsupported patterns and visible fallback

Examples that remain source wording without a guessed explanation: `pf.`, `vl.`, `2 pf.`, `1 PF.`, `1 pf`, `1 pf. `, `1 pf., 1 vl.`, `1 pf. / 1 vl.`, `1 voice`, empty/missing metadata, arbitrary compound abbreviations and other instrument codes. A compound in a single stored string is not split even if its components resemble supported keys. Separate stored rows exactly equal to the supported keys may each receive their own explanation.

For an unrecognized nonempty stored string, display the exact source wording with `Explanation unavailable for this source wording.` Missing instrumentation uses `Not supplied` or the existing `Unknown` state, without inventing a source string or identifying a musical ensemble. Section text, when present, remains separate source context and is not expanded.

## Catalogue cues and search wording

A typed catalogue identifier supplies its own family/type. Prefer an explicit CNW identifier for a CNW document where available; otherwise retain another explicit identifier type. Only the recognized document family `CNW` may prefix its stored number as a document-backed fallback when no typed identifier is available. Explicit typed identifiers take precedence over the document fallback. A bare number on an unrelated/legacy record remains a bare catalogue value; it never acquires CNW by inference. With neither typed identity nor document-backed family, use `Catalogue: <stored value>` or `Catalogue: Unknown`.

Do not change the stored heading or the F1 title policy. Add a visible catalogue cue inside the result link so its accessible name distinguishes equal titles, and show composer/year as available nearby. The detail context repeats the same derived cue.

General search guidance: `Search title variants, composer and catalogue text.` Dedicated catalogue guidance: `CNW 29 matches that typed identifier exactly. A bare fragment, such as 29, matches stored catalogue text. Filters combine.` Instrumentation guidance: `Match source wording, for example 1 pf.; explanations are display aids, not search aliases.` These descriptions must be checked against the shared validated query and current model scopes.

## Provenance wording

Relabel `Source XML` as `Imported file/reference identifier` and retain the value as escaped plain text. Provide in-page links to title variants, work classifications and source descriptions. Existing safe external links remain unchanged. Do not create catalogue URLs, download links or source-file reads on GET. The F2-R1 source partial, ownership wording, represented-item counts, partial/absent/unknown distinctions, inert pointers and keyboard-native disclosures remain authoritative.

## Evaluation limit

Focused unit/integration assertions and a developer browser walkthrough can verify the implemented labels and behavior. They are not participant outcomes, expert endorsement, a universal abbreviation glossary or accessibility certification. F4 participant/full-corpus evidence remains pending.

## Implementation and compatibility note

`app/helpers/works_helper.rb` performs exact whole-string lookup. List/detail views pair each escaped raw value with visible explanation text. The list's former raw-only cell now contains these pairs. The F1 HTML assertion in `test/integration/f1_work_projection_test.rb` was prospectively adapted to compare the ordered `.instrumentation-source` values with its original expected `1 pf.` and `1 voice`; the API assertion and source/order requirement are unchanged. The original file preimage and rationale are retained in F3 evidence. Focused `f3_works_interface_test.rb` cases add supported/unknown/compound/escaping checks. No historical F1 result is changed.

The catalogue cue chooses the first typed CNW identifier, otherwise an explicit typed identifier ordered by type/value/ID; only absent typed identity permits the recognized CNW document fallback. It adds no prefix to unrelated legacy bare values. Display cues do not change catalogue-filter semantics.

The existing F2-R1 `_catalogue_sources.html.erb` and `_source_values.html.erb` are byte-preserved. The imported file/reference label remains escaped text. New inspection navigation links only to existing in-page sections.

## Actual developer validation, 20 September 2026

U3-03 passed the focused integration cases and actual list/detail/narrow browser observations recorded in `validation/browser_observations.json` and the 164-test suite. Exact known strings remain paired with source wording; unknown and compound values retain explanation-unavailable wording. This validates the bounded implementation for these development cases, not participant understanding or a universal dictionary. The separate six-record semantic regression includes CNW 63; this register uses the supplied public protocol as its explanation authority and makes no independent new source-interpretation claim for CNW 63. The original prospective glossary and its limitations remain retained in `acceptance/F3_label_sources.md`. Overall F3 is PARTIAL because actual 200% browser zoom remains unverified.
