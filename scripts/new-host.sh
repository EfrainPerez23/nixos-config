#!/usr/bin/env bash
# Provisions a new host profile in `hosts/<profile>/` and generates `local/local.nix` (gitignored):
# - Auto-detects GPU (NVIDIA RTX/GTX, AMD, or Intel) via /sys/bus/pci and lspci
# - Generates hardware-configuration.nix (disks, partitions, and EFI mount point)
# - Stores your real username, full name, hostname, and timezone privately in `local/local.nix`
# - Registers the public profile in `flake.nix`

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORCE=0
APPLY=0
HOST_PROFILE=""

for arg in "$@"; do
  case "$arg" in
    --force|-f)
      FORCE=1
      ;;
    --apply|-a)
      APPLY=1
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./scripts/new-host.sh <profile> [--apply] [--force]

Examples:
  ./scripts/new-host.sh pc-rtx
  ./scripts/new-host.sh pc-rtx --apply
  ./scripts/new-host.sh desktop-amd --force

Options:
  --apply, -a   Stage the new host in Git and run the first `nixos-rebuild switch` (installs `just`, `nh`, and enables Flakes)
  --force, -f   Overwrite an existing profile and regenerate `local/local.nix`

Note: <profile> is a generic name for the public repo (e.g. laptop, pc-rtx, desktop-amd).
Your real hostname, username, full name, and timezone are stored only in
`local/local.nix` (gitignored).
EOF
      exit 0
      ;;
    *)
      if [ -z "$HOST_PROFILE" ]; then
        HOST_PROFILE="$arg"
      else
        echo "❌ Unknown argument: $arg" >&2
        exit 1
      fi
      ;;
  esac
done

HOST_PROFILE="${HOST_PROFILE:-desktop}"
HOST_PROFILE="$(printf '%s' "$HOST_PROFILE" | tr '[:upper:]' '[:lower:]')"

