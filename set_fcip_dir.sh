#!/bin/bash
# This script sets the FCIP_DIR environment variable to the directory where the script is located.
SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
export FCIP_DIR=$(dirname "$SCRIPT_PATH")
