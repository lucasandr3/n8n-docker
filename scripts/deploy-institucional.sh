#!/bin/bash

# Script para fazer deploy automático do site institucional
# Suporta Angular, React, Vue ou HTML estático
# Uso: ./deploy-institucional.sh [branch]

set -e

BRANCH=${1:-main}
INSTITUCIONAL_DIR="institucional"
BUILD_DIR="dist"

if [ ! -d "$INSTITUCIONAL_DIR" ]; then
    echo "❌ Erro: Diretório $INSTITUCIONAL_DIR não encontrado"
    exit 1
fi

echo "🚀 Iniciando deploy do site institucional (branch: $BRANCH)"

# Entrar no diretório institucional
cd "$INSTITUCIONAL_DIR"

# Verificar se é um repositório Git
if [ ! -d ".git" ]; then
    echo "⚠️  Diretório não é um repositório Git. Pulando git pull..."
else
    echo "📥 Fazendo pull do repositório..."
    git fetch origin
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
fi

# Verificar se é projeto Angular/React/Vue (tem package.json e node_modules ou precisa instalar)
if [ -f "package.json" ]; then
    echo "📦 Projeto Node.js detectado (Angular/React/Vue)"
    
    # Verificar se é Angular
    if [ -f "angular.json" ]; then
        echo "🅰️  Projeto Angular detectado"
        
        # Instalar dependências se necessário
        if [ ! -d "node_modules" ]; then
            echo "📥 Instalando dependências do npm..."
            docker run --rm -v "$(pwd):/app" -w /app node:20-alpine npm ci --legacy-peer-deps || docker run --rm -v "$(pwd):/app" -w /app node:20-alpine npm install --legacy-peer-deps
        else
            echo "📥 Atualizando dependências do npm..."
            docker run --rm -v "$(pwd):/app" -w /app node:20-alpine npm install --legacy-peer-deps
        fi
        
        # Fazer build do Angular
        echo "🔨 Fazendo build do Angular (produção)..."
        docker run --rm -v "$(pwd):/app" -w /app node:20-alpine npm run build -- --configuration production || docker run --rm -v "$(pwd):/app" -w /app node:20-alpine npx ng build --configuration production
        
        # Verificar onde o build foi gerado e organizar
        if [ -d "dist" ]; then
            # Verificar se há subdiretório em dist/ (ex: dist/nome-projeto/)
            DIST_SUBDIR=$(find dist -maxdepth 1 -type d ! -path dist | head -1)
            
            if [ -n "$DIST_SUBDIR" ] && [ -f "$DIST_SUBDIR/index.html" ]; then
                echo "📁 Build encontrado em: $DIST_SUBDIR"
                echo "📋 Movendo arquivos do build para dist/ (raiz)..."
                # Mover conteúdo do subdiretório para dist/ (raiz)
                mv "$DIST_SUBDIR"/* dist/ 2>/dev/null || true
                # Remover subdiretório vazio
                rmdir "$DIST_SUBDIR" 2>/dev/null || true
                echo "✅ Arquivos organizados em dist/"
            fi
            
            # Copiar conteúdo de dist/ para a raiz (para Nginx servir diretamente)
            if [ -f "dist/index.html" ]; then
                echo "📋 Copiando build para raiz do diretório..."
                # Manter dist/ como backup e copiar para raiz
                cp -r dist/* . 2>/dev/null || true
                echo "✅ Build copiado para raiz (Nginx servirá daqui)"
            fi
        fi
        
    # Verificar se é React (tem react-scripts ou vite)
    elif grep -q "react-scripts\|vite" package.json 2>/dev/null; then
        echo "⚛️  Projeto React detectado"
        
        # Instalar dependências
        if [ ! -d "node_modules" ]; then
            echo "📥 Instalando dependências do npm..."
            docker run --rm -v "$(pwd):/app" -w /app node:20-alpine npm ci || docker run --rm -v "$(pwd):/app" -w /app node:20-alpine npm install
        else
            echo "📥 Atualizando dependências do npm..."
            docker run --rm -v "$(pwd):/app" -w /app node:20-alpine npm install
        fi
        
        # Fazer build do React
        echo "🔨 Fazendo build do React (produção)..."
        docker run --rm -v "$(pwd):/app" -w /app node:20-alpine npm run build
        
        # Copiar build para raiz (React geralmente gera em build/ ou dist/)
        if [ -d "build" ] && [ -f "build/index.html" ]; then
            echo "📋 Copiando build do React para raiz..."
            cp -r build/* . 2>/dev/null || true
        elif [ -d "dist" ] && [ -f "dist/index.html" ]; then
            echo "📋 Copiando build do React para raiz..."
            cp -r dist/* . 2>/dev/null || true
        fi
        
    # Verificar se é Vue
    elif grep -q "vue" package.json 2>/dev/null && ([ -f "vite.config.js" ] || [ -f "vue.config.js" ]); then
        echo "🖖 Projeto Vue detectado"
        
        # Instalar dependências
        if [ ! -d "node_modules" ]; then
            echo "📥 Instalando dependências do npm..."
            docker run --rm -v "$(pwd):/app" -w /app node:20-alpine npm ci || docker run --rm -v "$(pwd):/app" -w /app node:20-alpine npm install
        else
            echo "📥 Atualizando dependências do npm..."
            docker run --rm -v "$(pwd):/app" -w /app node:20-alpine npm install
        fi
        
        # Fazer build do Vue
        echo "🔨 Fazendo build do Vue (produção)..."
        docker run --rm -v "$(pwd):/app" -w /app node:20-alpine npm run build
        
        # Copiar build para raiz (Vue geralmente gera em dist/)
        if [ -d "dist" ] && [ -f "dist/index.html" ]; then
            echo "📋 Copiando build do Vue para raiz..."
            cp -r dist/* . 2>/dev/null || true
        fi
        
    else
        echo "📦 Projeto Node.js genérico detectado"
        # Tentar build genérico
        if grep -q "\"build\"" package.json; then
            echo "🔨 Executando script de build..."
            if [ ! -d "node_modules" ]; then
                docker run --rm -v "$(pwd):/app" -w /app node:20-alpine npm install
            fi
            docker run --rm -v "$(pwd):/app" -w /app node:20-alpine npm run build
            
            # Tentar copiar build para raiz (pode ser dist/, build/, ou outro)
            if [ -d "dist" ] && [ -f "dist/index.html" ]; then
                echo "📋 Copiando build para raiz..."
                cp -r dist/* . 2>/dev/null || true
            elif [ -d "build" ] && [ -f "build/index.html" ]; then
                echo "📋 Copiando build para raiz..."
                cp -r build/* . 2>/dev/null || true
            fi
        fi
    fi
    
    echo "✅ Build concluído!"
    
    # Verificar se o build foi gerado
    if [ -d "dist" ] && [ "$(ls -A dist)" ]; then
        echo "✅ Arquivos de build encontrados em dist/"
    else
        echo "⚠️  Aviso: Diretório dist/ não encontrado ou vazio. Servindo arquivos estáticos diretamente."
    fi
else
    echo "📄 Projeto HTML estático detectado (sem build necessário)"
fi

# Voltar para a raiz do projeto
cd ..

echo "🔄 Reiniciando Nginx para aplicar mudanças..."
docker compose restart nginx

echo "✅ Deploy do site institucional concluído com sucesso!"

