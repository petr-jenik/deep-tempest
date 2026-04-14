#!/usr/bin/env bash
set -euo pipefail

# Deep-Tempest no-conda installer (Ubuntu/Debian oriented)
# Usage:
#   bash scripts/install_no_conda.sh
# Optional:
#   PYTHON_BIN=python3.12 bash scripts/install_no_conda.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3.12}"
REQUIREMENTS_FILE="${REQUIREMENTS_FILE:-${ROOT_DIR}/tempest_pyenv.txt}"
VENV_DIR="${ROOT_DIR}/.venv"
GR_DIR="${ROOT_DIR}/gr-tempest"
BUILD_DIR="${GR_DIR}/build-3.10-sanitized"
INSTALL_PREFIX="${HOME}/.local"
PY_MM=""

log() {
  echo "[install-no-conda] $*"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

install_apt_deps() {
  log "Installing system dependencies with apt (sudo required)..."
  sudo apt update
  sudo apt install -y \
    python3.12 python3.12-venv python3-pip \
    gnuradio gnuradio-dev \
    cmake g++ swig git pkg-config \
    libboost-all-dev libcppunit-dev liblog4cpp5-dev \
    tesseract-ocr python3-opencv
}

create_venv_and_install_python_deps() {
  log "Creating virtual environment at ${VENV_DIR}"
  "${PYTHON_BIN}" -m venv "${VENV_DIR}"
  # shellcheck disable=SC1091
  source "${VENV_DIR}/bin/activate"

  PY_MM="$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"

  log "Upgrading pip/setuptools/wheel"
  python -m pip install --upgrade pip setuptools wheel

  if [[ ! -f "${REQUIREMENTS_FILE}" ]]; then
    echo "Requirements file not found: ${REQUIREMENTS_FILE}" >&2
    exit 1
  fi

  log "Installing base Python dependencies from ${REQUIREMENTS_FILE}"
  pip install -r "${REQUIREMENTS_FILE}"

  log "Installing extra runtime/training dependencies"
  # fastwer has build issues under isolated PEP517 env in this stack;
  # using the active env toolchain is more reliable here.
  pip install --no-build-isolation git+https://github.com/sfernandezr/fastwer.git
}

build_and_install_gr_tempest() {
  log "Configuring and building gr-tempest"
  mkdir -p "${BUILD_DIR}"
  cd "${BUILD_DIR}"

  # Clean environment avoids accidental conda include/library pollution.
  env -i HOME="${HOME}" USER="${USER}" LOGNAME="${LOGNAME}" \
    SHELL=/bin/bash TERM="${TERM:-xterm}" \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    cmake ..

  env -i HOME="${HOME}" USER="${USER}" LOGNAME="${LOGNAME}" \
    SHELL=/bin/bash TERM="${TERM:-xterm}" \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    cmake --build . -j"$(nproc)"

  env -i HOME="${HOME}" USER="${USER}" LOGNAME="${LOGNAME}" \
    SHELL=/bin/bash TERM="${TERM:-xterm}" \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    cmake --install . --prefix "${INSTALL_PREFIX}"
}

print_post_install_notes() {
  cat <<EOF

[install-no-conda] Installation complete.

Add these to your shell config (~/.bashrc) so GNU Radio finds the module:

  export PYTHONPATH="${HOME}/.local/lib/python${PY_MM}/dist-packages:\$PYTHONPATH"
  export LD_LIBRARY_PATH="${HOME}/.local/lib/x86_64-linux-gnu:\$LD_LIBRARY_PATH"
  export GRC_BLOCKS_PATH="${HOME}/.local/share/gnuradio/grc/blocks:\$GRC_BLOCKS_PATH"

Quick check:

  /usr/bin/python3 -c "import gnuradio.tempest as t; print('ok', hasattr(t, 'tempest_msgbtn'))"

Run GNU Radio Companion (system binary):

  /usr/bin/gnuradio-companion

EOF
}

main() {
  need_cmd sudo
  need_cmd apt
  install_apt_deps

  if ! command -v "${PYTHON_BIN}" >/dev/null 2>&1; then
    echo "Python interpreter not found: ${PYTHON_BIN}" >&2
    echo "Tip: set PYTHON_BIN, e.g. PYTHON_BIN=python3.10" >&2
    exit 1
  fi

  create_venv_and_install_python_deps
  build_and_install_gr_tempest
  print_post_install_notes
}

main "$@"
