# 1Password Secrets Fish Plugin - Logging Standardization Plan

## Overview

This document outlines a comprehensive plan to standardize logging output across the 1Password Secrets Fish plugin, addressing inconsistencies in spacing, coloring, unicode/emojis, and message formatting.

## Design Principles

### 1. Semantic Color System
- **Green**: Success states, positive confirmations
- **Red**: Errors, failures, critical issues
- **Yellow**: Warnings, partial success, attention needed
- **Blue/Cyan**: Informational headers, section dividers
- **Dim/Gray**: Secondary information, file paths, timestamps
- **Bold**: Important status messages, headers

### 2. Consistent Icon System
- **✓**: Success/completion
- **✗**: Error/failure
- **⚠**: Warning/attention needed
- **ℹ**: Information/status
- **🔐**: Security/secrets related
- **🔄**: Process/loading
- **📁**: Files/configuration
- **🔍**: Diagnostics/checking

### 3. Spacing Standards
- **Double newline** (`\n\n`): Between major sections
- **Single newline** (`\n`): Between related items
- **2-space indentation**: For nested items and sub-information
- **4-space indentation**: For code examples and file content

### 4. Message Format Standards
- **Status messages**: `[ICON] [Message]`
- **File references**: Always in dim color
- **Commands/examples**: Always in dim color with consistent indentation
- **Section headers**: Bold with consistent casing
- **Variables**: Bold when referencing user input
- **Next action hints**: Always preceded by single newline, no indentation, dim color

### 5. Next Action Hints Standard

**Format**: `Run 'command' description`
**Spacing**: Single newline before hint, no indentation
**Color**: Dim/gray color for entire hint line
**Usage**: Only for immediate next steps user should take

**Examples**:
- `Run 'secrets refresh' to create cache`
- `Run 'op signin' to authenticate`
- `Run 'secrets status' to verify loaded secrets`

**Implementation**:
```fish
function _secrets_hint
    printf "\n%sRun '%s' %s%s\n" $__SECRETS_COLOR_DIM "$argv[1]" "$argv[2..]" $__SECRETS_COLOR_RESET
end
```

### Phase 1: Create Shared Utility Functions

Create `functions/_secrets_ui.fish` with standardized formatting functions:

```fish
# Color and style constants
set -g __SECRETS_COLOR_SUCCESS (set_color green)
set -g __SECRETS_COLOR_ERROR (set_color red)
set -g __SECRETS_COLOR_WARNING (set_color yellow)
set -g __SECRETS_COLOR_INFO (set_color cyan)
set -g __SECRETS_COLOR_DIM (set_color --dim)
set -g __SECRETS_COLOR_BOLD (set_color --bold)
set -g __SECRETS_COLOR_RESET (set_color normal)

# Standard formatting functions
function _secrets_success
    printf "%s✓%s %s\n" $__SECRETS_COLOR_SUCCESS $__SECRETS_COLOR_RESET "$argv"
end

function _secrets_error
    printf "%s✗%s %s\n" $__SECRETS_COLOR_ERROR $__SECRETS_COLOR_RESET "$argv"
end

function _secrets_warning
    printf "%s⚠%s %s\n" $__SECRETS_COLOR_WARNING $__SECRETS_COLOR_RESET "$argv"
end

function _secrets_info
    printf "%sℹ%s %s\n" $__SECRETS_COLOR_INFO $__SECRETS_COLOR_RESET "$argv"
end

function _secrets_hint
    printf "\n%sRun '%s' %s%s\n" $__SECRETS_COLOR_DIM "$argv[1]" "$argv[2..]" $__SECRETS_COLOR_RESET
end
```

### 5. Next Action Hints Standard

**Format**: `Run 'command' description`
**Spacing**: Single newline before hint, no indentation  
**Color**: Dim/gray color for entire hint line
**Usage**: Only for immediate next steps user should take

**Examples**:
- `Run 'secrets refresh' to create cache`
- `Run 'op signin' to authenticate` 
- `Run 'secrets status' to verify loaded secrets`

**Implementation**: Use the `_secrets_hint` function shown above

### Phase 2: Standardize Each Command

## Standardized Help Output

### Main Command Help (`secrets help`)

```
🔐 1Password Secrets Management CLI

USAGE:
    secrets <SUBCOMMAND> [OPTIONS]

SUBCOMMANDS:
    clear      Clear cached secrets and environment variables
    config     Show configuration file information and validate format
    doctor     Diagnose and validate complete setup
    refresh    Refresh secrets from 1Password
    reinit     Re-initialize plugin after authentication changes
    status     Show status of cached secrets and configuration
    help       Show this help message

EXAMPLES:
    secrets status               # Show all cached secrets status
    secrets refresh              # Refresh all secrets from 1Password
    secrets clear                # Clear all cached secrets
    secrets doctor               # Run comprehensive diagnostics

For detailed help on a subcommand, use: secrets <SUBCOMMAND> --help
```

### Status Command Help (`secrets status --help`)

```
Show status of cached secrets and configuration

USAGE:
    secrets status [SECRET_NAME]

ARGUMENTS:
    SECRET_NAME    Show status for specific secret (optional)

EXAMPLES:
    secrets status              # Show all secrets status
    secrets status API_KEY      # Show status for API_KEY only
```

