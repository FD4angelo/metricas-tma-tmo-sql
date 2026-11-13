/* =====================================================================
   04 · Consultas de exemplo em cima da tabela de métricas
   SQL Server

   Regra principal: para juntar operadores, dias ou equipes, soma os
   tempos e as quantidades e só depois divide. Média de médias dá peso
   igual para quem atendeu 5 e para quem atendeu 150 ligações.
   ===================================================================== */

-- 1) Por equipe e dia
SELECT
    data,
    equipe,
    COUNT(*)            AS operadores,
    SUM(em_ligacao_qtd) AS atendimentos,
    ROUND(SUM(em_ligacao_seg)                      * 1.0 / NULLIF(SUM(em_ligacao_qtd), 0), 1) AS tma_seg,
    ROUND(SUM(nao_disponivel_seg)                  * 1.0 / NULLIF(SUM(em_ligacao_qtd), 0), 1) AS tmt_seg,
    ROUND(SUM(em_ligacao_seg + nao_disponivel_seg) * 1.0 / NULLIF(SUM(em_ligacao_qtd), 0), 1) AS tmo_seg
FROM dbo.metricas_operador_dia
GROUP BY data, equipe
ORDER BY data, equipe;


-- 2) Por operador no mês, em mm:ss para leitura
SELECT
    operador,
    equipe,
    SUM(em_ligacao_qtd) AS atendimentos,
    CONVERT(varchar(8), DATEADD(SECOND, SUM(em_ligacao_seg)                      / NULLIF(SUM(em_ligacao_qtd), 0), 0), 108) AS tma,
    CONVERT(varchar(8), DATEADD(SECOND, SUM(nao_disponivel_seg)                  / NULLIF(SUM(em_ligacao_qtd), 0), 0), 108) AS tmt,
    CONVERT(varchar(8), DATEADD(SECOND, SUM(em_ligacao_seg + nao_disponivel_seg) / NULLIF(SUM(em_ligacao_qtd), 0), 0), 108) AS tmo
FROM dbo.metricas_operador_dia
WHERE data >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
GROUP BY operador, equipe
ORDER BY tmo DESC;


-- 3) Operadores com TMT acima da média da própria equipe no dia
WITH equipe_dia AS (
    SELECT data, equipe,
           SUM(nao_disponivel_seg) * 1.0 / NULLIF(SUM(em_ligacao_qtd), 0) AS tmt_equipe
    FROM dbo.metricas_operador_dia
    GROUP BY data, equipe
)
SELECT m.data, m.equipe, m.operador, m.tmt_seg, ROUND(e.tmt_equipe, 1) AS tmt_equipe
FROM dbo.metricas_operador_dia m
JOIN equipe_dia e ON e.data = m.data AND e.equipe = m.equipe
WHERE m.tmt_seg > e.tmt_equipe
ORDER BY m.data, m.equipe, m.tmt_seg DESC;
