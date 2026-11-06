#!/bin/sh
set -eu

PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$PROJECT_ROOT"

if ! command -v swiftlint >/dev/null 2>&1; then
    echo "error: SwiftLint is missing. Install it with: brew install swiftlint" >&2
    exit 1
fi

exec swiftlint lint --strict --no-cache --config .swiftlint.yml "$@"