### Refresh Command Help (`secrets refresh --help`)

```
Refresh secrets from 1Password

USAGE:
    secrets refresh [SECRET_NAME]

ARGUMENTS:
    SECRET_NAME    Refresh specific secret only (optional)

EXAMPLES:
    secrets refresh              # Refresh all secrets
    secrets refresh DATABASE_URL # Refresh DATABASE_URL only
```

### Clear Command Help (`secrets clear --help`)

```
Clear cached secrets and environment variables

USAGE:
    secrets clear [OPTIONS]

OPTIONS:
    -h, --help            Show this help message
    -q, --quiet-footer    Skip the footer help message

EXAMPLES:
    secrets clear                # Clear all cached secrets
    secrets clear --quiet-footer # Clear without showing footer
```

### Config Command Help (`secrets config --help`)

```
Show configuration file information and validate format

USAGE:
    secrets config

EXAMPLES:
    secrets config    # Show config file info and validate format
```

### Doctor Command Help (`secrets doctor --help`)

```
Diagnose and validate complete setup

USAGE:
    secrets doctor

EXAMPLES:
    secrets doctor    # Run comprehensive diagnostics
```

### Reinit Command Help (`secrets reinit --help`)

```
Re-initialize plugin after authentication changes

USAGE:
    secrets reinit

EXAMPLES:
    secrets reinit    # Clear cache and reload all secrets
```

## Standardized Command Output Examples

### `secrets status` (All secrets)

```
📁 Cache file: /Users/user/.cache/fish/1password-secrets/secrets.fish
ℹ Last updated: Dec 25 10:30:42 2024

ℹ Cached secrets: 3

Cached secrets:
  API_KEY: ✓ Cached & Loaded
  DATABASE_URL: ✓ Cached & Loaded  
  GITHUB_TOKEN: ✓ Cached, ✗ Not loaded
```

### `secrets status API_KEY` (Specific secret)

```
📁 Cache file: /Users/user/.cache/fish/1password-secrets/secrets.fish
ℹ Last updated: Dec 25 10:30:42 2024

✓ Secret 'API_KEY': Cached
✓ Environment: Loaded
```

### `secrets status` (No cache)

```
✗ Cache file: Not found

Run 'secrets refresh' to create cache
```

### `secrets refresh` (All secrets)

```
🔐 Loading secrets from 1Password...
  API_KEY ✓
  DATABASE_URL ✓
  GITHUB_TOKEN ✓

✓ Success! 3 secrets loaded
```

### `secrets refresh API_KEY` (Specific secret)

```
🔐 Refreshing specific secret: API_KEY
  API_KEY ✓

✓ Success! API_KEY refreshed
```

### `secrets clear`

```
🔄 Clearing cached secrets...

  Unsetting environment variables...
    API_KEY ✓
    DATABASE_URL ✓
    GITHUB_TOKEN ✓

  Removing cache file...
    ✓ Cache file removed: /Users/user/.cache/fish/1password-secrets/secrets.fish

✓ Success! Secrets cleared

Run 'secrets refresh' to reload secrets from 1Password
```

### `secrets config` (Valid configuration)

```
Checking configuration file locations:
  ✓ /Users/user/.config/fish/secrets.yaml (FOUND)
  ✗ /Users/user/.config/fish/secrets.yml
  ✗ /Users/user/.config/fish/.secrets.yaml
  ✗ /Users/user/.config/fish/.secrets.yml
  ✗ /Users/user/.config/1password-secrets/secrets.yaml
  ✗ /Users/user/.config/1password-secrets/secrets.yml

📁 Active configuration file: /Users/user/.config/fish/secrets.yaml
ℹ Last modified: Dec 25 10:25:15 2024

Configuration validation:
  ✓ API_KEY: op://vault/Development/API Keys/api_key
  ✓ DATABASE_URL: op://vault/Development/Database/connection_string
  ⚠ GITHUB_TOKEN: not-a-1password-reference (not a 1Password reference)

✓ Success! Configuration valid
ℹ Found 3 secret(s) defined
```

### `secrets config` (No configuration)

```
Checking configuration file locations:
  ✗ /Users/user/.config/fish/secrets.yaml
  ✗ /Users/user/.config/fish/secrets.yml
  ✗ /Users/user/.config/fish/.secrets.yaml
  ✗ /Users/user/.config/fish/.secrets.yml
  ✗ /Users/user/.config/1password-secrets/secrets.yaml
  ✗ /Users/user/.config/1password-secrets/secrets.yml

✗ Error: No configuration file found!

Create a secrets configuration file at one of these locations:
  /Users/user/.config/fish/secrets.yaml (recommended)

Example format:
    secrets:
      API_KEY: "op://vault/MyVault/API Keys/api_key"
      DATABASE_URL: "op://vault/MyVault/Database/connection_string"
```

### `secrets doctor` (All good)

