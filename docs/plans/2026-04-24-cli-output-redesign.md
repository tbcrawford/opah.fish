# CLI Output Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all emoji-based output in opah with a coherent Ocean-palette design system using geometric Unicode sigils, title-case section headers, and consistent spacing.

**Architecture:** Rewrite `_opah_ui.fish` first to establish the new primitives, then update each subcommand file to call them. Update smoke tests last to match new output text. No new files needed — this is a pure rewrite of existing output code.

**Tech Stack:** Fish shell, fishtape (test runner), `set_color` for terminal colors.

**Spec:** `docs/specs/2026-04-24-cli-output-redesign.md`

---

## File Map

| File | Change |
|---|---|
| `functions/_opah_ui.fish` | Full rewrite — new primitives, remove legacy functions |
| `functions/_opah_show_help.fish` | Full rewrite — new header + section layout |
| `functions/_opah_status.fish` | Update all output calls + section structure |
| `functions/_opah_doctor.fish` | Update all output calls + section structure |
| `functions/_opah_load.fish` | Update inline progress output |
| `functions/_opah_refresh.fish` | Update output calls |
| `functions/_opah_clear.fish` | Update output calls, remove `--quiet-footer` flag |
| `functions/_opah_config.fish` | Update all output calls + section structure |
| `functions/_opah_reinit.fish` | Update all output calls + step section structure |
| `functions/opah.fish` | Update unknown subcommand error message |
| `conf.d/opah.fish` | Update startup error output |
| `tests/test_ui.fish` | New — unit tests for `_opah_ui.fish` primitives |
| `tests/test_cli_smoke.fish` | Update string match patterns to new output text |

---

## Task 1: Rewrite `_opah_ui.fish`

**Files:**
- Modify: `functions/_opah_ui.fish`
- Create: `tests/test_ui.fish`

- [ ] **Step 1: Write the failing tests**

Create `tests/test_ui.fish`:

```fish
# Unit tests for _opah_ui.fish output primitives.
# Strips ANSI escape codes before asserting text content.

set repo_root (path dirname (status dirname))
set functions_dir "$repo_root/functions"

function run_ui -a script_body
    fish --no-config -C "set fish_function_path $functions_dir \$fish_function_path" \
        -c "$script_body" 2>&1 \
        | string replace --all --regex '\x1b\[[0-9;]*m' ''
end

@test "_opah_success prints bullet and message" \
    (run_ui '_opah_success "op is installed"') \
    = " ● op is installed"

@test "_opah_success prints detail line when provided" \
    (run_ui '_opah_success "op is installed" "version 2.26.1"' | string collect) \
    = " ● op is installed
     version 2.26.1"

@test "_opah_error prints X and message" \
    (run_ui '_opah_error "cache not found"') \
    = " ✕ cache not found"

@test "_opah_error prints detail line when provided" \
    (run_ui '_opah_error "cache not found" "run: opah refresh"' | string collect) \
    = " ✕ cache not found
     run: opah refresh"

@test "_opah_warning prints triangle and message" \
    (run_ui '_opah_warning "permissions should be 600"') \
    = " ▲ permissions should be 600"

@test "_opah_info prints diamond and message" \
    (run_ui '_opah_info "3 secrets defined"') \
    = " ◆ 3 secrets defined"

@test "_opah_section prints title with leading blank line" \
    (run_ui '_opah_section "Cache"' | string collect) \
    = "
Cache"

@test "_opah_hint prints indented dim text" \
    (run_ui '_opah_hint "run: opah refresh"') \
    = "     run: opah refresh"

@test "_opah_header prints opah and separator" \
    (run_ui '_opah_header' | string collect | string match -r 'opah') \
    = opah
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
just test tests/test_ui.fish
```

Expected: all tests fail — functions don't exist yet in new form.

- [ ] **Step 3: Rewrite `functions/_opah_ui.fish`**

