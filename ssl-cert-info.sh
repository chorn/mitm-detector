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
	echo "Usage: ${0##*/} [-h|--help] <hostname>"
  echo "  openssl must be in your path"
	exit 1
}

[[ $# -eq 0 || $1 =~ -h || $1 =~ \.\. || $1 =~ / ]] && usage
command -v openssl >/dev/null 2>/dev/null || usage



HOST="$1"
CERT="${BASE}/certs/${HOST}.pem"

if [[ ! -f "$CERT" && ! -f "$HOST" ]] ; then
  echo "I can't find a cert for $HOST here: $CERT"
  exit 1
elif [[ ! -f "$CERT" && -f "$HOST" ]] ; then
  CERT="$HOST"
fi

openssl x509 -in "${CERT}" -text -nameopt multiline -certopt no_header,no_version,no_serial,no_pubkey,no_sigdump,ext_default -noout


