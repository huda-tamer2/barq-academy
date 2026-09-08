# Evidence and submission index

This index maps assessment requirements to repository evidence, implementation
commits, and the final video demonstration.

The final submission fields that depend on the recorded challenge are left
pending until the challenge is performed in the final video working copy.

## Submission information

* **Repository URL:** PENDING — fill with final repository URL before submission.
* **Final commit:** PENDING — final commit after the 8090/three-instance video work.
* **Matching CI run:** PENDING — record the successful CI workflow run matching
  the final commit.
* **Continuous 12-18 minute video URL:** PENDING — record the final continuous
  video URL.
* **Challenge receipt ID:** PENDING — record the receipt produced by the first
  `./video_challenge.sh` execution during the final video.
* **Starting video commit:** PENDING — record the commit/working state used at
  the beginning of the final video.
* **Later documentation-only commits, if any:** PENDING — record any commits
  made after the video that only correct documentation/evidence.

## Requirement evidence

### Git history and progressive commits

* **Requirement:** Preserve the baseline and make meaningful progressive
  commits.
* **Evidence:** `git log --oneline --decorate --all`
* **Relevant commits:** The implementation history from the starter release
  through the current `main` branch, including:

  * `69cfc02 Initial commit`
  * `ca25803 Fix application healthcheck endpoint`
  * `52e3114 Fix application and nginx connectivity`
  * `403d0f2 Fix internal database and redis ports`
  * `791069c Remove secrets from image and compose configuration`
  * `6738918 Persist PostgreSQL data in named volume`
  * `c6fc487 Enable Redis AOF persistence`
  * `04b95ad Persist Redis AOF in named volume`
  * `796514e Improve NGINX upstream failover`
  * `2809883 Configure app resources and backend URLs`
  * `2029857 Harden service dependencies and network isolation`
  * `f88b64a Implement PostgreSQL backup script`
  * `c5cac8d Implement PostgreSQL restore script`
  * `5ea6189 Implement environment validation`
  * `d906c2b Implement backend failure recovery test`
  * `7183645 Document correlated log analysis`
* **Video timestamp:** PENDING.

### Docker and Compose architecture

* **Requirement:** Two Flask instances behind NGINX with PostgreSQL and
  Redis, with only NGINX publicly exposed.
* **Evidence:** `Dockerfile`, `docker-compose.yml`, `nginx/nginx.conf`,
  `app/server.py`
* **Relevant commits:** `f76b6e7`, `2809883`, `2029857`
* **Verification:** `./validate.py`
* **Video timestamp:** PENDING.

### Required HTTP endpoints

* **Requirement:** `/`, `/health`, `/ready`, `/instance`, `/records`,
  `/counter`.
* **Evidence:** `app/server.py`
* **Verification:** `./validate.py`
* **Relevant commit:** `5ea6189`
* **Video timestamp:** PENDING.

### Distinct application identities and load balancing

* **Requirement:** Multiple application instances must be distinguishable and
  traffic must reach both.
* **Evidence:** `INSTANCE_ID` configuration in `docker-compose.yml`,
  `/instance` endpoint in `app/server.py`, NGINX upstream configuration.
* **Verification:** `./validate.py` and repeated `/instance` requests.
* **Relevant commits:** `796514e`, `5ea6189`
* **Video timestamp:** PENDING.

### Health and readiness

* **Requirement:** Services must expose meaningful health/readiness behavior.
* **Evidence:** `app/server.py`, Compose healthchecks, `validate.py`.
* **Verification:** `./validate.py`
* **Relevant commit:** `5ea6189`
* **Video timestamp:** PENDING.

### Network isolation

* **Requirement:** NGINX must not directly access PostgreSQL or Redis;
  backend network must be internal.
* **Evidence:** `docker-compose.yml`
* **Verification:** Docker network inspection and `./validate.py`
* **Relevant commit:** `2029857`
* **Video timestamp:** PENDING.

### Resource limits and restart policies

* **Requirement:** Appropriate resource limits and restart behavior.
* **Evidence:** `docker-compose.yml`
* **Relevant commits:** `3cff720`, `2809883`
* **Video timestamp:** PENDING.

### PostgreSQL persistence

* **Requirement:** PostgreSQL records must survive container recreation.
* **Evidence:** named `postgres-data` volume in `docker-compose.yml`.
* **Verification:** Record creation, PostgreSQL container removal/recreation,
  and subsequent `/records` check.
* **Relevant commit:** `6738918`
* **Video timestamp:** PENDING.

### Redis persistence

* **Requirement:** Redis persistence must survive Redis container recreation.
* **Evidence:** Redis AOF configuration and named `redis-data` volume.
* **Verification:** Counter value was checked before and after Redis container
  recreation using the persistent volume.
