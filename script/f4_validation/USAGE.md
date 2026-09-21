# F4 validation tools

These maintained, standard-library Python tools independently compare the frozen source expectations with retained SQL/API observations. They do not connect to PostgreSQL, start a service, modify the application or invoke application mapping/filter/serializer code.

Run `python3 script/f4_validation/run_offline.py --run /absolute/path/to/retained/F4/run --out /private/tmp/new_unique_review_directory` from any directory. The input run must contain the exact frozen F4 artifact layout, the retained local SQL snapshots and captured API values; the review ZIP deliberately excludes whole database snapshots. The output must be new, external, and absent. The runner verifies the master freeze before executing the five named independent comparisons. This is an evidence replay, not a new import or public-clone release check.

Individual tools accept explicit paths; use `--help`. The source reader requires the supplied package, pinned existing source directory and inspected prior context. It is provided for methodological review, not authorization for a new corpus/participant study. `f4_corpus_table.py` constructs the446row current report from the three independently recorded import rounds.

The exact guarded runtime execution programs, their failed attempts/adaptation diffs, target/build identities and command records are retained in the F4 review evidence. They are pinned to this completed, now-stopped instance. Do not restart retained databases or blindly replay those service scripts. New database execution requires a new scoped authorization/target review. Installed dependencies were reused; setup/CI/readme/public-clone changes remain F5.

No result from these tools establishes overall catalogue accuracy, user benefit, security certification or release readiness. Follow-up participant evaluation is NOT_EVALUATED_BY_USER_DECISION.
