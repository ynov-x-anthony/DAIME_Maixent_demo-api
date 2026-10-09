# demo-api

API Node.js (Express) + PostgreSQL + Adminer, lancés avec Docker Compose.

## Prérequis

- Docker avec Compose v2 (`docker compose version`)
- `git`, `curl`
- Windows : terminal WSL ou Git Bash

## Installation

```bash
git clone <url-du-repo> demo-api
cd demo-api

cp .env.example .env

mkdir -p secrets
printf 'mon-mot-de-passe' > secrets/db_password.txt
```

`.env` et `secrets/` ne sont pas commités (voir `.gitignore`).

## Variables (`.env`)

| Variable | Rôle | Défaut |
|---|---|---|
| `POSTGRES_USER` | utilisateur PostgreSQL | `demo` |
| `POSTGRES_DB` | nom de la base | `demo` |
| `API_PORT` | port de l'API sur l'hôte | `8080` |
| `ADMINER_PORT` | port d'Adminer sur l'hôte | `8081` |

## Secret

Le mot de passe de la base n'est pas dans `.env`. Il est lu depuis
`secrets/db_password.txt`, monté par Compose dans `/run/secrets/db_password` :

- `db` : `POSTGRES_PASSWORD_FILE=/run/secrets/db_password`
- `api` : `PGPASSWORD_FILE=/run/secrets/db_password` (lu par `api/db.js`)

## Lancement

```bash
docker compose up -d --build
```

## URLs

| Service | URL |
|---|---|
| API | http://localhost:8080 |
| Produits | http://localhost:8080/products |
| Adminer | http://localhost:8081 (serveur `db`, utilisateur `demo`, base `demo`) |

La base n'a pas de port publié : elle n'est joignable que depuis le réseau Compose.

## Commandes

```bash
docker compose ps            # état des services
docker compose logs -f api   # logs de l'API
docker compose down          # arrête et supprime les conteneurs, garde les données
docker compose down -v       # supprime aussi le volume pgdata : repart de zéro, init.sql rejoué
```

## Tests réalisés

Commande testée :

```bash
docker compose up -d --build
```

`docker compose ps` :

```
NAME                               IMAGE                        SERVICE   STATUS                    PORTS
daime_maixent_demo-api-adminer-1   adminer:4                    adminer   Up 24 seconds             0.0.0.0:8081->8080/tcp
daime_maixent_demo-api-api-1       daime_maixent_demo-api-api   api       Up 19 seconds (healthy)   0.0.0.0:8080->3000/tcp
daime_maixent_demo-api-db-1        postgres:16-alpine           db        Up 25 seconds (healthy)   5432/tcp
```

Produits de `init.sql` :

```
$ curl -s localhost:8080/products
[{"id":3,"name":"T-shirt conteneur","price_cents":1990,...},{"id":2,"name":"Mug Docker","price_cents":990,...},{"id":1,"name":"Sticker Demo","price_cents":150,...}]
```

Ajout d'un produit :

```
$ curl -s -X POST -H 'content-type: application/json' \
  -d '{"name":"Gourde","price_cents":900}' localhost:8080/products
{"id":4,"name":"Gourde","price_cents":900,"created_at":"2026-10-09T12:18:55.844Z"}
```

Persistance après `docker compose down` puis `docker compose up -d --build` :

```
$ curl -s localhost:8080/products
[{"id":4,"name":"Gourde","price_cents":900,...},{"id":3,"name":"T-shirt conteneur",...},{"id":2,"name":"Mug Docker",...},{"id":1,"name":"Sticker Demo",...}]
```