```fish
#
# UI primitives for consistent output formatting.
#
# Defines the Ocean design system: four geometric sigils (● ✕ ▲ ◆),
# section headers, hint lines, and the brand header used only by
# the help screen. All emoji and legacy message types are removed.
#
# Color palette (set_color arguments):
#   brcyan --bold  brand accent, section headers
#   green          success sigil ●
#   red            error sigil ✕
#   yellow         warning sigil ▲
#   brcyan         info sigil ◆
#   normal --dim   detail text, hints, descriptions
#   brcyan --dim   help screen separator rule
#
function _opah_ui -d "Initialize UI color constants"
    set -g __OPAH_COLOR_SUCCESS (set_color green)
    set -g __OPAH_COLOR_ERROR (set_color red)
    set -g __OPAH_COLOR_WARNING (set_color yellow)
    set -g __OPAH_COLOR_INFO (set_color brcyan)
    set -g __OPAH_COLOR_DIM (set_color normal --dim)
    set -g __OPAH_COLOR_BOLD (set_color brcyan --bold)
    set -g __OPAH_COLOR_RESET (set_color normal)
    set -g __OPAH_COLOR_SEP (set_color brcyan --dim)
end

# Print success message with ● sigil.
#
# @param argv[1] Primary message
# @param argv[2] Optional detail line (printed indented and dim)
#
function _opah_success -d "Print success: ● msg [detail]"
    printf "%s ● %s%s\n" $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET "$argv[1]"
    if set -q argv[2]
        printf "%s     %s%s\n" $__OPAH_COLOR_DIM "$argv[2]" $__OPAH_COLOR_RESET
    end
end

# Print error message with ✕ sigil.
#
# @param argv[1] Primary message
# @param argv[2] Optional detail line
#
function _opah_error -d "Print error: ✕ msg [detail]"
    printf "%s ✕ %s%s\n" $__OPAH_COLOR_ERROR $__OPAH_COLOR_RESET "$argv[1]"
    if set -q argv[2]
        printf "%s     %s%s\n" $__OPAH_COLOR_DIM "$argv[2]" $__OPAH_COLOR_RESET
    end
end

# Print warning message with ▲ sigil.
#
# @param argv[1] Primary message
# @param argv[2] Optional detail line
#
function _opah_warning -d "Print warning: ▲ msg [detail]"
    printf "%s ▲ %s%s\n" $__OPAH_COLOR_WARNING $__OPAH_COLOR_RESET "$argv[1]"
    if set -q argv[2]
        printf "%s     %s%s\n" $__OPAH_COLOR_DIM "$argv[2]" $__OPAH_COLOR_RESET
    end
end

# Print info message with ◆ sigil.
# Also used for: security, process, file, and diagnostic messages (legacy types
# collapsed into this single info primitive).
#
# @param argv[1] Primary message
# @param argv[2] Optional detail line
#
function _opah_info -d "Print info: ◆ msg [detail]"
    printf "%s ◆ %s%s\n" $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET "$argv[1]"
    if set -q argv[2]
        printf "%s     %s%s\n" $__OPAH_COLOR_DIM "$argv[2]" $__OPAH_COLOR_RESET
    end
end

# Print a section header.
#
# Prints a blank line then the title in bold brcyan (title case expected from
# caller). One blank line between sections; none before the first section is
# acceptable as it adds visual breathing room after the shell prompt.
#
# @param argv Section title string (caller provides title case)
#
function _opah_section -d "Print section header: bold cyan title"
    printf "\n%s%s%s\n" $__OPAH_COLOR_BOLD "$argv" $__OPAH_COLOR_RESET
end

# Print a hint line (actionable suggestion).
#
# Indented 5 spaces (aligns under sigil message text). No sigil. Dim.
#
# @param argv Full hint string, e.g. "run: opah refresh to reload secrets"
#
function _opah_hint -d "Print hint: dim indented suggestion"
    printf "%s     %s%s\n" $__OPAH_COLOR_DIM "$argv" $__OPAH_COLOR_RESET
end

# Print the brand header and separator rule.
#
# Called ONLY from _opah_show_help. All other subcommands start output
# directly without a title or rule.
#
function _opah_header -d "Print brand header and separator (help screen only)"
    printf "%sopah%s  %s1password secrets manager%s\n" \
        $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "%s────────────────────────────%s\n" \
        $__OPAH_COLOR_SEP $__OPAH_COLOR_RESET
end

_opah_ui
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
just test tests/test_ui.fish
```

