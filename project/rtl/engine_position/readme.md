# Engine Position

Este diretório contém o subsistema responsável por transformar o sinal bruto do sensor CKP em informações utilizáveis pelo restante da ECU:

- rotação do motor em RPM;
- sincronismo da roda fônica;
- número do dente atual;
- posição angular contínua do virabrequim.

A implementação foi dividida em módulos pequenos e independentes. Cada módulo possui uma única responsabilidade e pode ser validado isoladamente por meio de seu próprio testbench.

## Visão rápida

```text
Entrada do subsistema:
    sinal digital do sensor CKP

Saídas do subsistema:
    rpm
    rpm_valid
    tooth_number
    position_valid
    crankshaft_angle
    angle_valid
    synchronized
```

O restante da ECU não precisa conhecer os detalhes internos da leitura da roda fônica. Todos os módulos deste diretório serão agrupados pelo `engine_position_core`, que fornecerá uma interface única para o `ecu_top`.

## Status atual

| Módulo | Responsabilidade | Status |
|---|---|---|
| `edge_detector` | Detectar as bordas do sinal CKP | Implementado |
| `period_counter` | Medir o tempo entre dentes | Implementado; requer exposição de `time_since_tooth` para a integração |
| `missing_tooth_detector` | Detectar a região dos dentes ausentes e estabelecer sincronismo | Implementado |
| `rpm_estimator` | Calcular a rotação do motor | Implementado; parametrização e tratamento do gap devem ser verificados na integração |
| `crankshaft_position` | Manter o número do dente após o sincronismo | Implementado; requer realinhamento pelo pulso `missing_tooth` |
| `angle_interpolator` | Estimar o ângulo entre dentes | Implementado |
| `engine_position_core` | Agrupar e conectar todos os módulos | Próximo módulo a ser implementado |

## Arquitetura do subsistema

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
│      ├── tooth_period ───────────────────────► rpm_estimator                  │
│      ├── tooth_period ───────────────────────► missing_tooth_detector         │
│      └── time_since_tooth ───────────────┐                                    │
│                                          │                                    │
│  missing_tooth_detector                  │                                    │
│      ├── sync ───────────────────────┐    │                                    │
│      └── missing_tooth ──────────────┤    │                                    │
│                                      ▼    │                                    │
│                              crankshaft_position                              │
│                                      │ tooth_number                           │
│                                      └───────────────┐                         │
│                                                      ▼                         │
│                                             angle_interpolator ◄──────────────┘
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
        │                  │                  │                  │
        ▼                  ▼                  ▼                  ▼
       rpm           tooth_number      crankshaft_angle     synchronized
