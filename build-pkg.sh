#!/bin/bash
# Builds a signed and notarized installer for clean-microsoft-accounts.command.
# Run on a Mac with Xcode command line tools:
#
#   ./build-pkg.sh 1.0.0
#
# The installer puts "Clean Microsoft Teams Accounts.command" in /Applications/Utilities.
# It does not run the cleanup. The user double-clicks the file afterwards,
# then deletes it from Applications > Utilities when done.

set -euo pipefail

VERSION="${1:-1.0.0}"
IDENTIFIER="com.mstudio.clean-microsoft-teams-accounts"
SIGN_ID="${SIGN_ID:-Developer ID Installer: Chung Pong Martin Yeung (3H95TBP74D)}"
# Saved once with: xcrun notarytool store-credentials "<name>" --apple-id ... --team-id 3H95TBP74D
NOTARY_PROFILE="${NOTARY_PROFILE:-notary}"

cd "$(dirname "$0")"
OUT_DIR="build"
ROOT="$OUT_DIR/root"
PKG="$OUT_DIR/Clean-Microsoft-Teams-Accounts-$VERSION.pkg"

echo "== Building $PKG"
rm -rf "$OUT_DIR"
mkdir -p "$ROOT/Applications/Utilities"
cp clean-microsoft-accounts.command "$ROOT/Applications/Utilities/Clean Microsoft Teams Accounts.command"
chmod 755 "$ROOT/Applications/Utilities/Clean Microsoft Teams Accounts.command"
# Remove extended attributes (quarantine, Finder info) so they don't end up in the package.
xattr -cr "$ROOT"

pkgbuild \
  --root "$ROOT" \
  --identifier "$IDENTIFIER" \
  --version "$VERSION" \
  --install-location / \
  --ownership recommended \
  --sign "$SIGN_ID" \
  "$PKG"

echo "== Notarizing (this can take a few minutes)"
xcrun notarytool submit "$PKG" --keychain-profile "$NOTARY_PROFILE" --wait

echo "== Stapling"
xcrun stapler staple "$PKG"

echo "== Checking"
pkgutil --check-signature "$PKG"
spctl --assess --type install -vv "$PKG"

echo
echo "Done: $PKG"
