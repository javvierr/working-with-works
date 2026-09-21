# F3-Z1 completion — zoom component passed, for review

The missing actual **200% Chrome page-zoom check passed** on the unchanged final F3 build. This addendum proposes closure of the outstanding component of V3-01 for review. It does not rewrite F3's historical PARTIAL documents, approve a release, or start F4.

Chrome's initial menu exposed zoom controls but omitted its percentage from accessibility text, and native-window screenshot capture was unavailable. The authorized fallback was requested once on the exact owned page. The user reported “was 100, is 200”. That report is separate from the agent's subsequent direct observation: Chrome's toolbar displayed **“Zoom: 200%”** before the workflow; its toolbar and zoom dialog directly displayed **200%** again afterward. The owned origin was reset, and the native dialog directly showed **“Zoom: 100%”**. The owned tab was then closed.

The normal desktop page viewport measured 1713×940 CSS pixels before/after and 856×470 at 200%; these measurements corroborate layout rather than prove zoom. No viewport override, CSS zoom, transform or device scaling was used. Browser version and outer-window dimensions were not exposed by the permitted observations and are not invented.

## Observed at 200%

- Labels, guidance and reachable form controls; invalid year `19x` returned readable feedback and retained the safe value. Keyboard Clear recovered to all 51 works.
- Filtered pages showed 1–2 and 3–3 of three same-title results. Next and Previous worked by keyboard, retained search/year/page-size filters and displayed a 3px blue focus outline. CNW 446, CNW 447 and FS: 448 remained distinguishable; raw known/unknown instrument wording remained visible.
- CNW 17's native source disclosure and relationship provenance opened with Space. Long locators/JSON wrapped, parent source/item identities remained readable, and normal scrolling reached lower item/repository content.
- The synthetic partial fixture retained its unsupported missing-ID warning, distinct from Coll. 27's genuine “No held-item nodes are supplied for this description.”

No essential content/control clipping, overlap or horizontal scrolling was observed. Narrow year/genre cells wrapped some digits/words across lines; that observed presentation limit is retained. Vertical scrolling was necessary and usable. These are development observations, not participant evidence or accessibility certification.

## Identity, runtime and preservation

The actual repository is `/Users/javier/Documents/academia/uol/final project/prototype/UoL final project`. All 154 copied application files, including CSS, match final F3 build `f3-1602645a261ed754`; stylesheet SHA-256 is `a916844a63292a805345b120fee35812ba54f1c31192fd1c75f0e9f797b20207`. The fresh 941-path baseline matches accepted F3 evidence. HEAD/main remain `b0142488fd5609e86d93c84978134a7d849d1882`, with index/staging preserved. Only these four new F3-Z1 documents are added; the application patch is empty.

The minimal dataset used 48 frozen synthetic works, CNW 17, Coll. 27 and the supplied missing-ID synthetic XML: 51 works, 17 source descriptions, 13 held items and 15 relations. Three pinned XML imports succeeded. No reserved records/full-corpus import or accepted full-suite/API/source experiment was repeated.

There were 11 actual GET requests: nine application requests plus CSS/favicon; ten returned 200 and the invalid-year request returned 400 with zero SQL. All 15 domain tables, 15 sequences and structural schema remained identical. The new local app process PID 43961/port 52601 stopped at `2026-09-21T00:06:36.958451+00:00`. The only started new PostgreSQL instance, PID 43157, private socket `/private/tmp/www_f3z1_pg_l74dwx6z/socket`, port 55436, database `www_f3z1_browser_g6jtiei7`, stopped at `2026-09-21T00:06:48.500079+00:00`. Its data remain retained under `/private/tmp/www_f3z1_pg_l74dwx6z/data`.

## Evidence limits and handoff

Fifteen real page captures were inspected inline; zero image files were exported. Native Chrome capture failed, but the exact Chrome zoom accessibility labels were directly observed. Structured observations and a capture register are supplied; no image pixels or screenshot files are falsely claimed in the ZIP. Two immediately sampled tab URLs lagged navigation; their raw samples, live DOM results and fresh AX/server corroboration are retained.

The first new PostgreSQL initialization was sandbox-denied before a server or application data existed. `initdb` automatically removed its partial initialization contents; the failed root/directories and logs remain. A second new root used `--no-clean` through the supported permission process. A separate denied socket diagnostic and its scoped permission follow-up are retained. No agent cleanup, old-instance restart, software installation or existing database/role operation occurred.

Initial native Chrome selection automatically exposed an unrelated foreground page because the owned tab had opened in the background. No personal page was operated or screenshot, and none of its content was copied into retained evidence. The owned tab was isolated in a new window before testing. Browser restoration claims concern only the owned origin/tab, not a complete personal-browser audit.

Review archive: `$F3Z1_RUN/Working_with_Works_F3Z1_Review.zip`, with adjacent validation. It contains these addenda, the docs-only patch, empty application patch, build/input/target evidence, actual observations/requests, retained attempts, unchanged state comparisons and confirmed shutdown/restoration. Final safe preservation and archive integrity are recorded separately. Stop before F4; nothing staged, committed or pushed.
