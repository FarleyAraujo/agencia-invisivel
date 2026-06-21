# 🚀 PROJETO: AGÊNCIA IA DE ATENDIMENTO INVISÍVEL
### Documento de Visão Geral, Arquitetura e Estratégia de Negócios (SaaS Multiempresa)

Este documento serve como a **Bíblia do Projeto** para o fundador. Ele traduz a infraestrutura técnica para o valor de negócios, descreve as ferramentas, detalha todas as etapas do desenvolvimento e fornece as estratégias comerciais para venda aos clientes finais.

---

## 📌 1. Visão de Negócios & Abordagem Comercial

### O Posicionamento Estratégico
Você **não** vende um "chatbot" ou um "fluxo automático". Chatbots tradicionais irritam clientes e parecem robóticos.
Você vende uma **"Equipe Invisível de Atendimento de IA que trabalha 24h por dia, qualifica seus leads e agenda reuniões diretamente para o seu time de vendas"**.

#### Como abordar o cliente final (Sells Pitch por Segmento):

| Segmento | A Dor do Cliente | Sua Proposta de Valor (O Pitch) |
| :--- | :--- | :--- |
| **Clínicas / Consultórios** | Demora para responder agendamentos fora do horário comercial, perdendo pacientes. | *"Sua clínica vai responder e agendar consultas em 30 segundos, mesmo às 3 horas da manhã de um domingo, com a mesma simpatia da sua melhor secretária."* |
| **Energia Solar** | Leads caros de anúncios Meta esfriam por demora no primeiro contato e falta de qualificação. | *"Sua equipe de vendas só vai receber no WhatsApp contatos prontos, qualificados (que têm casa própria, faturamento de luz acima de R$ 500 e que moram na região certa)."* |
| **Imobiliárias** | Corretores demoram a responder sobre imóveis, perdendo o momento de interesse (timing) do lead. | *"Uma IA que conhece todo o seu catálogo de imóveis, tira dúvidas imediatas sobre localização e vagas, e agenda a visita direto na agenda do corretor."* |
| **Oficinas / Serviços** | Dono ocupado no operacional não consegue atender orçamentos no WhatsApp a tempo. | *"Uma IA que faz a triagem do problema do veículo, coleta marca/modelo e agenda o horário de diagnóstico sem que você precise parar o trabalho na oficina."* |

### Modelo de Cobrança (SaaS High-Ticket)
*   **Taxa de Implantação (Setup):** R$ 2.000 a R$ 15.000+ (cobrado uma única vez para mapear a base de conhecimento do cliente, treinar a IA, criar os prompts e testar).
*   **Recorrência Mensal (Mensalidade):** R$ 500 a R$ 3.000+ (para cobrir custos de infraestrutura, APIs de IA e suporte continuado/atualização de prompts).

---

## 🧱 2. A Stack de Ferramentas (Por que escolhemos cada uma?)

Para criar um sistema altamente escalável e de **baixíssimo custo fixo**, estruturamos o projeto em containers Docker em um servidor próprio (Contabo).

```
┌─────────────────────────────────────────────────────────────┐
│                    SUA VPS (CONTABO)                        │
│                                                             │
│  ┌──────────────────────┐        ┌───────────────────────┐  │
│  │ Nginx Proxy Manager  │ ◄────► │       Portainer       │  │
│  │ (Segurança / SSL)    │        │ (Gerência Visual UI)  │  │
│  └──────────┬───────────┘        └───────────────────────┘  │
│             │                                               │
│             ▼                                               │
│  ┌──────────────────────┐        ┌───────────────────────┐  │
│  │    Evolution API     │ ◄────► │          n8n          │  │
│  │ (Conexão WhatsApp)   │        │ (Cérebro/Automações)  │  │
│  └──────────┬───────────┘        └───────────┬───────────┘  │
│             │                                │              │
│             └───────────────┬────────────────┘              │
│                             ▼                               │
│                  ┌──────────────────────┐                   │
│                  │  PostgreSQL (Local)  │                   │
│                  │  (Banco de Dados)    │                   │
│                  └──────────────────────┘                   │
└─────────────────────────────┬───────────────────────────────┘
                              │
               ┌──────────────┴──────────────┐
               ▼                             ▼
         ┌───────────┐                 ┌───────────┐
         │ Claude IA │                 │ Langfuse  │
         │ (Cérebro) │                 │ (Métricas)│
         └───────────┘                 └───────────┘
```

