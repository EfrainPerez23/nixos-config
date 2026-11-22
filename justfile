# Management commands for NixOS + Home Manager
# Quick usage:
#   just                  # List all available commands
#   just dry              # Dry-build without modifying the running system
#   just apply            # Apply configuration (defaults to host="laptop")
#   just apply pc-rtx     # Apply a different host profile

default_host := "laptop"
nix_env := 'env NIX_CONFIG="experimental-features = nix-command flakes"'
local_dir := justfile_directory() + "/local"
override := if path_exists(local_dir + "/local.nix") == "true" { "--override-input local path:" + local_dir } else { "" }

# List all available commands
default:
    @just --list --unsorted

# Evaluate and dry-build without modifying the system
dry host=default_host:
    {{ nix_env }} nixos-rebuild dry-build --flake .#{{ host }} {{ override }}

# Apply the configuration (uses `nh` if installed; otherwise falls back to `nixos-rebuild`)
apply host=default_host:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v nh >/dev/null 2>&1; then
      {{ nix_env }} nh os switch "{{ justfile_directory() }}" -H "{{ host }}" -- {{ override }}
    else
      sudo {{ nix_env }} nixos-rebuild switch --flake ".#{{ host }}" {{ override }}
    fi

# Build the configuration to activate on next reboot
boot host=default_host:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v nh >/dev/null 2>&1; then
      {{ nix_env }} nh os boot "{{ justfile_directory() }}" -H "{{ host }}" -- {{ override }}
    else
      sudo {{ nix_env }} nixos-rebuild boot --flake ".#{{ host }}" {{ override }}
    fi

# Update locked inputs in flake.lock (nixpkgs, home-manager, bootvine)
update:
    {{ nix_env }} nix flake update

# Clean old generations keeping the last 3
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v nh >/dev/null 2>&1; then
      nh clean all --keep 3
    else
      sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +3
      sudo nix-collect-garbage
    fi

# Format all .nix files with the official formatter (nixfmt-tree)
fmt:
    {{ nix_env }} nix fmt -- --tree-root "{{ justfile_directory() }}"

# Audit Nix code with statix and deadnix
lint:
    {{ nix_env }} nix develop --command sh -c 'statix check . && deadnix --fail --exclude hosts/*/hardware-configuration.nix .'

# Enter the Nix development shell (just, nixfmt, nil, statix, deadnix)
dev:
    {{ nix_env }} nix develop

# Provision a new machine by auto-detecting GPU and disks (e.g. just new-host pc-rtx)
new-host host:
    ./scripts/new-host.sh "{{ host }}"
