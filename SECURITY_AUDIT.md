# Security Audit Report: rayaun/superset

**Date:** May 2026
**Scope:** Full codebase — Python backend, frontend (npm), Helm chart, Docker configuration

---

## Critical / High Findings

### 1. `vm2` — Critical Sandbox Escape (Frontend)

- **Severity:** Critical
- **Package:** `vm2` (<=3.11.1)
- **Advisory:** [GHSA-47x8-96vw-5wg6](https://github.com/advisories/GHSA-47x8-96vw-5wg6)
- **Observation:** The `superset-frontend` npm dependency tree includes `vm2`, which has a known sandbox escape vulnerability allowing arbitrary code execution on the host. The package is no longer maintained. A fix exists by upgrading past 3.11.1, but the upstream package has been deprecated entirely.
- **Dependency chain:** `geostyler@18.5.0` → `typescript-json-schema@0.67.1` → `vm2@3.10.5`
- **Remediation:** Added npm override `"vm2": ">=3.11.2"` in `superset-frontend/package.json` to force resolution to 3.11.2, which is above the vulnerable range.

---

### 2. `eslint-plugin-i18n-strings` — Critical Advisory (Frontend)

- **Severity:** Critical
- **Package:** `eslint-plugin-i18n-strings` (all versions)
- **Advisory:** [GHSA-55h3-fm53-wq99](https://github.com/advisories/GHSA-55h3-fm53-wq99)
- **Observation:** All published versions of this ESLint plugin carry a critical advisory. No patched version is available. The package is a direct devDependency of `superset-frontend`.

---

### 3. `axios` — HTTP Request Vulnerabilities (Frontend)

- **Severity:** High
- **Package:** `axios` (1.0.0–1.15.1)
- **Advisories:** [GHSA-w9j2-pvgh-6h63](https://github.com/advisories/GHSA-w9j2-pvgh-6h63), [GHSA-pmwg-cvhr-8vh7](https://github.com/advisories/GHSA-pmwg-cvhr-8vh7)
- **Observation:** The version of `axios` used in `superset-frontend` falls within the affected range. These advisories cover SSRF and credential leakage vectors in HTTP request handling. A fix is available.
- **Dependency chain:** `wait-on@9.0.5` / `nx` / `jest-process-manager` → `axios@1.15.0` (all devDependencies)
- **Remediation:** Added npm override `"axios": ">=1.15.2"` in `superset-frontend/package.json` to force resolution to 1.16.0, which is above the vulnerable range.

---

### 4. `flask` — Session Cache Leak (Python Backend)

- **Severity:** High (contextual)
- **Package:** `flask` 2.3.3
- **CVE:** CVE-2026-27205 (fixed in 3.1.3)
- **Observation:** The pinned Flask version does not set the `Vary: Cookie` header when the session is accessed via the Python `in` operator. If the application sits behind a caching proxy that does not strip cookies, responses containing session-specific data may be served to other users from cache. The current pin (`==2.3.3`) is one major version behind the fix.

---

### 5. Helm Chart — All Pods Run as Root

- **Severity:** Critical
- **Location:** `helm/superset/values.yaml` line 36
- **Observation:** The default Helm values set `runAsUser: 0`, meaning every Superset pod (web server, Celery worker, Celery beat, init jobs) runs as the root user inside the container. Additionally:
  - `podSecurityContext` and `containerSecurityContext` are both empty (`{}`).
  - The default database password is hardcoded as `db_pass: superset`.
  - No resource limits are defined (`resources: {}`).
  - No NetworkPolicy templates exist in the chart.
