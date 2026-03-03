#!/bin/bash
set -e

echo "📦 Building iOS IPA via Xcode..."

# Paths
ARCHIVE_PATH="build/testflight/Runner.xcarchive"
EXPORT_PATH="build/testflight/export"
EXPORT_OPTIONS="ci/testflight/ExportOptions.plist"

# Default env = dev
ENVIRONMENT="dev"

# Parse args
IS_PUBLISH=false
SPECIFIC_VERSION=""

for ((i=1; i<=$#; i++)); do
  if [[ ${!i} == "--publish" ]]; then
    IS_PUBLISH=true
  fi
  if [[ ${!i} == "--version" ]]; then
    j=$((i+1))
    SPECIFIC_VERSION=${!j}
  fi
  if [[ ${!i} == "--env" ]]; then
    j=$((i+1))
    ENVIRONMENT=${!j}
  fi
done

echo "🌍 Environment: $ENVIRONMENT"
echo "🚀 Publish: $IS_PUBLISH"
if [[ -n "$SPECIFIC_VERSION" ]]; then
  echo "🏷️ Specific version: $SPECIFIC_VERSION"
fi

# Step 1: Auto version update
parse_pubspec_version() {
  version_line=$(grep '^version:' pubspec.yaml | cut -d ':' -f2 | xargs)
  BUILD_NAME=$(echo "$version_line" | cut -d '+' -f1)
  BUILD_NUMBER=$(echo "$version_line" | cut -d '+' -f2)
}

set_version_to_pubspec() {
  sed -i '' "s/^version: .*/version: $1+$2/" pubspec.yaml
  echo "✅ Đã cập nhật pubspec.yaml → version: $1+$2"
}

if $IS_PUBLISH; then
  parse_pubspec_version

  if [[ -n "$SPECIFIC_VERSION" ]]; then
    NEW_BUILD_NAME="$SPECIFIC_VERSION"
    NEW_BUILD_NUMBER=1
    set_version_to_pubspec "$NEW_BUILD_NAME" "$NEW_BUILD_NUMBER"
  else
    NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
    echo "🔢 Phiên bản hiện tại: $BUILD_NAME.$BUILD_NUMBER"
    echo "📈 Đề xuất tăng thành: $BUILD_NAME.$NEW_BUILD_NUMBER"

    read -p "❓ Bạn có muốn tự động tăng version và cập nhật pubspec.yaml không? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      set_version_to_pubspec "$BUILD_NAME" "$NEW_BUILD_NUMBER"
    else
      echo "⏭️ Bỏ qua cập nhật version."
    fi
  fi
fi

# Clean build folders
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
mkdir -p "$EXPORT_PATH"

# Step 2: Build archive
flutter pub get
flutter build ios --release --no-codesign --dart-define=ENV=$ENVIRONMENT

xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -sdk iphoneos \
  -archivePath "$ARCHIVE_PATH" \
  archive

# Step 3: Export IPA
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -exportPath "$EXPORT_PATH" \
  -allowProvisioningUpdates

# Step 4: Find IPA
IPA_PATH=$(find "$EXPORT_PATH" -type f -name "*.ipa" | head -n 1)
if [ ! -f "$IPA_PATH" ]; then
  echo "❌ Export thành công nhưng không tìm thấy file .ipa"
  echo "🔍 Kiểm tra trong thư mục: $EXPORT_PATH"
  ls -al "$EXPORT_PATH"
  exit 1
fi

echo "✅ IPA created at: $IPA_PATH"

# Step 5: Upload nếu có --publish
if $IS_PUBLISH; then
  echo "🚀 Uploading to TestFlight..."

  if [ ! -f ci/.env.ci ]; then
    echo "❌ Thiếu file ci/.env.ci"
    exit 1
  fi

  export $(cat ci/.env.ci | xargs)

  if [ -z "$APPSTORE_CONNECT_KEY_ID" ] || [ -z "$APPSTORE_CONNECT_ISSUER_ID" ]; then
    echo "❌ Thiếu APPSTORE_CONNECT_KEY_ID hoặc APPSTORE_CONNECT_ISSUER_ID trong .env.ci"
    exit 1
  fi

  # Đường dẫn đến tệp .p8
  API_KEY_PATH="ci/testflight/AuthKey_$APPSTORE_CONNECT_KEY_ID.p8"

  # Thông tin API Key
  KEY_ID="$APPSTORE_CONNECT_KEY_ID"
  ISSUER_ID="$APPSTORE_CONNECT_ISSUER_ID"

  # Kiểm tra sự tồn tại của tệp .p8
  if [[ ! -f "$API_KEY_PATH" ]]; then
    echo "❌ Không tìm thấy tệp API Key tại $API_KEY_PATH"
    exit 1
  fi

    # Copy về thư mục mặc định để altool sử dụng
  mkdir -p ~/.appstoreconnect/private_keys
  cp "$API_KEY_PATH" ~/.appstoreconnect/private_keys/ || {
    echo "❌ Không thể copy $API_KEY_PATH về ~/.appstoreconnect/private_keys/"
    exit 1
  }

  # Upload tệp .ipa lên App Store Connect
  xcrun altool --upload-app \
    --type ios \
    --file "$IPA_PATH" \
    --apiKey "$KEY_ID" \
    --apiIssuer "$ISSUER_ID"
else
  echo "ℹ️ Bỏ qua upload vì không có --publish"
fi
