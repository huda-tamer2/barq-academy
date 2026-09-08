# Technical decisions

This document records the main engineering decisions made for the BARQ Systems
DevOps assessment. Each decision includes the assumption, alternatives,
trade-offs, evidence, and a production follow-up.

## Decision 1 — Use a pinned Python slim base image

* **Choice:** Use `python:3.12-slim-bookworm` pinned by image digest.
* **Why:** The slim image reduces unnecessary packages and image size compared
  with a full Python image. Python 3.12 provides a current supported runtime
  for the Flask application. Pinning by digest makes the exact image immutable
  and improves reproducibility.
* **Assumption:** The application and its Python dependencies are compatible
  with Python 3.12 and Debian Bookworm.
* **Alternative:** Use a full Python image or an Alpine-based Python image.
* **Trade-off:** The slim image is smaller than the full image but still
  contains a Debian userspace. Alpine could be smaller, but native Python
  dependencies can have additional compatibility/build considerations.
* **Evidence / commit:** `Dockerfile`; implementation present before the
  documentation commit. The Dockerfile uses
  `python:3.12-slim-bookworm@sha256:...`.
* **Production improvement:** Build through a trusted CI pipeline, scan the
  image for vulnerabilities, rebuild regularly for security updates, and
  maintain a documented image update process.

## Decision 2 — Run the application as a non-root user

* **Choice:** Create UID/GID 10001 and run the Flask process as user `app`.
* **Why:** A compromised application process should not automatically have
  root privileges inside the container. This follows the principle of least
  privilege.
* **Assumption:** The application only needs access to its own application
  files and does not require privileged kernel or filesystem operations.
* **Alternative:** Run the application as the default container user.
* **Trade-off:** Non-root execution improves isolation but requires file
  ownership and permissions to be configured correctly during the image build.
* **Evidence / commit:** `Dockerfile` creates the `app` user, copies application
  files with `--chown=app:app`, and uses `USER app`.
* **Production improvement:** Use a read-only root filesystem where practical,
  drop unnecessary Linux capabilities, and verify the runtime security context
  with container security tooling.

## Decision 3 — Separate health and readiness checks

* **Choice:** Provide `/health` for process health and `/ready` for dependency
  readiness. Docker healthchecks use `/health`, while `/ready` checks
  PostgreSQL and Redis.
* **Why:** A running Flask process does not necessarily mean the service can
  serve real application requests. Separating liveness from dependency
  readiness prevents the two concepts from being confused.
* **Assumption:** PostgreSQL and Redis are required dependencies for the
  application's ready state.
* **Alternative:** Use one endpoint for both process and dependency status.
* **Trade-off:** Two endpoints require slightly more implementation and testing,
  but provide clearer operational behavior.
* **Evidence / commit:** `app/server.py`, `docker-compose.yml`,
  `validate.py`, and the successful validation run in commit
  `5ea6189 Implement environment validation`.
* **Production improvement:** Integrate readiness/liveness semantics with the
  orchestrator being used in production and expose dependency-specific
  monitoring and alerting.

## Decision 4 — Use separate frontend and backend networks

* **Choice:** NGINX is attached only to `frontend`. Flask applications are
  attached to both `frontend` and `backend`. PostgreSQL and Redis are attached
  only to the internal `backend` network.
* **Why:** The topology limits which services can directly communicate with
  the data layer. NGINX cannot directly reach PostgreSQL or Redis.
* **Assumption:** The application instances are the only services that need
  access to PostgreSQL and Redis.
* **Alternative:** Put every service on one Docker network.
* **Trade-off:** Multiple networks require more configuration but provide a
  meaningful network isolation boundary.
* **Evidence / commit:** `docker-compose.yml`; network hardening was included
  in commit `2029857 Harden service dependencies and network isolation`.
* **Production improvement:** Apply equivalent segmentation using production
  network policies, firewall rules, security groups, or Kubernetes NetworkPolicy
  depending on the deployment platform.

## Decision 5 — Use Docker service names instead of fixed container IPs

* **Choice:** Applications connect to `postgres` and `redis`, while NGINX
  connects to `app-01` and `app-02`.
* **Why:** Docker Compose service-name DNS is more stable than hard-coding
  container IP addresses. Containers can be recreated without requiring
  application configuration to be rewritten.
* **Assumption:** Docker's internal DNS is available for the Compose networks.
* **Alternative:** Configure static container IP addresses.
* **Trade-off:** Service-name DNS depends on the Docker networking environment,
  but avoids brittle IP management.
* **Evidence / commit:** `docker-compose.yml` and `nginx/nginx.conf`.
* **Production improvement:** Use platform-native service discovery in
  production and monitor DNS/service-discovery failures.

## Decision 6 — Configure bounded timeouts and upstream retries

* **Choice:** NGINX uses bounded proxy connect/read timeouts and can retry
  another upstream for connection errors, timeouts, and selected 502/503/504
  responses. Application database and Redis connections also use bounded
  timeouts.
* **Why:** A dependency or backend that stops responding should not cause
  requests to wait indefinitely. Upstream retry improves availability when
  one application instance fails.
* **Assumption:** Retrying the selected request types is safe for this
  assessment application. Production write operations require additional
  idempotency analysis.
* **Alternative:** Disable retries and rely entirely on client retries.
* **Trade-off:** Retries can improve availability but may increase latency and
  can duplicate non-idempotent operations if configured incorrectly.
