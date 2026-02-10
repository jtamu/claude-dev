#!/bin/bash

COUNT="${1:-1}"

for i in $(seq 1 "$COUNT"); do
  docker compose -p "claude-dev-${i}" up -d --build
done
