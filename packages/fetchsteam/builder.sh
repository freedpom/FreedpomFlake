#!/usr/bin/env bash
set -euo pipefail

# Standard stdenv setup
source "$stdenv/setup"

: "${out:?}"

export HOME
HOME="$(mktemp -d)"

args=()

# Core app/depot info
if [ -n "${STEAM_APP_ID:-}" ]; then args+=(-app "$STEAM_APP_ID"); fi
if [ -n "${STEAM_DEPOT_ID:-}" ]; then args+=(-depot "$STEAM_DEPOT_ID"); fi
if [ -n "${STEAM_MANIFEST_ID:-}" ]; then args+=(-manifest "$STEAM_MANIFEST_ID"); fi

# Workshop
if [ -n "${STEAM_UGC_ID:-}" ]; then args+=(-ugc "$STEAM_UGC_ID"); fi
if [ -n "${STEAM_PUBFILE_ID:-}" ]; then args+=(-pubfile "$STEAM_PUBFILE_ID"); fi

# Branch and password
if [ -n "${STEAM_BRANCH:-}" ]; then args+=(-branch "$STEAM_BRANCH"); fi
if [ -n "${STEAM_BRANCH_PASSWORD:-}" ]; then args+=(-branchpassword "$STEAM_BRANCH_PASSWORD"); fi

# Authentication
if [ -n "${STEAM_USERNAME:-}" ]; then args+=(-username "$STEAM_USERNAME"); fi
if [ -n "${STEAM_PASSWORD:-}" ]; then args+=(-password "$STEAM_PASSWORD"); fi
if [ -n "${STEAM_REMEMBER_PASSWORD:-}" ]; then args+=(-remember-password); fi

# OS / architecture
if [ -n "${STEAM_OS:-}" ]; then args+=(-os "$STEAM_OS"); fi
if [ -n "${STEAM_OSARCH:-}" ]; then args+=(-osarch "$STEAM_OSARCH"); fi
if [ -n "${STEAM_ALL_PLATFORMS:-}" ]; then args+=(-all-platforms); fi
if [ -n "${STEAM_ALL_ARCHS:-}" ]; then args+=(-all-archs); fi
if [ -n "${STEAM_ALL_LANGUAGES:-}" ]; then args+=(-all-languages); fi
if [ -n "${STEAM_LANGUAGE:-}" ]; then args+=(-language "$STEAM_LANGUAGE"); fi
if [ -n "${STEAM_LOWVIOLENCE:-}" ]; then args+=(-lowviolence); fi

# Filelist
if [ -n "${STEAM_FILELIST:-}" ]; then args+=(-filelist "$STEAM_FILELIST"); fi

# Other options
if [ -n "${STEAM_VALIDATE:-}" ]; then args+=(-validate); fi
if [ -n "${STEAM_MANIFEST_ONLY:-}" ]; then args+=(-manifest-only); fi
if [ -n "${STEAM_CELLID:-}" ]; then args+=(-cellid "$STEAM_CELLID"); fi
if [ -n "${STEAM_MAX_DOWNLOADS:-}" ]; then args+=(-max-downloads "$STEAM_MAX_DOWNLOADS"); fi
if [ -n "${STEAM_USE_LANCACHE:-}" ]; then args+=(-use-lancache); fi
if [ -n "${STEAM_DEBUG:-}" ]; then args+=(-debug); fi

# Output directory
args+=(-dir "$out")

# Optional hooks
if [ -n "${STEAM_PREFETCH:-}" ]; then eval "$STEAM_PREFETCH"; fi

# Run DepotDownloader
DepotDownloader "${args[@]}"
parallel -j "${STEAM_MAX_DOWNLOADS:-5}" "DepotDownloader -app $STEAM_APP_ID -pubfile {} -dir $out" ::: $MODLIST

# Cleanup
rm -rf "$out/.DepotDownloader"

# Post-fetch hook
if [ -n "${STEAM_POSTFETCH:-}" ]; then eval "$STEAM_POSTFETCH"; fi
