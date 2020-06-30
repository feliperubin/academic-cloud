#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Writes a single stamp file
# Use this script instead of ansible command
# due to possible future improvements here.

STAMPID="$1"
# This is the main purpose.
touch "/.$STAMPID.stamp"
# This is to let ansible know that
# this script was executed for the given
# stamp at least once previously.
touch "/.stampgen.$STAMPID.stamp"
