# BARQ Systems DevOps Assessment

This repository contains the implementation, investigation evidence, validation
scripts, failure testing, persistence testing, backup/restore procedures,
security review, engineering decisions, and CI configuration for the BARQ
Systems DevOps assessment.

## Current verified environment

The currently verified environment contains:

- NGINX as the only public entry point
- Flask application instances `app-01` and `app-02`
- PostgreSQL 16
- Redis 7.4 with AOF persistence
- Separate frontend and backend Docker networks
- Internal backend network
- PostgreSQL named-volume persistence
- Redis named-volume persistence
- Application readiness checks
- Container health checks
- Restart policies
- Resource limits
- Non-root application container
- Pinned container image digests
- No host ports for applications, PostgreSQL, or Redis

Current verified development endpoint:

    http://127.0.0.1:8080

The final assessment video will demonstrate the required three-instance
configuration on port 8090.

## Architecture

Current request flow:

    Client
      |
      v
    NGINX :80
      |
      +---- app-01:8080
      |
      +---- app-02:8080
                  |
                  +---- PostgreSQL :5432
                  |
                  +---- Redis :6379

Networks:

- frontend: NGINX and application containers
- backend: application containers, PostgreSQL, and Redis
- backend is an internal Docker network

PostgreSQL and Redis do not expose host ports.

See `docs/ARCHITECTURE.md` and the final `architecture.png` or
`architecture.pdf`.

## Repository structure

    app/                    Flask application
    database/               PostgreSQL initialization
    nginx/                  NGINX configuration
    logs/                   Original assessment logs
    tests/                  Application tests
    docs/                   Documentation and evidence
    assessment/             Assessment material
    assets/                 Assessment assets

    docker-compose.yml      Docker Compose configuration
    Dockerfile              Application image
    requirements.txt        Python dependencies

    validate.py             Environment validation
    failure_test.py         Backend failure/recovery test
    backup.sh               PostgreSQL backup
    restore.sh              PostgreSQL restore
    video_challenge.sh      Final live troubleshooting challenge

    log_analysis.md         Correlated log analysis
    troubleshooting.md      Investigation journal
    decisions.md            Engineering decisions
    security_review.md      Security review
    AI_USAGE.md             AI/tool usage disclosure

## Prerequisites

Install or have available:

- Ubuntu/Linux
- Docker Engine
- Docker Compose v2
- Git
- Python 3

Verify:

    git --version
    docker version
    docker compose version
    python3 --version

Docker commands may require `sudo` depending on local Docker permissions.

## Configuration

Create a local environment file:

    cp .env.example .env

Edit `.env` and set a local PostgreSQL password:

    nano .env

Example:

    PUBLIC_PORT=8080
    POSTGRES_PASSWORD=change-this-locally

Never commit `.env` or real credentials.

## Build

    sudo docker compose build

## Start

    sudo docker compose up -d

Check the services:

    sudo docker compose ps

Wait until all required health checks report healthy.

## Stop

Stop containers:

    sudo docker compose stop

Remove containers while preserving named volumes:

    sudo docker compose down

Do not use `docker compose down -v` during persistence testing because
that removes the PostgreSQL and Redis named volumes.

## HTTP endpoints

Required endpoints:

    /
    /health
    /ready
    /instance
    /records
    /counter

Test them:

    curl -i http://127.0.0.1:8080/
    curl -i http://127.0.0.1:8080/health
    curl -i http://127.0.0.1:8080/ready
    curl -i http://127.0.0.1:8080/instance
    curl -i http://127.0.0.1:8080/records
    curl -i http://127.0.0.1:8080/counter

Repeated `/instance` requests demonstrate load balancing:

    for i in {1..10}; do
        curl -s http://127.0.0.1:8080/instance
        echo
    done

## Automated validation

Run:

    ./validate.py

The validator checks:

