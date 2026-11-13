/* =====================================================================
   03 · Carga diária de TMA, TMT e TMO por operador e dia
   SQL Server

   TMA = tempo em "Em Ligação"     ÷ vezes em "Em Ligação"
   TMT = tempo em "Não Disponível" ÷ vezes em "Em Ligação"
   TMO = TMA + TMT

   Por padrão calcula ONTEM. Pode rodar mais de uma vez: apaga o período
   e insere de novo, então não duplica.
   Para carga inicial ou reprocessamento, troque @Inicio e @Fim.
   ===================================================================== */

DECLARE @Inicio date = CAST(DATEADD(DAY, -1, GETDATE()) AS date);
DECLARE @Fim    date = @Inicio;

-- Para rodar com os dados de exemplo:
-- SET @Inicio = '2026-11-03'; SET @Fim = '2026-11-04';

DECLARE @EM_LIGACAO     int = 5;
DECLARE @NAO_DISPONIVEL int = 3;
DECLARE @LIVRE          int = 1;

BEGIN TRANSACTION;

DELETE FROM dbo.metricas_operador_dia
WHERE data BETWEEN @Inicio AND @Fim;

WITH linhas AS (
    SELECT h.data, h.operador_id, h.grupo_id, h.estado_id, h.duracao_seg, r.numero
    FROM dbo.historico_estado h
    JOIN dbo.ramal r ON r.ramal_id = h.ramal_id
    WHERE h.data BETWEEN @Inicio AND @Fim
      AND r.numero BETWEEN 1000 AND 2999          -- só operador: fora robôs e URA
),
base AS (
    SELECT
        data, operador_id,
        MIN(numero) AS ramal_numero,
        SUM(CASE WHEN estado_id = @EM_LIGACAO     THEN 1           ELSE 0 END) AS em_ligacao_qtd,
        SUM(CASE WHEN estado_id = @EM_LIGACAO     THEN duracao_seg ELSE 0 END) AS em_ligacao_seg,
        SUM(CASE WHEN estado_id = @NAO_DISPONIVEL THEN duracao_seg ELSE 0 END) AS nao_disponivel_seg,
        SUM(CASE WHEN estado_id = @LIVRE          THEN duracao_seg ELSE 0 END) AS livre_seg,
        SUM(duracao_seg) AS logado_seg
    FROM linhas
    GROUP BY data, operador_id
),
equipe_do_dia AS (
    -- se o operador passou por mais de uma equipe no dia, fica a que teve mais tempo
    SELECT data, operador_id, grupo_id,
           ROW_NUMBER() OVER (PARTITION BY data, operador_id ORDER BY SUM(duracao_seg) DESC) AS ordem
    FROM linhas
    GROUP BY data, operador_id, grupo_id
)
INSERT INTO dbo.metricas_operador_dia
    (data, operador_id, operador, ramal_numero, grupo_id, equipe,
     em_ligacao_qtd, em_ligacao_seg, nao_disponivel_seg, livre_seg, logado_seg,
     tma_seg, tmt_seg, tmo_seg)
SELECT
    b.data, b.operador_id, o.nome, b.ramal_numero, e.grupo_id, g.nome,
    b.em_ligacao_qtd, b.em_ligacao_seg, b.nao_disponivel_seg, b.livre_seg, b.logado_seg,
    ROUND(b.em_ligacao_seg     * 1.0                   / NULLIF(b.em_ligacao_qtd, 0), 1),
    ROUND(b.nao_disponivel_seg * 1.0                   / NULLIF(b.em_ligacao_qtd, 0), 1),
    ROUND((b.em_ligacao_seg + b.nao_disponivel_seg) * 1.0 / NULLIF(b.em_ligacao_qtd, 0), 1)
FROM base b
JOIN dbo.operador o      ON o.operador_id = b.operador_id
JOIN equipe_do_dia e     ON e.data = b.data AND e.operador_id = b.operador_id AND e.ordem = 1
JOIN dbo.grupo g         ON g.grupo_id = e.grupo_id
WHERE g.considera_metricas = 1;                    -- fora: grupos de teste e administrativo

COMMIT TRANSACTION;

-- Conferência rápida do que entrou
SELECT data, COUNT(*) AS operadores, SUM(em_ligacao_qtd) AS atendimentos
FROM dbo.metricas_operador_dia
WHERE data BETWEEN @Inicio AND @Fim
GROUP BY data
ORDER BY data;
