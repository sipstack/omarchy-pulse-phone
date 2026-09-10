#!/usr/bin/env bash
#
# Pulse Phone for Omarchy — install the pieces that live outside the plugin.
#
# The bar widget itself is installed by Omarchy (`omarchy plugin add`). This
# script wires up the parts a QML plugin cannot: the launcher on PATH, the
# Hyprland window rules that make the phone a floating scratchpad panel, the
# desktop entry, and the tel:/sip:/callto: URI handler.
#
# Everything here is idempotent and every user-owned file is backed up before
# it is touched. Run with --uninstall to reverse it.
#
set -euo pipefail

readonly PLUGIN_ID="com.sipstack.pulse-phone"
SRC_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SRC_DIR
readonly PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
readonly BIN_DIR="$HOME/.local/bin"
readonly ICON_DIR="$HOME/.local/share/icons/hicolor/192x192/apps"
readonly APP_DIR="$HOME/.local/share/applications"
readonly HYPR_DIR="$HOME/.config/hypr"
readonly HYPR_ENTRY="$HYPR_DIR/hyprland.lua"
readonly HYPR_RULES="$HYPR_DIR/pulse-phone.lua"
readonly REQUIRE_LINE='require("hypr.pulse-phone")'
STAMP="$(date +%Y%m%d%H%M%S)"
readonly STAMP

readonly GREEN=$'\033[32m' RED=$'\033[31m' DIM=$'\033[2m' BOLD=$'\033[1m' OFF=$'\033[0m'

ok()   { printf '  %s✓%s %s\n' "$GREEN" "$OFF" "$*"; }
skip() { printf '  %s·%s %s\n' "$DIM" "$OFF" "$*"; }
warn() { printf '  %s!%s %s\n' "$RED" "$OFF" "$*"; }
die()  { printf '\n%serror:%s %s\n' "$RED" "$OFF" "$*" >&2; exit 1; }

backup() {
  local f="$1"
  [[ -e "$f" ]] || return 0
  cp -a "$f" "$f.pulse-phone-bak.$STAMP"
  skip "backed up $(basename "$f") → $(basename "$f").pulse-phone-bak.$STAMP"
}

# ------------------------------------------------------------------- preflight

preflight() {
  printf '%sChecking your system%s\n' "$BOLD" "$OFF"

  # omarchy-shell only exists in Omarchy 4+ (Quickshell). Omarchy 3 shipped
  # Waybar, which cannot host this plugin at all.
  command -v omarchy-shell >/dev/null 2>&1 ||
    die "this needs Omarchy 4 or newer (omarchy-shell not found).
       Omarchy 3 used Waybar, which cannot load Quickshell plugins.
       Upgrade with: Update > Omarchy, then Update > Omarchy to Quattro"

  command -v omarchy-launch-webapp >/dev/null 2>&1 ||
    die "omarchy-launch-webapp not found — is this a complete Omarchy install?"

  local missing=()
  for c in hyprctl jq; do
    command -v "$c" >/dev/null 2>&1 || missing+=("$c")
  done
  ((${#missing[@]})) && die "missing required commands: ${missing[*]}"

  # The phone needs real WebRTC. webkit2gtk has none, and Firefox has no
  # --app mode, so a Chromium-family browser is not negotiable.
  local browser
  browser="$(xdg-settings get default-web-browser 2>/dev/null || true)"
  case "$browser" in
    google-chrome* | brave* | microsoft-edge* | opera* | vivaldi* | helium* | chromium*)
      ok "default browser is Chromium-family ($browser)" ;;
    *)
      warn "default browser is '${browser:-unknown}'"
      warn "Pulse needs a Chromium-family browser for WebRTC; it will fall back"
      warn "to chromium.desktop. Install chromium if calls fail to connect." ;;
  esac

  ok "Omarchy 4 shell detected"
}

# --------------------------------------------------------------------- install

install_launcher() {
  mkdir -p "$BIN_DIR"
  ln -sfn "$SRC_DIR/bin/pulse-phone" "$BIN_DIR/pulse-phone"
  ok "launcher → $BIN_DIR/pulse-phone"

  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) warn "$BIN_DIR is not on your PATH — add it so 'pulse-phone' works from a shell" ;;
  esac
}

install_icon() {
  mkdir -p "$ICON_DIR"
  install -m 0644 "$SRC_DIR/assets/icon.png" "$ICON_DIR/pulse-phone.png"
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -qtf "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
  fi
  ok "icon → $ICON_DIR/pulse-phone.png"
}

