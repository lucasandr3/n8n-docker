# Webhook Deploy Handler

Sistema de deploy automático via webhooks do GitHub/GitLab para APIs Laravel e site institucional.

## 🚀 Como Funciona

Quando você faz push no repositório Git, o webhook é acionado e automaticamente:
1. Faz `git pull` no diretório correspondente
2. Instala/atualiza dependências (Composer para Laravel)
3. Roda migrations (para APIs Laravel)
4. Limpa e cacheia configurações
5. Reinicia containers se necessário

## 📋 Configuração

### 1. Gerar Secret para Webhook

```bash
# Gere uma string aleatória segura
openssl rand -hex 32
```

Adicione ao `.env`:
```env
WEBHOOK_SECRET=sua-string-gerada-aqui
```

### 2. Configurar no GitHub

1. Vá em **Settings** → **Webhooks** → **Add webhook**
2. **Payload URL**: `https://webhook.gestgo.com.br/webhook/github`
3. **Content type**: `application/json`
4. **Secret**: Cole o mesmo valor do `WEBHOOK_SECRET`
5. **Events**: Selecione apenas **Push events**
6. Clique em **Add webhook**

### 3. Configurar no GitLab

1. Vá em **Settings** → **Webhooks**
2. **URL**: `https://webhook.gestgo.com.br/deploy/api/nome-da-api?token=SEU_TOKEN`
3. **Secret token**: Use o mesmo `WEBHOOK_SECRET`
4. **Trigger**: Selecione **Push events**
5. Clique em **Add webhook**

## 🔧 Endpoints Disponíveis

### Deploy de API Laravel

```bash
POST https://webhook.gestgo.com.br/deploy/api/nome-da-api
```

**Headers:**
- `X-Webhook-Token: SEU_TOKEN` (para GitLab ou uso genérico)
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

**Headers:**
- `X-Webhook-Token: SEU_TOKEN`
- `X-Hub-Signature-256: ...` (GitHub)

**Body (opcional):**
```json
{
  "branch": "main"
}
```

### Webhook Genérico do GitHub

```bash
POST https://webhook.gestgo.com.br/webhook/github
```

Este endpoint detecta automaticamente se é API ou institucional baseado no nome do repositório.

## 📝 Preparar Repositórios

### Para APIs Laravel

1. Inicialize Git no diretório da API:
   ```bash
   cd apis/nome-da-api/app
   git init
   git remote add origin https://github.com/seu-usuario/nome-do-repo.git
   git add .
   git commit -m "Initial commit"
   git push -u origin main
   ```

2. Configure o webhook no GitHub/GitLab apontando para:
   - `https://webhook.gestgo.com.br/deploy/api/nome-da-api`

### Para Site Institucional

1. Inicialize Git no diretório institucional:
   ```bash
   cd institucional
   git init
   git remote add origin https://github.com/seu-usuario/institucional.git
   git add .
   git commit -m "Initial commit"
   git push -u origin main
   ```

2. Configure o webhook no GitHub/GitLab apontando para:
   - `https://webhook.gestgo.com.br/deploy/institucional`

## 🔒 Segurança

- **GitHub**: Usa assinatura HMAC SHA-256 para validar requisições
- **GitLab/Genérico**: Usa token no header `X-Webhook-Token`
- Sempre use HTTPS em produção
- Mantenha o `WEBHOOK_SECRET` seguro e nunca commite no Git

## 🧪 Testar Localmente

### Testar endpoint de health

```bash
curl http://localhost:8087/health
```

### Testar deploy manualmente

```bash
# Deploy de API
curl -X POST http://localhost:8087/deploy/api/nome-da-api \
  -H "X-Webhook-Token: seu-token" \
  -H "Content-Type: application/json" \
  -d '{"branch": "main"}'

# Deploy institucional
curl -X POST http://localhost:8087/deploy/institucional \
  -H "X-Webhook-Token: seu-token" \
  -H "Content-Type: application/json" \
  -d '{"branch": "main"}'
```

## 📊 Logs

Para ver os logs do webhook handler:

```bash
docker logs -f webhook-deploy-handler
```

## ⚠️ Troubleshooting

### Webhook não está funcionando

1. Verifique se o `WEBHOOK_SECRET` está configurado no `.env`
2. Verifique os logs: `docker logs webhook-deploy-handler`
3. Teste o endpoint de health: `curl http://localhost:8087/health`

### Erro de permissão no Git

Certifique-se de que o diretório tem permissões corretas:
```bash
chmod -R 755 apis/nome-da-api/app
chmod -R 755 institucional
```

### Erro ao executar scripts

Verifique se os scripts têm permissão de execução:
```bash
chmod +x scripts/deploy-api.sh
chmod +x scripts/deploy-institucional.sh
```

