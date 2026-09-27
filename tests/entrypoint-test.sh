#!/usr/bin/env bash
set -euo pipefail

image_name="ha-omniroute-test"
data_dir="$(mktemp -d)"
container_name="ha-omniroute-test-$$"

cleanup() {
  docker rm -f "$container_name" >/dev/null 2>&1 || true
  rm -rf "$data_dir"
}
trap cleanup EXIT

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

docker build --build-arg BUILD_VERSION=3.8.50 -t "$image_name" omniroute
docker run -d --name "$container_name" -p 20128:20128 -v "$data_dir:/data" "$image_name"

for _ in $(seq 1 30); do
  if curl --fail --silent http://localhost:20128/healthz >/dev/null; then
    break
  fi
  sleep 1
done

curl --fail --silent http://localhost:20128/healthz >/dev/null
jq -e '.jwt_secret and .api_key_secret and .storage_encryption_key' "$data_dir/.haos-secrets.json" >/dev/null
test "$(stat -f '%Lp' "$data_dir/.haos-secrets.json")" = "600"

docker rm -f "$container_name" >/dev/null
rm "$data_dir/.haos-secrets.json"
touch "$data_dir/storage.sqlite"

if docker run --rm -v "$data_dir:/data" "$image_name" 2>&1 | grep -q 'storage.sqlite exists but /data/.haos-secrets.json is missing'; then
  exit 0
fi

echo 'Expected startup to reject a database without persistent secrets.' >&2
exit 1
