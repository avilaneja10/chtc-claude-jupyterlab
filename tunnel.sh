#!/bin/bash
# tunnel.sh
# condor_ssh_to_job does not take ssh options directly; it calls a wrapper
# program instead. This is that wrapper, and it injects the port forwards.
#
# This is hop two of two:
#   laptop      -> access point   (lab-local)
#   access point -> execute node  (this file)
# The port number must match in both hops and in launch_session.sh, or the
# chain breaks silently.

CONFIG="${CHTC_LAB_CONFIG:-$HOME/.chtc-jupyterlab/config.sh}"
. "$CONFIG"

exec ssh -L "${JUPYTER_PORT}:localhost:${JUPYTER_PORT}" \
         -L "${EXTRA_PORT}:localhost:${EXTRA_PORT}" "$@"
