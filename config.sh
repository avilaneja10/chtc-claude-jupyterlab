# config.sh
# The only file you need to edit. Copy to your staging area and adjust.

# --- Identity and paths ---------------------------------------------------
NETID="aaneja4"
STAGING_ROOT="/staging/groups/waldron_group/${NETID}"

# Where your notebooks and code live. Shared between the access point and the
# execute node, which is what makes the session survive job restarts.
WORKDIR="${STAGING_ROOT}/lab"

# Claude Code binary and config. Also on staging so credentials persist.
TOOLS="${STAGING_ROOT}/tools"

# Runtime directory on the access point: submit file, launch script, logs.
# Deliberately NOT the clone directory. install.sh copies files here.
PROJECT_DIR="${HOME}/chtc-jupyterlab"

# --- Hardware -------------------------------------------------------------
# The execute node to pin to. MUST be a machine your group owns or has
# prioritised access to. condor_ssh_to_job was disabled on CHTC's shared GPU
# machines in April 2026, so an unpinned job will land somewhere you cannot
# tunnel into. Find yours with:
#   condor_status -constraint 'TotalGpus > 0' -af Machine GPUs_DeviceName
GPU_MACHINE="mrudolphgpu4000.chtc.wisc.edu"

CONTAINER="${HOME}/chtc-jupyterlab/jupyterlab-container.sif"

REQUEST_CPUS=12
REQUEST_MEMORY="128GB"
REQUEST_DISK="128GB"
GPU_MIN_MEMORY="40GB"
GPU_MIN_CAPABILITY="9.0"

# --- Ports ----------------------------------------------------------------
# Avoid 8888/8889/8501. The access point is shared by hundreds of people and
# those defaults collide constantly. Pick something arbitrary.
JUPYTER_PORT=8747
EXTRA_PORT=8748   # spare, e.g. Streamlit

# --- Timing ---------------------------------------------------------------
JOB_START_TIMEOUT=1800   # give up waiting for the GPU after 30 min
RC_TIMEOUT=90            # how long to wait for the Claude session URL
