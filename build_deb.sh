#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${THEOS:-}" ]]; then
  echo "THEOS is not set. Example: export THEOS=\$HOME/theos" >&2
  exit 1
fi

if [[ ! -d "${THEOS}/makefiles" ]]; then
  echo "Theos not found at: ${THEOS}" >&2
  exit 1
fi

make clean package FINALPACKAGE=1 "$@"

src="$(find packages -maxdepth 1 -type f -name '*.deb' ! -name 'Rxaa*.deb' | head -n 1)"
if [[ -z "${src}" ]]; then
  echo "No .deb was produced in packages/" >&2
  exit 1
fi

if [[ "${THEOS_PACKAGE_SCHEME:-}" == "rootless" ]]; then
  target="packages/Rxaa-rootless.deb"
else
  target="packages/Rxaa.deb"
fi

cp "${src}" "${target}"
echo
echo "Built package: ${src}"
echo "Named copy:    ${target}"
