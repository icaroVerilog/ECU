# Engine Position

Este diretório contém o subsistema que transforma o sinal digital do sensor CKP em informações de velocidade e posição do virabrequim.

Quem utiliza o subsistema não precisa conhecer seus módulos internos. O ponto de integração é o `engine_position_core`.

## Visão rápida

```text
Entrada:
    ckp_signal

Saídas principais:
    synchronized
    rpm
    rpm_valid
    tooth_number
    position_valid
    crankshaft_angle
    angle_valid
```

## Arquitetura

```text
                         engine_position_core
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│  ckp_signal                                                                  │
│      │                                                                       │
│      ▼                                                                       │
│  edge_detector                                                               │
│      │ tooth_rise                                                            │
│      ▼                                                                       │
│  period_counter                                                              │
│      ├── tooth_period ───────────────► missing_tooth_detector                 │
│      └── time_since_tooth ────────────────────────────────────────────┐       │
│                                                                       │       │
│  missing_tooth_detector                                               │       │
│      ├── synchronized                                                 │       │
│      ├── missing_tooth ─────────────► crankshaft_position             │       │
│      └── normal_tooth_period ───────► rpm_estimator                   │       │
│                    │                       │                           │       │
│                    │                       └── rpm                      │       │
│                    │                                                   │       │
│                    └──────────────────────────────────────────────┐    │       │
│                                                                   ▼    ▼       │
│  crankshaft_position ── tooth_number ─────────────────────► angle_interpolator │
│                                                                   │            │
│                                                                   ▼            │
│                                                        crankshaft_angle         │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Responsabilidade do `engine_position_core`

O `engine_position_core` não refaz cálculos. Ele:

- instancia os módulos do subsistema;
- conecta as saídas de um módulo às entradas do próximo;
- concentra parâmetros como `CLOCK_FREQ`, `TOTAL_TEETH` e `PHYSICAL_TEETH`;
- expõe uma interface única para o restante da ECU;
- evita que o intervalo longo da falha contamine o cálculo de RPM e a interpolação;
- disponibiliza sinais de diagnóstico para simulação e depuração.

Ele não agenda injeção, não calcula combustível e não aciona drivers de potência.

## Fluxo de funcionamento

### 1. `edge_detector`

Converte cada borda do CKP em um pulso de um ciclo.

Entradas:

- `clk`;
- `rst`;
- `ckp_in`.

Saídas:

- `tooth_rise`;
- `tooth_fall`.

### 2. `period_counter`

Mede o número de ciclos entre duas bordas de subida consecutivas.

A primeira borda depois do reset apenas estabelece uma referência. O primeiro `period_valid` somente ocorre na segunda borda.

Saídas:

- `tooth_period`: último período concluído;
- `period_valid`: pulso indicando uma nova medição;
- `time_since_tooth`: tempo transcorrido desde o dente mais recente.

### 3. `missing_tooth_detector`

Detecta o intervalo longo da roda 60-2.

Saídas:

- `missing_tooth`: pulso de um ciclo na referência da roda;
- `sync`: permanece ativo depois do primeiro sincronismo;
- `normal_tooth_period`: média dos períodos normais, sem incluir o gap;
- `normal_period_valid`: indica atualização do período normal.

O `normal_tooth_period` é usado pelo RPM e pelo interpolador. O período bruto do gap não deve ser usado nesses cálculos.

### 4. `rpm_estimator`

Calcula:

```text
RPM = (60 × CLOCK_FREQ) / (normal_tooth_period × TOTAL_TEETH)
```

Para uma roda 60-2:

```text
TOTAL_TEETH = 60
PHYSICAL_TEETH = 58
```

O cálculo usa 60 porque cada período normal corresponde a uma das 60 posições de 6 graus da roda. Usar 58 com o período normal superestimaria o RPM.

### 5. `crankshaft_position`

Mantém o número do dente físico atual.

- antes do sincronismo, `position_valid = 0`;
- no pulso `missing_tooth`, `tooth_number` é realinhado para zero;
- nos dentes seguintes, a contagem avança de 0 a 57;
- uma nova falha corrige novamente a referência a cada volta.

### 6. `angle_interpolator`

Calcula a posição angular contínua:

```text
angle = tooth_number × ANGLE_PER_TOOTH
      + time_since_tooth × ANGLE_PER_TOOTH / normal_tooth_period
```

Representação utilizada:

```text
360 graus = 65536 unidades
6 graus   = 1092 unidades
```

Durante o gap, `time_since_tooth` continua aumentando por aproximadamente três períodos normais. Isso permite que o ângulo avance de aproximadamente 342 graus até o wrap em zero, mesmo sem bordas físicas nas duas posições ausentes.

## Interface principal

```verilog
module engine_position_core #(
    parameter integer CLOCK_FREQ      = 50000000,
    parameter integer TOTAL_TEETH     = 60,
    parameter integer PHYSICAL_TEETH  = 58,
    parameter integer ANGLE_BITS      = 16,
    parameter integer ANGLE_PER_TOOTH = 1092
)(
    input  wire clk,
    input  wire rst,
    input  wire ckp_signal,

    output wire synchronized,
    output wire missing_tooth,
    output wire position_valid,
    output wire angle_valid,
    output wire rpm_valid,

    output wire [5:0]  tooth_number,
    output wire [15:0] crankshaft_angle,
    output wire [31:0] rpm
);
```

A implementação também expõe sinais de diagnóstico, como os períodos bruto e filtrado e `time_since_tooth`.

## Status

| Módulo | Status |
|---|---|
| `edge_detector` | Implementado e testado isoladamente |
| `period_counter` | Implementado; expõe `time_since_tooth` |
| `missing_tooth_detector` | Implementado; expõe período normal filtrado |
| `rpm_estimator` | Implementado com 60 posições angulares |
| `crankshaft_position` | Implementado com realinhamento por gap |
| `angle_interpolator` | Implementado |
| `engine_position_core` | Implementado |
| `tb_engine_position_core` | Implementado para roda 60-2 completa |

## Teste integrado

O arquivo `project/sim/testbenches/tb_engine_position_core.v` gera somente `ckp_signal`.

Ele simula:

```text
58 dentes físicos
+ intervalo de três períodos
+ nova volta
```

São executadas uma volta de aquisição e duas voltas sincronizadas. O teste verifica automaticamente:

- ausência de saídas válidas antes do sincronismo;
- períodos normais e períodos triplos;
- detecção de três gaps;
- realinhamento para o dente zero;
- sequência completa dos dentes;
- RPM esperado;
- continuidade do ângulo;
- avanço angular durante os dentes ausentes;
- wrap permitido apenas no final da volta.

Execução:

```bash
./scripts/run.sh engine_position_core
```

Todos os testes:

```bash
./scripts/run.sh all
```

Os arquivos VCD são gravados em `project/sim/waves`.

## Próxima etapa

Somente depois da regressão integrada passar no ambiente de desenvolvimento, o próximo módulo será o `event_scheduler`.