Expected: all 9 tests pass.

- [ ] **Step 5: Commit**

```bash
git add functions/_opah_ui.fish tests/test_ui.fish
git commit -m "feat: rewrite _opah_ui with Ocean design system primitives"
```

---

## Task 2: Rewrite `_opah_show_help.fish`

**Files:**
- Modify: `functions/_opah_show_help.fish`

- [ ] **Step 1: Rewrite the file**

```fish
#
# Display the main opah help screen.
#
# The help screen is the only place that renders the brand header and
# separator rule. All other subcommands start output directly without
# a title line. Section labels use title case.
#
function _opah_show_help -d "Display opah help screen"
    _opah_header

    _opah_section "Usage"
    printf "  %sopah%s %s<command>%s %s[options]%s\n" \
        $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET

    _opah_section "Commands"
    printf "  %sstatus    %s%sshow cached secrets%s\n" \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %srefresh   %s%spull secrets from 1password%s\n" \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %sclear     %s%sclear cache and env vars%s\n" \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %sconfig    %s%sshow and validate config%s\n" \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %sdoctor    %s%sdiagnose setup%s\n" \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %sreinit    %s%sre-initialize after auth changes%s\n" \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %shelp      %s%sshow this message%s\n" \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET

    _opah_section "Examples"
    printf "  %sopah status             # show all cached secrets%s\n" \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %sopah refresh            # pull all secrets%s\n" \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %sopah doctor             # run diagnostics%s\n" \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET

    printf "\n%s  run 'opah <command> --help' for details%s\n" \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
end
```

- [ ] **Step 2: Run smoke tests**

```bash
just test tests/test_cli_smoke.fish
```

Expected: "cli smoke: bare opah shows help" and "cli smoke: opah help shows help" will **fail** — the string match patterns look for `USAGE:` and `SUBCOMMANDS:` which no longer exist. All other tests unaffected. This is expected — smoke tests are updated in Task 12.

- [ ] **Step 3: Commit**

```bash
git add functions/_opah_show_help.fish
git commit -m "feat: rewrite help screen with Ocean design system"
```

---

## Task 3: Update `_opah_status.fish`

**Files:**
- Modify: `functions/_opah_status.fish`

- [ ] **Step 1: Rewrite the file**

```fish
#
# Display status of cached secrets and configuration.
#
function _opah_status -d "Show status of cached secrets"
    # --help
    if contains -- --help $argv; or contains -- -h $argv
        _opah_section "Usage"
        printf "  %sopah status%s %s[SECRET_NAME]%s\n" \
            $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        _opah_section "Arguments"
        printf "  %sSECRET_NAME%s  %sshow status for a specific secret (optional)%s\n" \
            $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        _opah_section "Examples"
        printf "  %sopah status              # show all cached secrets%s\n" \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        printf "  %sopah status API_KEY      # show status for API_KEY only%s\n" \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    set -l cache_file (_opah_get_cache_file)
    set -l filter_key $argv[1]

    if not test -f "$cache_file"
        _opah_error "cache file not found"
        _opah_hint "run: opah refresh to create cache"
        return 1
    end

    # Cache section
    _opah_section "Cache"
    set -l mod_time (command stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$cache_file" 2>/dev/null; or command stat -c "%y" "$cache_file" 2>/dev/null | string replace -r '\.[0-9]+ .*' '')
    _opah_info "last updated $mod_time"
    set -l perms (command stat -f "%OLp" "$cache_file" 2>/dev/null; or command stat -c "%a" "$cache_file" 2>/dev/null)
    if test "$perms" = 600
        _opah_info "permissions secure (600)"
    else
        _opah_warning "permissions $perms (should be 600)"
    end

    # Parse cached keys
    set -l cached_keys (string match -r "^set -gx ([A-Z_]+)" <"$cache_file" | string replace -r "^set -gx " "")

    # Secrets section
    _opah_section "Secrets"

    if test -n "$filter_key"
        # Single secret lookup
        if contains -- $filter_key $cached_keys
            if set -q $filter_key
                printf "  %s%-20s%s %scached · loaded%s\n" \
                    $__OPAH_COLOR_DIM $filter_key $__OPAH_COLOR_RESET \
                    $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET
            else
                printf "  %s%-20s%s %scached%s · %snot loaded%s\n" \
                    $__OPAH_COLOR_DIM $filter_key $__OPAH_COLOR_RESET \
                    $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET \
                    $__OPAH_COLOR_ERROR $__OPAH_COLOR_RESET
            end
        else
            _opah_error "$filter_key not found in cache"
            return 1
        end
    else
        # All secrets
        set -l loaded_count 0
        for key in $cached_keys
            if set -q $key
                printf "  %s%-20s%s %scached · loaded%s\n" \
                    $__OPAH_COLOR_DIM $key $__OPAH_COLOR_RESET \
                    $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET
                set loaded_count (math $loaded_count + 1)
            else
                printf "  %s%-20s%s %scached%s · %snot loaded%s\n" \
                    $__OPAH_COLOR_DIM $key $__OPAH_COLOR_RESET \
                    $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET \
                    $__OPAH_COLOR_ERROR $__OPAH_COLOR_RESET
            end
        end

        set -l total (count $cached_keys)

        # Summary section
        _opah_section "Summary"
        if test $loaded_count -eq $total
            _opah_success "$total of $total secrets loaded"
        else
            _opah_warning "$loaded_count of $total secrets loaded"
            _opah_hint "run: opah refresh to reload"
        end
    end
end
```

