# CI and Release System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add GitHub Actions CI for lint and tests, plus tag-driven GitHub Releases with attached source archives.

**Architecture:** Keep automation thin and repo-local. Add one CI workflow and one release workflow, then guard them with a Fish-based workflow regression test file so workflow intent stays enforced in version control.

**Tech Stack:** GitHub Actions, Fish shell, `just`, `fishtape`, Ruby YAML parsing, Git archives

---

## File Structure

- Create: `.github/workflows/ci.yml`
  - Push and pull request validation workflow.
- Create: `.github/workflows/release.yml`
  - Tag-driven release workflow that reruns project verification and publishes archives.
- Create: `tests/test_workflows.fish`
  - Regression tests that assert workflow files exist, parse as YAML, and contain required commands and triggers.
- Modify: `README.md`
  - Document CI expectations and the tag-driven release flow for maintainers.

## Task 1: Add CI Workflow Regression Tests And Implement `ci.yml`

**Files:**
- Create: `tests/test_workflows.fish`
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Write the failing test for the CI workflow**

Add this initial test file:

```fish
# Tests for GitHub workflow files

set repo_root (path dirname (status dirname))
set ci_workflow "$repo_root/.github/workflows/ci.yml"
set release_workflow "$repo_root/.github/workflows/release.yml"

function workflow_text -a file
    string collect < "$file"
end

@test "workflow: ci.yml exists" \
    -f "$ci_workflow"

@test "workflow: ci.yml parses as YAML" \
    (ruby -e 'require "yaml"; YAML.load_file(ARGV[0])' "$ci_workflow" >/dev/null 2>&1; echo $status) -eq 0

@test "workflow: ci.yml runs just lint and just test" \
    (begin
        set -l text (workflow_text "$ci_workflow")
        string match -q '*just lint*' -- $text
        and string match -q '*just test*' -- $text
        echo $status
    end) -eq 0

@test "workflow: ci.yml includes push and pull_request triggers" \
    (begin
        set -l text (workflow_text "$ci_workflow")
        string match -q '*pull_request:*' -- $text
        and string match -q '*push:*' -- $text
        echo $status
    end) -eq 0
```

- [ ] **Step 2: Run the new workflow test to verify it fails**

Run:

```bash
just test-one tests/test_workflows.fish
```

Expected:

```text
not ok 1 workflow: ci.yml exists
```

- [ ] **Step 3: Write the minimal CI workflow**

Create `.github/workflows/ci.yml` with this content:

```yaml
name: CI

on:
  push:
  pull_request:

concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  verify:
    runs-on: ubuntu-latest

    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Install Fish
        run: |
          sudo apt-get update
          sudo apt-get install -y fish

      - name: Install just
        uses: extractions/setup-just@v2

      - name: Install fishtape
        shell: fish
        run: |
          curl -sL https://git.io/fisher | source
          fisher install jorgebucaran/fishtape

      - name: Run lint
        shell: fish
        run: just lint

      - name: Run tests
        shell: fish
        run: just test
```

- [ ] **Step 4: Run the workflow regression test to verify it passes**

Run:

```bash
just test-one tests/test_workflows.fish
```

Expected:

```text
ok 1 workflow: ci.yml exists
ok 2 workflow: ci.yml parses as YAML
ok 3 workflow: ci.yml runs just lint and just test
ok 4 workflow: ci.yml includes push and pull_request triggers
```

- [ ] **Step 5: Commit the CI workflow work**

Run:

```bash
git add .github/workflows/ci.yml tests/test_workflows.fish
git commit -m "ci: add GitHub Actions validation workflow"
```

## Task 2: Extend Workflow Tests And Implement `release.yml`

**Files:**
- Modify: `tests/test_workflows.fish`
- Create: `.github/workflows/release.yml`

- [ ] **Step 1: Extend the workflow test file with failing release checks**

Append these tests to `tests/test_workflows.fish`:

```fish
@test "workflow: release.yml exists" \
    -f "$release_workflow"

@test "workflow: release.yml parses as YAML" \
    (ruby -e 'require "yaml"; YAML.load_file(ARGV[0])' "$release_workflow" >/dev/null 2>&1; echo $status) -eq 0

@test "workflow: release.yml triggers on v tags" \
    (begin
        set -l text (workflow_text "$release_workflow")
        string match -q "*tags:*" -- $text
        and string match -q "*'v*'*" -- $text
        echo $status
    end) -eq 0

@test "workflow: release.yml runs just ci before publishing" \
    (begin
        set -l text (workflow_text "$release_workflow")
        string match -q '*just ci*' -- $text
        and string match -q '*contents: write*' -- $text
        echo $status
    end) -eq 0

@test "workflow: release.yml publishes tar.gz and zip artifacts" \
    (begin
        set -l text (workflow_text "$release_workflow")
        string match -q '*.tar.gz*' -- $text
        and string match -q '*.zip*' -- $text
        and string match -q '*softprops/action-gh-release@v2*' -- $text
        echo $status
    end) -eq 0
```

