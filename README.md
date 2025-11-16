# N8N Docker Setup com Evolution API, Portainer e Múltiplas APIs Laravel

Stack completa com N8N, Evolution API, Portainer, múltiplas APIs Laravel (cada uma com seu subdomínio e banco), PostgreSQL, Redis e Nginx com SSL.

## 🚀 Serviços

### Produção (VPS com domínio)
- **Site Institucional**: `https://gestgo.com.br`
- **N8N Editor**: `https://n8n.gestgo.com.br`
- **Evolution API**: `https://evolution.gestgo.com.br`
- **Portainer**: `https://portainer.gestgo.com.br`
- **Webhook Handler**: `https://webhook.gestgo.com.br` (deploy automático)
- **APIs Laravel**: Cada API tem seu próprio subdomínio (ex: `https://vendas.gestgo.com.br`)

### Desenvolvimento Local
- **N8N Editor**: `http://localhost:8081`
- **Evolution API**: `http://localhost:8082`
- **Portainer**: `http://localhost:9000` (acesso direto) ou `http://localhost:8083` (via proxy)
- **Webhook Handler**: `http://localhost:8087` (deploy automático)
- **APIs Laravel**: Cada API tem sua própria porta local (configurada ao adicionar)

## 📋 Pré-requisitos

1. Docker e Docker Compose instalados
2. Domínio `gestgo.com.br` configurado no Cloudflare
3. DNS apontando para a VPS:
   - `gestgo.com.br` e `www.gestgo.com.br` → IP da VPS (site institucional)
   - `n8n.gestgo.com.br` → IP da VPS
   - `evolution.gestgo.com.br` → IP da VPS
   - `portainer.gestgo.com.br` → IP da VPS
   - `webhook.gestgo.com.br` → IP da VPS (deploy automático)
   - Para cada API Laravel, configure o subdomínio correspondente (ex: `vendas.gestgo.com.br`)

## 🔧 Instalação

### Teste Local (Desenvolvimento)

Para testar localmente, não é necessário configurar DNS ou SSL:

1. **Inicie os serviços:**
   ```bash
   make up
   ```

2. **Acesse os serviços:**
   - N8N: http://localhost:8081
   - Evolution API: http://localhost:8082
   - Portainer: http://localhost:9000 (recomendado - acesso direto, evita problemas de origin)
   - Portainer (via proxy): http://localhost:8083
   - APIs Laravel: Cada API terá sua própria porta (configurada ao adicionar)

### Produção (VPS)

1. **Clone ou copie os arquivos para a VPS**

2. **Configure o arquivo `.env`** com as variáveis necessárias (veja `.env-example`)

3. **Crie os bancos de dados** (se ainda não existirem):
   ```bash
   # Banco para Evolution API
   docker exec postgres-n8n psql -U postgres -c "CREATE DATABASE evolution;"
   ```

4. **Adicione suas APIs Laravel** usando o script helper:
   ```bash
   ./scripts/add-api.sh <nome-api> <subdominio> <porta-local>
   ```
   
   Exemplo:
   ```bash
   ./scripts/add-api.sh vendas vendas 8085
   ```
   
   Isso criará a estrutura necessária. Depois:
   - Coloque seu projeto Laravel em `apis/<nome-api>/app/`
   - Configure o `.env` do Laravel com as credenciais do PostgreSQL
   - Crie o banco de dados: `docker exec postgres-n8n psql -U postgres -c "CREATE DATABASE <nome_api>;"`
   
   Veja mais detalhes em `apis/README.md`

5. **Inicie os serviços**:
   ```bash
   make up
   ```

6. **Configure os certificados SSL**:
   ```bash
   make ssl-init
   ```
   Ou manualmente:
   ```bash
   CERTBOT_EMAIL=seu-email@gestgo.com.br ./init-ssl.sh
   ```

## 📝 Comandos Úteis

### Comandos Básicos

```bash
# Iniciar todos os serviços
make up

# Parar e remover tudo (incluindo volumes)
make down

# Deploy completo (down + up)
make deploy

# Ver logs de todos os serviços
make logs

# Reiniciar todos os serviços
make restart

# Renovar certificados SSL
make ssl-renew
```

### Reiniciar Serviços Específicos

```bash
# Reiniciar serviço específico (sem atualizar imagem)
make restart-n8n          # Reinicia N8N (editor, workers, webhooks)
make restart-evolution    # Reinicia Evolution API
make restart-portainer    # Reinicia Portainer
make restart-nginx        # Reinicia Nginx
make restart-postgres     # Reinicia PostgreSQL
make restart-redis        # Reinicia Redis

# Reiniciar uma API Laravel específica
make restart-api API_NAME=vendas
```

### Atualizar Imagens Docker

