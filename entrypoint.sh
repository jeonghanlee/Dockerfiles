#!/bin/sh
# Read in the file of environment settings
#. /usr/local/setEnv
# Then run the CMD
exec "$@"

