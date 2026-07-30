`timescale 1ns/1ps

module tb_rpm_estimator;

    //==========================================================================
    // Clock e sinais de entrada
    //==========================================================================

    reg clk;
    reg rst;

    reg [31:0] tooth_period;
    reg        tooth_period_valid;


    //==========================================================================
    // Saídas do DUT (Device Under Test - Dispositivo em Teste)
    //==========================================================================

    wire [31:0] rpm;
    wire        rpm_valid;


    //==========================================================================
    // Instância do módulo
    //==========================================================================

    rpm_estimator #(
        .CLK_FREQ(50000000),
        .TEETH(58)
    ) dut (
        .clk(clk),
        .rst(rst),

        .tooth_period(tooth_period),
        .tooth_period_valid(tooth_period_valid),

        .rpm(rpm),
        .rpm_valid(rpm_valid)
    );


    //==========================================================================
    // Clock de 50 MHz
    // Período = 20 ns
    //==========================================================================

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end


    //==========================================================================
    // Gera uma nova medição de período
    //
    // Simula uma nova saída do period_counter.
    //
    // period:
    // quantidade de ciclos entre dentes.
    //
    //==========================================================================

    task send_period(input [31:0] period);
    begin

        @(posedge clk);

        tooth_period <= period;
        tooth_period_valid <= 1'b1;

        @(posedge clk);

        tooth_period_valid <= 1'b0;

    end
    endtask


    //==========================================================================
    // Simula funcionamento do motor em uma determinada rotação
    //
    // Cada chamada representa várias medições consecutivas do CKP.
    //
    //==========================================================================

    task simulate_rpm(
        input [31:0] period,
        input integer samples
    );

    integer i;

    begin

        for(i = 0; i < samples; i = i + 1) begin

            repeat(period) @(posedge clk);

            send_period(period);

        end

    end

    endtask


    //==========================================================================
    // Estímulos
    //==========================================================================

    initial begin

        rst = 1'b1;

        tooth_period = 32'd0;
        tooth_period_valid = 1'b0;


        // Reset

        repeat(5) @(posedge clk);

        rst = 1'b0;



        //==============================================================
        // Motor em baixa rotação
        //
        // Aproximadamente 500 RPM
        //
        // RPM =
        //
        // 60*50MHz
        // ------------
        // 100000*58
        //
        //==============================================================

        simulate_rpm(100000, 5);



        //==============================================================
        // Marcha lenta
        //
        // Aproximadamente 1000 RPM
        //
        //==============================================================

        simulate_rpm(51724, 10);



        //==============================================================
        // Aceleração intermediária
        //
        // Aproximadamente 2000 RPM
        //
        //==============================================================

        simulate_rpm(25862, 10);



        //==============================================================
        // Motor em 3000 RPM
        //
        //==============================================================

        simulate_rpm(17241, 10);



        //==============================================================
        // Alta rotação
        //
        // Aproximadamente 6000 RPM
        //
        //==============================================================

        simulate_rpm(8620, 10);



        //==============================================================
        // Teste de período inválido
        //
        // Não deve atualizar RPM
        //
        //==============================================================

        send_period(0);



        repeat(20) @(posedge clk);


        $finish;

    end


    //==========================================================================
    // Monitor
    //==========================================================================

    initial begin

        $display("----------------------------------------------");
        $display(" Time(ns) | Tooth Period | RPM | Valid");
        $display("----------------------------------------------");

        forever begin

            @(posedge clk);

            if(rpm_valid) begin

                $display(
                    "%8t | %12d | %4d |   %b",
                    $time,
                    tooth_period,
                    rpm,
                    rpm_valid
                );

            end

        end

    end


    //==========================================================================
    // Arquivo VCD para GTKWave
    //==========================================================================

    initial begin

        $dumpfile("tb_rpm_estimator.vcd");
        $dumpvars(0, tb_rpm_estimator);

    end


endmodule