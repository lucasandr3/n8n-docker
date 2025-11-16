# Site Institucional

Este diretório contém o site institucional que será servido no domínio principal `gestgo.com.br`.

## 🚀 Suporta Múltiplos Frameworks

O deploy automático **detecta automaticamente** e faz build para:

- ✅ **Angular** - Detecta `angular.json` e executa `ng build --configuration production`
  - Instala dependências automaticamente
  - Faz build de produção
  - Organiza arquivos em `dist/` e copia para raiz
- ✅ **React** - Detecta `react-scripts` ou `vite` e executa `npm run build`
  - Suporta `build/` ou `dist/` como diretório de saída
- ✅ **Vue** - Detecta `vue.config.js` ou `vite.config.js` e executa `npm run build`
  - Build gerado em `dist/`
- ✅ **HTML Estático** - Serve diretamente sem build necessário

## 📦 Estrutura

### Para Angular/React/Vue:

```
institucional/
├── src/              # Código fonte
├── dist/             # Build gerado automaticamente (não commitar)
├── package.json
├── angular.json      # (Angular)
├── tsconfig.json     # (TypeScript)
└── ...
```

### Para HTML Estático:

```
institucional/
├── index.html
├── css/
├── js/
└── images/
```

## 🔧 Como Usar

### 1. Colocar seu projeto Angular

```bash
# Copie seu projeto Angular para este diretório
cp -r /caminho/do/seu/projeto/angular/* institucional/

# Ou clone diretamente aqui
cd institucional
git clone https://github.com/seu-usuario/institucional.git .
```

### 2. Configurar Git (para deploy automático)

```bash
cd institucional
git init
git remote add origin https://github.com/seu-usuario/institucional.git
git add .
git commit -m "Initial commit"
git push -u origin main
```

### 3. Deploy Automático

Quando você fizer `git push`, o webhook automaticamente:

1. ✅ Faz `git pull` do repositório
2. ✅ Detecta que é Angular (pelo `angular.json`)
3. ✅ Instala/atualiza dependências (`npm install`)
4. ✅ Faz build de produção (`ng build --configuration production`)
5. ✅ Organiza arquivos: se o build estiver em `dist/nome-projeto/`, move para `dist/`
6. ✅ Copia arquivos de `dist/` para a raiz do diretório
7. ✅ Nginx serve os arquivos da raiz (build compilado)

**Resultado**: Seu site Angular fica online automaticamente! 🎉

## 📝 Configuração do Build

### Angular

O script detecta automaticamente e executa:
```bash
npm run build -- --configuration production
```

Ou se não houver script:
```bash
npx ng build --configuration production
```

### Personalizar Build

Se precisar personalizar o comando de build, edite `scripts/deploy-institucional.sh` ou adicione um script `build` no `package.json`:

```json
{
  "scripts": {
    "build": "ng build --configuration production --output-path=dist"
  }
}
```

## 🔍 Verificar Build

Após o deploy, verifique se o build foi gerado:

```bash
ls -la institucional/dist/
```

O Nginx automaticamente serve os arquivos de `dist/` quando existem.

## ⚠️ Notas Importantes

1. **Não commite `node_modules/`** - Adicione ao `.gitignore`
2. **Não commite `dist/`** - O build é gerado automaticamente no servidor
3. **`.env` local** - Se usar variáveis de ambiente, configure no servidor
4. **Base Href** - Para Angular, certifique-se de que o `baseHref` está correto no `angular.json`:

```json
{
  "projects": {
    "seu-projeto": {
      "architect": {
        "build": {
          "options": {
            "baseHref": "/",
            "outputPath": "dist"
          }
        }
      }
    }
  }
}
```

## 🧪 Testar Localmente

```bash
# Fazer build manualmente
cd institucional
npm install
npm run build

# Verificar se dist/ foi criado
ls -la dist/
```

## 📚 Documentação Adicional

- Deploy automático: Veja `../DEPLOY-AUTOMATICO.md`
- Webhook handler: Veja `../webhook-handler/README.md`
