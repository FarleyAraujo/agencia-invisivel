# Sprint 01 — Guia Passo a Passo

> **Pré-requisito**: ter a VPS Contabo contratada, domínio registrado no Registro.br, e DNS no Cloudflare.

---

## FASE 1 — Antes de tocar no servidor

### 1.1 — Contratar a VPS na Contabo

```
1. Acesse: https://contabo.com/en/vps/
2. Escolha: VPS S (8GB RAM, 4 vCPUs, 200GB SSD)
3. Sistema: Ubuntu 24.04
4. Localização: São Paulo (ou USA East)
5. Finalize a compra
6. Aguarde o email com IP e senha root
```

**ANOTE:**
- IP do servidor: _______________
- Senha root: _______________

### 1.2 — Registrar domínio no Registro.br

```
1. Acesse: https://registro.br
2. Busque o domínio desejado (ex: suaempresa.com.br)
3. Registre e pague
```

### 1.3 — Configurar Cloudflare DNS

```
1. Acesse: https://dash.cloudflare.com
2. Crie conta (grátis)
3. Clique em "Add a Site" → digite seu domínio
4. Escolha plano FREE
5. O Cloudflare vai pedir para trocar os nameservers no Registro.br
6. Vá no Registro.br → seu domínio → altere os DNS para os que o Cloudflare indicou
7. Aguarde até 24h para propagar (geralmente 15-60 min)
```

Depois, crie os registros DNS no Cloudflare:

```
Tipo: A  |  Nome: npm        |  Valor: [IP_DO_SERVIDOR]  |  Proxy: OFF (nuvem cinza)
Tipo: A  |  Nome: portainer  |  Valor: [IP_DO_SERVIDOR]  |  Proxy: OFF (nuvem cinza)
```

> ⚠️ **IMPORTANTE**: Deixe o Proxy DESLIGADO (nuvem cinza) por enquanto. Se ligar, o SSL do Nginx Proxy Manager não consegue gerar o certificado.

---

## FASE 2 — Configurar o servidor

### 2.1 — Conectar via SSH

No seu computador (PowerShell ou Terminal):

```powershell
ssh root@SEU_IP_AQUI
```

Primeira vez? Digite `yes` quando perguntar. Depois cole a senha.

### 2.2 — Rodar o script de setup

Copie o conteúdo do arquivo `scripts/setup-server.sh` e cole no terminal do servidor.

Ou, se preferir enviar o arquivo:

```powershell
# No seu computador (PowerShell), envie o script para o servidor:
scp c:\AGENCIA-IA\06-INFRA\scripts\setup-server.sh root@SEU_IP_AQUI:/root/

# Depois, no servidor (SSH):
chmod +x /root/setup-server.sh
./root/setup-server.sh
```

O script vai:
- ✅ Atualizar o sistema
- ✅ Criar usuário `deploy`
- ✅ Configurar firewall
- ✅ Instalar Docker + Docker Compose
- ✅ Criar rede Docker `proxy`
- ✅ Criar pastas dos serviços

---

## FASE 3 — Subir os containers

### 3.1 — Copiar os docker-compose para o servidor

No seu computador (PowerShell):

```powershell
# Copia o docker-compose do Nginx Proxy Manager
scp c:\AGENCIA-IA\06-INFRA\docker-compose\nginx-proxy-manager\docker-compose.yml root@SEU_IP_AQUI:/opt/nginx-proxy-manager/

# Copia o docker-compose do Portainer
scp c:\AGENCIA-IA\06-INFRA\docker-compose\portainer\docker-compose.yml root@SEU_IP_AQUI:/opt/portainer/

# Copia o docker-compose do PostgreSQL
scp c:\AGENCIA-IA\06-INFRA\docker-compose\postgresql\docker-compose.yml root@SEU_IP_AQUI:/opt/postgresql/

# Copia o arquivo de variáveis de ambiente para o PostgreSQL
scp c:\AGENCIA-IA\06-INFRA\.env.example root@SEU_IP_AQUI:/opt/postgresql/.env
```

> ⚠️ Depois de copiar o `.env`, acesse o servidor e edite a senha:
> ```bash
> nano /opt/postgresql/.env
> ```
> Troque `TROQUE_POR_UMA_SENHA_FORTE_AQUI` por uma senha real. Salve: `Ctrl+X`, `Y`, `Enter`.

### 3.2 — Subir Nginx Proxy Manager (1º)

```bash
cd /opt/nginx-proxy-manager
docker compose up -d
```

Verificar:
```bash
docker ps | grep nginx
# Deve mostrar o container "nginx-proxy-manager" com status "Up"
```

### 3.3 — Subir Portainer (2º)

```bash
cd /opt/portainer
docker compose up -d
```

