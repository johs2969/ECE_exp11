`timescale 1us / 1ps

module DAC_tb();

reg clk,rst;
reg [5:0] btn;
reg add_sel;
wire dac_csn, dac_ldacn, dac_wrn, dac_a_b;
wire [7:0] dac_d, led_out;

DAC u1(.clk(clk), .rst(rst), .btn(btn), .add_sel(add_sel), .dac_csn(dac_csn), .dac_ldacn(dac_ldacn), .dac_wrn(dac_wrn), .dac_a_b(dac_a_b), .dac_d(dac_d), .led_out(led_out));

always begin
    #0.6 clk <=~clk;
end

initial begin
    clk =0;
    rst =1;
    btn =0;
    add_sel =0;
    #100 rst =0;
    #100 rst =1;
    #12 btn =6'b000100;
    #1000 btn =6'b001000;
    #1000 btn =6'b000001;
    #1000 btn =6'b000010;
    #1000 btn =6'b010000;
    #1000 btn =6'b100000;
    #1000;
    
    $stop;
end        

endmodule