```bash
# Atualizar todas as imagens e reiniciar serviços
make pull-update

# Apenas baixar novas versões (sem reiniciar)
make pull

# Atualizar serviço específico
make update-n8n          # Atualiza N8N (editor, workers, webhooks)
make update-evolution    # Atualiza Evolution API
make update-portainer    # Atualiza Portainer
make update-nginx        # Atualiza Nginx
make update-postgres     # Atualiza PostgreSQL
make update-redis        # Atualiza Redis

# Atualizar uma API Laravel específica
make update-api API_NAME=vendas

# Ver versões das imagens instaladas
make versions
```

### Ver Logs de Serviços Específicos

```bash
# Logs do N8N
make logs-n8n

# Logs da Evolution API
make logs-evolution

# Logs de uma API Laravel específica
make logs-api API_NAME=vendas
```

### Exemplos de Uso em Produção

```bash
# Atualizar apenas o N8N sem afetar outros serviços
make update-n8n

# Atualizar uma API Laravel específica
make update-api API_NAME=vendas

# Verificar se há atualizações disponíveis
make pull

# Aplicar atualizações e reiniciar tudo
make pull-update
```

## 🔐 Segurança

- Todos os serviços estão protegidos com SSL/TLS (HTTPS)
- Certificados são renovados automaticamente via Certbot
- Serviços internos não expõem portas diretamente (apenas via Nginx)

## 🌐 Configuração DNS no Cloudflare

Certifique-se de que os seguintes registros estão configurados:

- **Tipo A**: `n8n` → IP da VPS
- **Tipo A**: `evolution` → IP da VPS  
- **Tipo A**: `portainer` → IP da VPS
- **Tipo A**: Para cada API Laravel, configure o subdomínio (ex: `vendas` → IP da VPS)

Ou use um registro CNAME se preferir.

## 📦 Estrutura de Diretórios

```
.
├── docker-compose.yaml
├── .env
├── Makefile
├── init-ssl.sh
├── nginx/
│   ├── conf.d/
│   │   ├── n8n.conf
│   │   ├── evolution.conf
│   │   ├── portainer.conf
│   │   └── default.conf
│   └── certbot/
│       ├── conf/
│       └── www/
├── n8n_data/
├── postgres_data/
├── redis_data/
├── evolution_instances/
├── portainer_data/
├── institucional/    # Site institucional (gestgo.com.br)
│   ├── index.html
│   ├── css/
│   ├── js/
│   └── images/
├── apis/             # Múltiplas APIs Laravel
│   ├── template/     # Templates para criar novas APIs
│   ├── api1/         # Exemplo: primeira API
│   │   ├── app/      # Código Laravel
│   │   ├── Dockerfile
│   │   └── php.ini
│   └── ...
├── webhook-handler/  # Sistema de deploy automático via webhooks
│   ├── Dockerfile
│   ├── server.js
│   └── package.json
└── scripts/
    ├── add-api.sh              # Script para adicionar novas APIs
    ├── deploy-api.sh           # Script de deploy para APIs Laravel
    └── deploy-institucional.sh # Script de deploy para site institucional
```

## 🚀 Deploy Automático via Git

O projeto inclui um sistema completo de deploy automático via webhooks do GitHub/GitLab.

### Configuração Rápida

1. **Gere um secret**:
   ```bash
   openssl rand -hex 32
   ```
   Adicione ao `.env`: `WEBHOOK_SECRET=sua-string-gerada`

2. **Configure webhook no GitHub/GitLab**:
   - URL: `https://webhook.gestgo.com.br/webhook/github`
   - Secret: Use o mesmo `WEBHOOK_SECRET`
   - Events: Push events

3. **Inicialize Git nos diretórios**:
   ```bash
   # Para API
   cd apis/nome-da-api/app
   git init
   git remote add origin https://github.com/seu-usuario/repo.git
   
   # Para institucional
   cd institucional
   git init
   git remote add origin https://github.com/seu-usuario/institucional.git
   ```

**Documentação completa**: Veja `DEPLOY-AUTOMATICO.md`

## 🔄 Renovação de Certificados

Os certificados SSL são renovados automaticamente pelo container `certbot` a cada 12 horas. O Nginx recarrega a configuração a cada 6 horas para aplicar novos certificados.

Para renovação manual:
```bash
make ssl-renew
```

## ⚠️ Notas Importantes

- **Primeira execução**: Execute `make ssl-init` após configurar os DNS
- **Cloudflare**: Se usar proxy do Cloudflare, certifique-se de que o SSL está configurado como "Full" ou "Full (strict)"
- **Firewall**: Certifique-se de que as portas 80 e 443 estão abertas na VPS
- **Backup**: Faça backup regular dos volumes de dados (`n8n_data`, `postgres_data`, etc.)

