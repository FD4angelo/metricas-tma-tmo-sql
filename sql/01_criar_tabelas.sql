/* =====================================================================
   01 · Criar as tabelas (rodar uma vez)
   SQL Server

   Tabelas de origem (como vêm do discador):
     estado, grupo, operador, ramal, historico_estado
   Tabela de destino (o que este projeto calcula):
     metricas_operador_dia
   ===================================================================== */

-- Estados possíveis do ramal do operador
CREATE TABLE dbo.estado (
    estado_id   int          NOT NULL PRIMARY KEY,
    descricao   varchar(50)  NOT NULL
);

-- Equipes. considera_metricas = 0 para grupos de teste ou administrativos
CREATE TABLE dbo.grupo (
    grupo_id            int          NOT NULL PRIMARY KEY,
    nome                varchar(100) NOT NULL,
    considera_metricas  bit          NOT NULL DEFAULT 1
);

CREATE TABLE dbo.operador (
    operador_id  int          NOT NULL PRIMARY KEY,
    nome         varchar(150) NOT NULL
);

-- Ramais de operador vão de 1000 a 2999. Acima disso são robôs e URA
CREATE TABLE dbo.ramal (
    ramal_id  int NOT NULL PRIMARY KEY,
    numero    int NOT NULL
);

-- Cada linha é um intervalo em que o operador ficou num estado
CREATE TABLE dbo.historico_estado (
    historico_id  int  IDENTITY(1,1) PRIMARY KEY,
    data          date NOT NULL,
    operador_id   int  NOT NULL REFERENCES dbo.operador (operador_id),
    ramal_id      int  NOT NULL REFERENCES dbo.ramal (ramal_id),
    grupo_id      int  NOT NULL REFERENCES dbo.grupo (grupo_id),
    estado_id     int  NOT NULL REFERENCES dbo.estado (estado_id),
    duracao_seg   int  NOT NULL
);

-- Destino: uma linha por operador por dia
CREATE TABLE dbo.metricas_operador_dia (
    data                date          NOT NULL,
    operador_id         int           NOT NULL,
    operador            varchar(150)  NULL,
    ramal_numero        int           NULL,
    grupo_id            int           NULL,  -- equipe onde ficou mais tempo no dia
    equipe              varchar(100)  NULL,

    em_ligacao_qtd      int           NOT NULL,  -- vezes em "Em Ligação" (divisor das médias)
    em_ligacao_seg      int           NOT NULL,
    nao_disponivel_seg  int           NOT NULL,  -- tabulação depois da ligação
    livre_seg           int           NOT NULL,
    logado_seg          int           NOT NULL,

    tma_seg             decimal(9,1)  NULL,
    tmt_seg             decimal(9,1)  NULL,
    tmo_seg             decimal(9,1)  NULL,

    carregado_em        datetime2(0)  NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT pk_metricas_operador_dia PRIMARY KEY (data, operador_id)
);
