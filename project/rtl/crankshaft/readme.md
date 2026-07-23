# Crankshaft

Este diretório contém os módulos responsáveis pela leitura, sincronização e determinação da posição angular do virabrequim.

A arquitetura foi dividida em módulos independentes, onde cada um possui uma única responsabilidade. Essa abordagem facilita o desenvolvimento, os testes individuais e a reutilização dos componentes.

## Fluxo de dados

```text
CKP (Crankshaft Position Sensor - Sensor de posição do virabrequim)
        │
        ▼
edge_detector
        │
        ▼
period_counter
        │
        ├────────► rpm_estimator
        │
        ▼
missing_tooth_detector
        │
        ▼
crankshaft_position
        │
        ▼
angle_interpolator
        │
        ▼
scheduler
```

## Módulos

### ✅ edge_detector

**Status:** Implementado

Responsável por detectar as bordas do sinal proveniente do sensor CKP.

Transforma um pulso com duração arbitrária em um pulso de exatamente um ciclo de clock.

Entradas:

- `clk`
- `rst`
- `ckp_in`

Saídas:

- `tooth_rise`
- `tooth_fall`

---

### ✅ period_counter

**Status:** Implementado

Mede o tempo entre dois dentes consecutivos da roda fônica.

Entradas:

- `clk`
- `rst`
- `tooth_rise`

Saídas:

- `tooth_period`
- `tooth_period_valid`

---

### ✅ missing_tooth_detector

**Status:** Implementado

Detecta a ausência de dentes na roda fônica comparando o período entre dentes consecutivos.

Entradas:

- `clk`
- `rst`
- `tooth_period`
- `tooth_period_valid`

Saídas:

- `missing_tooth`
- `sync`

---

### ✅ rpm_estimator

**Status:** Implementado

Calcula a rotação do motor a partir do período entre dentes.

Entradas:

- `clk`
- `rst`
- `tooth_period`
- `tooth_period_valid`

Saídas:

- `rpm`
- `rpm_valid`

---

### ✅ crankshaft_position

**Status:** Implementado

Mantém o sincronismo do virabrequim e controla o contador de dentes.

Entradas:

- `clk`
- `rst`
- `tooth_rise`
- `sync`
- `missing_tooth`

Saídas:

- `tooth_number`
- `crankshaft_angle`
- `position_valid`

---

### ⏳ angle_interpolator

**Status:** Não implementado

Interpola o ângulo entre dois dentes utilizando o tempo decorrido desde o último pulso.

Esse módulo aumenta significativamente a resolução angular da ECU.

Entradas:

- `clk`
- `rst`
- `tooth_period`
- `tooth_number`

Saídas:

- `interpolated_angle`

---

### ⏳ scheduler

**Status:** Não implementado

Agenda todos os eventos dependentes do ângulo do motor.

Exemplos:

- abertura dos injetores;
- fechamento dos injetores;
- início da carga da bobina de ignição;
- disparo da centelha.

Entradas:

- `clk`
- `rst`
- `interpolated_angle`
- `rpm`

Saídas:

- sinais de controle dos atuadores.

---

## Filosofia do projeto

Cada módulo deve possuir apenas uma responsabilidade.

Os módulos devem ser independentes entre si, permitindo testes individuais através de um testbench dedicado.

O fluxo de informações deve ocorrer sempre em uma única direção, evitando dependências circulares.

Cada módulo somente deve conhecer suas entradas e saídas, sem depender da implementação interna dos demais módulos.

Essa arquitetura facilita a manutenção, a expansão futura e a validação individual de cada etapa do processamento do sinal do virabrequim.




## Melhorias Futuras

A implementação atual foi desenvolvida para rodas fônicas do tipo "missing tooth", como 60-2, utilizando a detecção de um intervalo entre dentes significativamente maior que os demais.

Como evolução do projeto, a arquitetura poderá ser generalizada para suportar diferentes padrões de rodas fônicas e estratégias de sincronização, permitindo a configuração do número de dentes, quantidade de dentes ausentes e outros padrões utilizados por diferentes fabricantes. Dessa forma, o mesmo conjunto de módulos poderá ser reutilizado em diversas aplicações apenas por meio da parametrização, sem alterações na lógica principal.

Além disso, a referência angular do sincronismo poderá ser parametrizada. Em aplicações reais, a posição do dente ausente em relação ao Ponto Morto Superior (PMS) varia conforme o projeto mecânico do motor. Dessa forma, a arquitetura futura poderá incluir um deslocamento angular de sincronização (`sync_offset`), permitindo compensar a posição física da falha da roda fônica e obter a posição absoluta real do virabrequim.

Essa abordagem permitirá que o módulo `crankshaft_position` seja utilizado em diferentes motores sem alterações na lógica interna, modificando apenas os parâmetros de configuração da roda fônica e da referência angular.