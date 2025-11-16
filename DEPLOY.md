# Guia de Deploy para Produção

Este guia explica como adicionar uma API Laravel e fazer deploy na produção.

## 📦 Adicionar Projeto Laravel Existente

### Passo 1: Adicionar a API ao projeto

Execute o script helper com o nome da sua API:

```bash
./scripts/add-api.sh nome-da-api subdominio porta-local
```

**Exemplo:**
```bash
./scripts/add-api.sh vendas vendas 8085
```

Isso criará:
- `apis/vendas/` com a estrutura necessária
- Serviço no `docker-compose.yaml`
- Configurações do Nginx
- Tudo configurado automaticamente

### Passo 2: Copiar seu projeto Laravel

```bash
# Copie todo o conteúdo do seu projeto Laravel para apis/nome-da-api/app/
cp -r /caminho/do/seu/projeto/laravel/* apis/vendas/app/

# Ou se você tem o projeto em outro lugar
rsync -av /caminho/do/seu/projeto/laravel/ apis/vendas/app/
```

### Passo 3: Configurar o .env do Laravel

Edite `apis/vendas/app/.env`:

```env
APP_NAME="Sua API"
APP_ENV=production
APP_KEY=base64:... (gere com: php artisan key:generate)
APP_DEBUG=false
APP_URL=https://vendas.gestgo.com.br

DB_CONNECTION=pgsql
DB_HOST=postgres-n8n
DB_PORT=5432
DB_DATABASE=vendas
DB_USERNAME=postgres
DB_PASSWORD=postgres

REDIS_HOST=redis-n8n
REDIS_PASSWORD=null
REDIS_PORT=6379
REDIS_DB=0

CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
```

### Passo 4: Criar o banco de dados

```bash
docker exec postgres-n8n psql -U postgres -c "CREATE DATABASE vendas;"
```

### Passo 5: Instalar dependências e rodar migrations

```bash
# Instalar dependências do Composer
docker exec -it laravel-vendas composer install --no-dev --optimize-autoloader

# Rodar migrations
docker exec -it laravel-vendas php artisan migrate --force

# (Opcional) Rodar seeders
docker exec -it laravel-vendas php artisan db:seed --force

# (Opcional) Limpar e cachear configurações
docker exec -it laravel-vendas php artisan config:cache
docker exec -it laravel-vendas php artisan route:cache
docker exec -it laravel-vendas php artisan view:cache
```

## 🚀 Deploy na Produção (VPS)

### Passo 1: Preparar o ambiente na VPS

```bash
# Conecte na VPS
ssh usuario@ip-da-vps

# Clone ou copie o projeto para a VPS
git clone seu-repositorio /caminho/para/n8n-docker
# OU
scp -r /caminho/local/n8n-docker usuario@vps:/caminho/para/
```

### Passo 2: Configurar o .env na VPS

```bash
cd /caminho/para/n8n-docker

# Copie o .env-example
cp .env-example .env

# Edite o .env com os valores de produção
nano .env
```

Configure as variáveis de produção:

```env
## N8N - Produção
N8N_HOST=n8n.gestgo.com.br
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n.gestgo.com.br/
N8N_EDITOR_BASE_URL=https://n8n.gestgo.com.br/
N8N_DIAGNOSTICS_ENABLED=true
N8N_PERSONALIZATION_ENABLED=true
N8N_VERSION_NOTIFICATIONS_ENABLED=true
N8N_METRICS=true
EXECUTIONS_DATA_PRUNE=true

## PostgreSQL (ajuste se necessário)
DB_POSTGRESDB_PASSWORD=senha-segura-aqui

## Evolution API
AUTHENTICATION_API_KEY=sua-chave-segura-aqui
```

### Passo 3: Configurar DNS no Cloudflare

Adicione os registros DNS:

