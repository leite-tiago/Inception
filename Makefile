# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: tborges- <tborges-@student.42lisboa.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/07/21 19:26:29 by tborges-          #+#    #+#              #
#    Updated: 2025/09/29 19:52:52 by tborges-         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

NAME=Inception
COMPOSE_FILE=srcs/docker-compose.yml
ENV_FILE=srcs/.env
LOGIN?=$(shell whoami)
PROJECT?=$(NAME)

DATA_DIR=/home/$(LOGIN)/data
DB_DIR=$(DATA_DIR)/mariadb
WP_DIR=$(DATA_DIR)/wordpress

DOCKER_COMPOSE=docker compose -f $(COMPOSE_FILE)

.PHONY: all build up start stop down ps logs fclean clean re prune volumes status help certs

all: build up ## Build and start the full stack

build: ## Build images (no cache use BUILD=1 to force)
	@echo "[+] Building images..."
	$(DOCKER_COMPOSE) build $(if $(BUILD),--no-cache,)

up: ## Launch containers in background
	@echo "[+] Ensuring data directories exist under $(DATA_DIR)"
	@mkdir -p $(DB_DIR) $(WP_DIR)
	@echo "[+] Starting services..."
	LOGIN=$(LOGIN) $(DOCKER_COMPOSE) up -d --remove-orphans
	@$(DOCKER_COMPOSE) ps

start: up ## Alias of up

stop: ## Stop containers (keep volumes/images)
	$(DOCKER_COMPOSE) stop

down: ## Stop and remove containers, networks (keep volumes)
	$(DOCKER_COMPOSE) down

ps: ## Show container status
	$(DOCKER_COMPOSE) ps

logs: ## Tail logs (use S=service for a single service)
	$(DOCKER_COMPOSE) logs -f $(S)

volumes: ## List project volumes
	docker volume ls | grep '$(PROJECT)' || true

prune: ## Remove dangling resources (CAREFUL)
	@echo "[!] Pruning dangling images/containers (safe)"
	docker system prune -f

clean: down ## Remove containers + network (keep images & volumes)
	@echo "[+] Clean done"

fclean: down ## Remove EVERYTHING: images + volumes + data folders
	@echo "[!] Removing images and volumes for project"
	-docker image rm mariadb wordpress nginx 2>/dev/null || true
	-docker volume rm $$(docker volume ls -q | grep -E 'mariadb|wordpress') 2>/dev/null || true
	@echo "[!] Deleting bind data directories"
	rm -rf $(DB_DIR) $(WP_DIR)

re: fclean all ## Full rebuild

certs: ## Show generated self-signed cert info (nginx must be up)
	@docker exec nginx openssl x509 -noout -subject -issuer -dates -in /etc/nginx/ssl/server.crt

status: ## High-level status report
	@echo "Login: $(LOGIN)"
	@echo "Data directories:"; ls -ld $(DB_DIR) $(WP_DIR) || true
	@echo "Volumes:"; docker volume ls | grep $(LOGIN) || true
	@$(DOCKER_COMPOSE) ps

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sed 's/:.*##/: /' | sort

