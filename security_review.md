# Security and production-readiness review

This review records concrete security, reliability, and production-readiness
risks in the assessment solution. Implemented fixes are separated from
production follow-ups so that planned improvements are not presented as
completed work.

## 1. Secrets in source code or container images

* **Risk and evidence:** Database credentials must not be embedded in source
  code, the Dockerfile, or a committed Compose file.
* **Impact:** A committed credential could allow unauthorized database access
  and could remain available in Git history even after deletion.
* **Implemented fix / commit:** Database configuration was moved to runtime
  environment variables and secret values were removed from the image and
  Compose configuration in `791069c Remove secrets from image and compose
  configuration`.
* **Production follow-up:** Use a dedicated secret manager or platform secret
  store, rotate credentials regularly, and apply least-privilege database
  accounts.
* **How to verify:**

  ```bash
  git grep -nE 'POSTGRES_PASSWORD=|password[[:space:]]*[:=]'
  grep -nE '^\.env|config/app\.env' .gitignore
  ```

## 2. Public host-port exposure

* **Risk and evidence:** PostgreSQL, Redis, and the Flask applications should
  not be directly reachable from the host.
* **Impact:** Direct access would bypass NGINX and increase the externally
  reachable attack surface.
* **Implemented fix / commit:** Backend host-port exposure was removed in
  `f76b6e7 Remove backend host port exposure`.
* **Production follow-up:** Enforce network policy/firewall rules at the
  infrastructure level and expose only the intended ingress/load-balancer
  endpoint.
* **How to verify:**

  ```bash
  sudo docker compose ps
  sudo docker inspect app-01 --format '{{json .NetworkSettings.Ports}}'
  sudo docker inspect app-02 --format '{{json .NetworkSettings.Ports}}'
  sudo docker inspect postgres --format '{{json .NetworkSettings.Ports}}'
  sudo docker inspect redis --format '{{json .NetworkSettings.Ports}}'
  ```

## 3. Application container runs as root

* **Risk and evidence:** Running a web application as root would increase the
  impact of application compromise.
* **Impact:** A container escape or successful privilege abuse could have a
  larger impact on the host or container environment.
* **Implemented fix / commit:** The Dockerfile creates UID/GID 10001 and runs
  the application as the non-root `app` user.
* **Production follow-up:** Use a read-only root filesystem where possible,
  drop Linux capabilities, and apply a hardened runtime security profile.
* **How to verify:**

  ```bash
  sudo docker exec app-01 id
  ```

  The result should show the non-root `app` user/UID.

## 4. Mutable or unverified container images

* **Risk and evidence:** Tags alone can move to different image versions.
* **Impact:** An unexpected image update can introduce vulnerabilities or
  change application behavior.
* **Implemented fix / commit:** The application base image and Compose service
  images are pinned by SHA-256 digest.
* **Production follow-up:** Maintain an approved image update process, scan
  images in CI, monitor CVEs, and periodically update pinned digests.
* **How to verify:**

  ```bash
  grep -n '@sha256:' Dockerfile docker-compose.yml
  ```

## 5. Excessive network reachability

* **Risk and evidence:** A single shared Docker network would allow unnecessary
  service-to-service connectivity.
* **Impact:** A compromised frontend service could potentially communicate
  directly with backend data services.
* **Implemented fix / commit:** NGINX is frontend-only, applications are on
  frontend/backend, and PostgreSQL/Redis are backend-only. The backend network
  is marked internal. This was hardened in
  `2029857 Harden service dependencies and network isolation`.
* **Production follow-up:** Add explicit network policies/firewall controls
  and deny unnecessary east-west traffic.
* **How to verify:**

  ```bash
  sudo docker network inspect barq-assessment_frontend
  sudo docker network inspect barq-assessment_backend
  ```

## 6. Database persistence without backup would not be sufficient

* **Risk and evidence:** A named volume survives container recreation but does
  not protect against accidental deletion, logical corruption, or host loss.
* **Impact:** A database incident could result in permanent data loss.
* **Implemented fix / commit:** PostgreSQL uses a named persistent volume,
  and backup/restore scripts were implemented in
  `6738918`, `f88b64a`, and `c5cac8d`.
* **Production follow-up:** Store encrypted backups outside the Docker host,
  implement retention, monitor backup jobs, and define/test RPO and RTO.
* **How to verify:**

  ```bash
  sudo docker volume ls | grep postgres-data
  ./backup.sh
  ```

## 7. Redis persistence without external recovery would be insufficient

* **Risk and evidence:** Redis AOF protects persisted data across container
  recreation only when the persistence files themselves survive.
