# TMA, TMT e TMO por operador e dia

Modelagem em SQL Server para calcular os tempos de atendimento de um call center a partir do histórico de estados do discador. O resultado é uma tabela com uma linha por operador por dia, que serve de base para comparar operadores e equipes.

Fiz isso no trabalho para substituir um cálculo que dependia de exportar relatórios na mão e cruzar no Excel. Esta é uma versão genérica, com nomes de tabelas neutros e dados inventados.

## As métricas

| Métrica | Fórmula |
|---|---|
| TMA (tempo médio de atendimento) | tempo em "Em Ligação" ÷ vezes em "Em Ligação" |
| TMT (tempo médio de tabulação) | tempo em "Não Disponível" ÷ vezes em "Em Ligação" |
| TMO (tempo médio operacional) | TMA + TMT |

O divisor é sempre a quantidade de atendimentos, inclusive no TMT. Assim o TMO fecha certinho como a soma dos dois.

## Regras

- Só entram ramais de operador (1000 a 2999). Robôs e URA ficam de fora.
- Grupos de teste ou administrativos (`considera_metricas = 0`) não aparecem no resultado.
- Se o operador passou por mais de uma equipe no dia, ele fica na equipe em que passou mais tempo.
- Operador sem nenhum atendimento no dia fica com as médias vazias, em vez de dar erro de divisão por zero.
- Para juntar operadores, dias ou equipes, soma os tempos e as quantidades e só depois divide. Fazer média das médias distorce o resultado.

## Arquivos

| Arquivo | O que faz |
|---|---|
| `sql/01_criar_tabelas.sql` | Cria as tabelas de origem e a de destino |
| `sql/02_dados_exemplo.sql` | Base inventada: 6 operadores, 2 dias, 1 robô e 1 grupo de teste |
| `sql/03_carga_diaria.sql` | Calcula o dia anterior e grava. Pode rodar de novo sem duplicar |
| `sql/04_consultas.sql` | Exemplos: visão por equipe, ranking do mês, quem está acima da média da equipe |
| `gerar_dados_exemplo.py` | Gera o `02_dados_exemplo.sql` |

## Como testar

Num banco SQL Server vazio, rode os arquivos na ordem. No `03`, descomente a linha do `SET` para usar as datas dos dados de exemplo (03 e 04/11/2026).

## Tabela de destino

| Coluna | Descrição |
|---|---|
| data, operador_id | Chave da tabela |
| operador, ramal_numero | Nome e ramal usado no dia |
| grupo_id, equipe | Equipe do dia |
| em_ligacao_qtd | Atendimentos (divisor das médias) |
| em_ligacao_seg, nao_disponivel_seg, livre_seg, logado_seg | Tempos em segundos |
| tma_seg, tmt_seg, tmo_seg | Médias em segundos |
| carregado_em | Quando a linha foi gravada |

---

**English:** SQL Server model that calculates average handle time (TMA), wrap-up time (TMT) and total operation time (TMO) per agent per day from a dialer's agent state history. It filters out bots and test groups, assigns each agent to the team where they spent the most time that day, and the daily load can be re-run without duplicating rows. Sample data is fake.
