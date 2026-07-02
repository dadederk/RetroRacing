#!/usr/bin/env bash
set -euo pipefail

# Upload RetroRapid! 1.5 to TestFlight using the Mestre hybrid workflow:
#   1. xcodebuild archive (Xcode 26)
#   2. xcodebuild -exportArchive with destination=upload
#   3. helm-asc build update + attach (compliance, What to Test, beta groups)
#
# Scope: iOS (includes watchOS) + macOS. TestFlight beta only — not App Store review.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HELM="${HELM:-/Applications/Helm.app/Contents/Helpers/helm-asc}"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR

APP_ID="6758641625"
VERSION="1.5"
BUILD_NUMBER="28"
SCHEME="RetroRacingUniversal"
PROJECT="$ROOT/RetroRacing/RetroRacing.xcodeproj"
BUILD_DIR="$ROOT/build/testflight-1.5"
UPLOAD_PLIST="$ROOT/AppStore/testflight/ExportOptions-upload.plist"
WHATS_NEW_FILE="$ROOT/AppStore/testflight/beta-notes/en-US/whats-new.txt"
EXTERNAL_GROUP="${TESTFLIGHT_EXTERNAL_GROUP:-df40f833-12c7-4411-b28d-122690045c58}"
POLL_ATTEMPTS="${POLL_ATTEMPTS:-40}"
POLL_INTERVAL="${POLL_INTERVAL:-15}"

usage() {
  cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  archive       Archive iOS and macOS with Xcode 26
  upload-ios    Upload iOS archive to App Store Connect, then configure via Helm
  upload-mac    Upload macOS archive to App Store Connect, then configure via Helm
  all           archive → upload-ios → upload-mac

Environment:
  HELM                         Path to helm-asc
  DEVELOPER_DIR                Xcode 26 toolchain (default: /Applications/Xcode.app)
  TESTFLIGHT_EXTERNAL_GROUP    Beta group ID for attach (default: External Testing)
  POLL_ATTEMPTS / POLL_INTERVAL  Wait for ASC processing (defaults: 40 × 15s)

Prerequisites:
  - Active Helm auth
  - Marketing version $VERSION and build $BUILD_NUMBER in RetroRacingUniversal + Watch
EOF
}

require_helm() {
  if [[ ! -x "$HELM" ]]; then
    echo "Helm CLI not found at: $HELM" >&2
    exit 1
  fi
}

require_whats_new() {
  if [[ ! -f "$WHATS_NEW_FILE" ]]; then
    echo "Missing What to Test copy: $WHATS_NEW_FILE" >&2
    exit 1
  fi
}

archive_ios() {
  mkdir -p "$BUILD_DIR"
  xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination 'generic/platform=iOS' \
    -archivePath "$BUILD_DIR/RetroRacingUniversal-iOS.xcarchive" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=PV9S9FTZF2 \
    -allowProvisioningUpdates
}

archive_mac() {
  mkdir -p "$BUILD_DIR"
  xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination 'generic/platform=macOS' \
    -archivePath "$BUILD_DIR/RetroRacingUniversal-macOS.xcarchive" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=PV9S9FTZF2 \
    -allowProvisioningUpdates
}

upload_archive() {
  local archive_path="$1"
  echo "Uploading archive to App Store Connect: $archive_path"
  xcodebuild -exportArchive \
    -archivePath "$archive_path" \
    -exportOptionsPlist "$UPLOAD_PLIST" \
    -allowProvisioningUpdates
}

extract_build_id() {
  /usr/bin/python3 -c '
import json, sys
data = json.load(sys.stdin)
if isinstance(data, dict) and "id" in data:
    print(data["id"])
elif isinstance(data, list) and data and "id" in data[0]:
    print(data[0]["id"])
'

}

wait_for_build_id() {
  local helm_platform="$1"
  local attempt=1

  require_helm

  while (( attempt <= POLL_ATTEMPTS )); do
    echo "Polling App Store Connect for $helm_platform build $VERSION ($BUILD_NUMBER)... ($attempt/$POLL_ATTEMPTS)" >&2
    local result
    result="$("$HELM" apps "$APP_ID" builds --platform "$helm_platform" --version "$VERSION" --number "$BUILD_NUMBER" --agent 2>&1 || true)"

    if build_id="$(printf '%s' "$result" | extract_build_id)"; then
      if [[ -n "$build_id" ]]; then
        echo "$build_id"
        return 0
      fi
    fi

    sleep "$POLL_INTERVAL"
    attempt=$((attempt + 1))
  done

  echo "Timed out waiting for $helm_platform build $VERSION ($BUILD_NUMBER) in App Store Connect." >&2
  return 1
}

configure_testflight_build() {
  local build_id="$1"
  local helm_platform="$2"
  local whats_new
  whats_new="$(<"$WHATS_NEW_FILE")"

  require_helm
  require_whats_new

  echo "Configuring build $build_id via Helm..."
  "$HELM" build "$build_id" update \
    --uses-non-exempt-encryption false \
    --locale en-US \
    --whats-new "$whats_new" \
    --agent

  echo "Attaching build $build_id to External Testing..."
  "$HELM" build "$build_id" attach \
    --groups "$EXTERNAL_GROUP" \
    --agent

  echo "Final build state:"
  "$HELM" apps "$APP_ID" builds --platform "$helm_platform" --version "$VERSION" --number "$BUILD_NUMBER" --agent
}

upload_ios() {
  upload_archive "$BUILD_DIR/RetroRacingUniversal-iOS.xcarchive"
  local build_id
  build_id="$(wait_for_build_id iOS)"
  configure_testflight_build "$build_id" iOS
}

upload_mac() {
  upload_archive "$BUILD_DIR/RetroRacingUniversal-macOS.xcarchive"
  local build_id
  build_id="$(wait_for_build_id macOS)"
  configure_testflight_build "$build_id" macOS
}

cmd="${1:-}"
case "$cmd" in
  archive)
    archive_ios
    archive_mac
    ;;
  upload-ios)
    upload_ios
    ;;
  upload-mac)
    upload_mac
    ;;
  all)
    archive_ios
    archive_mac
    upload_ios
    upload_mac
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage
    exit 1
    ;;
esac