- [ ] **Step 2: Run smoke tests (status-related)**

```bash
just test tests/test_cli_smoke.fish
```

Expected: "cli smoke: opah status reports mocked secret" fails — pattern `'*Environment: Loaded*'` no longer matches. Expected for now; fixed in Task 12.

- [ ] **Step 3: Commit**

```bash
git add functions/_opah_status.fish
git commit -m "feat: update opah status with Ocean design system"
```

---

## Task 4: Update `_opah_doctor.fish`

**Files:**
- Modify: `functions/_opah_doctor.fish`

- [ ] **Step 1: Rewrite the file**

```fish
#
# Diagnose and validate the complete opah setup.
#
function _opah_doctor -d "Diagnose and validate complete setup"
    if contains -- --help $argv; or contains -- -h $argv
        _opah_section "Usage"
        printf "  %sopah doctor%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        _opah_section "Examples"
        printf "  %sopah doctor    # run comprehensive diagnostics%s\n" \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    set -l issues 0

    # ── 1Password CLI ────────────────────────────────────────────────────────
    _opah_section "1Password CLI"
    if command -q op
        set -l op_version (op --version 2>/dev/null)
        _opah_success "op is installed" "version $op_version"
    else
        _opah_error "op is not installed"
        _opah_hint "install from: https://developer.1password.com/docs/cli/get-started/"
        set issues (math $issues + 1)
    end

    # ── Authentication ───────────────────────────────────────────────────────
    _opah_section "Authentication"
    if command -q op
        set -l accounts (op account list --format=json 2>/dev/null)
        if test -n "$accounts"; and test "$accounts" != "[]"
            _opah_success "signed in to 1password"
            set -l emails (echo $accounts | string match -ra '"email":"[^"]*"' | string replace -ra '"email":"([^"]*)"' '$1' | string join ", ")
            if test -n "$emails"
                printf "%s     %s%s\n" $__OPAH_COLOR_DIM "$emails" $__OPAH_COLOR_RESET
            end
        else
            _opah_warning "not signed in to 1password"
            _opah_hint "run: op signin"
        end
    else
        _opah_info "skipped (op not installed)"
    end

    # ── Configuration ────────────────────────────────────────────────────────
    _opah_section "Configuration"
    set -l config_file (_opah_find_config)
    if test -n "$config_file"
        _opah_success "$config_file"
        set -l secret_count (string match -ra "op://" <"$config_file" | count)
        _opah_info "$secret_count secrets defined"
        # Check for non-1Password values
        set -l non_op (grep -v "op://" "$config_file" | grep -v "secrets:" | grep -v "^#" | grep -v "^$" | grep ":" | count 2>/dev/null; or echo 0)
        if test "$non_op" -gt 0
            _opah_warning "$non_op value(s) are not 1password references"
            set issues (math $issues + 1)
        end
    else
        _opah_error "no configuration file found"
        _opah_hint "create: ~/.config/fish/secrets.yaml"
        set issues (math $issues + 1)
    end

    # ── Cache ────────────────────────────────────────────────────────────────
    _opah_section "Cache"
    set -l cache_file (_opah_get_cache_file)
    set -l cache_dir (_opah_get_cache_dir)
    if test -d "$cache_dir"
        _opah_success "cache directory exists" "$cache_dir"
    else
        _opah_warning "cache directory missing (created automatically on refresh)"
    end

    if test -f "$cache_file"
        set -l mod_time (command stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$cache_file" 2>/dev/null; or command stat -c "%y" "$cache_file" 2>/dev/null | string replace -r '\.[0-9]+ .*' '')
        set -l secret_count (string match -ra "^set -gx" <"$cache_file" | count)
        _opah_success "cache file exists"
        printf "%s     last updated: %s%s\n" $__OPAH_COLOR_DIM "$mod_time" $__OPAH_COLOR_RESET
        printf "%s     cached secrets: %s%s\n" $__OPAH_COLOR_DIM "$secret_count" $__OPAH_COLOR_RESET
        set -l perms (command stat -f "%OLp" "$cache_file" 2>/dev/null; or command stat -c "%a" "$cache_file" 2>/dev/null)
        if test "$perms" = 600
            printf "%s     permissions: secure (600)%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        else
            _opah_warning "permissions $perms (should be 600)"
            _opah_hint "run: chmod 600 $cache_file"
            set issues (math $issues + 1)
        end
    else
        _opah_warning "cache file missing"
        _opah_hint "run: opah refresh to create cache"
    end

    # ── Fish Shell Integration ───────────────────────────────────────────────
    _opah_section "Fish Shell Integration"
    if functions -q opah; and functions -q _opah_load
        _opah_success "core functions are available"
    else
        _opah_error "core functions not loaded"
        set issues (math $issues + 1)
    end

    # ── Summary ──────────────────────────────────────────────────────────────
    _opah_section "Summary"
    if test $issues -eq 0
        _opah_success "all systems operational"
        _opah_hint "run: opah status to verify loaded secrets"
    else
        _opah_warning "$issues issue(s) detected"
        _opah_hint "address the items marked with ✕ or ▲ above"
    end
end
```

