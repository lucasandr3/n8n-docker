# APIs Laravel

Este diretório contém todas as suas APIs Laravel. Cada API tem seu próprio subdomínio e banco de dados.

## Estrutura

```
apis/
├── template/          # Templates para criar novas APIs
│   ├── Dockerfile
│   ├── php.ini
│   ├── nginx.conf.ssl
│   ├── nginx.conf.local
│   └── docker-compose.service.yml
├── api1/             # Exemplo: primeira API
│   ├── app/          # Código Laravel aqui
│   ├── Dockerfile
│   └── php.ini
├── api2/             # Exemplo: segunda API
│   ├── app/
│   ├── Dockerfile
│   └── php.ini
└── ...
```

## Como adicionar uma nova API

### Opção 1: Usando o script helper (recomendado)

```bash
./scripts/add-api.sh nome-da-api subdominio porta-local
```

Exemplo:
```bash
./scripts/add-api.sh vendas vendas 8085
```

Isso criará:
- `apis/vendas/` com a estrutura necessária
- Adicionará o serviço ao docker-compose.yaml
- Criará as configurações do Nginx
- Configurará tudo automaticamente

### Opção 2: Manualmente

1. **Crie o diretório da API:**
   ```bash
   mkdir -p apis/nome-da-api/app
   ```

2. **Copie os arquivos do template:**
   ```bash
   cp apis/template/Dockerfile apis/nome-da-api/
   cp apis/template/php.ini apis/nome-da-api/
   ```

3. **Coloque seu projeto Laravel em `apis/nome-da-api/app/`**

4. **Adicione o serviço ao docker-compose.yaml:**
   - Copie o conteúdo de `apis/template/docker-compose.service.yml`
   - Substitua `{API_NAME}` pelo nome da sua API
   - Adicione ao final do arquivo `docker-compose.yaml` (antes de `networks:`)

5. **Crie as configurações do Nginx:**
   ```bash
   # Para produção (SSL)
   cp apis/template/nginx.conf.ssl nginx/conf.d/nome-da-api.conf.ssl
   # Edite e substitua {SUBDOMAIN} e {CONTAINER_NAME}
   
   # Para local
   cp apis/template/nginx.conf.local nginx/conf.d/nome-da-api.conf
   # Edite e substitua {LOCAL_PORT} e {CONTAINER_NAME}
   ```

6. **Adicione o volume ao serviço nginx no docker-compose.yaml:**
   ```yaml
   volumes:
     - ./apis/nome-da-api/app:/var/www/html/nome-da-api:ro
   ```

7. **Crie o banco de dados:**
   ```bash
   docker exec postgres-n8n psql -U postgres -c "CREATE DATABASE nome_da_api;"
   ```

8. **Configure o `.env` do Laravel** em `apis/nome-da-api/app/.env`:
   ```env
   DB_CONNECTION=pgsql
   DB_HOST=postgres-n8n
   DB_PORT=5432
   DB_DATABASE=nome_da_api
   DB_USERNAME=postgres
   DB_PASSWORD=postgres
   ```

9. **Adicione o subdomínio ao script `init-ssl.sh`** se for usar SSL

10. **Reinicie os serviços:**
    ```bash
    make restart
    ```

## Convenções de Nomenclatura

- **Nome da API**: use apenas letras minúsculas, números e hífens (ex: `vendas-api`, `api1`)
- **Subdomínio**: será `{subdominio}.gestgo.com.br`
- **Container**: `laravel-{nome-da-api}`
- **Banco de dados**: `{nome_da_api}` (underscores são permitidos no PostgreSQL)

## Exemplo Completo

Vamos criar uma API chamada "vendas":

1. Execute o script:
   ```bash
   ./scripts/add-api.sh vendas vendas 8085
   ```

2. Coloque seu projeto Laravel:
   ```bash
   cp -r /caminho/do/seu/projeto/* apis/vendas/app/
   ```

3. Configure o `.env` do Laravel em `apis/vendas/app/.env`

4. Crie o banco:
   ```bash
   docker exec postgres-n8n psql -U postgres -c "CREATE DATABASE vendas;"
   ```

5. Inicie:
   ```bash
   make up
   ```

6. Acesse:
   - Local: `http://localhost:8085`
   - Produção: `https://vendas.gestgo.com.br`

