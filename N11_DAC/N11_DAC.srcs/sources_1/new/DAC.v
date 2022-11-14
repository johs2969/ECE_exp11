`timescale 1ns / 1ps

module DAC(clk, rst, btn, add_sel, dac_csn, dac_ldacn, dac_wrn, dac_a_b, dac_d, led_out, seg_data, seg_sel, LCD_E, LCD_RS, LCD_RW, LCD_DATA );

// DAC

input clk,rst;
input [5:0] btn;
input add_sel;
output reg dac_csn, dac_ldacn, dac_wrn, dac_a_b;
output reg [7:0] dac_d, led_out;

reg [7:0] dac_d_temp, cnt;
reg [1:0] state;
wire [5:0] btn_t;

parameter DELAY = 2'b00,
          SET_WRN = 2'b01,
          UP_DATA = 2'b10;
          
 oneshot_universal #(.width(6)) uu1(.clk(clk), .rst(rst), .btn({btn[5:0]}), .btn_trig({btn_t[5:0]})); 
 
 always @(posedge clk or negedge rst) begin
    if(!rst) begin
        state <= DELAY;
        cnt <= 8'b0000_0000;
        dac_wrn <=1;
    end
    else begin
        case(state)
            DELAY : begin
                if(cnt == 200) state <= SET_WRN;
                if(cnt >= 200) cnt <=0;
                else cnt <= cnt+1;
                dac_wrn <= 1;
                end
            SET_WRN : begin
                if(cnt == 50) state <= UP_DATA;
                if(cnt >= 50) cnt <=0;
                else cnt <= cnt+1;
                dac_wrn <= 0;
                end
            UP_DATA : begin
                if(cnt == 30) state <= DELAY;
                if(cnt >= 30) cnt <=0;
                else cnt <= cnt+1;  
                dac_d <= dac_d_temp;
                end          
            endcase
        end
  end          

always @(posedge clk or negedge rst) begin
    if(!rst) begin
        dac_d_temp <=8'b0000_0000;
        led_out <=8'b0101_0101;
     end
     else begin if(|btn_t) begin
        if(btn ==6'b100000)  dac_d_temp = dac_d_temp -8'b0000_0001;
        else if(btn ==6'b010000)  dac_d_temp = dac_d_temp +8'b0000_0001;
        else if(btn ==6'b001000)  dac_d_temp = dac_d_temp -8'b0000_0010;
        else if(btn ==6'b000100)  dac_d_temp = dac_d_temp +8'b0000_0010;
        else if(btn ==6'b000010)  dac_d_temp = dac_d_temp -8'b0000_1000;
        else if(btn ==6'b000001)  dac_d_temp = dac_d_temp +8'b0000_1000;
       led_out = dac_d_temp;
        end
     end
 end       
 
 always @(posedge clk) begin
    dac_csn <=0;
    dac_ldacn <=0;
    dac_a_b <= add_sel; //0 :select A, 1:select B
 end   
 
 // 7 segment  

wire [11:0] bcd;
reg [3:0] display_bcd;

output reg [7:0] seg_data;
output reg [7:0] seg_sel;

bin22bcd b1 (.clk(clk), .rst(rst), .bin(dac_d_temp), .bcd_out(bcd));

always @(posedge clk or negedge rst) begin
    if(!rst) seg_sel <=8'b11111110;
    else begin
        seg_sel <={seg_sel[6:0],seg_sel[7]};
        end
    end         

always @(*) begin
    case(display_bcd [3:0])
        0 :seg_data = 8'b11111100;
        1 :seg_data = 8'b01100000;
        2 :seg_data = 8'b11011010;
        3 :seg_data = 8'b11110010;
        4 :seg_data = 8'b01100110;
        5 :seg_data = 8'b10110110;
        6 :seg_data = 8'b10111110;
        7 :seg_data = 8'b11100000;
        8 :seg_data = 8'b11111110;
        9 :seg_data = 8'b11110110;
        default seg_data = 8'b00000000;
    endcase
end

always @(*) begin
    case(seg_sel)
        8'b11111110 :display_bcd = bcd[3:0];
        8'b11111101 :display_bcd = bcd[7:4];
        8'b11111011 :display_bcd = bcd[11:8];
        8'b11110111 :display_bcd = 4'b0000;
        8'b11101111 :display_bcd = 4'b0000;
        8'b11011111 :display_bcd = 4'b0000;
        8'b10111111 :display_bcd = 4'b0000;
        8'b01111111 :display_bcd = 4'b0000;
        default display_bcd=4'b0000;
    endcase
 end
      
 //text LCD
      
output LCD_E;
output reg LCD_RS, LCD_RW;
output reg [7:0] LCD_DATA;

reg [3:0] state2 = 4'b0011;
parameter DELAY2 =4'b0011,
          FUNCTION_SET =4'b0100,
          ENTRY_MODE =4'b0101,
          DISP_ONOFF =4'b0110,
          LINE1 =4'b0111,
          DELAY_T =4'b1000,
          CLEAR_DISP =4'b1001;
          
 integer ccnt;               
          
always @(posedge clk or negedge rst)
begin
    if(!rst) begin
        state2 <= DELAY2;
        ccnt <=0;
        end
    else
    begin
        case(state2)
        DELAY2 :begin
            if(ccnt >=70) ccnt <= 0;
            else ccnt <= ccnt+1;
            if(ccnt == 70) state2 = FUNCTION_SET;
        end
        FUNCTION_SET :begin
            if(ccnt >=30) ccnt <= 0;
            else ccnt <= ccnt+1;
            if(ccnt == 30) state2 <= DISP_ONOFF;
        end
        DISP_ONOFF :begin
            if(ccnt >=30) ccnt <= 0;
            else ccnt <= ccnt+1;
            if(ccnt == 30) state2 <= ENTRY_MODE;
        end
        ENTRY_MODE :begin
            if(ccnt >=30) ccnt <= 0;
            else ccnt <= ccnt+1;
            if(ccnt == 30) state2 <= LINE1;
        end
        LINE1 :begin
            if(ccnt >=20) ccnt <= 0;
            else ccnt <= ccnt+1;
            if(ccnt == 20) state2 <= DELAY_T;
        end
        DELAY_T :begin
            if(ccnt >= 5) ccnt <= 0;
            else ccnt <= ccnt+1;
            if(ccnt == 5) state2 <= LINE1;
        end
        default : state2 <= DELAY2;
     endcase
  end
end
                              
always @(posedge clk or negedge rst)
begin
    if(!rst)
        {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_1_00000000;
    else begin
        case(state2)
            FUNCTION_SET :
                {LCD_RS, LCD_RW, LCD_DATA} <=10'b0_0_0011_0000;// N=0으로 설정하여 표시행수를 1로 설정한다.
            DISP_ONOFF :
                {LCD_RS, LCD_RW, LCD_DATA} <=10'b0_0_0000_1100;
            ENTRY_MODE :
                {LCD_RS, LCD_RW, LCD_DATA} <=10'b0_0_0000_0110;   
            LINE1 : begin
                case(ccnt)
                    00 : {LCD_RS, LCD_RW, LCD_DATA} <=10'b0_0_1000_0000; //        
                    01 : begin case(bcd[11:8]) //100의 자릿수 입력
                            0: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
                            1: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
                            2: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0010; // 2
                            3: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0011; // 3
                            4: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0100; // 4
                            5: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0101; // 5
                            6: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0110; // 6
                            7: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0111; // 7
                            8: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1000; // 8
                            9: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1001; // 9
                        endcase
                        end                  
                    02 : begin case(bcd[7:4]) //10의 자릿수 입력
                            0: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
                            1: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
                            2: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0010; // 2
                            3: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0011; // 3
                            4: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0100; // 4
                            5: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0101; // 5
                            6: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0110; // 6
                            7: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0111; // 7
                            8: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1000; // 8
                            9: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1001; // 9
                        endcase
                        end                  
                    03 :begin case(bcd[3:0]) //1의 자릿수 입력
                            0: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
                            1: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
                            2: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0010; // 2
                            3: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0011; // 3
                            4: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0100; // 4
                            5: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0101; // 5
                            6: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0110; // 6
                            7: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0111; // 7
                            8: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1000; // 8
                            9: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1001; // 9
                        endcase
                        end                  
                    default : {LCD_RS, LCD_RW, LCD_DATA} <=10'b1_0_0010_0000; // 
                 endcase
              end
            DELAY_T :
                {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0000_0010;
            default :
                {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_1_0000_0000;              
          endcase
      end
  end
  
  assign LCD_E = clk;               
           
endmodule
