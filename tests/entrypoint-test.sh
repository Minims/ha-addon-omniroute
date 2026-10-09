#!/usr/bin/env bash
set -euo pipefail

image_name="ha-omniroute-test"
data_dir="$(mktemp -d)"
recovery_dir="$(mktemp -d)"
container_name="ha-omniroute-test-$$"

cleanup() {
  docker rm -f "$container_name" >/dev/null 2>&1 || true
  rm -rf "$data_dir"
  rm -rf "$recovery_dir"
}
trap cleanup EXIT

file_mode() {
  stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"
}

cat >"$data_dir/options.json" <<'JSON'
{
  "initial_password": "TestPassword123!",
  "public_url": "http://localhost:20128",
  "memory_mb": 1024,
  "require_api_key": true,
  "log_to_file": false,
  "headroom_url": ""
}
JSON

build_version="$(sed -n 's/^version: "\{0,1\}\([^"[:space:]]*\)"\{0,1\}$/\1/p' omniroute/config.yaml)"
docker build --build-arg BUILD_VERSION="$build_version" -t "$image_name" omniroute
docker run -d --name "$container_name" -p 127.0.0.1::20128 -v "$data_dir:/data" "$image_name"

for _ in $(seq 1 30); do
  health_status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$container_name")"
  if [ "$health_status" = healthy ]; then
    break
  fi
  sleep 1
done

test "$(docker inspect --format '{{.State.Health.Status}}' "$container_name")" = healthy
docker exec "$container_name" jq -e '.jwt_secret and .api_key_secret and .storage_encryption_key' /data/.haos-secrets.json >/dev/null
test "$(docker exec "$container_name" stat -c '%a' /data/.haos-secrets.json)" = "600"
docker exec "$container_name" gosu 1000:1000 node -e '
  const { chromium } = require("playwright");
  chromium.launch({ args: ["--disable-dev-shm-usage"] })
    .then((browser) => browser.close())
    .catch((error) => { console.error(error); process.exit(1); });
'

secrets_checksum="$(docker exec "$container_name" sha256sum /data/.haos-secrets.json | cut -d ' ' -f 1)"
docker rm -f "$container_name" >/dev/null
docker run -d --name "$container_name" -p 127.0.0.1::20128 -v "$data_dir:/data" "$image_name"

for _ in $(seq 1 30); do
  health_status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$container_name")"
  if [ "$health_status" = healthy ]; then
    break
  fi
  sleep 1
done

test "$(docker inspect --format '{{.State.Health.Status}}' "$container_name")" = healthy
test "$secrets_checksum" = "$(docker exec "$container_name" sha256sum /data/.haos-secrets.json | cut -d ' ' -f 1)"

docker rm -f "$container_name" >/dev/null

cp "$data_dir/options.json" "$recovery_dir/options.json"
touch "$recovery_dir/storage.sqlite"

set +e
startup_output="$(docker run --rm -v "$recovery_dir:/data" "$image_name" 2>&1)"
startup_status=$?
set -e
if grep -q 'storage.sqlite exists but /data/.haos-secrets.json is missing' <<<"$startup_output"; then
  exit 0
fi

echo 'Expected startup to reject a database without persistent secrets.' >&2
printf '%s\n' "$startup_output" >&2
echo "Exit status: $startup_status" >&2
exit 1
