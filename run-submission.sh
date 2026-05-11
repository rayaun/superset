#!/usr/bin/env bash
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

# ─── Superset Submission Runner ──────────────────────────────────────
# Convenience script to build and run the Superset submission package.
# Usage:
#   ./run-submission.sh          # Build and start all services
#   ./run-submission.sh stop     # Stop all services
#   ./run-submission.sh clean    # Stop and remove all data
#   ./run-submission.sh status   # Show running containers
#   ./run-submission.sh logs     # Follow container logs
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

COMPOSE_FILE="docker-compose-non-dev.yml"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$PROJECT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Superset Security Review — Submission Package${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

check_prerequisites() {
    local missing=0

    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Error: Docker is not installed.${NC}"
        echo "  Install from: https://www.docker.com/get-started"
        missing=1
    fi

    if ! docker compose version &>/dev/null 2>&1; then
        echo -e "${RED}Error: Docker Compose (v2) is not available.${NC}"
        echo "  Install from: https://docs.docker.com/compose/install/"
        missing=1
    fi

    if [ "$missing" -eq 1 ]; then
        exit 1
    fi

    local mem
    mem=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo "0")
    local mem_gb=$((mem / 1073741824))
    if [ "$mem_gb" -lt 6 ]; then
        echo -e "${YELLOW}Warning: Docker has ${mem_gb}GB RAM allocated. 8GB+ recommended.${NC}"
    fi
}

cmd_start() {
    print_header
    check_prerequisites

    echo -e "${GREEN}Building and starting Superset...${NC}"
    echo -e "  Compose file: ${COMPOSE_FILE}"
    echo ""
    echo -e "${YELLOW}This will take 3-5 minutes on first run.${NC}"
    echo ""

    docker compose -f "$COMPOSE_FILE" up --build -d

    echo ""
    echo -e "${GREEN}Superset is starting up.${NC}"
    echo ""
    echo -e "  Application:  ${BLUE}http://localhost:8088${NC}"
    echo -e "  Credentials:  admin / admin"
    echo ""
    echo -e "  Dashboard:    ${BLUE}https://security-dashboard-xwgymjld.devinapps.com/${NC}"
    echo ""
    echo -e "  View logs:    ${YELLOW}./run-submission.sh logs${NC}"
    echo -e "  Stop:         ${YELLOW}./run-submission.sh stop${NC}"
    echo ""
}

cmd_stop() {
    echo -e "${YELLOW}Stopping Superset...${NC}"
    docker compose -f "$COMPOSE_FILE" down
    echo -e "${GREEN}Stopped.${NC}"
}

cmd_clean() {
    echo -e "${YELLOW}Stopping Superset and removing all data...${NC}"
    docker compose -f "$COMPOSE_FILE" down -v
    echo -e "${GREEN}Cleaned.${NC}"
}

cmd_status() {
    docker compose -f "$COMPOSE_FILE" ps
}

cmd_logs() {
    docker compose -f "$COMPOSE_FILE" logs -f
}

cmd_help() {
    print_header
    echo "Usage: ./run-submission.sh [command]"
    echo ""
    echo "Commands:"
    echo "  (none)    Build and start all services"
    echo "  stop      Stop all services"
    echo "  clean     Stop and remove all data volumes"
    echo "  status    Show running containers"
    echo "  logs      Follow container logs"
    echo "  help      Show this help message"
    echo ""
}

case "${1:-start}" in
    start|up)   cmd_start ;;
    stop|down)  cmd_stop ;;
    clean|nuke) cmd_clean ;;
    status|ps)  cmd_status ;;
    logs)       cmd_logs ;;
    help|-h)    cmd_help ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
