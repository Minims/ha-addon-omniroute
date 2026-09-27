# OmniRoute

## Requirements

- Home Assistant OS on a Raspberry Pi 5 with 8 GB RAM.
- SSD or NVMe storage.
- At least 5 GB free disk space for the web image and an update's temporary image overlap.

## Installation

1. In **Settings → Add-ons → Add-on Store**, open **⋮ → Repositories**.
2. Add `https://github.com/Minims/ha-addon-omniroute`.
3. Install **OmniRoute**.
4. In **Configuration**, set `initial_password` and set `public_url` to the Pi's LAN address, for example `http://192.168.1.10:20128`.
5. Start the add-on and open `http://<PI_IP>:20128`.

## Configuration

| Option | Default | Purpose |
| --- | --- | --- |
| `initial_password` | required | Initial dashboard administrator password. Change it in **Settings → Security** after the first sign-in. |
| `public_url` | `http://192.168.1.10:20128` | LAN URL used by supported OmniRoute callbacks. |
| `memory_mb` | `3072` | Node.js memory limit. Keep this conservative on an 8 GB Pi because Chromium and Home Assistant also need RAM. |
| `require_api_key` | `true` | Requires an OmniRoute API key for `/v1/*` requests. |
| `log_to_file` | `false` | Writes application logs under `/data/logs`; disabled by default to reduce SSD writes. |
| `headroom_url` | empty | Optional URL for an external Headroom proxy. |

## Persistent data and backups

OmniRoute stores its SQLite database, providers, API keys, browser-session data, and generated encryption secrets in `/data`. Home Assistant preserves this volume across restarts and add-on image updates.

The add-on uses a **cold** backup: Home Assistant stops OmniRoute before copying its data. This protects SQLite and its WAL journal. Take a Home Assistant backup before an OmniRoute major-version update.

`/data/.haos-secrets.json` is essential: it contains the keys that protect the database and API keys. If `storage.sqlite` exists but this file is missing, the add-on intentionally refuses to start. Restore both files from the same Home Assistant backup; do not delete the secret file to reset a password.

## Connect OpenCode from the Mac

1. In the OmniRoute dashboard, create an inference API key in **Endpoints**.
2. Configure the OpenAI-compatible OmniRoute provider in OpenCode with:

   - base URL: `http://192.168.1.10:20128/v1`
   - API key: the key created in OmniRoute
   - model: an OmniRoute model or combo, such as `auto`

For a connectivity check:

```bash
curl \
  -H "Authorization: Bearer $OMNIROUTE_API_KEY" \
  http://192.168.1.10:20128/v1/models
```

The OmniRoute CLI can also configure OpenCode when it is installed on the Mac:

```bash
omniroute setup-opencode \
  --remote http://192.168.1.10:20128 \
  --api-key "$OMNIROUTE_API_KEY"
```

Use the manual OpenAI-compatible provider configuration if this command does not work with the installed CLI version.

## Context compression and Headroom

Nothing needs to be configured in OpenCode for context compression. Caveman, RTK, Headroom, and the other bundled OmniRoute engines operate inside OmniRoute before a request is sent to the selected LLM provider.

Configure them only in **OmniRoute Dashboard → Context & Cache → Compression**. The `headroom_url` add-on option is for an optional, separately deployed Headroom token-saver proxy. Headroom MCP memory is a different, optional integration and must be configured in the agent itself if you choose to use it.

## Troubleshooting

### The dashboard is unreachable

Confirm the add-on is running, then access `http://<PI_IP>:20128` from the same LAN. Do not use a public URL without adding TLS or a VPN.

### The add-on reports missing secrets

Restore `/data/.haos-secrets.json` and `/data/storage.sqlite` together from the same Home Assistant backup. Starting with a new secret file against an old database can make encrypted values unreadable.

### Chromium or a Web provider crashes

The `-web` image includes Chromium. Close unused browser sessions, keep one heavy request at a time on an 8 GB Pi, and keep sufficient free memory and disk space.
