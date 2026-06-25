#!/usr/bin/env bash
# Writes native Measure credentials for Android and iOS release builds.
# When unset, empty values are written so local dev builds skip Measure initialization.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MEASURE_API_KEY="${MEASURE_API_KEY:-}"
MEASURE_API_URL="${MEASURE_API_URL:-}"

cat >"${ROOT_DIR}/android/measure.properties" <<EOF
MEASURE_API_KEY=${MEASURE_API_KEY}
MEASURE_API_URL=${MEASURE_API_URL}
EOF

mkdir -p "${ROOT_DIR}/ios/Flutter"
cat >"${ROOT_DIR}/ios/Flutter/MeasureSecrets.xcconfig" <<EOF
MEASURE_API_KEY=${MEASURE_API_KEY}
MEASURE_API_URL=${MEASURE_API_URL}
EOF

if [ -n "${MEASURE_API_KEY}" ] && [ -n "${MEASURE_API_URL}" ]; then
  echo "Measure native config written."
else
  echo "Measure credentials not set; native SDK will remain disabled."
fi