* **Relevant commits:** `c6fc487`, `04b95ad`
* **Video timestamp:** PENDING.

### PostgreSQL backup

* **Requirement:** Provide a reproducible PostgreSQL backup procedure.
* **Evidence:** `backup.sh`
* **Verification:** `./backup.sh` successfully generated a SQL backup.
* **Relevant commit:** `f88b64a`
* **Video timestamp:** PENDING.

### PostgreSQL restore

* **Requirement:** Demonstrate that a PostgreSQL backup can restore data.
* **Evidence:** `restore.sh`, backup SQL file kept locally under ignored
  `backups/`.
* **Verification:** Controlled database recreation followed by SQL restore and
  `/records` verification.
* **Relevant commit:** `c5cac8d`
* **Video timestamp:** PENDING.

### Backend failure and recovery

* **Requirement:** Stop one backend, demonstrate continued availability,
  restore it, and demonstrate recovery.
* **Evidence:** `failure_test.py`
* **Verification:** Baseline 20/20 success; during app-01 stop 20/20 success
  through app-02; after recovery 20/20 success with both instances receiving
  traffic.
* **Relevant commit:** `d906c2b`
* **Video timestamp:** PENDING.

### Automated environment validation

* **Requirement:** Validation must produce PASS/FAIL results and nonzero exit
  status on failure.
* **Evidence:** `validate.py`
* **Verification:** `./validate.py` completed with
  `=== VALIDATION PASSED ===`.
* **Relevant commit:** `5ea6189`
* **Video timestamp:** PENDING.

### Failure-test automation

* **Requirement:** Automated backend failure/recovery test.
* **Evidence:** `failure_test.py`
* **Verification:** `./failure_test.py` completed with
  `=== FAILURE/RECOVERY TEST PASSED ===`.
* **Relevant commit:** `d906c2b`
* **Video timestamp:** PENDING.

### Historical log analysis

* **Requirement:** Analyze access, error, and application logs and correlate
  incidents without double-counting retries.
* **Evidence:** `log_analysis.md`, `logs/access.log`, `logs/error.log`,
  `logs/application.log`
* **Verification:** Reproducible Bash/Python analysis documented in
  `log_analysis.md`.
* **Relevant commit:** `7183645`
* **Video timestamp:** PENDING.

### Technical decisions

* **Requirement:** At least five documented engineering decisions with
  assumptions, alternatives, trade-offs, limitations, and production
  improvements.
* **Evidence:** `decisions.md`
* **Relevant commits:** Implementation commits referenced inside the document.
* **Video timestamp:** PENDING.

### Security review

* **Requirement:** At least eight concrete security/production-readiness
  findings, including secrets, ports, users, images, networks, persistence,
  backup, logging, and availability.
* **Evidence:** `security_review.md`
* **Relevant commits:** Implementation commits referenced inside the document.
* **Video timestamp:** PENDING.

### AI disclosure

* **Requirement:** Disclose AI use, affected files/decisions, rejected or
  changed suggestions, and independent verification.
* **Evidence:** `AI_USAGE.md`
* **Relevant commits:** Implementation commits referenced inside the document.
* **Video timestamp:** PENDING.

### Architecture diagram

* **Requirement:** Required architecture diagram showing the final
  three-instance system, public port 8090, request flow, ports, networks,
  storage, health/readiness, and remaining single points of failure.
* **Evidence:** `architecture.png` or `architecture.pdf` at repository root.
* **Current status:** NOT YET CREATED.
* **Video timestamp:** PENDING.

## Final video evidence

The final video must demonstrate the final state rather than merely describe
it.

The following items are intentionally pending until the recorded challenge:

1. Show the starting commit and clean Git status.
2. Start the assessment environment and show service health.
3. Demonstrate the required endpoints.
4. Demonstrate distinct application identities.
5. Stop one backend and demonstrate continued availability.
6. Restore the backend and demonstrate recovery.
7. Demonstrate persistence after application/PostgreSQL container recreation.
8. Run validation and failure tests.
9. Run `./video_challenge.sh` for the first time in the video working copy.
10. Diagnose and fix the challenge runtime fault without `docker compose down`.
11. Change the public port from 8080 to 8090 live.
12. Add `app-03` live and demonstrate all three instances.
13. Rerun validation against the final three-instance/8090 setup.
14. Show Git status, diff, and commit hashes.
15. Push the final commits and capture the final CI run.

## Final consistency check

Before submission, verify that all four representations agree:

* README documentation
* architecture diagram
* GitHub repository code
* final video

The final demonstrated architecture must contain three Flask instances and use
public port `8090`.

No video timestamp, receipt ID, final hash, CI URL, or repository URL should
be fabricated. Populate those fields only from the actual final run and
recording.