1.  **Ubuntu Server (VPS Contabo):** Nosso "computador na nuvem". Escolhemos a Contabo pelo custo-benefício incrível (4 vCPUs, 8GB RAM por ~R$ 30/mês).
2.  **Docker & Portainer:** Docker isola cada programa em uma "caixa" (container) para que um serviço não quebre o outro. O Portainer é o painel visual para você gerenciar essas caixas pelo navegador sem precisar digitar códigos.
3.  **Nginx Proxy Manager (NPM):** O porteiro do servidor. Ele recebe o tráfego da internet, garante a segurança com o cadeado verde (SSL/HTTPS Let's Encrypt) e direciona para o painel correto.
4.  **PostgreSQL 16:** O coração dos dados. Ele armazena as informações das empresas clientes, o histórico de conversas dos contatos, as memórias que a IA aprende sobre cada lead e os agendamentos.
5.  **Evolution API (WhatsApp):** API de código aberto que emula o WhatsApp Web. Permite conectar múltiplos celulares via QR Code em uma única instalação, economizando milhares de reais que seriam pagos à API Oficial (Meta).
6.  **n8n (Workflow Automation):** O cérebro da integração. É nele que desenhamos visualmente os fluxos: "Lead mandou mensagem -> Busca no Postgres se ele já existe -> Pergunta ao Claude o que responder -> Envia resposta via Evolution API -> Atualiza o estágio no CRM".
7.  **Claude (Anthropic API) & OpenAI API:** As inteligências artificiais que decidem as respostas de forma natural e humanizada.
8.  **Langfuse (LLM Ops):** Sistema de monitoramento. Registra o custo exato de cada resposta de IA, o tempo de resposta e se a IA cometeu erros, permitindo auditoria detalhada de cada interação.

---

## 🗄️ 3. Estrutura do Banco de Dados (Sprint 02)

Estruturado de forma **Multiempresa (Multi-tenant)**. Todas as tabelas têm chaves estrangeiras que as ligam às respectivas empresas utilizando identificadores únicos universais (`UUID`), garantindo privacidade total para seus clientes.

*   **`companies` (Empresas):** Registra cada cliente da sua agência (ex: Eco Fonte, Clínica Sorriso, etc.).
*   **`contacts` (Contatos/CRM):** Guarda a agenda de leads de cada empresa. Evita a duplicação e armazena o estágio do funil (Lead, Qualificado, Agendado, Perdido).
*   **`messages` (Mensagens):** O histórico completo de chat (quem enviou, o texto e quando). Crucial para a IA ler o passado recente antes de responder.
*   **`customer_memory` (Memória do Cliente):** Fatos cruciais aprendidos pela IA sobre o contato de forma dinâmica (ex: *"Mora em imóvel alugado"*, *"Tem dor no dente do siso"*, *"Faturamento R$ 10.000"*).
*   **`sessions` (Sessões):** Controla o tempo de conversa ativa de um atendimento.
*   **`appointments` (Agendamentos):** Controla as datas, horas e consultores definidos para as reuniões agendadas pela IA.
*   **`prompts` (Personalidades):** Guarda as diretrizes de comportamento de cada robô de atendimento (Tom de voz, regras de negócio e objetivos).
*   **`knowledge_base` (FAQ):** A base de dados estruturada que a IA consulta para tirar dúvidas sobre a empresa (preços, serviços, políticas, etc.).

---

## 🗺️ 4. O Roadmap de Desenvolvimento (Sprint por Sprint)

Dividimos o projeto em 8 sprints focados, garantindo validação em cada etapa:

### 🎯 Sprint 01: Infraestrutura Base (Status: Concluído)
*   **Foco:** VPS, Domínio, DNS Cloudflare, Docker, Portainer, PostgreSQL e Proxy Reverso NPM.
*   **O que foi entregue:** Toda a base de servidores ativa e segura na Contabo, painéis Portainer e NPM acessíveis locais, banco de dados testado.

### 🎯 Sprint 02: Banco de Dados Multiempresa (Status: Concluído)
*   **Foco:** Criação de tabelas, índices de busca rápidos, banco estruturado baseado no PRD e script de backup automatizado da VPS.
*   **O que foi entregue:** Arquivos `schema.sql` e `seeds.sql` criados e rodando perfeitamente dentro do container PostgreSQL. Validação de relacionamentos funcionando. Backup do servidor gerado.

### 🎯 Sprint 03: Integração do WhatsApp (Evolution API) (A Seguir)
*   **Foco:** Instalação da Evolution API no servidor para conexões múltiplas do WhatsApp.
*   **Próximos Passos:** Subir o container da API, apontar subdomínio `api.mysage.com.br`, configurar segurança, conectar celulares via QR Code e fazer envios e recebimentos de testes de mensagens via Postman ou cURL.

### 🎯 Sprint 04: Motor de Automação (n8n)
*   **Foco:** Subir o n8n e integrá-lo com a rede local e banco de dados.
*   **O que faremos:** Instalação do n8n na VPS, configuração do subdomínio `n8n.mysage.com.br` no NPM com SSL, criação do primeiro fluxo de recebimento de webhook (quando chega mensagem no WhatsApp, o n8n recebe o aviso).

### 🎯 Sprint 05: Integração com Inteligência Artificial (Claude/OpenAI)
*   **Foco:** Fazer a IA responder mensagens simples recebidas no n8n.
*   **O que faremos:** Integração das chaves de API da Anthropic e OpenAI, busca do prompt correto da empresa no banco de dados, envio do contexto básico para a IA e retorno da mensagem gerada direto no celular do cliente via Evolution API.

### 🎯 Sprint 06: Memória e Contexto de Conversa
*   **Foco:** Ensinar a IA a lembrar do histórico e extrair fatos de forma dinâmica.
*   **O que faremos:** O n8n buscará as últimas 10 mensagens do banco de dados para alimentar a IA (evitando que ela esqueça o assunto), criaremos um fluxo secundário de IA que analisa a conversa e salva fatos importantes na tabela `customer_memory` de forma invisível.

### 🎯 Sprint 07: CRM e Lógica de Negócio (Qualificação & Agendamento)
*   **Foco:** Conectar o funil de vendas à IA.
*   **O que faremos:** A IA tentará obter as 3 perguntas cruciais de qualificação (segmento solar: valor da conta, cidade, se o imóvel é próprio). Ao qualificar, a IA puxará os horários disponíveis e agendará uma chamada, criando a linha na tabela `appointments` e enviando um alerta ao vendedor humano.

### 🎯 Sprint 08: Observabilidade e Auditoria (Langfuse)
*   **Foco:** Monitorar custos, latência e comportamento da IA.
*   **O que faremos:** Instalar o Langfuse na VPS, criar o subdomínio `langfuse.mysage.com.br`, integrar com as chamadas de IA do n8n, monitorar os custos de tokens e criar alertas automáticos em caso de respostas lentas ou erradas.

---

## 🛠️ 5. Práticas de Segurança e Continuidade (Como não perder o trabalho?)

A segurança do projeto está estruturada em três camadas:

1.  **Controle de Versão com Git (Código):** Todo o código que escrevemos no seu computador (composes, scripts, rotas SQL) é versionado usando Git e enviado com segurança para a sua conta privada no GitHub.
2.  **Backup da VPS (`/opt/backups`):** A VPS possui o script `backup-server.sh` que compacta e gera uma cópia idêntica de todas as pastas de configurações em `/opt/`. Se você precisar migrar de servidor ou se a Contabo travar, basta extrair esse arquivo de backup em outro servidor Ubuntu e rodar `docker compose up -d` para restaurar o sistema em 5 minutos.
3.  **Dumps de Banco de Dados:** O mesmo script de backup gera arquivos `.sql` automáticos, exportando todos os dados cadastrados no Postgres para fora do container.

---

Este projeto foi desenhado sob medida para o seu perfil: **foco total em negócios, escala e conversão de vendas**, enquanto eu cuido da sustentação técnica e arquitetura de forma modular, segura e profissional.
