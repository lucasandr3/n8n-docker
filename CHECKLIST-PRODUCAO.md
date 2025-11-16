# ✅ Checklist de Deploy para Produção

## 🔒 1. SEGURANÇA - CRÍTICO ⚠️

### Senhas e Secrets

- [ ] **PostgreSQL**: Alterar senha padrão `postgres` no `.env`
  ```env
  DB_POSTGRESDB_PASSWORD=sua-senha-super-segura-aqui
  POSTGRES_PASSWORD=sua-senha-super-segura-aqui
  ```

- [ ] **N8N Encryption Key**: Gerar e configurar
  ```bash
  openssl rand -base64 32
  ```
  Adicionar ao `.env`:
  ```env
  N8N_ENCRYPTION_KEY=chave-gerada-aqui
  ```

- [ ] **Evolution API Key**: Configurar chave de autenticação
  ```env
  AUTHENTICATION_API_KEY=sua-chave-segura-aqui
  ```

- [ ] **Webhook Secret**: Gerar secret para webhooks
  ```bash
  openssl rand -hex 32
  ```
  Adicionar ao `.env`:
  ```env
  WEBHOOK_SECRET=secret-gerado-aqui
  ```

### Arquivo .env

- [ ] Criar `.env` a partir de `.env-example`
- [ ] **NÃO COMMITAR** o `.env` no Git (já está no .gitignore)
- [ ] Configurar todas as variáveis de produção

## 🌐 2. DNS - Cloudflare

Configure os seguintes registros DNS (Tipo A) apontando para o IP da VPS:

- [ ] `gestgo.com.br` → IP da VPS
- [ ] `www.gestgo.com.br` → IP da VPS
- [ ] `n8n.gestgo.com.br` → IP da VPS
- [ ] `evolution.gestgo.com.br` → IP da VPS
- [ ] `portainer.gestgo.com.br` → IP da VPS
- [ ] `webhook.gestgo.com.br` → IP da VPS
- [ ] Para cada API Laravel: `{subdominio}.gestgo.com.br` → IP da VPS

**Importante**: Aguarde a propagação do DNS (pode levar alguns minutos)

## ⚙️ 3. CONFIGURAÇÕES DO .ENV

### N8N - Produção

```env
N8N_HOST=n8n.gestgo.com.br
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n.gestgo.com.br/
N8N_EDITOR_BASE_URL=https://n8n.gestgo.com.br/
N8N_PORT=5678

# Telemetria (opcional - pode deixar false)
N8N_DIAGNOSTICS_ENABLED=false
N8N_PERSONALIZATION_ENABLED=false
N8N_VERSION_NOTIFICATIONS_ENABLED=false
N8N_METRICS=false
EXECUTIONS_DATA_PRUNE=false
```

### PostgreSQL

```env
DB_POSTGRESDB_PASSWORD=senha-segura-aqui
POSTGRES_PASSWORD=senha-segura-aqui
```

### Evolution API

```env
AUTHENTICATION_API_KEY=sua-chave-segura-aqui
```

### Webhook

```env
WEBHOOK_SECRET=secret-gerado-aqui
```

## 🚀 4. DEPLOY NA VPS

### Passo 1: Copiar projeto

```bash
# Na VPS
git clone seu-repositorio /caminho/para/n8n-docker
# OU
scp -r /caminho/local/n8n-docker usuario@vps:/caminho/para/
```

### Passo 2: Configurar .env

```bash
cd /caminho/para/n8n-docker
cp .env-example .env
nano .env  # Editar com valores de produção
```

### Passo 3: Criar bancos de dados (se necessário)

```bash
# Banco para Evolution API
docker exec postgres-n8n psql -U postgres -c "CREATE DATABASE evolution;"

# Banco para suas APIs Laravel (exemplo)
docker exec postgres-n8n psql -U postgres -c "CREATE DATABASE vendas;"
```

### Passo 4: Iniciar serviços

```bash
make up
```

### Passo 5: Configurar SSL

**IMPORTANTE**: Execute apenas após os DNS estarem configurados e propagados!

```bash
make ssl-init
```

Ou manualmente:
```bash
CERTBOT_EMAIL=seu-email@gestgo.com.br ./init-ssl.sh
```

## 📦 5. SITE INSTITUCIONAL (Angular)

- [ ] Projeto Angular colocado em `institucional/`
- [ ] Git inicializado e configurado
- [ ] Webhook configurado no GitHub/GitLab
- [ ] Testar deploy automático fazendo push

## 🔧 6. APIs LARAVEL (se houver)

Para cada API:

- [ ] Executar `./scripts/add-api.sh nome-api subdominio porta`
- [ ] Projeto Laravel copiado para `apis/nome-api/app/`
- [ ] `.env` do Laravel configurado
- [ ] Banco de dados criado
- [ ] Migrations rodadas
- [ ] Webhook configurado (opcional)

## ✅ 7. VERIFICAÇÕES PÓS-DEPLOY

### Testar Acessos

- [ ] `https://gestgo.com.br` - Site institucional
- [ ] `https://n8n.gestgo.com.br` - N8N Editor
- [ ] `https://evolution.gestgo.com.br` - Evolution API
- [ ] `https://portainer.gestgo.com.br` - Portainer
- [ ] `https://webhook.gestgo.com.br/health` - Webhook handler

### Verificar Logs

```bash
# Ver logs gerais
make logs

# Ver logs específicos
docker logs n8n-editor
docker logs evolution-api
docker logs nginx-proxy
docker logs webhook-deploy-handler
```

### Verificar Containers

```bash
docker compose ps
```

Todos os containers devem estar com status `Up` e `healthy` (se aplicável).

## 🔐 8. SEGURANÇA ADICIONAL

- [ ] Firewall configurado (portas 80, 443 abertas)
- [ ] Senhas fortes configuradas
- [ ] `.env` não está no Git
- [ ] Backups configurados (opcional mas recomendado)
- [ ] Cloudflare SSL configurado como "Full" ou "Full (strict)"

## 📝 9. DOCUMENTAÇÃO

- [ ] README.md lido e entendido
- [ ] DEPLOY.md consultado para APIs Laravel
- [ ] DEPLOY-AUTOMATICO.md consultado para webhooks

## ⚠️ PROBLEMAS COMUNS

### DNS não propagou
- Aguarde alguns minutos
- Verifique no Cloudflare se os registros estão corretos
- Use `dig gestgo.com.br` para verificar

### Certificados SSL não geram
- Verifique se DNS está propagado
- Verifique se portas 80 e 443 estão abertas
- Verifique logs: `docker logs certbot`

### Containers não iniciam
- Verifique logs: `docker compose logs`
- Verifique se `.env` está configurado
- Verifique se portas não estão em uso

### N8N não acessa
- Verifique variáveis `N8N_HOST` e `N8N_PROTOCOL` no `.env`
- Verifique se SSL está configurado
- Verifique logs: `docker logs n8n-editor`

## 🎉 PRONTO!

Após completar todos os itens, seu ambiente estará em produção! 🚀

