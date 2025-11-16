#!/bin/bash

# Script para fazer deploy automático de uma API Laravel
# Uso: ./deploy-api.sh <nome-api> [branch]

set -e

API_NAME=$1
BRANCH=${2:-main}

if [ -z "$API_NAME" ]; then
    echo "❌ Erro: Especifique o nome da API"
    echo "Uso: ./deploy-api.sh <nome-api> [branch]"
    exit 1
fi

API_DIR="apis/${API_NAME}/app"
CONTAINER_NAME="laravel-${API_NAME}"

if [ ! -d "$API_DIR" ]; then
    echo "❌ Erro: Diretório $API_DIR não encontrado"
    exit 1
fi

echo "🚀 Iniciando deploy da API: $API_NAME (branch: $BRANCH)"

# Entrar no diretório da API
cd "$API_DIR"

# Verificar se é um repositório Git
if [ ! -d ".git" ]; then
    echo "⚠️  Diretório não é um repositório Git. Pulando git pull..."
else
    echo "📥 Fazendo pull do repositório..."
    git fetch origin
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
fi

# Voltar para a raiz do projeto
cd ../../..

echo "📦 Instalando dependências do Composer..."
docker exec -it "$CONTAINER_NAME" composer install --no-dev --optimize-autoloader --no-interaction

echo "🔄 Limpando cache do Laravel..."
docker exec -it "$CONTAINER_NAME" php artisan config:clear
docker exec -it "$CONTAINER_NAME" php artisan route:clear
docker exec -it "$CONTAINER_NAME" php artisan view:clear
docker exec -it "$CONTAINER_NAME" php artisan cache:clear

echo "📝 Rodando migrations..."
docker exec -it "$CONTAINER_NAME" php artisan migrate --force --no-interaction

echo "💾 Cacheando configurações..."
docker exec -it "$CONTAINER_NAME" php artisan config:cache
docker exec -it "$CONTAINER_NAME" php artisan route:cache
docker exec -it "$CONTAINER_NAME" php artisan view:cache

echo "🔧 Ajustando permissões..."
docker exec "$CONTAINER_NAME" chown -R www-data:www-data /var/www/html
docker exec "$CONTAINER_NAME" chmod -R 755 /var/www/html/storage
docker exec "$CONTAINER_NAME" chmod -R 755 /var/www/html/bootstrap/cache

echo "✅ Deploy da API $API_NAME concluído com sucesso!"

