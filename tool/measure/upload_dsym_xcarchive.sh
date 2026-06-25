#!/usr/bin/env bash
# Usage: upload_dsym_xcarchive.sh <xcarchive> <api_url> <api_key> [custom_headers] [ipa_path]
# https://github.com/measure-sh/measure/blob/main/docs/features/feature-crash-reporting.md#ios-1

set -euo pipefail

[ "$#" -ge 3 ] || {
  echo "Usage: $0 <xcarchive> <api_url> <api_key> [custom_headers] [ipa_path]"
  exit 1
}
command -v jq >/dev/null || {
  echo "jq is required (brew install jq)"
  exit 1
}

archive=$1 api_url=$2 api_key=$3 raw_headers=${4:-} ipa_path=${5:-}
info_plist="$archive/Info.plist"
dsym_dir="$archive/dSYMs"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

[ -d "$archive" ] || {
  echo "xcarchive not found: $archive"
  exit 1
}
[ -f "$info_plist" ] || {
  echo "Info.plist not found in xcarchive"
  exit 1
}
[ -d "$dsym_dir" ] || {
  echo "dSYMs folder not found in xcarchive"
  exit 1
}

pb() {
  /usr/libexec/PlistBuddy -c "Print :ApplicationProperties:$1" "$info_plist"
}

version_name=$(pb CFBundleShortVersionString)
version_code=$(pb CFBundleVersion)
app_id=$(pb CFBundleIdentifier)

if [ -n "$ipa_path" ] && [ -f "$ipa_path" ]; then
  build_size=$(stat -f%z "$ipa_path")
else
  app_bundle="$archive/Products/Applications/$(basename "$(pb ApplicationPath)")"
  if [ -d "$app_bundle" ]; then
    build_size=$(($(du -sk "$app_bundle" | awk '{print $1}') * 1024))
  else
    build_size=0
  fi
fi

mappings_json='[]'
tgz_names=()
tgz_paths=()

for dsym in "$dsym_dir"/*.dSYM; do
  [ -d "$dsym" ] || continue
  base=$(basename "$dsym")
  tgz_name="$base.tgz"
  tgz_path="$work_dir/$tgz_name"
  tar -czf "$tgz_path" -C "$dsym_dir" "$base"
  tgz_names+=("$tgz_name")
  tgz_paths+=("$tgz_path")
  mappings_json=$(jq -n --argjson mappings "$mappings_json" --arg filename "$tgz_name" \
    '$mappings + [{type: "dsym", filename: $filename}]')
done

[ "${#tgz_names[@]}" -gt 0 ] || {
  echo "No dSYM files found in xcarchive"
  exit 1
}

metadata_file="$work_dir/metadata.json"
jq -n \
  --arg version_name "$version_name" \
  --arg version_code "$version_code" \
  --argjson build_size "$build_size" \
  --arg app_unique_id "$app_id" \
  --argjson mappings "$mappings_json" \
  '{
    version_name: $version_name,
    version_code: $version_code,
    build_size: $build_size,
    build_type: "ipa",
    app_unique_id: $app_unique_id,
    os_name: "ios",
    mappings: $mappings
  }' >"$metadata_file"

meta_args=(
  -sS -w '%{http_code}' -o "$work_dir/response.json"
  -X PUT "$api_url/builds"
  -H "Authorization: Bearer $api_key"
  -H 'Content-Type: application/json'
  --data @"$metadata_file"
)
IFS='|' read -r -a custom_headers <<<"$raw_headers"
for header in "${custom_headers[@]}"; do
  [ -n "$header" ] && meta_args+=(-H "$header")
done

echo "Uploading build metadata..."
status=$(curl "${meta_args[@]}")
case "$status" in
  200 | 201) ;;
  401)
    echo "Invalid api-key; stack traces will not be symbolicated."
    exit 1
    ;;
  413)
    echo "Build size limit exceeded; stack traces will not be symbolicated."
    exit 1
    ;;
  *)
    echo "Metadata upload failed with status $status."
    exit 1
    ;;
esac

tgz_path_for() {
  local expected=$1 i
  for i in "${!tgz_names[@]}"; do
    if [ "${tgz_names[$i]}" = "$expected" ]; then
      echo "${tgz_paths[$i]}"
      return 0
    fi
  done
  return 1
}

upload_file() {
  local object=$1
  local url filename path header status attempt
  url=$(jq -r '.upload_url' <<<"$object")
  filename=$(jq -r '.filename' <<<"$object")
  path=$(tgz_path_for "$filename") || {
    echo "Missing local archive for $filename"
    return 1
  }

  local -a upload_args=(
    -sS -w '%{http_code}' -o /dev/null
    -X PUT "$url"
    --data-binary "@$path"
  )
  while IFS= read -r header; do
    [ -n "$header" ] && upload_args+=(-H "$header")
  done < <(jq -r '.headers | to_entries[] | "\(.key): \(.value)"' <<<"$object")

  for attempt in 1 2 3; do
    echo "  Uploading $filename (attempt $attempt/3)..."
    status=$(curl "${upload_args[@]}")
    if [ "$status" -ge 200 ] && [ "$status" -le 299 ]; then
      echo "  Uploaded $filename"
      return 0
    fi
    [ "$attempt" -lt 3 ] && sleep 1
  done
  echo "  Failed to upload $filename (status $status)"
  return 1
}

echo "Uploading dSYM files..."
failed=0
while IFS= read -r object; do
  upload_file "$object" || failed=1
done < <(jq -c '.mappings[]' "$work_dir/response.json")

if [ "$failed" -eq 0 ]; then
  echo "Successfully uploaded dSYM files to Measure."
else
  echo "Failed to upload one or more dSYM files."
  exit 1
fi
