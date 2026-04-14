#!/usr/bin/env bash
set -e

# Use user-local gr-tempest installation paths.
export PYTHONPATH="$HOME/.local/lib/python3.12/dist-packages:$PYTHONPATH"
export LD_LIBRARY_PATH="$HOME/.local/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
export GRC_BLOCKS_PATH="$HOME/.local/share/gnuradio/grc/blocks:$GRC_BLOCKS_PATH"

# Force system GNU Radio Companion to avoid conda Python mismatch.
exec /usr/bin/gnuradio-companion "$@"
