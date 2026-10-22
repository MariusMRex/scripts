#!/usr/bin/env bash
set -x  # <-- ENABLE DEBUG STATEMENTS.
# snagged from https://www.howtogeek.com/beginner-friendly-ways-to-level-up-your-bash-scripts/

_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

OPTIONS
  -h     display this help menu
  -r     do NOT press this button
  -a     echo something
EOF
}

while getopts "ra:h" opt; do
  case "$opt" in
  r)
    curl 'https://ascii.live/rick'
    ;;
  a)
    echo "ECHO -$opt: $OPTARG" # For example, "ECHO -a: foo"
    ;;
  h)
    _help
    exit 0
    ;;
  esac
done