Verificar:
```bash
docker ps | grep portainer
# Deve mostrar o container "portainer" com status "Up"
```

### 3.4 — Subir PostgreSQL (3º)

```bash
cd /opt/postgresql
docker compose up -d
```

Verificar:
```bash
docker ps | grep postgres
# Deve mostrar o container "postgres" com status "Up"
```

### 3.5 — Verificar tudo rodando

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

Deve mostrar:
```
NAMES                  STATUS          PORTS
nginx-proxy-manager    Up X minutes    0.0.0.0:80->80, 0.0.0.0:81->81, 0.0.0.0:443->443
portainer              Up X minutes    8000/tcp, 9000/tcp, 9443/tcp
postgres               Up X minutes    5432/tcp
```

---

## FASE 4 — Configurar acessos

### 4.1 — Acessar o Nginx Proxy Manager

```
1. Abra o navegador
2. Acesse: http://SEU_IP_AQUI:81
3. Login inicial:
   Email: admin@example.com
   Senha: changeme
4. Vai pedir para trocar o email e senha — TROQUE AGORA
```

### 4.2 — Criar proxy para o Portainer no NPM

```
1. No NPM, vá em "Proxy Hosts" → "Add Proxy Host"
2. Preencha:
   Domain Names: portainer.seudominio.com.br
   Scheme: http
   Forward Hostname: portainer
   Forward Port: 9000
3. Aba "SSL":
   SSL Certificate: Request a new SSL Certificate
   ✅ Force SSL
   ✅ HTTP/2 Support
   Email: seu email
   ✅ I Agree to the Terms
4. Clique "Save"
```

### 4.3 — Criar proxy para o próprio NPM

```
1. No NPM, vá em "Proxy Hosts" → "Add Proxy Host"
2. Preencha:
   Domain Names: npm.seudominio.com.br
   Scheme: http
   Forward Hostname: nginx-proxy-manager
   Forward Port: 81
3. Aba "SSL":
   SSL Certificate: Request a new SSL Certificate
   ✅ Force SSL
   ✅ HTTP/2 Support
   Email: seu email
   ✅ I Agree to the Terms
4. Clique "Save"
```

### 4.4 — Acessar o Portainer

```
1. Abra o navegador
2. Acesse: https://portainer.seudominio.com.br
3. Crie uma senha de admin (mínimo 12 caracteres)
4. Selecione "Get Started"
5. Clique em "local" → pronto!
```

### 4.5 — Fechar porta 81 do firewall

Agora que o NPM está acessível via `npm.seudominio.com.br`, feche a porta 81:

```bash
ufw delete allow 81/tcp
ufw status
```

---

## FASE 5 — Verificação Final

### Checklist

| # | Verificação | Como testar | ✅ |
|---|-------------|-------------|---|
| 1 | Docker rodando | `docker ps` mostra 3 containers | ☐ |
| 2 | NPM acessível | `https://npm.seudominio.com.br` abre no navegador | ☐ |
| 3 | Portainer acessível | `https://portainer.seudominio.com.br` abre no navegador | ☐ |
| 4 | SSL funcionando | Cadeado verde nos dois subdomínios | ☐ |
| 5 | PostgreSQL rodando | `docker logs postgres` sem erros | ☐ |
| 6 | Firewall ativo | `ufw status` mostra apenas 22, 80, 443 | ☐ |

### Testar conexão do PostgreSQL (dentro do servidor)

```bash
docker exec -it postgres psql -U saas_admin -d saas_whatsapp -c "SELECT 'Banco funcionando!' AS status;"
```

Deve retornar:
```
       status
--------------------
 Banco funcionando!
```

---

## 🚨 Resolução de Problemas

### "Não consigo acessar o NPM na porta 81"
```bash
# Verifique se o container está rodando
docker ps | grep nginx

# Veja os logs
docker logs nginx-proxy-manager

# Verifique se a porta está aberta no firewall
ufw status | grep 81
```

### "SSL não gera certificado"
```
1. Verifique se o DNS propagou: https://dnschecker.org
2. Certifique-se que o Proxy do Cloudflare está OFF (nuvem cinza)
3. Verifique se as portas 80 e 443 estão abertas no firewall
```

### "PostgreSQL não conecta"
```bash
# Verifique se o .env está correto
cat /opt/postgresql/.env

# Veja os logs
docker logs postgres

# Recrie o container
cd /opt/postgresql
docker compose down
docker compose up -d
```

---

## ✅ Sprint 01 Concluído!

Quando todos os 6 itens do checklist estiverem marcados, o Sprint 01 está **COMPLETO**.

**Próximo Sprint**: Sprint 02 — Banco de Dados (estrutura de tabelas multiempresa)
