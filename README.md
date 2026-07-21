# ECU-FPGA

Uma ECU automotiva desenvolvida do zero utilizando FPGA como núcleo de tempo real.

O objetivo deste projeto não é apenas controlar um motor, mas desenvolver uma arquitetura modular, escalável e testável que possa evoluir futuramente para uma ECU comercial.

Toda a lógica é desenvolvida inicialmente por simulação, permitindo validação completa antes da integração com hardware.

---

# Filosofia do projeto

O desenvolvimento segue alguns princípios fundamentais:

* Cada módulo possui uma única responsabilidade.
* A lógica de controle é independente do hardware.
* Todo módulo deve possuir testbench próprio.
* A simulação sempre antecede a validação física.
* A arquitetura prioriza clareza em vez de abstrações prematuras.
* Componentes somente serão generalizados quando houver necessidade real de reutilização.

---

# Organização do projeto

```
ecu-fpga/

├── rtl/
├── sim/
├── hardware/
├── docs/
└── software/
```

Cada diretório possui uma responsabilidade bem definida.

---

# rtl/

Contém toda a lógica desenvolvida em Verilog.

Cada módulo representa um bloco funcional da ECU.

```
rtl/

├── common/
├── injector/
├── ignition/
├── crank/
├── engine/
└── top/
```

---

## common/

Biblioteca de componentes reutilizáveis.

Esses módulos não possuem conhecimento sobre motores ou veículos.

Exemplos:

```
common/

counter.v
edge_detector.v
clock_divider.v
debouncer.v
```

Novos componentes somente devem ser adicionados aqui quando forem utilizados por múltiplos módulos da ECU.

---

## injector/

Responsável exclusivamente pelo acionamento dos bicos injetores.

Exemplo de módulos:

```
injector/

injector_controller.v
injector_timer.v
```

Responsabilidades:

* controlar abertura do bico;
* controlar duração da injeção;
* controlar estados internos do injetor;
* futuramente aplicar dead-time e compensações elétricas.

Não realiza cálculo de combustível.

Recebe apenas comandos já calculados.

---

## ignition/

Responsável pelo sistema de ignição.

Exemplo:

```
ignition/

ignition_controller.v
```

Responsabilidades:

* controle do dwell;
* disparo da bobina;
* temporização da ignição.

---

## crank/

Responsável pela leitura da roda fônica.

Exemplo:

```
crank/

crank_decoder.v
```

Responsabilidades:

* detectar dentes;
* detectar dente ausente;
* sincronizar posição do motor;
* fornecer eventos para o gerenciamento do motor.

---

## engine/

Responsável pelo estado interno do motor.

Exemplo:

```
engine/

rpm_calculator.v
sync_manager.v
```

Responsabilidades:

* calcular RPM;
* controlar sincronismo;
* determinar posição angular;
* fornecer informações para os módulos de injeção e ignição.

---

## top/

Integra todos os módulos do projeto.

Exemplo:

```
top/

ecu_top.v
```

Responsabilidades:

* interligar módulos;
* distribuir clocks;
* conectar entradas e saídas;
* representar a ECU completa.

---

# sim/

Todo desenvolvimento deve possuir validação por simulação.

```
sim/

├── testbenches/
├── motor_models/
├── waveforms/
└── regression/
```

---

## testbenches/

Cada módulo do diretório `rtl/` deve possuir seu respectivo testbench.

Exemplo:

```
tb_injector_controller.v
tb_crank_decoder.v
tb_rpm_calculator.v
```

---

## motor_models/

Modelos simplificados do comportamento do motor.

Exemplos futuros:

* gerador de roda fônica;
* simulador de RPM;
* simulador de sensores;
* simulador de bicos.

O objetivo é permitir testes completos sem hardware.

---

## waveforms/

Arquivos de configuração das formas de onda.

Exemplo:

```
*.gtkw
*.do
```

Facilitam depuração durante o desenvolvimento.

---

## regression/

Scripts responsáveis por executar automaticamente todos os testes da ECU.

O objetivo é garantir que novos módulos não introduzam regressões em funcionalidades já implementadas.

---

# hardware/

Toda documentação relacionada ao hardware.

```
hardware/

├── injector_driver/
├── ignition_driver/
├── power_supply/
└── pcb/
```

---

## injector_driver/

Circuito de potência para acionamento dos bicos.

Inclui:

* MOSFET;
* proteção flyback;
* TVS;
* medições;
* esquemáticos.

---

## ignition_driver/

Circuito responsável pelo acionamento da bobina de ignição.

---

## power_supply/

Circuitos de alimentação.

Exemplos:

* entrada automotiva;
* proteção contra inversão de polaridade;
* TVS;
* reguladores;
* filtros.

---

## pcb/

Projeto eletrônico da ECU.

Inclui:

* esquemáticos;
* layout;
* biblioteca de componentes;
* revisões.

---

# docs/

Documentação do projeto.

Exemplos futuros:

* arquitetura da ECU;
* protocolo interno;
* especificação dos módulos;
* requisitos;
* diagramas;
* decisões de projeto.

Todo módulo importante deve possuir documentação correspondente.

---

# software/

Reservado para componentes executados em um microcontrolador externo.

```
software/

future_mcu/
```

Inicialmente permanecerá vazio.

No futuro poderá conter:

* comunicação CAN;
* USB;
* Bluetooth;
* interface gráfica;
* atualização de firmware;
* diagnóstico;
* gerenciamento de mapas.

A FPGA permanecerá responsável apenas pelas tarefas determinísticas e críticas de tempo.

---

# Estratégia de desenvolvimento

O projeto será desenvolvido incrementalmente.

Cada módulo deverá seguir o seguinte fluxo:

```
Especificação

↓

Implementação RTL

↓

Testbench

↓

Simulação

↓

Integração

↓

Hardware
```

Nenhum módulo deverá ser integrado ao hardware antes de possuir validação por simulação.

---

# Objetivo final

Construir uma ECU modular baseada em FPGA que permita evolução contínua, mantendo código organizado, testável e preparado para aplicações reais.