```

## `engine_position_core`

O `engine_position_core` será o módulo de integração do subsistema de posição do motor.

Ele não deve duplicar fórmulas nem refazer cálculos que pertencem aos módulos internos. Sua responsabilidade é organizar a cadeia de processamento e apresentar uma interface única para o restante da ECU.

### Responsabilidades

- instanciar os módulos de posição do motor;
- conectar as saídas de um módulo às entradas do próximo;
- concentrar parâmetros compartilhados, como a frequência do clock e a configuração da roda fônica;
- expor somente os sinais relevantes para o restante da ECU;
- impedir que posições ou ângulos inválidos sejam usados antes do sincronismo;
- centralizar regras de integração, como o tratamento do intervalo dos dentes ausentes;
- permitir a validação de toda a cadeia utilizando apenas um sinal CKP simulado.

### O que ele não deve fazer

- detectar bordas diretamente;
- medir períodos diretamente;
- calcular RPM diretamente;
- contar dentes diretamente;
- executar a fórmula de interpolação angular diretamente;
- agendar injeção ou ignição;
- controlar drivers de potência.

Essas responsabilidades pertencem aos módulos especializados.

### Interface externa proposta

```verilog
module engine_position_core #(
    parameter integer CLOCK_FREQ    = 50_000_000,
    parameter integer TOTAL_TEETH   = 60,
    parameter integer MISSING_TEETH = 2,
    parameter integer ANGLE_BITS    = 16,
    parameter integer TIME_BITS     = 32
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  ckp_signal,

    output wire                  synchronized,
    output wire                  rpm_valid,
    output wire                  position_valid,
    output wire                  angle_valid,

    output wire [31:0]           rpm,
    output wire [5:0]            tooth_number,
    output wire [ANGLE_BITS-1:0] crankshaft_angle,
    output wire [TIME_BITS-1:0]  tooth_period
);
```

A largura exata de `tooth_number` pode ser calculada com `$clog2(PHYSICAL_TEETH)` na implementação.

## Fluxo de funcionamento

### 1. Leitura do CKP

O `edge_detector` recebe o sinal digital do sensor CKP e transforma cada transição em um pulso com duração de um ciclo de clock.

O pulso utilizado pela cadeia principal é:

```text
tooth_rise
```

Cada `tooth_rise` representa a passagem de um novo dente físico pelo sensor.

### 2. Medição do período

O `period_counter` conta quantos ciclos do clock ocorreram desde o último `tooth_rise`.

Quando um novo dente é detectado, ele publica:

```text
tooth_period
period_valid
```

Para a interpolação em tempo real, ele também deverá disponibilizar continuamente:

```text
time_since_tooth
```

`tooth_period` representa o período concluído entre os últimos dentes. `time_since_tooth` representa o tempo que já passou desde o dente mais recente.

### 3. Estimativa de RPM

O `rpm_estimator` transforma o período entre dentes em rotação do motor.

Para uma roda 60-2, o período normal entre dentes corresponde a uma das 60 posições angulares da roda, ou seja, 6 graus. O intervalo ampliado causado pelos dois dentes ausentes não deve ser interpretado como um período normal.

O cálculo conceitual é:

```text
RPM = (60 × CLOCK_FREQ) / (tooth_period × TOTAL_TEETH)
```

onde `TOTAL_TEETH` representa o total de posições angulares da roda, incluindo as posições dos dentes ausentes.

### 4. Detecção dos dentes ausentes

O `missing_tooth_detector` compara o período atual com períodos normais anteriores.

Quando encontra um intervalo significativamente maior, produz:

```text
missing_tooth = 1 por um ciclo
sync = 1 após o primeiro sincronismo
```

O pulso `missing_tooth` identifica a referência física da roda. O sinal `sync` informa que essa referência já foi encontrada.

### 5. Determinação do dente atual

O `crankshaft_position` mantém o número do dente atual depois que o sincronismo foi adquirido.

Ele recebe:

```text
tooth_rise
sync
missing_tooth
```

O `missing_tooth` deve realinhar a contagem em todas as voltas. Isso evita que um dente perdido ou um pulso espúrio provoque um deslocamento permanente da posição.

O módulo publica:

```text
tooth_number
position_valid
```

O `tooth_number` representa uma posição discreta. Ele não representa sozinho o ângulo contínuo entre dois dentes.

### 6. Interpolação angular

O `angle_interpolator` recebe:

```text
tooth_number
tooth_period
time_since_tooth
position_valid
```

A posição angular é calculada por interpolação linear:

```text
ângulo = ângulo_base + avanço_desde_o_último_dente

ângulo_base = tooth_number × ANGLE_PER_TOOTH

avanço_desde_o_último_dente =
    (time_since_tooth × ANGLE_PER_TOOTH) / tooth_period