install_desktop_entry() {
  mkdir -p "$APP_DIR"
  backup "$APP_DIR/pulse-phone.desktop"
  install -m 0644 "$SRC_DIR/desktop/pulse-phone.desktop" "$APP_DIR/pulse-phone.desktop"
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q "$APP_DIR" 2>/dev/null || true
  fi
  ok "desktop entry → $APP_DIR/pulse-phone.desktop"

  if command -v xdg-mime >/dev/null 2>&1; then
    local h
    for h in tel sip callto; do
      xdg-mime default pulse-phone.desktop "x-scheme-handler/$h" 2>/dev/null || true
    done
    ok "registered as handler for tel: sip: callto:"
  fi
}

install_hypr_rules() {
  mkdir -p "$HYPR_DIR"
  backup "$HYPR_RULES"
  install -m 0644 "$SRC_DIR/hypr/pulse-phone.lua" "$HYPR_RULES"
  ok "window rules → $HYPR_RULES"

  if [[ ! -f "$HYPR_ENTRY" ]]; then
    warn "$HYPR_ENTRY not found — add this line to your Hyprland config yourself:"
    warn "    $REQUIRE_LINE"
    return 0
  fi

  if grep -qF "$REQUIRE_LINE" "$HYPR_ENTRY"; then
    skip "hyprland.lua already requires the rules"
  else
    backup "$HYPR_ENTRY"
    printf '\n-- Pulse Phone window rules (installed by omarchy-pulse-phone)\n%s\n' \
      "$REQUIRE_LINE" >>"$HYPR_ENTRY"
    ok "hyprland.lua now requires the rules"
  fi

  if hyprctl reload >/dev/null 2>&1; then
    ok "hyprctl reload"
  else
    warn "hyprctl reload failed — log out and back in"
  fi
}

check_plugin() {
  if [[ "$SRC_DIR" == "$PLUGIN_DIR" ]]; then
    ok "bar widget is installed as an Omarchy plugin"
    return 0
  fi
  if [[ -d "$PLUGIN_DIR" ]]; then
    ok "bar widget already present at $PLUGIN_DIR"
    return 0
  fi
  warn "the bar widget is NOT installed yet. Add it with:"
  warn "    omarchy plugin add https://github.com/sipstack/omarchy-pulse-phone.git --enable"
}

# ------------------------------------------------------------------- uninstall

# Remove a path if it is there, and say so. Deliberately never fails: under
# `set -e` a bare `[[ -f x ]] && rm ...` chain aborts the whole script the first
# time a file is already gone, which is exactly when uninstall must keep going.
drop() {
  if [[ -e "$1" || -L "$1" ]]; then
    rm -f "$1"
    ok "removed $2"
  else
    skip "$2 already gone"
  fi
}

uninstall() {
  printf '%sRemoving Pulse Phone%s\n' "$BOLD" "$OFF"

  if command -v pulse-phone >/dev/null 2>&1; then
    pulse-phone quit >/dev/null 2>&1 || true
  fi

  drop "$BIN_DIR/pulse-phone"        "launcher"
  drop "$ICON_DIR/pulse-phone.png"   "icon"
  drop "$APP_DIR/pulse-phone.desktop" "desktop entry"
  drop "$HYPR_RULES"                 "window rules"

  if [[ -f "$HYPR_ENTRY" ]] && grep -qF "$REQUIRE_LINE" "$HYPR_ENTRY"; then
    backup "$HYPR_ENTRY"
    # Drop the require line and the comment we wrote directly above it.
    grep -vF -e "$REQUIRE_LINE" \
      -e '-- Pulse Phone window rules (installed by omarchy-pulse-phone)' \
      "$HYPR_ENTRY" >"$HYPR_ENTRY.tmp" && mv "$HYPR_ENTRY.tmp" "$HYPR_ENTRY"
    ok "unhooked from hyprland.lua"
  fi

  hyprctl reload >/dev/null 2>&1 || true

  printf '\n%sLeft in place on purpose:%s\n' "$BOLD" "$OFF"
  printf '  the browser profile at %s\n' "$HOME/.local/share/pulse-phone"
  printf '    %s(it holds your signed-in session; delete it to sign out)%s\n' "$DIM" "$OFF"
  printf '  the bar widget — remove with: omarchy plugin remove %s\n' "$PLUGIN_ID"
  printf '  every .pulse-phone-bak.* backup this script ever made\n\n'
}

# ------------------------------------------------------------------------ main

case "${1:-install}" in
  install)
    printf '\n%sPulse Phone for Omarchy%s\n\n' "$BOLD" "$OFF"
    preflight
    printf '\n%sInstalling%s\n' "$BOLD" "$OFF"
    install_launcher
    install_icon
    install_desktop_entry
    install_hypr_rules
    check_plugin
    printf '\n%sDone.%s Click the Pulse icon in your bar, or run: pulse-phone\n' "$GREEN" "$OFF"
    printf 'Sign in once — the session persists.\n\n'
    ;;
  --uninstall | uninstall) uninstall ;;
  -h | --help | help)
    printf 'usage: install.sh [install|--uninstall]\n'
    ;;
  *) die "unknown argument: $1" ;;
esac