- [ ] **Step 2: Run smoke tests (doctor-related)**

```bash
just test tests/test_cli_smoke.fish
```

Expected: "cli smoke: opah doctor succeeds" fails — `'*All systems operational!*'` no longer matches. Expected for now.

- [ ] **Step 3: Commit**

```bash
git add functions/_opah_doctor.fish
git commit -m "feat: update opah doctor with Ocean design system"
```

---

## Task 5: Update `_opah_load.fish`

**Files:**
- Modify: `functions/_opah_load.fish`

The inline per-key progress pattern changes from:
- Before: `printf " %s" $key` then `printf " ✓\n"` or `printf " ✗\n"`
- After: `printf "  %-20s" $key` then `printf "%s ● %s\n"` or `printf "%s ✕ %s\n"`

- [ ] **Step 1: Update the inline progress output in `_opah_load.fish`**

Find all inline key-printing and result-printing code. Replace with:

```fish
# When printing a key being fetched (before result is known):
printf "  %s%-20s%s" $__OPAH_COLOR_DIM "$key" $__OPAH_COLOR_RESET

# On success (appended to same line):
printf "%s ● %s\n" $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET

# On failure (appended to same line):
printf "%s ✕ %s\n" $__OPAH_COLOR_ERROR $__OPAH_COLOR_RESET
```

Also replace all calls to `_opah_security`, `_opah_process`, `_opah_file`, `_opah_diagnostic` with `_opah_info`:

