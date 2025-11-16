# 🚀 Deploy Automático via Git Webhooks

Sistema completo de deploy automático para APIs Laravel e site institucional via webhooks do GitHub/GitLab.

## 📋 Pré-requisitos

1. Repositórios Git configurados (GitHub ou GitLab)
2. `WEBHOOK_SECRET` configurado no `.env`
3. DNS configurado: `webhook.gestgo.com.br` → IP da VPS

## 🔧 Configuração Inicial

### 1. Gerar Secret

```bash
openssl rand -hex 32
```

Adicione ao `.env`:
```env
WEBHOOK_SECRET=sua-string-gerada-aqui
```

### 2. Inicializar Git nos Diretórios

#### Para API Laravel:

```bash
cd apis/nome-da-api/app
git init
git remote add origin https://github.com/seu-usuario/nome-do-repo.git
git add .
git commit -m "Initial commit"
git push -u origin main
```

#### Para Site Institucional:

```bash
cd institucional
git init
git remote add origin https://github.com/seu-usuario/institucional.git
git add .
git commit -m "Initial commit"
git push -u origin main
```

### 3. Configurar Webhook no GitHub

1. Vá em **Settings** → **Webhooks** → **Add webhook**
2. **Payload URL**: `https://webhook.gestgo.com.br/webhook/github`
3. **Content type**: `application/json`
4. **Secret**: Cole o mesmo valor do `WEBHOOK_SECRET`
5. **Events**: Selecione apenas **Push events**
6. Clique em **Add webhook**

### 4. Configurar Webhook no GitLab

1. Vá em **Settings** → **Webhooks**
2. **URL**: `https://webhook.gestgo.com.br/deploy/api/nome-da-api?token=SEU_TOKEN`
3. **Secret token**: Use o mesmo `WEBHOOK_SECRET`
4. **Trigger**: Selecione **Push events**
5. Clique em **Add webhook**

## 🎯 Como Funciona

Quando você faz `git push`:

1. **GitHub/GitLab** envia webhook para `webhook.gestgo.com.br`
2. **Webhook Handler** valida a assinatura/token
3. **Script de deploy** executa:
   - `git pull` no diretório correspondente
   - Instala/atualiza dependências (Composer para Laravel)
   - Roda migrations (para APIs Laravel)
   - Limpa e cacheia configurações
   - Ajusta permissões

## 📝 Endpoints Disponíveis

### Deploy Específico de API

```bash
POST https://webhook.gestgo.com.br/deploy/api/nome-da-api
```

**Headers:**
- `X-Webhook-Token: SEU_TOKEN` (GitLab/genérico)
- `X-Hub-Signature-256: ...` (GitHub - automático)

**Body (opcional):**
```json
{
  "branch": "main"
}
```

### Deploy do Site Institucional

```bash
POST https://webhook.gestgo.com.br/deploy/institucional
```

### Webhook Genérico do GitHub

```bash
POST https://webhook.gestgo.com.br/webhook/github
```

Detecta automaticamente se é API ou institucional pelo nome do repositório.

## 🔍 Detecção Automática (GitHub)

O webhook genérico do GitHub tenta detectar automaticamente:

- **Institucional**: Se o nome do repositório contém "institucional"
- **API Laravel**: Remove "api" do nome e usa como nome da API

**Exemplo:**
- Repo: `vendas-api` → API: `vendas`
- Repo: `institucional` → Site institucional

## 🧪 Testar Localmente

```bash
# Health check
curl http://localhost:8087/health

# Deploy de API (com token)
curl -X POST http://localhost:8087/deploy/api/vendas \
  -H "X-Webhook-Token: seu-token" \
  -H "Content-Type: application/json" \
  -d '{"branch": "main"}'

# Deploy institucional
curl -X POST http://localhost:8087/deploy/institucional \
  -H "X-Webhook-Token: seu-token" \
  -H "Content-Type: application/json" \
  -d '{"branch": "main"}'
```

## 📊 Monitoramento

### Ver Logs

```bash
# Logs do webhook handler
docker logs -f webhook-deploy-handler

# Logs de uma API específica
docker logs -f laravel-nome-da-api
```

### Verificar Status

```bash
# Status dos containers
docker compose ps

# Verificar se webhook está rodando
curl http://localhost:8087/health
```

## ⚠️ Troubleshooting

### Webhook não está funcionando

1. Verifique `WEBHOOK_SECRET` no `.env`
2. Verifique logs: `docker logs webhook-deploy-handler`
3. Teste health: `curl http://localhost:8087/health`
4. Verifique DNS: `webhook.gestgo.com.br` apontando para VPS

### Erro de permissão no Git

```bash
chmod -R 755 apis/nome-da-api/app
chmod -R 755 institucional
```

### Erro ao executar scripts

```bash
chmod +x scripts/deploy-api.sh
chmod +x scripts/deploy-institucional.sh
```

### Erro de assinatura (GitHub)

- Verifique se o `WEBHOOK_SECRET` está correto
- Verifique se o secret no GitHub está igual ao `.env`

## 🔒 Segurança

- ✅ HTTPS obrigatório em produção
- ✅ Validação de assinatura HMAC (GitHub)
- ✅ Validação de token (GitLab/genérico)
- ✅ `WEBHOOK_SECRET` nunca deve ser commitado
- ✅ Use tokens fortes e únicos

## 📚 Estrutura de Arquivos

```
webhook-handler/
├── Dockerfile
├── package.json
├── server.js
└── README.md

scripts/
├── deploy-api.sh
└── deploy-institucional.sh
```

## 🎉 Pronto!

Agora você pode fazer push no Git e o deploy será automático! 🚀

