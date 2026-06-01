<!--
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
-->

# Superset Security Review — Submission Package

This repository contains a fork of [Apache Superset](https://github.com/apache/superset) with security fixes, CI/CD improvements, and tooling enhancements implemented using [Devin AI](https://devin.ai/).

## Live Security Dashboard

**[https://security-dashboard-xwgymjld.devinapps.com/](https://security-dashboard-xwgymjld.devinapps.com/)**

---

## Table of Contents

- [Quick Start (Docker Bundle)](#quick-start-docker-bundle)
- [Build from Source (Alternative)](#build-from-source-alternative)
- [Simulating the Security Workflow](#simulating-the-security-workflow)
- [Verifying the Fixes](#verifying-the-fixes)
- [Pull Requests Summary](#pull-requests-summary)
- [Security Audit Report](#security-audit-report)
- [CI/CD Workflows](#cicd-workflows)
- [Docker Architecture](#docker-architecture)
- [Walkthrough Presentation](#walkthrough-presentation)
- [Additional Resources](#additional-resources)

---

## Quick Start (Docker Bundle)

The Docker bundle (`superset-docker-bundle.tar.gz`, ~545 MB) contains three pre-built images — the Superset application, PostgreSQL 17, and Redis 7 — so you can run the full stack without building from source.

### Prerequisites

- [Docker](https://www.docker.com/get-started) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)
- At least **4 GB RAM** allocated to Docker
- **2 GB free disk space** (images expand to ~1.5 GB)

### Step 1 — Load the images

```bash
docker load < superset-docker-bundle.tar.gz
```

This loads `superset-app:latest`, `redis:7`, and `postgres:17` into your local Docker daemon.

### Step 2 — Clone the repository

```bash
git clone https://github.com/rayaun/superset.git
cd superset
```

### Step 3 — Start the stack

```bash
docker compose -f docker-compose-submission.yml up -d
```

Wait 2–3 minutes for the `superset-init` container to finish database setup, then open **[http://localhost:8088](http://localhost:8088)**.

**Default credentials:** `admin` / `admin`

### Step 4 — Stop / clean up

```bash
# Stop all services
docker compose -f docker-compose-submission.yml down

# Stop and remove all data volumes
docker compose -f docker-compose-submission.yml down -v
```

### Convenience Script

A helper script is also available:

```bash
chmod +x run-submission.sh

./run-submission.sh start   # Start the stack
./run-submission.sh status  # Check container health
./run-submission.sh logs    # Tail logs
./run-submission.sh stop    # Stop containers
./run-submission.sh clean   # Stop and remove volumes
```

---

## Build from Source (Alternative)

If you prefer to build from source instead of using the pre-built bundle:

```bash
git clone https://github.com/rayaun/superset.git
cd superset

# Build and start (takes 10–15 minutes on first run)
docker compose -f docker-compose-non-dev.yml up --build
```

Or for development mode with hot-reloading:

```bash
docker compose up --build
```

---

## Simulating the Security Workflow

This section explains how the event-driven security automation works and how to test each fix locally.

### How the Automation Pipeline Works

```
GitHub Issue (labeled "security-vulnerability")
        │
        ▼
GitHub Actions workflow triggers  (.github/workflows/devin-security-review.yml)
        │
        ▼
Devin AI receives the task via API
        │
        ▼
Devin investigates → writes fix → opens PR
        │
        ▼
CI runs security checks → PR reviewed → merged
```

**Example runs:**
- [Issue #7](https://github.com/rayaun/superset/issues/7) → Devin opened [PR #9](https://github.com/rayaun/superset/pull/9) (XSS fix in SQL Lab)
- [Issue #10](https://github.com/rayaun/superset/issues/10) → Devin opened [PR #12](https://github.com/rayaun/superset/pull/12) (mako CVE fix)

### Test 1 — XSS Prevention in SQL Lab (PR #9)

This fix ensures SQL Lab escapes HTML in query results, preventing stored XSS.

1. Open **[http://localhost:8088](http://localhost:8088)** and log in as `admin` / `admin`.
2. Navigate to **SQL Lab** → **SQL Editor**.
3. Select the **examples** database.
4. Run a query with an XSS payload:

   ```sql
   SELECT '<script>alert("xss")</script>' AS test_column
   ```

5. **Expected result:** The output renders the literal text `<script>alert("xss")</script>` — no alert dialog appears. The HTML is escaped, not executed.

### Test 2 — Verify npm Dependency Fixes (PR #6, #13)

```bash
cd superset-frontend
npm audit
# Critical/high vulnerabilities for vm2 and axios should be resolved
# via npm overrides in package.json
```

### Test 3 — Verify mako Version (PR #12)

```bash
# Inside the running container:
docker exec superset_app pip show mako | grep Version
# Should show Mako >= 1.3.12 (patched for CVE-2026-44307)
```

### Test 4 — Verify CI Workflows Exist

```bash
ls -la .github/workflows/ci-*.yml .github/workflows/devin-*.yml
```

### Test 5 — Trigger the Automation (requires GitHub access)

To see the full automation end-to-end on your own fork:

1. Create a new GitHub Issue with the label `security-vulnerability`.
2. Title it with a known CVE or describe a dependency vulnerability.
3. The `devin-security-review.yml` workflow fires, calling the Devin API.
4. Devin investigates, creates a branch, pushes a fix, and opens a PR.

> **Note:** This requires a Devin API key configured as a GitHub Actions secret (`DEVIN_API_KEY`). See `.github/workflows/devin-security-review.yml` for details.

---

## Pull Requests Summary

All PRs follow [Conventional Commits](https://www.conventionalcommits.org/) and are merged into `master`.

### Merged PRs

| PR | Title | Category | Date |
|----|-------|----------|------|
| [#9](https://github.com/rayaun/superset/pull/9) | `fix(security):` make SQL Lab results escape HTML by default (XSS, #7) | Application Security | 2026-05-10 |
| [#8](https://github.com/rayaun/superset/pull/8) | `ci(security):` migrate Devin API from v3 to v1 for Pro account compatibility | CI/CD | 2026-05-10 |
| [#6](https://github.com/rayaun/superset/pull/6) | `fix:` address vm2 and axios vulnerabilities via npm overrides | Dependency Security | 2026-05-10 |
| [#5](https://github.com/rayaun/superset/pull/5) | `ci(security):` add automated Devin security vulnerability review workflow | CI/CD | 2026-05-10 |
| [#4](https://github.com/rayaun/superset/pull/4) | `fix:` improve Playwright test stability for CI | Testing | 2026-05-07 |
| [#3](https://github.com/rayaun/superset/pull/3) | `feat:` add all 51 gstack skills from garrytan/gstack | Tooling | 2026-05-07 |
| [#2](https://github.com/rayaun/superset/pull/2) | `ci:` add PR quality gate, skill validation, code quality, and security workflows | CI/CD | 2026-05-07 |
| [#1](https://github.com/rayaun/superset/pull/1) | `feat:` add all 14 superpowers skills from obra/superpowers | Tooling | 2026-05-07 |
| [#13](https://github.com/rayaun/superset/pull/13) | `fix(security):` tighten axios override and guard against GHSA-w9j2-pvgh-6h63 regressions (#11) | Dependency Security | 2026-05-11 |
| [#12](https://github.com/rayaun/superset/pull/12) | `fix(security):` bump mako to 1.3.12 (CVE-2026-44307, #10) | Dependency Security | 2026-05-11 |

### Open PRs (Additional Security Fixes)

| PR | Title | Category |
|----|-------|----------|
| [#18](https://github.com/rayaun/superset/pull/18) | `fix(security):` pin dockerize.Dockerfile base image to alpine 3.23.4 + digest (#17) | Supply Chain Security |
| [#14](https://github.com/rayaun/superset/pull/14) | `docs:` add Devin AI walkthrough presentation for Superset integration | Documentation |

---

## Security Audit Report

A comprehensive security audit is documented in [`SECURITY_AUDIT.md`](SECURITY_AUDIT.md). Key findings:

| # | Finding | Severity | Status |
|---|---------|----------|--------|
| 1 | `vm2` sandbox escape (GHSA-47x8-96vw-5wg6) | **Critical** | Fixed (PR #6) |
| 2 | `eslint-plugin-i18n-strings` advisory (GHSA-55h3-fm53-wq99) | **Critical** | Documented (no patch available) |
| 3 | `axios` HTTP request vulnerabilities (GHSA-w9j2-pvgh-6h63) | **High** | Fixed (PR #6, #13) |
| 4 | `flask` session cache leak (CVE-2026-27205) | **High** | Documented (requires major version upgrade) |
| 5 | Helm chart pods run as root | **Critical** | Documented (infrastructure change) |
| 6 | Unpinned base image in `dockerize.Dockerfile` | **High** | Fixed (PR #18) |

---

## CI/CD Workflows

| Workflow | File | Purpose |
|----------|------|---------|
| PR Quality Gate | `.github/workflows/ci-pr-quality.yml` | Validates PR title, labels, and description |
| Code Quality | `.github/workflows/ci-code-quality.yml` | Runs linters and formatters |
| Security Checks | `.github/workflows/ci-security.yml` | Scans for vulnerabilities in dependencies |
| Skill Validation | `.github/workflows/ci-skill-validation.yml` | Validates Devin AI skill definitions |
| Devin Security Review | `.github/workflows/devin-security-review.yml` | Automated security vulnerability review |

---

## Docker Architecture

```
┌─────────────────────────────────────────┐
│              Docker Network             │
│                                         │
│  ┌───────────┐  ┌───────────────────┐   │
│  │  Redis 7  │  │  PostgreSQL 17    │   │
│  │  (cache)  │  │  (metadata DB)    │   │
│  └─────┬─────┘  └────────┬──────────┘   │
│        │                 │              │
│  ┌─────┴─────────────────┴──────────┐   │
│  │     Superset Application          │   │
│  │     (Flask + Gunicorn)            │   │
│  │     Port 8088                     │   │
│  └───────────────────────────────────┘   │
│                                         │
│  ┌───────────────────────────────────┐   │
│  │     Celery Worker + Beat          │   │
│  │     (async tasks & scheduling)    │   │
│  └───────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| `db` | `postgres:17` | 5432 | Metadata database |
| `redis` | `redis:7` | 6379 | Cache and Celery broker |
| `superset` | `superset-app:latest` | 8088 | Web application |
| `superset-init` | `superset-app:latest` | — | One-time DB initialization |
| `superset-worker` | `superset-app:latest` | — | Async task processing |
| `superset-worker-beat` | `superset-app:latest` | — | Scheduled task runner |

---

## Walkthrough Presentation

A self-contained HTML walkthrough is included at [`docs/devin-walkthrough/index.html`](docs/devin-walkthrough/index.html). It covers:

1. **What is Devin** — Introduction to Devin AI as an autonomous software engineer
2. **Devin Capabilities in Superset** — Autonomous CI/CD, security audit workflow, knowledge & playbooks
3. **Event-Driven Automation** — API integration, end-to-end automation flow, live XSS fix and mako CVE examples

To view:

```bash
# macOS
open docs/devin-walkthrough/index.html

# Linux
xdg-open docs/devin-walkthrough/index.html

# Windows
start docs/devin-walkthrough/index.html
```

Or view the live version: **[https://devin-walkthrough-qqptfffr.devinapps.com/](https://devin-walkthrough-qqptfffr.devinapps.com/)**

---

## Project Structure

```
superset/
├── SUBMISSION_README.md              # This file
├── SECURITY_AUDIT.md                 # Detailed security findings
├── run-submission.sh                 # Convenience start/stop script
├── docker-compose-submission.yml     # Pre-built image compose (use with bundle)
├── docker-compose-non-dev.yml        # Build-from-source compose
├── Dockerfile                        # Multi-stage build (Node + Python)
├── docker/                           # Docker support scripts and config
│   ├── .env                          # Default environment variables
│   ├── docker-init.sh                # Database initialization
│   └── docker-bootstrap.sh           # Application bootstrap
├── docs/
│   └── devin-walkthrough/
│       └── index.html                # Standalone walkthrough presentation
├── superset/                         # Python backend (Flask, SQLAlchemy)
├── superset-frontend/                # React/TypeScript frontend
│   └── package.json                  # Includes npm override security fixes
├── .github/workflows/                # CI/CD pipeline definitions
│   ├── ci-security.yml               # Security scanning
│   ├── ci-code-quality.yml           # Code quality
│   └── devin-security-review.yml     # Automated security review
└── .agents/skills/                   # Devin AI skill definitions
```

---

## Additional Resources

- **Live Security Dashboard:** [https://security-dashboard-xwgymjld.devinapps.com/](https://security-dashboard-xwgymjld.devinapps.com/)
- **Walkthrough Presentation (live):** [https://devin-walkthrough-qqptfffr.devinapps.com/](https://devin-walkthrough-qqptfffr.devinapps.com/)
- **Repository:** [https://github.com/rayaun/superset](https://github.com/rayaun/superset)
- **Apache Superset Docs:** [https://superset.apache.org](https://superset.apache.org)
- **Devin AI:** [https://devin.ai](https://devin.ai)
