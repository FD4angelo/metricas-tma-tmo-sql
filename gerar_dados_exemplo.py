"""
Gera sql/02_dados_exemplo.sql com uma base pequena e inventada:
6 operadores, 2 dias, 2 equipes, 1 grupo de teste e 1 ramal de robô.
Os casos especiais (troca de equipe, robô, teste) existem de propósito,
para dar para ver as regras da carga funcionando.
"""

import random
from pathlib import Path

random.seed(7)

ESTADOS = [(1, 'Livre'), (2, 'Intervalo'), (3, 'Não Disponível'), (5, 'Em Ligação')]
GRUPOS = [(10, 'Equipe Norte', 1), (20, 'Equipe Sul', 1), (99, 'Teste', 0)]
OPERADORES = [(1, 'Ana Souza'), (2, 'Bruno Lima'), (3, 'Carla Mendes'),
              (4, 'Diego Rocha'), (5, 'Elisa Prado'), (6, 'Felipe Torres'),
              (7, 'Robô Discador')]
RAMAIS = [(101, 1201), (102, 1202), (103, 1203), (104, 1204), (105, 1205), (106, 1206),
          (107, 9001)]  # 9001 = robô, deve ficar de fora
DIAS = ['2026-11-03', '2026-11-04']

# operador -> (ramal_id, equipe, perfil de TMA em segundos, perfil de TMT)
PERFIL = {1: (101, 10, 140, 25), 2: (102, 10, 95, 40), 3: (103, 10, 180, 15),
          4: (104, 20, 120, 30), 5: (105, 20, 160, 55), 6: (106, 20, 100, 20)}

linhas = []
for dia in DIAS:
    for op, (ramal, grupo, tma, tmt) in PERFIL.items():
        chamadas = random.randint(12, 20)
        for i in range(chamadas):
            g = grupo
            if op == 2 and dia == DIAS[1] and i < 3:
                g = 20  # Bruno começa o 2º dia na outra equipe, mas passa mais tempo na dele
            linhas.append((dia, op, ramal, g, 5, max(15, int(random.gauss(tma, tma * 0.3)))))
            linhas.append((dia, op, ramal, g, 3, max(3, int(random.gauss(tmt, tmt * 0.4)))))
            linhas.append((dia, op, ramal, g, 1, random.randint(20, 240)))
        linhas.append((dia, op, ramal, grupo, 2, random.randint(15 * 60, 20 * 60)))
    # robô e grupo de teste: entram na origem, mas não podem aparecer no resultado
    for _ in range(5):
        linhas.append((dia, 7, 107, 10, 5, random.randint(5, 30)))

# Felipe faz um teste rápido no grupo Teste no 1º dia (fica na Equipe Sul, onde passou mais tempo)
linhas.append((DIAS[0], 6, 106, 99, 5, 60))


def valores(rows, fmt):
    return ',\n'.join('    (' + fmt(r) + ')' for r in rows)


q = lambda s: "'" + s.replace("'", "''") + "'"
sql = ['/* Dados de exemplo, inventados. Rodar depois do 01_criar_tabelas.sql */', '']
sql.append('INSERT INTO dbo.estado (estado_id, descricao) VALUES\n'
           + valores(ESTADOS, lambda r: f'{r[0]}, {q(r[1])}') + ';\n')
sql.append('INSERT INTO dbo.grupo (grupo_id, nome, considera_metricas) VALUES\n'
           + valores(GRUPOS, lambda r: f'{r[0]}, {q(r[1])}, {r[2]}') + ';\n')
sql.append('INSERT INTO dbo.operador (operador_id, nome) VALUES\n'
           + valores(OPERADORES, lambda r: f'{r[0]}, {q(r[1])}') + ';\n')
sql.append('INSERT INTO dbo.ramal (ramal_id, numero) VALUES\n'
           + valores(RAMAIS, lambda r: f'{r[0]}, {r[1]}') + ';\n')

# SQL Server aceita no máximo 1000 linhas por INSERT ... VALUES
for i in range(0, len(linhas), 500):
    bloco = linhas[i:i + 500]
    sql.append('INSERT INTO dbo.historico_estado (data, operador_id, ramal_id, grupo_id, estado_id, duracao_seg) VALUES\n'
               + valores(bloco, lambda r: f"{q(r[0])}, {r[1]}, {r[2]}, {r[3]}, {r[4]}, {r[5]}") + ';\n')

saida = Path(__file__).parent / 'sql' / '02_dados_exemplo.sql'
saida.write_text('\n'.join(sql), encoding='utf-8')
print(f'{len(linhas)} intervalos gravados em {saida}')
