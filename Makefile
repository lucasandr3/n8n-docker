deploy:
	docker compose down -v && docker compose up -d

down:
	docker compose down -v

up:
	docker compose up -d

restart:
	docker compose restart

logs:
	docker compose logs -f

ssl-init:
	@echo "⚠️  Certifique-se de que os DNS estão configurados no Cloudflare antes de executar!"
	@read -p "Digite seu email para Let's Encrypt: " email; \
	CERTBOT_EMAIL=$$email ./init-ssl.sh

ssl-renew:
	docker compose exec certbot certbot renew
	docker compose exec nginx nginx -s reload