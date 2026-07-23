//==============================================================================
// Módulo: period_counter
//
// Objetivo:
//
// O objetivo deste módulo é medir o intervalo de tempo entre dois dentes
// consecutivos da roda fônica.
//
// O módulo recebe como entrada o pulso `tooth_rise`, gerado pelo
// `edge_detector`, que representa a passagem de um dente pelo sensor CKP
// (Crankshaft Position Sensor - Sensor de posição do virabrequim).
//
// Internamente, um contador é incrementado a cada ciclo de clock da FPGA.
// Quando um novo pulso `tooth_rise` é detectado, o valor acumulado pelo
// contador representa exatamente quantos ciclos de clock transcorreram desde a
// passagem do dente anterior.
//
// Esse valor é disponibilizado na saída `tooth_period`, enquanto a saída
// `period_valid` gera um pulso de um único ciclo de clock indicando aos módulos
// seguintes que uma nova medição foi concluída e está pronta para ser utilizada.
//
// Este módulo não interpreta o valor medido. Ele não calcula a rotação do
// motor, não detecta dentes faltantes, não determina a posição angular do
// virabrequim e não toma qualquer decisão sobre o funcionamento da ECU.
//
// Sua única responsabilidade é atuar como um cronômetro de alta resolução,
// convertendo a sequência de pulsos gerada pelo sensor em uma medida precisa do
// tempo entre dentes consecutivos.
//
// Essa informação é utilizada por diversos módulos da ECU, como:
//
//   - rpm_estimator
//       Calcula a rotação do motor a partir do período entre dentes.
//
//   - missing_tooth_detector
//       Detecta a região dos dentes ausentes comparando o período entre dentes
//       consecutivos.
//
//   - angle_interpolator
//       Estima o ângulo do virabrequim entre dois dentes utilizando o período
//       medido como referência.
//
// Ao concentrar toda a medição de tempo em um único módulo, evita-se que cada
// componente da ECU implemente seu próprio contador, reduzindo duplicação de
// lógica, simplificando a arquitetura e garantindo que todos os cálculos do
// sistema utilizem exatamente a mesma referência temporal.
//==============================================================================

module period_counter (
    input wire clk,
    input wire rst,
    input wire tooth_rise,
    output reg [31:0] tooth_period,
    output reg        period_valid
);

    reg [31:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            counter <= 32'd0;
            tooth_period <= 32'd0;
            period_valid <= 1'b0;
        end else begin
            if (tooth_rise) begin
                tooth_period <= counter - 1'b1; // Subtrai 1 para compensar o ciclo de clock do pulso tooth_rise
                period_valid <= 1'b1;
                counter <= 32'd0;
            end else begin
                period_valid <= 1'b0;
                counter <= counter + 1'b1;
            end
        end
    end
endmodule