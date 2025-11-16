const express = require('express');
const crypto = require('crypto');
const { exec } = require('child_process');
const { promisify } = require('util');
const fs = require('fs');

const execAsync = promisify(exec);

const app = express();
const PORT = 3000;

// Middleware para parsear JSON
app.use(express.json());

// Função para verificar assinatura do GitHub
function verifyGitHubSignature(payload, signature, secret) {
    if (!signature || !secret) return false;
    
    const hmac = crypto.createHmac('sha256', secret);
    const digest = 'sha256=' + hmac.update(payload).digest('hex');
    
    return crypto.timingSafeEqual(
        Buffer.from(signature),
        Buffer.from(digest)
    );
}

// Função para verificar token simples (GitLab ou uso genérico)
function verifyToken(token, expectedToken) {
    return token === expectedToken;
}

// Executar script de deploy
async function runDeploy(script, args = []) {
    try {
        const command = `chmod +x ${script} && ${script} ${args.join(' ')}`;
        console.log(`Executando: ${command}`);
        
        const { stdout, stderr } = await execAsync(command, {
            cwd: '/workspace',
            maxBuffer: 10 * 1024 * 1024 // 10MB
        });
        
        if (stdout) console.log(stdout);
        if (stderr) console.error(stderr);
        
        return { success: true, output: stdout, error: stderr };
    } catch (error) {
        console.error(`Erro ao executar deploy: ${error.message}`);
        return { success: false, error: error.message };
    }
}

// Endpoint de health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', service: 'webhook-deploy-handler' });
});

// Endpoint para deploy de API Laravel
app.post('/deploy/api/:apiName', async (req, res) => {
    const { apiName } = req.params;
    const secret = process.env.WEBHOOK_SECRET;
    const token = req.headers['x-webhook-token'] || req.query.token;
    
    // Verificar autenticação
    if (secret && !token) {
        // GitHub webhook
        const signature = req.headers['x-hub-signature-256'];
        const payload = JSON.stringify(req.body);
        
        if (!verifyGitHubSignature(payload, signature, secret)) {
            return res.status(401).json({ error: 'Assinatura inválida' });
        }
    } else if (token && secret && !verifyToken(token, secret)) {
        return res.status(401).json({ error: 'Token inválido' });
    }
    
    const branch = req.body.ref ? req.body.ref.replace('refs/heads/', '') : req.body.branch || 'main';
    
    console.log(`Deploy solicitado para API: ${apiName}, branch: ${branch}`);
    
    const result = await runDeploy('scripts/deploy-api.sh', [apiName, branch]);
    
    if (result.success) {
        res.json({ 
            success: true, 
            message: `Deploy da API ${apiName} concluído`,
            branch 
        });
    } else {
        res.status(500).json({ 
            success: false, 
            error: result.error 
        });
    }
});

// Endpoint para deploy do site institucional
app.post('/deploy/institucional', async (req, res) => {
    const secret = process.env.WEBHOOK_SECRET;
    const token = req.headers['x-webhook-token'] || req.query.token;
    
    // Verificar autenticação
    if (secret && !token) {
        // GitHub webhook
        const signature = req.headers['x-hub-signature-256'];
        const payload = JSON.stringify(req.body);
        
        if (!verifyGitHubSignature(payload, signature, secret)) {
            return res.status(401).json({ error: 'Assinatura inválida' });
        }
    } else if (token && secret && !verifyToken(token, secret)) {
        return res.status(401).json({ error: 'Token inválido' });
    }
    
    const branch = req.body.ref ? req.body.ref.replace('refs/heads/', '') : req.body.branch || 'main';
    
    console.log(`Deploy solicitado para site institucional, branch: ${branch}`);
    
    const result = await runDeploy('scripts/deploy-institucional.sh', [branch]);
    
    if (result.success) {
        res.json({ 
            success: true, 
            message: 'Deploy do site institucional concluído',
            branch 
        });
    } else {
        res.status(500).json({ 
            success: false, 
            error: result.error 
        });
    }
});

// Endpoint genérico para GitHub webhooks
app.post('/webhook/github', express.raw({ type: 'application/json' }), async (req, res) => {
    const secret = process.env.WEBHOOK_SECRET;
    const signature = req.headers['x-hub-signature-256'];
    const event = req.headers['x-github-event'];
    
    if (!secret) {
        return res.status(500).json({ error: 'WEBHOOK_SECRET não configurado' });
    }
    
    // req.body é um Buffer para raw body
    const payload = req.body.toString();
    
    if (!verifyGitHubSignature(payload, signature, secret)) {
        return res.status(401).json({ error: 'Assinatura inválida' });
    }
    
    // Parse do JSON após verificar assinatura
    const body = JSON.parse(payload);
    
    // Processar apenas eventos de push
    if (event !== 'push') {
        return res.json({ message: 'Evento ignorado', event });
    }
    
    const repo = body.repository?.name || '';
    const branch = body.ref?.replace('refs/heads/', '') || 'main';
    const fullName = body.repository?.full_name || '';
    
    console.log(`GitHub webhook recebido: ${event} em ${fullName} (${branch})`);
    
    // Detectar se é API Laravel ou institucional
    if (repo.includes('institucional') || repo === 'institucional') {
        const result = await runDeploy('scripts/deploy-institucional.sh', [branch]);
        return res.json({ 
            success: result.success, 
            message: 'Deploy do site institucional',
            branch 
        });
    } else {
        // Tentar detectar nome da API do repositório
        // Você pode ajustar essa lógica conforme necessário
        const apiName = repo.replace(/[-_]?api[-_]?/i, '').toLowerCase();
        const result = await runDeploy('scripts/deploy-api.sh', [apiName, branch]);
        return res.json({ 
            success: result.success, 
            message: `Deploy da API ${apiName}`,
            branch 
        });
    }
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Webhook Deploy Handler rodando na porta ${PORT}`);
    console.log(`📝 Endpoints disponíveis:`);
    console.log(`   POST /deploy/api/:apiName`);
    console.log(`   POST /deploy/institucional`);
    console.log(`   POST /webhook/github`);
    console.log(`   GET  /health`);
});

