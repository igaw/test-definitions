#!/bin/sh -e
# shellcheck disable=SC1090
# shellcheck disable=SC2154
# pmqtest start pairs of threads and measure the latency of interprocess
# communication with POSIX messages queues.

TEST_DIR=$(dirname "$(realpath "$0")")
OUTPUT="${TEST_DIR}/output"
LOGFILE="${OUTPUT}/pmqtest.log"
RESULT_FILE="${OUTPUT}/result.txt"
DURATION="5m"
MAX_LATENCY="100"
BACKGROUND_CMD=""

usage() {
    echo "Usage: $0 [-D duration] [-m latency] [-w background_cmd]" 1>&2
    exit 1
}

while getopts ":D:m:w:" opt; do
    case "${opt}" in
        D) DURATION="${OPTARG}" ;;
	m) MAX_LATENCY="${OPTARG}" ;;
	w) BACKGROUND_CMD="${OPTARG}" ;;
        *) usage ;;
    esac
done

. "${TEST_DIR}/../../lib/sh-test-lib"

! check_root && error_msg "Please run this script as root."
create_out_dir "${OUTPUT}"

# Run pmqtest.
if ! binary=$(command -v pmqtest); then
    detect_abi
    # shellcheck disable=SC2154
    binary="./bin/${abi}/pmqtest"
fi

background_process_start bgcmd --cmd "${BACKGROUND_CMD}"

"${binary}" -S -p 98 -D "${DURATION}" | tee "${LOGFILE}"

background_process_stop bgcmd

# Parse test log.
../../lib/parse_rt_tests_results.py pmqtest "${LOGFILE}" "${MAX_LATENCY}" \
    | tee -a "${RESULT_FILE}"
