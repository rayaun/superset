/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

/**
 * Regression guard for security-driven npm overrides.
 *
 * If these tests fail, a vulnerable transitive dependency was reintroduced
 * either by relaxing the override in package.json or by an upstream package
 * pulling in an older version. Update the override (and this guard) only after
 * confirming the new floor is past the relevant advisory's patched version.
 */
import fs from 'fs';
import path from 'path';

type LockfilePackage = {
  version?: string;
};

type Lockfile = {
  packages?: Record<string, LockfilePackage>;
};

type PackageJson = {
  overrides?: Record<string, string>;
};

const FRONTEND_ROOT = path.resolve(__dirname, '..', '..');

const readJson = <T>(relPath: string): T =>
  JSON.parse(fs.readFileSync(path.join(FRONTEND_ROOT, relPath), 'utf-8')) as T;

const parseVersion = (version: string): [number, number, number] => {
  const [major, minor, patch] = version.split('.').map(part => {
    const n = Number.parseInt(part, 10);
    return Number.isFinite(n) ? n : 0;
  });
  return [major, minor, patch];
};

const compareVersions = (a: string, b: string): number => {
  const [aMajor, aMinor, aPatch] = parseVersion(a);
  const [bMajor, bMinor, bPatch] = parseVersion(b);
  if (aMajor !== bMajor) return aMajor - bMajor;
  if (aMinor !== bMinor) return aMinor - bMinor;
  return aPatch - bPatch;
};

const collectInstalledVersions = (
  lock: Lockfile,
  packageName: string,
): { pkgPath: string; version: string }[] => {
  const results: { pkgPath: string; version: string }[] = [];
  for (const [pkgPath, info] of Object.entries(lock.packages ?? {})) {
    const segments = pkgPath.split('node_modules/');
    if (segments.length > 1 && segments[segments.length - 1] === packageName) {
      const { version } = info;
      if (version) {
        results.push({ pkgPath, version });
      }
    }
  }
  return results;
};

test('package.json declares the GHSA-w9j2-pvgh-6h63 axios override', () => {
  const pkg = readJson<PackageJson>('package.json');
  const override = pkg.overrides?.axios;
  expect(override).toBeDefined();
  // Override must encode a floor at or above 1.12.0, the version that patches
  // GHSA-w9j2-pvgh-6h63 (axios DoS via crafted data: URL handling).
  expect(override).toMatch(/^(\^|~|>=)?1\.(1[2-9]|[2-9]\d)\.\d+/);
});

test('every installed axios entry is patched against GHSA-w9j2-pvgh-6h63', () => {
  const lock = readJson<Lockfile>('package-lock.json');
  const installs = collectInstalledVersions(lock, 'axios');
  expect(installs.length).toBeGreaterThan(0);
  for (const { pkgPath, version } of installs) {
    // axios 1.12.0 is the first version that fixes GHSA-w9j2-pvgh-6h63.
    // We require >= 1.12.0 (covers the patch) while still permitting future
    // 1.x and 2.x releases.
    const failureMessage = `Vulnerable axios version ${version} resolved at ${pkgPath}; bump override in package.json.`;
    expect({ pkgPath, version, failureMessage }).toEqual(
      expect.objectContaining({
        pkgPath,
        version: expect.any(String),
      }),
    );
    expect(compareVersions(version, '1.12.0')).toBeGreaterThanOrEqual(0);
  }
});

test('package.json declares the vm2 sandbox-escape override', () => {
  const pkg = readJson<PackageJson>('package.json');
  const override = pkg.overrides?.vm2;
  expect(override).toBeDefined();
  // vm2 3.11.2 is the first version that fixes GHSA-47x8-96vw-5wg6.
  expect(override).toMatch(
    /^(\^|~|>=)?3\.(11\.[2-9]|1[2-9]\.\d+|[2-9]\d\.\d+)/,
  );
});
