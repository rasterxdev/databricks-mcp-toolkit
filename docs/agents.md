# Agentes

O toolkit inclui dois agentes especializados, acionados automaticamente pelo Claude Code conforme o tipo de tarefa.

---

## `databricks-analyst`

| Atributo | Detalhe |
|---|---|
| **Modelo** | Sonnet |
| **Perfil** | Engenheiro de Dados e Analista sênior |
| **Ferramentas** | 9 ferramentas MCP de dados + Read, Write, Edit, Bash, Glob, Grep |

### Capacidades

1. **Exploração de dados**: navegar em catálogos, schemas e tabelas do Unity Catalog
2. **SQL Analytics**: escrever e executar queries SQL otimizadas
3. **Análise estatística**: gerar estatísticas descritivas, distribuições, correlações
4. **Data Quality**: identificar nulos, duplicatas, outliers e inconsistências
5. **PySpark**: escrever e revisar código PySpark para transformações
6. **Notebooks**: criar notebooks Databricks com análises completas

### Quando é acionado

O agente entra em ação quando você pede coisas como:
- "analisa a tabela X pra mim"
- "cria um notebook que calcula Y"
- "roda esse SQL e me explica o resultado"

### Fluxo de análise

O agente segue uma metodologia consistente:

`describe_table` (entender colunas e tipos) → `table_stats` (visão geral de nulos e cardinalidade) → `sample_table` (ver dados reais) → `run_sql` (queries específicas)

---

## `data-scientist`

| Atributo | Detalhe |
|---|---|
| **Modelo** | Sonnet |
| **Perfil** | Cientista de Dados sênior / ML Engineer |
| **Ferramentas** | Todas as 18 ferramentas MCP (dados + MLflow) + Read, Write, Edit, Bash, Glob, Grep |

### Capacidades

1. **ML Lifecycle**: explorar experimentos, runs, modelos e serving endpoints via MLflow
2. **Análise estatística avançada**: correlação, distribuições, testes de hipótese via SQL
3. **Feature engineering**: encoding, scaling, window features, lag features
4. **Pipelines preditivos**: classificação, regressão, AutoML com logging no MLflow
5. **Séries temporais**: tendência, sazonalidade, forecasting
6. **Avaliação de modelos**: métricas, comparação de runs, análise de convergência
7. **Analytics avançado**: clustering, anomalias, segmentação, cohort analysis

### Quando é acionado

O agente entra em ação quando você pede coisas como:
- "compara os últimos runs do experimento X"
- "cria um modelo preditivo para churn"
- "analisa a série temporal de vendas"
- "faz feature engineering na tabela Y"
