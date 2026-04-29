<div align="center">

<img src="assets/opah-hero.png" alt="opah.fish" width="720"/>

Automatically load 1Password secrets into your Fish shell environment.<br>
Secure caching, instant startup, and a clean CLI for day-to-day secret management.

```fish
fisher install tbcrawford/opah.fish
```

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-000000?style=flat-square)](LICENSE)&nbsp;&nbsp;[![Fish](https://img.shields.io/badge/Fish_3.0+-4B7BEC?style=flat-square)](https://fishshell.com)&nbsp;&nbsp;[![Release](https://img.shields.io/github/v/release/tbcrawford/opah.fish?style=flat-square&color=000000)](https://github.com/tbcrawford/opah.fish/releases)

</div>

## Quick Start

Define your secrets once in a YAML file. On every shell startup, opah loads them from 1Password and exports them as environment variables — fetching live on first run, then reading from a secure local cache.

<p align="center">
  <img src="assets/demo/demo.gif" alt="Terminal demo showing opah refresh, status, and doctor" width="720" />
</p>

---

## Why opah

Dotfiles committed to git should not contain secrets. The alternatives — templating systems, encrypted files, excluded config — all add friction.

opah separates the reference from the value. Your dotfiles hold only `op://` URIs. The actual secrets live in 1Password and are fetched on demand, cached locally, and exported into your environment automatically.

- Commit your entire Fish config without exposing credentials
- No preprocessors, no templates, no extra tooling
- Works across every machine that has the 1Password CLI installed

---

## Install

**Prerequisites**: [Fish 3.0+](https://fishshell.com) and [1Password CLI](https://developer.1password.com/docs/cli/get-started/) (`op`)

**Fisher**

```fish
fisher install tbcrawford/opah.fish
```

**Oh My Fish**

```fish
omf install https://github.com/tbcrawford/opah.fish
```

---

## Configuration

Create `~/.config/fish/secrets.yaml`:

```yaml
secrets:
  API_KEY: "op://Work/API Keys/api_key"
  DATABASE_URL: "op://Work/Database/connection_string"
  GITHUB_TOKEN: "op://Work/GitHub/token"
```

Values must be [1Password secret references](https://developer.1password.com/docs/cli/secret-reference-syntax/) in `op://vault/item/field` format. opah also checks `~/.config/fish/secrets.yml`, `~/.config/opah/secrets.yaml`, and a few other locations if the primary path is absent.

---

## Command Reference

| Command | Description |
|---|---|
| `opah refresh [KEY]` | Fetch secrets from 1Password and update the cache. Pass a key name to refresh a single secret. |
| `opah status [KEY]` | Show which secrets are cached and loaded into the environment. |
| `opah config` | Validate the configuration file and list defined secrets. |
| `opah doctor` | Run health checks: CLI installation, authentication, config, and cache. |
| `opah clear` | Remove the cache and unset all managed environment variables. |
| `opah reinit` | Clear state, re-authenticate, and reload everything from scratch. |
| `opah help` | Show usage. All subcommands also accept `-h`. |

---

## How It Works

On each shell startup, opah checks for a local cache. If it exists, secrets load instantly without touching 1Password. If it is missing, opah calls `op read` for each secret in your config, writes a fresh cache, and exports everything into the environment.

The cache is stored at `~/.cache/fish/opah/secrets.fish` with `600` permissions and is invalidated manually via `opah refresh` or `opah clear`.

---

## Security

Cached secrets are stored in plaintext on disk. Use `opah clear` before walking away from a shared machine. On personal machines, whole-disk encryption provides the appropriate layer of protection beneath the `600` file permissions opah sets on the cache.

Secrets are exported as global environment variables and are visible to all child processes. This is the same posture as loading secrets from a `.env` file — convenient for local development, not appropriate for production hosts.

---

<div align="center">

Apache 2.0 License · Built for Fish shell · [Report an issue](https://github.com/tbcrawford/opah.fish/issues)

</div>