```fish
# Before:
_opah_security "Loading secrets from 1Password..."
_opah_process "Refreshing specific secret: $key"

# After:
_opah_info "Loading secrets from 1password..."
_opah_info "Refreshing secret: $key"
```

Replace all summary messages:

```fish
# Before:
_opah_success "Success! $count secrets loaded"
_opah_info "Partial success: $count/$total secrets loaded"
_opah_error "Failed: No secrets loaded"

# After:
_opah_success "$count secrets loaded"
_opah_warning "$count of $total secrets loaded"
_opah_error "no secrets loaded"
```

Replace all `_opah_hint` calls (old API was two args; new API is one string):

```fish
# Before:
_opah_hint "op signin" "to authenticate"
_opah_hint "Install from: https://..." ""

# After:
_opah_hint "run: op signin to authenticate"
_opah_hint "install from: https://developer.1password.com/docs/cli/get-started/"
```

- [ ] **Step 2: Run smoke tests (refresh-related)**

```bash
just test tests/test_cli_smoke.fish
```

Expected: "cli smoke: opah refresh succeeds" may fail on text match. Expected for now.

- [ ] **Step 3: Commit**

```bash
git add functions/_opah_load.fish
git commit -m "feat: update _opah_load inline progress with Ocean design system"
```

---

## Task 6: Update `_opah_refresh.fish`

**Files:**
- Modify: `functions/_opah_refresh.fish`

- [ ] **Step 1: Update output calls**

Replace the `--help` output block:

```fish
if contains -- --help $argv; or contains -- -h $argv
    _opah_section "Usage"
    printf "  %sopah refresh%s %s[SECRET_NAME]%s\n" \
        $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    _opah_section "Arguments"
    printf "  %sSECRET_NAME%s  %srefresh specific secret only (optional)%s\n" \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    _opah_section "Examples"
    printf "  %sopah refresh              # refresh all secrets%s\n" \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %sopah refresh DATABASE_URL # refresh DATABASE_URL only%s\n" \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    return 0
end
```

Replace `_opah_security "Refreshing specific secret: $key"` with `_opah_info "Refreshing secret: $key"`.

- [ ] **Step 2: Commit**

```bash
git add functions/_opah_refresh.fish
git commit -m "feat: update opah refresh with Ocean design system"
```

---

## Task 7: Update `_opah_clear.fish`

**Files:**
- Modify: `functions/_opah_clear.fish`

