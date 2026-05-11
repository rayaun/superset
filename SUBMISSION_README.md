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

This repository contains a fork of [Apache Superset](https://github.com/apache/superset) with a series of security fixes, CI/CD improvements, and tooling enhancements implemented using [Devin AI](https://devin.ai/).

## Live Security Dashboard

A live dashboard summarizing all findings and fixes is available at:

**[https://security-dashboard-xwgymjld.devinapps.com/](https://security-dashboard-xwgymjld.devinapps.com/)**

---

## Table of Contents

- [Quick Start (Docker)](#quick-start-docker)
- [Repository Overview](#repository-overview)
- [Pull Requests Summary](#pull-requests-summary)
- [Security Audit Report](#security-audit-report)
- [CI/CD Workflows](#cicd-workflows)
- [Project Structure](#project-structure)
- [Verifying the Fixes](#verifying-the-fixes)
- [Additional Resources](#additional-resources)

---

## Quick Start (Docker)

### Prerequisites

- [Docker](https://www.docker.com/get-started) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)
- At least **8 GB RAM** allocated to Docker
- **20 GB free disk space**

### Option 1: Production-like Build (Recommended for Review)

This builds and runs Superset with all security fixes applied:

```bash
# Clone the repository
git clone https://github.com/rayaun/superset.git
cd superset

# Start the full stack (PostgreSQL, Redis, Superset)
docker compose -f docker-compose-non-dev.yml up --build
```

Wait 3-5 minutes for initialization, then open **[http://localhost:8088](http://localhost:8088)**.

Default credentials:
- **Username:** `admin`
- **Password:** `admin`

### Option 2: Development Mode

For full development mode with hot-reloading:

```bash
docker compose up --build
```

This mounts source code as volumes for live editing. Open **[http://localhost:8088](http://localhost:8088)** after initialization.

### Option 3: Quick Review (No Build Required)

To inspect the code and security fixes without building the full application:

```bash
# Clone the repository
git clone https://github.com/rayaun/superset.git
cd superset

# View the security audit report
cat SECURITY_AUDIT.md

# View the git log of all security-related changes
git log --oneline --all --since="2026-05-07"

# List all merged PRs
gh pr list --state merged
```

### Stopping the Containers

```bash
# Stop all services
docker compose -f docker-compose-non-dev.yml down

# Stop and remove all data volumes
docker compose -f docker-compose-non-dev.yml down -v
```

---

## Repository Overview

This submission demonstrates a complete security review and remediation workflow for Apache Superset, an enterprise-grade data visualization platform. The work covers:

1. **Dependency vulnerability remediation** — Critical and high-severity CVEs in both Python and npm dependencies
2. **Application-level security fixes** — XSS prevention in SQL Lab
3. **CI/CD security automation** — Automated vulnerability scanning workflows
4. **Testing infrastructure** — Playwright test stabilization for CI
5. **AI-assisted development tooling** — Skills and workflow automation for Devin AI

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

### Open PRs (Additional Security Fixes)

| PR | Title | Category |
|----|-------|----------|
| [#14](https://github.com/rayaun/superset/pull/14) | `docs:` add Devin AI walkthrough presentation for Superset integration | Documentation |
| [#13](https://github.com/rayaun/superset/pull/13) | `fix(security):` tighten axios override and guard against GHSA-w9j2-pvgh-6h63 regressions | Dependency Security |
| [#12](https://github.com/rayaun/superset/pull/12) | `fix(security):` bump mako to 1.3.12 (CVE-2026-44307, #10) | Dependency Security |

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

---

## CI/CD Workflows

The following GitHub Actions workflows were added or modified:

| Workflow | File | Purpose |
|----------|------|---------|
| PR Quality Gate | `.github/workflows/ci-pr-quality.yml` | Validates PR title, labels, and description |
| Code Quality | `.github/workflows/ci-code-quality.yml` | Runs linters and formatters |
| Security Checks | `.github/workflows/ci-security.yml` | Scans for vulnerabilities in dependencies |
| Skill Validation | `.github/workflows/ci-skill-validation.yml` | Validates Devin AI skill definitions |
| Devin Security Review | `.github/workflows/devin-security-review.yml` | Automated security vulnerability review |

---

## Project Structure

Key files and directories relevant to this submission:

```
superset/
├── SUBMISSION_README.md          # This file
├── SECURITY_AUDIT.md             # Detailed security findings report
├── Dockerfile                    # Multi-stage Docker build (Node + Python)
├── docker-compose.yml            # Development Docker Compose
├── docker-compose-non-dev.yml    # Production-like Docker Compose
├── docker/                       # Docker support scripts and config
│   ├── .env                      # Default environment variables
│   ├── docker-init.sh            # Database initialization script
│   ├── docker-bootstrap.sh       # Application bootstrap script
│   └── pythonpath_dev/           # Python configuration overrides
├── superset/                     # Python backend (Flask, SQLAlchemy)
├── superset-frontend/            # React/TypeScript frontend
│   └── package.json              # Includes npm override security fixes
├── .github/workflows/            # CI/CD pipeline definitions
│   ├── ci-security.yml           # Security scanning workflow
│   ├── ci-code-quality.yml       # Code quality workflow
│   └── devin-security-review.yml # Automated security review
└── .agents/skills/               # Devin AI skill definitions
```

---

## Verifying the Fixes

### 1. Verify npm Dependency Fixes

```bash
cd superset-frontend
npm audit
# Should show reduced critical/high vulnerabilities vs. upstream
```

### 2. Verify XSS Fix in SQL Lab

The fix in PR #9 ensures SQL Lab query results escape HTML by default. To verify:

```bash
# Check the configuration change
grep -r "HTML_SANITIZATION" superset/config.py
```

### 3. Verify CI Workflows

```bash
# List all CI workflow files
ls -la .github/workflows/ci-*.yml .github/workflows/devin-*.yml
```

### 4. Run the Security Audit Manually

```bash
# Python dependency check
pip-audit -r requirements/base.txt 2>/dev/null || echo "Install pip-audit: pip install pip-audit"

# npm dependency check
cd superset-frontend && npm audit
```

---

## Docker Architecture

The Docker setup uses a multi-service architecture:

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

### Services

| Service | Image/Build | Port | Purpose |
|---------|-------------|------|---------|
| `db` | `postgres:17` | 5432 | Metadata database |
| `redis` | `redis:7` | 6379 | Cache and Celery broker |
| `superset` | Built from Dockerfile | 8088 | Web application |
| `superset-init` | Built from Dockerfile | — | One-time DB initialization |
| `superset-worker` | Built from Dockerfile | — | Async task processing |
| `superset-worker-beat` | Built from Dockerfile | — | Scheduled task runner |

---

## Additional Resources

- **Live Security Dashboard:** [https://security-dashboard-xwgymjld.devinapps.com/](https://security-dashboard-xwgymjld.devinapps.com/)
- **Repository:** [https://github.com/rayaun/superset](https://github.com/rayaun/superset)
- **Apache Superset Docs:** [https://superset.apache.org](https://superset.apache.org)
- **Devin AI:** [https://devin.ai](https://devin.ai)
