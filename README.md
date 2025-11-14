# N8N Docker Setup com Evolution API e Portainer

Stack completa com N8N, Evolution API, Portainer, PostgreSQL, Redis e Nginx com SSL.

## 🚀 Serviços

### Produção (VPS com domínio)
- **N8N Editor**: `https://n8n.gestgo.com.br`
- **Evolution API**: `https://evolution.gestgo.com.br`
- **Portainer**: `https://portainer.gestgo.com.br`

### Desenvolvimento Local
- **N8N Editor**: `http://localhost:8081`
- **Evolution API**: `http://localhost:8082`
- **Portainer**: `http://localhost:9000` (acesso direto) ou `http://localhost:8083` (via proxy)

## 📋 Pré-requisitos

1. Docker e Docker Compose instalados
2. Domínio `gestgo.com.br` configurado no Cloudflare
3. DNS apontando para a VPS:
   - `n8n.gestgo.com.br` → IP da VPS
   - `evolution.gestgo.com.br` → IP da VPS
   - `portainer.gestgo.com.br` → IP da VPS

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

### Produção (VPS)

1. **Clone ou copie os arquivos para a VPS**

2. **Configure o arquivo `.env`** com as variáveis necessárias:
   ```bash
   # Evolution API
   DATABASE_ENABLED=true
   DATABASE_PROVIDER=postgresql
   DATABASE_CONNECTION_URI=postgresql://postgres:postgres@postgres-n8n:5432/evolution?schema=public
   CACHE_REDIS_URI=redis://redis-n8n:6379/0
   AUTHENTICATION_API_KEY=sua-chave-aqui
   ```

3. **Crie o banco de dados Evolution** (se ainda não existir):
   ```bash
   docker exec postgres-n8n psql -U postgres -c "CREATE DATABASE evolution;"
   ```

4. **Inicie os serviços**:
   ```bash
   make up
   ```

5. **Configure os certificados SSL**:
   ```bash
   make ssl-init
   ```
   Ou manualmente:
   ```bash
   CERTBOT_EMAIL=seu-email@gestgo.com.br ./init-ssl.sh
   ```

## 📝 Comandos Úteis

```bash
# Iniciar todos os serviços
make up

# Parar e remover tudo (incluindo volumes)
make down

# Deploy completo (down + up)
make deploy

# Ver logs
make logs

# Reiniciar todos os serviços
make restart

# Renovar certificados SSL
make ssl-renew
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
└── portainer_data/
```

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

