# F4 operational results

The five prospectively fixed timing scenarios each completed five warm-up requests followed by thirty measured serial requests on the stable canonical 446-work dataset. All 175 responses were correct under the same independent SQL-derived API comparator. The 150 measured requests have no failures or exclusions. This is a descriptive development-machine measurement with no pass threshold, speedup or production-capacity claim.

## Fixed method and conditions

`acceptance/api_timing_rules_v1.json` freezes the five scenarios, schedule and formulas before canonical import. `validation/api_corpus_01/timing_raw.json` retains every duration, status, correctness result and raw-response reference. `validation/api_corpus_01/result.json` retains the calculated summaries; the separate `validation/api_corpus_independent_audit.json` independently recomputes every summary from the raw measured values.

The application is unchanged accepted build `f3-1602645a261ed754`, 154 files, in the verified external copy. The target is `www_f4_corpus_ose8xy9`, on this run's PostgreSQL 14.23 instance using a private Unix socket and C/C collation; TCP is disabled. Runtime is Ruby 4.0.5, Rails 8.1.3, Rack 3.2.6 and pg 1.6.3. Machine observations identify Darwin 25.6.0 arm64. The optional hardware model/memory/core-count query was denied by the sandbox; the denial is retained in `logs/api_environment_hardware.log` and was not retried through another route. Those hardware details are unavailable in this run.

Transport is an in-process Rack GET through the actual Rails application, followed by response-body consumption. There is no application-server TCP transfer, browser rendering or network latency in the measurements. A monotonic wall clock surrounds request construction, application execution and body consumption, including the live identity guard overhead for each application SQL event. Independent response comparison and evidence-file writing occur outside the timing interval.

Concurrency is one request at a time in one process/worker. The database/app caches were already exercised by the preceding canonical API round; each scenario also has five further warm-ups. No cache flush or cold-start claim is made. Parent-run database mutations completed at 00:56:00 UTC, before this API process began at 00:57:19 UTC. The developer browser session waited until the round ended at 00:57:37 UTC. This removes concurrent F4 import/test workloads from the timing interval; unrelated operating-system load remains uncontrolled. See `validation/api_operational_environment.json` and the sanitized runtime command record.

p50 is the median (mean of the middle pair for n=30). p95 is nearest-rank `ceil(0.95*n)`, the 29th sorted observation for n=30. Range is the actual minimum/maximum. The table rounds seconds to milliseconds for display; raw durations preserve their measured precision. Each n below excludes its five warm-ups solely under the prospective schedule.

| Scenario | Measured n | Correct n | Min ms | p50 ms | p95 ms | Max ms |
|---|---:|---:|---:|---:|---:|---:|
| Unfiltered index, page 1 / size 20 | 30 | 30 | 9.194 | 9.971 | 10.505 | 10.563 |
| Combined title/catalogue/instrumentation/genre/year filters | 30 | 30 | 6.134 | 7.565 | 8.160 | 8.247 |
| Zero-match query | 30 | 30 | 4.603 | 5.147 | 5.896 | 5.936 |
| Small detail: CNW 417 | 30 | 30 | 13.672 | 15.229 | 16.895 | 17.470 |
| Dense detail: CNW 1 | 30 | 30 | 52.610 | 55.250 | 63.480 | 67.607 |

## Limits and evidence separation

The dense record has 32 supplied source descriptions and substantial nested content; its timing is one named purposive request, not a scalability benchmark. These measurements show the observed local cost of the identified requests under the stated warm-cache, serial, guarded conditions. They do not demonstrate acceptable user latency, comparative superiority, production throughput, concurrent stability, an accessibility outcome or expert validation. HTTP/SQL agreement is separately checked and does not replace source fidelity.

The structured developer walkthrough and accepted historical keyboard/layout/actual-200%-zoom evidence are reported in `F4_developer_walkthrough.md` with their own build/date/operator identities. They are not included as latency samples or participant outcomes. The previous public three-person/nine-attempt study remains formative history on its original build. No follow-up sessions were conducted; follow-up participant evaluation is `NOT_EVALUATED_BY_USER_DECISION`, separately from technical completion. Public committed-clone/setup verification remains F5.
