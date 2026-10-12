#!/usr/bin/env bash
# DAWN Validator browser runner for Ubuntu VPS
# Safe scope: keeps the official browser extension running and restarts Chrome/Xvfb
# after a crash. It does not automate login, claims, referrals, reward requests,
# CAPTCHA, multi-account use, proxy rotation, or network spoofing.
set -Eeuo pipefail

DISPLAY_NUM="${DISPLAY_NUM:-99}"
export DISPLAY=":${DISPLAY_NUM}"
PROFILE_DIR="${DAWN_PROFILE_DIR:-$HOME/.config/dawn-validator}"
LOG_DIR="${DAWN_LOG_DIR:-$HOME/.local/state/dawn-validator}"
CHROME_BIN="${CHROME_BIN:-}"
RESTART_DELAY="${RESTART_DELAY:-10}"

mkdir -p "$PROFILE_DIR" "$LOG_DIR"

log() {
  printf '[%s] %s\n' "$(date -Is)" "$*" | tee -a "$LOG_DIR/runner.log"
}

find_browser() {
  if [[ -n "$CHROME_BIN" && -x "$CHROME_BIN" ]]; then
    printf '%s\n' "$CHROME_BIN"
    return 0
  fi
  for candidate in google-chrome google-chrome-stable chromium chromium-browser; do
    if command -v "$candidate" >/dev/null 2>&1; then
      command -v "$candidate"
      return 0
    fi
  done
  return 1
}

cleanup() {
  [[ -n "${CHROME_PID:-}" ]] && kill "$CHROME_PID" 2>/dev/null || true
  [[ -n "${XVFB_PID:-}" ]] && kill "$XVFB_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

if ! command -v Xvfb >/dev/null 2>&1; then
  echo "Xvfb tidak ditemukan. Install: sudo apt-get update && sudo apt-get install -y xvfb" >&2
  exit 1
fi

BROWSER="$(find_browser || true)"
if [[ -z "$BROWSER" ]]; then
  echo "Chrome/Chromium tidak ditemukan. Install Google Chrome atau Chromium terlebih dahulu." >&2
  exit 1
fi

# Start a private virtual display. No VNC or remote-debugging port is exposed here.
if ! pgrep -f "Xvfb :${DISPLAY_NUM}" >/dev/null 2>&1; then
  Xvfb "$DISPLAY" -screen 0 1280x900x24 -nolisten tcp >"$LOG_DIR/xvfb.log" 2>&1 &
  XVFB_PID=$!
  sleep 2
fi

log "Browser: $BROWSER"
log "Profile: $PROFILE_DIR"
log "Display: $DISPLAY"
log "Start only after the official DAWN extension has been installed manually in this profile."

while true; do
  log "Starting Chrome/Chromium. Login must be completed manually; no credentials are read by this script."
  "$BROWSER" \
    --user-data-dir="$PROFILE_DIR" \
    --profile-directory=Default \
    --no-first-run \
    --no-default-browser-check \
    --disable-session-crashed-bubble \
    --disable-dev-shm-usage \
    --disable-background-networking \
    --disable-features=Translate \
    about:blank \
    >>"$LOG_DIR/chrome.log" 2>&1 &
  CHROME_PID=$!

  if wait "$CHROME_PID"; then
    log "Chrome exited normally; restarting in ${RESTART_DELAY}s."
  else
    log "Chrome stopped unexpectedly; restarting in ${RESTART_DELAY}s."
  fi
  CHROME_PID=""
  sleep "$RESTART_DELAY"
done
