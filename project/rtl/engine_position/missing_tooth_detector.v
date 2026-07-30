//==============================================================================
// Módulo: missing_tooth_detector
//
// Descrição:
// Detecta a região dos dentes faltantes da roda fônica.
//
// O módulo possui dois estados:
//
// ACQUISITION:
// Ainda não possui sincronismo com a roda fônica. O primeiro gap é detectado
// comparando o período atual com o período anterior.
//
// SYNCHRONIZED:
// Após encontrar o primeiro gap, utiliza a média dos últimos quatro dentes
// normais como referência. Períodos correspondentes aos dentes faltantes não
// são adicionados à média.
//
// O filtro de rearmamento impede que variações momentâneas sejam interpretadas
// como múltiplos dentes faltantes consecutivos.
//==============================================================================

module missing_tooth_detector #(
    parameter integer THRESHOLD_NUMERATOR   = 2,
    parameter integer THRESHOLD_DENOMINATOR = 1,
    parameter integer REARM_TEETH           = 4
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] tooth_period,
    input  wire        period_valid,
    output reg         missing_tooth,
    output reg         sync
);

    localparam ACQUISITION  = 1'b0;
    localparam SYNCHRONIZED = 1'b1;

    reg state;

    reg [31:0] previous_period;

    reg [31:0] tooth_period_sample0;
    reg [31:0] tooth_period_sample1;
    reg [31:0] tooth_period_sample2;
    reg [31:0] tooth_period_sample3;

    reg [31:0] normal_teeth_count;

    wire [33:0] sum_periods;

    assign sum_periods = tooth_period_sample0 + tooth_period_sample1 + tooth_period_sample2 + tooth_period_sample3;

    wire [31:0] mean_period;

    assign mean_period = sum_periods >> 2;

    wire [63:0] threshold_value;

    assign threshold_value = (mean_period * THRESHOLD_NUMERATOR) / THRESHOLD_DENOMINATOR;

    always @(posedge clk) begin
        if (rst) begin
            state <= ACQUISITION;
            previous_period <= 32'd0;

            tooth_period_sample0 <= 32'd0;
            tooth_period_sample1 <= 32'd0;
            tooth_period_sample2 <= 32'd0;
            tooth_period_sample3 <= 32'd0;

            normal_teeth_count <= 32'd0;

            missing_tooth <= 1'b0;
            sync <= 1'b0;
        end
        else begin
            missing_tooth <= 1'b0;

            if (period_valid) begin
                case (state)
                    ACQUISITION: begin
                        if (previous_period != 32'd0) begin
                            if (tooth_period > ((previous_period * THRESHOLD_NUMERATOR) / THRESHOLD_DENOMINATOR)) begin

                                missing_tooth <= 1'b1;
                                sync <= 1'b1;

                                state <= SYNCHRONIZED;

                                tooth_period_sample0 <= previous_period;
                                tooth_period_sample1 <= previous_period;
                                tooth_period_sample2 <= previous_period;
                                tooth_period_sample3 <= previous_period;

                                normal_teeth_count <= 32'd0;
                            end
                            else begin
                                previous_period <= tooth_period;
                            end
                        end
                        else begin
                            previous_period <= tooth_period;
                        end
                    end

                    SYNCHRONIZED: begin
                        if (tooth_period > threshold_value[31:0]) begin
                            if (normal_teeth_count >= REARM_TEETH) begin
                                missing_tooth <= 1'b1;
                                normal_teeth_count <= 32'd0;
                            end
                        end
                        else begin
                            if (normal_teeth_count < REARM_TEETH) begin
                                normal_teeth_count <= normal_teeth_count + 1'b1;
                            end

                            tooth_period_sample3 <= tooth_period_sample2;
                            tooth_period_sample2 <= tooth_period_sample1;
                            tooth_period_sample1 <= tooth_period_sample0;
                            tooth_period_sample0 <= tooth_period;
                        end
                    end
                endcase
            end
        end
    end

endmodule