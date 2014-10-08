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
	echo "Usage: ${0##*/} [--echo-port <number>] [--port <number>] [--crypto passphrase]  [--echo-server hostname]"
  echo "  -h|--help        this help"
  echo "  -e|--echo-port   59031 is the default echo-port if it is not specified"
  echo "  -p|--port        80 is the default port tested for transparent proxies"
  echo "  -s|--echo-server mitm-check.chorn.com is the default echo-server if it is not specified"
  echo "  -c|--crypto      mitm-check is the default passphrase, and the one you have to user for mitm-check.chorn.com."
  echo " nping, dig, tcpdump must all be in your path, and you'll need sudo privs"
	exit 1
}

command -v nping >/dev/null 2>/dev/null || usage
command -v dig >/dev/null 2>/dev/null || usage
command -v tcpdump >/dev/null 2>/dev/null || usage

declare echo_server="mitm-check.chorn.com"
declare -i echo_port=59031
declare -i port=80
declare passphrase="mitm-check"
declare -i total=10

while [[ $# -gt 1 ]] ; do
  curr_arg="$1" ; shift
  if [[ $# -gt 0 ]] ; then next_arg="$1" ; shift ; else next_arg="" ; fi
  case "$curr_arg" in
    -e|--echo-port)   echo_port=$next_arg ;;
    -p|--port)        port=$next_arg ;;
    -s|--echo-server) echo_server=$next_arg ;;
    -c|--crypto)      passphrase=$next_arg ;;
    -h|--help|help)   usage ;;
  esac
done

gateway=""
interface=""

declare -i local_nameserver=$(grep -c '^nameserver  *127\.' /etc/resolv.conf)
opendns="@208.67.222.222"
nameserver=""

if [[ $local_nameserver -gt 0 ]] ; then
  # nameserver running locally, hopefully, probably, for dnscrypt-proxy
  dnscrypt=$(which dnscrypt-proxy)
  # true story, free wifi lies
else
  nameserver=$opendns
fi

internet_ip=$(dig +short $nameserver myip.opendns.com)
server_ip=$(dig +short $nameserver $echo_server)

if [ "${OSTYPE:0:6}" = "darwin" ] ; then
  gateway=$(route -n get default | grep gateway | sed -e 's/^.*: //')
  interface=$(route -n get default | grep interface | sed -e 's/^.*: //')
else
  gateway=$(ip route list | grep 'default via' | sed -e 's/^default via //' -e 's/ .*//')
  interface=$(ip route list | grep 'default via' | sed -e 's/^.*dev //')
fi

local_ip=$(ifconfig $interface | grep 'inet ' | sed -e 's/^.*inet //' -e 's/addr://' -e 's/ .*$//')
declare -i private_ip=$("$BASE/private-ip-check.sh" $local_ip)

echo "Default Gateway:   $gateway"
echo "Default Interface: $interface"

declare -i target=$(($total))

if [[ $private_ip -eq 0 ]] ; then
  echo "IPv4 Local:        $local_ip (Private Network Block, assuming NAT)"
  let target--
elif [[ $local_ip != $internet_ip ]] ; then
  echo "IPv4 Local:        $local_ip (Your external IP is different)"
  let target--
fi

echo "IPv4 Internet:     $internet_ip"

# sudo nmap --traceroute -n -T4 mitm-check.chorn.com -p 80

params=(
--echo-client "$passphrase"
--echo-port $echo_port
--tcp
-p $port
-c $total
-v2
$echo_server
)
# --bpf-filter "((src host $local_ip and dst host $echo_server) or (src host $echo_server and dst host $local_ip)) and tcp and not port $echo_port"

echo "Running nping echo-client (requires sudo), this should take about $total seconds..."

# Did we lose any packets?
declare -i lost
declare -a sent
declare -a capt
declare -a rcvd

while read line ; do
  case ${line} in
  (SENT*) sent+=("$line") ;;
  (CAPT*) capt+=("$line") ;;
  (RCVD*) rcvd+=("$line") ;;
  (Raw*)
    snip=${line/*Lost: /}
    lost=${snip/ */}
    ;;
  (*) ;;
esac
done < <(sudo nping ${params[@]} 2>nping.stderr | sed -e "s/^\([A-Z]*\) (.*) TCP \[\([0-9\.]*\):[0-9]* > \([0-9\.]*\):[0-9]* \([A-Z]*\) .*$/\1 \2 \3 \4/" -e "s/${internet_ip//./\\.}/INTERNET_IP/" -e "s/${local_ip//./\\.}/LOCAL_IP/" -e "s/${server_ip//./\\.}/SERVER_IP/" -e "s/${gateway_ip//./\\.}/GATEWAY_IP/")

[[ $! ]] && cat nping.stderr
[[ -f nping.stderr ]] && sudo rm nping.stderr

echo ${sent[@]} ${rcvd[@]} ${capt[@]} | grep '[0-9]'

declare ok=0

if [[ ${#sent[@]} -eq $total ]] ; then
  let ok++
else
  echo "SENT should be $total, observed ${#sent[@]}:"
  for line in "${sent[@]}" ; do echo $line ; done
fi

if (( ${#rcvd[@]} == ($total - $lost) )) ; then
  let ok++
else
  echo "RCVD should be $total, observed ${#rcvd[@]}:"
  for line in "${rcvd[@]}" ; do echo $line ; done
fi

if [[ ${#capt[@]} -ge $target ]] ; then
  let ok++
else
  echo "CAPT should be at least $target, observed ${#capt[@]}:"
  for line in "${capt[@]}" ; do echo $line ; done
fi

if [[ $ok -eq 3 ]] ; then
  echo "OK"
elif [[ $ok -eq 2 ]] ; then
  echo "There might be a transparent proxy? Run this again and compare the results."
  echo ${sent[@]} ${rcvd[@]} ${capt[@]} | grep '[0-9]'
else
  echo "Something is misconfigured or unreachable."
fi


