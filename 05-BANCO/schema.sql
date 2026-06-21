-- 05-BANCO/schema.sql
-- Remove tabelas anteriores em ordem de dependência para recriar o esquema limpo
DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS customer_memory CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS prompts CASCADE;
DROP TABLE IF EXISTS knowledge_base CASCADE;
DROP TABLE IF EXISTS contacts CASCADE;
DROP TABLE IF EXISTS companies CASCADE;

-- Função genérica para atualização automática da coluna 'updated_at'
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 1. Tabela de Empresas (Companies/Tenants)
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome_empresa VARCHAR(255) NOT NULL,
    segmento VARCHAR(100),
    whatsapp VARCHAR(20),
    plano VARCHAR(50) DEFAULT 'start' CHECK (plano IN ('start', 'pro', 'elite')),
    status VARCHAR(50) DEFAULT 'ativo' CHECK (status IN ('ativo', 'inativo', 'suspenso')),
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_companies_updated_at 
    BEFORE UPDATE ON companies 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2. Tabela de Contatos (CRM/Leads)
CREATE TABLE contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    nome VARCHAR(255),
    telefone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    cidade VARCHAR(100),
    origem VARCHAR(100),
    primeira_entrada TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ultimo_contato TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    estagio VARCHAR(50) DEFAULT 'lead' CHECK (estagio IN ('lead', 'qualificado', 'agendado', 'perdido')),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_contact_per_company UNIQUE (company_id, telefone),
    -- Garante uma restrição única composta para permitir a validação de FK nas tabelas filhas
    CONSTRAINT contacts_company_id_unique UNIQUE (company_id, id)
);

CREATE TRIGGER update_contacts_updated_at 
    BEFORE UPDATE ON contacts 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 3. Tabela de Histórico de Mensagens
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    contact_id UUID NOT NULL,
    mensagem TEXT NOT NULL,
    origem VARCHAR(50) NOT NULL CHECK (origem IN ('cliente', 'ia', 'humano')),
    data_hora TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Chave estrangeira composta crítica para evitar vazamento de dados entre tenants
    CONSTRAINT messages_company_contact_fkey 
        FOREIGN KEY (company_id, contact_id) 
        REFERENCES contacts(company_id, id) 
        ON DELETE CASCADE
);

-- 4. Tabela de Memória do Cliente (Dados extraídos sobre o Lead)
CREATE TABLE customer_memory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contact_id UUID NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
    tipo VARCHAR(100) NOT NULL CHECK (tipo IN ('perfil', 'interesse', 'objecao', 'dados_faturamento')),
    informacao TEXT NOT NULL,
    importancia INTEGER DEFAULT 1 CHECK (importancia BETWEEN 1 AND 5),
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_customer_memory_updated_at 
    BEFORE UPDATE ON customer_memory 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. Tabela de Sessões de Conversa
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contact_id UUID NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
    inicio TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fim TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) DEFAULT 'aberto' CHECK (status IN ('aberto', 'qualificacao', 'agendado', 'encerrado')),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_sessions_updated_at 
    BEFORE UPDATE ON sessions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 6. Tabela de Agendamentos (com proteção contra choque de horários do consultor)
CREATE TABLE appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contact_id UUID NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
    data DATE NOT NULL,
    hora TIME NOT NULL,
    consultor VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'agendado' CHECK (status IN ('agendado', 'realizado', 'cancelado', 'no-show')),
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Impede choque de agenda: mesmo consultor no mesmo dia e hora
    CONSTRAINT unique_appointment_time UNIQUE (consultor, data, hora)
);

CREATE TRIGGER update_appointments_updated_at 
    BEFORE UPDATE ON appointments 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. Tabela de Prompts da IA
CREATE TABLE prompts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    nome VARCHAR(100) NOT NULL,
    prompt_sistema TEXT NOT NULL,
    versao INTEGER DEFAULT 1 CHECK (versao >= 1),
    data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_prompts_updated_at 
    BEFORE UPDATE ON prompts 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 8. Tabela de Base de Conhecimento (FAQ)
CREATE TABLE knowledge_base (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    pergunta TEXT NOT NULL,
    resposta TEXT NOT NULL,
    categoria VARCHAR(100),
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_knowledge_base_updated_at 
    BEFORE UPDATE ON knowledge_base 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Índices recomendados para velocidade e indexação
CREATE INDEX IF NOT EXISTS idx_contacts_company ON contacts(company_id);
CREATE INDEX IF NOT EXISTS idx_contacts_phone ON contacts(telefone);
CREATE INDEX IF NOT EXISTS idx_messages_contact ON messages(contact_id);
CREATE INDEX IF NOT EXISTS idx_messages_company ON messages(company_id);
CREATE INDEX IF NOT EXISTS idx_memory_contact ON customer_memory(contact_id);
CREATE INDEX IF NOT EXISTS idx_sessions_contact ON sessions(contact_id);
CREATE INDEX IF NOT EXISTS idx_appointments_contact ON appointments(contact_id);
CREATE INDEX IF NOT EXISTS idx_prompts_company ON prompts(company_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_company ON knowledge_base(company_id);
