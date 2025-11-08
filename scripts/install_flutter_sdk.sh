#!/usr/bin/env bash
set -euo pipefail

# ---- usage -----------------------------------------------------------------
show_usage() {
  cat <<EOF
Install Flutter SDK - Download and install Flutter SDK to /opt/flutter

USAGE:
  $0 <flutter_sdk_tar_url>
  $0 [OPTIONS]

ARGUMENTS:
  flutter_sdk_tar_url    URL to Flutter SDK tarball (.tar.xz or .tar.gz)

OPTIONS:
  -h, --help             Show this help message

DESCRIPTION:
  Downloads Flutter SDK from the provided URL and installs it to /opt/flutter.
  Creates a symlink at /usr/local/bin/flutter for easy access.
  Updates your shell RC file (.zshrc or .bashrc) with PATH configuration.

EXAMPLES:
  $0 https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.35.7-stable.tar.xz

FIND TARBALL:
  https://docs.flutter.dev/install/manual

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

SDK_URL="$1"

# ---- helpers ---------------------------------------------------------------
msg(){ printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die(){ printf '\n\033[1;31m!! %s\033[0m\n' "$*" >&2; exit 1; }

# pick rc file
SHELL_NAME="$(basename "${SHELL:-sh}")"
if [ "$SHELL_NAME" = "zsh" ]; then
  RCFILE="$HOME/.zshrc"
else
  RCFILE="$HOME/.bashrc"
fi

# constants/paths
INSTALL_DIR="/opt/flutter"                 # flutter tree lives here
BIN_SYMLINK="/usr/local/bin/flutter"       # user-facing executable
MARK_START="# >>> FLUTTER (managed by setup-flutter) >>>"
MARK_END="# <<< FLUTTER (managed by setup-flutter) <<<"

# ---- prerequisites ---------------------------------------------------------
msg "Installing prerequisites (requires sudo)"
if ! command -v sudo >/dev/null 2>&1; then
  die "sudo not found; install it and re-run."
fi
# wget + basic build deps recommended by flutter doctor for Linux desktop
sudo pacman -Syu --needed --noconfirm wget tar cmake ninja pkgconf mesa-utils

# ---- download to temp ------------------------------------------------------
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

TAR_NAME="$(basename "$SDK_URL")"
TAR_PATH="$TMPDIR/$TAR_NAME"

msg "Downloading Flutter SDK: $SDK_URL"
wget -qO "$TAR_PATH" "$SDK_URL" || die "Failed to download Flutter SDK."

# ---- extract & stage -------------------------------------------------------
msg "Extracting Flutter SDK (staged)"
# tarball contains a top-level 'flutter' dir
tar -xJf "$TAR_PATH" -C "$TMPDIR" 2>/dev/null || tar -xzf "$TAR_PATH" -C "$TMPDIR" 2>/dev/null || die "Unknown archive format."
[ -d "$TMPDIR/flutter" ] || die "Expected 'flutter' directory in archive."

STAGE_DIR="$TMPDIR/flutter"

# ---- install atomically ----------------------------------------------------
msg "Installing to $INSTALL_DIR (requires sudo)"
sudo mkdir -p "$(dirname "$INSTALL_DIR")"
if [ -d "$INSTALL_DIR" ]; then
  sudo rm -rf "${INSTALL_DIR}.bak" || true
  sudo mv "$INSTALL_DIR" "${INSTALL_DIR}.bak"
fi
sudo mv "$STAGE_DIR" "$INSTALL_DIR"
[ -d "${INSTALL_DIR}.bak" ] && sudo rm -rf "${INSTALL_DIR}.bak" || true

# ---- symlink ---------------------------------------------------------------
msg "Linking $BIN_SYMLINK -> $INSTALL_DIR/bin/flutter"
sudo mkdir -p "$(dirname "$BIN_SYMLINK")"
sudo ln -sf "$INSTALL_DIR/bin/flutter" "$BIN_SYMLINK"

# ---- shell rc block (no duplicates) ---------------------------------------
msg "Adding PATH to $RCFILE"
if [ -f "$RCFILE" ] && grep -qF "$MARK_START" "$RCFILE"; then
  # remove existing managed block
  awk -v s="$MARK_START" -v e="$MARK_END" '
    $0==s {skip=1}
    !skip {print}
    $0==e {skip=0}
  ' "$RCFILE" > "$RCFILE.tmp" && mv "$RCFILE.tmp" "$RCFILE"
fi

cat >> "$RCFILE" <<'EOF'

# >>> FLUTTER (managed by setup-flutter) >>>
# Prefer symlinked flutter first; fall back to /opt/flutter/bin explicitly
if ! command -v flutter >/dev/null 2>&1; then
  export PATH="/usr/local/bin:$PATH"
fi
if [ -d "/opt/flutter/bin" ] && [[ ":$PATH:" != *":/opt/flutter/bin:"* ]]; then
  export PATH="/opt/flutter/bin:$PATH"
fi
# <<< FLUTTER (managed by setup-flutter) <<<
EOF

# ---- current shell PATH ----------------------------------------------------
export PATH="/usr/local/bin:/opt/flutter/bin:$PATH"

# ---- quick sanity checks ---------------------------------------------------
msg "Verifying Flutter"
which flutter || die "flutter not found on PATH"
readlink -f "$(command -v flutter)"
flutter --version

msg "Running flutter doctor (non-fatal if Android pieces missing)"
flutter doctor -v || true

msg "Done! Open a NEW shell so $RCFILE changes take effect."

