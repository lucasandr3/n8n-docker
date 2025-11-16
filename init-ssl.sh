#!/bin/bash

# Script para inicializar certificados SSL com Let's Encrypt
# Execute este script apenas na primeira vez ou quando precisar renovar os certificados

DOMAINS=(
    "gestgo.com.br"
    "www.gestgo.com.br"
    "n8n.gestgo.com.br"
    "evolution.gestgo.com.br"
    "portainer.gestgo.com.br"
    "webhook.gestgo.com.br"
    # APIs Laravel serão adicionadas automaticamente pelo script add-api.sh
)

EMAIL="${CERTBOT_EMAIL:-seu-email@gestgo.com.br}"

echo "🚀 Iniciando geração de certificados SSL para os domínios..."

# Criar diretórios necessários
mkdir -p nginx/certbot/conf
mkdir -p nginx/certbot/www

# Usar configurações iniciais (HTTP) se os certificados ainda não existirem
if [ ! -f "nginx/certbot/conf/live/n8n.gestgo.com.br/fullchain.pem" ]; then
    echo "📝 Usando configurações HTTP iniciais..."
    rm -f nginx/conf.d/n8n.conf nginx/conf.d/evolution.conf nginx/conf.d/portainer.conf
    cp nginx/conf.d/n8n-init.conf nginx/conf.d/n8n.conf 2>/dev/null || true
    cp nginx/conf.d/evolution-init.conf nginx/conf.d/evolution.conf 2>/dev/null || true
    cp nginx/conf.d/portainer-init.conf nginx/conf.d/portainer.conf 2>/dev/null || true
fi

# Iniciar nginx para validação
echo "📦 Iniciando nginx para validação..."
docker compose up -d nginx

# Aguardar nginx iniciar
echo "⏳ Aguardando nginx iniciar..."
sleep 10

# Gerar certificados para cada domínio
for domain in "${DOMAINS[@]}"; do
    echo "🔐 Gerando certificado para $domain..."
    
    docker run --rm \
        --network "$(basename $(pwd))_n8n-network" \
        -v "$(pwd)/nginx/certbot/conf:/etc/letsencrypt" \
        -v "$(pwd)/nginx/certbot/www:/var/www/certbot" \
        certbot/certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        -d "$domain"
    
    if [ $? -eq 0 ]; then
        echo "✅ Certificado gerado com sucesso para $domain"
    else
        echo "❌ Erro ao gerar certificado para $domain"
        echo "   Verifique se o DNS está configurado corretamente no Cloudflare"
    fi
done

# Substituir configurações iniciais pelas finais com SSL
echo "📝 Atualizando configurações do Nginx com SSL..."

# Verificar se os certificados foram gerados e atualizar configurações
if [ -f "nginx/certbot/conf/live/n8n.gestgo.com.br/fullchain.pem" ]; then
    echo "✅ Certificados encontrados, aplicando configurações SSL..."
    cp nginx/conf.d/main.conf.ssl nginx/conf.d/main.conf
    cp nginx/conf.d/n8n.conf.ssl nginx/conf.d/n8n.conf
    cp nginx/conf.d/evolution.conf.ssl nginx/conf.d/evolution.conf
    cp nginx/conf.d/portainer.conf.ssl nginx/conf.d/portainer.conf
    cp nginx/conf.d/webhook.conf.ssl nginx/conf.d/webhook.conf
    # APIs Laravel: copiar todos os .conf.ssl para .conf
    for conf in nginx/conf.d/*.conf.ssl; do
        if [ -f "$conf" ] && [[ "$conf" != *"main.conf.ssl" ]] && [[ "$conf" != *"n8n.conf.ssl" ]] && [[ "$conf" != *"evolution.conf.ssl" ]] && [[ "$conf" != *"portainer.conf.ssl" ]] && [[ "$conf" != *"webhook.conf.ssl" ]]; then
            cp "$conf" "${conf%.ssl}" 2>/dev/null || true
        fi
    done
    
    echo "🔄 Reiniciando nginx com certificados SSL..."
    docker compose restart nginx
    echo "✅ Concluído! Certificados SSL configurados."
    echo ""
    echo "🌐 Acesse os serviços:"
    echo "   - https://n8n.gestgo.com.br"
    echo "   - https://evolution.gestgo.com.br"
    echo "   - https://portainer.gestgo.com.br"
    # APIs Laravel serão listadas automaticamente se existirem
else
    echo "⚠️  Alguns certificados não foram gerados. Verifique os logs acima."
    echo "   Os serviços continuarão funcionando via HTTP até os certificados serem gerados."
    echo "   Execute o script novamente após verificar os DNS."
fi

# Limpar arquivos temporários
rm -f nginx/conf.d/n8n-init.conf nginx/conf.d/evolution-init.conf nginx/conf.d/portainer-init.conf

