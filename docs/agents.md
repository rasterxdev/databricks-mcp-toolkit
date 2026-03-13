# Agentes

O toolkit inclui dois agentes especializados, acionados automaticamente pelo Claude Code conforme o tipo de tarefa.

---

## `databricks-analyst`

| Atributo | Detalhe |
|---|---|
| **Modelo** | Sonnet |
| **Perfil** | Engenheiro de Dados e Analista senior |
| **Ferramentas** | 9 ferramentas MCP de dados + Read, Write, Edit, Bash, Glob, Grep |

### Capacidades

1. **Exploração de dados**: navegar em catalogos, schemas e tabelas do Unity Catalog
2. **SQL Analytics**: escrever e executar queries SQL otimizadas
3. **Analise estatística**: gerar estatísticas descritivas, distribuições, correlações
4. **Data Quality**: identificar nulos, duplicatas, outliers e inconsistências
5. **PySpark**: escrever e revisar codigo PySpark para transformações
6. **Notebooks**: criar notebooks Databricks com analises completas

### Quando e acionado

O agente entra em ação quando você pede coisas como:
- "analisa a tabela X pra mim"
- "cria um notebook que calcula Y"
- "roda esse SQL e me explica o resultado"

### Fluxo de analise

O agente segue uma metodologia consistente:

`describe_table` (entender colunas e tipos) → `table_stats` (visão geral de nulos e cardinalidade) → `sample_table` (ver dados reais) → `run_sql` (queries específicas)

---

## `data-scientist`

| Atributo | Detalhe |
|---|---|
| **Modelo** | Sonnet |
| **Perfil** | Cientista de Dados senior / ML Engineer |
| **Ferramentas** | Todas as 18 ferramentas MCP (dados + MLflow) + Read, Write, Edit, Bash, Glob, Grep |

### Capacidades

1. **ML Lifecycle**: explorar experimentos, runs, modelos e serving endpoints via MLflow
2. **Analise estatística avançada**: correlação, distribuições, testes de hipotese via SQL
3. **Feature engineering**: encoding, scaling, window features, lag features
4. **Pipelines preditivos**: classificação, regressão, AutoML com logging no MLflow
5. **Series temporais**: tendência, sazonalidade, forecasting
6. **Avaliação de modelos**: metricas, comparação de runs, analise de convergência
7. **Analytics avançado**: clustering, anomalias, segmentação, cohort analysis

### Quando e acionado

O agente entra em ação quando você pede coisas como:
- "compara os ultimos runs do experimento X"
- "cria um modelo preditivo para churn"
- "analisa a serie temporal de vendas"
- "faz feature engineering na tabela Y"