if ! [[ "$HOST_PROFILE" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "❌ Invalid profile name: '$HOST_PROFILE' (use lowercase letters, digits, and hyphens only)." >&2
  exit 1
fi

HOST_DIR="$REPO_DIR/hosts/$HOST_PROFILE"
if [ -d "$HOST_DIR" ] && [ "$FORCE" -ne 1 ]; then
  echo "❌ '$HOST_DIR' already exists. Pass --force to overwrite it." >&2
  exit 1
fi

echo "🔍 Inspecting hardware for profile '$HOST_PROFILE'..."

# 1) Detect GPU(s) from PCI sysfs (works even without `lspci` installed)
HAS_NVIDIA=0
HAS_AMD=0
HAS_INTEL=0

for dev in /sys/bus/pci/devices/*; do
  [ -r "$dev/class" ] && [ -r "$dev/vendor" ] || continue
  pci_class="$(cat "$dev/class" 2>/dev/null || true)"
  case "$pci_class" in
    0x03*)
      vendor="$(cat "$dev/vendor" 2>/dev/null || true)"
      case "$vendor" in
        0x10de) HAS_NVIDIA=1 ;;
        0x1002) HAS_AMD=1 ;;
        0x8086) HAS_INTEL=1 ;;
      esac
      ;;
  esac
done

GPU_PROFILE="none"
NVIDIA_OPEN="true"
GPU_NOTE=""

if [ "$HAS_NVIDIA" -eq 1 ]; then
  GPU_PROFILE="nvidia"
  if command -v lspci >/dev/null 2>&1; then
    NV_MODEL="$(lspci -nn | grep -iE 'vga|3d|display' | grep -i nvidia | head -n1 || true)"
    if printf '%s' "$NV_MODEL" | grep -qiE 'GTX (9|10)[0-9]{2}|GT [0-9]{3}|Quadro [KMP]'; then
      NVIDIA_OPEN="false"
    fi
    GPU_NOTE=" ($NV_MODEL)"
  fi
  if [ "$HAS_INTEL" -eq 1 ] || [ "$HAS_AMD" -eq 1 ]; then
    echo "ℹ️  Hybrid GPU detected (iGPU + NVIDIA). Enabling 'nvidia' profile."
    echo "   For Optimus laptops, you can also configure 'hardware.nvidia.prime' in hosts/$HOST_PROFILE/default.nix."
  fi
elif [ "$HAS_AMD" -eq 1 ]; then
  GPU_PROFILE="amd"
  if command -v lspci >/dev/null 2>&1; then
    AMD_MODEL="$(lspci -nn | grep -iE 'vga|3d|display' | grep -iE 'amd|ati' | head -n1 || true)"
    GPU_NOTE=" ($AMD_MODEL)"
  fi
elif [ "$HAS_INTEL" -eq 1 ]; then
  GPU_PROFILE="intel"
  if command -v lspci >/dev/null 2>&1; then
    INTEL_MODEL="$(lspci -nn | grep -iE 'vga|3d|display' | grep -i intel | head -n1 || true)"
    GPU_NOTE=" ($INTEL_MODEL)"
  fi
fi

echo "🎮 Detected GPU: $GPU_PROFILE$GPU_NOTE"

# 2) Detect current EFI mount point (informational; nixos/core/boot.nix auto-detects it)
if mountpoint -q /boot/efi 2>/dev/null; then
  echo "💿 EFI detected at /boot/efi (shared/partitioned disk)."
else
  echo "💿 EFI detected at /boot (dedicated disk or standard layout)."
fi

# 3) Detect local personal settings (saved ONLY in gitignored `local/local.nix`)
REAL_HOSTNAME="$(hostname)"
USER_NAME="${SUDO_USER:-${USER:-myuser}}"
FULL_NAME="$(getent passwd "$USER_NAME" 2>/dev/null | cut -d: -f5 | cut -d, -f1 || true)"
FULL_NAME="${FULL_NAME:-$USER_NAME}"

TIME_ZONE="UTC"
if command -v timedatectl >/dev/null 2>&1; then
  TZ_DETECTED="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
  [ -n "$TZ_DETECTED" ] && TIME_ZONE="$TZ_DETECTED"
elif [ -L /etc/localtime ]; then
  TZ_DETECTED="$(readlink -f /etc/localtime | sed -n 's|.*/zoneinfo/||p' || true)"
  [ -n "$TZ_DETECTED" ] && TIME_ZONE="$TZ_DETECTED"
fi

# 4) Create/update `local/local.nix` (gitignored)
mkdir -p "$REPO_DIR/local"
if [ ! -f "$REPO_DIR/local/local.nix" ] || [ "$FORCE" -eq 1 ]; then
  cat > "$REPO_DIR/local/local.nix" <<EOF
# Private personal and regional settings for this machine (gitignored in .gitignore)
# Never push this file to a public GitHub repository.

{
  hostName = "$REAL_HOSTNAME";
  username = "$USER_NAME";
  fullName = "$FULL_NAME";
  flakeDir = "$REPO_DIR";
  timeZone = "$TIME_ZONE";
  defaultLocale = "en_US.UTF-8";
  extraLocale = "en_US.UTF-8";
  xkbLayout = "us";
  xkbVariant = "";
}
EOF
  echo "🔒 Generated local/local.nix (private, gitignored)."
else
  echo "🔒 Kept existing local/local.nix (pass --force to regenerate)."
fi

# 5) Create public host profile directory and generate hardware-configuration.nix
mkdir -p "$HOST_DIR"

if command -v nixos-generate-config >/dev/null 2>&1; then
  echo "🛠️  Generating hosts/$HOST_PROFILE/hardware-configuration.nix..."
  nixos-generate-config --show-hardware-config > "$HOST_DIR/hardware-configuration.nix"
elif [ -f /etc/nixos/hardware-configuration.nix ]; then
  echo "🛠️  Copying /etc/nixos/hardware-configuration.nix..."
  cp /etc/nixos/hardware-configuration.nix "$HOST_DIR/hardware-configuration.nix"
else
  echo "⚠️  Neither 'nixos-generate-config' nor '/etc/nixos/hardware-configuration.nix' was found."
  echo "   Please copy your hardware-configuration.nix into hosts/$HOST_PROFILE/ manually."
fi

# 6) Generate hosts/<profile>/default.nix (no personal data)
NVIDIA_OPEN_LINE=""
if [ "$GPU_PROFILE" = "nvidia" ]; then
  NVIDIA_OPEN_LINE=$'\n      nvidiaOpen = '"$NVIDIA_OPEN"'; # true for RTX 2000+/GTX 1600+, false for older GPUs'
fi

cat > "$HOST_DIR/default.nix" <<EOF
# Host control panel: $HOST_PROFILE
# Personal settings (username, full name, hostname, timezone) are loaded from \`local/local.nix\` (gitignored).

{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  my = {
    hardware = {
      gpu = "$GPU_PROFILE"; # "intel" | "amd" | "nvidia" | "none"$NVIDIA_OPEN_LINE
    };

    desktop = {
      gnome.enable = true;
      guake.enable = true;
      vicinae.enable = true;
    };

    apps = {
      browsers.enable = true;
      antigravity.enable = true;
    };
  };

  # Initial NixOS state version (do not change after installation)
  system.stateVersion = "26.05";
}
EOF

echo "✅ Created hosts/$HOST_PROFILE/default.nix (no personal data)."

# 7) Register the host profile in flake.nix if not already present
FLAKE_FILE="$REPO_DIR/flake.nix"
if grep -qE "^[[:space:]]*${HOST_PROFILE}[[:space:]]*=" "$FLAKE_FILE"; then
  echo "ℹ️  '$HOST_PROFILE' is already registered in flake.nix."
elif grep -q "# <new-hosts>" "$FLAKE_FILE"; then
  sed -i "s|# <new-hosts>|$HOST_PROFILE = mkHost \"$HOST_PROFILE\" ./hosts/$HOST_PROFILE;\n        # <new-hosts>|" "$FLAKE_FILE"
  echo "✅ Registered '$HOST_PROFILE = mkHost \"$HOST_PROFILE\" ./hosts/$HOST_PROFILE;' in flake.nix"
else
  echo "⚠️  Add this line manually under nixosConfigurations in flake.nix:"
  echo "   $HOST_PROFILE = mkHost \"$HOST_PROFILE\" ./hosts/$HOST_PROFILE;"
fi

if [ "$APPLY" -eq 1 ]; then
  echo ""
  echo "🚀 Staging in Git and applying the initial switch (installs \`just\`, \`nh\`, and enables Flakes)..."
  cd "$REPO_DIR"
  git add "hosts/$HOST_PROFILE" flake.nix
  sudo env NIX_CONFIG="experimental-features = nix-command flakes" \
    nixos-rebuild switch --flake ".#$HOST_PROFILE" --override-input local "path:$REPO_DIR/local"
  echo ""
  echo "✅ Done! From now on just run \`just apply\`, \`just fmt\`, \`just clean\`, or \`nrs\`."
else
  echo ""
  echo "🚀 Next steps to apply this machine:"
  echo "   cd \"$REPO_DIR\""
  echo "   git add hosts/$HOST_PROFILE flake.nix"
  echo "   sudo env NIX_CONFIG=\"experimental-features = nix-command flakes\" nixos-rebuild switch --flake .#$HOST_PROFILE --override-input local path:./local"
  echo ""
  echo "   (After the first switch, \`just\` is installed and you can simply run: just apply or nrs)"
fi