- [ ] **Step 2: Run the workflow test file to verify the new release checks fail**

Run:

```bash
just test-one tests/test_workflows.fish
```

Expected:

```text
not ok 5 workflow: release.yml exists
```

- [ ] **Step 3: Write the minimal release workflow**

Create `.github/workflows/release.yml` with this content:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest

    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Install Fish
        run: |
          sudo apt-get update
          sudo apt-get install -y fish

      - name: Install just
        uses: extractions/setup-just@v2

      - name: Install fishtape
        shell: fish
        run: |
          curl -sL https://git.io/fisher | source
          fisher install jorgebucaran/fishtape

      - name: Run CI checks
        shell: fish
        run: just ci

      - name: Create release archives
        run: |
          mkdir -p dist
          git archive --format=tar.gz --prefix="opah.fish-${GITHUB_REF_NAME}/" -o "dist/opah.fish-${GITHUB_REF_NAME}.tar.gz" HEAD
          git archive --format=zip --prefix="opah.fish-${GITHUB_REF_NAME}/" -o "dist/opah.fish-${GITHUB_REF_NAME}.zip" HEAD

      - name: Publish GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
          files: |
            dist/*.tar.gz
            dist/*.zip
```

- [ ] **Step 4: Run the workflow regression test file to verify it passes**

Run:

```bash
just test-one tests/test_workflows.fish
```

Expected:

```text
ok 5 workflow: release.yml exists
ok 6 workflow: release.yml parses as YAML
ok 7 workflow: release.yml triggers on v tags
ok 8 workflow: release.yml runs just ci before publishing
ok 9 workflow: release.yml publishes tar.gz and zip artifacts
```

- [ ] **Step 5: Commit the release workflow work**

Run:

```bash
git add .github/workflows/release.yml tests/test_workflows.fish
git commit -m "release: add tag-driven GitHub release workflow"
```

## Task 3: Document Contributor-Facing CI And Release Flow

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add a short contributor section to README**

Insert a new section near the end of `README.md`:

```md
## CI and Releases

### Continuous Integration

GitHub Actions validates this project on pushes and pull requests by running:

```fish
just lint
just test
```

The test suite uses mocked `op` behavior, so CI does not require access to a real 1Password vault.

### Cutting a Release

Releases are tag-driven.

1. Merge release-ready changes to `main`.
2. Create and push a semantic version tag such as `v0.1.0`.
3. GitHub Actions will run the release workflow.
4. The workflow reruns `just ci`, creates `.tar.gz` and `.zip` source archives, and publishes a GitHub Release with autogenerated notes.
```

- [ ] **Step 2: Verify the README contains the new release documentation**

Run:

```bash
grep -n "CI and Releases" README.md
```

Expected:

```text
<line-number>:## CI and Releases
```

- [ ] **Step 3: Run the full repo verification after workflow and README changes**

Run:

```bash
just ci
```

Expected:

```text
All files OK
...
# ok
```

- [ ] **Step 4: Commit the documentation update**

Run:

```bash
git add README.md
git commit -m "docs: describe CI checks and release flow"
```

## Task 4: Final Release-System Verification

**Files:**
- Modify: `.github/workflows/ci.yml` (only if verification reveals issues)
- Modify: `.github/workflows/release.yml` (only if verification reveals issues)
- Modify: `tests/test_workflows.fish` (only if verification reveals issues)

- [ ] **Step 1: Re-run the workflow regression tests in isolation**

Run:

```bash
just test-one tests/test_workflows.fish
```

Expected:

```text
1..9
# pass 9
# ok
```

- [ ] **Step 2: Re-run the full repository verification**

Run:

```bash
just ci
```

Expected:

```text
All files OK
...
# ok
```

- [ ] **Step 3: Inspect the final workflow diff before handing off**

Run:

```bash
git diff -- .github/workflows tests/test_workflows.fish README.md
```

Expected:

```text
diff --git a/.github/workflows/ci.yml b/.github/workflows/ci.yml
diff --git a/.github/workflows/release.yml b/.github/workflows/release.yml
diff --git a/tests/test_workflows.fish b/tests/test_workflows.fish
```

- [ ] **Step 4: Create the final integration commit**

Run:

```bash
git add .github/workflows/ci.yml .github/workflows/release.yml tests/test_workflows.fish README.md
git commit -m "ci: add automated validation and tagged releases"
```

## Spec Coverage Check

- CI on push and pull request: covered in Task 1.
- Tag-driven GitHub Release on `v*`: covered in Task 2.
- Re-run project verification before release: covered in Task 2.
- Attach `.tar.gz` and `.zip` artifacts: covered in Task 2.
- No 1Password secrets required in CI: covered by reuse of mocked tests in Tasks 1 and 2 and documented in Task 3.

## Self-Review Notes

- No placeholders remain.
- Workflow file paths are exact.
- Commands and expected outputs are concrete.
- The plan stays within the approved scope and avoids external registry publishing or changelog automation.
