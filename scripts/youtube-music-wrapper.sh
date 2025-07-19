#!/bin/zsh
# Wrapper to ensure YouTube Music runs with the correct environment
source ~/.zshrc
exec youtube-music "$@"