* **Impact:** Loss of the Docker host or persistent volume can still result in
  data loss.
* **Implemented fix / commit:** Redis AOF was enabled in `c6fc487` and its
  `/data` directory was placed on a named volume in `04b95ad`.
* **Production follow-up:** Use managed/replicated Redis where required and
  test recovery from persistent storage.
* **How to verify:**

  ```bash
  sudo docker inspect redis --format '{{json .Mounts}}'
  sudo docker exec redis redis-cli INFO persistence
  ```

## 8. Unbounded requests and dependency waits

* **Risk and evidence:** A backend or dependency that never responds can
  consume worker resources if requests are allowed to wait indefinitely.
* **Impact:** Hanging requests can reduce availability and increase resource
  consumption.
* **Implemented fix / commit:** NGINX proxy timeouts and application database
  and Redis connection/read timeouts are bounded. NGINX upstream retry behavior
  was improved in `796514e`.
* **Production follow-up:** Tune timeout budgets using observed latency,
  implement circuit breakers where appropriate, and monitor timeout rates.
* **How to verify:**

  ```bash
  grep -nE 'proxy_(connect|read)_timeout|connect_timeout|socket_.*timeout' \
    nginx/nginx.conf app/server.py
  ```

## 9. Availability depends on multiple services

* **Risk and evidence:** Although two Flask instances provide application
  redundancy, NGINX, PostgreSQL, Redis, and the Docker host remain potential
  single points of failure.
* **Impact:** Failure of a single non-redundant dependency can make the overall
  application unavailable or degrade functionality.
* **Implemented fix / commit:** Two application instances and NGINX upstream
  failover were implemented and tested. The failure/recovery test is recorded
  in `d906c2b Implement backend failure recovery test`.
* **Production follow-up:** Use redundant ingress/load balancing, PostgreSQL
  replication/failover, Redis HA, multiple hosts/nodes, and orchestration.
* **How to verify:**

  ```bash
  ./failure_test.py
  ./validate.py
  ```

## 10. Logging without complete centralized monitoring

* **Risk and evidence:** Container stdout/stderr and structured application
  logs provide useful evidence, but local logs alone do not provide durable
  centralized observability.
* **Impact:** Logs can be lost with the host/container lifecycle and may not
  provide sufficient alerting during an incident.
* **Implemented fix / commit:** NGINX and application logs use structured
  fields including timestamps, request IDs, paths, status, and instance
  information. Log analysis was documented in `7183645`.
* **Production follow-up:** Send logs to centralized storage, add metrics and
  distributed tracing, define alerts for error rate/latency/dependency
  failures, and protect sensitive log data.
* **How to verify:**

  ```bash
  docker compose logs --no-color nginx
  docker compose logs --no-color app-01
  docker compose logs --no-color app-02
  ```

## 11. Resource exhaustion

* **Risk and evidence:** Containers without resource limits can consume
  excessive host CPU or memory.
* **Impact:** One service can starve other services and reduce overall
  availability.
* **Implemented fix / commit:** CPU and memory limits were added to the
  services. Application limits were configured in `2809883`.
* **Production follow-up:** Size limits from production measurements, monitor
  saturation, and use autoscaling/capacity planning where appropriate.
* **How to verify:**

  ```bash
  sudo docker inspect app-01 --format '{{json .HostConfig.Memory}}'
  sudo docker inspect app-01 --format '{{json .HostConfig.NanoCpus}}'
  ```

## 12. Backup restore script is intentionally non-destructive

* **Risk and evidence:** `restore.sh` restores a SQL dump into the existing
  `barq_tasks` database. It does not automatically drop and recreate the
  database.
* **Impact:** Restoring into a database containing existing schema/data can
  produce duplicate-object or duplicate-key errors.
* **Implemented fix / commit:** The script validates the backup file and
  PostgreSQL availability and fails rather than silently destroying existing
  data. The controlled backup/restore procedure was tested separately.
* **Production follow-up:** Provide a documented restore-to-new-database
  procedure, require explicit confirmation for destructive operations, and
  automate restore validation in an isolated environment.
* **How to verify:**

  ```bash
  ./restore.sh backups/barq_tasks_backup.sql
  ```

  Use an appropriate clean target database when performing a real recovery
  test.

## Security limitations

This assessment demonstrates important baseline controls but does not claim
production-grade security. Remaining improvements include centralized secret
management, image vulnerability scanning, stronger container hardening,
centralized logging/monitoring, network policy enforcement, encrypted and
off-host backups, high availability for stateful dependencies, and formal
incident-response procedures.
