#!/bin/bash
# ============================================================
# SCRIPT DE SETUP — Sprint 01 — Infraestrutura Base
# ============================================================
# COMO USAR:
#   1. Conecte ao servidor via SSH
#   2. Cole este script inteiro no terminal
#   3. Ou salve como arquivo e execute:
#      chmod +x setup-server.sh
#      ./setup-server.sh
# ============================================================

set -e  # Para imediatamente se qualquer comando falhar

echo ""
echo "========================================="
echo "  SPRINT 01 — SETUP DA INFRAESTRUTURA"
echo "========================================="
echo ""

# ----------------------------------------------------------
# PASSO 1: Atualizar o sistema
# ----------------------------------------------------------
echo "[1/7] Atualizando o sistema..."
apt update && apt upgrade -y
echo "✅ Sistema atualizado."
echo ""

# ----------------------------------------------------------
# PASSO 2: Criar usuário deploy
# ----------------------------------------------------------
echo "[2/7] Criando usuário 'deploy'..."
if id "deploy" &>/dev/null; then
    echo "⚠️  Usuário 'deploy' já existe. Pulando."
else
    adduser --gecos "" deploy
    usermod -aG sudo deploy
    echo "✅ Usuário 'deploy' criado com permissão sudo."
fi
echo ""

# ----------------------------------------------------------
# PASSO 3: Configurar Firewall (UFW)
# ----------------------------------------------------------
echo "[3/7] Configurando Firewall..."
apt install -y ufw
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP (necessário para SSL)
ufw allow 443/tcp   # HTTPS
ufw allow 81/tcp    # NPM Admin (temporário — fechar depois)
ufw --force enable
echo "✅ Firewall ativo. Portas abertas: 22, 80, 81, 443."
echo ""

# ----------------------------------------------------------
# PASSO 4: Instalar Docker
# ----------------------------------------------------------
echo "[4/7] Instalando Docker..."
if command -v docker &>/dev/null; then
    echo "⚠️  Docker já instalado. Pulando."
else
    apt install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Permite o usuário deploy usar Docker sem sudo
    usermod -aG docker deploy

    echo "✅ Docker instalado."
fi
echo ""

# ----------------------------------------------------------
# PASSO 5: Criar rede Docker compartilhada
# ----------------------------------------------------------
echo "[5/7] Criando rede Docker 'proxy'..."
if docker network ls | grep -q "proxy"; then
    echo "⚠️  Rede 'proxy' já existe. Pulando."
else
    docker network create proxy
    echo "✅ Rede 'proxy' criada."
fi
echo ""

# ----------------------------------------------------------
# PASSO 6: Criar pastas dos serviços
# ----------------------------------------------------------
echo "[6/7] Criando estrutura de pastas..."
mkdir -p /opt/nginx-proxy-manager
mkdir -p /opt/portainer
mkdir -p /opt/postgresql
echo "✅ Pastas criadas em /opt/"
echo ""

# ----------------------------------------------------------
# PASSO 7: Resumo
# ----------------------------------------------------------
echo "[7/7] Verificação final..."
echo ""
echo "========================================="
echo "  ✅ SETUP CONCLUÍDO COM SUCESSO!"
echo "========================================="
echo ""
echo "Docker:    $(docker --version)"
echo "Compose:   $(docker compose version)"
echo "Firewall:  $(ufw status | head -1)"
echo "Rede:      $(docker network ls | grep proxy)"
echo ""
echo "========================================="
echo "  PRÓXIMO PASSO:"
echo "  Copie os docker-compose.yml para o"
echo "  servidor e suba os containers."
echo "  Veja o GUIA-PASSO-A-PASSO.md"
echo "========================================="
echo ""
