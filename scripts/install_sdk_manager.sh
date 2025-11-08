#!/usr/bin/env bash
set -euo pipefail

# ---- Usage -----------------------------------------------------------------
show_usage() {
  cat <<EOF
Install SDK Manager - Setup Android SDK Command-line Tools

USAGE:
  $0 <sdk_manager_zip_url>
  $0 [OPTIONS]

ARGUMENTS:
  sdk_manager_zip_url    URL to Android SDK command-line tools ZIP

OPTIONS:
  -h, --help             Show this help message

DESCRIPTION:
  Downloads and installs Android SDK command-line tools to:
    \$HOME/android/Sdk/cmdline-tools/latest
  
  Installs core packages:
    - platform-tools
    - emulator
    - platforms;android-35
    - build-tools;35.0.0
  
  Updates your shell RC file (.zshrc or .bashrc) with environment variables.
  Points Flutter to the Android SDK if Flutter is installed.

EXAMPLES:
  $0 https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip

FIND ZIP:
  https://developer.android.com/studio#command-line-tools-only

EOF
}

# ---- Parse arguments -------------------------------------------------------
if [ "$#" -eq 0 ]; then
  show_usage
  exit 1
fi

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      show_usage
      exit 0
      ;;
  esac
done

ZIP_URL="$1"

# ---- Helpers ---------------------------------------------------------------
msg(){ printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die(){ printf '\n\033[1;31m!! %s\033[0m\n' "$*" >&2; exit 1; }

# Choose rc file
SHELL_NAME="$(basename "${SHELL:-sh}")"
if [ "$SHELL_NAME" = "zsh" ]; then
  RCFILE="$HOME/.zshrc"
else
  RCFILE="$HOME/.bashrc"
fi

# Constants
ANDROID_SDK_ROOT="$HOME/android/Sdk"
CMDLINE_LATEST="$ANDROID_SDK_ROOT/cmdline-tools/latest"
MARK_START="# >>> ANDROID_SDK (managed by setup-android-sdk) >>>"
MARK_END="# <<< ANDROID_SDK (managed by setup-android-sdk) <<<"

# ---- Ensure prerequisites --------------------------------------------------
msg "Installing prerequisites (requires sudo): unzip, wget, JDK 17"
if ! command -v sudo >/dev/null 2>&1; then
  die "sudo not found; install and re-run."
fi

sudo pacman -Syu --needed --noconfirm unzip wget jdk17-openjdk

# Ensure Java 17 is active
if command -v archlinux-java >/dev/null 2>&1; then
  sudo archlinux-java set java-17-openjdk || true
fi

# ---- Prepare directories ---------------------------------------------------
msg "Preparing SDK directories at $ANDROID_SDK_ROOT"
mkdir -p "$ANDROID_SDK_ROOT"

# ---- Download to a temp file ----------------------------------------------
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

BASENAME="$(basename "$ZIP_URL")"
ZIP_PATH="$TMPDIR/$BASENAME"

msg "Downloading: $ZIP_URL"
wget -qO "$ZIP_PATH" "$ZIP_URL" || die "Failed to download SDK ZIP."

# ---- Extract to 'cmdline-tools/latest' ------------------------------------
msg "Extracting Command-line Tools"
# The zip contains a top-level "cmdline-tools" directory. We move it to 'latest'.
unzip -q "$ZIP_PATH" -d "$TMPDIR/extracted"

# There are a few possible layouts; normalize them.
if [ -d "$TMPDIR/extracted/cmdline-tools" ]; then
  SRC_DIR="$TMPDIR/extracted/cmdline-tools"
else
  # Try to find it
  SRC_DIR="$(find "$TMPDIR/extracted" -maxdepth 2 -type d -name cmdline-tools | head -n1 || true)"
  [ -n "$SRC_DIR" ] || die "Could not locate 'cmdline-tools' inside ZIP."
fi

# Create final dest: $ANDROID_SDK_ROOT/cmdline-tools/latest
mkdir -p "$(dirname "$CMDLINE_LATEST")"
# Replace atomically
if [ -e "$CMDLINE_LATEST" ]; then
  msg "Replacing existing cmdline-tools 'latest'"
  rm -rf "$CMDLINE_LATEST"
fi
mv "$SRC_DIR" "$CMDLINE_LATEST"

# ---- Environment variables (current shell) --------------------------------
msg "Exporting environment variables (current shell)"
export ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export ANDROID_AVD_HOME="$HOME/.android/avd"
export PATH="$CMDLINE_LATEST/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH"

# ---- Persist environment to RC file ---------------------------------------
msg "Writing environment to $RCFILE"
# Remove previous managed block if any
if grep -qF "$MARK_START" "$RCFILE" 2>/dev/null; then
  awk -v s="$MARK_START" -v e="$MARK_END" '
    $0==s {skip=1}
    !skip {print}
    $0==e {skip=0}
  ' "$RCFILE" > "$RCFILE.tmp" && mv "$RCFILE.tmp" "$RCFILE"
fi

cat >> "$RCFILE" <<EOF

$MARK_START
# Android SDK root (HOME-based)
export ANDROID_SDK_ROOT="\$HOME/android/Sdk"
export ANDROID_HOME="\$ANDROID_SDK_ROOT"
export ANDROID_AVD_HOME="\$HOME/.android/avd"

# cmdline-tools/latest first; add platform-tools & emulator
if [[ ":\$PATH:" != *":\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:"* ]]; then
  export PATH="\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:\$PATH"
fi
if [[ ":\$PATH:" != *":\$ANDROID_SDK_ROOT/platform-tools:"* ]]; then
  export PATH="\$ANDROID_SDK_ROOT/platform-tools:\$PATH"
fi
if [[ ":\$PATH:" != *":\$ANDROID_SDK_ROOT/emulator:"* ]]; then
  export PATH="\$ANDROID_SDK_ROOT/emulator:\$PATH"
fi
$MARK_END
EOF

# ---- Point Flutter to this SDK (if flutter exists) ------------------------
if command -v flutter >/dev/null 2>&1; then
  msg "Pointing Flutter to Android SDK"
  flutter config --android-sdk "$ANDROID_SDK_ROOT" >/dev/null || true
fi

# ---- Verify sdkmanager is available ---------------------------------------
msg "Verifying sdkmanager"
if ! command -v sdkmanager >/dev/null 2>&1; then
  which sdkmanager || true
  readlink -f "$(command -v sdkmanager)" 2>/dev/null || true
  die "sdkmanager not found in PATH. Check $CMDLINE_LATEST/bin is first in PATH."
fi

# ---- Install core packages + accept licenses ------------------------------
msg "Installing core Android packages and accepting licenses"
yes | sdkmanager --sdk_root="$ANDROID_SDK_ROOT" --licenses >/dev/null
yes | sdkmanager --sdk_root="$ANDROID_SDK_ROOT" \
  "platform-tools" \
  "emulator" \
  "platforms;android-35" \
  "build-tools;35.0.0" >/dev/null

# ---- Final checks ----------------------------------------------------------
msg "Final checks"
java  -version || die "Java not working"
javac -version || die "Javac not working"
sdkmanager --version || die "sdkmanager not working"

msg "Done! Open a NEW shell (to read $RCFILE), then run:  flutter doctor -v"

