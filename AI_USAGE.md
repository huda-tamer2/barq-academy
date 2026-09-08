# AI usage disclosure

AI assistance was used during the assessment. The AI was used as an
engineering support tool, not as a substitute for testing or understanding
the implementation.

## Use 1 — DevOps architecture and implementation planning

* **Tool/model:** ChatGPT
* **Purpose:** Explain Docker, Docker Compose, NGINX reverse proxying,
  PostgreSQL, Redis, health/readiness checks, networking, persistence,
  failover, backup/restore, and the assessment requirements in simpler terms.
* **Files or decisions affected:** `Dockerfile`, `docker-compose.yml`,
  `nginx/nginx.conf`, `app/server.py`, validation/failure-test approach,
  persistence design, and documentation structure.
* **What you changed or rejected:** Suggestions were reviewed against the
  actual assessment requirements and existing repository. The implementation
  was adapted rather than copied blindly. In particular, service names,
  internal backend networking, host-port restrictions, health/readiness
  behavior, persistence, and resource settings were checked against the
  running environment.
* **How you independently verified it:** Docker Compose configuration,
  container health, endpoint responses, network inspection, persistence tests,
  and failure/recovery tests were executed in the Ubuntu VM.
* **Related commit:** Multiple implementation commits, including
  `2809883`, `2029857`, `796514e`, and `04b95ad`.

## Use 2 — Troubleshooting and root-cause analysis

* **Tool/model:** ChatGPT
* **Purpose:** Help interpret observed Docker, NGINX, PostgreSQL, Redis, and
  application behavior and organize hypotheses, tests, and conclusions.
* **Files or decisions affected:** `troubleshooting.md`, `nginx/nginx.conf`,
  `docker-compose.yml`, `app/server.py`, and operational test procedures.
* **What you changed or rejected:** Proposed explanations were treated as
  hypotheses. Commands were run against the actual containers before accepting
  a root cause. For example, application readiness failure was traced to the
  missing `DATABASE_URL`; the NGINX failover issue was investigated using
  container/network/DNS evidence before changing the configuration.
* **How you independently verified it:** Reproduced failures, inspected
  container health and Docker networks, tested DNS/service connectivity,
  reloaded NGINX, repeated HTTP requests, and verified recovery.
* **Related commit:** `2809883` and `796514e`.

## Use 3 — Log analysis assistance

* **Tool/model:** ChatGPT
* **Purpose:** Help structure analysis of the supplied access, error, and
  application logs, including deduplication, status counts, latency
  calculations, incident correlation, and timeline construction.
* **Files or decisions affected:** `log_analysis.md`.
* **What you changed or rejected:** The report was based on commands and actual
  log contents. Duplicate request IDs, malformed records, status counts,
  retry patterns, dependency errors, latency statistics, and incident
  timelines were checked against the supplied files.
* **How you independently verified it:** Bash/Python log-processing commands
  were used to count valid/malformed/duplicate records, calculate status
  counts and latency statistics, and correlate request IDs across logs.
* **Related commit:** `7183645 Document correlated log analysis`.

## Use 4 — Validation and failure-test design

* **Tool/model:** ChatGPT
* **Purpose:** Help design bounded validation and backend failure/recovery
  tests that produce explicit PASS/FAIL results and nonzero exits on failure.
* **Files or decisions affected:** `validate.py` and `failure_test.py`.
* **What you changed or rejected:** The scripts were adapted to the actual
  Compose topology and assessment requirements. False checks and assumptions
  were corrected after running the scripts against the real environment.
* **How you independently verified it:** `./validate.py` completed with
  `=== VALIDATION PASSED ===`, and `./failure_test.py` completed with
  `=== FAILURE/RECOVERY TEST PASSED ===`.
* **Related commit:** `5ea6189 Implement environment validation` and
  `d906c2b Implement backend failure recovery test`.

## Use 5 — Backup/restore and persistence documentation

* **Tool/model:** ChatGPT
* **Purpose:** Help structure reproducible PostgreSQL backup/restore and
  container-recreation persistence procedures.
* **Files or decisions affected:** `backup.sh`, `restore.sh`, `README.md`,
  `troubleshooting.md`, and persistence documentation.
* **What you changed or rejected:** Scripts were kept intentionally
  conservative. `restore.sh` does not automatically destroy an existing
  database. The destructive database recreation used for the controlled
  restore test was performed explicitly and separately.
* **How you independently verified it:** A PostgreSQL backup was generated,
  a restore was performed into a controlled database state, and application
  records were checked before and after container recreation.
* **Related commit:** `f88b64a Implement PostgreSQL backup script` and
  `c5cac8d Implement PostgreSQL restore script`.

## Verification principle

AI-generated explanations or suggestions were not treated as proof. Claims
included in the repository were accepted only after being checked against the
actual code, Docker configuration, command output, logs, tests, or observed
runtime behavior.

The final video challenge is intentionally not documented here as completed
evidence until it is executed and recorded in the required continuous video.
