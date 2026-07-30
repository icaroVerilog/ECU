//==============================================================================
// Módulo: rpm_estimator
//
// Objetivo:
//
// Este módulo calcula a rotação do motor (RPM - Revolutions Per Minute) a partir
// do período medido entre dois dentes consecutivos da roda fônica.
//
// O módulo recebe como entrada a medida gerada pelo `period_counter`, que
// representa quantos ciclos de clock da FPGA ocorreram entre dois eventos de
// passagem de dentes.
//
// A partir dessa informação, utilizando a frequência do clock da FPGA e a
// quantidade de dentes da roda fônica, o módulo calcula o tempo necessário para
// uma revolução completa do virabrequim e converte esse valor para RPM.
//
// A fórmula utilizada é:
//
// RPM = (60 * CLOCK_FREQ) / (tooth_period * TOTAL_TEETH)
//
// Onde:
//
//   CLOCK_FREQ
//       Frequência do clock utilizado como referência de tempo.
//
//   tooth_period
//       Quantidade de ciclos de clock entre dois dentes consecutivos.
//
//   TEETH
//       Quantidade total de posições angulares existentes na roda fônica.
//
// Este módulo não possui conhecimento sobre sincronismo angular, dentes
// faltantes ou posição do motor.
//
// Ele não determina:
//
//   - posição do virabrequim;
//   - PMS dos cilindros;
//   - avanço de ignição;
//   - momento de injeção.
//
// Sua única responsabilidade é transformar uma medida temporal entre dentes em
// uma estimativa da velocidade de rotação do motor.
//
// A saída `rpm_valid` informa aos módulos seguintes que uma nova estimativa de
// rotação foi calculada.
//
// A informação de RPM poderá ser utilizada por outros módulos da ECU, como:
//
//   - scheduler
//       Define eventos dependentes da rotação do motor.
//
//   - fuel_controller
//       Ajusta estratégias de injeção.
//
//   - ignition_controller
//       Define estratégias de ignição.
//
// Este módulo foi desenvolvido de forma independente para permitir futuras
// melhorias, como:
//
//   - filtragem digital do RPM;
//   - média móvel de múltiplas medições;
//   - cálculo de aceleração/desaceleração do motor;
//   - rejeição de medições inválidas causadas por ruído no sensor.
//==============================================================================

module rpm_estimator #(
    parameter CLK_FREQ = 50000000,
    parameter TEETH = 58
)(
    input wire clk,
    input wire rst,

    input wire [31:0] tooth_period,
    input wire tooth_period_valid,

    output reg [31:0] rpm,
    output reg rpm_valid
);

    reg [63:0] numerator;
    reg [63:0] denominator;

    always @(posedge clk) begin
        if(rst) begin
            rpm <= 0;
            rpm_valid <= 0;
        end
        else begin
            rpm_valid <= 0;

            if(tooth_period_valid) begin

                /*
                    Cálculo do RPM a partir do período entre dentes.
                    A multiplicação por 60 é feita para converter de revoluções
                    por segundo para revoluções por minuto.
                    A divisão é feita utilizando números de 64 bits para evitar
                    estouro de capacidade durante a multiplicação.

                */

                numerator = 64'd60 * CLK_FREQ;
                denominator = tooth_period * TEETH;

                if(denominator != 0) begin
                    rpm <= numerator / denominator;
                    rpm_valid <= 1;
                end
            end
        end
    end
endmodule


// Fórmula:
//
// RPM = (60 * CLK_FREQ) / (tooth_period * TEETH)
//
// Onde:
//
// CLK_FREQ:
//     Frequência do clock da FPGA em ciclos por segundo.
//
// tooth_period:
//     Quantidade de ciclos de clock entre dois dentes consecutivos.
//
// TEETH:
//     Quantidade de dentes reais da roda fônica em uma revolução.
//
// Derivação:
//
// Tempo entre dentes:
//
//     T_dente = tooth_period / CLK_FREQ
//
//
// Tempo de uma revolução:
//
//     T_rev = T_dente * TEETH
//
//     T_rev = (tooth_period * TEETH) / CLK_FREQ
//
//
// Conversão para rotações por segundo:
//
//     RPS = 1 / T_rev
//
//     RPS = CLK_FREQ / (tooth_period * TEETH)
//
//
// Conversão para rotações por minuto:
//
//     RPM = RPS * 60
//
//     RPM = (60 * CLK_FREQ) / (tooth_period * TEETH)