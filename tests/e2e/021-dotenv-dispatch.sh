#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
e2e_setup "021"
setup_dispatch_fixtures

cat > "$WS/.env" <<'ENV'
# working-directory dispatcher environment
BUS_E2E_DOTENV=loaded
export BUS_E2E_DOTENV_EXPORTED=exported
BUS_E2E_DOTENV_SPACED = spaced value
BUS_E2E_DOTENV_EXISTING=from-dotenv
GENERIC_E2E_DOTENV=generic
ENV

(cd "$WS" && PATH="$TEST_PATH" BUS_E2E_DOTENV_EXISTING=from-process "$BIN" env BUS_E2E_DOTENV BUS_E2E_DOTENV_EXPORTED BUS_E2E_DOTENV_SPACED BUS_E2E_DOTENV_EXISTING GENERIC_E2E_DOTENV > "$WS/dotenv.out" 2> "$WS/dotenv.err")
diff -u <(printf 'BUS_E2E_DOTENV=loaded\nBUS_E2E_DOTENV_EXPORTED=exported\nBUS_E2E_DOTENV_SPACED=spaced value\nBUS_E2E_DOTENV_EXISTING=from-process\nGENERIC_E2E_DOTENV=generic\n') "$WS/dotenv.out"
! test -s "$WS/dotenv.err"

mkdir -p "$WS/app"
printf 'BUS_E2E_DOTENV_CHDIR=from-chdir\n' > "$WS/app/.env"
PATH="$TEST_PATH" "$BIN" -C "$WS/app" env BUS_E2E_DOTENV_CHDIR > "$WS/dotenv_chdir.out" 2> "$WS/dotenv_chdir.err"
diff -u <(printf 'BUS_E2E_DOTENV_CHDIR=from-chdir\n') "$WS/dotenv_chdir.out"
! test -s "$WS/dotenv_chdir.err"

mkdir -p "$WS/launcher/projects/busdk"
cat > "$WS/launcher/.env" <<'ENV'
BUS_PWD=projects/busdk
BUS_LAUNCHER_ONLY=from-launcher
ENV
printf 'BUS_TARGET_ENV=from-target\n' > "$WS/launcher/projects/busdk/.env"
printf 'workspace-stack\n' > "$WS/launcher/projects/busdk/services.yml"
cat > "$WS/path_first/bus-workspace" <<'SH'
#!/bin/sh
IFS= read -r services < services.yml
printf 'cwd=%s\n' "$(pwd)"
printf 'services=%s\n' "$services"
printf 'BUS_TARGET_ENV=%s\n' "${BUS_TARGET_ENV-}"
printf 'BUS_LAUNCHER_ONLY=%s\n' "${BUS_LAUNCHER_ONLY-}"
printf 'PWD=%s\n' "${PWD-}"
printf 'BUS_PWD=%s\n' "${BUS_PWD-}"
SH
chmod +x "$WS/path_first/bus-workspace"

bus_pwd_target="$(cd "$WS/launcher/projects/busdk" && pwd)"
(cd "$WS/launcher" && PATH="$TEST_PATH" "$BIN" workspace > "$WS/bus_pwd.out" 2> "$WS/bus_pwd.err")
diff -u <(printf 'cwd=%s\nservices=workspace-stack\nBUS_TARGET_ENV=from-target\nBUS_LAUNCHER_ONLY=\nPWD=%s\nBUS_PWD=%s\n' "$bus_pwd_target" "$bus_pwd_target" "$bus_pwd_target") "$WS/bus_pwd.out"
! test -s "$WS/bus_pwd.err"

printf 'accounts from-bus-pwd\n' > "$WS/launcher/projects/busdk/replay.bus"
(cd "$WS/launcher" && PATH="$TEST_PATH" "$BIN" replay.bus > "$WS/bus_pwd_busfile.out" 2> "$WS/bus_pwd_busfile.err")
diff -u <(printf 'ACCOUNTS:from-bus-pwd\n') "$WS/bus_pwd_busfile.out"
! test -s "$WS/bus_pwd_busfile.err"

(cd "$WS/launcher" && PATH="$TEST_PATH" "$BIN" --no-chdir env BUS_LAUNCHER_ONLY > "$WS/bus_pwd_disabled.out" 2> "$WS/bus_pwd_disabled.err")
diff -u <(printf 'BUS_LAUNCHER_ONLY=from-launcher\n') "$WS/bus_pwd_disabled.out"
! test -s "$WS/bus_pwd_disabled.err"

printf '1INVALID=value\n' > "$WS/.env"
if (cd "$WS" && PATH="$TEST_PATH" "$BIN" env BUS_E2E_DOTENV > "$WS/dotenv_invalid.out" 2> "$WS/dotenv_invalid.err"); then
  fail "invalid .env unexpectedly succeeded"
fi
! test -s "$WS/dotenv_invalid.out"
grep -q 'bus: failed to load .env: .env:1: invalid environment variable name "1INVALID"' "$WS/dotenv_invalid.err"

echo "e2e OK"
