<p align="center">
  <img src="assets/opah-hero.png" alt="OPAH" />
</p>

# 🐠 opah.fish

A Fish shell plugin for seamless 1Password secrets management with automatic loading and intelligent caching.

## 🎯 What is this?

`opah.fish` is a Fish shell plugin that automatically loads secrets from 1Password into your shell environment variables. It features intelligent caching to minimize 1Password CLI calls and includes `opah` (a playful nod to the [opah fish](https://en.wikipedia.org/wiki/Opah) and the 1Password CLI `op`), a comprehensive CLI for managing your secrets.

## 💡 Why use this?

**Commit your dotfiles without committing your secrets.** 

When you manage your Fish shell configuration in git, you typically face a dilemma: either hardcode secrets directly (and risk committing them), use templating systems (adding complexity), or exclude configuration files from version control (losing the benefits of dotfile management).

`opah.fish` solves this by:
- **Separating secrets from configuration** - Your dotfiles contain only references to secrets, not the secrets themselves
- **Enabling safe version control** - Commit your entire Fish configuration to git without worrying about exposed credentials
- **Eliminating templating complexity** - No need for dotfile preprocessors or template systems
- **Maintaining portability** - The same configuration works across all your machines, with secrets fetched securely from 1Password

### Key Features

- 🔐 **Automatic secret loading** on shell startup
- 💾 **Intelligent caching** to avoid repeated 1Password authentication
- 🎨 **Beautiful CLI** with modern UI and helpful diagnostics
- ⚡ **Selective refresh** - update individual secrets without reloading everything
- 🔍 **Comprehensive diagnostics** with `opah doctor`
- 🛡️ **Secure** - secrets are fetched directly from 1Password and cached locally

## 📦 Installation

### Prerequisites

- [Fish shell](https://fishshell.com/) 3.0+
- [1Password CLI](https://developer.1password.com/docs/cli/get-started/) (`op`)

### Using Fisher

```fish
fisher install tbcrawford/opah.fish
```

To install a specific release instead of the latest version:

```fish
fisher install tbcrawford/opah.fish@v0.1.0
```

### Using Oh My Fish

```fish
omf install https://github.com/tbcrawford/opah.fish
```

### Manual Installation

Clone the repository to your Fish functions directory:

```fish
git clone https://github.com/tbcrawford/opah.fish.git ~/.config/fish/conf.d/opah
```

## ⚙️ Configuration

Create a configuration file at one of these locations (checked in order):

1. `~/.config/fish/secrets.yaml` _(recommended)_
2. `~/.config/fish/secrets.yml`
3. `~/.config/fish/.secrets.yaml`
4. `~/.config/fish/.secrets.yml`
5. `~/.config/opah/secrets.yaml`
6. `~/.config/opah/secrets.yml`

### Configuration Format

```yaml
secrets:
  API_KEY: "op://vault/MyVault/API Keys/api_key"
  DATABASE_URL: "op://vault/MyVault/Database/connection_string"
  AWS_ACCESS_KEY_ID: "op://vault/AWS/Access Key"
  AWS_SECRET_ACCESS_KEY: "op://vault/AWS/Secret Key"
  GITHUB_TOKEN: "op://vault/GitHub/Personal Access Token"
```

Each secret should use the [1Password secret reference URI format](https://developer.1password.com/docs/cli/secret-reference-syntax/):

```
op://[vault]/[item]/[section]/[field]
```

## 🐟 The `opah` CLI

The plugin includes `opah`, a comprehensive CLI for managing your 1Password secrets. The name is a playful reference to the [opah fish](https://en.wikipedia.org/wiki/Opah) and the 1Password CLI `op`.

### Usage

```fish
opah <SUBCOMMAND> [OPTIONS]
```

### Subcommands

#### `opah status [SECRET_NAME]`

Show the status of cached secrets and configuration.

```fish
# Show all secrets status
opah status

# Show specific secret status
opah status API_KEY
```

**Example output:**
```
📁 Cache file: ~/.cache/fish/opah/secrets.fish
ℹ Last updated: Sep 30 12:34:56 2025

ℹ Cached secrets: 5

Cached secrets:
    API_KEY: ✓ Cached & Loaded
    DATABASE_URL: ✓ Cached & Loaded
    AWS_ACCESS_KEY_ID: ✓ Cached & Loaded
```

#### `opah refresh [SECRET_NAME]`

Refresh secrets from 1Password, forcing a new fetch from the 1Password CLI.

```fish
# Refresh all secrets
opah refresh

# Refresh specific secret only
opah refresh DATABASE_URL
```

This command will:
- Re-authenticate with 1Password if needed
- Fetch the latest secret values
- Update the cache
- Load secrets into your current shell session

#### `opah clear`

Clear all cached secrets and unset environment variables.

```fish
opah clear
```

This is useful when:
- You want to remove secrets from memory
- You're switching 1Password accounts
- You need to clean up before re-initialization

#### `opah config`

Show configuration file information and validate the format.

```fish
opah config
```

**Example output:**
```
Checking configuration file locations:
✓ ~/.config/fish/secrets.yaml (FOUND)
✗ ~/.config/fish/secrets.yml
...

📁 Active configuration file: ~/.config/fish/secrets.yaml
ℹ Last modified: Sep 30 12:00:00 2025

Configuration validation:
    ✓ API_KEY: op://vault/MyVault/API Keys/api_key
    ✓ DATABASE_URL: op://vault/MyVault/Database/connection_string
    ⚠ SOME_VAR: not_a_1password_ref (not a 1Password reference)

✓ Success! Configuration valid
ℹ Found 3 secret(s) defined
```

#### `opah doctor`

Run comprehensive diagnostics to validate your complete setup.

```fish
opah doctor
```

This command checks:
- ✅ 1Password CLI installation and version
- ✅ 1Password authentication status
- ✅ Configuration file existence and validity
- ✅ Cache system status
- ✅ Fish shell integration
- ✅ Core functions availability

**Example output:**
```
🔍 Checking 1Password CLI...
  ✓ 1Password CLI (op) is installed
    Version: 2.23.0

🔍 Checking 1Password authentication...
  ✓ Signed in to 1Password
    Accounts: user@example.com

🔍 Checking configuration file...
  ✓ Configuration file found: ~/.config/fish/secrets.yaml
    Format: Valid YAML with secrets section
    1Password references: 5

🔍 Checking cache system...
  ✓ Cache directory exists: ~/.cache/fish/opah
  ✓ Cache file exists: ~/.cache/fish/opah/secrets.fish
    Last updated: Sep 30 12:34:56 2025
    Cached secrets: 5

🔍 Checking Fish shell integration...
  ✓ Running from functions directory
  ✓ Core functions are available

📋 Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ All systems operational!

Next steps:
    Run 'opah refresh' to load secrets from 1Password
    Run 'opah status' to verify loaded secrets
```

#### `opah reinit`

Re-initialize the plugin after authentication changes (e.g., switching 1Password accounts).

```fish
opah reinit
```

This command will:
1. Clear existing cache and environment variables
2. Check 1Password authentication (prompting if needed)
3. Reload all secrets from configuration

#### `opah help`

Display help information.

```fish
opah help
```

All subcommands also support the `-h`/`--help` flag:

```fish
opah status --help
opah refresh --help
opah clear --help
```

## 🔄 How It Works

### Automatic Loading

When you start a new Fish shell session, the plugin automatically:

1. Checks for cached secrets in `~/.cache/fish/opah/secrets.fish`
2. If cache exists and is valid, loads secrets from cache (fast!)
3. If cache is missing, fetches secrets from 1Password using the CLI
4. Stores fetched secrets in cache for future sessions
5. Exports secrets as environment variables

### Caching Strategy

- **Cache location**: `~/.cache/fish/opah/secrets.fish`
- **Cache format**: Fish shell script with `set -gx` commands
- **Cache invalidation**: Manual (use `opah refresh` or `opah clear`)
- **Selective updates**: Refresh individual secrets with `opah refresh SECRET_NAME`

This approach minimizes authentication prompts while keeping your secrets secure and up-to-date.

## 🎨 Shell Completion

The plugin includes intelligent tab completion for the `opah` command:

- Subcommand completion
- Secret name completion for `status` and `refresh`
- Help flag completion for all subcommands

Try typing `opah <TAB>` or `opah refresh <TAB>` to see it in action!

## 🛠️ Advanced Usage

### Selective Secret Refresh

Update a single secret without refreshing everything:

```fish
opah refresh DATABASE_URL
```

This is perfect when:
- You've rotated a single credential
- You want to test a specific secret reference
- You don't want to re-fetch all secrets

### Shell Integration

Since secrets are loaded as environment variables, they're available to all commands:

```fish
# Use in scripts
echo $DATABASE_URL

# Pass to commands
psql $DATABASE_URL

# Use in config files
export DATABASE_URL  # Already exported by opah!
```

### Conditional Loading

Want to skip automatic loading in certain scenarios? You can disable the auto-load by removing or commenting out the `conf.d/opah.fish` file.

## 🔒 Security Considerations

- **Cache storage**: Cached secrets are stored in plain text in `~/.cache/fish/opah/secrets.fish`
  - Ensure your home directory has appropriate permissions
  - Consider encrypting your home directory
  - Use `opah clear` when done with a session on shared machines

- **Environment variables**: Secrets are stored as global environment variables
  - They're available to all processes started from your shell
  - They may appear in process listings
  - Clear them with `opah clear` when working with untrusted code

- **1Password CLI**: The plugin relies on 1Password CLI's authentication
  - Use biometric unlock when available
  - Set appropriate session timeouts in 1Password settings

## 🐛 Troubleshooting

### Secrets not loading on startup

Run diagnostics:
```fish
opah doctor
```

### "Not signed in to 1Password" error

Sign in manually:
```fish
op signin
```

Or let `opah` handle it:
```fish
opah refresh  # Will prompt for authentication if needed
```

### Configuration file not found

Check your configuration file location:
```fish
opah config
```

Create a configuration file if needed:
```fish
mkdir -p ~/.config/fish
touch ~/.config/fish/secrets.yaml
```

### Invalid secret references

Validate your configuration:
```fish
opah config
```

Make sure your secret references follow the format:
```
op://[vault]/[item]/[section]/[field]
```

### Cache issues

Clear and rebuild the cache:
```fish
opah reinit
```

## 📝 Example Workflow

Here's a typical workflow for using `opah.fish`:

```fish
# 1. Initial setup
opah doctor                    # Check your setup

# 2. First-time load
opah refresh                   # Fetch secrets from 1Password
opah status                    # Verify secrets are loaded

# 3. Daily usage
# Secrets automatically load on shell startup!

# 4. When a secret changes
opah refresh DATABASE_URL      # Update just one secret

# 5. When switching contexts
opah clear                     # Clear secrets
opah reinit                    # Re-initialize with new context
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Named after the [opah fish](https://en.wikipedia.org/wiki/Opah), continuing the aquatic theme of Fish shell
- Built on top of the excellent [1Password CLI](https://developer.1password.com/docs/cli/)
- Inspired by the Fish shell community's focus on user-friendly tooling

---

Made with 🐟 by [@tbcrawford](https://github.com/tbcrawford)
