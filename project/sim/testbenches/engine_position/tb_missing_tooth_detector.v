`timescale 1ns/1ps

module tb_missing_tooth_detector;

    reg clk;
    reg rst;
    reg [31:0] tooth_period;
    reg period_valid;

    wire missing_tooth;
    wire sync;

    missing_tooth_detector #(
        .THRESHOLD_NUMERATOR(2),
        .THRESHOLD_DENOMINATOR(1),
        .REARM_TEETH(4)
    ) dut (
        .clk(clk),
        .rst(rst),
        .tooth_period(tooth_period),
        .period_valid(period_valid),
        .missing_tooth(missing_tooth),
        .sync(sync)
    );

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    task send_period;
        input [31:0] period;
        begin
            @(posedge clk);

            tooth_period <= period;
            period_valid <= 1'b1;

            @(posedge clk);

            period_valid <= 1'b0;
            tooth_period <= 32'd0;
        end
    endtask

    task send_noisy_period;
        input [31:0] base_period;

        integer noise;
        integer final_period;

        begin
            noise = ($random % 11) - 5;
            final_period = base_period + noise;

            send_period(final_period);
        end
    endtask

    task send_normal_tooths;
        input integer count;
        input [31:0] period;

        integer i;

        begin
            for (i = 0; i < count; i = i + 1) begin
                send_period(period);

                @(posedge clk);
                @(posedge clk);
            end
        end
    endtask

    task send_noisy_tooths;
        input integer count;
        input [31:0] period;

        integer i;

        begin
            for (i = 0; i < count; i = i + 1) begin
                send_noisy_period(period);

                @(posedge clk);
                @(posedge clk);
            end
        end
    endtask

    task simulate_60_2_rotation;
        input [31:0] period;

        integer i;

        begin
            for (i = 0; i < 58; i = i + 1) begin
                send_period(period);

                @(posedge clk);
                @(posedge clk);
            end

            send_period(period * 3);

            @(posedge clk);
            @(posedge clk);
        end
    endtask

    task simulate_noisy_60_2_rotation;
        input [31:0] period;

        integer i;

        begin
            for (i = 0; i < 58; i = i + 1) begin
                send_noisy_period(period);

                @(posedge clk);
                @(posedge clk);
            end

            send_period(period * 3);

            @(posedge clk);
            @(posedge clk);
        end
    endtask

    initial begin
        rst = 1'b1;

        tooth_period = 32'd0;
        period_valid = 1'b0;

        repeat(5)
            @(posedge clk);

        rst = 1'b0;

        $display("============================================");
        $display("SIMULACAO DETECTOR RODA FONICA 60-2");
        $display("============================================");

        $display("TESTE 1 - Aquisicao inicial");
        simulate_60_2_rotation(32'd100);

        $display("TESTE 2 - Marcha lenta");

        simulate_60_2_rotation(32'd100);
        simulate_60_2_rotation(32'd100);

        $display("TESTE 3 - Aceleracao");

        simulate_60_2_rotation(32'd80);
        simulate_60_2_rotation(32'd60);

        $display("TESTE 4 - Alta rotacao");

        simulate_60_2_rotation(32'd40);

        $display("TESTE 5 - Desaceleracao");

        simulate_60_2_rotation(32'd70);
        simulate_60_2_rotation(32'd100);

        $display("TESTE 6 - Roda 60-2 com ruido mecanico");

        simulate_noisy_60_2_rotation(32'd100);

        $display("TESTE 7 - Variacao forte de RPM com ruido");

        simulate_noisy_60_2_rotation(32'd80);
        simulate_noisy_60_2_rotation(32'd50);
        simulate_noisy_60_2_rotation(32'd100);

        $display("TESTE 8 - Falso gap pequeno");

        send_period(32'd100);
        send_period(32'd100);
        send_period(32'd130);
        send_period(32'd100);
        send_period(32'd100);

        $display("TESTE 9 - Pulso espurio");

        send_period(32'd100);
        send_period(32'd100);
        send_period(32'd20);
        send_period(32'd100);
        send_period(32'd100);

        $display("TESTE 10 - Reset durante funcionamento");

        simulate_60_2_rotation(32'd100);

        rst = 1'b1;

        repeat(5)
            @(posedge clk);

        rst = 1'b0;

        simulate_60_2_rotation(32'd100);

        repeat(20)
            @(posedge clk);

        $display("============================================");
        $display("SIMULACAO FINALIZADA");
        $display("============================================");

        $finish;
    end

    initial begin
        $display("-----------------------------------------------");
        $display(" Tempo(ns) | Periodo | Valid | Missing | Sync | Estado");
        $display("-----------------------------------------------");

        forever begin
            @(posedge clk);

            if (period_valid || missing_tooth) begin
                $display("%10t | %7d |   %b   |    %b    |  %b  | %s",
                    $time,
                    tooth_period,
                    period_valid,
                    missing_tooth,
                    sync,
                    dut.state ? "SYNC" : "ACQ"
                );
            end

            if (missing_tooth)
                $display(">>> GAP 60-2 DETECTADO <<<");
        end
    end

    initial begin
        $dumpfile("tb_missing_tooth_detector.vcd");
        $dumpvars(0,tb_missing_tooth_detector);
    end

endmodule