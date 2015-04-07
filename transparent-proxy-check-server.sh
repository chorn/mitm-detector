#!/usr/bin/env bash

sudo nping --tcp --echo-server "mitm-check" --echo-port 59031 -p 80 -vvv

