# N8N Docker Setup com Evolution API, Portainer e Múltiplas APIs Laravel

Stack completa com N8N, Evolution API, Portainer, múltiplas APIs Laravel (cada uma com seu subdomínio e banco), PostgreSQL, Redis e Nginx com SSL.

## 🚀 Serviços

### Produção (VPS com domínio)
- **N8N Editor**: `https://n8n.gestgo.com.br`
- **Evolution API**: `https://evolution.gestgo.com.br`
- **Portainer**: `https://portainer.gestgo.com.br`
- **APIs Laravel**: Cada API tem seu próprio subdomínio (ex: `https://vendas.gestgo.com.br`)

### Desenvolvimento Local
- **N8N Editor**: `http://localhost:8081`
- **Evolution API**: `http://localhost:8082`
- **Portainer**: `http://localhost:9000` (acesso direto) ou `http://localhost:8083` (via proxy)
- **APIs Laravel**: Cada API tem sua própria porta local (configurada ao adicionar)

## 📋 Pré-requisitos

1. Docker e Docker Compose instalados
2. Domínio `gestgo.com.br` configurado no Cloudflare
3. DNS apontando para a VPS:
   - `n8n.gestgo.com.br` → IP da VPS
   - `evolution.gestgo.com.br` → IP da VPS
   - `portainer.gestgo.com.br` → IP da VPS
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
├── apis/             # Múltiplas APIs Laravel
│   ├── template/     # Templates para criar novas APIs
│   ├── api1/         # Exemplo: primeira API
│   │   ├── app/      # Código Laravel
│   │   ├── Dockerfile
│   │   └── php.ini
│   └── ...
└── scripts/
    └── add-api.sh    # Script para adicionar novas APIs
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