* **Evidence / commit:** NGINX failover behavior and configuration were
  improved in commit `796514e Improve NGINX upstream failover`. The failure
  recovery test passed in commit
  `d906c2b Implement backend failure recovery test`.
* **Production improvement:** Define retry budgets, distinguish idempotent from
  non-idempotent requests, add circuit breakers where appropriate, and monitor
  retry rates and tail latency.

## Decision 7 — Apply restart policies and resource limits

* **Choice:** Services use `restart: unless-stopped`. CPU and memory limits
  are defined for the application, NGINX, PostgreSQL, and Redis containers.
* **Why:** Restart policies provide basic recovery from unexpected container
  termination, while resource limits reduce the risk of one service consuming
  all available host resources.
* **Assumption:** The configured limits are sufficient for this assessment
  workload.
* **Alternative:** No restart policy or unlimited resources.
* **Trade-off:** Limits improve containment but can cause failures if set below
  actual workload requirements.
* **Evidence / commit:** Resource and restart configuration is present in
  `docker-compose.yml`; resource configuration was introduced in
  `2809883 Configure app resources and backend URLs`, while restart policies
  were implemented in `3cff720 Set restart policies for all services`.
* **Production improvement:** Size limits from measured workload data and use
  production autoscaling/capacity management where appropriate.

## Decision 8 — Persist PostgreSQL data using a named volume

* **Choice:** PostgreSQL stores its data in the named Docker volume
  `postgres-data`.
* **Why:** Container recreation should not delete application records.
  Separating database storage from the PostgreSQL container lifecycle provides
  persistence.
* **Assumption:** The Docker host and named volume are available when the
  PostgreSQL container is recreated.
* **Alternative:** Store database data only inside the container filesystem.
* **Trade-off:** Named-volume persistence protects against container
  recreation but is not a substitute for backups or disaster recovery.
* **Evidence / commit:** PostgreSQL persistence was implemented in
  `6738918 Persist PostgreSQL data in named volume`. Container recreation was
  subsequently tested and the test record remained available.
* **Production improvement:** Use managed PostgreSQL or replicated storage in
  production, with tested off-host backups and documented recovery objectives.

## Decision 9 — Persist Redis AOF data using a named volume

* **Choice:** Redis uses AOF persistence and stores `/data` on the named
  `redis-data` volume.
* **Why:** AOF provides Redis persistence data, while the named volume ensures
  that the persisted files survive Redis container recreation.
* **Assumption:** Redis is being used as a persistent counter/data dependency
  for this assessment and the workload does not require a highly available
  Redis cluster.
* **Alternative:** Redis without persistence or persistence without a named
  volume.
* **Trade-off:** AOF improves persistence but adds disk I/O and does not by
  itself provide high availability.
* **Evidence / commit:** AOF was enabled in `c6fc487 Enable Redis AOF
  persistence`; named-volume persistence was added in
  `04b95ad Persist Redis AOF in named volume`.
* **Production improvement:** Use an HA Redis deployment or managed Redis
  service where required, define persistence/recovery objectives, and test
  failover and restore procedures.

## Decision 10 — Keep secrets outside images and source-controlled Compose

* **Choice:** The PostgreSQL password is supplied through the environment
  rather than hard-coded into the image or committed Compose configuration.
  `.env` and local secret configuration are ignored by Git, while
  `.env.example` contains safe example configuration.
* **Why:** Credentials should not be embedded in source code or container
  images.
* **Assumption:** The local assessment environment provides the required secret
  through a protected environment file or shell environment.
* **Alternative:** Hard-code the password in Compose or the application source.
* **Trade-off:** External secret injection requires environment setup, but
  avoids committing credentials.
* **Evidence / commit:** Secret removal was implemented in
  `791069c Remove secrets from image and compose configuration`. The
  `.gitignore` also excludes `.env` and `config/app.env`.
* **Production improvement:** Use a dedicated secret manager or platform
  secrets mechanism, rotate credentials, and avoid exposing secrets through
  process listings or logs.

## Decision 11 — Use explicit PostgreSQL backup and restore scripts

* **Choice:** Provide `backup.sh` for `pg_dump` backups and `restore.sh` for
  controlled restoration.
* **Why:** Persistence alone does not protect against logical corruption,
  accidental deletion, or other data-loss scenarios. Backup and restore must
  be operationally reproducible.
* **Assumption:** PostgreSQL is running in the Compose container named
  `postgres`.
* **Alternative:** Rely only on the Docker named volume.
* **Trade-off:** Backup management adds operational steps, but provides a
  recoverable logical copy of the database.
* **Evidence / commit:** `backup.sh` was implemented in
  `f88b64a Implement PostgreSQL backup script` and `restore.sh` in
  `c5cac8d Implement PostgreSQL restore script`. A backup/restore exercise was
  also performed successfully.
* **Production improvement:** Store backups off-host, encrypt them, rotate
  them, monitor backup success, and regularly perform automated restore
  tests.

## Overall limitations

This solution is designed for the assessment environment and demonstrates
containerization, service discovery, network isolation, persistence,
validation, failover, and recovery. It is not intended to claim production
high availability. In particular, the current architecture still has
single-instance dependencies such as the PostgreSQL primary, Redis primary,
NGINX, and the Docker host. Production deployment would require appropriate
replication, orchestration, external storage, monitoring, secret management,
and disaster-recovery controls.
