//==============================================================================
// Modulo: engine_position_core
//
// Descricao:
// Integra toda a cadeia responsavel pela aquisicao da velocidade e da posicao
// angular do virabrequim.
//
// Este modulo nao refaz calculos. Ele apenas instancia os blocos especializados,
// conecta suas interfaces, concentra parametros da roda e expoe uma interface
// unica para o restante da ECU.
//==============================================================================

module engine_position_core #(
    parameter integer CLOCK_FREQ            = 50000000,
    parameter integer TOTAL_TEETH           = 60,
    parameter integer PHYSICAL_TEETH        = 58,
    parameter integer ANGLE_BITS            = 16,
    parameter integer ANGLE_PER_TOOTH       = 1092,
    parameter integer THRESHOLD_NUMERATOR   = 2,
    parameter integer THRESHOLD_DENOMINATOR = 1,
    parameter integer REARM_TEETH           = 4
)(
    input  wire clk,
    input  wire rst,
    input  wire ckp_signal,

    output wire synchronized,
    output wire missing_tooth,
    output wire position_valid,
    output wire angle_valid,
    output wire rpm_valid,

    output wire [$clog2(PHYSICAL_TEETH)-1:0] tooth_number,
    output wire [ANGLE_BITS-1:0]             crankshaft_angle,
    output wire [31:0]                       rpm,

    // Saidas de diagnostico utilizadas pela simulacao e por futuras rotinas
    // de monitoramento.
    output wire        tooth_rise,
    output wire        tooth_fall,
    output wire [31:0] tooth_period,
    output wire        tooth_period_valid,
    output wire [31:0] normal_tooth_period,
    output wire        normal_period_valid,
    output wire [31:0] time_since_tooth
);

    wire rpm_period_valid;
    wire [15:0] tooth_number_for_interpolator;

    assign rpm_period_valid = normal_period_valid & synchronized;
    assign tooth_number_for_interpolator = tooth_number;

    edge_detector edge_detector_inst (
        .clk(clk),
        .rst(rst),
        .ckp_in(ckp_signal),
        .tooth_rise(tooth_rise),
        .tooth_fall(tooth_fall)
    );

    period_counter period_counter_inst (
        .clk(clk),
        .rst(rst),
        .tooth_rise(tooth_rise),
        .tooth_period(tooth_period),
        .period_valid(tooth_period_valid),
        .time_since_tooth(time_since_tooth)
    );

    missing_tooth_detector #(
        .THRESHOLD_NUMERATOR(THRESHOLD_NUMERATOR),
        .THRESHOLD_DENOMINATOR(THRESHOLD_DENOMINATOR),
        .REARM_TEETH(REARM_TEETH)
    ) missing_tooth_detector_inst (
        .clk(clk),
        .rst(rst),
        .tooth_period(tooth_period),
        .period_valid(tooth_period_valid),
        .missing_tooth(missing_tooth),
        .sync(synchronized),
        .normal_tooth_period(normal_tooth_period),
        .normal_period_valid(normal_period_valid)
    );

    rpm_estimator #(
        .CLK_FREQ(CLOCK_FREQ),
        .TEETH(TOTAL_TEETH)
    ) rpm_estimator_inst (
        .clk(clk),
        .rst(rst),
        .tooth_period(normal_tooth_period),
        .tooth_period_valid(rpm_period_valid),
        .rpm(rpm),
        .rpm_valid(rpm_valid)
    );

    crankshaft_position #(
        .TOTAL_TEETH(TOTAL_TEETH),
        .PHYSICAL_TEETH(PHYSICAL_TEETH)
    ) crankshaft_position_inst (
        .clk(clk),
        .rst(rst),
        .tooth_rise(tooth_rise),
        .sync(synchronized),
        .missing_tooth(missing_tooth),
        .tooth_number(tooth_number),
        .position_valid(position_valid)
    );

    angle_interpolator #(
        .ANGLE_BITS(ANGLE_BITS),
        .TIME_BITS(32),
        .ANGLE_PER_TOOTH(ANGLE_PER_TOOTH)
    ) angle_interpolator_inst (
        .clk(clk),
        .rst(rst),
        .tooth_number(tooth_number_for_interpolator),
        .tooth_period(normal_tooth_period),
        .time_since_tooth(time_since_tooth),
        .position_valid(position_valid),
        .interpolated_angle(crankshaft_angle),
        .angle_valid(angle_valid)
    );

endmodule
