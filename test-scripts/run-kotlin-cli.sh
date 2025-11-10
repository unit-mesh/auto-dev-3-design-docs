#!/bin/bash

# Run Kotlin RemoteAgentCli
# This is the Kotlin equivalent of the TypeScript CLI

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "🚀 Running Kotlin RemoteAgentCli"
echo ""

# Parse arguments
TASK=""
PROJECT_ID=""
SERVER="http://localhost:8080"
EXTRA_ARGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --task)
            TASK="$2"
            shift 2
            ;;
        --project-id)
            PROJECT_ID="$2"
            shift 2
            ;;
        -s|--server)
            SERVER="$2"
            shift 2
            ;;
        *)
            EXTRA_ARGS="$EXTRA_ARGS $1"
            shift
            ;;
    esac
done

if [ -z "$TASK" ] || [ -z "$PROJECT_ID" ]; then
    echo "Usage: $0 --task <task> --project-id <project-id> [--server <url>]"
    echo ""
    echo "Example:"
    echo "  $0 --task '编写 BlogService 测试' \\"
    echo "     --project-id https://github.com/unit-mesh/untitled \\"
    echo "     --server http://localhost:8080"
    exit 1
fi

# Run via Gradle
./gradlew :mpp-ui:run --args="--task \"$TASK\" --project-id \"$PROJECT_ID\" --server \"$SERVER\" $EXTRA_ARGS"

