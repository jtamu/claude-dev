#!/bin/bash

PROJECT_NAME="${1:-claude-dev-1}"

docker compose -p $PROJECT_NAME up -d --build
