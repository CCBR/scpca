#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 PARAMS_FILE" >&2
  exit 2
fi

cd "$(dirname "$0")/../.."

output="$(
  nextflow -log /dev/null run tests/biowulf/reference_paths.nf \
    -params-file "$1" \
    -ansi-log false
)"

printf '%s\n' "$output"

missing_root="${TMPDIR:-/tmp}/scpca-biowulf-missing-reference-$$"
if [[ -e "$missing_root" ]]; then
  printf 'Refusing to use existing negative-control path: %s\n' "$missing_root" >&2
  exit 1
fi

if missing_output="$(
  nextflow -log /dev/null run tests/biowulf/reference_paths.nf \
    -ansi-log false \
    --ref_rootdir "$missing_root" \
    2>&1
)"; then
  printf 'Expected the missing-reference control to fail for %s\n' "$missing_root" >&2
  exit 1
fi

if ! grep -Fq 'Required local reference is missing:' <<<"$missing_output"; then
  printf 'Missing-reference control failed for an unexpected reason:\n%s\n' "$missing_output" >&2
  exit 1
fi

printf 'Missing-reference control failed as expected: %s\n' "$missing_root"
