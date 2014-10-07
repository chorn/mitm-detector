#!/usr/bin/env bash

BASE=$(
  prg=$0
  case $prg in
    (*/*) ;;
    (*) [ -e "$prg" ] || prg=$(command -v -- "$0")
  esac
  cd -P -- "$(dirname -- "$prg")" && pwd -P
)

usage() {
	echo "Usage: ${0##*/} [-h|--help] <hostname> [port]"
  echo "  443 is the default port if it is not specified"
  echo "  openssl must be in your path"
	exit 1
}

[[ $# -eq 0 || $1 =~ -h || $1 =~ \.\. || $1 =~ / ]] && usage
command -v openssl >/dev/null 2>/dev/null || usage

PORT=443
HOST="$1"
[[ $2 =~ [0-9]+ ]] && PORT=${BASH_REMATCH[0]}

CAPATH="${BASE}/ca"
DUMP="${HOST}.dump"
CERT="${BASE}/certs/${HOST}.pem"

if openssl s_client -connect "${HOST}:${PORT}" -showcerts -CApath "${CAPATH}" < /dev/null >& "${DUMP}" ; then
	openssl x509 -in "${DUMP}" -out "${CERT}"
	echo "Certificate written to: ${CERT}"
	openssl x509 -issuer -subject -fingerprint -enddate -noout -in "${CERT}"
else
	cat "${DUMP}"
fi

[[ -f "${DUMP}" ]] && rm "${DUMP}"