The `--quiet-footer` flag is removed (the new design doesn't have a "footer" — hint is inline). The `--help` block, all output calls, and `--quiet-footer` argument handling are updated.

- [ ] **Step 1: Rewrite the file**

Supports an internal `--quiet` flag (used by `opah reinit`) that suppresses the final summary line and hint.

```fish
#
# Clear cached secrets and environment variables.
#
# Flags:
#   --quiet    suppress final summary and hint (used internally by opah reinit)
#
function _opah_clear -d "Clear cached secrets and environment variables"
    if contains -- --help $argv; or contains -- -h $argv
        _opah_section "Usage"
        printf "  %sopah clear%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        _opah_section "Examples"
        printf "  %sopah clear    # clear all cached secrets and env vars%s\n" \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    set -l quiet 0
    if contains -- --quiet $argv
        set quiet 1
    end

    set -l cache_file (_opah_get_cache_file)

    # Unset environment variables
    if test -f "$cache_file"
        set -l keys (string match -ra "set -gx ([A-Z_]+)" <"$cache_file" | string replace -ra "set -gx ([A-Z_]+).*" '$1')
        for key in $keys
            set -e $key 2>/dev/null
            _opah_info "unset $key"
        end
    end

    # Remove cache file
    if test -f "$cache_file"
        rm -f "$cache_file"
        _opah_success "cache file removed"
    else
        _opah_info "no cache file found"
    end

    if test $quiet -eq 0
        _opah_success "secrets cleared"
        _opah_hint "run: opah refresh to reload secrets from 1password"
    end
end
```

- [ ] **Step 2: Commit**

```bash
git add functions/_opah_clear.fish
git commit -m "feat: update opah clear with Ocean design system"
```

---

## Task 8: Update `_opah_config.fish`

**Files:**
- Modify: `functions/_opah_config.fish`

- [ ] **Step 1: Update all output calls**

Replace the `--help` block:

```fish
if contains -- --help $argv; or contains -- -h $argv
    _opah_section "Usage"
    printf "  %sopah config%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
    _opah_section "Examples"
    printf "  %sopah config    # show config file info and validate format%s\n" \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    return 0
end
```

Replace section/output structure. The three existing logical sections map to:

```fish
_opah_section "Locations"
# per-path:
_opah_success "$path"           # found
_opah_error "$path"             # not found

_opah_section "Validation"
# per-key:
_opah_success "$key: $value"    # valid op:// reference
_opah_warning "$key: $value"    # not a 1password reference

_opah_section "Summary"
_opah_success "configuration valid" "$count secret(s) defined"
# or:
_opah_error "invalid configuration"
```

Replace `_opah_file "Active configuration file: $path"` with `_opah_info "active config: $path"`.

Replace `_opah_info "Last modified: $time"` with `_opah_info "last modified: $time"`.

Remove the inline YAML example block that was shown when no config was found — replace with:

```fish
_opah_error "no configuration file found"
_opah_hint "create: ~/.config/fish/secrets.yaml"
_opah_hint "format: secrets:\\n  API_KEY: \"op://vault/item/field\""
```

- [ ] **Step 2: Commit**

```bash
git add functions/_opah_config.fish
git commit -m "feat: update opah config with Ocean design system"
```

---

## Task 9: Update `_opah_reinit.fish`

**Files:**
- Modify: `functions/_opah_reinit.fish`

- [ ] **Step 1: Rewrite the file**

```fish
#
# Re-initialize the plugin after authentication changes.
# Clears cache, verifies auth, and reloads all secrets.
#
function _opah_reinit -d "Re-initialize plugin after authentication changes"
    if contains -- --help $argv; or contains -- -h $argv
        _opah_section "Usage"
        printf "  %sopah reinit%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        _opah_section "Examples"
        printf "  %sopah reinit    # clear cache and reload all secrets%s\n" \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    # Step 1: Clear Cache
    _opah_section "Step 1  Clear Cache"
    _opah_clear --quiet 2>/dev/null
    or begin
        # _opah_clear handles its own output; just proceed
        true
    end

    # Step 2: Authenticate
    _opah_section "Step 2  Authenticate"
    if command -q op
        set -l accounts (op account list --format=json 2>/dev/null)
        if test -n "$accounts"; and test "$accounts" != "[]"
            _opah_success "already signed in"
        else
            _opah_info "signing in to 1password..."
            if not op signin 2>/dev/null
                _opah_error "could not sign in to 1password"
                _opah_hint "run: op signin manually then retry opah reinit"
                return 1
            end
            _opah_success "signed in"
        end
    else
        _opah_error "op is not installed"
        _opah_hint "install from: https://developer.1password.com/docs/cli/get-started/"
        return 1
    end

    # Step 3: Load Secrets
    _opah_section "Step 3  Load Secrets"
    if not _opah_load --force
        _opah_error "could not reload secrets"
        _opah_hint "run: opah doctor to diagnose"
        return 1
    end

    _opah_section "Summary"
    _opah_success "reinitialization complete"
    _opah_hint "run: opah status to verify loaded secrets"
end
```

- [ ] **Step 2: Commit**

```bash
git add functions/_opah_reinit.fish
git commit -m "feat: update opah reinit with Ocean design system step headers"
```

---

## Task 10: Update `conf.d/opah.fish`

**Files:**
- Modify: `conf.d/opah.fish`

The startup error block currently uses emoji and inline color codes. Replace with `_opah_ui` primitives.

- [ ] **Step 1: Read the current startup error block**

Open `conf.d/opah.fish` and find the error output block (around line 25-31). It will look like:

```fish
printf "%s✗ Failed to load 1Password secrets%s\n" (set_color --bold) (set_color normal) >&2
printf "  %s⚠ Some functionality may be limited...%s\n" (set_color brblack) (set_color normal) >&2
printf "  %s💡 Run 'opah status' to check configuration%s\n" (set_color --dim) (set_color normal) >&2
```

- [ ] **Step 2: Replace with new primitives**

Replace the error block with:

```fish
_opah_error "failed to load 1password secrets" >&2
_opah_hint "run: opah status to check configuration" >&2
```

Note: `_opah_error` and `_opah_hint` write to stdout by default. Redirecting to stderr here preserves the startup-error behavior of the original code.

- [ ] **Step 3: Commit**

```bash
git add conf.d/opah.fish
git commit -m "feat: update startup error output with Ocean design system"
```

---

## Task 11: Update `opah.fish`

**Files:**
- Modify: `functions/opah.fish`

- [ ] **Step 1: Update the unknown subcommand error message**

Find the fallback case in `opah.fish` (around line 38-40):

```fish
_opah_error "Unknown subcommand: $subcommand"
_opah_hint "opah help" "for usage information"
```

Replace with:

```fish
_opah_error "unknown command: $subcommand"
_opah_hint "run: opah help for usage information"
```

- [ ] **Step 2: Commit**

```bash
git add functions/opah.fish
git commit -m "feat: update opah dispatch error with Ocean design system"
```

---

## Task 12: Update Smoke Tests

**Files:**
- Modify: `tests/test_cli_smoke.fish`

The smoke tests use `string match -q '*OLD_TEXT*'` patterns that reference the old output. Update each to match the new output text.

- [ ] **Step 1: Update all string match patterns**

Replace the entire `tests/test_cli_smoke.fish` match patterns:

```fish
# test: bare opah shows help
# OLD: string match -q '*USAGE:*' and '*SUBCOMMANDS:*'
# NEW:
if string match -q '*Usage*' -- $output; and string match -q '*Commands*' -- $output
    echo ok
end

# test: opah help shows help without unknown commands
# OLD: string match -q '*SUBCOMMANDS:*'
# NEW:
if string match -q '*Unknown command*' -- $output
    echo bad
else if string match -q '*Commands*' -- $output
    echo ok
end

# test: opah config validates temp config
# OLD: string match -q '*Success! Configuration valid*'
# NEW:
if string match -q '*configuration valid*' -- $output; and string match -q "*$config_file*" -- $output
    echo ok
end

# test: opah refresh succeeds
# OLD: string match -q '*Success! 2 secrets loaded*'
# NEW:
if string match -q '*2 secrets loaded*' -- $output; and test -f "$cache_file"
    echo ok
end

# test: opah status reports secret
# OLD: string match -q "*Secret '*" and '*Environment: Loaded*'
# NEW:
if string match -q '*cached*' -- $output; and string match -q '*loaded*' -- $output
    echo ok
end

# test: opah clear removes cache
# OLD: string match -q '*Success! Secrets cleared*'
# NEW:
if string match -q '*secrets cleared*' -- $output; and string match -q '*cache-missing*' -- $output
    echo ok
end

# test: opah doctor succeeds
# OLD: string match -q '*All systems operational!*'
# NEW:
if string match -q '*doctor-ok*' -- $output; and string match -q '*all systems operational*' -- $output
    echo ok
end
```

- [ ] **Step 2: Run the full test suite**

```bash
just test
```

Expected: all tests pass.

- [ ] **Step 3: Run lint**

```bash
just lint
```

Expected: no syntax or indent errors.

- [ ] **Step 4: Commit**

```bash
git add tests/test_cli_smoke.fish
git commit -m "test: update smoke tests for Ocean design system output"
```

---

## Task 13: Final Verification

- [ ] **Step 1: Run the full test suite one final time**

```bash
just test
```

Expected: all tests pass with no failures.

- [ ] **Step 2: Run lint**

```bash
just lint
```

Expected: `All files OK`.

- [ ] **Step 3: Manual spot-check**

```bash
just install local
opah help
opah doctor
opah status
```

Visually verify the output matches the approved design from `docs/specs/2026-04-24-cli-output-redesign.md`.

- [ ] **Step 4: Push**

```bash
git push
```
