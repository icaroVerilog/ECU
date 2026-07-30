`timescale 1ns/1ps

module tb_crankshaft_position;

    parameter CLK_PERIOD = 20;

    reg clk;
    reg rst;
    reg tooth_rise;
    reg sync;

    wire [5:0] tooth_number;
    wire [8:0] crankshaft_angle;
    wire position_valid;


    crankshaft_position dut (
        .clk(clk),
        .rst(rst),
        .tooth_rise(tooth_rise),
        .sync(sync),
        .tooth_number(tooth_number),
        .crankshaft_angle(crankshaft_angle),
        .position_valid(position_valid)
    );


    always #(CLK_PERIOD/2) clk = ~clk;


    task send_tooth;
        begin
            tooth_rise = 1;
            #(CLK_PERIOD);
            tooth_rise = 0;
            #(CLK_PERIOD);
        end
    endtask


    initial begin

        $dumpfile("tb_crankshaft_position.vcd");
        $dumpvars(0, tb_crankshaft_position);


        clk = 0;
        rst = 1;
        tooth_rise = 0;
        sync = 0;


        #(CLK_PERIOD*5);


        /*
         * Remove reset
         */
        rst = 0;


        /*
         * Sem sincronismo:
         * A posição deve permanecer inválida.
         */
        #(CLK_PERIOD*5);


        /*
         * Simula detecção da falha dos dentes.
         *
         * A partir deste ponto a ECU sabe
         * a referência angular.
         */
        sync = 1;


        #(CLK_PERIOD*5);


        /*
         * Simula os 58 dentes físicos
         * de uma roda 60-2.
         */
        repeat(58) begin
            send_tooth;

            $display(
                "Time=%0t | Tooth=%0d | Angle=%0d | Valid=%b",
                $time,
                tooth_number,
                crankshaft_angle,
                position_valid
            );
        end


        /*
         * Segunda volta:
         * verifica se o contador retorna para zero.
         */
        repeat(5) begin
            send_tooth;

            $display(
                "Time=%0t | Tooth=%0d | Angle=%0d | Valid=%b",
                $time,
                tooth_number,
                crankshaft_angle,
                position_valid
            );
        end


        #(CLK_PERIOD*10);


        $finish;

    end

endmodule