```

A saída é:

```text
crankshaft_angle
angle_valid
```

## Representação angular

O projeto utiliza ponto fixo para representar ângulos sem utilizar ponto flutuante na FPGA.

```text
360 graus = 65536 unidades
1 unidade = aproximadamente 0,00549 grau
6 graus   = aproximadamente 1092 unidades
```

A saída angular utiliza 16 bits e faz wrap naturalmente ao completar uma volta:

```text
359,99 graus → 0 grau
```

O valor `ANGLE_PER_TOOTH = 1092` é uma aproximação inteira. A diferença acumulada causada pelo arredondamento deve ser considerada na implementação do wrap e na referência angular.

## Sinais internos principais

| Sinal | Origem | Destino | Significado |
|---|---|---|---|
| `tooth_rise` | `edge_detector` | `period_counter`, `crankshaft_position` | Novo dente detectado |
| `tooth_fall` | `edge_detector` | Diagnóstico futuro | Borda de descida do CKP |
| `tooth_period` | `period_counter` | `rpm_estimator`, `missing_tooth_detector`, `angle_interpolator` | Período concluído entre dentes |
| `period_valid` | `period_counter` | `rpm_estimator`, `missing_tooth_detector` | Nova medição de período disponível |
| `time_since_tooth` | `period_counter` | `angle_interpolator` | Tempo transcorrido desde o último dente |
| `missing_tooth` | `missing_tooth_detector` | `crankshaft_position`, lógica de integração | Pulso de referência da falha da roda |
| `sync` | `missing_tooth_detector` | `crankshaft_position`, saída do core | Sincronismo adquirido |
| `tooth_number` | `crankshaft_position` | `angle_interpolator`, saída do core | Posição discreta da roda |
| `position_valid` | `crankshaft_position` | `angle_interpolator`, saída do core | Número do dente válido |
| `interpolated_angle` | `angle_interpolator` | Saída do core, scheduler futuro | Posição angular contínua |
| `angle_valid` | `angle_interpolator` | Saída do core | Ângulo disponível e válido |
| `rpm` | `rpm_estimator` | Saída do core, cálculos futuros | Rotação estimada do motor |
| `rpm_valid` | `rpm_estimator` | Saída do core | Nova estimativa de RPM disponível |

## Módulos

### `edge_detector`

**Status:** implementado.

Detecta as bordas de subida e descida do sinal CKP.

Entradas:

- `clk`;
- `rst`;
- `ckp_in`.

Saídas:

- `tooth_rise`;
- `tooth_fall`.

O módulo não mede tempo e não interpreta a posição do motor.

---

### `period_counter`

**Status:** implementado, com ajuste necessário para integração.

Mede o número de ciclos de clock entre duas bordas de subida consecutivas.

Entradas:

- `clk`;
- `rst`;
- `tooth_rise`.

Saídas atuais:

- `tooth_period`;
- `period_valid`.

Saída necessária para o `engine_position_core`:

- `time_since_tooth`.

O módulo deve ser a única referência temporal da cadeia, evitando que outros componentes mantenham contadores duplicados.

---

### `missing_tooth_detector`

**Status:** implementado.

Detecta a região dos dentes ausentes utilizando a diferença entre o período atual e a média dos períodos normais anteriores.

Entradas:

- `clk`;
- `rst`;
- `tooth_period`;
- `period_valid`.

Saídas:

- `missing_tooth`;
- `sync`.

O módulo possui uma fase inicial de aquisição e uma fase sincronizada. Depois do primeiro gap, mantém uma referência baseada em dentes normais e evita detectar múltiplos gaps sem o rearmamento necessário.

---

### `rpm_estimator`

**Status:** implementado, com validações necessárias na integração.

Calcula a rotação do motor a partir do período entre dentes.

Entradas:

- `clk`;
- `rst`;
- `tooth_period`;
- `tooth_period_valid`.

Saídas:

- `rpm`;
- `rpm_valid`.

Durante a integração devem ser confirmados:

- uso de `TOTAL_TEETH = 60` para os períodos normais de uma roda 60-2;
- rejeição do período ampliado correspondente aos dentes ausentes;
- comportamento durante aceleração e desaceleração.

---

### `crankshaft_position`

**Status:** implementado, com ajuste necessário para realinhamento.

Mantém a posição discreta da roda fônica.

Entradas desejadas na arquitetura integrada:

- `clk`;
- `rst`;
- `tooth_rise`;
- `sync`;
- `missing_tooth`.

Saídas:

- `tooth_number`;
- `position_valid`.

O módulo não deve calcular o ângulo interpolado. Sua responsabilidade termina na identificação do dente físico atual.

A implementação integrada deve utilizar `missing_tooth` como referência de realinhamento em cada volta.

---

### `angle_interpolator`

**Status:** implementado.

Estima continuamente a posição angular entre dois dentes consecutivos.

Entradas:

- `clk`;
- `rst`;
- `tooth_number`;
- `tooth_period`;
- `time_since_tooth`;
- `position_valid`.

Saídas:

- `interpolated_angle`;
- `angle_valid`.

O módulo pressupõe que a velocidade angular permanece aproximadamente constante dentro do intervalo entre dois dentes.

---

### `engine_position_core`

**Status:** próximo módulo a ser implementado.

Agrupa todos os módulos deste diretório e apresenta uma interface única ao restante da ECU.

Entradas:

- `clk`;
- `rst`;
- `ckp_signal`.

Saídas principais:

- `synchronized`;
- `rpm`;
- `rpm_valid`;
- `tooth_number`;
- `position_valid`;
- `crankshaft_angle`;
- `angle_valid`;
- `tooth_period` para diagnóstico.

## Pontos que devem ser resolvidos antes do teste integrado

### Expor `time_since_tooth`

O contador interno do `period_counter` deve ser disponibilizado para o `angle_interpolator`.

Sem esse sinal, não existe interpolação angular contínua em uma integração real.

### Realinhar a posição em cada gap

O `crankshaft_position` deve receber o pulso `missing_tooth` e estabelecer uma posição de referência definida quando o gap for detectado.

O sinal persistente `sync` informa apenas que o sincronismo já foi adquirido; ele não substitui o pulso de referência de cada volta.

### Não usar o período do gap como período normal

Em uma roda 60-2, o intervalo que contém os dois dentes ausentes é aproximadamente três vezes maior que um intervalo normal.

Esse valor não deve:

- reduzir artificialmente o RPM;
- fazer a interpolação avançar como se a distância angular fosse apenas 6 graus;
- contaminar a referência de período normal.

O `engine_position_core` deverá selecionar ou produzir uma referência de período normal para os cálculos que dependem dela.

### Qualificar as saídas

Antes do sincronismo:

```text
synchronized = 0
position_valid = 0
angle_valid = 0
```

Depois do sincronismo:

```text
synchronized = 1
position_valid = 1
angle_valid = 1
```

Apenas sinais acompanhados pelos respectivos indicadores de validade devem ser utilizados pelo restante da ECU.

## Teste integrado

O testbench do `engine_position_core` deve estimular somente:

```text
clk
rst
ckp_signal
```

Ele não deve preencher manualmente `tooth_period`, `tooth_number` ou `time_since_tooth`. Esses sinais devem ser produzidos pela cadeia real de módulos.

### Sequência básica da roda 60-2

```text
58 dentes físicos
2 posições sem dente
58 dentes físicos
2 posições sem dente
...
```

Como as posições ausentes formam um único intervalo maior, o gerador CKP deve produzir 57 intervalos normais entre dentes físicos e um intervalo ampliado de aproximadamente 18 graus entre o último dente antes da falha e o primeiro dente depois dela.

### Validações mínimas

- nenhum dado de posição deve ser considerado válido antes do primeiro gap;
- o primeiro gap deve ativar o sincronismo;
- `tooth_number` deve avançar na ordem esperada;
- o pulso `missing_tooth` deve realinhar a posição em todas as voltas;
- `crankshaft_angle` deve crescer continuamente entre os dentes;
- o ângulo só pode retroceder no wrap de 360 para 0 graus;
- o RPM deve permanecer próximo do RPM gerado pelo modelo;
- o gap não deve produzir uma queda falsa de RPM;
- acelerações e desacelerações não devem causar perda indevida de sincronismo;
- uma perda prolongada do CKP deve invalidar posição e ângulo;
- pulsos espúrios devem ser detectados ou rejeitados por uma evolução futura da arquitetura.

### Cenários recomendados

```text
200 RPM   - partida lenta
500 RPM   - partida
1000 RPM  - baixa rotação
3000 RPM  - rotação intermediária
6000 RPM  - alta rotação
1000 → 3000 RPM - aceleração
3000 → 800 RPM  - desaceleração
perda temporária do CKP
pulso CKP espúrio
```

## Relação com o restante da ECU

```text
ecu_top
│
├── engine_position_core
│   ├── edge_detector
│   ├── period_counter
│   ├── missing_tooth_detector
│   ├── rpm_estimator
│   ├── crankshaft_position
│   └── angle_interpolator
│
├── fuel_calculator
├── pulsewidth_to_angle
├── event_scheduler
└── injector_driver
```

O `event_scheduler` deverá consumir informações já qualificadas pelo `engine_position_core`, principalmente:

```text
crankshaft_angle
angle_valid
rpm
rpm_valid
synchronized
```

Dessa forma, o scheduler não precisa conhecer bordas, períodos, gaps ou números de dentes.

## Estrutura de arquivos

```text
rtl/
└── engine_position/
    ├── edge_detector.v
    ├── period_counter.v
    ├── missing_tooth_detector.v
    ├── rpm_estimator.v
    ├── crankshaft_position.v
    ├── angle_interpolator.v
    ├── engine_position_core.v
    └── README.md

