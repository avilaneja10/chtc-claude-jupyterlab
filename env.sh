# env.sh
# Sourced by the job and by claude-login so both agree on paths.
# Do not edit. Edit config.sh instead.

_here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "${_here}/config.sh"

export WORKDIR TOOLS
export PATH="${TOOLS}/bin:${PATH}"
export CLAUDE_CONFIG_DIR="${TOOLS}/claude-config"
export DISABLE_AUTOUPDATER=1

mkdir -p "${CLAUDE_CONFIG_DIR}" "${WORKDIR}"