- Container health
- Public NGINX access
- Required HTTP endpoints
- Application readiness
- PostgreSQL readiness
- Redis readiness
- Load balancing
- Host port exposure
- Network isolation
- Internal backend network
- PostgreSQL records
- Redis counter

The verified environment currently ends with:

    === VALIDATION PASSED ===
    All required checks passed.

## Failure and recovery test

Run:

    ./failure_test.py

The test:

1. Measures baseline traffic.
2. Stops `app-01`.
3. Sends traffic through NGINX.
4. Confirms `app-02` continues serving requests.
5. Restores `app-01`.
6. Waits for it to become healthy.
7. Confirms traffic returns to both instances.

The verified run achieved:

    Baseline:       20/20 successful
    During failure: 20/20 successful
    Errors:          0/20
    After recovery: 20/20 successful

## PostgreSQL persistence

Create a record:

    curl -s -X POST http://127.0.0.1:8080/records \
      -H 'Content-Type: application/json' \
      -d '{"title":"CONTAINER_RECREATE_TEST"}'

Verify it:

    curl -s http://127.0.0.1:8080/records

PostgreSQL uses the named volume `postgres-data`.

The persistence test recreates the PostgreSQL container while retaining the
volume and verifies that the record survives.

## PostgreSQL backup

Run:

    ./backup.sh

Backups are written to:

    backups/

Generated backup files are ignored by Git.

## PostgreSQL restore

Usage:

    ./restore.sh backups/<backup-file>.sql

The restore script restores a compatible PostgreSQL dump into the target
database. A clean full restore may require recreating the target database
first.

## Log investigation

The original logs are preserved under:

    logs/

The investigation is documented in:

    log_analysis.md

The analysis covers:

- Log validity
- Status-code counts
- Duplicate request IDs
- NGINX retry behavior
- Dependency failures
- Upstream failures
- Timeout incidents
- Latency
- Cross-log correlation
- Timeline
- Root-cause conclusions

The original log files were not modified.

## Troubleshooting journal

Investigation steps, hypotheses, commands, failed attempts, fixes, and retests
are documented in:

    troubleshooting.md

## Engineering decisions

Engineering decisions, assumptions, alternatives, trade-offs, and limitations
are documented in:

    decisions.md

## Security review

The security review covers:

- Secrets
- Host ports
- Container users
- Image pinning
- Docker networks
- Persistence and backups
- Logging
- Availability
- Resource limits

See:

    security_review.md

Implemented fixes are separated from future recommendations.

## CI

The GitHub Actions workflow is:

    .github/workflows/ci.yml

The pipeline is intended to run on pushes and pull requests and performs:

1. Checkout
2. Python syntax checks
3. Docker Compose configuration validation
4. Image build
5. Environment startup
6. Readiness wait
7. Full validation

The final successful CI run will be recorded in the evidence index.

## Final video challenge

The assessment requires a live troubleshooting demonstration using:

    ./video_challenge.sh

The challenge must be run for the first time in the video working copy.

The final demonstration will:

- Diagnose and fix the injected runtime problem
- Avoid `docker compose down`
- Change the public port from 8080 to 8090
- Add a third application instance
- Demonstrate all three instances
- Re-run validation
- Show Git status and diffs
- Show commit hashes
- Push the final commits
## Final Assessment Video

The final continuous assessment demonstration is available here:

[Watch the final assessment video](https://drive.google.com/file/d/1hisZSOScIZgwcq83VuARYFEBLcUwiXPX/view?usp=sharing)

## Evidence

Assessment evidence is tracked in:

    docs/EVIDENCE_INDEX.md

The evidence index maps requirements to repository files, commands,
commits, validation evidence, and final video timestamps.

## Cleanup

To remove containers while preserving data:

    sudo docker compose down

To intentionally delete persistent data:

    sudo docker compose down -v

The second command is destructive to the PostgreSQL and Redis volumes.

## Verification rule

Only claim a fix when it has been reproduced and verified.

Commands, failed attempts, test results, and conclusions used as assessment
evidence are documented in the investigation and evidence files.
