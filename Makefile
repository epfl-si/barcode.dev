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

FRONTEND_ENV := /keybase/team/epfl_lil/frontend/local/env
BACKEND_ENV  := /keybase/team/epfl_lil/backend/local/env

ifeq ($(wildcard $(FRONTEND_ENV)),)
$(error Missing required env file: $(FRONTEND_ENV))
endif
ifeq ($(wildcard $(BACKEND_ENV)),)
$(error Missing required env file: $(BACKEND_ENV))
endif
include $(FRONTEND_ENV)
include $(BACKEND_ENV)
export

.PHONY: print-env
print-env:
	@echo "----- Frontend -----"
	@echo "LIL_REACT_APP_AUTH_SERVER_URL=${LIL_REACT_APP_AUTH_SERVER_URL}"
	@echo "LIL_REACT_APP_HOMEPAGE_URL=${LIL_REACT_APP_HOMEPAGE_URL}"
	@echo "LIL_REACT_APP_GRAPHQL_ENDPOINT_URL=${LIL_REACT_APP_GRAPHQL_ENDPOINT_URL}"
	@echo "LIL_REACT_APP_ENDPOINT_URL=${LIL_REACT_APP_ENDPOINT_URL}"
	@echo "LIL_OIDC_SCOPE=${LIL_OIDC_SCOPE}"
	@echo "LIL_OIDC_CLIENT_ID=${LIL_OIDC_CLIENT_ID}"
	@echo ""
	@echo "----- Backend -----"
	@echo "DATABASE_URL=${DATABASE_URL}"

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
install: install-backend install-frontend

######## App

.PHONY: start-db
start-db:
	@docker compose up

.PHONY: stop-db
stop-db:
	@docker compose down

.PHONY: start-backend
start-backend: lil-backend
	cd lil-backend && npm run dev

.PHONY: start-frontend
start-frontend: lil-frontend
	cd lil-frontend && npm run dev
