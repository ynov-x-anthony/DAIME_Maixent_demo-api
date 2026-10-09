#!/usr/bin/env bash
cd /c/Document/COUR_M2/GORSKI/DAIME_Maixent_demo-api
export MSYS_NO_PATHCONV=1

docker rm -f demo-api demo-db 2>/dev/null || true
docker volume rm demo_pgdata 2>/dev/null || true
docker network rm demo_net 2>/dev/null || true

docker build -t demo-api:1.0 ./api

docker volume create demo_pgdata
docker network create demo_net

docker run -d --name demo-db --network demo_net \
  -e POSTGRES_USER=demo -e POSTGRES_PASSWORD=demo -e POSTGRES_DB=demo \
  -v demo_pgdata:/var/lib/postgresql/data \
  -v "$(pwd -W)/db/init.sql":/docker-entrypoint-initdb.d/init.sql:ro \
  postgres:16-alpine

until docker exec demo-db pg_isready -h localhost -U demo; do sleep 1; done

docker run -d --name demo-api --network demo_net -p 8080:3000 -e PGHOST=demo-db demo-api:1.0
until curl -sf localhost:8080/ready; do sleep 1; done; echo

printf '%s' '{"name":"Casquette Démo","price_cents":1200}' | \
  curl -s -X POST -H 'content-type: application/json' --data-binary @- localhost:8080/products
echo
echo
echo "### GET /products AVANT suppression de demo-db"
curl -s localhost:8080/products; echo # SORITE AVANT
echo

docker rm -f demo-db
docker run -d --name demo-db --network demo_net \
  -e POSTGRES_USER=demo -e POSTGRES_PASSWORD=demo -e POSTGRES_DB=demo \
  -v demo_pgdata:/var/lib/postgresql/data \
  -v "$(pwd -W)/db/init.sql":/docker-entrypoint-initdb.d/init.sql:ro \
  postgres:16-alpine
until docker exec demo-db pg_isready -h localhost -U demo; do sleep 1; done

docker rm -f demo-api
docker run -d --name demo-api --network demo_net -p 8080:3000 -e PGHOST=demo-db demo-api:1.0
until curl -sf localhost:8080/ready; do sleep 1; done; echo
echo
echo "### GET /products APRES recréation de demo-db"
curl -s localhost:8080/products; echo # SORTIE APRES
echo

docker volume ls | grep demo_pgdata
curl -s localhost:8080/products; echo
docker rm -f demo-api demo-db
docker network rm demo_net
# docker volume rm demo_pgdata # Si on veut le supprimer au cas ou
