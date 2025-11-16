deploy:
	docker compose down -v && docker compose up -d

down:
	docker compose down -v

up:
	docker compose up -d

restart:
	docker compose restart

# Reiniciar serviço específico
restart-n8n:
	docker compose restart n8n-editor n8n-workers n8n-webhooks

restart-evolution:
	docker compose restart evolution-api

restart-portainer:
	docker compose restart portainer

restart-nginx:
	docker compose restart nginx

restart-postgres:
	docker compose restart postgres

restart-redis:
	docker compose restart redis

restart-api:
	@if [ -z "$(API_NAME)" ]; then \
		echo "❌ Erro: Especifique o nome da API. Exemplo: make restart-api API_NAME=vendas"; \
		exit 1; \
	fi
	docker compose restart laravel-$(API_NAME)

logs:
	docker compose logs -f

ssl-init:
	@echo "⚠️  Certifique-se de que os DNS estão configurados no Cloudflare antes de executar!"
	@read -p "Digite seu email para Let's Encrypt: " email; \
	CERTBOT_EMAIL=$$email ./init-ssl.sh

ssl-renew:
	docker compose exec certbot certbot renew
	docker compose exec nginx nginx -s reload

# Atualizar imagens
pull:
	docker compose pull

pull-update:
	docker compose pull && docker compose up -d

# Atualizar serviço específico
update-n8n:
	docker compose pull n8n-editor n8n-workers n8n-webhooks
	docker compose up -d n8n-editor n8n-workers n8n-webhooks

update-evolution:
	docker compose pull evolution-api
	docker compose up -d evolution-api

update-portainer:
	docker compose pull portainer
	docker compose up -d portainer

update-nginx:
	docker compose pull nginx
	docker compose up -d nginx

update-postgres:
	docker compose pull postgres
	docker compose up -d postgres

update-redis:
	docker compose pull redis
	docker compose up -d redis

# Atualizar API Laravel específica (ex: make update-api API_NAME=vendas)
update-api:
	@if [ -z "$(API_NAME)" ]; then \
		echo "❌ Erro: Especifique o nome da API. Exemplo: make update-api API_NAME=vendas"; \
		exit 1; \
	fi
	docker compose pull laravel-$(API_NAME)
	docker compose up -d laravel-$(API_NAME)

# Ver versões das imagens
versions:
	@echo "📦 Versões das imagens Docker:"
	@docker compose images

# Ver logs de um serviço específico
logs-n8n:
	docker compose logs -f n8n-editor

logs-evolution:
	docker compose logs -f evolution-api

logs-api:
	@if [ -z "$(API_NAME)" ]; then \
		echo "❌ Erro: Especifique o nome da API. Exemplo: make logs-api API_NAME=vendas"; \
		exit 1; \
	fi
	docker compose logs -f laravel-$(API_NAME)