```
🔍 Checking 1Password CLI...
  ✓ 1Password CLI (op) is installed
    Version: 2.21.0

🔍 Checking 1Password authentication...
  ✓ Signed in to 1Password
    Accounts: user@example.com

🔍 Checking configuration file...
  ✓ Configuration file found: /Users/user/.config/fish/secrets.yaml
    Format: Valid YAML with secrets section
    1Password references: 3

🔍 Checking cache system...
  ✓ Cache directory exists: /Users/user/.cache/fish/1password-secrets
  ✓ Cache file exists: /Users/user/.cache/fish/1password-secrets/secrets.fish
    Last updated: Dec 25 10:30:42 2024
    Cached secrets: 3

🔍 Checking Fish shell integration...
  ✓ Running from functions directory
  ✓ Core functions are available

📋 Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ All systems operational!

Next steps:
  Run 'secrets refresh' to load secrets from 1Password
  Run 'secrets status' to verify loaded secrets
```

### `secrets doctor` (Issues detected)

```
🔍 Checking 1Password CLI...
  ✗ 1Password CLI (op) is not installed
    Install from: https://developer.1password.com/docs/cli/get-started/

🔍 Checking 1Password authentication...
  ⚠ Not signed in to 1Password
    Run: op signin
    (This will be done automatically when refreshing secrets)

🔍 Checking configuration file...
  ✗ No configuration file found
    Create: /Users/user/.config/fish/secrets.yaml

🔍 Checking cache system...
  ⚠ Cache directory missing (will be created automatically)
  ⚠ Cache file missing (run 'secrets refresh' to create)

🔍 Checking Fish shell integration...
  ✓ Running from functions directory
  ✓ Core functions are available

📋 Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠ Some issues detected. Please address the items marked with ✗ above.

Common fixes:
  Install 1Password CLI: brew install 1password-cli
  Create config file: touch /Users/user/.config/fish/secrets.yaml
  Sign in to 1Password: op signin
```

### `secrets reinit`

```
📍 Step 1: Clearing existing cache and environment variables...

🔄 Clearing cached secrets...

  Unsetting environment variables...
    API_KEY ✓
    DATABASE_URL ✓

  Removing cache file...
    ✓ Cache file removed: /Users/user/.cache/fish/1password-secrets/secrets.fish

✓ Success! Secrets cleared

📍 Step 2: Checking 1Password authentication...

✓ Already signed in to 1Password

📍 Step 3: Reloading secrets from configuration...

🔐 Loading secrets from 1Password...
  API_KEY ✓
  DATABASE_URL ✓

✓ Success! 2 secrets loaded

Run 'secrets status' to verify loaded secrets
```

## Error Output Examples

### Authentication Error

```
✗ Not signed in to 1Password

Run 'op signin' to authenticate
```

### Missing Configuration

```
✗ No secrets configuration found
  Expected locations:
  /Users/user/.config/fish/secrets.yaml
  /Users/user/.config/fish/secrets.yml
  /Users/user/.config/fish/.secrets.yaml
  /Users/user/.config/fish/.secrets.yml
  /Users/user/.config/1password-secrets/secrets.yaml
  /Users/user/.config/1password-secrets/secrets.yml
```

### 1Password CLI Not Found

```
✗ 1Password CLI not found

Install from: https://developer.1password.com/docs/cli/get-started/
```

### Secret Not Found

```
✗ Failed: Secret 'INVALID_KEY' not found in configuration
```

### Partial Success

```
🔐 Loading secrets from 1Password...
  API_KEY ✓
  DATABASE_URL ✗
  GITHUB_TOKEN ✓

ℹ Partial success: 2/3 secrets loaded

Warning: Failed to fetch from op://vault/Dev/Database/url
```

## Implementation Timeline

### Phase 1: Foundation (Week 1)
- Create `_secrets_ui.fish` utility functions
- Define color and icon constants
- Create shared formatting functions

### Phase 2: Core Commands (Week 2)
- Update `secrets.fish` main command
- Standardize `_secrets_status.fish`
- Standardize `_secrets_refresh.fish`

### Phase 3: Utility Commands (Week 3)
- Standardize `_secrets_clear.fish`
- Standardize `_secrets_config.fish`
- Update `_secrets_show_help.fish`

### Phase 4: Advanced Commands (Week 4)
- Standardize `_secrets_doctor.fish`
- Standardize `_secrets_reinit.fish`
- Update startup configuration

### Phase 5: Testing & Polish (Week 5)
- Test all commands with various scenarios
- Ensure consistent behavior across edge cases
- Update documentation and examples

## Migration Strategy

1. **Backward Compatibility**: Maintain all existing functionality while updating output
2. **Gradual Rollout**: Update one command at a time to allow for testing
3. **User Testing**: Gather feedback on new output format before finalizing
4. **Documentation**: Update all help text and examples simultaneously

## Benefits

1. **Improved UX**: Consistent, professional-looking output
2. **Better Accessibility**: Clear visual hierarchy and semantic meaning
3. **Maintainability**: Shared utility functions reduce code duplication
4. **Debuggability**: Standardized error messages make troubleshooting easier
5. **Professionalism**: Polished output reflects quality of the tool

This plan provides a clear roadmap for creating a consistent, professional user experience while maintaining all existing functionality.