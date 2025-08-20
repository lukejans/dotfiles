#!/bin/bash
#
set -euo pipefail

PORT=${1:-8000}
SCRIPT=${2:-testing.sh}

cleanup() {
    echo -e "\nShutting down server..."
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

if [[ ! -f "${SCRIPT}" ]]; then
    echo "Error: Script file '${SCRIPT}' not found"
    exit 1
fi

echo "Serving ${SCRIPT} on port ${PORT} (Ctrl+C to stop)..."
echo "Test with: curl -fsSL http://localhost:$PORT | bash"

while true; do
    {
        echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: $(wc -c <"${SCRIPT}")\r\n"
        cat "${SCRIPT}"
    } | nc -l "${PORT}"

    # Check if nc failed (port might be in use)
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to bind to port ${PORT}"
        exit 1
    fi

    sleep 0.1
done
