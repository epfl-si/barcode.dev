-include .env

-include .make.vars

# Auto-detected variables (computed once and stored until "make clean")
.make.vars:
	@echo _GITHUB_BASE = $(if $(shell ssh -T git@github.com 2>&1|grep 'successful'),git@github.com:,https://github.com/) >> $@

.PHONY: help
help:
	@echo "Main:"
	@echo "  make help                 — Display this help"
	@echo "  make print-env            — Print environment variables"
	@echo "Sub-Repositories:"
	@echo "  make checkout             — Clone all sub-repositories if not already cloned"
	@echo "  make git-pull             — Update all sub-repositories with git pull --rebase"
	@echo "Setup:"
	@echo "  make install-backend      — Install the backend dependencies"
	@echo "  make install-frontend     — Install the frontend dependencies"
	@echo "  make install              — Install all dependencies"
	@echo "App:"
	@echo "  make start-db             — Start the database with Docker Compose"
	@echo "  make stop-db              — Stop the database with Docker Compose"
	@echo "  make start-frontend       — Start the frontend development server"
	@echo "  make start-backend        — Start the backend development server"

.PHONY: fetch-env
fetch-env:
	@echo "Récupération du .env Frontend..."
	keybase fs read /keybase/team/epfl_lil/frontend/local/env > ./lil-frontend/.env
	@echo "Récupération du .env Backend..."
	keybase fs read /keybase/team/epfl_lil/backend/local/env > ./lil-backend/.env

.PHONY: print-env
print-env:
	@echo "----- Frontend -----"
	keybase fs read /keybase/team/epfl_lil/frontend/local/env
	@echo ""
	@echo "----- Backend -----"
	keybase fs read /keybase/team/epfl_lil/backend/local/env

######## Sub-Repositories

_git_clone = devscripts/ensure-git-clone.sh $(_GITHUB_BASE)$(strip $(1)) $@ $(2); touch $@

lil-frontend:
	$(call _git_clone, epfl-si/lil.frontend, main)

lil-backend:
	$(call _git_clone, epfl-si/lil.backend, main)

lil-ops:
	$(call _git_clone, epfl-si/lil.ops, main)

.PHONY: checkout
checkout: lil-frontend lil-backend lil-ops

_find_git_depots := find . \( -path ./volumes -prune -false \) -o -name .git -prune |xargs -n 1 dirname|grep -v 'ansible-deps-cache'
.PHONY: git-pull
git-pull: ## Walk down the directory to find repositories to update (with rebase!)
	@set -e; for dir in `$(_find_git_depots)`; do (cd $$dir; echo "$$(tput bold)$$dir$$(tput sgr0)"; git pull --rebase --autostash; echo); done

######## Setup

.PHONY: install-backend
install-backend: lil-backend
	cd lil-backend && npm install && npx prisma generate

.PHONY: install-frontend
install-frontend: lil-frontend
	cd lil-frontend && npm install

.PHONY: install
install: fetch-env install-backend install-frontend

######## App

.PHONY: start-db
start-db: fetch-env
	@docker compose up

.PHONY: stop-db
stop-db:
	@docker compose down

.PHONY: start-backend
start-backend: fetch-env lil-backend
	cd lil-backend && npm run dev

.PHONY: start-frontend
start-frontend: fetch-env lil-frontend
	cd lil-frontend && npm run dev
