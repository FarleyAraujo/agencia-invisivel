-- 05-BANCO/schema.sql
-- Habilita a extensão para geração de UUID se não estiver ativa
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Tabela de Empresas (Companies/Tenants)
CREATE TABLE IF NOT EXISTS companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome_empresa VARCHAR(255) NOT NULL,
    segmento VARCHAR(100),
    whatsapp VARCHAR(20),
    plano VARCHAR(50),
    status VARCHAR(50) DEFAULT 'ativo',
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabela de Contatos (CRM/Leads)
CREATE TABLE IF NOT EXISTS contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    nome VARCHAR(255),
    telefone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    cidade VARCHAR(100),
    origem VARCHAR(100), -- Ex: 'anuncio_meta', 'organico', 'indicacao'
    primeira_entrada TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ultimo_contato TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    estagio VARCHAR(50) DEFAULT 'lead', -- Ex: 'lead', 'qualificado', 'agendado', 'perdido'
    
    -- Um contato é único por telefone dentro da mesma empresa
    CONSTRAINT unique_contact_per_company UNIQUE (company_id, telefone)
);

-- 3. Tabela de Histórico de Mensagens
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    contact_id UUID NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
    mensagem TEXT NOT NULL,
    origem VARCHAR(50) NOT NULL, -- Ex: 'cliente' (recebida), 'ia' (enviada), 'humano' (enviada manual)
    data_hora TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabela de Memória do Cliente (Dados extraídos sobre o Lead)
CREATE TABLE IF NOT EXISTS customer_memory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contact_id UUID NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
    tipo VARCHAR(100) NOT NULL, -- Ex: 'perfil', 'interesse', 'objecao', 'dados_faturamento'
    informacao TEXT NOT NULL,
    importancia INTEGER DEFAULT 1, -- Nível de relevância (1 a 5)
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Tabela de Sessões de Conversa (Atendimento ativo)
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contact_id UUID NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
    inicio TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fim TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) DEFAULT 'aberto' -- Ex: 'aberto', 'qualificação', 'agendado', 'encerrado'
);

-- 6. Tabela de Agendamentos
CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contact_id UUID NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
    data DATE NOT NULL,
    hora TIME NOT NULL,
    consultor VARCHAR(255),
    status VARCHAR(50) DEFAULT 'agendado', -- Ex: 'agendado', 'realizado', 'cancelado', 'no-show'
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Tabela de Prompts e Personalidades da IA
CREATE TABLE IF NOT EXISTS prompts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    nome VARCHAR(100) NOT NULL, -- Ex: 'SDR Vendas', 'FAQ Suporte'
    prompt_sistema TEXT NOT NULL,
    versao INTEGER DEFAULT 1,
    data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 8. Tabela de Base de Conhecimento (FAQs locais das empresas)
CREATE TABLE IF NOT EXISTS knowledge_base (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    pergunta TEXT NOT NULL,
    resposta TEXT NOT NULL,
    categoria VARCHAR(100),
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices recomendados para otimização de consultas e velocidade de leitura
CREATE INDEX IF NOT EXISTS idx_contacts_company ON contacts(company_id);
CREATE INDEX IF NOT EXISTS idx_contacts_phone ON contacts(telefone);
CREATE INDEX IF NOT EXISTS idx_messages_contact ON messages(contact_id);
CREATE INDEX IF NOT EXISTS idx_messages_company ON messages(company_id);
CREATE INDEX IF NOT EXISTS idx_memory_contact ON customer_memory(contact_id);
CREATE INDEX IF NOT EXISTS idx_sessions_contact ON sessions(contact_id);
CREATE INDEX IF NOT EXISTS idx_appointments_contact ON appointments(contact_id);
CREATE INDEX IF NOT EXISTS idx_prompts_company ON prompts(company_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_company ON knowledge_base(company_id);
