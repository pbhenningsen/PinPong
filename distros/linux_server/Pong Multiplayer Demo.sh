#!/bin/sh
echo -ne '\033c\033]0;PinPong\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Pong Multiplayer Demo.x86_64" "$@"
