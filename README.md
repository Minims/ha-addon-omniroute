# OmniRoute Home Assistant Add-on

[![Build](https://github.com/Minims/ha-addon-omniroute/actions/workflows/build.yaml/badge.svg)](https://github.com/Minims/ha-addon-omniroute/actions/workflows/build.yaml)

Run OmniRoute's OpenAI-compatible API, dashboard, and browser-based providers on Home Assistant OS.

## Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**.
2. Select **⋮ → Repositories** and add:

   ```text
   https://github.com/Minims/ha-addon-omniroute
   ```

3. Find **OmniRoute** and select **Install**.
4. Set an initial dashboard password and the Pi's LAN URL in **Configuration**.
5. Start the add-on.

## Access

- Dashboard: `http://<PI_IP>:20128`
- API: `http://<PI_IP>:20128/v1`

## License

MIT
