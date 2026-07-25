// module crankshaft_position #(
//     parameter TOTAL_TEETH = 60,
//     parameter PHYSICAL_TEETH = 58
// )(
//     input wire clk,
//     input wire rst,
//     input wire tooth_rise,
//     input wire sync,

//     output reg [$clog2(PHYSICAL_TEETH)-1:0] tooth_number,
//     output reg [8:0] crankshaft_angle,
//     output reg position_valid
// );

//     reg sync_active;

//     always @(posedge clk) begin
//         if (rst) begin
//             tooth_number <= 0;
//             crankshaft_angle <= 0;
//             position_valid <= 0;
//             sync_active <= 0;

//         end else begin
//             /*
//              * Quando o sincronismo é encontrado, a ECU passa a conhecer a referência angular da roda fônica.
//              * O sincronismo não deve zerar o contador de dentes, pois a contagem representa a posição atual do
//              * virabrequim após a referência ser encontrada.
//              */
//             if (sync) begin
//                 sync_active <= 1;
//             end
//             /*
//              * Antes do sincronismo ser encontrado, a ECU não sabe a posição absoluta do virabrequim.
//              */
//             if (!sync_active) begin
//                 position_valid <= 0;
//             end 
//             else begin
//                 position_valid <= 1;
//                 if (tooth_rise) begin
//                     if (tooth_number < PHYSICAL_TEETH-1) begin
//                         tooth_number <= tooth_number + 1;
//                     end
//                     else begin
//                         tooth_number <= 0;
//                     end


//                     /*
//                      * Converte o número do dente em posição angular. Uma roda 60-2 possui:
//                      * 360 graus / 60 posições = 6 graus
//                      * Mesmo existindo somente 58 dentes físicos,
//                      * a referência angular continua sendo baseada
//                      * nas 60 posições da roda.
//                      */
//                     if (tooth_number < PHYSICAL_TEETH-1) begin
//                         crankshaft_angle <= (tooth_number + 1) * (360 / TOTAL_TEETH);
//                     end
//                     else begin
//                         crankshaft_angle <= 0;
//                     end
//                 end
//             end
//         end
//     end
// endmodule



//==============================================================================
// Módulo: crankshaft_position
//
// Descrição:
// Mantém o sincronismo da roda fônica após a detecção do dente ausente.
//
// Sua única responsabilidade é informar qual dente físico está passando pelo
// sensor CKP.
//
// A conversão da posição do dente em ângulo absoluto é realizada pelo módulo
// angle_interpolator.
//==============================================================================

module crankshaft_position #(
    parameter TOTAL_TEETH = 60,
    parameter PHYSICAL_TEETH = 58
)(
    input wire clk,
    input wire rst,
    input wire tooth_rise,
    input wire sync,

    output reg [$clog2(PHYSICAL_TEETH)-1:0] tooth_number,
    output reg position_valid
);

    reg sync_active;

    always @(posedge clk) begin
        if (rst) begin
            tooth_number <= 0;
            position_valid <= 0;
            sync_active <= 0;
        end else begin
            /*
             * Quando o sincronismo é encontrado, a ECU passa a conhecer
             * a posição absoluta da roda fônica.
             */
            if (sync) begin
                sync_active <= 1;
            end
            /*
             * Antes do sincronismo, a posição do dente não é válida.
             */
            if (!sync_active) begin
                position_valid <= 0;
            end
            else begin
                position_valid <= 1;
                /*
                 * Cada borda de subida representa a passagem de um
                 * novo dente físico.
                 */
                if (tooth_rise) begin
                    if (tooth_number < PHYSICAL_TEETH-1) begin
                        tooth_number <= tooth_number + 1;
                    end
                    else begin
                        tooth_number <= 0;
                    end
                end
            end
        end
    end
endmodule