- **Tipo A**: `n8n` → IP da VPS
- **Tipo A**: `evolution` → IP da VPS
- **Tipo A**: `portainer` → IP da VPS
- **Tipo A**: `vendas` → IP da VPS (ou o subdomínio da sua API)

### Passo 4: Criar bancos de dados

```bash
# Banco para Evolution API
docker exec postgres-n8n psql -U postgres -c "CREATE DATABASE evolution;"

# Banco para sua API Laravel
docker exec postgres-n8n psql -U postgres -c "CREATE DATABASE vendas;"
```

### Passo 5: Iniciar os serviços

```bash
# Iniciar tudo
make up

# Ou se preferir fazer deploy completo
make deploy
```

### Passo 6: Configurar SSL

```bash
# Configurar certificados SSL
make ssl-init
```

Ou manualmente:
```bash
CERTBOT_EMAIL=seu-email@gestgo.com.br ./init-ssl.sh
```

### Passo 7: Configurar Laravel na produção

```bash
# Ajustar permissões
docker exec laravel-vendas chown -R www-data:www-data /var/www/html
docker exec laravel-vendas chmod -R 755 /var/www/html/storage
docker exec laravel-vendas chmod -R 755 /var/www/html/bootstrap/cache

# Instalar dependências
docker exec -it laravel-vendas composer install --no-dev --optimize-autoloader

# Gerar key se necessário
docker exec -it laravel-vendas php artisan key:generate

# Cachear configurações
docker exec -it laravel-vendas php artisan config:cache
docker exec -it laravel-vendas php artisan route:cache
docker exec -it laravel-vendas php artisan view:cache

# Rodar migrations
docker exec -it laravel-vendas php artisan migrate --force
```

## 🔄 Atualizar API Laravel na Produção

### Opção 1: Atualizar código via Git

```bash
# Na VPS
cd /caminho/para/n8n-docker

# Atualizar código da API
cd apis/vendas/app
git pull origin main  # ou sua branch

# Voltar para raiz
cd ../../..

# Reiniciar o container
make restart-api API_NAME=vendas

# Ou atualizar e reconstruir
docker compose build laravel-vendas
docker compose up -d laravel-vendas
```

### Opção 2: Atualizar código manualmente

```bash
# Copiar novo código
scp -r /caminho/local/novo-codigo/* usuario@vps:/caminho/para/n8n-docker/apis/vendas/app/

# Reiniciar
make restart-api API_NAME=vendas
```

### Opção 3: Reconstruir imagem (se mudou Dockerfile)

```bash
# Reconstruir e reiniciar
docker compose build laravel-vendas
docker compose up -d laravel-vendas
```

## 📋 Checklist de Deploy

- [ ] Projeto Laravel copiado para `apis/nome-da-api/app/`
- [ ] `.env` do Laravel configurado
- [ ] Banco de dados criado
- [ ] Dependências instaladas (`composer install`)
- [ ] Migrations rodadas
- [ ] DNS configurado no Cloudflare
- [ ] `.env` na raiz configurado para produção
- [ ] SSL configurado (`make ssl-init`)
- [ ] Permissões do Laravel ajustadas
- [ ] Cache do Laravel gerado
- [ ] Testado acesso à API

## 🔍 Verificar se está funcionando

```bash
# Ver logs da API
make logs-api API_NAME=vendas

# Ver status dos containers
docker compose ps

# Testar acesso
curl https://vendas.gestgo.com.br
```

## ⚠️ Dicas Importantes

1. **Backup**: Sempre faça backup antes de fazer deploy:
   ```bash
   # Backup do banco
   docker exec postgres-n8n pg_dump -U postgres vendas > backup_vendas.sql
   ```

2. **Teste local primeiro**: Teste tudo localmente antes de subir para produção

3. **Variáveis sensíveis**: Nunca commite o `.env` no Git

4. **Permissões**: Certifique-se de que as permissões do Laravel estão corretas

5. **Logs**: Monitore os logs após o deploy:
   ```bash
   make logs-api API_NAME=vendas
   ```

