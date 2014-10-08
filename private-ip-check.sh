#!/usr/bin/env bash

ip=$1

if [[ $ip =~ ^127\. || $ip =~ ^10\. || $ip =~ ^172\.1[6-9]\. || $ip =~ ^172\.2[0-9]\. || $ip =~ ^172\.3[0-1]\. || $ip =~ ^192\.168\. ]] ; then
  echo 0
else
  echo 1
fi
