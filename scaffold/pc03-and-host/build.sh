#!/usr/bin/env bash
set -eu

if [ "$#" -ne 2 ]; then
    printf 'usage: build.sh <pc03-worktree> <output-directory>\n' >&2
    exit 2
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SCRIPT_WIN=$(cygpath -w "$SCRIPT_DIR/build.cmd")
SOURCE_WIN=$(cygpath -w "$1")
OUTPUT_WIN=$(cygpath -w "$2")
cmd.exe /d /c "\"$SCRIPT_WIN\" \"$SOURCE_WIN\" \"$OUTPUT_WIN\""
