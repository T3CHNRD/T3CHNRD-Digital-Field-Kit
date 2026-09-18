#!/bin/zsh
set -u
printf '%s\n' '=== SYSTEM INFORMATION ==='
sw_vers
printf '%s\n' '--- Hardware ---'
system_profiler SPHardwareDataType
printf '%s\n' '--- Storage ---'
diskutil list
