# Skills — Slash Commands

Skills são atalhos que injetam prompts especializados no Claude Code. Basta digitar o comando no chat.

---

## `/sql` — Executar SQL

Executa queries SQL diretamente ou gera SQL a partir de linguagem natural.

```
/sql SELECT * FROM silver.ibge.ipca_mensal WHERE valor > 5 ORDER BY data_referencia
```

Também aceita linguagem natural:

```
/sql me mostra as 10 maiores variações do IPCA
```

**O que acontece por baixo:** se você fornece uma query pronta, ela é executada diretamente. Se descreve o que quer, o Claude primeiro inspeciona as tabelas com `describe_table`, monta a query e então executa.

---

## `/analyze` — Análise exploratória (EDA)

Executa uma análise exploratória completa de qualquer tabela.

```
/analyze silver.ibge.ipca_mensal
```

**Etapas executadas automaticamente:**

1. Leitura do schema (colunas e tipos)
2. Estatísticas descritivas (contagem, nulos, cardinalidade)
3. Amostra de dados reais
4. Distribuições de valores (categóricas, numéricas, temporais)
5. Verificações de data quality (nulos, duplicatas, outliers)

O resultado é apresentado em markdown organizado, com uma seção final de observações e insights.

---

## `/notebook` — Criar notebook PySpark

Gera um arquivo `.py` no formato nativo de notebooks Databricks.

```
/notebook análise de tendência do IPCA com média móvel de 3 meses
```

**O notebook gerado inclui:**

- Header `# Databricks notebook source`
- Separadores de célula `# COMMAND ----------`
- Células de documentação com `# MAGIC %md`
- Código PySpark estruturado e comentado
- Célula de validação/verificação ao final

---

## `/explore` — Navegar pelo Unity Catalog

Navegação progressiva pelo Unity Catalog, do nível mais alto até o detalhe de uma tabela.

```
/explore                           # lista catálogos
/explore silver                    # lista schemas do catálogo silver
/explore silver.ibge               # lista tabelas do schema ibge
/explore silver.ibge.ipca_mensal   # descreve a tabela completa
```

---

## `/predict` — Pipeline ML completo

Gera um notebook Databricks com pipeline de Machine Learning completo.

```
/predict classificar churn na tabela gold.clientes.features
```

**O notebook gerado inclui:** EDA, feature engineering, split treino/teste, treinamento com logging no MLflow, avaliação de métricas e registro do modelo.

---

## `/stats` — Análise estatística avançada

Executa testes estatísticos e análises avançadas usando funções SQL nativas do Databricks.

```
/stats correlação entre preço e volume na tabela silver.mercado.acoes
```

**Análises disponíveis:** estatísticas descritivas avançadas (skewness, kurtosis), correlação, detecção de outliers (IQR), distribuição de frequência, teste de normalidade aproximado.

---

## `/timeseries` — Séries temporais

Analisa séries temporais e gera notebooks de forecasting.

```
/timeseries tendência do IPCA em silver.ibge.ipca_mensal
```

**O que faz:** identifica tendência, sazonalidade, anomalias temporais, variação período a período, e opcionalmente gera um notebook de forecasting com Prophet ou ARIMA.

---

## `/model` — Gerenciar MLflow

Inspeciona experimentos, runs, modelos registrados e serving endpoints do MLflow.

```
/model list experiments
/model runs 123456
/model compare run_id1,run_id2
/model endpoints
```

---

## `/feature` — Feature engineering

Analisa features de uma tabela e gera pipelines de feature engineering.

```
/feature gold.clientes.transacoes target=churn
```

**O que faz:** classifica features por tipo, analisa correlação com target, recomenda transformações (encoding, scaling, window features) e opcionalmente gera um notebook com o pipeline completo.