tb/
└── engine_position/
    ├── tb_edge_detector.v
    ├── tb_period_counter.v
    ├── tb_missing_tooth_detector.v
    ├── tb_rpm_estimator.v
    ├── tb_crankshaft_position.v
    ├── tb_angle_interpolator_math.v
    ├── tb_angle_interpolator_realtime.v
    └── tb_engine_position_core.v
```

Enquanto a reorganização das pastas não for realizada, este documento também pode permanecer em `project/rtl/crankshaft/readme.md`.

## Filosofia do projeto

- cada módulo deve possuir uma única responsabilidade;
- cálculos não devem ser duplicados no módulo de integração;
- os módulos devem se comunicar apenas por entradas e saídas explícitas;
- o fluxo de dados deve seguir uma única direção;
- cada módulo deve possuir um testbench individual;
- o conjunto deve possuir um testbench de integração;
- sinais de dados devem ser acompanhados por sinais de validade quando necessário;
- a implementação deve priorizar clareza antes de otimizações prematuras;
- toda aritmética sintetizável deve utilizar inteiros ou ponto fixo;
- parâmetros mecânicos da roda não devem ficar espalhados em diversos módulos.

## Melhorias futuras

### Parametrização de rodas fônicas

A arquitetura poderá ser generalizada para diferentes configurações:

- 60-2;
- 36-1;
- outras quantidades de dentes;
- múltiplos dentes ausentes;
- padrões especiais de sincronização.

Os principais parâmetros devem ser concentrados no `engine_position_core` e encaminhados aos módulos internos.

### Referência mecânica e `sync_offset`

A falha da roda fônica não representa necessariamente 0 grau mecânico nem o PMS do cilindro 1.

Uma evolução futura deverá permitir:

```text
ângulo_absoluto = ângulo_medido + sync_offset
```

O `sync_offset` compensará a distância física entre a falha da roda e a referência mecânica real do motor.

### Perda de sincronismo

A arquitetura poderá invalidar o sincronismo quando ocorrer:

- ausência de pulsos por tempo excessivo;
- período fora dos limites físicos;
- quantidade incorreta de dentes entre gaps;
- múltiplos gaps inesperados;
- aceleração incompatível com o comportamento mecânico do motor.

### Sensor de fase

O CKP fornece a posição do virabrequim em uma volta de 360 graus. Para identificar o ciclo completo de um motor quatro tempos, com 720 graus, poderá ser adicionado futuramente um sensor CMP.

Esse sinal permitirá distinguir as fases de compressão e escape e viabilizar a injeção totalmente sequencial dos quatro bicos.

## Próxima etapa

A próxima etapa deste subsistema é:

1. ajustar o `period_counter` para expor `time_since_tooth`;
2. ajustar o `crankshaft_position` para realinhar a contagem com `missing_tooth`;
3. definir o tratamento do período ampliado do gap;
4. criar `engine_position_core.v`;
5. criar `tb_engine_position_core.v`;
6. validar toda a roda 60-2 conectada;
7. somente depois iniciar o `event_scheduler`.