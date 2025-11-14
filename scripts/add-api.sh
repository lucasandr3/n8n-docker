#!/bin/bash

# Script para adicionar uma nova API Laravel ao projeto
# Uso: ./scripts/add-api.sh <nome-api> <subdominio> <porta-local>
# Exemplo: ./scripts/add-api.sh vendas vendas 8085

set -e

if [ $# -lt 3 ]; then
    echo "❌ Erro: Parâmetros insuficientes"
    echo "Uso: $0 <nome-api> <subdominio> <porta-local>"
    echo "Exemplo: $0 vendas vendas 8085"
    exit 1
fi

API_NAME="$1"
SUBDOMAIN="$2"
LOCAL_PORT="$3"
CONTAINER_NAME="laravel-${API_NAME}"
DB_NAME="${API_NAME//-/_}"  # Substitui hífens por underscores para o banco

echo "🚀 Adicionando nova API: $API_NAME"
echo "   Subdomínio: ${SUBDOMAIN}.gestgo.com.br"
echo "   Porta local: $LOCAL_PORT"
echo "   Container: $CONTAINER_NAME"
echo "   Banco de dados: $DB_NAME"

# 1. Criar diretório da API
echo "📁 Criando estrutura de diretórios..."
mkdir -p "apis/${API_NAME}/app"

# 2. Copiar arquivos do template
echo "📋 Copiando arquivos do template..."
cp apis/template/Dockerfile "apis/${API_NAME}/"
cp apis/template/php.ini "apis/${API_NAME}/"

# 3. Adicionar serviço ao docker-compose.yaml
echo "🐳 Adicionando serviço ao docker-compose.yaml..."
# Criar arquivo temporário com o serviço
TEMP_SERVICE=$(mktemp)
cat apis/template/docker-compose.service.yml | sed "s/{API_NAME}/${API_NAME}/g" > "$TEMP_SERVICE"
# Inserir antes da linha "networks:" usando awk
awk -v file="$TEMP_SERVICE" '/^networks:/ {while ((getline line < file) > 0) print line; close(file)} 1' docker-compose.yaml > docker-compose.yaml.tmp && mv docker-compose.yaml.tmp docker-compose.yaml
rm -f "$TEMP_SERVICE"

# 4. Adicionar volume ao nginx
echo "🌐 Adicionando volume ao Nginx..."
# Encontrar a linha com volumes do nginx e adicionar o novo volume
sed -i "/- \.\/nginx\/certbot\/www:\/var\/www\/certbot/a\      - ./apis/${API_NAME}/app:/var/www/html/${API_NAME}:ro" docker-compose.yaml

# 5. Adicionar dependência do nginx
echo "🔗 Adicionando dependência no Nginx..."
sed -i "/- portainer$/a\      - ${CONTAINER_NAME}" docker-compose.yaml

# 6. Adicionar porta local ao nginx (se ainda não existir)
if ! grep -q "# ${API_NAME} local" docker-compose.yaml; then
    sed -i "/- 8083:8083/a\      - ${LOCAL_PORT}:${LOCAL_PORT}  # ${API_NAME} local" docker-compose.yaml
fi

# 7. Criar configuração Nginx para local
echo "📝 Criando configuração Nginx local..."
LOCAL_CONF=$(cat apis/template/nginx.conf.local | sed "s/{LOCAL_PORT}/${LOCAL_PORT}/g" | sed "s/{CONTAINER_NAME}/${CONTAINER_NAME}/g" | sed "s/{API_NAME}/${API_NAME}/g")
echo "$LOCAL_CONF" > "nginx/conf.d/${API_NAME}.conf"

# 8. Criar configuração Nginx para SSL
echo "🔐 Criando configuração Nginx SSL..."
SSL_CONF=$(cat apis/template/nginx.conf.ssl | sed "s/{SUBDOMAIN}/${SUBDOMAIN}/g" | sed "s/{CONTAINER_NAME}/${CONTAINER_NAME}/g" | sed "s/{API_NAME}/${API_NAME}/g")
echo "$SSL_CONF" > "nginx/conf.d/${API_NAME}.conf.ssl"

# 9. Atualizar init-ssl.sh
echo "📜 Atualizando script de SSL..."
if ! grep -q "\"${SUBDOMAIN}.gestgo.com.br\"" init-ssl.sh; then
    sed -i "/DOMAINS=(/a\    \"${SUBDOMAIN}.gestgo.com.br\"" init-ssl.sh
    sed -i "/cp nginx\/conf.d\/portainer.conf.ssl/a\    cp nginx/conf.d/${API_NAME}.conf.ssl nginx/conf.d/${API_NAME}.conf 2>/dev/null || true" init-ssl.sh
    sed -i "/https:\/\/portainer.gestgo.com.br/a\    echo \"   - https://${SUBDOMAIN}.gestgo.com.br\"" init-ssl.sh
fi

echo ""
echo "✅ API ${API_NAME} adicionada com sucesso!"
echo ""
echo "📋 Próximos passos:"
echo ""
echo "1. Coloque seu projeto Laravel em: apis/${API_NAME}/app/"
echo "   Exemplo: cp -r /caminho/do/seu/projeto/* apis/${API_NAME}/app/"
echo ""
echo "2. Configure o .env do Laravel em: apis/${API_NAME}/app/.env"
echo "   DB_CONNECTION=pgsql"
echo "   DB_HOST=postgres-n8n"
echo "   DB_PORT=5432"
echo "   DB_DATABASE=${DB_NAME}"
echo "   DB_USERNAME=postgres"
echo "   DB_PASSWORD=postgres"
echo ""
echo "3. Crie o banco de dados:"
echo "   docker exec postgres-n8n psql -U postgres -c \"CREATE DATABASE ${DB_NAME};\""
echo ""
echo "4. Configure o DNS no Cloudflare:"
echo "   ${SUBDOMAIN}.gestgo.com.br → IP da VPS"
echo ""
echo "5. Inicie os serviços:"
echo "   make up"
echo ""
echo "6. Para SSL em produção, execute:"
echo "   make ssl-init"
echo ""
echo "🌐 Acessos:"
echo "   Local: http://localhost:${LOCAL_PORT}"
echo "   Produção: https://${SUBDOMAIN}.gestgo.com.br"

