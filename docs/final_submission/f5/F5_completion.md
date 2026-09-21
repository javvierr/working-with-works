# F5 release preparation — PARTIAL

Local release functionality and isolated reproduction passed. F5 remains **PARTIAL**, with 12 preparatory gates passing and **P5-01 failing** because an independent check supplied directories to a recursive text search. It may have opened excluded credential files. No secret values appeared in output, no secret fingerprints were made, and no excluded files were copied or changed. The incident is retained at `preservation/read_scope_incident.json`; this cannot be undone or relabelled a clean read-scope pass.

The actual starting 968 safe paths matched accepted F4 bytes/modes. HEAD/main is `b0142488fd5609e86d93c84978134a7d849d1882`. Exact final byte/Git comparisons are in `preservation/final/`, separate from the read-scope failure. Accepted unstaged/untracked F1–F4 work is included. Codex internal checkpoint refs are reported separately from user refs/index.

Final runtime candidate **f5-e152006d650d0a93** contains 158 files. Four of the old 154 files changed: README.md, bin/setup, bin/ci and config/ci.rb. The other 150—including evaluated application, importer, views, schema, migrations, dependencies and samples—match F4. Four new helper/test files make setup finite and CI explicitly test-targeted. Nine new F5 documents and preserved public evidence form a 255-path local release proposal. F4 retains its original build `f3-1602645a261ed754`.

Actual final direct tests, local CI tests and second-copy tests each passed **164 tests /2,586 assertions**, with no failures/errors/skips. CI also passed **15 focused tests /297 assertions**. Demo imports reported4/4successes, repeated imports preserved domain facts, and separate pinned official import reported6/6successes. Final official smoke passed14API and3HTML requests; actual bin/dev loopback smoke passed5API and5HTML requests. These are technical observations, not participant benefit or a fresh visual/zoom audit.

New PostgreSQL 14.23 instance `/private/tmp/www_f5_pg_gvjk81ac/data`, private socket `/private/tmp/www_f5_pg_gvjk81ac/socket`, port 55441, PID 3968 was stopped at 2026-09-21T15:13:37Z. Its data, failed initial data directory and all evidence remain. Both owned app processes stopped, their ports closed and no browser tabs were created. See `evidence/resource_shutdown.json`.

The review ZIP includes exact F5-only patch/preimages and selected expectations/observations. Full snapshots, official XML/archive, dependencies, secrets/private files and .git are excluded. Producer and independent archive validations are adjacent. Archive-integrity PASS does not remove the P5-01 failure.

**PUBLIC_RELEASE=PENDING_USER_COMMIT_AND_PUBLICATION. PUBLIC_FRESH_CLONE=NOT_RUN.** Nothing staged, committed, pushed, published or submitted. Follow-up participant evaluation remains **NOT_EVALUATED_BY_USER_DECISION**. Stop for review; later publication/public-clone work requires a separate invocation.
