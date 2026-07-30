//==============================================================================
// Modulo: missing_tooth_detector
//
// Descricao:
// Detecta a regiao dos dentes ausentes de uma roda fonica do tipo missing
// tooth, como a 60-2.
//
// Durante a aquisicao, o periodo atual e comparado com o periodo anterior.
// Depois do sincronismo, a referencia passa a ser a media dos quatro ultimos
// periodos normais.
//
// O modulo tambem publica normal_tooth_period. Essa saida representa o periodo
// esperado entre duas posicoes angulares consecutivas da roda e nao e
// contaminada pelo intervalo maior da falha. Ela deve ser usada pelo calculo
// de RPM e pela interpolacao angular.
//
// Condicao de deteccao:
//
// tooth_period > reference_period * THRESHOLD_NUMERATOR
//                ---------------------------------------
//                       THRESHOLD_DENOMINATOR
//
// Para evitar divisao e truncamento, a comparacao e reorganizada:
//
// tooth_period * THRESHOLD_DENOMINATOR
//     >
// reference_period * THRESHOLD_NUMERATOR
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
    output reg         sync,
    output reg  [31:0] normal_tooth_period,
    output reg         normal_period_valid
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
    wire [31:0] mean_period;
    wire [63:0] acquisition_current_scaled;
    wire [63:0] acquisition_previous_scaled;
    wire [63:0] synchronized_current_scaled;
    wire [63:0] synchronized_reference_scaled;
    wire [33:0] next_normal_sum;

    // Soma os quatro ultimos periodos normais sem perder bits no resultado.
    assign sum_periods = {2'b00, tooth_period_sample0} + {2'b00, tooth_period_sample1} + {2'b00, tooth_period_sample2} + {2'b00, tooth_period_sample3};

    // Divide a soma por quatro para obter a media dos periodos normais.
    assign mean_period = sum_periods >> 2;

    // Multiplica o periodo atual pelo denominador do limite de deteccao.
    assign acquisition_current_scaled = {32'd0, tooth_period} * THRESHOLD_DENOMINATOR;

    // Multiplica o periodo anterior pelo numerador do limite de deteccao.
    assign acquisition_previous_scaled = {32'd0, previous_period} * THRESHOLD_NUMERATOR;

    // Multiplica o periodo atual pelo denominador durante o sincronismo.
    assign synchronized_current_scaled = {32'd0, tooth_period} * THRESHOLD_DENOMINATOR;

    // Multiplica a media normal pelo numerador durante o sincronismo.
    assign synchronized_reference_scaled = {32'd0, mean_period} * THRESHOLD_NUMERATOR;

    // Soma o periodo atual aos tres periodos normais mais recentes.
    assign next_normal_sum = {2'b00, tooth_period} + {2'b00, tooth_period_sample0} + {2'b00, tooth_period_sample1} + {2'b00, tooth_period_sample2};

    always @(posedge clk) begin
        if (rst) begin
            state                <= ACQUISITION;
            previous_period      <= 32'd0;
            tooth_period_sample0 <= 32'd0;
            tooth_period_sample1 <= 32'd0;
            tooth_period_sample2 <= 32'd0;
            tooth_period_sample3 <= 32'd0;
            normal_teeth_count   <= 32'd0;
            missing_tooth        <= 1'b0;
            sync                 <= 1'b0;
            normal_tooth_period  <= 32'd0;
            normal_period_valid  <= 1'b0;
        end
        else begin
            // As saidas de evento permanecem ativas por apenas um ciclo.
            missing_tooth       <= 1'b0;
            normal_period_valid <= 1'b0;

            if (period_valid && (tooth_period != 32'd0)) begin
                case (state)
                    ACQUISITION: begin
                        // Compara o periodo atual com o anterior sem realizar divisao.
                        if ((previous_period != 32'd0) && (acquisition_current_scaled > acquisition_previous_scaled)) begin
                            missing_tooth <= 1'b1;
                            sync          <= 1'b1;
                            state         <= SYNCHRONIZED;

                            // O periodo anterior ao gap inicializa a janela
                            // com uma referencia conhecida como normal.
                            tooth_period_sample0 <= previous_period;
                            tooth_period_sample1 <= previous_period;
                            tooth_period_sample2 <= previous_period;
                            tooth_period_sample3 <= previous_period;

                            normal_tooth_period <= previous_period;
                            normal_period_valid <= 1'b1;
                            normal_teeth_count  <= 32'd0;
                        end
                        else begin
                            // Enquanto nao houver gap, o periodo atual se
                            // torna a referencia da proxima comparacao.
                            previous_period     <= tooth_period;
                            normal_tooth_period <= tooth_period;
                            normal_period_valid <= 1'b1;
                        end
                    end

                    SYNCHRONIZED: begin
                        // Detecta um periodo maior que o limite calculado
                        // sobre a media dos quatro ultimos periodos normais.
                        if (synchronized_current_scaled > synchronized_reference_scaled) begin
                            // Exige dentes normais antes de permitir uma
                            // nova deteccao da falha.
                            if (normal_teeth_count >= REARM_TEETH) begin
                                missing_tooth      <= 1'b1;
                                normal_teeth_count <= 32'd0;
                            end
                        end
                        else begin
                            // Rearma gradualmente o detector depois do gap.
                            if (normal_teeth_count < REARM_TEETH) begin
                                normal_teeth_count <= normal_teeth_count + 32'd1;
                            end

                            // Desloca a janela e adiciona o periodo normal atual.
                            tooth_period_sample3 <= tooth_period_sample2;
                            tooth_period_sample2 <= tooth_period_sample1;
                            tooth_period_sample1 <= tooth_period_sample0;
                            tooth_period_sample0 <= tooth_period;

                            // Divide por quatro a soma da nova janela de periodos.
                            normal_tooth_period <= next_normal_sum >> 2;
                            normal_period_valid <= 1'b1;
                            previous_period     <= tooth_period;
                        end
                    end

                    default: begin
                        state <= ACQUISITION;
                    end
                endcase
            end
        end
    end

endmodule