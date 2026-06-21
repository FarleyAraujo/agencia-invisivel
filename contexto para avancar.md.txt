Resumo de Contexto — Plataforma SaaS Multiempresa IA (Sprint 01)
Este documento resume o estado atual do projeto para servir de contexto em novas sessões de desenvolvimento.

1. Escopo & Arquitetura Geral do SaaS
Objetivo: Plataforma multiempresa de atendimento via WhatsApp integrado a IAs (Claude/OpenAI), com controle de memória, banco de dados isolado/estruturado e CRM.
Fluxo de Dados: Cliente ⇆ WhatsApp ⇆ Evolution API ⇆ n8n ⇆ PostgreSQL / Memória / Prompt / IA ⇆ CRM
Modelo de Implantação: Todo o ecossistema principal rodará em containers Docker dentro de uma VPS única (inicialmente para 3-4 clientes).
2. Decisões de Infraestrutura (Sprint 01)
Provedor VPS: Contabo (Plano Cloud VPS 10 — 8GB RAM, 4 vCPU Cores, 75GB NVMe, Ubuntu 24.04).
Custo do Servidor: 4.32/m 
e
^
 s( R 25,00/mês).
Domínio: Registro.br (.com.br).
Servidor de DNS: Cloudflare (Plano Grátis, Proxy desativado temporariamente para validação do SSL).
Proxy Reverso & SSL: Nginx Proxy Manager (NPM).
Gerenciador de Containers: Portainer.
Banco de Dados: PostgreSQL 16 local (container Docker na rede interna).
Senha Root Provisória do Servidor: Js3N7FTQXLX5uwyvJyN8rlo3 (será alterada após o primeiro acesso por segurança).
3. Estrutura de Arquivos Criada Localmente
A estrutura de infraestrutura inicial foi gerada no diretório 
06-INFRA
:

.env.example
: Variáveis de ambiente padrão para o PostgreSQL e configurações.
docker-compose.yml (NPM)
: Orquestração do Nginx Proxy Manager nas portas 80, 443 e 81.
docker-compose.yml (Portainer)
: Painel administrativo (acesso apenas via rede interna e proxy).
docker-compose.yml (PostgreSQL)
: Banco de dados rodando na rede interna proxy.
setup-server.sh
: Script Bash para execução automática pós-SSH (atualização, firewall UFW, instalação do Docker, criação da rede docker proxy e pastas /opt/).
GUIA-PASSO-A-PASSO.md
: Manual com todos os comandos para contratação, configuração de DNS, subida de containers e provisionamento de SSL.
4. Estado Atual e Próximos Passos
Status: Em andamento (Sprint 01).
Bloqueio Atual: Aguardando o provisionamento e liberação da VPS por parte da Contabo (pode levar de 30 minutos a 3 horas).
Ações Imediatas quando a VPS liberar:
Coletar o IP público da VPS enviado pela Contabo.
No painel da Cloudflare, criar registros tipo A para npm e portainer apontando para o IP da VPS (com Proxy em cinza/desativado).
Conectar na VPS via SSH usando a senha root salva.
Executar o script setup-server.sh.
Enviar os arquivos docker-compose da pasta local para a VPS e iniciar os containers.
Configurar o SSL no painel do Nginx Proxy Manager.