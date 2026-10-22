#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${THEOS:-}" ]]; then
  echo "THEOS is not set. Example: export THEOS=\$HOME/theos" >&2
  exit 1
fi

if [[ ! -x "${THEOS}/bin/makefiles" && ! -d "${THEOS}/makefiles" ]]; then
  echo "Theos not found at: ${THEOS}" >&2
  exit 1
fi

make clean package FINALPACKAGE=1 "$@"
echo
echo "Built packages:"
ls -1 packages/*.deb 2>/dev/null || true
