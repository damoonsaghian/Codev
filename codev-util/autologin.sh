#!/usr/bin/env sh

# set resource limits for realtime applications like the rt module in pipewire
ulimit -r 95 -e -19 -l 4194304

# todo: implement a parent control service, which needs root password for activation and deactivation
# it runs as user "parent" (create if does not exist) and reports (through gnunet) various data
# including the status of the device (so the parent will know if the os is replaced)

exec login -f nu
