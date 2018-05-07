#!/bin/bash

set -eu

# Adapted from: https://github.com/docker-library/mysql/issues/47
# A wrapper around "$@" to trap the SIGINT signal (Ctrl+C) and forward it to the $@ process
# I.e.: trap SIGINT and SIGTERM signals and forward SIGTERM to the child

asyncRun() {
    "$@" &
    pid="$!"
    cmd="$@"
    trap "echo -e '\nStopping container PID $pid: $cmd\n' ; sleep 1 ; kill -SIGTERM $pid" SIGINT SIGTERM

    # A signal emitted from a child while wait is running will make the wait command return with code > 128.
    # So, we wrap the wait it in a loop that continues as long as $pid is alive.
    set +e
    while kill -0 $pid > /dev/null 2>&1; do
        wait
    done
}

asyncRun "$@"
