#!/bin/bash
# Script de Backup Automático da Infraestrutura e Banco de Dados
# Caminho sugerido no servidor: /opt/scripts/backup-server.sh

# Cores para saída formatada
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sem cor

BACKUP_DIR="/opt/backups"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

echo -e "${YELLOW}=== Iniciando Processo de Backup (Sprint 01) ===${NC}"

# 1. Criar diretório de backups se não existir
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "Criando diretório de backups em $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR"
fi

# 2. Backup das configurações e compose files (/opt/)
echo -e "Compactando arquivos de configuração do Docker (/opt/)..."
tar --exclude="$BACKUP_DIR" -czf "$BACKUP_DIR/infra_configs_$TIMESTAMP.tar.gz" \
    /opt/nginx-proxy-manager \
    /opt/portainer \
    /opt/postgresql \
    2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[OK] Configurações salvas em: $BACKUP_DIR/infra_configs_$TIMESTAMP.tar.gz${NC}"
else
    echo -e "${RED}[ERRO] Falha ao compactar arquivos de configuração.${NC}"
fi

# 3. Backup do banco de dados (pg_dump)
echo -e "Gerando Dump do Banco de Dados PostgreSQL (saas_whatsapp)..."
if docker ps | grep -q postgres; then
    # Executa o pg_dump de dentro do container
    docker exec -t postgres pg_dump -U saas_admin -d saas_whatsapp > "$BACKUP_DIR/database_dump_$TIMESTAMP.sql" 2>/dev/null
    
    if [ $? -eq 0 ] && [ -s "$BACKUP_DIR/database_dump_$TIMESTAMP.sql" ]; then
        echo -e "${GREEN}[OK] Banco de dados salvo em: $BACKUP_DIR/database_dump_$TIMESTAMP.sql${NC}"
    else
        echo -e "${RED}[ERRO] Falha ao gerar o Dump do banco de dados (banco vazio ou senha incorreta).${NC}"
    fi
else
    echo -e "${YELLOW}[AVISO] Container 'postgres' não está rodando. Pulando backup de dados.${NC}"
fi

echo -e "${YELLOW}=== Processo de Backup Concluído com Sucesso! ===${NC}"
echo -e "Arquivos disponíveis em: ${GREEN}$BACKUP_DIR${NC}"
ls -lh "$BACKUP_DIR" | grep "$TIMESTAMP"
