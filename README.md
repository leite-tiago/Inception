# Inception Project

Small self-contained infrastructure with Docker Compose: Nginx (TLS only) -> WordPress (php-fpm) -> MariaDB. Two bind-mounted volumes under `/home/<login>/data` for persistence.

## Stack Overview

| Service   | Role | Tech | Exposed Ports | Notes |
|-----------|------|------|---------------|-------|
| nginx     | Entry reverse proxy + TLS | Debian + Nginx + OpenSSL | 443 | Self‑signed cert generated on first start. Only TLSv1.2/1.3. |
| wordpress | PHP-FPM runtime (no web server) | Debian + php-fpm + wp-cli | (internal) 9000 | Installs & configures WP idempotently. |
| mariadb   | Database | Debian + MariaDB Server | (internal) 3306 | Initializes DB, creates limited and privileged users. |

Network: single user-defined bridge (`inception`).

Persistence: bind mounts (required path layout) ->
```
/home/<login>/data/mariadb    # MariaDB datadir
/home/<login>/data/wordpress  # WordPress core + wp-content
```

## Why Containers (Defense Talking Points)

- Image vs Container: an image is an immutable filesystem + metadata; a container is a runtime instance (copy-on-write layer + process namespace). In Compose each `service:` produces (or uses) an image and runs 1+ managed containers.
- Compose Value: declarative multi-service topology (build contexts, networks, volumes, env) + dependency ordering + reproducibility.
- Docker vs VM: Shared host kernel -> lighter, faster startup, denser resource utilization. VM emulates full OS/hardware -> heavier, slower to provision.
- Separation (Nginx / php-fpm / DB): Principle of single responsibility, least privilege, independent scaling, smaller attack surface (no full LAMP in one container).
- PID 1 correctness: Each container ends with `exec <daemon>` (no background loops or tail hacks), enabling proper signal handling.

## Security / Policy Requirements

| Requirement | Implementation |
|-------------|----------------|
| TLS only entry | Nginx exposes only 443; WordPress internal via fastcgi. |
| TLS versions | `ssl_protocols TLSv1.2 TLSv1.3` in Nginx config. |
| No forbidden hacks | No `tail -f`, `sleep infinity`, or keep-alive loops. |
| Admin username policy | Enforced in WP entrypoint (rejects names containing `admin`). |
| No `latest` | Explicit `debian:12` base. |
| Volumes path | Bind mounts to `/home/<login>/data/...`. |
| Secrets not in Dockerfiles | Passwords passed via env file (git-ignored). |

## Environment & Secrets

Real file: `srcs/.env` (git-ignored). Template: `srcs/.env.sample`.

Copy and edit:
```
cp srcs/.env.sample srcs/.env
<edit secure passwords>
```

Important Variables:
```
MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD
MYSQL_ADMIN, MYSQL_ADMIN_PASSWORD   # must not contain 'admin' in name
WP_URL (must be https://<login>.42.fr)
DOMAIN_NAME (same host part as WP_URL)
```

## Build & Run

```
make           # build & up
make logs S=nginx
make ps
```

First access: https://<login>.42.fr (accept self-signed cert). WordPress should already be installed (idempotent bootstrap in entrypoint).

To reset everything:
```
make fclean
```

## Healthchecks

- MariaDB: `mysqladmin ping` used to provide a healthy status.
- WordPress: php-fpm socket reachable via `nc` (existing check).
- Nginx: validated via container start + config test (`nginx -t`).

## How WordPress Bootstrap Works
1. Wait for DB (simple poll using MariaDB client).
2. Download core (`wp core download`) if `wp-config.php` absent.
3. Generate config referencing env-provided credentials.
4. Install site only if not installed (idempotent).
5. Optional secondary author user created.
6. Start php-fpm in foreground (`-F`).

## Nginx Dynamic Domain

`default.conf` contains a `${DOMAIN_NAME}` placeholder replaced at container start (entrypoint `sed`). A self-signed x509 cert is generated if absent.

## Persistence Demonstration Procedure
1. Create/edit a WordPress post or upload media.
2. Restart host / run `make down` then `make up`.
3. Content remains (bind mounts ensure persistence).

## Common Defense Questions & Ready Answers

Q: Why not Alpine?
A: Debian chosen for easier availability of MariaDB & PHP modules, stable glibc and fewer compatibility edge cases.

Q: Why php-fpm separate?
A: Nginx handles static + TLS termination; PHP executes dynamic code. Separation isolates runtime concerns and reduces attack surface if php is compromised.

Q: How do you scale?
A: WordPress container(s) could be replicated behind Nginx (fastcgi upstream). DB requires separate scaling strategy (replication) beyond scope.

Q: How is admin policy enforced?
A: Entry script aborts if `MYSQL_ADMIN` contains case-insensitive substring `admin` before install.

## Future Improvements / Bonus Ideas

- Redis object caching (drop-in `object-cache.php`).
- Adminer / phpMyAdmin for DB inspection (bonus service container).
- FTP(S)/SFTP container for media management (point to WordPress volume).
- Static portfolio site container served via Nginx extra server block.
- Automated cert renewal via acme.sh (requires external challenges; beyond subject scope).

## Cleanup & Maintenance

Rebuild without cache:
```
make BUILD=1 build
```

Remove everything (including data):
```
make fclean
```

Prune dangling artifacts:
```
make prune
```

## License

Educational project (42). No warranty.
