#!/bin/zsh --no-rcs
#
# build-pkg.sh
#
# Builds the App Auto-Patch installer pkg. Shared by local/manual testing and
# the release-pkg GitHub Actions workflow, so both produce an identical
# artifact.
#
# Build is a two-stage pkgbuild + productbuild process:
#   1. pkgbuild produces a payload-free "component" pkg. Its postinstall
#      script (Resources/Packaging/postinstall) stages the current
#      App-Auto-Patch-via-Dialog.zsh to a temp folder and runs it once,
#      letting the script's own self-install logic take over (copy itself
#      into /Library/Management/AppAutoPatch, create the LaunchDaemon, and
#      hand off to it via restart_aap()).
#   2. productbuild wraps that component pkg into the final, versioned
#      product pkg using distribution.xml, adding plain-text Introduction
#      (welcome) and Read Me (readme) panes (see Resources/Packaging/
#      Resources) plus the AAP logo as a bottom-left background watermark.
#
# Signing: if a "Developer ID Installer" identity is available in the
# default keychain search list (locally: your login keychain: in CI: a
# temporary keychain the workflow imports it into), the product pkg is
# signed automatically with --timestamp. No identity found -> build proceeds
# unsigned with a warning, so local dev iteration never requires a cert.
#
# Notarization: if NOTARY_API_KEY_PATH, NOTARY_API_KEY_ID, and
# NOTARY_API_ISSUER_ID are all set in the environment, the signed pkg is
# submitted to Apple notary service and stapled. Skipped otherwise.
#
# Usage:
#   Resources/Packaging/build-pkg.sh [output-directory]
#
# Output directory defaults to the repo root. Prints the built pkg's path on
# stdout, and, when running inside GitHub Actions, also writes it to
# $GITHUB_OUTPUT as `pkg_path`.

set -e

packaging_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "${packaging_dir}/../.." && pwd)"
script_name="App-Auto-Patch-via-Dialog.zsh"
script_path="${repo_root}/${script_name}"
logo_path="${repo_root}/Images/AAPLogo.png"
output_dir="${1:-${repo_root}}"

if [[ ! -f "${script_path}" ]]; then
    echo "ERROR: Could not find ${script_path}" >&2
    exit 1
fi

if [[ ! -f "${logo_path}" ]]; then
    echo "ERROR: Could not find ${logo_path}" >&2
    exit 1
fi

# Anchored to the start of the line so only the actual assignment is matched
# (same fix applied elsewhere in the script for Installomator version parsing).
script_version=$(grep -m1 '^scriptVersion=' "${script_path}" | sed -E 's/^scriptVersion="([^"]*)"$/\1/')
script_build=$(grep -m1 '^scriptBuild=' "${script_path}" | sed -E 's/^scriptBuild="([^"]*)"$/\1/')

if [[ -z "${script_version}" ]] || [[ -z "${script_build}" ]]; then
    echo "ERROR: Could not parse scriptVersion/scriptBuild from ${script_path}" >&2
    exit 1
fi

echo "Building pkg for App Auto-Patch ${script_version} (build ${script_build})"

scratch_dir=$(mktemp -d /tmp/AppAutoPatchPkgBuild.XXXXXX)
trap 'rm -rf "${scratch_dir}"' EXIT

# --- Stage 1: payload-free component pkg (script + postinstall) ---
scripts_dir="${scratch_dir}/scripts"
mkdir -p "${scripts_dir}"
cp "${packaging_dir}/postinstall" "${scripts_dir}/postinstall"
chmod 755 "${scripts_dir}/postinstall"
cp "${script_path}" "${scripts_dir}/${script_name}"
chmod 755 "${scripts_dir}/${script_name}"

component_pkg="${scratch_dir}/AppAutoPatchComponent.pkg"
pkgbuild --nopayload \
    --identifier "xyz.techitout.appAutoPatch.installer" \
    --scripts "${scripts_dir}" \
    "${component_pkg}"

# --- Stage 2: distribution resources (Introduction/Read Me panes + logo) ---
# Plain text (not HTML) - Installer.app's welcome/readme HTML renderer does
# not reliably support embedded images and has been observed to fall back to
# showing raw markup as text on some macOS versions, so plain .txt panes are
# used instead. The logo is shown via the distribution.xml
# <background>/<background-darkAqua> elements (the officially documented,
# reliably-supported mechanism for pane artwork) at native resolution, so it
# renders as a bottom-left watermark, clipped by the pane edges.
resources_dir="${scratch_dir}/Resources"
mkdir -p "${resources_dir}"
cp "${packaging_dir}/Resources/welcome.txt" "${resources_dir}/welcome.txt"
cp "${packaging_dir}/Resources/readme.txt" "${resources_dir}/readme.txt"
cp "${logo_path}" "${resources_dir}/AAPLogo.png"

# --- Stage 3: signing identity auto-detection ---
sign_args=()
identity_line=$(security find-identity -v -p basic 2>/dev/null | grep '"Developer ID Installer:' | head -1 || true)
if [[ -n "${identity_line}" ]]; then
    sign_identity=$(echo "${identity_line}" | sed -E 's/^[[:space:]]*[0-9]+\) [A-F0-9]+ "(.*)"$/\1/')
    echo "Signing with identity: ${sign_identity}"
    sign_args=(--sign "${sign_identity}" --timestamp)
else
    echo "WARNING: No 'Developer ID Installer' identity found - building unsigned pkg." >&2
fi

# --- Stage 4: productbuild - wrap component pkg + distribution.xml ---
mkdir -p "${output_dir}"
pkg_name="AppAutoPatch-${script_version}.pkg"
pkg_path="${output_dir}/${pkg_name}"

productbuild --distribution "${packaging_dir}/distribution.xml" \
    --package-path "${scratch_dir}" \
    --resources "${resources_dir}" \
    --version "${script_build}" \
    "${sign_args[@]}" \
    "${pkg_path}"

echo "Built: ${pkg_path}"

# --- Stage 5: notarization + stapling (only if credentials are present) ---
if [[ -n "${NOTARY_API_KEY_PATH:-}" ]] && [[ -n "${NOTARY_API_KEY_ID:-}" ]] && [[ -n "${NOTARY_API_ISSUER_ID:-}" ]]; then
    echo "Submitting ${pkg_name} for notarization..."
    xcrun notarytool submit "${pkg_path}" \
        --key "${NOTARY_API_KEY_PATH}" \
        --key-id "${NOTARY_API_KEY_ID}" \
        --issuer "${NOTARY_API_ISSUER_ID}" \
        --wait
    echo "Stapling notarization ticket..."
    xcrun stapler staple "${pkg_path}"
else
    echo "Notarization credentials not set - skipping notarization."
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "pkg_path=${pkg_path}" >> "${GITHUB_OUTPUT}"
fi
