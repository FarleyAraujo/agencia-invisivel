-- 05-BANCO/seeds.sql
-- Limpa dados anteriores para permitir rodar o script várias vezes sem duplicar
TRUNCATE TABLE companies, contacts, messages, customer_memory, sessions, appointments, prompts, knowledge_base CASCADE;

-- 1. Inserir Empresa de Teste (Tenante Eco Fonte)
INSERT INTO companies (nome_empresa, segmento, whatsapp, plano, status)
VALUES ('Eco Fonte', 'Energia Solar', '+5511999999999', 'Pro', 'ativo');

-- 2. Inserir Prompt do Sistema para a Eco Fonte
INSERT INTO prompts (company_id, nome, prompt_sistema)
VALUES (
    (SELECT id FROM companies WHERE nome_empresa = 'Eco Fonte' LIMIT 1),
    'SDR Vendas',
    'Você é o atendente virtual da Eco Fonte. Seu objetivo é qualificar leads interessados em energia solar residencial perguntando a cidade, valor médio da conta de luz e se o imóvel é próprio.'
);

-- 3. Inserir Contato (Lead) da Eco Fonte
INSERT INTO contacts (company_id, nome, telefone, email, cidade, origem, estagio)
VALUES (
    (SELECT id FROM companies WHERE nome_empresa = 'Eco Fonte' LIMIT 1),
    'Carlos Silva',
    '+5511988888888',
    'carlos.silva@email.com',
    'São Paulo',
    'anuncio_meta',
    'lead'
);

-- 4. Inserir Memórias extraídas pela IA sobre o contato
INSERT INTO customer_memory (contact_id, tipo, informacao, importancia)
VALUES (
    (SELECT id FROM contacts WHERE telefone = '+5511988888888' LIMIT 1),
    'dados_faturamento',
    'Conta de luz média em torno de R$ 600 por mês.',
    4
),
(
    (SELECT id FROM contacts WHERE telefone = '+5511988888888' LIMIT 1),
    'perfil',
    'Imóvel próprio residencial em São Paulo.',
    5
);

-- 5. Inserir Histórico de Conversa (Mensagens)
INSERT INTO messages (company_id, contact_id, mensagem, origem)
VALUES (
    (SELECT id FROM companies WHERE nome_empresa = 'Eco Fonte' LIMIT 1),
    (SELECT id FROM contacts WHERE telefone = '+5511988888888' LIMIT 1),
    'Olá, gostaria de saber mais sobre as placas de energia solar para minha casa.',
    'cliente'
),
(
    (SELECT id FROM companies WHERE nome_empresa = 'Eco Fonte' LIMIT 1),
    (SELECT id FROM contacts WHERE telefone = '+5511988888888' LIMIT 1),
    'Olá Carlos! Com certeza, a Eco Fonte pode te ajudar a economizar até 95% na sua conta. Qual é o valor médio da sua conta de luz hoje?',
    'ia'
);

-- 6. Inserir Base de Conhecimento (FAQ)
INSERT INTO knowledge_base (company_id, pergunta, resposta, categoria)
VALUES (
    (SELECT id FROM companies WHERE nome_empresa = 'Eco Fonte' LIMIT 1),
    'A instalação das placas demora quanto tempo?',
    'A instalação física geralmente leva de 1 a 3 dias úteis dependendo do tamanho do telhado.',
    'instalacao'
);
