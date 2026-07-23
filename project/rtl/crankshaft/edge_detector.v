//==============================================================================
// Módulo: edge_detector
//
// Descrição:
// Detecta as bordas de subida e de descida do sinal CKP (Crankshaft Position
// Sensor - Sensor de posição do virabrequim).
//
// Para cada transição detectada, gera um pulso com duração de um único ciclo
// de clock.
//
// Entradas:
//   clk     - Clock do sistema.
//   rst     - Reset síncrono.
//   ckp_in  - Sinal digital proveniente do sensor CKP.
//
// Saídas:
//   tooth_rise - Pulso de um clock na borda de subida.
//   tooth_fall - Pulso de um clock na borda de descida.
//==============================================================================

module edge_detector (
    input wire clk,
    input wire rst,
    input wire ckp_in, // crankshaft position signal input (sinal de posição do virabrequim)
    output reg tooth_rise,
    /*
        Atualmente não utilizado.
        Reservado para futuras implementações como:
        - diagnóstico do CKP;
        - medição da largura do pulso;
        - aumento da resolução angular.
    */
    output reg tooth_fall
);

    reg ckp_in_prev;

    always @(posedge clk) begin
        if (rst) begin
            tooth_rise <= 1'b0;
            tooth_fall <= 1'b0;
            ckp_in_prev <= 1'b0;
        end else begin
            tooth_rise <=  ckp_in & ~ckp_in_prev;
            tooth_fall <= ~ckp_in &  ckp_in_prev;

            ckp_in_prev <= ckp_in;
        end
    end

endmodule