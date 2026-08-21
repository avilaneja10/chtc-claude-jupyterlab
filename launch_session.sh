#!/bin/bash
# launch_session.sh
# Runs inside the container on the execute node. This IS the job.
#
# Note: the executable is Jupyter itself, not `sleep`. A sleep job holding a
# GPU while you occasionally ssh in is the pattern CHTC cited when they
# disabled condor_ssh_to_job on shared GPUs. Here the job's lifetime and the
# session's lifetime are the same thing.

set -eu

ENV_FILE="${CHTC_LAB_ENV:?CHTC_LAB_ENV not set}"
. "${ENV_FILE}"

TOKEN_FILE="${WORKDIR}/.jupyter_token"
RC_FILE="${WORKDIR}/rc_session.txt"

# Clear the previous job's URL so the launcher never prints a dead link.
rm -f "${RC_FILE}"

if [ ! -f "${TOKEN_FILE}" ]; then
    head -c 32 /dev/urandom | base64 | tr -d '/+=' > "${TOKEN_FILE}"
    chmod 600 "${TOKEN_FILE}"
fi
TOKEN=$(cat "${TOKEN_FILE}")

echo "=================================================="
echo "  host    : $(hostname)"
echo "  started : $(date)"
echo "  workdir : ${WORKDIR}"
echo "=================================================="
# Many containers lack nvidia-smi even when the GPU is bound correctly.
# The torch check is what actually matters.
python -c "import torch; print('GPU:', torch.cuda.get_device_name(0))" 2>&1 \
    || echo "WARNING: torch could not see a GPU"
echo "=================================================="

cd "${WORKDIR}"

# Remote Control asks "Enable Remote Control? (y/n)" on startup. Backgrounded
# from a job there is no stdin to answer it, so it blocks forever. Pipe in a
# single y. There is no --yes flag as of v2.1.x.
if command -v claude >/dev/null 2>&1; then
    printf 'y\n' | claude remote-control --name "chtc-$(hostname -s)" \
        > "${RC_FILE}" 2>&1 &
    echo "Claude Remote Control started (pid $!)"
else
    echo "claude not on PATH" > "${RC_FILE}"
    echo "WARNING: claude not found, skipping Remote Control"
fi

# Loopback only. The condor_ssh_to_job tunnel is the sole way in, so nothing
# else sharing this execute node can reach the kernel.
exec jupyter lab \
    --no-browser \
    --ip=127.0.0.1 \
    --port="${JUPYTER_PORT}" \
    --ServerApp.token="${TOKEN}" \
    --ServerApp.root_dir="${WORKDIR}" \
    --ServerApp.allow_origin='*'
