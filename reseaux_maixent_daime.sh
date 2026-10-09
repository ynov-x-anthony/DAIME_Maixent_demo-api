#!/usr/bin/env bash
export MSYS_NO_PATHCONV=1

docker rm -f demo-api demo-db 2>/dev/null || true
docker network rm demo_front demo_back 2>/dev/null || true

docker build -t demo-api:1.0 ./api

docker network create demo_back
docker network create demo_front

docker run -d --name demo-db --network demo_back \
  -e POSTGRES_USER=demo -e POSTGRES_PASSWORD=demo -e POSTGRES_DB=demo \
  -v "$(pwd -W)/db/init.sql":/docker-entrypoint-initdb.d/init.sql:ro \
  postgres:16-alpine

until docker exec demo-db pg_isready -h localhost -U demo; do sleep 1; done

docker run -d --name demo-api --network demo_front --network demo_back -p 8080:3000 -e PGHOST=demo-db demo-api:1.0
until curl -sf localhost:8080/ready; do sleep 1; done; echo

docker exec demo-api getent hosts demo-db

docker run --rm --network demo_front alpine nc -zv demo-db 5432

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAMConfig}} {{.IPAddress}}{{"\n"}}{{end}}' demo-db
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAMConfig}} {{.IPAddress}}{{"\n"}}{{end}}' demo-api

curl -s localhost:8080/products

docker rm -f demo-api demo-db 2>/dev/null || true
docker network rm demo_back 2>/dev/null || true
docker network rm demo_front 2>/dev/null || true
