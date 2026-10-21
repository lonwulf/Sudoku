# Sudoku backend

Spring Boot 3.5 / Java 17 API for the Sudoku app: puzzle generation, scoring and
leaderboards.

## What it needs

| Service    | Dev setup                                  | Used for                                         |
|------------|--------------------------------------------|--------------------------------------------------|
| Database   | Nothing to run: H2 in memory               | Players and scores. Flyway creates the schema.   |
| Redis      | Docker, port `6379`                        | Puzzle solutions, leaderboards, rate limits      |
| Keycloak   | Docker, port `8180`, realm `sudoku`        | Signing players in (JWT bearer tokens)           |

Install a **JDK 17** (Gradle downloads one if none is found) and **Docker**.

Without Redis every puzzle request fails with **503**. Without Keycloak puzzles
still load, but sign-in and everything that needs it (submit, scores,
leaderboard) does not.

## Run it in dev

### 1. Start Redis and Keycloak

From the repository root:

```sh
# Your Mac's LAN IP if the app runs on a phone; localhost for an emulator/simulator on this machine
export KEYCLOAK_HOST=$(ipconfig getifaddr en0)

docker run -d --name sudoku-redis -p 6379:6379 redis:7.4-alpine

docker run -d --name sudoku-keycloak -p 8180:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  -e KC_HOSTNAME=http://$KEYCLOAK_HOST:8180 \
  -v "$PWD/keycloak/sudoku-realm.json:/opt/keycloak/data/import/sudoku-realm.json:ro" \
  quay.io/keycloak/keycloak:26.0.7 start-dev --import-realm
```

Keycloak takes about 15 seconds. It is ready when
`http://$KEYCLOAK_HOST:8180/realms/sudoku/.well-known/openid-configuration`
answers. The realm (client `sudoku-mobile`, test users) is imported from
[`keycloak/sudoku-realm.json`](../keycloak/sudoku-realm.json) on first start.

### 2. Start the backend

**From a terminal:**

```sh
OAUTH2_ISSUER_URI=http://$KEYCLOAK_HOST:8180/realms/sudoku \
  ./gradlew :backend:bootRun --args='--spring.profiles.active=dev'
```

**From Android Studio / IntelliJ:** run `SudokuApplication` with

- **Active profiles:** `dev`
- **Environment variables:** `OAUTH2_ISSUER_URI=http://<KEYCLOAK_HOST>:8180/realms/sudoku`

After any change to `build.gradle`, run **File → Sync Project with Gradle Files**
first. The IDE runs the app with the libraries from its last sync, and a stale
sync can leave out new ones (see [Troubleshooting](#troubleshooting)).

The server listens on `http://0.0.0.0:8080`. `GET /actuator/health` answers
`{"status":"UP"}` when it is running.

### 3. Point the app at it

In `mobile/sudoku/config/debug.json` use the same host for both:

```json
"API_BASE_URL": "http://<KEYCLOAK_HOST>:8080",
"OIDC_ISSUER": "http://<KEYCLOAK_HOST>:8180/realms/sudoku"
```

### The one rule: one address for Keycloak

Keycloak writes its address into every token (the `iss` claim), and the backend
only accepts tokens from exactly `OAUTH2_ISSUER_URI`. `KC_HOSTNAME`,
`OAUTH2_ISSUER_URI` and the app's `OIDC_ISSUER` must therefore name the same
host. A phone can't reach `localhost` on your Mac, so for a phone they all use
the Mac's LAN IP. If the LAN IP changes, update all three and restart Keycloak
and the backend.

### Alternative: Docker Compose

`docker-compose.yml` at the repository root runs Redis, Keycloak and the
backend (in the `docker` profile) together. It needs the Docker Compose plugin
and reads `KEYCLOAK_HOST` from the environment:

```sh
KEYCLOAK_HOST=$(ipconfig getifaddr en0) docker compose up --build
```

### Stopping

```sh
docker rm -f sudoku-redis sudoku-keycloak
```

The backend's H2 database is in memory, so players and scores reset whenever the
backend restarts. Keycloak keeps its users (including anyone who registered)
until its container is removed.

## Test accounts

| Where                                    | Username / password      | Notes                                    |
|------------------------------------------|--------------------------|------------------------------------------|
| Keycloak, realm `sudoku` (the app)       | `player` / `player`      | Regular player                           |
| Keycloak, realm `sudoku` (the app)       | `admin` / `admin`        | Also has the `admin` role (`/admin/**`)  |
| Keycloak admin console (`:8180/admin`)   | `admin` / `admin`        | Manages Keycloak itself                  |
| Backend `dev` profile, HTTP basic auth   | `user` / `user123`, `admin` / `admin123` | For curl without Keycloak, e.g. `curl -u user:user123 localhost:8080/scores/my_score` |

New players can also register from the Keycloak sign-in page.

## Configuration

| Setting (env var / property)              | Default                                   | Notes |
|-------------------------------------------|-------------------------------------------|-------|
| `SPRING_PROFILES_ACTIVE`                  | none                                      | `dev`, `docker` or `prod` (below) |
| `OAUTH2_ISSUER_URI`                       | `http://localhost:8180/realms/sudoku`     | Required in `prod` |
| `SPRING_REDIS_HOST` / `SPRING_REDIS_PORT` | `localhost` / `6379`                      | Read by the `dev` profile |
| `sudoku.rate-limit.puzzles-per-minute`    | `120`                                     | Per signed-in player, or per IP when anonymous |
| `sudoku.rate-limit.submits-per-minute`    | `20`                                      | |
| `sudoku.puzzle-ttl`                       | `24h`                                     | How long a puzzle can still be scored |

Profiles:

- **dev:** H2 in memory, SQL logging, basic-auth test users.
- **docker:** H2 in memory, Redis at host `redis` (as in Compose).
- **prod:** PostgreSQL at `prod-db` (`DB_USER`, `DB_PASS`), Redis from
  `REDIS_HOST` / `REDIS_PORT` / `REDIS_PASSWORD`, and `OAUTH2_ISSUER_URI` must be
  set.

With no profile the backend behaves like `dev` without the basic-auth users.

## Tests

```sh
./gradlew :backend:test
```

Tests use H2, and point Redis at a closed port where they need it unavailable.
They pass whether or not a dev Redis or Keycloak is running.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Startup fails with `Schema-validation: missing table [fraud_flags]`, and the log has no `Flyway` lines | The IDE's Gradle sync is older than the Flyway dependency, so migrations never run | Sync Project with Gradle Files, or start with `./gradlew :backend:bootRun` |
| Every request returns **503** "Service temporarily unavailable" | Redis isn't running | Start the Redis container. The backend reconnects without a restart |
| Signed-in requests return **401**, or **500** with "The Issuer … did not match the requested issuer" | `OAUTH2_ISSUER_URI` doesn't match `KC_HOSTNAME` (usually `localhost` vs. the LAN IP) | Make the addresses match ([the one rule](#the-one-rule-one-address-for-keycloak)) and restart the backend |
| The phone can't sign in or connect | The phone isn't on the same Wi-Fi, or the Mac's firewall blocks `8080`/`8180` | Check with `adb shell 'toybox nc -w 3 <LAN IP> 8080 </dev/null && echo ok'` |
| `Port 8080 was already in use` | Another backend is running | `lsof -iTCP:8080 -sTCP:LISTEN` to find it |
