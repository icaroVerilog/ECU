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

### ⏳ period_counter

**Status:** Não implementado

Mede o tempo entre dois dentes consecutivos da roda fônica.

Entradas:

- `clk`
- `rst`
- `tooth_rise`

Saídas:

- `tooth_period`
- `tooth_period_valid`

---

### ⏳ missing_tooth_detector

**Status:** Não implementado

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

### ⏳ rpm_estimator

**Status:** Não implementado

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

### ⏳ crankshaft_position

**Status:** Não implementado

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