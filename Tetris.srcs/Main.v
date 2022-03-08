
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/18 14:35:44
// Design Name: 
// Module Name: Main
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Main(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    //input  [3:0] usr_sw,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
);

assign usr_led = 4'b0000;
//Declare Signals
//--BTN signals
wire [3:0] btn_level, btn_pressed, btn_released;
reg [3:0] prev_btn_level;
reg prev_double [1:0];
reg SP_B3, SP_B20, SP_B21;
wire SP_hold;
wire SP_left;
wire SP_right;
wire SP_down;
wire SP_clkrt;
wire SP_ctclkrt;
wire SP_fastsown;
wire SP_gnrtobst;
wire SP_pause;
wire exit = (P == SPSR) && |btn_pressed;
//--LCD signals
reg [127:0] row_A;
reg [127:0] row_B;
//--SRAM signals
wire [11:0] data_in = 12'h000;
wire [17:0] sram_addr0;
wire [17:0] sram_addr1;
wire [17:0] sram_addr_grid;
wire [16:0] sram_addr_NEXT;
wire [16:0] sram_addr_number;
//wire sram_we = usr_sw[3];
wire sram_en = 1;
wire [11:0] data_out0;
wire [11:0] data_out1;
wire [11:0] data_out_grid [8:0];
wire [11:0] data_out_NEXT [0:8];
wire [11:0] data_out_number [0:9];
//--VGA signals
wire vga_clk;
wire video_on;
wire pixel_tick;
wire [9:0] pixel_x;
wire [9:0] pixel_y;
reg  [11:0] rgb_reg;
reg  [11:0] rgb_next;
//--FSM Signals
localparam IDLE = 0; //How many player
localparam SPPM = 1; //Pick map
localparam SPIG = 2; //Initial game
localparam SPFL = 3; //Falling
localparam SPUG = 4; //update grid & calculate the boundary
localparam SPCL = 5; //Clear lines & Count point & Calculate Height
localparam SPGP = 6; //Generate Piece & updata height
localparam SPPP = 7; //Put piece
localparam SPGO = 8; //Generate Obstacle
localparam SPSR = 9; //Show Result
localparam DPIG = 10;
reg  [4:0] P, P_next;
wire SP, DP;
localparam initial_time = 30_000_000;
//--Grid->Output signals
localparam board_HPOS = 86;
localparam board_VPOS = 18;
localparam screen_W = 320;
localparam screen_H = 240;
localparam board_W = 108;
localparam board_H = 208;
localparam grid_W = 10;
localparam grid_H = 10;
localparam NEXT_VPOS = 60;
localparam NEXT_HPOS = 20;
localparam NEXT_W = 30;
localparam NEXT_H = 20;
//scoreboard
reg [9:0] number_VPOS;
reg [9:0] number_HPOS;
reg [9:0] score_picture_HPOS;
reg [9:0] score_picture_VPOS;
//
localparam number_W = 6; 
localparam number_H = 7;
localparam hold_VPOS = 90;
localparam hold_HPOS = 210;
localparam hold_W = 30;
localparam hold_H = 20;
localparam boardsize = 336;
reg [3:0]  grid [0:boardsize - 1]; //10 * 22
reg [9:0]  grid_idx;
reg [9:0]  NEXT_idx;
reg [3:0]  number_idx;
wire       board_region;
wire       grid_region;
wire       NEXT_region;
wire       number_region;
wire       hold_region;
reg [17:0] pixel_addr0;
reg [17:0] pixel_addr1;
reg [17:0] pixel_addr_grid;
reg [17:0] pixel_addr_NEXT;
reg [17:0] pixel_addr_number;
reg [17:0] pixel_addr_hold;
//pick map
wire picked;
reg [3:0] map;
localparam map_size = 7;
//--Game signals
localparam tetro_I = 1;
localparam tetro_O = 2;
localparam tetro_L = 3;
localparam tetro_J = 4;
localparam tetro_T = 5;
localparam tetro_S = 6;
localparam tetro_Z = 7;
localparam T_S = 0; // tetro state: spawn
localparam T_L = 1; // tetro state: left
localparam T_2 = 2; // tetro state: 2
localparam T_R = 3; // tetro state: right
reg [3:0] tetromino_next [5:0];
reg [3:0] next_tetro;
reg [3:0] current_tetromino;
reg [9:0] current_tetromino_grid [0:3]; // 存�??�tetromino裡面??��?�grid??�pos
reg [9:0] shadow_pos [0:3]; // 存�?�別shadow grid??�pos
reg [4:0] deviation; //the deviation from the tetromino to height
reg [4:0] deviation_delay;
reg [1:0] current_state; //0:spawn; 1:R; 2:2; 3:L
reg [9:0] current_pos;
reg [27:0] fall_counter;
reg [27:0] speed_num; // actual speed number
reg [27:0] level_speed;
wire inited;
reg [30:0] init_counter;
reg fallen;
reg [4:0] height [0:9];
wire dead;
reg [23:0] score;
reg [3:0] scorebroad[7:0];
reg [2:0] line_cleared;
reg [7:0] tetro_list [0:104];
reg [7:0] tetromino_ctr;
reg [3:0] init_tetro_counter;
reg [3:0] hold;
reg first_hold;
reg first_holded;
reg holded;
reg [7:0] holded_idx;
reg [7:0] pre_holded_idx;
wire row_full;
reg [9:0] boundary;
reg [1:0] cl_counter;
wire cleared;
wire [7:0] current_tetro_idx;
reg [1:0] random_obst_counter;
reg [29:0] t_spin_counter;
localparam t_spin_time = 29'b10_001_111_000_011_010_001_100_000_000; //29bits
wire t_spin_period = t_spin_counter < t_spin_time;
reg [1:0] t_spin_type;
wire t_spin_single;
wire t_spin_double;
wire t_spin_triple;

//
wire [9:0]  pos_marquee;
wire [16:0] sram_addr_marquee;
wire [11:0] data_out_marquee[0:8];
wire [1:0]  marquee_number;
wire marquee_region;
reg [17:0] pixel_addr_marquee;
reg [17:0] marquee_addr;

wire [16:0] sram_addr_start_pic;
wire [11:0] data_out_start_pic;
wire start_pic_region;
reg [17:0] pixel_addr_start_pic;
reg [17:0] start_pic_addr;

localparam marquee_VPOS = 150;
localparam marquee_HPOS = 85;
localparam marquee_W = 30;
localparam marquee_H = 20;

localparam start_pic_VPOS = 65;
localparam start_pic_HPOS = 85;
localparam start_pic_W = 150;
localparam start_pic_H = 65;

assign sram_addr_marquee = pixel_addr_marquee;
assign marquee_number=(marquee_region);
assign marquee_region = pixel_x >= ((marquee_HPOS ) << 1) && pixel_x < ((marquee_HPOS + marquee_W*5 ) << 1)
                    && pixel_y >= ((marquee_VPOS ) << 1) && pixel_y < ((marquee_VPOS + marquee_H ) << 1);
assign sram_addr_start_pic = pixel_addr_start_pic;
assign start_pic_region = pixel_x >= ((start_pic_HPOS ) << 1) && pixel_x < ((start_pic_HPOS + start_pic_W ) << 1)
                    && pixel_y >= ((start_pic_VPOS ) << 1) && pixel_y < ((start_pic_VPOS + start_pic_H ) << 1);

always @( posedge clk)begin
  if( ~reset_n)begin
    pixel_addr_marquee <= 0;
  end
  else begin
    pixel_addr_marquee <= marquee_addr +
                   (((pixel_x>>1)- marquee_HPOS)% marquee_W) +
                  ((pixel_y>>1) -marquee_VPOS)* marquee_W;
  end
end

always @( posedge clk)begin
  if( ~reset_n)begin
    pixel_addr_start_pic <= 0;
  end
  else begin
    pixel_addr_start_pic <= start_pic_addr +
                   (((pixel_x>>1)- start_pic_HPOS)% start_pic_W) +
                  ((pixel_y>>1) -start_pic_VPOS)* start_pic_W;
  end
end

// ------------------------------------------------------------------------
reg [31:0]start_time ;
reg [31:0] start_ctr;
reg [3:0] marquee_list[0:9];
//marquee_idx
integer marquee_idx;
always@(posedge clk ) begin
  if (~reset_n) begin
   start_time=0;
    start_ctr <= 0;
    marquee_idx <= 0;
  end
  else begin
   start_time <= (start_time == 100000000) ?0 :start_time+1;
    start_ctr <= (start_time == 100000000)? start_ctr+1 : start_ctr ;
    marquee_idx <= ((pixel_x >> 1) - (marquee_HPOS)) / marquee_W;
    marquee_list[0] <= 1; marquee_list[1] <= 2; marquee_list[2] <= 3; marquee_list[3] <= 4; marquee_list[4] <= 5; marquee_list[5] <= 6; marquee_list[6] <= 7;
  end
end

//james
wire [9:0]  arrow_right_HPOS;
wire arrow_right_region;
reg  [3:0]arrow_right_idx;
localparam arrow_right_VPOS   = 25;// Vertical location of the fish in the sea image.
localparam arrow_right_W      = 20; // Width of the fish.
localparam arrow_right_H     = 20; // Height of the fish.

wire [9:0]  arrow_left_HPOS;
wire arrow_left_region;
reg  [3:0]arrow_left_idx;
localparam arrow_left_VPOS   = 25;// Vertical location of the fish in the sea image.
localparam arrow_left_W      = 20; // Width of the fish.
localparam arrow_left_H     = 20; // Height of the fish.

wire [9:0]  game_over_HPOS;
wire game_over_region;
reg  [3:0]game_over_idx;
localparam game_over_VPOS   = 25;// Vertical location of the fish in the sea image.
localparam game_over_W      = 100; // Width of the fish.
localparam game_over_H     = 100; // Height of the fish.

wire score_picture_region;
reg  [3:0]score_picture_idx;
localparam score_picture_W      = 100; // Width of the fish.
localparam score_picture_H     = 100; // Height of the fish.

wire [9:0]  start_HPOS;
wire start_region;
reg  [3:0]start_idx;
localparam start_VPOS   = 50;// Vertical location of the fish in the sea image.
localparam start_W      = 150; // Width of the fish.
localparam start_H     = 40; // Height of the fish.

wire [9:0]  pause_HPOS;
wire pause_region;
reg  [3:0]pause_idx;
localparam pause_VPOS   = 25;// Vertical location of the fish in the sea image.
localparam pause_W      = 150; // Width of the fish.
localparam pause_H     = 38; // Height of the fish.

wire [9:0]  pick_map_HPOS;
wire pick_map_region;
reg  [3:0]pick_map_idx;
localparam pick_map_VPOS   = 25;// Vertical location of the fish in the sea image.
localparam pick_map_W      = 100; // Width of the fish.
localparam pick_map_H     = 20; // Height of the fish.

wire [9:0]  double_HPOS;
wire double_region;
reg  [3:0]double_idx;
localparam double_VPOS   = 200;// Vertical location of the fish in the sea image.
localparam double_W      = 70; // Width of the fish.
localparam double_H     = 20; // Height of the fish.

wire [9:0]  triple_HPOS;
wire triple_region;
reg  [3:0]triple_idx;
localparam triple_VPOS   = 200;// Vertical location of the fish in the sea image.
localparam triple_W      = 70; // Width of the fish.
localparam triple_H     = 20; // Height of the fish.

wire [9:0]  t_spin_HPOS;
wire t_spin_region;
reg  [3:0]t_spin_idx;
localparam t_spin_VPOS   = 180;// Vertical location of the fish in the sea image.
localparam t_spin_W      = 70; // Width of the fish.
localparam t_spin_H     = 20; // Height of the fish.

wire [9:0]  broad_HPOS;
wire broad_region;
reg  [3:0]broad_idx;
localparam broad_VPOS   = 18;// Vertical location of the fish in the sea image.
localparam broad_W      = 108; // Width of the fish.
localparam broad_H     = 208; // Height of the fish.

wire [9:0]  next_HPOS;
wire next_region;
reg  [3:0]next_idx;
localparam next_VPOS   = 18;// Vertical location of the fish in the sea image.
localparam next_W      = 70; // Width of the fish.
localparam next_H     = 20; // Height of the fish.

wire [9:0]  holdword_HPOS;
wire holdword_region;
reg  [3:0]holdword_idx;
localparam holdword_VPOS   = 18;// Vertical location of the fish in the sea image.
localparam holdword_W      = 70; // Width of the fish.
localparam holdword_H     = 20; // Height of the fish.

assign arrow_right_HPOS=202;
assign arrow_left_HPOS=55;
assign game_over_HPOS=85;
assign start_HPOS=70;
assign pause_HPOS=90;
assign pick_map_HPOS=89;
assign double_HPOS=5;
assign triple_HPOS=5;
assign t_spin_HPOS=5;
assign next_HPOS=5;
assign holdword_HPOS=200;

// declare SRAM control signals
wire [16:0] sram_addr_arrow_right;
wire [16:0] sram_addr_arrow_left;
wire [16:0] sram_addr_game_over;
wire [16:0] sram_addr_score_picture;
wire [16:0] sram_addr_start;
wire [16:0] sram_addr_pause;
wire [16:0] sram_addr_pick_map;
wire [16:0] sram_addr_double;
wire [16:0] sram_addr_triple;
wire [16:0] sram_addr_t_spin;
wire [16:0] sram_addr_next;
wire [16:0] sram_addr_holdword;


wire [11:0] data_out_arrow_right;
wire [11:0] data_out_arrow_left;
wire [11:0] data_out_game_over;
wire [11:0] data_out_score_picture;
wire [11:0] data_out_start;
wire [11:0] data_out_pause;
wire [11:0] data_out_pick_map;
wire [11:0] data_out_double;
wire [11:0] data_out_triple;
wire [11:0] data_out_t_spin;
wire [11:0] data_out_next;
wire [11:0] data_out_holdword;

reg  [17:0] pixel_addr_arrow_right;
reg  [17:0] pixel_addr_arrow_left;
reg  [17:0] pixel_addr_game_over;
reg  [17:0] pixel_addr_score_picture;
reg  [17:0] pixel_addr_start;
reg  [17:0] pixel_addr_pause;
reg  [17:0] pixel_addr_pick_map;
reg  [17:0] pixel_addr_double;
reg  [17:0] pixel_addr_triple;
reg  [17:0] pixel_addr_t_spin;
reg  [17:0] pixel_addr_broad;
reg  [17:0] pixel_addr_next;
reg  [17:0] pixel_addr_holdword;

sram_arrow_right #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(arrow_right_W*arrow_right_H))
  arrow_right (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_arrow_right), .data_i(data_in), .data_o(data_out_arrow_right));
sram_arrow_left #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(arrow_left_W*arrow_left_H))
  arrow_left (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_arrow_left), .data_i(data_in), .data_o(data_out_arrow_left));
sram_game_over #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(game_over_W*game_over_H))
  game_over (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_game_over), .data_i(data_in), .data_o(data_out_game_over)); 
sram_score_picture #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(score_picture_W*score_picture_H))
  score_picture (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_score_picture), .data_i(data_in), .data_o(data_out_score_picture)); 
sram_start #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(start_W*start_H))
  start (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_start), .data_i(data_in), .data_o(data_out_start)); 
sram_pause #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(pause_W*pause_H))
  pause (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_pause), .data_i(data_in), .data_o(data_out_pause)); 
sram_pick_map #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(pick_map_W*pick_map_H))
  pick_map (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_pick_map), .data_i(data_in), .data_o(data_out_pick_map));
// sram_double #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(double_W*double_H))
//   double (.clk(clk), .we(sram_we), .en(sram_en),
//           .addr(sram_addr_double), .data_i(data_in), .data_o(data_out_double));  
// sram_triple #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(triple_W*triple_H))
//   triple (.clk(clk), .we(sram_we), .en(sram_en),
//           .addr(sram_addr_triple), .data_i(data_in), .data_o(data_out_triple));  
sram_t_spin #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(t_spin_W*t_spin_H))
  t_spin (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_t_spin), .data_i(data_in), .data_o(data_out_t_spin));  
sram_next #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(next_W*next_H))
  next (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_next), .data_i(data_in), .data_o(data_out_next));       
sram_holdword #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(holdword_W*holdword_H))
  holdword (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_holdword), .data_i(data_in), .data_o(data_out_holdword));

assign sram_addr_arrow_right=pixel_addr_arrow_right;
assign sram_addr_arrow_left=pixel_addr_arrow_left;
assign sram_addr_game_over=pixel_addr_game_over;
assign sram_addr_score_picture=pixel_addr_score_picture;
assign sram_addr_start=pixel_addr_start;
assign sram_addr_pause=pixel_addr_pause;
assign sram_addr_pick_map=pixel_addr_pick_map;
assign sram_addr_double=pixel_addr_double;
assign sram_addr_triple=pixel_addr_triple;
assign sram_addr_t_spin=pixel_addr_t_spin;
assign sram_addr_next=pixel_addr_next;
assign sram_addr_holdword=pixel_addr_holdword; 


assign arrow_right_region = pixel_x >= ((arrow_right_HPOS) << 1) && pixel_x < ((arrow_right_HPOS+ arrow_right_W) << 1)
                    && pixel_y >= ((arrow_right_VPOS) << 1) && pixel_y < ((arrow_right_VPOS + arrow_right_H) << 1);
assign arrow_left_region = pixel_x >= ((arrow_left_HPOS) << 1) && pixel_x < ((arrow_left_HPOS+ arrow_left_W) << 1)
                    && pixel_y >= ((arrow_left_VPOS) << 1) && pixel_y < ((arrow_left_VPOS + arrow_left_H) << 1);
assign game_over_region = pixel_x >= ((game_over_HPOS) << 1) && pixel_x < ((game_over_HPOS+ game_over_W) << 1)
                    && pixel_y >= ((game_over_VPOS) << 1) && pixel_y < ((game_over_VPOS + game_over_H) << 1);
assign score_picture_region = pixel_x >= ((score_picture_HPOS) << 1) && pixel_x < ((score_picture_HPOS+ score_picture_W) << 1)
                    && pixel_y >= ((score_picture_VPOS) << 1) && pixel_y < ((score_picture_VPOS + score_picture_H) << 1);
assign start_region = pixel_x >= ((start_HPOS) << 1) && pixel_x < ((start_HPOS+ start_W) << 1)
                    && pixel_y >= ((start_VPOS) << 1) && pixel_y < ((start_VPOS + start_H) << 1);
assign pause_region = pixel_x >= ((pause_HPOS) << 1) && pixel_x < ((pause_HPOS+ pause_W) << 1)
                    && pixel_y >= ((pause_VPOS) << 1) && pixel_y < ((pause_VPOS + pause_H) << 1);
assign pick_map_region = pixel_x >= ((pick_map_HPOS) << 1) && pixel_x < ((pick_map_HPOS+ pick_map_W) << 1)
                    && pixel_y >= ((pick_map_VPOS) << 1) && pixel_y < ((pick_map_VPOS + pick_map_H) << 1);
assign double_region = pixel_x >= ((double_HPOS) << 1) && pixel_x < ((double_HPOS+ double_W) << 1)
                    && pixel_y >= ((double_VPOS) << 1) && pixel_y < ((double_VPOS + double_H) << 1);
assign triple_region = pixel_x >= ((triple_HPOS) << 1) && pixel_x < ((triple_HPOS+ triple_W) << 1)
                    && pixel_y >= ((triple_VPOS) << 1) && pixel_y < ((triple_VPOS + triple_H) << 1);
assign t_spin_region = pixel_x >= ((t_spin_HPOS) << 1) && pixel_x < ((t_spin_HPOS+ t_spin_W) << 1)
                    && pixel_y >= ((t_spin_VPOS) << 1) && pixel_y < ((t_spin_VPOS + t_spin_H) << 1);
assign next_region = pixel_x >= ((next_HPOS) << 1) && pixel_x < ((next_HPOS+ next_W) << 1)
                    && pixel_y >= ((next_VPOS) << 1) && pixel_y < ((next_VPOS + next_H) << 1);
assign holdword_region = pixel_x >= ((holdword_HPOS) << 1) && pixel_x < ((holdword_HPOS+ holdword_W) << 1)
                    && pixel_y >= ((holdword_VPOS) << 1) && pixel_y < ((holdword_VPOS + holdword_H) << 1);
                    

//james

//reg fall_counter
//End of signal declarations

//LCD
LCD_module lcd0(
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);
//End of LCD

reg [7:0]data[0:4];
always @(posedge clk ) begin
    data[0] <= P + 48;
    row_A <= {"state: ", data[0], "        "};
    row_B <= "Good Morning =3 ";
end

//LCD display
/*
reg [7:0]data[0:4];
reg [7:0] hehe [0:9];
always @(posedge clk ) begin
    if (!reset_n) begin
        row_A <= "STATE: IDLE     ";
        row_B <= "Good Morning =3 ";
    end
    else begin 
        if (P == IDLE) begin
            row_A <= "STATE: IDLE     ";
            row_B <= "Good Morning =3 ";
        end
        else if (P == SPPM) begin
            row_A <= "STATE: SPPM     ";
            row_B <= "Good Morning =3 ";
        end
        else if (P == SPIG) begin
            row_A <= "STATE: SPIG     ";
            row_B <= "Good Morning =3 ";
        end
        else if (P == SPFL) begin
            if (fall_counter == speed_num) begin
                data[0] <= (tetromino_ctr[7:4] > 9) ? tetromino_ctr[7:4] + 55 : tetromino_ctr[7:4]+48;
                data[1] <= (tetromino_ctr[3:0] > 9) ? tetromino_ctr[3:0] + 55 : tetromino_ctr[3:0]+48;
                // data[2] <=tetromino_next[2]+48;
                // data[3] <=tetromino_next[3]+48;
                // data[4] <=tetromino_next[4]+48;

                hehe[0] <= holded + 48;
                hehe[1] <= first_hold + 48;
                hehe[2] <= (holded_idx[7:4] > 9) ? holded_idx[7:4] + 55 : holded_idx[7:4]+48;
                hehe[3] <= (holded_idx[3:0] > 9) ? holded_idx[3:0] + 55 : holded_idx[3:0]+48;

                hehe[4] <= current_tetromino + 48;

                // hehe[0] <=height[0]%10+48;
                // hehe[1] <=height[1]%10+48;
                // hehe[2] <=height[2]%10+48;
                // hehe[3] <=height[3]%10+48;
                // hehe[4] <=height[4]%10+48;
                // hehe[5] <=height[5]%10+48;
                // hehe[6] <=height[6]%10+48;
                // hehe[7] <=height[7]%10+48;
                // hehe[8] <=height[8]%10+48;
                // hehe[9] <=height[9]%10+48;
                row_A <= {"0", data[0], data[1],"  ", hehe[4],"  4       "};
                row_B <= {hehe[0], hehe[1], hehe[2], hehe[3], "            "};
            end 
            else if (SP_hold) begin
                row_A <= "STATE: SPFL     ";
                row_B <= "hold            ";
            end
            else if (SP_left) begin
                row_A <= "STATE: SPFL     ";
                row_B <= "move left       ";
            end
            else if (SP_right) begin
                row_A <= "STATE: SPFL     ";
                row_B <= "move right      ";
            end
            else if (SP_down) begin
                row_A <= "STATE: SPFL     ";
                row_B <= "slow down       ";
            end
            else if (SP_clkrt) begin
                row_A <= "STATE: SPFL     ";
                row_B <= "clockwise rotate";
            end
            else if (SP_ctclkrt) begin
                row_A <= "STATE: SPFL     ";
                row_B <= "ctclkwise rotate";
            end
            else if (SP_fastsown) begin
                row_A <= "STATE: SPFL     ";
                row_B <= "fast down       ";
            end
            else if (SP_gnrtobst) begin
                row_A <= "STATE: SPFL     ";
                row_B <= "genert obstacle ";
            end
            else if (SP_pause) begin
                row_A <= "STATE: SPFL     ";
                row_B <= "pause           ";
            end
        end
    end
end
*/
//End of LCD display

//Button control
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[0]),
  .btn_output(btn_level[0])
);
debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);
debounce btn_db2(
  .clk(clk),
  .btn_input(usr_btn[2]),
  .btn_output(btn_level[2])
);
debounce btn_db3(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level[3])
);
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 4'b1111;
  else
    prev_btn_level <= btn_level;
end
assign btn_pressed = (btn_level & ~prev_btn_level);
assign btn_released = (~btn_level & prev_btn_level);
//single player btn control
assign SP_hold     = (btn_released[3] && !SP_B3);
assign SP_left     = (!btn_level[3] && !btn_level[1] && !btn_level[0] && !SP_B20 && !SP_B21 && !SP_B3 && btn_released[2]);
assign SP_right    = (!btn_level[3] && !btn_level[2] && !btn_level[1] && !SP_B20 && !SP_B21 && !SP_B3 && btn_released[0]);
assign SP_down     = (!btn_level[3] && !btn_level[2] && !btn_level[0] && !SP_B20 && !SP_B21 && !SP_B3 && btn_released[1]);
assign SP_clkrt    = (btn_level[3] && btn_released[0]);
assign SP_ctclkrt   = (btn_level[3] && btn_released[2]);
assign SP_fastsown = (btn_level[3] && btn_released[1]);
assign SP_gnrtobst = (btn_level[2] && btn_pressed[0]);
assign SP_pause    = (btn_level[2] && btn_level[1]);

always @(posedge clk ) begin
    if (!reset_n || P == IDLE) begin
        SP_B3  <= 0;
        SP_B20 <= 0;
        SP_B21 <= 0;
    end
    else begin 
        if (P == IDLE) begin

        end
        else if (P == SPPM) begin

        end
        else if (P == SPIG) begin

        end
        else if (P == SPFL) begin
            if (fall_counter == speed_num) begin

            end 
            if (btn_released[3] && SP_B3) begin
                SP_B3 <= 0;
            end
            else if (((btn_released[2] && !btn_level[0]) || (btn_released[0] && !btn_level[2])) && SP_B20) begin
                SP_B20 <= 0;
            end
            else if (((btn_released[2] && !btn_level[1]) || (btn_released[1] && !btn_level[2])) && SP_B21) begin
                SP_B21 <= 0;
            end
            else if (SP_hold) begin

            end
            else if (SP_left) begin

            end
            else if (SP_right) begin

            end
            else if (SP_down) begin

            end
            else if (SP_clkrt) begin
                SP_B3 <= 1;
            end
            else if (SP_ctclkrt) begin
                SP_B3 <= 1;
            end
            else if (SP_fastsown) begin
                SP_B3 <= 1;
            end
            else if (SP_gnrtobst) begin
                SP_B20 <= 1;
            end
            else if (SP_pause) begin
                SP_B21 <= 1;
            end
        end
    end
end
//End of Button control

//SRAMs
// sram0 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(screen_W*screen_H))
//     ram0 (.clk(clk), .we(sram_we), .en(sram_en),
//         .addr(sram_addr0), .data_i(data_in), .data_o(data_out0));
sram1 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(board_W * board_H))
    ram1 (.clk(clk), .we(sram_we), .en(sram_en),
        .addr(sram_addr1), .data_i(data_in), .data_o(data_out1));
sram_I #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(grid_W * grid_H))
    ram_I (.clk(clk), .we(sram_we), .en(sram_en),
        .addr(sram_addr_grid), .data_i(data_in), .data_o(data_out_grid[1]));
sram_O #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(grid_W * grid_H))
    ram_O (.clk(clk), .we(sram_we), .en(sram_en),
        .addr(sram_addr_grid), .data_i(data_in), .data_o(data_out_grid[2]));
sram_L #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(grid_W * grid_H))
    ram_L (.clk(clk), .we(sram_we), .en(sram_en),
        .addr(sram_addr_grid), .data_i(data_in), .data_o(data_out_grid[3]));
sram_J #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(grid_W * grid_H))
    ram_J (.clk(clk), .we(sram_we), .en(sram_en),
        .addr(sram_addr_grid), .data_i(data_in), .data_o(data_out_grid[4]));
sram_T #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(grid_W * grid_H))
    ram_T (.clk(clk), .we(sram_we), .en(sram_en),
        .addr(sram_addr_grid), .data_i(data_in), .data_o(data_out_grid[5]));
sram_S #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(grid_W * grid_H))
    ram_S (.clk(clk), .we(sram_we), .en(sram_en),
        .addr(sram_addr_grid), .data_i(data_in), .data_o(data_out_grid[6]));
sram_Z #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(grid_W * grid_H))
    ram_Z (.clk(clk), .we(sram_we), .en(sram_en),
        .addr(sram_addr_grid), .data_i(data_in), .data_o(data_out_grid[7]));
sram_shadow #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(grid_W * grid_H))
    ram_shadow (.clk(clk), .we(sram_we), .en(sram_en),
        .addr(sram_addr_grid), .data_i(data_in), .data_o(data_out_grid[8]));

sram_Buf_I #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(NEXT_W*NEXT_H))
  ram_Buf_I (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_NEXT), .data_i(data_in), .data_o(data_out_NEXT[1]));
sram_Buf_O #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(NEXT_W*NEXT_H))
  ram_Buf_O (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_NEXT), .data_i(data_in), .data_o(data_out_NEXT[2]));
sram_Buf_L #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(NEXT_W*NEXT_H))
  ram_Buf_L (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_NEXT), .data_i(data_in), .data_o(data_out_NEXT[3]));
sram_Buf_J #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(NEXT_W*NEXT_H))
  ram_Buf_J (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_NEXT), .data_i(data_in), .data_o(data_out_NEXT[4]));
sram_Buf_T #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(NEXT_W*NEXT_H))
  ram_Buf_T (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_NEXT), .data_i(data_in), .data_o(data_out_NEXT[5]));        
sram_Buf_S #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(NEXT_W*NEXT_H))
  ram_Buf_S (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_NEXT), .data_i(data_in), .data_o(data_out_NEXT[6]));
sram_Buf_Z #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(NEXT_W*NEXT_H))
  ram_Buf_Z (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_NEXT), .data_i(data_in), .data_o(data_out_NEXT[7]));

sram_number0 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(number_W*number_H))
  number0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_number), .data_i(data_in), .data_o(data_out_number[0]));          
sram_number1 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(number_W*number_H))
  number1 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_number), .data_i(data_in), .data_o(data_out_number[1]));
sram_number2 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(number_W*number_H))
  number2 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_number), .data_i(data_in), .data_o(data_out_number[2]));
sram_number3 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(number_W*number_H))
  number3 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_number), .data_i(data_in), .data_o(data_out_number[3]));
sram_number4 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(number_W*number_H))
  number4 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_number), .data_i(data_in), .data_o(data_out_number[4]));
sram_number5 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(number_W*number_H))
  number5 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_number), .data_i(data_in), .data_o(data_out_number[5]));
sram_number6 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(number_W*number_H))
  number6 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_number), .data_i(data_in), .data_o(data_out_number[6]));
sram_number7 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(number_W*number_H))
  number7 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_number), .data_i(data_in), .data_o(data_out_number[7]));
sram_number8 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(number_W*number_H))
  number8 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_number), .data_i(data_in), .data_o(data_out_number[8]));
sram_number9 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(number_W*number_H))
  number9 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_number), .data_i(data_in), .data_o(data_out_number[9]));

// sram_Buf_I #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(marquee_W*marquee_H))
//   ram_Buf_I_2 (.clk(clk), .we(sram_we), .en(sram_en),
//           .addr(sram_addr_marquee), .data_i(data_in), .data_o(data_out_marquee[1]));
// sram_Buf_O #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(marquee_W*marquee_H))
//   ram_Buf_O_2 (.clk(clk), .we(sram_we), .en(sram_en),
//           .addr(sram_addr_marquee), .data_i(data_in), .data_o(data_out_marquee[2]));
// sram_Buf_L #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(marquee_W*marquee_H))
//   ram_Buf_L_2 (.clk(clk), .we(sram_we), .en(sram_en),
//           .addr(sram_addr_marquee), .data_i(data_in), .data_o(data_out_marquee[3]));
// sram_Buf_J #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(marquee_W*marquee_H))
//   ram_Buf_J_2 (.clk(clk), .we(sram_we), .en(sram_en),
//           .addr(sram_addr_marquee), .data_i(data_in), .data_o(data_out_marquee[4]));
// sram_Buf_T #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(marquee_W*marquee_H))
//   ram_Buf_T_2 (.clk(clk), .we(sram_we), .en(sram_en),
//           .addr(sram_addr_marquee), .data_i(data_in), .data_o(data_out_marquee[5]));        
// sram_Buf_S #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(marquee_W*marquee_H))
//   ram_Buf_S_2 (.clk(clk), .we(sram_we), .en(sram_en),
//           .addr(sram_addr_marquee), .data_i(data_in), .data_o(data_out_marquee[6]));
// sram_Buf_Z #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(marquee_W*marquee_H))
//   ram_Buf_Z_2 (.clk(clk), .we(sram_we), .en(sram_en),
//           .addr(sram_addr_marquee), .data_i(data_in), .data_o(data_out_marquee[7]));


sram_start_pic #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(start_pic_W*start_pic_H))
  ram_start_pic (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_start_pic), .data_i(data_in), .data_o(data_out_start_pic));
          

assign sram_addr0 = pixel_addr0;
assign sram_addr1 = pixel_addr1;
assign sram_addr_grid = pixel_addr_grid;
assign sram_addr_NEXT = (NEXT_region) ? pixel_addr_NEXT : ((marquee_region) ? pixel_addr_marquee : pixel_addr_hold);
assign sram_addr_number = pixel_addr_number;

//End of SRAMs

//VGA display
//跟W, H??��?��?�水平�?�直資�?�都?��0-319*0-239尺度???

vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);
clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);
always @(posedge clk) begin
    if (pixel_tick) rgb_reg <= rgb_next;
end
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;
assign board_region = pixel_x >= (board_HPOS << 1) && pixel_x < ((board_HPOS + board_W) << 1)
                    && pixel_y >= (board_VPOS << 1) && pixel_y < ((board_VPOS + board_H) << 1);
assign grid_region = pixel_x >= ((board_HPOS + 4) << 1) && pixel_x < ((board_HPOS + board_W - 4) << 1)
                    && pixel_y >= ((board_VPOS + 4) << 1) && pixel_y < ((board_VPOS + board_H - 4) << 1);
assign NEXT_region = pixel_x >= ((NEXT_HPOS ) << 1) && pixel_x < ((NEXT_HPOS + NEXT_W ) << 1)
                    && pixel_y >= ((NEXT_VPOS ) << 1) && pixel_y < ((NEXT_VPOS + NEXT_H*5 ) << 1);
assign number_region = pixel_x >= ((number_HPOS) << 1) && pixel_x < ((number_HPOS+ 7*number_W) << 1)
                    && pixel_y >= ((number_VPOS) << 1) && pixel_y < ((number_VPOS + number_H) << 1);
assign hold_region = pixel_x >= ((hold_HPOS) << 1) && pixel_x < ((hold_HPOS+ hold_W) << 1)
                    && pixel_y >= ((hold_VPOS) << 1) && pixel_y < ((hold_VPOS + hold_H) << 1);

// number index
always @(posedge clk ) begin
    if (~reset_n || P == IDLE) begin
        number_idx <= 0;
    end
    else begin
        number_idx = ((pixel_x>>1) - number_HPOS) / number_W;
                    
    end
end
// NEXT_idx
always@(posedge clk ) begin
    if (~reset_n || P == IDLE) begin
        NEXT_idx <= 0;
    end
    else begin
        NEXT_idx <= ((pixel_y >> 1) - (NEXT_VPOS)) / NEXT_H;
    end
end
//grid_idx
always @(posedge clk ) begin
    if (~reset_n || P == IDLE) begin
        grid_idx <= 0;
    end
    else begin
        // if (pixel_x[0] == 0 && pixel_y[0]) begin //e, e
        //     grid_idx <= (((pixel_y >> 1) - (board_VPOS + 4)) / grid_H + 2) * 14
        //                 + ((pixel_x >> 1) - (board_HPOS + 4)) / grid_W + 2;
        // end
        // else if (pixel_x[0] == 1 && pixel_y[0]) begin //o, e
        //     grid_idx <= (((pixel_y >> 1) - (board_VPOS + 4)) / grid_H + 2) * 14
        //                 + ((pixel_x >> 1) + 1 - (board_HPOS + 4)) / grid_W + 2;
        // end
        grid_idx <= (((pixel_y >> 1) - (board_VPOS + 4)) / grid_H + 2) * 14
                    + ((pixel_x >> 1) - (board_HPOS + 4)) / grid_W + 2;
    end
end
//pixel_addr of a grid
always @(posedge clk ) begin
    if (~reset_n || P == IDLE) begin
        pixel_addr0 <= 0;
        pixel_addr1 <= 0;
        pixel_addr_grid <= 0;
        pixel_addr_NEXT <= 0;
        pixel_addr_number <= 0;
        //james
        pixel_addr_arrow_right <= 0;
        pixel_addr_arrow_left <= 0;
        pixel_addr_game_over <= 0;
        pixel_addr_score_picture <= 0;
        pixel_addr_start <= 0;
        pixel_addr_pause <= 0;
        pixel_addr_pick_map <= 0;
        pixel_addr_double <= 0;
        pixel_addr_triple <= 0;
        pixel_addr_t_spin <= 0;
        pixel_addr_next <= 0;
        pixel_addr_holdword <= 0;
        //james
    end
    else begin
        pixel_addr0 <= (pixel_y >> 1) * screen_W + (pixel_x >> 1);
        pixel_addr1 <= ((pixel_y >> 1) - board_VPOS) * board_W
                        + ((pixel_x - (board_HPOS << 1)) >> 1);
        pixel_addr_grid <= (((pixel_y >> 1) - (board_VPOS + 4)) % grid_H) * grid_W
                        + ((pixel_x >> 1) - (board_HPOS + 4)) % grid_W;
        pixel_addr_NEXT <= (((pixel_y >> 1) - NEXT_VPOS) % NEXT_H) * NEXT_W
                        + ((pixel_x >> 1) - NEXT_HPOS);
        pixel_addr_number <= (((pixel_y >> 1) - number_VPOS)) * number_W
                        + ((pixel_x >> 1) - number_HPOS) % number_W;
        pixel_addr_hold <= (((pixel_y >> 1) - hold_VPOS) % hold_H) * hold_W
                        + ((pixel_x >> 1) - hold_HPOS);
        //james
        pixel_addr_arrow_right <= (((pixel_y >> 1) - arrow_right_VPOS)) * arrow_right_W
                        + ((pixel_x >> 1) - arrow_right_HPOS);
        pixel_addr_arrow_left <= (((pixel_y >> 1) - arrow_left_VPOS)) * arrow_left_W
                        + ((pixel_x >> 1) - arrow_left_HPOS);
        pixel_addr_game_over <= (((pixel_y >> 1) - game_over_VPOS)) * game_over_W
                        + ((pixel_x >> 1) - game_over_HPOS);
        pixel_addr_score_picture <= (((pixel_y >> 1) - score_picture_VPOS)) * score_picture_W
                        + ((pixel_x >> 1) - score_picture_HPOS);
        pixel_addr_start <= (((pixel_y >> 1) - start_VPOS)) * start_W
                        + ((pixel_x >> 1) - start_HPOS);
        pixel_addr_pause <= (((pixel_y >> 1) - pause_VPOS)) * pause_W
                        + ((pixel_x >> 1) - pause_HPOS);
        pixel_addr_pick_map <= (((pixel_y >> 1) - pick_map_VPOS)) * pick_map_W
                        + ((pixel_x >> 1) - pick_map_HPOS);
        pixel_addr_double <= (((pixel_y >> 1) - double_VPOS)) * double_W
                        + ((pixel_x >> 1) - double_HPOS);
        pixel_addr_triple <= (((pixel_y >> 1) - triple_VPOS)) * triple_W
                        + ((pixel_x >> 1) - triple_HPOS);
        pixel_addr_t_spin <= (((pixel_y >> 1) - t_spin_VPOS)) * t_spin_W
                        + ((pixel_x >> 1) - t_spin_HPOS);
        pixel_addr_next <= (((pixel_y >> 1) - next_VPOS)) * next_W
                        + ((pixel_x >> 1) - next_HPOS);
        pixel_addr_holdword <= (((pixel_y >> 1) - holdword_VPOS)) * holdword_W
                        + ((pixel_x >> 1) - holdword_HPOS);
        //james
    end
end
//send data_out to rgb_next
always @(posedge clk ) begin
    if (~video_on) begin 
        rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
    end
    else begin
        if (P == IDLE) begin
            if(marquee_region)begin
                if(data_out_NEXT[marquee_list[(marquee_idx+start_ctr)%7]]==12'h0f0)begin
                    rgb_next =12'hfff;
                end
                else begin
                    rgb_next =data_out_NEXT[marquee_list[(marquee_idx+start_ctr)%7]];
                end       
            end 
            else if(start_pic_region)begin
                if(data_out_start_pic==12'h0f0)begin
                    rgb_next =12'hfff;
                end
                else begin
                    rgb_next =data_out_start_pic;
                end    
            end 
            else begin
                rgb_next = 12'hfff;
            end
        end
        else if (P == SPPM) begin
            if (grid_region) begin
                if(board_region==1)begin
                    if(pick_map_region==1)begin
                        if (data_out_pick_map==12'h0f0)
                            rgb_next = data_out1;
                        else
                            rgb_next = data_out_pick_map;
                    end else begin
                        if (grid[grid_idx] == 0) begin
                            rgb_next <= data_out1;
                        end
                        else begin
                            rgb_next <= data_out_grid[grid[grid_idx]];
                        end   
                    end
                end else begin
                    rgb_next <= 12'hfff;
                end
                
            end
            //james
            else if (board_region) begin
                if(pick_map_region==1)begin
                  if (data_out_pick_map==12'h0f0)
                    rgb_next = data_out1;
                  else
                    rgb_next = data_out_pick_map;
                end else begin
                  if (data_out1==12'h0f0)
                    rgb_next = 12'hfff;
                  else
                    rgb_next = data_out1;    
                end
            end
            
            else if(arrow_right_region==1)begin
                if (data_out_arrow_right==12'h0f0)
                rgb_next = 12'hfff;
            else
                rgb_next = data_out_arrow_right;
            end

            else if(arrow_left_region==1)begin
                  if (data_out_arrow_left==12'h0f0)
                rgb_next = 12'hfff;
            else
                rgb_next = data_out_arrow_left;
            end
            
            else if(pick_map_region==1)begin
                  if (data_out_pick_map==12'h0f0)
                rgb_next = 12'hfff;
            else
                rgb_next = data_out_pick_map;
            end
            
            //james
            else begin
                    rgb_next <= 12'hfff;
            end
            
        end
        else if (P == SPIG) begin
            rgb_next <= 12'hfff;
        end
        else if (P == SPFL) begin
            if (grid_region) begin
                if ((grid_idx == current_tetromino_grid[0]) || (grid_idx == current_tetromino_grid[1]) 
                    || (grid_idx == current_tetromino_grid[2]) || (grid_idx == current_tetromino_grid[3])) begin
                    rgb_next <= data_out_grid[current_tetromino];
                end
                else if ((grid_idx == shadow_pos[0]) || (grid_idx == shadow_pos[1]) 
                    || (grid_idx == shadow_pos[2]) || (grid_idx == shadow_pos[3])) begin
                    rgb_next <= (data_out_grid[8] == 12'h0f0) ? data_out1 : data_out_grid[8];
                end
                else if (grid[grid_idx] == 0) begin
                    rgb_next <= data_out1;
                end
                else begin
                    rgb_next <= data_out_grid[grid[grid_idx]];
                end
            end
            else if (number_region) begin
                if (number_idx >= 0 && number_idx <= 6) begin
                    if (scorebroad[number_idx] >= 1 && scorebroad[number_idx] <= 9)begin
                        if (data_out_number[scorebroad[number_idx]] == 12'h0f0)
                            rgb_next = 12'hfff;
                        else
                            rgb_next = data_out_number[scorebroad[number_idx]];
                    end 
                    else begin
                        if (data_out_number[scorebroad[number_idx]]==12'h0f0)
                            rgb_next = 12'hfff;
                        else
                            rgb_next = data_out_number[0];
                    end
                end 
            end
            //james
            else if(score_picture_region==1)begin
                if (data_out_score_picture==12'h0f0)
                    rgb_next = 12'hfff;
                else
                    rgb_next = data_out_score_picture;
            end
            
            else if(t_spin_region && t_spin_period)begin
                if (data_out_t_spin==12'h0f0)
                    rgb_next = 12'hfff;
                else
                    rgb_next = data_out_t_spin;
            end 

            else if(double_region && t_spin_type == 2 && t_spin_period)begin
                if (data_out_double==12'h0f0)
                    rgb_next = 12'hfff;
                else
                    rgb_next = data_out_double;
            end 
            
            else if(triple_region && t_spin_type == 3 && t_spin_period)begin
                if (data_out_triple==12'h0f0)
                    rgb_next = 12'hfff;
                else
                    rgb_next = data_out_triple;
            end 
             
            else if(next_region==1)begin
                if (data_out_next==12'h0f0)
                    rgb_next = 12'hfff;
                else
                    rgb_next = data_out_next;
              end 
            
              else if(holdword_region==1)begin
                if (data_out_holdword==12'h0f0)
                    rgb_next = 12'hfff;
                else
                    rgb_next = data_out_holdword;
              end 
            
            //james
            else if (hold_region) begin // havent check if output is 0f0
                if (first_holded) begin
                    if (holded) begin
                        rgb_next <= (data_out_NEXT[tetro_list[holded_idx]] == 12'h0f0) ? data_out1 : data_out_NEXT[tetro_list[holded_idx]];
                    end
                    else begin
                        rgb_next <= (data_out_NEXT[tetro_list[pre_holded_idx]] == 12'h0f0) ? data_out1 : data_out_NEXT[tetro_list[pre_holded_idx]];
                    end
                end
                else 
                    rgb_next <= data_out1;
            end
            else if (board_region) begin
                rgb_next <= data_out1;
            end
            else if (NEXT_region) begin
                rgb_next <= (data_out_NEXT[tetromino_next[NEXT_idx + 1]] == 12'h0f0) ? data_out1 : data_out_NEXT[tetromino_next[NEXT_idx + 1]];
            end
            else begin
                rgb_next <= 12'hfff;
            end
        end
        else if (P == SPUG) begin
            rgb_next <= 12'hfff;
        end
        else if (P == SPPP) begin
            rgb_next <= 12'hfff;
        end
        else if (P == SPGO) begin
            rgb_next <= 12'hfff;
        end
        else if (P == SPSR) begin
            if (game_over_region) begin
                if (data_out_game_over==12'h0f0)
                    rgb_next = 12'hfff;
                else
                    rgb_next = data_out_game_over;
                end
            else if (number_region) begin
                if (number_idx >= 0 && number_idx <= 6) begin
                    if (scorebroad[number_idx] >= 1 && scorebroad[number_idx] <= 9)begin
                        if (data_out_number[scorebroad[number_idx]] == 12'h0f0)
                            rgb_next = 12'hfff;
                        else
                            rgb_next = data_out_number[scorebroad[number_idx]];
                    end 
                    else begin
                        if (data_out_number[scorebroad[number_idx]]==12'h0f0)
                            rgb_next = 12'hfff;
                        else
                            rgb_next = data_out_number[0];
                    end
                end 
            end
            //james
            else if(score_picture_region==1)begin
                if (data_out_score_picture==12'h0f0)
                    rgb_next = 12'hfff;
                else
                    rgb_next = data_out_score_picture;
            end
            else 
                rgb_next <= 12'hfff;    
        end
    end
end
//End of VGA display

//FSM
assign picked = btn_pressed[1];
assign inited = init_counter == initial_time;
always @(posedge clk ) begin
    if (~reset_n) begin
        P_next <= IDLE;
    end
    else begin
        P <= P_next;
    end

    case (P)
        IDLE: begin
            if (btn_pressed[0] || btn_pressed[1] || btn_pressed[2] || btn_pressed[3]) P_next <= SPPM;
            else P_next <= IDLE;
        end
        SPPM: begin
            if (picked) P_next <= SPIG;
            else P_next <= SPPM;
        end
        SPIG: begin
            P_next <= SPGP;
        end
        SPFL: begin
            if (fallen) P_next <= SPUG;
            else if (SP_gnrtobst) P_next <= SPGO;
            else if (SP_hold && (pre_holded_idx == 128)) P_next <= SPGP;
            else P_next <= SPFL;
        end
        SPUG: begin
            // if (dead) P_next <= SPSR; 
            if (dead) P_next <= SPSR; 
            else P_next <= SPCL;
        end
        SPCL: begin
            if (cleared) P_next <= SPGP;
            else P_next <= SPCL;
        end
        SPGP: begin
            P_next <= SPPP;
        end
        SPPP: begin
            P_next <= SPFL;
        end
        SPGO: begin
            P_next <= SPFL;
        end
        SPSR: begin
            if (exit) P_next <= IDLE;
            else P_next <= SPSR;
        end
        default: begin
            P_next <= IDLE;
        end
    endcase
end
//End of FSM

//Game (tetromino, grid...)
integer idx, idx_cl;
assign row_full = grid[boundary / 14 * 14 + 2] != 0
                    && grid[boundary / 14 * 14 + 3] != 0
                    && grid[boundary / 14 * 14 + 4] != 0
                    && grid[boundary / 14 * 14 + 5] != 0
                    && grid[boundary / 14 * 14 + 6] != 0
                    && grid[boundary / 14 * 14 + 7] != 0
                    && grid[boundary / 14 * 14 + 8] != 0
                    && grid[boundary / 14 * 14 + 9] != 0
                    && grid[boundary / 14 * 14 + 10] != 0
                    && grid[boundary / 14 * 14 + 11] != 0;

assign dead = grid[2] != 0 || grid[3] != 0 || grid[4] != 0 || grid[5] != 0 || grid[6] != 0 || grid[7] != 0 || grid[8] != 0 || grid[9] != 0 || grid[10] != 0 || grid[11] != 0;
assign cleared = cl_counter == 3;
assign current_tetro_idx = ((holded == 1) && (first_hold == 0)) ? pre_holded_idx : tetromino_ctr - 5;
// assign t_spin_period = t_spin_counter < 
assign t_spin_single = current_tetromino == tetro_T
                    && current_state == T_2
                    && grid[current_pos + 13] != 0 
                    && grid[current_pos + 15] != 0
                    && (grid[current_pos - 15] != 0 || grid[current_pos - 13] != 0)
                    && line_cleared == 1;
assign t_spin_double = current_tetromino == tetro_T
                    && current_state == T_2
                    && grid[current_pos + 13] != 0 
                    && grid[current_pos + 15] != 0
                    && (grid[current_pos - 15] != 0 || grid[current_pos - 13] != 0)
                    && line_cleared == 2;
assign t_spin_triple = ((current_tetromino == tetro_T
            && current_state == T_L
            && grid[current_pos - 45] != 0 
            && grid[current_pos - 42] != 0 
            && grid[current_pos - 31] != 0 
            && grid[current_pos - 27] != 0 
            && grid[current_pos - 15] != 0 
            && grid[current_pos - 13] != 0 
            && grid[current_pos - 2] != 0 
            && grid[current_pos + 1] != 0 
            && grid[current_pos + 13] != 0 
            && grid[current_pos + 15] != 0
            && line_cleared == 3)
            ||
            (current_tetromino == tetro_T
            && current_state == T_R
            && grid[current_pos - 42] != 0 
            && grid[current_pos - 39] != 0 
            && grid[current_pos - 29] != 0 
            && grid[current_pos - 25] != 0 
            && grid[current_pos - 15] != 0 
            && grid[current_pos - 13] != 0 
            && grid[current_pos - 1] != 0 
            && grid[current_pos + 2] != 0 
            && grid[current_pos + 13] != 0 
            && grid[current_pos + 15] != 0
            && line_cleared == 3));

always @(posedge clk ) begin
    current_tetromino <= tetro_list[current_tetro_idx];
    if (P == IDLE) begin
        map <= 0;
        score <= 0;
    end
    if (P == SPPM) begin
        if (btn_pressed[0]) begin
            map <= (map == map_size) ? 0 : map + 1;
        end
        else if (btn_pressed[2]) begin
            map <= (map == 0) ? map_size : map - 1;
        end

        // initial map
        if (map == 0) begin //none
            grid[  0] <= 1; grid[  1] <= 1; grid[  2] <= 0; grid[  3] <= 0; grid[  4] <= 0; grid[  5] <= 0; grid[  6] <= 0; grid[  7] <= 0; grid[  8] <= 0; grid[  9] <= 0; grid[ 10] <= 0; grid[ 11] <= 0; grid[ 12] <= 1; grid[ 13] <= 1; 
            grid[ 14] <= 1; grid[ 15] <= 1; grid[ 16] <= 0; grid[ 17] <= 0; grid[ 18] <= 0; grid[ 19] <= 0; grid[ 20] <= 0; grid[ 21] <= 0; grid[ 22] <= 0; grid[ 23] <= 0; grid[ 24] <= 0; grid[ 25] <= 0; grid[ 26] <= 1; grid[ 27] <= 1; 
            grid[ 28] <= 1; grid[ 29] <= 1; grid[ 30] <= 0; grid[ 31] <= 0; grid[ 32] <= 0; grid[ 33] <= 0; grid[ 34] <= 0; grid[ 35] <= 0; grid[ 36] <= 0; grid[ 37] <= 0; grid[ 38] <= 0; grid[ 39] <= 0; grid[ 40] <= 1; grid[ 41] <= 1; 
            grid[ 42] <= 1; grid[ 43] <= 1; grid[ 44] <= 0; grid[ 45] <= 0; grid[ 46] <= 0; grid[ 47] <= 0; grid[ 48] <= 0; grid[ 49] <= 0; grid[ 50] <= 0; grid[ 51] <= 0; grid[ 52] <= 0; grid[ 53] <= 0; grid[ 54] <= 1; grid[ 55] <= 1; 
            grid[ 56] <= 1; grid[ 57] <= 1; grid[ 58] <= 0; grid[ 59] <= 0; grid[ 60] <= 0; grid[ 61] <= 0; grid[ 62] <= 0; grid[ 63] <= 0; grid[ 64] <= 0; grid[ 65] <= 0; grid[ 66] <= 0; grid[ 67] <= 0; grid[ 68] <= 1; grid[ 69] <= 1; 
            grid[ 70] <= 1; grid[ 71] <= 1; grid[ 72] <= 0; grid[ 73] <= 0; grid[ 74] <= 0; grid[ 75] <= 0; grid[ 76] <= 0; grid[ 77] <= 0; grid[ 78] <= 0; grid[ 79] <= 0; grid[ 80] <= 0; grid[ 81] <= 0; grid[ 82] <= 1; grid[ 83] <= 1; 
            grid[ 84] <= 1; grid[ 85] <= 1; grid[ 86] <= 0; grid[ 87] <= 0; grid[ 88] <= 0; grid[ 89] <= 0; grid[ 90] <= 0; grid[ 91] <= 0; grid[ 92] <= 0; grid[ 93] <= 0; grid[ 94] <= 0; grid[ 95] <= 0; grid[ 96] <= 1; grid[ 97] <= 1; 
            grid[ 98] <= 1; grid[ 99] <= 1; grid[100] <= 0; grid[101] <= 0; grid[102] <= 0; grid[103] <= 0; grid[104] <= 0; grid[105] <= 0; grid[106] <= 0; grid[107] <= 0; grid[108] <= 0; grid[109] <= 0; grid[110] <= 1; grid[111] <= 1; 
            grid[112] <= 1; grid[113] <= 1; grid[114] <= 0; grid[115] <= 0; grid[116] <= 0; grid[117] <= 0; grid[118] <= 0; grid[119] <= 0; grid[120] <= 0; grid[121] <= 0; grid[122] <= 0; grid[123] <= 0; grid[124] <= 1; grid[125] <= 1; 
            grid[126] <= 1; grid[127] <= 1; grid[128] <= 0; grid[129] <= 0; grid[130] <= 0; grid[131] <= 0; grid[132] <= 0; grid[133] <= 0; grid[134] <= 0; grid[135] <= 0; grid[136] <= 0; grid[137] <= 0; grid[138] <= 1; grid[139] <= 1; 
            grid[140] <= 1; grid[141] <= 1; grid[142] <= 0; grid[143] <= 0; grid[144] <= 0; grid[145] <= 0; grid[146] <= 0; grid[147] <= 0; grid[148] <= 0; grid[149] <= 0; grid[150] <= 0; grid[151] <= 0; grid[152] <= 1; grid[153] <= 1; 
            grid[154] <= 1; grid[155] <= 1; grid[156] <= 0; grid[157] <= 0; grid[158] <= 0; grid[159] <= 0; grid[160] <= 0; grid[161] <= 0; grid[162] <= 0; grid[163] <= 0; grid[164] <= 0; grid[165] <= 0; grid[166] <= 1; grid[167] <= 1; 
            grid[168] <= 1; grid[169] <= 1; grid[170] <= 0; grid[171] <= 0; grid[172] <= 0; grid[173] <= 0; grid[174] <= 0; grid[175] <= 0; grid[176] <= 0; grid[177] <= 0; grid[178] <= 0; grid[179] <= 0; grid[180] <= 1; grid[181] <= 1; 
            grid[182] <= 1; grid[183] <= 1; grid[184] <= 0; grid[185] <= 0; grid[186] <= 0; grid[187] <= 0; grid[188] <= 0; grid[189] <= 0; grid[190] <= 0; grid[191] <= 0; grid[192] <= 0; grid[193] <= 0; grid[194] <= 1; grid[195] <= 1; 
            grid[196] <= 1; grid[197] <= 1; grid[198] <= 0; grid[199] <= 0; grid[200] <= 0; grid[201] <= 0; grid[202] <= 0; grid[203] <= 0; grid[204] <= 0; grid[205] <= 0; grid[206] <= 0; grid[207] <= 0; grid[208] <= 1; grid[209] <= 1; 
            grid[210] <= 1; grid[211] <= 1; grid[212] <= 0; grid[213] <= 0; grid[214] <= 0; grid[215] <= 0; grid[216] <= 0; grid[217] <= 0; grid[218] <= 0; grid[219] <= 0; grid[220] <= 0; grid[221] <= 0; grid[222] <= 1; grid[223] <= 1; 
            grid[224] <= 1; grid[225] <= 1; grid[226] <= 0; grid[227] <= 0; grid[228] <= 0; grid[229] <= 0; grid[230] <= 0; grid[231] <= 0; grid[232] <= 0; grid[233] <= 0; grid[234] <= 0; grid[235] <= 0; grid[236] <= 1; grid[237] <= 1; 
            grid[238] <= 1; grid[239] <= 1; grid[240] <= 0; grid[241] <= 0; grid[242] <= 0; grid[243] <= 0; grid[244] <= 0; grid[245] <= 0; grid[246] <= 0; grid[247] <= 0; grid[248] <= 0; grid[249] <= 0; grid[250] <= 1; grid[251] <= 1; 
            grid[252] <= 1; grid[253] <= 1; grid[254] <= 0; grid[255] <= 0; grid[256] <= 0; grid[257] <= 0; grid[258] <= 0; grid[259] <= 0; grid[260] <= 0; grid[261] <= 0; grid[262] <= 0; grid[263] <= 0; grid[264] <= 1; grid[265] <= 1; 
            grid[266] <= 1; grid[267] <= 1; grid[268] <= 0; grid[269] <= 0; grid[270] <= 0; grid[271] <= 0; grid[272] <= 0; grid[273] <= 0; grid[274] <= 0; grid[275] <= 0; grid[276] <= 0; grid[277] <= 0; grid[278] <= 1; grid[279] <= 1; 
            grid[280] <= 1; grid[281] <= 1; grid[282] <= 0; grid[283] <= 0; grid[284] <= 0; grid[285] <= 0; grid[286] <= 0; grid[287] <= 0; grid[288] <= 0; grid[289] <= 0; grid[290] <= 0; grid[291] <= 0; grid[292] <= 1; grid[293] <= 1; 
            grid[294] <= 1; grid[295] <= 1; grid[296] <= 0; grid[297] <= 0; grid[298] <= 0; grid[299] <= 0; grid[300] <= 0; grid[301] <= 0; grid[302] <= 0; grid[303] <= 0; grid[304] <= 0; grid[305] <= 0; grid[306] <= 1; grid[307] <= 1; 
            grid[308] <= 1; grid[309] <= 1; grid[310] <= 1; grid[311] <= 1; grid[312] <= 1; grid[313] <= 1; grid[314] <= 1; grid[315] <= 1; grid[316] <= 1; grid[317] <= 1; grid[318] <= 1; grid[319] <= 1; grid[320] <= 1; grid[321] <= 1; 
            grid[322] <= 1; grid[323] <= 1; grid[324] <= 1; grid[325] <= 1; grid[326] <= 1; grid[327] <= 1; grid[328] <= 1; grid[329] <= 1; grid[330] <= 1; grid[331] <= 1; grid[332] <= 1; grid[333] <= 1; grid[334] <= 1; grid[335] <= 1; 
        end
        else if (map == 1) begin // broken
            grid[  0] <= 1; grid[  1] <= 1; grid[  2] <= 0; grid[  3] <= 0; grid[  4] <= 0; grid[  5] <= 0; grid[  6] <= 0; grid[  7] <= 0; grid[  8] <= 0; grid[  9] <= 0; grid[ 10] <= 0; grid[ 11] <= 0; grid[ 12] <= 1; grid[ 13] <= 1; 
            grid[ 14] <= 1; grid[ 15] <= 1; grid[ 16] <= 0; grid[ 17] <= 0; grid[ 18] <= 0; grid[ 19] <= 0; grid[ 20] <= 0; grid[ 21] <= 0; grid[ 22] <= 0; grid[ 23] <= 0; grid[ 24] <= 0; grid[ 25] <= 0; grid[ 26] <= 1; grid[ 27] <= 1; 
            grid[ 28] <= 1; grid[ 29] <= 1; grid[ 30] <= 0; grid[ 31] <= 0; grid[ 32] <= 0; grid[ 33] <= 0; grid[ 34] <= 0; grid[ 35] <= 0; grid[ 36] <= 0; grid[ 37] <= 0; grid[ 38] <= 0; grid[ 39] <= 0; grid[ 40] <= 1; grid[ 41] <= 1; 
            grid[ 42] <= 1; grid[ 43] <= 1; grid[ 44] <= 0; grid[ 45] <= 0; grid[ 46] <= 0; grid[ 47] <= 0; grid[ 48] <= 0; grid[ 49] <= 0; grid[ 50] <= 7; grid[ 51] <= 7; grid[ 52] <= 0; grid[ 53] <= 0; grid[ 54] <= 1; grid[ 55] <= 1; 
            grid[ 56] <= 1; grid[ 57] <= 1; grid[ 58] <= 0; grid[ 59] <= 0; grid[ 60] <= 0; grid[ 61] <= 0; grid[ 62] <= 0; grid[ 63] <= 0; grid[ 64] <= 0; grid[ 65] <= 7; grid[ 66] <= 0; grid[ 67] <= 0; grid[ 68] <= 1; grid[ 69] <= 1; 
            grid[ 70] <= 1; grid[ 71] <= 1; grid[ 72] <= 1; grid[ 73] <= 1; grid[ 74] <= 7; grid[ 75] <= 7; grid[ 76] <= 7; grid[ 77] <= 7; grid[ 78] <= 0; grid[ 79] <= 7; grid[ 80] <= 1; grid[ 81] <= 1; grid[ 82] <= 1; grid[ 83] <= 1; 
            grid[ 84] <= 1; grid[ 85] <= 1; grid[ 86] <= 1; grid[ 87] <= 7; grid[ 88] <= 7; grid[ 89] <= 7; grid[ 90] <= 7; grid[ 91] <= 0; grid[ 92] <= 0; grid[ 93] <= 7; grid[ 94] <= 7; grid[ 95] <= 1; grid[ 96] <= 1; grid[ 97] <= 1; 
            grid[ 98] <= 1; grid[ 99] <= 1; grid[100] <= 1; grid[101] <= 7; grid[102] <= 7; grid[103] <= 7; grid[104] <= 0; grid[105] <= 0; grid[106] <= 0; grid[107] <= 7; grid[108] <= 7; grid[109] <= 1; grid[110] <= 1; grid[111] <= 1; 
            grid[112] <= 1; grid[113] <= 1; grid[114] <= 1; grid[115] <= 1; grid[116] <= 1; grid[117] <= 1; grid[118] <= 0; grid[119] <= 7; grid[120] <= 7; grid[121] <= 7; grid[122] <= 7; grid[123] <= 7; grid[124] <= 1; grid[125] <= 1; 
            grid[126] <= 1; grid[127] <= 1; grid[128] <= 1; grid[129] <= 1; grid[130] <= 1; grid[131] <= 1; grid[132] <= 0; grid[133] <= 0; grid[134] <= 7; grid[135] <= 7; grid[136] <= 7; grid[137] <= 7; grid[138] <= 1; grid[139] <= 1; 
            grid[140] <= 1; grid[141] <= 1; grid[142] <= 1; grid[143] <= 1; grid[144] <= 1; grid[145] <= 1; grid[146] <= 0; grid[147] <= 0; grid[148] <= 0; grid[149] <= 7; grid[150] <= 7; grid[151] <= 7; grid[152] <= 1; grid[153] <= 1; 
            grid[154] <= 1; grid[155] <= 1; grid[156] <= 1; grid[157] <= 7; grid[158] <= 7; grid[159] <= 7; grid[160] <= 7; grid[161] <= 1; grid[162] <= 0; grid[163] <= 7; grid[164] <= 7; grid[165] <= 7; grid[166] <= 1; grid[167] <= 1; 
            grid[168] <= 1; grid[169] <= 1; grid[170] <= 1; grid[171] <= 7; grid[172] <= 7; grid[173] <= 7; grid[174] <= 7; grid[175] <= 0; grid[176] <= 0; grid[177] <= 7; grid[178] <= 7; grid[179] <= 7; grid[180] <= 1; grid[181] <= 1; 
            grid[182] <= 1; grid[183] <= 1; grid[184] <= 1; grid[185] <= 7; grid[186] <= 7; grid[187] <= 7; grid[188] <= 0; grid[189] <= 0; grid[190] <= 0; grid[191] <= 7; grid[192] <= 7; grid[193] <= 7; grid[194] <= 1; grid[195] <= 1; 
            grid[196] <= 1; grid[197] <= 1; grid[198] <= 1; grid[199] <= 7; grid[200] <= 7; grid[201] <= 7; grid[202] <= 0; grid[203] <= 1; grid[204] <= 7; grid[205] <= 7; grid[206] <= 7; grid[207] <= 7; grid[208] <= 1; grid[209] <= 1; 
            grid[210] <= 1; grid[211] <= 1; grid[212] <= 1; grid[213] <= 7; grid[214] <= 7; grid[215] <= 7; grid[216] <= 0; grid[217] <= 0; grid[218] <= 7; grid[219] <= 7; grid[220] <= 1; grid[221] <= 1; grid[222] <= 1; grid[223] <= 1; 
            grid[224] <= 1; grid[225] <= 1; grid[226] <= 1; grid[227] <= 7; grid[228] <= 7; grid[229] <= 1; grid[230] <= 0; grid[231] <= 0; grid[232] <= 0; grid[233] <= 7; grid[234] <= 1; grid[235] <= 1; grid[236] <= 1; grid[237] <= 1; 
            grid[238] <= 1; grid[239] <= 1; grid[240] <= 1; grid[241] <= 7; grid[242] <= 7; grid[243] <= 1; grid[244] <= 1; grid[245] <= 7; grid[246] <= 0; grid[247] <= 7; grid[248] <= 1; grid[249] <= 1; grid[250] <= 1; grid[251] <= 1; 
            grid[252] <= 1; grid[253] <= 1; grid[254] <= 1; grid[255] <= 7; grid[256] <= 7; grid[257] <= 1; grid[258] <= 1; grid[259] <= 0; grid[260] <= 0; grid[261] <= 7; grid[262] <= 1; grid[263] <= 1; grid[264] <= 1; grid[265] <= 1; 
            grid[266] <= 1; grid[267] <= 1; grid[268] <= 1; grid[269] <= 7; grid[270] <= 7; grid[271] <= 1; grid[272] <= 1; grid[273] <= 0; grid[274] <= 0; grid[275] <= 0; grid[276] <= 1; grid[277] <= 1; grid[278] <= 1; grid[279] <= 1; 
            grid[280] <= 1; grid[281] <= 1; grid[282] <= 1; grid[283] <= 1; grid[284] <= 1; grid[285] <= 1; grid[286] <= 1; grid[287] <= 1; grid[288] <= 0; grid[289] <= 1; grid[290] <= 1; grid[291] <= 1; grid[292] <= 1; grid[293] <= 1; 
            grid[294] <= 1; grid[295] <= 1; grid[296] <= 1; grid[297] <= 1; grid[298] <= 1; grid[299] <= 1; grid[300] <= 1; grid[301] <= 1; grid[302] <= 0; grid[303] <= 1; grid[304] <= 1; grid[305] <= 1; grid[306] <= 1; grid[307] <= 1; 
            grid[308] <= 1; grid[309] <= 1; grid[310] <= 1; grid[311] <= 1; grid[312] <= 1; grid[313] <= 1; grid[314] <= 1; grid[315] <= 1; grid[316] <= 1; grid[317] <= 1; grid[318] <= 1; grid[319] <= 1; grid[320] <= 1; grid[321] <= 1; 
            grid[322] <= 1; grid[323] <= 1; grid[324] <= 1; grid[325] <= 1; grid[326] <= 1; grid[327] <= 1; grid[328] <= 1; grid[329] <= 1; grid[330] <= 1; grid[331] <= 1; grid[332] <= 1; grid[333] <= 1; grid[334] <= 1; grid[335] <= 1; 
        end
        else if (map == 2) begin // elevator
            grid[  0] <= 1; grid[  1] <= 1; grid[  2] <= 0; grid[  3] <= 0; grid[  4] <= 0; grid[  5] <= 0; grid[  6] <= 0; grid[  7] <= 0; grid[  8]<= 0; grid[  9] <= 0; grid[ 10] <= 0; grid[ 11] <= 0; grid[ 12] <= 1; grid[ 13] <= 1; 
            grid[ 14] <= 1; grid[ 15] <= 1; grid[ 16] <= 0; grid[ 17] <= 0; grid[ 18] <= 0; grid[ 19] <= 0; grid[ 20] <= 0; grid[ 21] <= 0; grid[ 22] <= 0; grid[ 23] <= 0; grid[ 24] <= 0; grid[ 25] <= 0; grid[ 26] <= 1; grid[ 27] <= 1; 
            grid[ 28] <= 1; grid[ 29] <= 1; grid[ 30] <= 0; grid[ 31] <= 0; grid[ 32] <= 0; grid[ 33] <= 0; grid[ 34] <= 0; grid[ 35] <= 0; grid[ 36] <= 0; grid[ 37] <= 0; grid[ 38] <= 0; grid[ 39] <= 0; grid[ 40] <= 1; grid[ 41] <= 1; 
            grid[ 42] <= 1; grid[ 43] <= 1; grid[ 44] <= 6; grid[ 45] <= 0; grid[ 46] <= 0; grid[ 47] <= 0; grid[ 48] <= 0; grid[ 49] <= 0; grid[ 50] <= 0; grid[ 51] <= 0; grid[ 52] <= 0; grid[ 53] <= 0; grid[ 54] <= 1; grid[ 55] <= 1; 
            grid[ 56] <= 1; grid[ 57] <= 1; grid[ 58] <= 6; grid[ 59] <= 0; grid[ 60] <= 0; grid[ 61] <= 0; grid[ 62] <= 6; grid[ 63] <= 6; grid[ 64] <= 6; grid[ 65] <= 6; grid[ 66] <= 0; grid[ 67] <= 0; grid[ 68] <= 1; grid[ 69] <= 1; 
            grid[ 70] <= 1; grid[ 71] <= 1; grid[ 72] <= 6; grid[ 73] <= 0; grid[ 74] <= 1; grid[ 75] <= 0; grid[ 76] <= 6; grid[ 77] <= 6; grid[ 78] <= 6; grid[ 79] <= 6; grid[ 80] <= 0; grid[ 81] <= 0; grid[ 82] <= 1; grid[ 83] <= 1; 
            grid[ 84] <= 1; grid[ 85] <= 1; grid[ 86] <= 6; grid[ 87] <= 0; grid[ 88] <= 0; grid[ 89] <= 0; grid[ 90] <= 6; grid[ 91] <= 6; grid[ 92] <= 6; grid[ 93] <= 6; grid[ 94] <= 0; grid[ 95] <= 0; grid[ 96] <= 1; grid[ 97] <= 1; 
            grid[ 98] <= 1; grid[ 99] <= 1; grid[100] <= 6; grid[101] <= 6; grid[102] <= 0; grid[103] <= 0; grid[104] <= 0; grid[105] <= 6; grid[106] <= 6; grid[107] <= 6; grid[108] <= 0; grid[109] <= 0; grid[110] <= 1; grid[111] <= 1; 
            grid[112] <= 1; grid[113] <= 1; grid[114] <= 6; grid[115] <= 6; grid[116] <= 0; grid[117] <= 0; grid[118] <= 0; grid[119] <= 6; grid[120] <= 6; grid[121] <= 6; grid[122] <= 0; grid[123] <= 0; grid[124] <= 1; grid[125] <= 1; 
            grid[126] <= 1; grid[127] <= 1; grid[128] <= 6; grid[129] <= 6; grid[130] <= 0; grid[131] <= 1; grid[132] <= 0; grid[133] <= 6; grid[134] <= 6; grid[135] <= 6; grid[136] <= 0; grid[137] <= 0; grid[138] <= 1; grid[139] <= 1; 
            grid[140] <= 1; grid[141] <= 1; grid[142] <= 6; grid[143] <= 6; grid[144] <= 0; grid[145] <= 0; grid[146] <= 0; grid[147] <= 6; grid[148] <= 6; grid[149] <= 6; grid[150] <= 0; grid[151] <= 0; grid[152] <= 1; grid[153] <= 1; 
            grid[154] <= 1; grid[155] <= 1; grid[156] <= 6; grid[157] <= 6; grid[158] <= 6; grid[159] <= 0; grid[160] <= 0; grid[161] <= 0; grid[162] <= 6; grid[163] <= 6; grid[164] <= 0; grid[165] <= 0; grid[166] <= 1; grid[167] <= 1; 
            grid[168] <= 1; grid[169] <= 1; grid[170] <= 6; grid[171] <= 6; grid[172] <= 6; grid[173] <= 0; grid[174] <= 0; grid[175] <= 0; grid[176] <= 6; grid[177] <= 6; grid[178] <= 0; grid[179] <= 0; grid[180] <= 1; grid[181] <= 1; 
            grid[182] <= 1; grid[183] <= 1; grid[184] <= 6; grid[185] <= 6; grid[186] <= 6; grid[187] <= 0; grid[188] <= 1; grid[189] <= 0; grid[190] <= 6; grid[191] <= 6; grid[192] <= 0; grid[193] <= 0; grid[194] <= 1; grid[195] <= 1; 
            grid[196] <= 1; grid[197] <= 1; grid[198] <= 6; grid[199] <= 6; grid[200] <= 6; grid[201] <= 0; grid[202] <= 0; grid[203] <= 0; grid[204] <= 6; grid[205] <= 6; grid[206] <= 0; grid[207] <= 0; grid[208] <= 1; grid[209] <= 1; 
            grid[210] <= 1; grid[211] <= 1; grid[212] <= 6; grid[213] <= 6; grid[214] <= 6; grid[215] <= 6; grid[216] <= 0; grid[217] <= 0; grid[218] <= 0; grid[219] <= 6; grid[220] <= 0; grid[221] <= 0; grid[222] <= 1; grid[223] <= 1; 
            grid[224] <= 1; grid[225] <= 1; grid[226] <= 6; grid[227] <= 6; grid[228] <= 6; grid[229] <= 6; grid[230] <= 0; grid[231] <= 0; grid[232] <= 0; grid[233] <= 6; grid[234] <= 0; grid[235] <= 0; grid[236] <= 1; grid[237] <= 1; 
            grid[238] <= 1; grid[239] <= 1; grid[240] <= 6; grid[241] <= 6; grid[242] <= 6; grid[243] <= 6; grid[244] <= 0; grid[245] <= 1; grid[246] <= 0; grid[247] <= 6; grid[248] <= 0; grid[249] <= 0; grid[250] <= 1; grid[251] <= 1; 
            grid[252] <= 1; grid[253] <= 1; grid[254] <= 6; grid[255] <= 6; grid[256] <= 6; grid[257] <= 6; grid[258] <= 0; grid[259] <= 0; grid[260] <= 0; grid[261] <= 6; grid[262] <= 0; grid[263] <= 0; grid[264] <= 1; grid[265] <= 1; 
            grid[266] <= 1; grid[267] <= 1; grid[268] <= 6; grid[269] <= 6; grid[270] <= 6; grid[271] <= 6; grid[272] <= 6; grid[273] <= 0; grid[274] <= 0; grid[275] <= 0; grid[276] <= 0; grid[277] <= 0; grid[278] <= 1; grid[279] <= 1; 
            grid[280] <= 1; grid[281] <= 1; grid[282] <= 6; grid[283] <= 6; grid[284] <= 6; grid[285] <= 6; grid[286] <= 6; grid[287] <= 0; grid[288] <= 0; grid[289] <= 0; grid[290] <= 0; grid[291] <= 0; grid[292] <= 1; grid[293] <= 1; 
            grid[294] <= 1; grid[295] <= 1; grid[296] <= 6; grid[297] <= 6; grid[298] <= 6; grid[299] <= 6; grid[300] <= 6; grid[301] <= 0; grid[302] <= 6; grid[303] <= 6; grid[304] <= 6; grid[305] <= 6; grid[306] <= 1; grid[307] <= 1; 
            grid[308] <= 1; grid[309] <= 1; grid[310] <= 1; grid[311] <= 1; grid[312] <= 1; grid[313] <= 1; grid[314] <= 1; grid[315] <= 1; grid[316] <= 1; grid[317] <= 1; grid[318] <= 1; grid[319] <= 1; grid[320] <= 1; grid[321] <= 1; 
            grid[322] <= 1; grid[323] <= 1; grid[324] <= 1; grid[325] <= 1; grid[326] <= 1; grid[327] <= 1; grid[328] <= 1; grid[329] <= 1; grid[330] <= 1; grid[331] <= 1; grid[332] <= 1; grid[333] <= 1; grid[334] <= 1; grid[335] <= 1;         
        end
        else if (map == 3) begin // egypt
            grid[  0] <= 1; grid[  1] <= 1; grid[  2] <= 0; grid[  3] <= 0; grid[  4] <= 0; grid[  5] <= 0; grid[  6] <= 0; grid[  7] <= 0; grid[  8] <= 0; grid[  9] <= 0; grid[ 10] <= 0; grid[ 11] <= 0; grid[ 12] <= 1; grid[ 13] <= 1; 
            grid[ 14] <= 1; grid[ 15] <= 1; grid[ 16] <= 0; grid[ 17] <= 0; grid[ 18] <= 0; grid[ 19] <= 0; grid[ 20] <= 0; grid[ 21] <= 0; grid[ 22] <= 0; grid[ 23] <= 0; grid[ 24] <= 0; grid[ 25] <= 0; grid[ 26] <= 1; grid[ 27] <= 1; 
            grid[ 28] <= 1; grid[ 29] <= 1; grid[ 30] <= 0; grid[ 31] <= 0; grid[ 32] <= 0; grid[ 33] <= 0; grid[ 34] <= 0; grid[ 35] <= 0; grid[ 36] <= 0; grid[ 37] <= 0; grid[ 38] <= 0; grid[ 39] <= 0; grid[ 40] <= 1; grid[ 41] <= 1; 
            grid[ 42] <= 1; grid[ 43] <= 1; grid[ 44] <= 0; grid[ 45] <= 0; grid[ 46] <= 0; grid[ 47] <= 0; grid[ 48] <= 0; grid[ 49] <= 0; grid[ 50] <= 0; grid[ 51] <= 0; grid[ 52] <= 0; grid[ 53] <= 0; grid[ 54] <= 1; grid[ 55] <= 1; 
            grid[ 56] <= 1; grid[ 57] <= 1; grid[ 58] <= 0; grid[ 59] <= 0; grid[ 60] <= 0; grid[ 61] <= 0; grid[ 62] <= 0; grid[ 63] <= 0; grid[ 64] <= 0; grid[ 65] <= 0; grid[ 66] <= 0; grid[ 67] <= 0; grid[ 68] <= 1; grid[ 69] <= 1; 
            grid[ 70] <= 1; grid[ 71] <= 1; grid[ 72] <= 0; grid[ 73] <= 0; grid[ 74] <= 0; grid[ 75] <= 0; grid[ 76] <= 0; grid[ 77] <= 0; grid[ 78] <= 0; grid[ 79] <= 0; grid[ 80] <= 0; grid[ 81] <= 0; grid[ 82] <= 1; grid[ 83] <= 1; 
            grid[ 84] <= 1; grid[ 85] <= 1; grid[ 86] <= 0; grid[ 87] <= 0; grid[ 88] <= 0; grid[ 89] <= 0; grid[ 90] <= 0; grid[ 91] <= 0; grid[ 92] <= 0; grid[ 93] <= 0; grid[ 94] <= 0; grid[ 95] <= 0; grid[ 96] <= 1; grid[ 97] <= 1; 
            grid[ 98] <= 1; grid[ 99] <= 1; grid[100] <= 0; grid[101] <= 0; grid[102] <= 0; grid[103] <= 0; grid[104] <= 0; grid[105] <= 0; grid[106] <= 0; grid[107] <= 0; grid[108] <= 0; grid[109] <= 0; grid[110] <= 1; grid[111] <= 1; 
            grid[112] <= 1; grid[113] <= 1; grid[114] <= 0; grid[115] <= 0; grid[116] <= 0; grid[117] <= 0; grid[118] <= 0; grid[119] <= 0; grid[120] <= 0; grid[121] <= 0; grid[122] <= 0; grid[123] <= 0; grid[124] <= 1; grid[125] <= 1; 
            grid[126] <= 1; grid[127] <= 1; grid[128] <= 0; grid[129] <= 0; grid[130] <= 0; grid[131] <= 0; grid[132] <= 0; grid[133] <= 0; grid[134] <= 0; grid[135] <= 0; grid[136] <= 0; grid[137] <= 0; grid[138] <= 1; grid[139] <= 1; 
            grid[140] <= 1; grid[141] <= 1; grid[142] <= 0; grid[143] <= 0; grid[144] <= 0; grid[145] <= 0; grid[146] <= 0; grid[147] <= 0; grid[148] <= 0; grid[149] <= 0; grid[150] <= 0; grid[151] <= 0; grid[152] <= 1; grid[153] <= 1; 
            grid[154] <= 1; grid[155] <= 1; grid[156] <= 0; grid[157] <= 0; grid[158] <= 0; grid[159] <= 0; grid[160] <= 0; grid[161] <= 0; grid[162] <= 0; grid[163] <= 0; grid[164] <= 0; grid[165] <= 0; grid[166] <= 1; grid[167] <= 1; 
            grid[168] <= 1; grid[169] <= 1; grid[170] <= 7; grid[171] <= 7; grid[172] <= 7; grid[173] <= 7; grid[174] <= 0; grid[175] <= 0; grid[176] <= 7; grid[177] <= 7; grid[178] <= 7; grid[179] <= 7; grid[180] <= 1; grid[181] <= 1; 
            grid[182] <= 1; grid[183] <= 1; grid[184] <= 7; grid[185] <= 0; grid[186] <= 0; grid[187] <= 2; grid[188] <= 0; grid[189] <= 0; grid[190] <= 2; grid[191] <= 7; grid[192] <= 7; grid[193] <= 7; grid[194] <= 1; grid[195] <= 1; 
            grid[196] <= 1; grid[197] <= 1; grid[198] <= 7; grid[199] <= 7; grid[200] <= 0; grid[201] <= 2; grid[202] <= 2; grid[203] <= 0; grid[204] <= 2; grid[205] <= 2; grid[206] <= 7; grid[207] <= 7; grid[208] <= 1; grid[209] <= 1; 
            grid[210] <= 1; grid[211] <= 1; grid[212] <= 7; grid[213] <= 2; grid[214] <= 0; grid[215] <= 0; grid[216] <= 0; grid[217] <= 0; grid[218] <= 0; grid[219] <= 0; grid[220] <= 2; grid[221] <= 7; grid[222] <= 1; grid[223] <= 1; 
            grid[224] <= 1; grid[225] <= 1; grid[226] <= 7; grid[227] <= 2; grid[228] <= 2; grid[229] <= 2; grid[230] <= 2; grid[231] <= 0; grid[232] <= 2; grid[233] <= 0; grid[234] <= 2; grid[235] <= 3; grid[236] <= 1; grid[237] <= 1; 
            grid[238] <= 1; grid[239] <= 1; grid[240] <= 7; grid[241] <= 2; grid[242] <= 2; grid[243] <= 2; grid[244] <= 2; grid[245] <= 0; grid[246] <= 2; grid[247] <= 0; grid[248] <= 0; grid[249] <= 3; grid[250] <= 1; grid[251] <= 1; 
            grid[252] <= 1; grid[253] <= 1; grid[254] <= 3; grid[255] <= 2; grid[256] <= 2; grid[257] <= 0; grid[258] <= 0; grid[259] <= 0; grid[260] <= 2; grid[261] <= 2; grid[262] <= 2; grid[263] <= 3; grid[264] <= 1; grid[265] <= 1; 
            grid[266] <= 1; grid[267] <= 1; grid[268] <= 3; grid[269] <= 3; grid[270] <= 2; grid[271] <= 0; grid[272] <= 2; grid[273] <= 0; grid[274] <= 2; grid[275] <= 2; grid[276] <= 3; grid[277] <= 3; grid[278] <= 1; grid[279] <= 1; 
            grid[280] <= 1; grid[281] <= 1; grid[282] <= 3; grid[283] <= 3; grid[284] <= 0; grid[285] <= 0; grid[286] <= 2; grid[287] <= 0; grid[288] <= 0; grid[289] <= 0; grid[290] <= 3; grid[291] <= 3; grid[292] <= 1; grid[293] <= 1; 
            grid[294] <= 1; grid[295] <= 1; grid[296] <= 3; grid[297] <= 3; grid[298] <= 3; grid[299] <= 3; grid[300] <= 3; grid[301] <= 3; grid[302] <= 3; grid[303] <= 0; grid[304] <= 3; grid[305] <= 3; grid[306] <= 1; grid[307] <= 1; 
            grid[308] <= 1; grid[309] <= 1; grid[310] <= 1; grid[311] <= 1; grid[312] <= 1; grid[313] <= 1; grid[314] <= 1; grid[315] <= 1; grid[316] <= 1; grid[317] <= 1; grid[318] <= 1; grid[319] <= 1; grid[320] <= 1; grid[321] <= 1; 
            grid[322] <= 1; grid[323] <= 1; grid[324] <= 1; grid[325] <= 1; grid[326] <= 1; grid[327] <= 1; grid[328] <= 1; grid[329] <= 1; grid[330] <= 1; grid[331] <= 1; grid[332] <= 1; grid[333] <= 1; grid[334] <= 1; grid[335] <= 1; 
        end
        else if (map == 4) begin // digging
            grid[  0] <= 1; grid[  1] <= 1; grid[  2] <= 0; grid[  3] <= 0; grid[  4] <= 0; grid[  5] <= 0; grid[  6] <= 0; grid[  7] <= 0; grid[  8] <= 0; grid[  9] <= 0; grid[ 10] <= 0; grid[ 11] <= 0; grid[ 12] <= 1; grid[ 13] <= 1; 
            grid[ 14] <= 1; grid[ 15] <= 1; grid[ 16] <= 0; grid[ 17] <= 0; grid[ 18] <= 0; grid[ 19] <= 0; grid[ 20] <= 0; grid[ 21] <= 0; grid[ 22] <= 0; grid[ 23] <= 0; grid[ 24] <= 0; grid[ 25] <= 0; grid[ 26] <= 1; grid[ 27] <= 1; 
            grid[ 28] <= 1; grid[ 29] <= 1; grid[ 30] <= 0; grid[ 31] <= 0; grid[ 32] <= 0; grid[ 33] <= 0; grid[ 34] <= 0; grid[ 35] <= 0; grid[ 36] <= 0; grid[ 37] <= 0; grid[ 38] <= 0; grid[ 39] <= 0; grid[ 40] <= 1; grid[ 41] <= 1; 
            grid[ 42] <= 1; grid[ 43] <= 1; grid[ 44] <= 0; grid[ 45] <= 0; grid[ 46] <= 0; grid[ 47] <= 0; grid[ 48] <= 0; grid[ 49] <= 0; grid[ 50] <= 0; grid[ 51] <= 0; grid[ 52] <= 0; grid[ 53] <= 0; grid[ 54] <= 1; grid[ 55] <= 1; 
            grid[ 56] <= 1; grid[ 57] <= 1; grid[ 58] <= 0; grid[ 59] <= 0; grid[ 60] <= 0; grid[ 61] <= 0; grid[ 62] <= 0; grid[ 63] <= 0; grid[ 64] <= 0; grid[ 65] <= 0; grid[ 66] <= 0; grid[ 67] <= 0; grid[ 68] <= 1; grid[ 69] <= 1; 
            grid[ 70] <= 1; grid[ 71] <= 1; grid[ 72] <= 0; grid[ 73] <= 0; grid[ 74] <= 0; grid[ 75] <= 0; grid[ 76] <= 0; grid[ 77] <= 0; grid[ 78] <= 0; grid[ 79] <= 0; grid[ 80] <= 0; grid[ 81] <= 0; grid[ 82] <= 1; grid[ 83] <= 1; 
            grid[ 84] <= 1; grid[ 85] <= 1; grid[ 86] <= 0; grid[ 87] <= 0; grid[ 88] <= 0; grid[ 89] <= 0; grid[ 90] <= 0; grid[ 91] <= 0; grid[ 92] <= 0; grid[ 93] <= 0; grid[ 94] <= 0; grid[ 95] <= 0; grid[ 96] <= 1; grid[ 97] <= 1; 
            grid[ 98] <= 1; grid[ 99] <= 1; grid[100] <= 0; grid[101] <= 0; grid[102] <= 0; grid[103] <= 0; grid[104] <= 0; grid[105] <= 0; grid[106] <= 0; grid[107] <= 0; grid[108] <= 0; grid[109] <= 0; grid[110] <= 1; grid[111] <= 1; 
            grid[112] <= 1; grid[113] <= 1; grid[114] <= 0; grid[115] <= 0; grid[116] <= 0; grid[117] <= 0; grid[118] <= 0; grid[119] <= 0; grid[120] <= 0; grid[121] <= 0; grid[122] <= 0; grid[123] <= 0; grid[124] <= 1; grid[125] <= 1; 
            grid[126] <= 1; grid[127] <= 1; grid[128] <= 0; grid[129] <= 0; grid[130] <= 0; grid[131] <= 0; grid[132] <= 0; grid[133] <= 0; grid[134] <= 0; grid[135] <= 0; grid[136] <= 0; grid[137] <= 0; grid[138] <= 1; grid[139] <= 1; 
            grid[140] <= 1; grid[141] <= 1; grid[142] <= 0; grid[143] <= 0; grid[144] <= 0; grid[145] <= 0; grid[146] <= 0; grid[147] <= 0; grid[148] <= 0; grid[149] <= 0; grid[150] <= 0; grid[151] <= 0; grid[152] <= 1; grid[153] <= 1; 
            grid[154] <= 1; grid[155] <= 1; grid[156] <= 0; grid[157] <= 0; grid[158] <= 0; grid[159] <= 0; grid[160] <= 0; grid[161] <= 0; grid[162] <= 0; grid[163] <= 0; grid[164] <= 0; grid[165] <= 0; grid[166] <= 1; grid[167] <= 1; 
            grid[168] <= 1; grid[169] <= 1; grid[170] <= 0; grid[171] <= 0; grid[172] <= 0; grid[173] <= 0; grid[174] <= 0; grid[175] <= 0; grid[176] <= 0; grid[177] <= 0; grid[178] <= 0; grid[179] <= 0; grid[180] <= 1; grid[181] <= 1; 
            grid[182] <= 1; grid[183] <= 1; grid[184] <= 0; grid[185] <= 0; grid[186] <= 0; grid[187] <= 0; grid[188] <= 0; grid[189] <= 0; grid[190] <= 0; grid[191] <= 0; grid[192] <= 0; grid[193] <= 0; grid[194] <= 1; grid[195] <= 1; 
            grid[196] <= 1; grid[197] <= 1; grid[198] <= 0; grid[199] <= 0; grid[200] <= 0; grid[201] <= 0; grid[202] <= 0; grid[203] <= 0; grid[204] <= 0; grid[205] <= 0; grid[206] <= 0; grid[207] <= 0; grid[208] <= 1; grid[209] <= 1; 
            grid[210] <= 1; grid[211] <= 1; grid[212] <= 0; grid[213] <= 0; grid[214] <= 0; grid[215] <= 0; grid[216] <= 0; grid[217] <= 0; grid[218] <= 0; grid[219] <= 0; grid[220] <= 0; grid[221] <= 0; grid[222] <= 1; grid[223] <= 1; 
            grid[224] <= 1; grid[225] <= 1; grid[226] <= 2; grid[227] <= 2; grid[228] <= 2; grid[229] <= 2; grid[230] <= 2; grid[231] <= 2; grid[232] <= 0; grid[233] <= 2; grid[234] <= 2; grid[235] <= 2; grid[236] <= 1; grid[237] <= 1; 
            grid[238] <= 1; grid[239] <= 1; grid[240] <= 2; grid[241] <= 2; grid[242] <= 2; grid[243] <= 0; grid[244] <= 2; grid[245] <= 2; grid[246] <= 2; grid[247] <= 2; grid[248] <= 2; grid[249] <= 2; grid[250] <= 1; grid[251] <= 1; 
            grid[252] <= 1; grid[253] <= 1; grid[254] <= 2; grid[255] <= 2; grid[256] <= 2; grid[257] <= 2; grid[258] <= 2; grid[259] <= 0; grid[260] <= 2; grid[261] <= 2; grid[262] <= 2; grid[263] <= 2; grid[264] <= 1; grid[265] <= 1; 
            grid[266] <= 1; grid[267] <= 1; grid[268] <= 2; grid[269] <= 2; grid[270] <= 2; grid[271] <= 2; grid[272] <= 2; grid[273] <= 2; grid[274] <= 2; grid[275] <= 2; grid[276] <= 0; grid[277] <= 2; grid[278] <= 1; grid[279] <= 1; 
            grid[280] <= 1; grid[281] <= 1; grid[282] <= 2; grid[283] <= 0; grid[284] <= 2; grid[285] <= 2; grid[286] <= 2; grid[287] <= 2; grid[288] <= 2; grid[289] <= 2; grid[290] <= 2; grid[291] <= 2; grid[292] <= 1; grid[293] <= 1; 
            grid[294] <= 1; grid[295] <= 1; grid[296] <= 2; grid[297] <= 2; grid[298] <= 2; grid[299] <= 2; grid[300] <= 2; grid[301] <= 2; grid[302] <= 2; grid[303] <= 0; grid[304] <= 2; grid[305] <= 2; grid[306] <= 1; grid[307] <= 1; 
            grid[308] <= 1; grid[309] <= 1; grid[310] <= 1; grid[311] <= 1; grid[312] <= 1; grid[313] <= 1; grid[314] <= 1; grid[315] <= 1; grid[316] <= 1; grid[317] <= 1; grid[318] <= 1; grid[319] <= 1; grid[320] <= 1; grid[321] <= 1; 
            grid[322] <= 1; grid[323] <= 1; grid[324] <= 1; grid[325] <= 1; grid[326] <= 1; grid[327] <= 1; grid[328] <= 1; grid[329] <= 1; grid[330] <= 1; grid[331] <= 1; grid[332] <= 1; grid[333] <= 1; grid[334] <= 1; grid[335] <= 1; 
        end
        else if (map == 5) begin // turtle
            grid[  0] <= 1; grid[  1] <= 1; grid[  2] <= 0; grid[  3] <= 0; grid[  4] <= 0; grid[  5] <= 0; grid[  6] <= 0; grid[  7] <= 0; grid[  8] <= 0; grid[  9] <= 0; grid[ 10] <= 0; grid[ 11] <= 0; grid[ 12] <= 1; grid[ 13] <= 1; 
            grid[ 14] <= 1; grid[ 15] <= 1; grid[ 16] <= 0; grid[ 17] <= 0; grid[ 18] <= 0; grid[ 19] <= 0; grid[ 20] <= 0; grid[ 21] <= 0; grid[ 22] <= 0; grid[ 23] <= 0; grid[ 24] <= 0; grid[ 25] <= 0; grid[ 26] <= 1; grid[ 27] <= 1; 
            grid[ 28] <= 1; grid[ 29] <= 1; grid[ 30] <= 0; grid[ 31] <= 0; grid[ 32] <= 0; grid[ 33] <= 0; grid[ 34] <= 0; grid[ 35] <= 0; grid[ 36] <= 0; grid[ 37] <= 0; grid[ 38] <= 0; grid[ 39] <= 0; grid[ 40] <= 1; grid[ 41] <= 1; 
            grid[ 42] <= 1; grid[ 43] <= 1; grid[ 44] <= 0; grid[ 45] <= 0; grid[ 46] <= 0; grid[ 47] <= 0; grid[ 48] <= 0; grid[ 49] <= 0; grid[ 50] <= 0; grid[ 51] <= 0; grid[ 52] <= 0; grid[ 53] <= 0; grid[ 54] <= 1; grid[ 55] <= 1; 
            grid[ 56] <= 1; grid[ 57] <= 1; grid[ 58] <= 0; grid[ 59] <= 0; grid[ 60] <= 0; grid[ 61] <= 0; grid[ 62] <= 0; grid[ 63] <= 0; grid[ 64] <= 0; grid[ 65] <= 0; grid[ 66] <= 0; grid[ 67] <= 0; grid[ 68] <= 1; grid[ 69] <= 1; 
            grid[ 70] <= 1; grid[ 71] <= 1; grid[ 72] <= 0; grid[ 73] <= 0; grid[ 74] <= 0; grid[ 75] <= 0; grid[ 76] <= 0; grid[ 77] <= 0; grid[ 78] <= 0; grid[ 79] <= 0; grid[ 80] <= 0; grid[ 81] <= 0; grid[ 82] <= 1; grid[ 83] <= 1; 
            grid[ 84] <= 1; grid[ 85] <= 1; grid[ 86] <= 0; grid[ 87] <= 0; grid[ 88] <= 0; grid[ 89] <= 0; grid[ 90] <= 0; grid[ 91] <= 0; grid[ 92] <= 0; grid[ 93] <= 0; grid[ 94] <= 0; grid[ 95] <= 0; grid[ 96] <= 1; grid[ 97] <= 1; 
            grid[ 98] <= 1; grid[ 99] <= 1; grid[100] <= 0; grid[101] <= 0; grid[102] <= 0; grid[103] <= 0; grid[104] <= 0; grid[105] <= 0; grid[106] <= 0; grid[107] <= 0; grid[108] <= 0; grid[109] <= 0; grid[110] <= 1; grid[111] <= 1; 
            grid[112] <= 1; grid[113] <= 1; grid[114] <= 0; grid[115] <= 0; grid[116] <= 0; grid[117] <= 0; grid[118] <= 0; grid[119] <= 0; grid[120] <= 0; grid[121] <= 0; grid[122] <= 0; grid[123] <= 0; grid[124] <= 1; grid[125] <= 1; 
            grid[126] <= 1; grid[127] <= 1; grid[128] <= 0; grid[129] <= 0; grid[130] <= 0; grid[131] <= 0; grid[132] <= 0; grid[133] <= 0; grid[134] <= 0; grid[135] <= 0; grid[136] <= 0; grid[137] <= 0; grid[138] <= 1; grid[139] <= 1; 
            grid[140] <= 1; grid[141] <= 1; grid[142] <= 0; grid[143] <= 0; grid[144] <= 0; grid[145] <= 0; grid[146] <= 0; grid[147] <= 0; grid[148] <= 0; grid[149] <= 0; grid[150] <= 0; grid[151] <= 0; grid[152] <= 1; grid[153] <= 1; 
            grid[154] <= 1; grid[155] <= 1; grid[156] <= 0; grid[157] <= 0; grid[158] <= 0; grid[159] <= 0; grid[160] <= 0; grid[161] <= 0; grid[162] <= 0; grid[163] <= 0; grid[164] <= 0; grid[165] <= 0; grid[166] <= 1; grid[167] <= 1; 
            grid[168] <= 1; grid[169] <= 1; grid[170] <= 0; grid[171] <= 0; grid[172] <= 0; grid[173] <= 0; grid[174] <= 0; grid[175] <= 0; grid[176] <= 0; grid[177] <= 0; grid[178] <= 0; grid[179] <= 0; grid[180] <= 1; grid[181] <= 1; 
            grid[182] <= 1; grid[183] <= 1; grid[184] <= 0; grid[185] <= 0; grid[186] <= 0; grid[187] <= 0; grid[188] <= 0; grid[189] <= 0; grid[190] <= 0; grid[191] <= 0; grid[192] <= 0; grid[193] <= 0; grid[194] <= 1; grid[195] <= 1; 
            grid[196] <= 1; grid[197] <= 1; grid[198] <= 0; grid[199] <= 0; grid[200] <= 0; grid[201] <= 0; grid[202] <= 0; grid[203] <= 0; grid[204] <= 0; grid[205] <= 0; grid[206] <= 0; grid[207] <= 0; grid[208] <= 1; grid[209] <= 1; 
            grid[210] <= 1; grid[211] <= 1; grid[212] <= 0; grid[213] <= 0; grid[214] <= 0; grid[215] <= 0; grid[216] <= 0; grid[217] <= 0; grid[218] <= 0; grid[219] <= 0; grid[220] <= 0; grid[221] <= 0; grid[222] <= 1; grid[223] <= 1; 
            grid[224] <= 1; grid[225] <= 1; grid[226] <= 0; grid[227] <= 0; grid[228] <= 0; grid[229] <= 0; grid[230] <= 3; grid[231] <= 3; grid[232] <= 3; grid[233] <= 3; grid[234] <= 0; grid[235] <= 0; grid[236] <= 1; grid[237] <= 1; 
            grid[238] <= 1; grid[239] <= 1; grid[240] <= 6; grid[241] <= 6; grid[242] <= 0; grid[243] <= 3; grid[244] <= 3; grid[245] <= 3; grid[246] <= 3; grid[247] <= 3; grid[248] <= 3; grid[249] <= 0; grid[250] <= 1; grid[251] <= 1; 
            grid[252] <= 1; grid[253] <= 1; grid[254] <= 6; grid[255] <= 6; grid[256] <= 0; grid[257] <= 3; grid[258] <= 3; grid[259] <= 3; grid[260] <= 3; grid[261] <= 3; grid[262] <= 3; grid[263] <= 3; grid[264] <= 1; grid[265] <= 1; 
            grid[266] <= 1; grid[267] <= 1; grid[268] <= 0; grid[269] <= 6; grid[270] <= 3; grid[271] <= 3; grid[272] <= 3; grid[273] <= 3; grid[274] <= 3; grid[275] <= 3; grid[276] <= 3; grid[277] <= 3; grid[278] <= 1; grid[279] <= 1; 
            grid[280] <= 1; grid[281] <= 1; grid[282] <= 0; grid[283] <= 0; grid[284] <= 3; grid[285] <= 6; grid[286] <= 6; grid[287] <= 3; grid[288] <= 3; grid[289] <= 6; grid[290] <= 6; grid[291] <= 3; grid[292] <= 1; grid[293] <= 1; 
            grid[294] <= 1; grid[295] <= 1; grid[296] <= 0; grid[297] <= 0; grid[298] <= 0; grid[299] <= 6; grid[300] <= 6; grid[301] <= 0; grid[302] <= 0; grid[303] <= 6; grid[304] <= 6; grid[305] <= 0; grid[306] <= 1; grid[307] <= 1; 
            grid[308] <= 1; grid[309] <= 1; grid[310] <= 1; grid[311] <= 1; grid[312] <= 1; grid[313] <= 1; grid[314] <= 1; grid[315] <= 1; grid[316] <= 1; grid[317] <= 1; grid[318] <= 1; grid[319] <= 1; grid[320] <= 1; grid[321] <= 1; 
            grid[322] <= 1; grid[323] <= 1; grid[324] <= 1; grid[325] <= 1; grid[326] <= 1; grid[327] <= 1; grid[328] <= 1; grid[329] <= 1; grid[330] <= 1; grid[331] <= 1; grid[332] <= 1; grid[333] <= 1; grid[334] <= 1; grid[335] <= 1; 
        end
        else if (map == 6) begin // monster
            grid[  0] <= 1; grid[  1] <= 1; grid[  2] <= 0; grid[  3] <= 0; grid[  4] <= 0; grid[  5] <= 0; grid[  6] <= 0; grid[  7] <= 0; grid[  8] <= 0; grid[  9] <= 0; grid[ 10] <= 0; grid[ 11] <= 0; grid[ 12] <= 1; grid[ 13] <= 1; 
            grid[ 14] <= 1; grid[ 15] <= 1; grid[ 16] <= 0; grid[ 17] <= 0; grid[ 18] <= 0; grid[ 19] <= 0; grid[ 20] <= 0; grid[ 21] <= 0; grid[ 22] <= 0; grid[ 23] <= 0; grid[ 24] <= 0; grid[ 25] <= 0; grid[ 26] <= 1; grid[ 27] <= 1; 
            grid[ 28] <= 1; grid[ 29] <= 1; grid[ 30] <= 0; grid[ 31] <= 0; grid[ 32] <= 0; grid[ 33] <= 0; grid[ 34] <= 0; grid[ 35] <= 0; grid[ 36] <= 0; grid[ 37] <= 0; grid[ 38] <= 0; grid[ 39] <= 0; grid[ 40] <= 1; grid[ 41] <= 1; 
            grid[ 42] <= 1; grid[ 43] <= 1; grid[ 44] <= 0; grid[ 45] <= 0; grid[ 46] <= 0; grid[ 47] <= 0; grid[ 48] <= 0; grid[ 49] <= 0; grid[ 50] <= 0; grid[ 51] <= 0; grid[ 52] <= 0; grid[ 53] <= 0; grid[ 54] <= 1; grid[ 55] <= 1; 
            grid[ 56] <= 1; grid[ 57] <= 1; grid[ 58] <= 0; grid[ 59] <= 0; grid[ 60] <= 0; grid[ 61] <= 0; grid[ 62] <= 0; grid[ 63] <= 0; grid[ 64] <= 0; grid[ 65] <= 0; grid[ 66] <= 0; grid[ 67] <= 0; grid[ 68] <= 1; grid[ 69] <= 1; 
            grid[ 70] <= 1; grid[ 71] <= 1; grid[ 72] <= 0; grid[ 73] <= 0; grid[ 74] <= 0; grid[ 75] <= 0; grid[ 76] <= 0; grid[ 77] <= 0; grid[ 78] <= 0; grid[ 79] <= 0; grid[ 80] <= 0; grid[ 81] <= 0; grid[ 82] <= 1; grid[ 83] <= 1; 
            grid[ 84] <= 1; grid[ 85] <= 1; grid[ 86] <= 0; grid[ 87] <= 0; grid[ 88] <= 0; grid[ 89] <= 0; grid[ 90] <= 0; grid[ 91] <= 0; grid[ 92] <= 0; grid[ 93] <= 0; grid[ 94] <= 0; grid[ 95] <= 0; grid[ 96] <= 1; grid[ 97] <= 1; 
            grid[ 98] <= 1; grid[ 99] <= 1; grid[100] <= 0; grid[101] <= 0; grid[102] <= 0; grid[103] <= 0; grid[104] <= 0; grid[105] <= 0; grid[106] <= 0; grid[107] <= 0; grid[108] <= 0; grid[109] <= 0; grid[110] <= 1; grid[111] <= 1; 
            grid[112] <= 1; grid[113] <= 1; grid[114] <= 0; grid[115] <= 0; grid[116] <= 0; grid[117] <= 0; grid[118] <= 0; grid[119] <= 0; grid[120] <= 0; grid[121] <= 0; grid[122] <= 0; grid[123] <= 0; grid[124] <= 1; grid[125] <= 1; 
            grid[126] <= 1; grid[127] <= 1; grid[128] <= 0; grid[129] <= 0; grid[130] <= 0; grid[131] <= 0; grid[132] <= 0; grid[133] <= 0; grid[134] <= 0; grid[135] <= 0; grid[136] <= 0; grid[137] <= 0; grid[138] <= 1; grid[139] <= 1; 
            grid[140] <= 1; grid[141] <= 1; grid[142] <= 0; grid[143] <= 0; grid[144] <= 0; grid[145] <= 0; grid[146] <= 0; grid[147] <= 0; grid[148] <= 0; grid[149] <= 0; grid[150] <= 0; grid[151] <= 0; grid[152] <= 1; grid[153] <= 1; 
            grid[154] <= 1; grid[155] <= 1; grid[156] <= 0; grid[157] <= 0; grid[158] <= 0; grid[159] <= 0; grid[160] <= 0; grid[161] <= 0; grid[162] <= 0; grid[163] <= 0; grid[164] <= 0; grid[165] <= 0; grid[166] <= 1; grid[167] <= 1; 
            grid[168] <= 1; grid[169] <= 1; grid[170] <= 0; grid[171] <= 0; grid[172] <= 0; grid[173] <= 0; grid[174] <= 0; grid[175] <= 0; grid[176] <= 0; grid[177] <= 0; grid[178] <= 0; grid[179] <= 1; grid[180] <= 1; grid[181] <= 1; 
            grid[182] <= 1; grid[183] <= 1; grid[184] <= 0; grid[185] <= 0; grid[186] <= 0; grid[187] <= 0; grid[188] <= 0; grid[189] <= 0; grid[190] <= 1; grid[191] <= 1; grid[192] <= 1; grid[193] <= 1; grid[194] <= 1; grid[195] <= 1; 
            grid[196] <= 1; grid[197] <= 1; grid[198] <= 0; grid[199] <= 0; grid[200] <= 0; grid[201] <= 0; grid[202] <= 0; grid[203] <= 1; grid[204] <= 1; grid[205] <= 4; grid[206] <= 4; grid[207] <= 4; grid[208] <= 1; grid[209] <= 1; 
            grid[210] <= 1; grid[211] <= 1; grid[212] <= 0; grid[213] <= 0; grid[214] <= 0; grid[215] <= 0; grid[216] <= 0; grid[217] <= 4; grid[218] <= 4; grid[219] <= 4; grid[220] <= 4; grid[221] <= 4; grid[222] <= 1; grid[223] <= 1; 
            grid[224] <= 1; grid[225] <= 1; grid[226] <= 0; grid[227] <= 0; grid[228] <= 0; grid[229] <= 0; grid[230] <= 0; grid[231] <= 4; grid[232] <= 4; grid[233] <= 2; grid[234] <= 4; grid[235] <= 2; grid[236] <= 1; grid[237] <= 1; 
            grid[238] <= 1; grid[239] <= 1; grid[240] <= 0; grid[241] <= 0; grid[242] <= 1; grid[243] <= 1; grid[244] <= 1; grid[245] <= 4; grid[246] <= 4; grid[247] <= 4; grid[248] <= 4; grid[249] <= 4; grid[250] <= 1; grid[251] <= 1; 
            grid[252] <= 1; grid[253] <= 1; grid[254] <= 0; grid[255] <= 0; grid[256] <= 1; grid[257] <= 4; grid[258] <= 4; grid[259] <= 4; grid[260] <= 4; grid[261] <= 4; grid[262] <= 4; grid[263] <= 4; grid[264] <= 1; grid[265] <= 1; 
            grid[266] <= 1; grid[267] <= 1; grid[268] <= 1; grid[269] <= 1; grid[270] <= 1; grid[271] <= 4; grid[272] <= 4; grid[273] <= 4; grid[274] <= 4; grid[275] <= 0; grid[276] <= 0; grid[277] <= 4; grid[278] <= 1; grid[279] <= 1; 
            grid[280] <= 1; grid[281] <= 1; grid[282] <= 1; grid[283] <= 4; grid[284] <= 4; grid[285] <= 4; grid[286] <= 4; grid[287] <= 4; grid[288] <= 4; grid[289] <= 0; grid[290] <= 0; grid[291] <= 0; grid[292] <= 1; grid[293] <= 1; 
            grid[294] <= 1; grid[295] <= 1; grid[296] <= 4; grid[297] <= 4; grid[298] <= 4; grid[299] <= 4; grid[300] <= 4; grid[301] <= 4; grid[302] <= 4; grid[303] <= 4; grid[304] <= 0; grid[305] <= 4; grid[306] <= 1; grid[307] <= 1; 
            grid[308] <= 1; grid[309] <= 1; grid[310] <= 1; grid[311] <= 1; grid[312] <= 1; grid[313] <= 1; grid[314] <= 1; grid[315] <= 1; grid[316] <= 1; grid[317] <= 1; grid[318] <= 1; grid[319] <= 1; grid[320] <= 1; grid[321] <= 1; 
            grid[322] <= 1; grid[323] <= 1; grid[324] <= 1; grid[325] <= 1; grid[326] <= 1; grid[327] <= 1; grid[328] <= 1; grid[329] <= 1; grid[330] <= 1; grid[331] <= 1; grid[332] <= 1; grid[333] <= 1; grid[334] <= 1; grid[335] <= 1; 
        end
        else if (map == 7) begin // combo breaker
            grid[  0] <= 1; grid[  1] <= 1; grid[  2] <= 0; grid[  3] <= 0; grid[  4] <= 0; grid[  5] <= 0; grid[  6] <= 0; grid[  7] <= 0; grid[  8] <= 0; grid[  9] <= 0; grid[ 10] <= 0; grid[ 11] <= 0; grid[ 12] <= 1; grid[ 13] <= 1; 
            grid[ 14] <= 1; grid[ 15] <= 1; grid[ 16] <= 0; grid[ 17] <= 0; grid[ 18] <= 0; grid[ 19] <= 0; grid[ 20] <= 0; grid[ 21] <= 0; grid[ 22] <= 0; grid[ 23] <= 0; grid[ 24] <= 0; grid[ 25] <= 0; grid[ 26] <= 1; grid[ 27] <= 1; 
            grid[ 28] <= 1; grid[ 29] <= 1; grid[ 30] <= 0; grid[ 31] <= 0; grid[ 32] <= 0; grid[ 33] <= 0; grid[ 34] <= 0; grid[ 35] <= 0; grid[ 36] <= 0; grid[ 37] <= 0; grid[ 38] <= 0; grid[ 39] <= 0; grid[ 40] <= 1; grid[ 41] <= 1; 
            grid[ 42] <= 1; grid[ 43] <= 1; grid[ 44] <= 0; grid[ 45] <= 0; grid[ 46] <= 0; grid[ 47] <= 0; grid[ 48] <= 0; grid[ 49] <= 0; grid[ 50] <= 0; grid[ 51] <= 0; grid[ 52] <= 0; grid[ 53] <= 0; grid[ 54] <= 1; grid[ 55] <= 1; 
            grid[ 56] <= 1; grid[ 57] <= 1; grid[ 58] <= 0; grid[ 59] <= 0; grid[ 60] <= 0; grid[ 61] <= 0; grid[ 62] <= 0; grid[ 63] <= 0; grid[ 64] <= 0; grid[ 65] <= 0; grid[ 66] <= 0; grid[ 67] <= 0; grid[ 68] <= 1; grid[ 69] <= 1; 
            grid[ 70] <= 1; grid[ 71] <= 1; grid[ 72] <= 0; grid[ 73] <= 0; grid[ 74] <= 0; grid[ 75] <= 0; grid[ 76] <= 0; grid[ 77] <= 0; grid[ 78] <= 0; grid[ 79] <= 0; grid[ 80] <= 0; grid[ 81] <= 0; grid[ 82] <= 1; grid[ 83] <= 1; 
            grid[ 84] <= 1; grid[ 85] <= 1; grid[ 86] <= 1; grid[ 87] <= 6; grid[ 88] <= 1; grid[ 89] <= 0; grid[ 90] <= 0; grid[ 91] <= 0; grid[ 92] <= 0; grid[ 93] <= 1; grid[ 94] <= 2; grid[ 95] <= 1; grid[ 96] <= 1; grid[ 97] <= 1; 
            grid[ 98] <= 1; grid[ 99] <= 1; grid[100] <= 7; grid[101] <= 1; grid[102] <= 3; grid[103] <= 0; grid[104] <= 0; grid[105] <= 0; grid[106] <= 0; grid[107] <= 5; grid[108] <= 1; grid[109] <= 4; grid[110] <= 1; grid[111] <= 1; 
            grid[112] <= 1; grid[113] <= 1; grid[114] <= 1; grid[115] <= 6; grid[116] <= 1; grid[117] <= 0; grid[118] <= 0; grid[119] <= 0; grid[120] <= 0; grid[121] <= 1; grid[122] <= 2; grid[123] <= 1; grid[124] <= 1; grid[125] <= 1; 
            grid[126] <= 1; grid[127] <= 1; grid[128] <= 7; grid[129] <= 1; grid[130] <= 3; grid[131] <= 0; grid[132] <= 0; grid[133] <= 0; grid[134] <= 0; grid[135] <= 5; grid[136] <= 1; grid[137] <= 4; grid[138] <= 1; grid[139] <= 1; 
            grid[140] <= 1; grid[141] <= 1; grid[142] <= 1; grid[143] <= 6; grid[144] <= 1; grid[145] <= 0; grid[146] <= 0; grid[147] <= 0; grid[148] <= 0; grid[149] <= 1; grid[150] <= 2; grid[151] <= 1; grid[152] <= 1; grid[153] <= 1; 
            grid[154] <= 1; grid[155] <= 1; grid[156] <= 7; grid[157] <= 1; grid[158] <= 3; grid[159] <= 0; grid[160] <= 0; grid[161] <= 0; grid[162] <= 0; grid[163] <= 5; grid[164] <= 1; grid[165] <= 4; grid[166] <= 1; grid[167] <= 1; 
            grid[168] <= 1; grid[169] <= 1; grid[170] <= 1; grid[171] <= 6; grid[172] <= 1; grid[173] <= 0; grid[174] <= 0; grid[175] <= 0; grid[176] <= 0; grid[177] <= 1; grid[178] <= 2; grid[179] <= 1; grid[180] <= 1; grid[181] <= 1; 
            grid[182] <= 1; grid[183] <= 1; grid[184] <= 7; grid[185] <= 1; grid[186] <= 3; grid[187] <= 0; grid[188] <= 0; grid[189] <= 0; grid[190] <= 0; grid[191] <= 5; grid[192] <= 1; grid[193] <= 4; grid[194] <= 1; grid[195] <= 1; 
            grid[196] <= 1; grid[197] <= 1; grid[198] <= 1; grid[199] <= 6; grid[200] <= 1; grid[201] <= 0; grid[202] <= 0; grid[203] <= 0; grid[204] <= 0; grid[205] <= 1; grid[206] <= 2; grid[207] <= 1; grid[208] <= 1; grid[209] <= 1; 
            grid[210] <= 1; grid[211] <= 1; grid[212] <= 7; grid[213] <= 1; grid[214] <= 3; grid[215] <= 0; grid[216] <= 0; grid[217] <= 0; grid[218] <= 0; grid[219] <= 5; grid[220] <= 1; grid[221] <= 4; grid[222] <= 1; grid[223] <= 1; 
            grid[224] <= 1; grid[225] <= 1; grid[226] <= 1; grid[227] <= 6; grid[228] <= 1; grid[229] <= 0; grid[230] <= 0; grid[231] <= 0; grid[232] <= 0; grid[233] <= 1; grid[234] <= 2; grid[235] <= 1; grid[236] <= 1; grid[237] <= 1; 
            grid[238] <= 1; grid[239] <= 1; grid[240] <= 7; grid[241] <= 1; grid[242] <= 3; grid[243] <= 0; grid[244] <= 0; grid[245] <= 0; grid[246] <= 0; grid[247] <= 5; grid[248] <= 1; grid[249] <= 4; grid[250] <= 1; grid[251] <= 1; 
            grid[252] <= 1; grid[253] <= 1; grid[254] <= 1; grid[255] <= 6; grid[256] <= 1; grid[257] <= 0; grid[258] <= 0; grid[259] <= 0; grid[260] <= 0; grid[261] <= 1; grid[262] <= 2; grid[263] <= 1; grid[264] <= 1; grid[265] <= 1; 
            grid[266] <= 1; grid[267] <= 1; grid[268] <= 7; grid[269] <= 1; grid[270] <= 3; grid[271] <= 0; grid[272] <= 0; grid[273] <= 0; grid[274] <= 0; grid[275] <= 5; grid[276] <= 1; grid[277] <= 4; grid[278] <= 1; grid[279] <= 1; 
            grid[280] <= 1; grid[281] <= 1; grid[282] <= 1; grid[283] <= 6; grid[284] <= 1; grid[285] <= 0; grid[286] <= 0; grid[287] <= 0; grid[288] <= 0; grid[289] <= 1; grid[290] <= 2; grid[291] <= 1; grid[292] <= 1; grid[293] <= 1; 
            grid[294] <= 1; grid[295] <= 1; grid[296] <= 7; grid[297] <= 1; grid[298] <= 3; grid[299] <= 1; grid[300] <= 7; grid[301] <= 1; grid[302] <= 0; grid[303] <= 5; grid[304] <= 1; grid[305] <= 4; grid[306] <= 1; grid[307] <= 1; 
            grid[308] <= 1; grid[309] <= 1; grid[310] <= 1; grid[311] <= 1; grid[312] <= 1; grid[313] <= 1; grid[314] <= 1; grid[315] <= 1; grid[316] <= 1; grid[317] <= 1; grid[318] <= 1; grid[319] <= 1; grid[320] <= 1; grid[321] <= 1; 
            grid[322] <= 1; grid[323] <= 1; grid[324] <= 1; grid[325] <= 1; grid[326] <= 1; grid[327] <= 1; grid[328] <= 1; grid[329] <= 1; grid[330] <= 1; grid[331] <= 1; grid[332] <= 1; grid[333] <= 1; grid[334] <= 1; grid[335] <= 1; 
        end
        // end of initial map
    end
    else if (P == SPIG) begin
        fallen <= 0;

        holded <= 0;
        first_hold <= 0;
        pre_holded_idx <= 128;
        holded_idx <= 128;

        score <= 0;
        boundary <= 0;

        //initialize height
        for (idx = 0; idx < 10; idx = idx + 1) begin
            height[idx] <= 0;
        end 

        //initialize tetro list
        if (map == 1 || map == 2) begin
            tetro_list[0] <= 5; tetro_list[1] <= 5; tetro_list[2] <= 5; tetro_list[3] <= 5; tetro_list[4] <= 5; tetro_list[5] <= 5; tetro_list[6] <= 5; tetro_list[7] <= 5; tetro_list[8] <= 5; tetro_list[9] <= 5; tetro_list[10] <= 5; tetro_list[11] <= 5; tetro_list[12] <= 5; tetro_list[13] <= 5; tetro_list[14] <= 5; tetro_list[15] <= 5; tetro_list[16] <= 5; tetro_list[17] <= 5; tetro_list[18] <= 5; tetro_list[19] <= 5; tetro_list[20] <= 5; tetro_list[21] <= 5; tetro_list[22] <= 5; tetro_list[23] <= 5; tetro_list[24] <= 5; tetro_list[25] <= 5; tetro_list[26] <= 5; tetro_list[27] <= 5; tetro_list[28] <= 5; tetro_list[29] <= 5; tetro_list[30] <= 5; tetro_list[31] <= 5; tetro_list[32] <= 5; tetro_list[33] <= 5; tetro_list[34] <= 5; tetro_list[35] <= 5; tetro_list[36] <= 5; tetro_list[37] <= 5; tetro_list[38] <= 5; tetro_list[39] <= 5; tetro_list[40] <= 5; tetro_list[41] <= 5; tetro_list[42] <= 5; tetro_list[43] <= 5; tetro_list[44] <= 5; tetro_list[45] <= 5; tetro_list[46] <= 5; tetro_list[47] <= 5; tetro_list[48] <= 5; tetro_list[49] <= 5; tetro_list[50] <= 5; tetro_list[51] <= 5; tetro_list[52] <= 5; tetro_list[53] <= 5; tetro_list[54] <= 5; tetro_list[55] <= 5; tetro_list[56] <= 5; tetro_list[57] <= 5; tetro_list[58] <= 5; tetro_list[59] <= 5; tetro_list[60] <= 5; tetro_list[61] <= 5; tetro_list[62] <= 5; tetro_list[63] <= 5; tetro_list[64] <= 5; tetro_list[65] <= 5; tetro_list[66] <= 5; tetro_list[67] <= 5; tetro_list[68] <= 5; tetro_list[69] <= 5; tetro_list[70] <= 5; tetro_list[71] <= 5; tetro_list[72] <= 5; tetro_list[73] <= 5; tetro_list[74] <= 5; tetro_list[75] <= 5; tetro_list[76] <= 5; tetro_list[77] <= 5; tetro_list[78] <= 5; tetro_list[79] <= 5; tetro_list[80] <= 5; tetro_list[81] <= 5; tetro_list[82] <= 5; tetro_list[83] <= 5; tetro_list[84] <= 5; tetro_list[85] <= 5; tetro_list[86] <= 5; tetro_list[87] <= 5; tetro_list[88] <= 5; tetro_list[89] <= 5; tetro_list[90] <= 5; tetro_list[91] <= 5; tetro_list[92] <= 5; tetro_list[93] <= 5; tetro_list[94] <= 5; tetro_list[95] <= 5; tetro_list[96] <= 5; tetro_list[97] <= 5; tetro_list[98] <= 5; tetro_list[99] <= 5; tetro_list[100] <= 5; tetro_list[101] <= 5; tetro_list[102] <= 5; tetro_list[103] <= 5; tetro_list[104] <= 5; 
        end
        else begin
            tetro_list[0] <= 2; tetro_list[1] <= 6; tetro_list[2] <= 5; tetro_list[3] <= 1; tetro_list[4] <= 7; tetro_list[5] <= 3; tetro_list[6] <= 4; tetro_list[7] <= 2; tetro_list[8] <= 7; tetro_list[9] <= 3; tetro_list[10] <= 1; tetro_list[11] <= 4; tetro_list[12] <= 6; tetro_list[13] <= 5; tetro_list[14] <= 5; tetro_list[15] <= 2; tetro_list[16] <= 1; tetro_list[17] <= 7; tetro_list[18] <= 6; tetro_list[19] <= 4; tetro_list[20] <= 3; tetro_list[21] <= 6; tetro_list[22] <= 2; tetro_list[23] <= 3; tetro_list[24] <= 7; tetro_list[25] <= 1; tetro_list[26] <= 5; tetro_list[27] <= 4; tetro_list[28] <= 7; tetro_list[29] <= 2; tetro_list[30] <= 6; tetro_list[31] <= 4; tetro_list[32] <= 5; tetro_list[33] <= 3; tetro_list[34] <= 1; tetro_list[35] <= 6; tetro_list[36] <= 5; tetro_list[37] <= 2; tetro_list[38] <= 4; tetro_list[39] <= 3; tetro_list[40] <= 1; tetro_list[41] <= 7; tetro_list[42] <= 6; tetro_list[43] <= 1; tetro_list[44] <= 3; tetro_list[45] <= 2; tetro_list[46] <= 4; tetro_list[47] <= 5; tetro_list[48] <= 7; tetro_list[49] <= 5; tetro_list[50] <= 3; tetro_list[51] <= 4; tetro_list[52] <= 7; tetro_list[53] <= 1; tetro_list[54] <= 6; tetro_list[55] <= 2; tetro_list[56] <= 5; tetro_list[57] <= 1; tetro_list[58] <= 7; tetro_list[59] <= 2; tetro_list[60] <= 3; tetro_list[61] <= 4; tetro_list[62] <= 6; tetro_list[63] <= 4; tetro_list[64] <= 2; tetro_list[65] <= 5; tetro_list[66] <= 7; tetro_list[67] <= 3; tetro_list[68] <= 6; tetro_list[69] <= 1; tetro_list[70] <= 4; tetro_list[71] <= 2; tetro_list[72] <= 5; tetro_list[73] <= 7; tetro_list[74] <= 3; tetro_list[75] <= 6; tetro_list[76] <= 1; tetro_list[77] <= 3; tetro_list[78] <= 1; tetro_list[79] <= 2; tetro_list[80] <= 6; tetro_list[81] <= 4; tetro_list[82] <= 7; tetro_list[83] <= 5; tetro_list[84] <= 2; tetro_list[85] <= 6; tetro_list[86] <= 1; tetro_list[87] <= 7; tetro_list[88] <= 5; tetro_list[89] <= 3; tetro_list[90] <= 4; tetro_list[91] <= 1; tetro_list[92] <= 6; tetro_list[93] <= 4; tetro_list[94] <= 7; tetro_list[95] <= 5; tetro_list[96] <= 3; tetro_list[97] <= 2; tetro_list[98] <= 1; tetro_list[99] <= 4; tetro_list[100] <= 2; tetro_list[101] <= 7; tetro_list[102] <= 3; tetro_list[103] <= 6; tetro_list[104] <= 5; 
        end 
        
        //end of initialization of tetro list
    end
    else if (P == SPUG) begin
        // calculate the boundary
        case (current_tetromino)
            tetro_I: begin
                case (current_state)
                    T_S: begin
                        boundary <= current_tetromino_grid[0] / 14 * 14 + 13;
                    end
                    T_L: begin
                        boundary <= current_tetromino_grid[1] / 14 * 14 + 13;
                    end
                    T_2: begin
                        boundary <= current_tetromino_grid[1] / 14 * 14 + 13;
                    end
                    T_R: begin
                        boundary <= current_tetromino_grid[3] / 14 * 14 + 13;
                    end
                endcase
            end
            tetro_O: begin
                boundary <= current_tetromino_grid[0] / 14 * 14 + 13;
            end
            tetro_L: begin
                case (current_state)
                    T_S: begin
                        boundary <= current_tetromino_grid[0] / 14 * 14 + 13;
                    end
                    T_L: begin
                        boundary <= current_tetromino_grid[2] / 14 * 14 + 13;
                    end
                    T_2: begin
                        boundary <= current_tetromino_grid[1] / 14 * 14 + 13;
                    end
                    T_R: begin
                        boundary <= current_tetromino_grid[1] / 14 * 14 + 13;
                    end
                endcase
            end
            tetro_J: begin
                case (current_state)
                    T_S: begin
                        boundary <= current_tetromino_grid[0] / 14 * 14 + 13;
                    end
                    T_L: begin
                        boundary <= current_tetromino_grid[1] / 14 * 14 + 13;
                    end
                    T_2: begin
                        boundary <= current_tetromino_grid[1] / 14 * 14 + 13;
                    end
                    T_R: begin
                        boundary <= current_tetromino_grid[3] / 14 * 14 + 13;
                    end
                endcase
            end
            tetro_T: begin
                case (current_state)
                    T_S: begin
                        boundary <= current_tetromino_grid[0] / 14 * 14 + 13;
                    end
                    T_L: begin
                        boundary <= current_tetromino_grid[2] / 14 * 14 + 13;
                    end
                    T_2: begin
                        boundary <= current_tetromino_grid[1] / 14 * 14 + 13;
                    end
                    T_R: begin
                        boundary <= current_tetromino_grid[3] / 14 * 14 + 13;
                    end
                endcase
            end
            tetro_S: begin
                case (current_state)
                    T_S: begin
                        boundary <= current_tetromino_grid[0] / 14 * 14 + 13;
                    end
                    T_L: begin
                        boundary <= current_tetromino_grid[3] / 14 * 14 + 13;
                    end
                    T_2: begin
                        boundary <= current_tetromino_grid[1] / 14 * 14 + 13;
                    end
                    T_R: begin
                        boundary <= current_tetromino_grid[2] / 14 * 14 + 13;
                    end
                endcase
            end
            tetro_Z: begin
                case (current_state)
                    T_S: begin
                        boundary <= current_tetromino_grid[0] / 14 * 14 + 13;
                    end
                    T_L: begin
                        boundary <= current_tetromino_grid[1] / 14 * 14 + 13;
                    end
                    T_2: begin
                        boundary <= current_tetromino_grid[1] / 14 * 14 + 13;
                    end
                    T_R: begin
                        boundary <= current_tetromino_grid[3] / 14 * 14 + 13;
                    end
                endcase
            end
        endcase

        // put current_tetromino_grid_pos to grid 
        grid[current_tetromino_grid[0]] <= current_tetromino;
        grid[current_tetromino_grid[1]] <= current_tetromino;
        grid[current_tetromino_grid[2]] <= current_tetromino;
        grid[current_tetromino_grid[3]] <= current_tetromino;
        //calculate next piece
        
        fallen <= 0;
    end
    else if (P == SPCL) begin
        // clear line
        if (row_full) begin
            for (idx_cl = 16; idx_cl < 306; idx_cl = idx_cl + 1) begin
                grid[idx_cl] <= (idx_cl < boundary) ? grid[idx_cl - 14] : grid[idx_cl];
            end
            line_cleared <= line_cleared + 1;
        end
        else begin
            boundary <= boundary - 14;
        end

        holded <= 0;
        first_hold <= 0;
    end
    else if (P == SPGP) begin
        // generate new piece
        tetromino_next[0] <= tetro_list[tetromino_ctr - 4];
        tetromino_next[1] <= tetro_list[tetromino_ctr - 3];
        tetromino_next[2] <= tetro_list[tetromino_ctr - 2];
        tetromino_next[3] <= tetro_list[tetromino_ctr - 1];
        tetromino_next[4] <= tetro_list[tetromino_ctr - 0];
        tetromino_next[5] <= tetro_list[tetromino_ctr + 1];

        line_cleared <= 0;

                // add score
        if (t_spin_single) begin // T spin single / double
            score <= score + 800;
        end
        else if (t_spin_double) begin // T spin single / double
            score <= score + 1200;
        end
        else if (t_spin_triple) begin // T spin triple (S -> R)
            score <= score + 1200;
        end
        else if (line_cleared == 1) begin
            score <= score + 100;
        end
        else if (line_cleared == 2) begin
            score <= score + 300;
        end
        else if (line_cleared == 3) begin
            score <= score + 500;
        end
        else if (line_cleared == 4) begin
            score <= score + 800;
        end
    end
    else if (P == SPPP) begin
        // current_tetromino <= tetro_list[current_tetro_idx];
        deviation <= 0;
        //initialize the new tetro's info
        current_pos <= 20; // 20 = (4, 1)
        current_state <= T_S;
        pre_holded_idx <= holded_idx;
    end
    else if (P == SPFL) begin
        // given current pos, current state, update current_tetro_grid(_pos)
        case (current_tetromino) 
            tetro_I: begin
                case (current_state) 
                    T_S: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[2] <= current_pos + 1;
                        current_tetromino_grid[3] <= current_pos + 2;
                        current_tetromino_grid[1] <= current_pos - 1;
                    end
                    T_L: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos + 14;
                        current_tetromino_grid[3] <= current_pos - 28;
                        current_tetromino_grid[2] <= current_pos - 14;
                    end
                    T_2: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos + 1;
                        current_tetromino_grid[3] <= current_pos - 2;
                        current_tetromino_grid[2] <= current_pos - 1;
                    end
                    T_R: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[2] <= current_pos + 14;
                        current_tetromino_grid[3] <= current_pos + 28;
                        current_tetromino_grid[1] <= current_pos - 14;
                    end
                endcase
            end
            tetro_O: begin
                current_tetromino_grid[0] <= current_pos;
                current_tetromino_grid[2] <= current_pos - 13;
                current_tetromino_grid[3] <= current_pos + 1;
                current_tetromino_grid[1] <= current_pos - 14;
            end
            tetro_L: begin
                case (current_state) 
                    T_S: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos - 13;
                        current_tetromino_grid[2] <= current_pos - 1;
                        current_tetromino_grid[3] <= current_pos + 1;
                    end
                    T_L: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos - 15;
                        current_tetromino_grid[2] <= current_pos + 14;
                        current_tetromino_grid[3] <= current_pos - 14;
                    end
                    T_2: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos + 13;
                        current_tetromino_grid[2] <= current_pos + 1;
                        current_tetromino_grid[3] <= current_pos - 1;
                    end
                    T_R: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos + 15;
                        current_tetromino_grid[2] <= current_pos - 14;
                        current_tetromino_grid[3] <= current_pos + 14;
                    end
                endcase
            end
            tetro_J: begin
                case (current_state) 
                    T_S: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos - 15;
                        current_tetromino_grid[2] <= current_pos - 1;
                        current_tetromino_grid[3] <= current_pos + 1;
                    end
                    T_L: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos + 13;
                        current_tetromino_grid[2] <= current_pos + 14;
                        current_tetromino_grid[3] <= current_pos - 14;
                    end
                    T_2: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos + 15;
                        current_tetromino_grid[2] <= current_pos + 1;
                        current_tetromino_grid[3] <= current_pos - 1;
                    end
                    T_R: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos - 13;
                        current_tetromino_grid[2] <= current_pos - 14;
                        current_tetromino_grid[3] <= current_pos + 14;
                    end
                endcase
            end
            tetro_T: begin
                case (current_state) 
                    T_S: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos - 14;
                        current_tetromino_grid[2] <= current_pos - 1;
                        current_tetromino_grid[3] <= current_pos + 1;
                    end
                    T_L: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos - 1;
                        current_tetromino_grid[2] <= current_pos + 14;
                        current_tetromino_grid[3] <= current_pos - 14;
                    end
                    T_2: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos + 14;
                        current_tetromino_grid[2] <= current_pos + 1;
                        current_tetromino_grid[3] <= current_pos - 1;
                    end
                    T_R: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos + 1;
                        current_tetromino_grid[2] <= current_pos - 14;
                        current_tetromino_grid[3] <= current_pos + 14;
                    end
                endcase
            end
            tetro_S: begin
                case (current_state) 
                    T_S: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos - 14;
                        current_tetromino_grid[2] <= current_pos - 13;
                        current_tetromino_grid[3] <= current_pos - 1;
                    end
                    T_L: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos - 1;
                        current_tetromino_grid[2] <= current_pos - 15;
                        current_tetromino_grid[3] <= current_pos + 14;
                    end
                    T_2: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos + 14;
                        current_tetromino_grid[2] <= current_pos + 13;
                        current_tetromino_grid[3] <= current_pos + 1;
                    end
                    T_R: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos + 1;
                        current_tetromino_grid[2] <= current_pos + 15;
                        current_tetromino_grid[3] <= current_pos - 14;
                    end
                endcase
            end
            tetro_Z: begin
                case (current_state) 
                    T_S: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos - 15;
                        current_tetromino_grid[2] <= current_pos - 14;
                        current_tetromino_grid[3] <= current_pos + 1;
                    end
                    T_L: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos + 13;
                        current_tetromino_grid[2] <= current_pos - 1;
                        current_tetromino_grid[3] <= current_pos - 14;
                    end
                    T_2: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos + 15;
                        current_tetromino_grid[2] <= current_pos + 14;
                        current_tetromino_grid[3] <= current_pos - 1;
                    end
                    T_R: begin
                        current_tetromino_grid[0] <= current_pos;
                        current_tetromino_grid[1] <= current_pos - 13;
                        current_tetromino_grid[2] <= current_pos + 1;
                        current_tetromino_grid[3] <= current_pos + 14;
                    end
                endcase
            end
        endcase
        // end of update grid

        // current_tetromino <= tetro_list[current_tetro_idx];

        // update deviation
        if (fall_counter == speed_num
            || SP_hold
            || SP_left
            || SP_right
            || SP_clkrt
            || SP_ctclkrt
            || SP_fastsown
            || SP_gnrtobst) begin
            deviation <= 0; 
            deviation_delay <= 0;    
        end
        else if (grid[current_tetromino_grid[0] + 14 * (deviation + 1)] == 0 
            && grid[current_tetromino_grid[1] + 14 * (deviation + 1)] == 0
            && grid[current_tetromino_grid[2] + 14 * (deviation + 1)] == 0
            && grid[current_tetromino_grid[3] + 14 * (deviation + 1)] == 0) begin
            deviation_delay <= deviation + 1;
            deviation <= deviation_delay;
        end
        else begin
            deviation <= deviation;
        end
        // end of updating deviation

        // given height of column, current_tetro_grid, update shadow_pos
            // column of grid = current_tetromino_grid[] % 14 - 2
            // height of grid = 22 - (current_tetromino_grid[] / 14)
        shadow_pos[0] <= current_tetromino_grid[0] + deviation * 14;
        shadow_pos[1] <= current_tetromino_grid[1] + deviation * 14;
        shadow_pos[2] <= current_tetromino_grid[2] + deviation * 14;
        shadow_pos[3] <= current_tetromino_grid[3] + deviation * 14;
        // end of update shadow_pos

        if (fall_counter == speed_num) begin // fall
            case (current_tetromino) 
                tetro_I: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos + 13] == 0 && grid[current_pos + 14] == 0 && grid[current_pos + 15] == 0 && grid[current_pos + 16] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos + 28] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos + 13] == 0 && grid[current_pos + 14] == 0 && grid[current_pos + 15] == 0 && grid[current_pos + 12] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos + 42] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                    endcase
                end
                tetro_O: begin
                    if (grid[current_pos + 14] == 0 && grid[current_pos + 15] == 0) begin
                        current_pos <= current_pos + 14;
                    end
                    else begin
                        fallen <= 1;
                    end
                end
                tetro_L: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos + 13] == 0 && grid[current_pos + 14] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos + 28] == 0 && grid[current_pos - 1] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos + 14] == 0 && grid[current_pos + 15] == 0 && grid[current_pos + 27] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos + 28] == 0 && grid[current_pos + 29] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                    endcase
                end
                tetro_J: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos + 13] == 0 && grid[current_pos + 14] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos + 28] == 0 && grid[current_pos + 27] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos + 13] == 0 && grid[current_pos + 14] == 0 && grid[current_pos + 29] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos + 28] == 0 && grid[current_pos + 1] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                    endcase
                end
                tetro_T: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos + 13] == 0 && grid[current_pos + 14] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos + 28] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos + 13] == 0 && grid[current_pos + 15] == 0 && grid[current_pos + 28] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos + 28] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                    endcase
                end
                tetro_S: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos + 13] == 0 && grid[current_pos + 14] == 0 && grid[current_pos + 1] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos + 28] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos + 27] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos + 29] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                    endcase
                end
                tetro_Z: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos + 15] == 0 && grid[current_pos + 14] == 0 && grid[current_pos - 1] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos + 27] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos + 29] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos + 28] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 14;
                            end
                            else begin
                                fallen <= 1;
                            end
                        end
                    endcase
                end
            endcase
        end

        else if (SP_hold && (holded == 0)) begin
            if (pre_holded_idx == 128) begin
                first_hold <= 1;
                holded_idx <= tetromino_ctr - 5;
                holded <= 1;
            end
            else begin
                // current_tetromino <= hold;
                holded_idx <= tetromino_ctr - 5;
                holded <= 1;
            end

            current_pos <= 20;
            current_state <= T_S;
        end

        else if (SP_left) begin
            case (current_tetromino) 
                tetro_I: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 2] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 29] == 0 && grid[current_pos - 15] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 3] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos + 27] == 0 && grid[current_pos - 15] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                    endcase
                end
                tetro_O: begin
                    if (grid[current_pos - 1] == 0 && grid[current_pos - 15] == 0) begin
                        current_pos <= current_pos - 1;
                    end
                end
                tetro_L: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 2] == 0 && grid[current_pos - 14] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 16] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 2] == 0 && grid[current_pos + 12] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 15] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                    endcase
                end
                tetro_J: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 2] == 0 && grid[current_pos - 16] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 15] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 12] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 2] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 15] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                    endcase
                end
                tetro_T: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 2] == 0 && grid[current_pos - 15] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 15] == 0 && grid[current_pos - 2] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 2] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 15] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                    endcase
                end
                tetro_S: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 2] == 0 && grid[current_pos - 15] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 16] == 0 && grid[current_pos - 2] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 1] == 0 && grid[current_pos + 12] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                    endcase
                end
                tetro_Z: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 1] == 0 && grid[current_pos - 16] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 15] == 0 && grid[current_pos - 2] == 0 && grid[current_pos + 12] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 2] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos - 1;
                            end
                        end
                    endcase
                end
            endcase
        end

        else if (SP_right) begin
            case (current_tetromino) 
                tetro_I: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos + 3] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 27] == 0 && grid[current_pos - 13] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos + 2] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos + 29] == 0 && grid[current_pos - 13] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                    endcase
                end
                tetro_O: begin
                    if (grid[current_pos + 2] == 0 && grid[current_pos - 12] == 0) begin
                        current_pos <= current_pos + 1;
                    end
                end
                tetro_L: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos + 2] == 0 && grid[current_pos - 12] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 13] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos + 2] == 0 && grid[current_pos + 16] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 12] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                    endcase
                end
                tetro_J: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos + 2] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 13] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos + 2] == 0 && grid[current_pos + 16] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 12] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                    endcase
                end
                tetro_T: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 13] == 0 && grid[current_pos + 2] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 13] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos + 2] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 13] == 0 && grid[current_pos + 2] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                    endcase
                end
                tetro_S: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 12] == 0 && grid[current_pos + 1] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos + 2] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 13] == 0 && grid[current_pos + 2] == 0 && grid[current_pos + 16] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                    endcase
                end
                tetro_Z: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos + 2] == 0 && grid[current_pos - 13] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 13] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos + 1] == 0 && grid[current_pos + 16] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 12] == 0 && grid[current_pos + 2] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 1;
                            end
                        end
                    endcase
                end
            endcase
        end

        // else if (SP_down) begin
            
        // end

        else if (SP_clkrt) begin

            case (current_tetromino) 
                tetro_I: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 13] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 15] == 0 && grid[current_pos + 29] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 13 - 2] == 0 && grid[current_pos + 1 - 2] == 0 && grid[current_pos + 15 - 2] == 0 && grid[current_pos + 29 - 2] == 0) begin
                                current_pos <= current_pos + 1 - 2;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 13 + 1] == 0 && grid[current_pos + 1 + 1] == 0 && grid[current_pos + 15 + 1] == 0 && grid[current_pos + 29 + 1] == 0) begin
                                current_pos <= current_pos + 1 + 1;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 13 + 12] == 0 && grid[current_pos + 1 + 12] == 0 && grid[current_pos + 15 + 12] == 0 && grid[current_pos + 29 + 12] == 0) begin
                                current_pos <= current_pos + 1 + 12;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 13 - 27] == 0 && grid[current_pos + 1 - 27] == 0 && grid[current_pos + 15 - 27] == 0 && grid[current_pos + 29 - 27] == 0) begin
                                current_pos <= current_pos + 1 - 27;
                                current_state <= T_R;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 12] == 0 && grid[current_pos - 15] == 0 && grid[current_pos - 14] == 0 && grid[current_pos - 13] == 0) begin
                                current_pos <= current_pos - 14;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 12 + 1] == 0 && grid[current_pos - 15 + 1] == 0 && grid[current_pos - 14 + 1] == 0 && grid[current_pos - 13 + 1] == 0) begin
                                current_pos <= current_pos - 14 + 1;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 12 - 2] == 0 && grid[current_pos - 15 - 2] == 0 && grid[current_pos - 14 - 2] == 0 && grid[current_pos - 13 - 2] == 0) begin
                                current_pos <= current_pos - 14 - 2;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 12 + 29] == 0 && grid[current_pos - 15 + 29] == 0 && grid[current_pos - 14 + 29] == 0 && grid[current_pos - 13 + 29] == 0) begin
                                current_pos <= current_pos - 14 + 29;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 12 - 16] == 0 && grid[current_pos - 15 - 16] == 0 && grid[current_pos - 14 - 16] == 0 && grid[current_pos - 13 - 16] == 0) begin
                                current_pos <= current_pos - 14 - 16;
                                current_state <= T_S;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 29] == 0 && grid[current_pos - 15] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 29 + 2] == 0 && grid[current_pos - 15 + 2] == 0 && grid[current_pos - 1 + 2] == 0 && grid[current_pos + 13 + 2] == 0) begin
                                current_pos <= current_pos - 1 + 2;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 29 - 1] == 0 && grid[current_pos - 15 - 1] == 0 && grid[current_pos - 1 - 1] == 0 && grid[current_pos + 13 - 1] == 0) begin
                                current_pos <= current_pos - 1 - 1;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 29 - 12] == 0 && grid[current_pos - 15 - 12] == 0 && grid[current_pos - 1 - 12] == 0 && grid[current_pos + 13 - 12] == 0) begin
                                current_pos <= current_pos - 1 - 12;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 29 + 27] == 0 && grid[current_pos - 15 + 27] == 0 && grid[current_pos - 1 + 27] == 0 && grid[current_pos + 13 + 27] == 0) begin
                                current_pos <= current_pos - 1 + 27;
                                current_state <= T_L;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos + 12] == 0 && grid[current_pos + 13] == 0 && grid[current_pos + 14] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos + 14;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 12 - 1] == 0 && grid[current_pos + 13 - 1] == 0 && grid[current_pos + 14 - 1] == 0 && grid[current_pos + 15 - 1] == 0) begin
                                current_pos <= current_pos + 14 - 1;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 12 + 2] == 0 && grid[current_pos + 13 + 2] == 0 && grid[current_pos + 14 + 2] == 0 && grid[current_pos + 15 + 2] == 0) begin
                                current_pos <= current_pos + 14 + 2;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 12 - 29] == 0 && grid[current_pos + 13 - 29] == 0 && grid[current_pos + 14 - 29] == 0 && grid[current_pos + 15 - 29] == 0) begin
                                current_pos <= current_pos + 14 - 29;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 12 + 16] == 0 && grid[current_pos + 13 + 16] == 0 && grid[current_pos + 14 + 16] == 0 && grid[current_pos + 15 + 16] == 0) begin
                                current_pos <= current_pos + 14 + 16;
                                current_state <= T_2;
                            end
                        end
                    endcase
                end
                tetro_O: begin
                end
                tetro_L: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos] == 0 && grid[current_pos + 15] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 15 - 1] == 0 && grid[current_pos + 14 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 15] == 0 && grid[current_pos - 15] == 0 && grid[current_pos + 15 - 15] == 0 && grid[current_pos + 14 - 15] == 0) begin
                                current_pos <= current_pos - 15;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 15 + 28] == 0 && grid[current_pos + 14 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 27] == 0 && grid[current_pos + 27] == 0 && grid[current_pos + 15 + 27] == 0 && grid[current_pos + 14 + 27] == 0) begin
                                current_pos <= current_pos + 27;
                                current_state <= T_R;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos - 13] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 1 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 1 - 1] == 0 && grid[current_pos - 13 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 1 + 13] == 0 && grid[current_pos + 13] == 0 && grid[current_pos + 1 + 13] == 0 && grid[current_pos - 13 + 13] == 0) begin
                                current_pos <= current_pos + 13;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 1 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos + 1 - 28] == 0 && grid[current_pos - 13 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 1 - 29] == 0 && grid[current_pos - 29] == 0 && grid[current_pos + 1 - 29] == 0 && grid[current_pos - 13 - 29] == 0) begin
                                current_pos <= current_pos - 29;
                                current_state <= T_S;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 15] == 0 && grid[current_pos - 14] == 0 && grid[current_pos] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 1] == 0 && grid[current_pos - 14 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 14 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 - 13] == 0 && grid[current_pos - 14 - 13] == 0 && grid[current_pos - 13] == 0 && grid[current_pos + 14 - 13] == 0) begin
                                current_pos <= current_pos - 13;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 28] == 0 && grid[current_pos - 14 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 14 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 29] == 0 && grid[current_pos - 14 + 29] == 0 && grid[current_pos + 29] == 0 && grid[current_pos + 14 + 29] == 0) begin
                                current_pos <= current_pos + 29;
                                current_state <= T_L;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 1 + 1] == 0 && grid[current_pos + 13 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 + 15] == 0 && grid[current_pos + 15] == 0 && grid[current_pos + 1 + 15] == 0 && grid[current_pos + 13 + 15] == 0) begin
                                current_pos <= current_pos + 15;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos + 1 - 28] == 0 && grid[current_pos + 13 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 - 27] == 0 && grid[current_pos - 27] == 0 && grid[current_pos + 1 - 27] == 0 && grid[current_pos + 13 - 27] == 0) begin
                                current_pos <= current_pos - 27;
                                current_state <= T_2;
                            end
                        end
                    endcase
                end
                tetro_J: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos - 13] == 0 && grid[current_pos] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 1] == 0 && grid[current_pos - 13 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 14 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 15] == 0 && grid[current_pos - 13 - 15] == 0 && grid[current_pos - 15] == 0 && grid[current_pos + 14 - 15] == 0) begin
                                current_pos <= current_pos - 15;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 28] == 0 && grid[current_pos - 13 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 14 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 27] == 0 && grid[current_pos - 13 + 27] == 0 && grid[current_pos + 27] == 0 && grid[current_pos + 14 + 27] == 0) begin
                                current_pos <= current_pos + 27;
                                current_state <= T_R;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 15] == 0 && grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 15 - 1] == 0 && grid[current_pos - 1 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 1 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 15 + 13] == 0 && grid[current_pos - 1 + 13] == 0 && grid[current_pos + 13] == 0 && grid[current_pos + 1 + 13] == 0) begin
                                current_pos <= current_pos + 13;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 15 - 28] == 0 && grid[current_pos - 1 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos + 1 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 15 - 29] == 0 && grid[current_pos - 1 - 29] == 0 && grid[current_pos - 29] == 0 && grid[current_pos + 1 - 29] == 0) begin
                                current_pos <= current_pos - 29;
                                current_state <= T_S;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos] == 0 && grid[current_pos + 13] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 14 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 13 + 1] == 0 && grid[current_pos + 14 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 14 - 13] == 0 && grid[current_pos - 13] == 0 && grid[current_pos + 13 - 13] == 0 && grid[current_pos + 14 - 13] == 0) begin
                                current_pos <= current_pos - 13;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 14 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 13 + 28] == 0 && grid[current_pos + 14 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 14 + 29] == 0 && grid[current_pos + 29] == 0 && grid[current_pos + 13 + 29] == 0 && grid[current_pos + 14 + 29] == 0) begin
                                current_pos <= current_pos + 29;
                                current_state <= T_L;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 1 + 1] == 0 && grid[current_pos + 15 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 + 15] == 0 && grid[current_pos + 15] == 0 && grid[current_pos + 1 + 15] == 0 && grid[current_pos + 15 + 15] == 0) begin
                                current_pos <= current_pos + 15;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos + 1 - 28] == 0 && grid[current_pos + 15 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 - 27] == 0 && grid[current_pos - 27] == 0 && grid[current_pos + 1 - 27] == 0 && grid[current_pos + 15 - 27] == 0) begin
                                current_pos <= current_pos - 27;
                                current_state <= T_2;
                            end
                        end
                    endcase
                end
                tetro_T: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 1 - 1] == 0 && grid[current_pos + 14 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 15] == 0 && grid[current_pos - 15] == 0 && grid[current_pos + 1 - 15] == 0 && grid[current_pos + 14 - 15] == 0) begin
                                current_pos <= current_pos - 15;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 1 + 28] == 0 && grid[current_pos + 14 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 27] == 0 && grid[current_pos + 27] == 0 && grid[current_pos + 1 + 27] == 0 && grid[current_pos + 14 + 27] == 0) begin
                                current_pos <= current_pos + 27;
                                current_state <= T_R;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 - 1] == 0 && grid[current_pos - 1 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 1 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 + 13] == 0 && grid[current_pos - 1 + 13] == 0 && grid[current_pos + 13] == 0 && grid[current_pos + 1 + 13] == 0) begin
                                current_pos <= current_pos + 13;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 - 28] == 0 && grid[current_pos - 1 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos + 1 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 - 29] == 0 && grid[current_pos - 1 - 29] == 0 && grid[current_pos - 29] == 0 && grid[current_pos + 1 - 29] == 0) begin
                                current_pos <= current_pos - 29;
                                current_state <= T_S;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos - 14] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 1 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos - 14 + 1] == 0 && grid[current_pos + 14 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 1 - 13] == 0 && grid[current_pos - 13] == 0 && grid[current_pos - 14 - 13] == 0 && grid[current_pos + 14 - 13] == 0) begin
                                current_pos <= current_pos - 13;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 1 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos - 14 + 28] == 0 && grid[current_pos + 14 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 1 + 29] == 0 && grid[current_pos + 29] == 0 && grid[current_pos - 14 + 29] == 0 && grid[current_pos + 14 + 29] == 0) begin
                                current_pos <= current_pos + 29;
                                current_state <= T_L;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 1 + 1] == 0 && grid[current_pos + 14 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 + 15] == 0 && grid[current_pos + 15] == 0 && grid[current_pos + 1 + 15] == 0 && grid[current_pos + 14 + 15] == 0) begin
                                current_pos <= current_pos + 15;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos + 1 - 28] == 0 && grid[current_pos + 14 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 - 27] == 0 && grid[current_pos - 27] == 0 && grid[current_pos + 1 - 27] == 0 && grid[current_pos + 14 - 27] == 0) begin
                                current_pos <= current_pos - 27;
                                current_state <= T_2;
                            end
                        end
                    endcase
                end
                tetro_S: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 1 - 1] == 0 && grid[current_pos + 15 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 15] == 0 && grid[current_pos - 15] == 0 && grid[current_pos + 1 - 15] == 0 && grid[current_pos + 15 - 15] == 0) begin
                                current_pos <= current_pos - 15;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 1 + 28] == 0 && grid[current_pos + 15 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 27] == 0 && grid[current_pos + 27] == 0 && grid[current_pos + 1 + 27] == 0 && grid[current_pos + 15 + 27] == 0) begin
                                current_pos <= current_pos + 27;
                                current_state <= T_R;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos - 13] == 0 && grid[current_pos] == 0 && grid[current_pos - 1] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 - 1] == 0 && grid[current_pos - 13 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos - 1 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 + 13] == 0 && grid[current_pos - 13 + 13] == 0 && grid[current_pos + 13] == 0 && grid[current_pos - 1 + 13] == 0) begin
                                current_pos <= current_pos + 13;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 - 28] == 0 && grid[current_pos - 13 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos - 1 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 - 29] == 0 && grid[current_pos - 13 - 29] == 0 && grid[current_pos - 29] == 0 && grid[current_pos - 1 - 29] == 0) begin
                                current_pos <= current_pos - 29;
                                current_state <= T_S;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 15] == 0 && grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 1] == 0 && grid[current_pos - 1 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 14 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 - 13] == 0 && grid[current_pos - 1 - 13] == 0 && grid[current_pos - 13] == 0 && grid[current_pos + 14 - 13] == 0) begin
                                current_pos <= current_pos - 13;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 28] == 0 && grid[current_pos - 1 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 14 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 29] == 0 && grid[current_pos - 1 + 29] == 0 && grid[current_pos + 29] == 0 && grid[current_pos + 14 + 29] == 0) begin
                                current_pos <= current_pos + 29;
                                current_state <= T_L;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos + 13] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 13 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 1 + 1] == 0 && grid[current_pos + 14 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 13 + 15] == 0 && grid[current_pos + 15] == 0 && grid[current_pos + 1 + 15] == 0 && grid[current_pos + 14 + 15] == 0) begin
                                current_pos <= current_pos + 15;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 13 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos + 1 - 28] == 0 && grid[current_pos + 14 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 13 - 27] == 0 && grid[current_pos - 27] == 0 && grid[current_pos + 1 - 27] == 0 && grid[current_pos + 14 - 27] == 0) begin
                                current_pos <= current_pos - 27;
                                current_state <= T_2;
                            end
                        end
                    endcase
                end
                tetro_Z: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 1 - 1] == 0 && grid[current_pos + 15 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 15] == 0 && grid[current_pos - 15] == 0 && grid[current_pos + 1 - 15] == 0 && grid[current_pos + 15 - 15] == 0) begin
                                current_pos <= current_pos - 15;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 1 + 28] == 0 && grid[current_pos + 15 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 27] == 0 && grid[current_pos + 27] == 0 && grid[current_pos + 1 + 27] == 0 && grid[current_pos + 15 + 27] == 0) begin
                                current_pos <= current_pos + 27;
                                current_state <= T_R;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos - 13] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 - 1] == 0 && grid[current_pos - 1 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos - 13 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 + 13] == 0 && grid[current_pos - 1 + 13] == 0 && grid[current_pos + 13] == 0 && grid[current_pos - 13 + 13] == 0) begin
                                current_pos <= current_pos + 13;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 - 28] == 0 && grid[current_pos - 1 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos - 13 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 - 29] == 0 && grid[current_pos - 1 - 29] == 0 && grid[current_pos - 29] == 0 && grid[current_pos - 13 - 29] == 0) begin
                                current_pos <= current_pos - 29;
                                current_state <= T_S;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 15] == 0 && grid[current_pos] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos - 1 + 1] == 0 && grid[current_pos + 13 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 - 13] == 0 && grid[current_pos - 13] == 0 && grid[current_pos - 1 - 13] == 0 && grid[current_pos + 13 - 13] == 0) begin
                                current_pos <= current_pos - 13;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos - 1 + 28] == 0 && grid[current_pos + 13 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 29] == 0 && grid[current_pos + 29] == 0 && grid[current_pos - 1 + 29] == 0 && grid[current_pos + 13 + 29] == 0) begin
                                current_pos <= current_pos + 29;
                                current_state <= T_L;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos + 13] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 13 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 1 + 1] == 0 && grid[current_pos + 14 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 13 + 15] == 0 && grid[current_pos + 15] == 0 && grid[current_pos + 1 + 15] == 0 && grid[current_pos + 14 + 15] == 0) begin
                                current_pos <= current_pos + 15;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 13 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos + 1 - 28] == 0 && grid[current_pos + 14 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 13 - 27] == 0 && grid[current_pos - 27] == 0 && grid[current_pos + 1 - 27] == 0 && grid[current_pos + 14 - 27] == 0) begin
                                current_pos <= current_pos - 27;
                                current_state <= T_2;
                            end
                        end
                    endcase
                end
            endcase

            // current_state <= (current_state == 0) ? 3 : current_state - 1;
        end

        else if (SP_ctclkrt) begin

            case (current_tetromino) 
                tetro_I: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos + 14] == 0 && grid[current_pos] == 0 && grid[current_pos - 14] == 0 && grid[current_pos + 28] == 0) begin
                                current_pos <= current_pos + 14;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos + 14 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos - 14 - 1] == 0 && grid[current_pos + 28 - 1] == 0) begin
                                current_pos <= current_pos + 14 - 1;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos + 14 + 2] == 0 && grid[current_pos + 2] == 0 && grid[current_pos - 14 + 2] == 0 && grid[current_pos + 28 + 2] == 0) begin
                                current_pos <= current_pos + 14 + 2;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos + 14 - 29] == 0 && grid[current_pos - 29] == 0 && grid[current_pos - 14 - 29] == 0 && grid[current_pos + 28 - 29] == 0) begin
                                current_pos <= current_pos + 14 - 29;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos + 14 + 16] == 0 && grid[current_pos + 16] == 0 && grid[current_pos - 14 + 16] == 0 && grid[current_pos + 28 + 16] == 0) begin
                                current_pos <= current_pos + 14 + 16;
                                current_state <= T_L;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 2] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 - 2] == 0 && grid[current_pos - 2] == 0 && grid[current_pos + 1 - 2] == 0 && grid[current_pos + 2 - 2] == 0) begin
                                current_pos <= current_pos + 1 - 2;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 1 + 1] == 0 && grid[current_pos + 2 + 1] == 0) begin
                                current_pos <= current_pos + 1 + 1;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 + 12] == 0 && grid[current_pos + 12] == 0 && grid[current_pos + 1 + 12] == 0 && grid[current_pos + 2 + 12] == 0) begin
                                current_pos <= current_pos + 1 + 12;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 - 27] == 0 && grid[current_pos - 27] == 0 && grid[current_pos + 1 - 27] == 0 && grid[current_pos + 2 - 27] == 0) begin
                                current_pos <= current_pos + 1 - 27;
                                current_state <= T_2;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 28] == 0 && grid[current_pos - 14] == 0 && grid[current_pos] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos - 14;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 28 + 1] == 0 && grid[current_pos - 14 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 14 + 1] == 0) begin
                                current_pos <= current_pos - 14 + 1;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 28 - 2] == 0 && grid[current_pos - 14 - 2] == 0 && grid[current_pos - 2] == 0 && grid[current_pos + 14 - 2] == 0) begin
                                current_pos <= current_pos - 14 - 2;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 28 + 29] == 0 && grid[current_pos - 14 + 29] == 0 && grid[current_pos + 29] == 0 && grid[current_pos + 14 + 29] == 0) begin
                                current_pos <= current_pos - 14 + 29;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 28 - 16] == 0 && grid[current_pos - 14 - 16] == 0 && grid[current_pos - 16] == 0 && grid[current_pos + 14 - 16] == 0) begin
                                current_pos <= current_pos - 14 - 16;
                                current_state <= T_R;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 2] == 0 && grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 2 + 2] == 0 && grid[current_pos - 1 + 2] == 0 && grid[current_pos + 2] == 0 && grid[current_pos + 1 + 2] == 0) begin
                                current_pos <= current_pos - 1 + 2;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 2 - 1] == 0 && grid[current_pos - 1 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 1 - 1] == 0) begin
                                current_pos <= current_pos - 1 - 1;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 2 - 12] == 0 && grid[current_pos - 1 - 12] == 0 && grid[current_pos - 12] == 0 && grid[current_pos + 1 - 12] == 0) begin
                                current_pos <= current_pos - 1 - 12;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 2 + 27] == 0 && grid[current_pos - 1 + 27] == 0 && grid[current_pos + 27] == 0 && grid[current_pos + 1 + 27] == 0) begin
                                current_pos <= current_pos - 1 + 27;
                                current_state <= T_S;
                            end
                        end
                    endcase
                end
                tetro_O: begin
                end
                tetro_L: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 15] == 0 && grid[current_pos - 14] == 0 && grid[current_pos] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 1] == 0 && grid[current_pos - 14 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 14 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 - 13] == 0 && grid[current_pos - 14 - 13] == 0 && grid[current_pos - 13] == 0 && grid[current_pos + 14 - 13] == 0) begin
                                current_pos <= current_pos - 13;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 28] == 0 && grid[current_pos - 14 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 14 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 29] == 0 && grid[current_pos - 14 + 29] == 0 && grid[current_pos + 29] == 0 && grid[current_pos + 14 + 29] == 0) begin
                                current_pos <= current_pos + 29;
                                current_state <= T_L;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 1 - 1] == 0 && grid[current_pos + 13 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 + 13] == 0 && grid[current_pos + 13] == 0 && grid[current_pos + 1 + 13] == 0 && grid[current_pos + 13 + 13] == 0) begin
                                current_pos <= current_pos + 13;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos + 1 - 28] == 0 && grid[current_pos + 13 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 - 29] == 0 && grid[current_pos - 29] == 0 && grid[current_pos + 1 - 29] == 0 && grid[current_pos + 13 - 29] == 0) begin
                                current_pos <= current_pos - 29;
                                current_state <= T_2;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos] == 0 && grid[current_pos + 15] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 15 - 1] == 0 && grid[current_pos + 14 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 15] == 0 && grid[current_pos - 15] == 0 && grid[current_pos + 15 - 15] == 0 && grid[current_pos + 14 - 15] == 0) begin
                                current_pos <= current_pos - 15;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 15 + 28] == 0 && grid[current_pos + 14 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 27] == 0 && grid[current_pos + 27] == 0 && grid[current_pos + 15 + 27] == 0 && grid[current_pos + 14 + 27] == 0) begin
                                current_pos <= current_pos + 27;
                                current_state <= T_R;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos - 13] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 1 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 1 + 1] == 0 && grid[current_pos - 13 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 1 + 15] == 0 && grid[current_pos + 15] == 0 && grid[current_pos + 1 + 15] == 0 && grid[current_pos - 13 + 15] == 0) begin
                                current_pos <= current_pos + 15;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 1 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos + 1 - 28] == 0 && grid[current_pos - 13 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 1 - 27] == 0 && grid[current_pos - 27] == 0 && grid[current_pos + 1 - 27] == 0 && grid[current_pos - 13 - 27] == 0) begin
                                current_pos <= current_pos - 27;
                                current_state <= T_S;
                            end
                        end
                    endcase
                end
                tetro_J: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos] == 0 && grid[current_pos + 13] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 14 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 13 + 1] == 0 && grid[current_pos + 14 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 14 - 13] == 0 && grid[current_pos - 13] == 0 && grid[current_pos + 13 - 13] == 0 && grid[current_pos + 14 - 13] == 0) begin
                                current_pos <= current_pos - 13;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 14 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 13 + 28] == 0 && grid[current_pos + 14 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 14 + 29] == 0 && grid[current_pos + 29] == 0 && grid[current_pos + 13 + 29] == 0 && grid[current_pos + 14 + 29] == 0) begin
                                current_pos <= current_pos + 29;
                                current_state <= T_L;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 1 - 1] == 0 && grid[current_pos + 15 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 + 13] == 0 && grid[current_pos + 13] == 0 && grid[current_pos + 1 + 13] == 0 && grid[current_pos + 15 + 13] == 0) begin
                                current_pos <= current_pos + 13;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos + 1 - 28] == 0 && grid[current_pos + 15 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 1 - 29] == 0 && grid[current_pos - 29] == 0 && grid[current_pos + 1 - 29] == 0 && grid[current_pos + 15 - 29] == 0) begin
                                current_pos <= current_pos - 29;
                                current_state <= T_2;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos - 13] == 0 && grid[current_pos] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 1] == 0 && grid[current_pos - 13 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 14 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 15] == 0 && grid[current_pos - 13 - 15] == 0 && grid[current_pos - 15] == 0 && grid[current_pos + 14 - 15] == 0) begin
                                current_pos <= current_pos - 15;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 28] == 0 && grid[current_pos - 13 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 14 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 27] == 0 && grid[current_pos - 13 + 27] == 0 && grid[current_pos + 27] == 0 && grid[current_pos + 14 + 27] == 0) begin
                                current_pos <= current_pos + 27;
                                current_state <= T_R;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 15] == 0 && grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 15 + 1] == 0 && grid[current_pos - 1 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 1 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 15 + 15] == 0 && grid[current_pos - 1 + 15] == 0 && grid[current_pos + 15] == 0 && grid[current_pos + 1 + 15] == 0) begin
                                current_pos <= current_pos + 15;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 15 - 28] == 0 && grid[current_pos - 1 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos + 1 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 15 - 27] == 0 && grid[current_pos - 1 - 27] == 0 && grid[current_pos - 27] == 0 && grid[current_pos + 1 - 27] == 0) begin
                                current_pos <= current_pos - 27;
                                current_state <= T_S;
                            end
                        end
                    endcase
                end
                tetro_T: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos - 14] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 1 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos - 14 + 1] == 0 && grid[current_pos + 14 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 1 - 13] == 0 && grid[current_pos - 13] == 0 && grid[current_pos - 14 - 13] == 0 && grid[current_pos + 14 - 13] == 0) begin
                                current_pos <= current_pos - 13;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 1 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos - 14 + 28] == 0 && grid[current_pos + 14 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 1 + 29] == 0 && grid[current_pos + 29] == 0 && grid[current_pos - 14 + 29] == 0 && grid[current_pos + 14 + 29] == 0) begin
                                current_pos <= current_pos + 29;
                                current_state <= T_L;
                            end
                        end
                        T_L: begin//
                            if (grid[current_pos - 14] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 14 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 1 - 1] == 0 && grid[current_pos + 14 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 14 + 13] == 0 && grid[current_pos + 13] == 0 && grid[current_pos + 1 + 13] == 0 && grid[current_pos + 14 + 13] == 0) begin
                                current_pos <= current_pos + 13;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 14 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos + 1 - 28] == 0 && grid[current_pos + 14 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos - 14 - 29] == 0 && grid[current_pos - 29] == 0 && grid[current_pos + 1 - 29] == 0 && grid[current_pos + 14 - 29] == 0) begin
                                current_pos <= current_pos - 29;
                                current_state <= T_2;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 1 - 1] == 0 && grid[current_pos + 14 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 15] == 0 && grid[current_pos - 15] == 0 && grid[current_pos + 1 - 15] == 0 && grid[current_pos + 14 - 15] == 0) begin
                                current_pos <= current_pos - 15;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 1 + 28] == 0 && grid[current_pos + 14 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 27] == 0 && grid[current_pos + 27] == 0 && grid[current_pos + 1 + 27] == 0 && grid[current_pos + 14 + 27] == 0) begin
                                current_pos <= current_pos + 27;
                                current_state <= T_R;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 + 1] == 0 && grid[current_pos - 1 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 1 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 + 15] == 0 && grid[current_pos - 1 + 15] == 0 && grid[current_pos + 15] == 0 && grid[current_pos + 1 + 15] == 0) begin
                                current_pos <= current_pos + 15;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 - 28] == 0 && grid[current_pos - 1 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos + 1 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 - 27] == 0 && grid[current_pos - 1 - 27] == 0 && grid[current_pos - 27] == 0 && grid[current_pos + 1 - 27] == 0) begin
                                current_pos <= current_pos - 27;
                                current_state <= T_S;
                            end
                        end
                    endcase
                end
                tetro_S: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 15] == 0 && grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 1] == 0 && grid[current_pos - 1 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 14 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 - 13] == 0 && grid[current_pos - 1 - 13] == 0 && grid[current_pos - 13] == 0 && grid[current_pos + 14 - 13] == 0) begin
                                current_pos <= current_pos - 13;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 28] == 0 && grid[current_pos - 1 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 14 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 29] == 0 && grid[current_pos - 1 + 29] == 0 && grid[current_pos + 29] == 0 && grid[current_pos + 14 + 29] == 0) begin
                                current_pos <= current_pos + 29;
                                current_state <= T_L;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos + 13] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 13 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 1 - 1] == 0 && grid[current_pos + 14 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 13 + 13] == 0 && grid[current_pos + 13] == 0 && grid[current_pos + 1 + 13] == 0 && grid[current_pos + 14 + 13] == 0) begin
                                current_pos <= current_pos + 13;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 13 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos + 1 - 28] == 0 && grid[current_pos + 14 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 13 - 29] == 0 && grid[current_pos - 29] == 0 && grid[current_pos + 1 - 29] == 0 && grid[current_pos + 14 - 29] == 0) begin
                                current_pos <= current_pos - 29;
                                current_state <= T_2;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 1 - 1] == 0 && grid[current_pos + 15 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 15] == 0 && grid[current_pos - 15] == 0 && grid[current_pos + 1 - 15] == 0 && grid[current_pos + 15 - 15] == 0) begin
                                current_pos <= current_pos - 15;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 1 + 28] == 0 && grid[current_pos + 15 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 27] == 0 && grid[current_pos + 27] == 0 && grid[current_pos + 1 + 27] == 0 && grid[current_pos + 15 + 27] == 0) begin
                                current_pos <= current_pos + 27;
                                current_state <= T_R;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos - 13] == 0 && grid[current_pos] == 0 && grid[current_pos - 1] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 + 1] == 0 && grid[current_pos - 13 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos - 1 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 + 15] == 0 && grid[current_pos - 13 + 15] == 0 && grid[current_pos + 15] == 0 && grid[current_pos - 1 + 15] == 0) begin
                                current_pos <= current_pos + 15;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 - 28] == 0 && grid[current_pos - 13 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos - 1 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 - 27] == 0 && grid[current_pos - 13 - 27] == 0 && grid[current_pos - 27] == 0 && grid[current_pos - 1 - 27] == 0) begin
                                current_pos <= current_pos - 27;
                                current_state <= T_S;
                            end
                        end
                    endcase
                end
                tetro_Z: begin
                    case (current_state) 
                        T_S: begin
                            if (grid[current_pos - 15] == 0 && grid[current_pos] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 13] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos - 1 + 1] == 0 && grid[current_pos + 13 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 - 13] == 0 && grid[current_pos - 13] == 0 && grid[current_pos - 1 - 13] == 0 && grid[current_pos + 13 - 13] == 0) begin
                                current_pos <= current_pos - 13;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos - 1 + 28] == 0 && grid[current_pos + 13 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_L;
                            end
                            else if (grid[current_pos - 15 + 29] == 0 && grid[current_pos + 29] == 0 && grid[current_pos - 1 + 29] == 0 && grid[current_pos + 13 + 29] == 0) begin
                                current_pos <= current_pos + 29;
                                current_state <= T_L;
                            end
                        end
                        T_L: begin
                            if (grid[current_pos + 13] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 14] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 13 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 1 - 1] == 0 && grid[current_pos + 14 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 13 + 13] == 0 && grid[current_pos + 13] == 0 && grid[current_pos + 1 + 13] == 0 && grid[current_pos + 14 + 13] == 0) begin
                                current_pos <= current_pos + 13;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 13 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos + 1 - 28] == 0 && grid[current_pos + 14 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_2;
                            end
                            else if (grid[current_pos + 13 - 29] == 0 && grid[current_pos - 29] == 0 && grid[current_pos + 1 - 29] == 0 && grid[current_pos + 14 - 29] == 0) begin
                                current_pos <= current_pos - 29;
                                current_state <= T_2;
                            end
                        end
                        T_2: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos] == 0 && grid[current_pos + 1] == 0 && grid[current_pos + 15] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 1] == 0 && grid[current_pos - 1] == 0 && grid[current_pos + 1 - 1] == 0 && grid[current_pos + 15 - 1] == 0) begin
                                current_pos <= current_pos - 1;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 - 15] == 0 && grid[current_pos - 15] == 0 && grid[current_pos + 1 - 15] == 0 && grid[current_pos + 15 - 15] == 0) begin
                                current_pos <= current_pos - 15;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 28] == 0 && grid[current_pos + 28] == 0 && grid[current_pos + 1 + 28] == 0 && grid[current_pos + 15 + 28] == 0) begin
                                current_pos <= current_pos + 28;
                                current_state <= T_R;
                            end
                            else if (grid[current_pos - 14 + 27] == 0 && grid[current_pos + 27] == 0 && grid[current_pos + 1 + 27] == 0 && grid[current_pos + 15 + 27] == 0) begin
                                current_pos <= current_pos + 27;
                                current_state <= T_R;
                            end
                        end
                        T_R: begin
                            if (grid[current_pos - 14] == 0 && grid[current_pos - 1] == 0 && grid[current_pos] == 0 && grid[current_pos - 13] == 0) begin
                                current_pos <= current_pos;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 + 1] == 0 && grid[current_pos - 1 + 1] == 0 && grid[current_pos + 1] == 0 && grid[current_pos - 13 + 1] == 0) begin
                                current_pos <= current_pos + 1;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 + 15] == 0 && grid[current_pos - 1 + 15] == 0 && grid[current_pos + 15] == 0 && grid[current_pos - 13 + 15] == 0) begin
                                current_pos <= current_pos + 15;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 - 28] == 0 && grid[current_pos - 1 - 28] == 0 && grid[current_pos - 28] == 0 && grid[current_pos - 13 - 28] == 0) begin
                                current_pos <= current_pos - 28;
                                current_state <= T_S;
                            end
                            else if (grid[current_pos - 14 - 27] == 0 && grid[current_pos - 1 - 27] == 0 && grid[current_pos - 27] == 0 && grid[current_pos - 13 - 27] == 0) begin
                                current_pos <= current_pos - 27;
                                current_state <= T_S;
                            end
                        end
                    endcase
                end
            endcase

            // current_state <= (current_state == 3) ? 0 : current_state + 1;
        end

        else if (SP_fastsown) begin
            current_pos <= shadow_pos[0];
            fallen <= 1;
        end

        else if (SP_gnrtobst) begin
            
        end

        else if (SP_pause) begin
            
        end
    end

    else if (P == SPGO) begin
        if (random_obst_counter == 0) begin //tsj
            grid[128] <= 0; grid[129] <= 0; grid[130] <= 0; grid[131] <= 0; grid[132] <= 0; 
            grid[142] <= 0; grid[143] <= 5; grid[144] <= 5; grid[145] <= 5; grid[146] <= 0; 
            grid[156] <= 0; grid[157] <= 0; grid[158] <= 5; grid[159] <= 0; grid[160] <= 0; 
            grid[171] <= 0; grid[172] <= 0; grid[173] <= 0; grid[174] <= 0; grid[175] <= 0; grid[176] <= 0;
            grid[187] <= 0; grid[188] <= 6; grid[189] <= 0; grid[190] <= 0; 
            grid[201] <= 0; grid[202] <= 6; grid[203] <= 6; grid[204] <= 0; 
            grid[215] <= 0; grid[216] <= 0; grid[217] <= 6; grid[218] <= 0; grid[219] <= 0; grid[220] <= 0; grid[221] <= 0; 
            grid[230] <= 0; grid[231] <= 0; grid[232] <= 0; grid[233] <= 0; grid[234] <= 4; grid[235] <= 0; 
            grid[246] <= 0; grid[247] <= 0; grid[248] <= 4; grid[249] <= 0; 
            grid[260] <= 0; grid[261] <= 4; grid[262] <= 4; grid[263] <= 0; 
            grid[274] <= 0; grid[275] <= 0; grid[276] <= 0; grid[277] <= 0; 
        end
        else if (random_obst_counter == 1) begin //trista
            grid[243] <= 0; grid[244] <= 0; grid[245] <= 0;             
            grid[254] <= 0; grid[255] <= 0; grid[256] <= 0; grid[257] <= 2; grid[258] <= 2; grid[259] <= 0; grid[260] <= 0; grid[261] <= 0; grid[262] <= 0; grid[263] <= 0;
            grid[268] <= 0; grid[269] <= 2; grid[270] <= 2; grid[271] <= 2; grid[272] <= 2; grid[273] <= 0; grid[274] <= 2; grid[275] <= 0; grid[276] <= 2; grid[277] <= 0; 
            grid[282] <= 0; grid[283] <= 2; grid[284] <= 2; grid[285] <= 0; grid[286] <= 0; grid[287] <= 0; grid[288] <= 2; grid[289] <= 0; grid[290] <= 2; grid[291] <= 0; 
            grid[296] <= 0; grid[297] <= 0; grid[298] <= 0;                                 grid[301] <= 0; grid[302] <= 0; grid[303] <= 0; grid[304] <= 0; grid[305] <= 0; 
        end
        else if (random_obst_counter == 2) begin //grass
            grid[254] <= 6; grid[255] <= 6; grid[256] <= 6; grid[257] <= 0; grid[258] <= 0; grid[259] <= 6; grid[260] <= 0; grid[261] <= 0; grid[262] <= 0; grid[263] <= 0; 
            grid[268] <= 0; grid[269] <= 6; grid[270] <= 6; grid[271] <= 6; grid[272] <= 6; grid[273] <= 6; grid[274] <= 6; grid[275] <= 6; grid[276] <= 0; grid[277] <= 6; 
            grid[282] <= 0; grid[283] <= 0; grid[284] <= 6; grid[285] <= 0; grid[286] <= 6; grid[287] <= 6; grid[288] <= 0; grid[289] <= 6; grid[290] <= 6; grid[291] <= 6;
        end
        else if (random_obst_counter == 3) begin // fire
            grid[187] <= 0; grid[188] <= 0; grid[189] <= 0; grid[190] <= 0; 
            grid[201] <= 0; grid[202] <= 7; grid[203] <= 7; grid[204] <= 0; grid[205] <= 0; 
            grid[214] <= 0; grid[215] <= 0; grid[216] <= 7; grid[217] <= 7; grid[218] <= 7; grid[219] <= 0;
            grid[227] <= 0; grid[228] <= 0; grid[229] <= 7; grid[230] <= 7; grid[231] <= 3; grid[232] <= 7; grid[233] <= 0; grid[234] <= 0;
            grid[241] <= 0; grid[242] <= 7; grid[243] <= 7; grid[244] <= 3; grid[245] <= 3; grid[246] <= 3; grid[247] <= 7; grid[248] <= 0; 
            grid[254] <= 0; grid[255] <= 0; grid[256] <= 7; grid[257] <= 7; grid[258] <= 3; grid[259] <= 3; grid[260] <= 3; grid[261] <= 7; grid[262] <= 0; grid[263] <= 0; 
            grid[268] <= 7; grid[269] <= 7; grid[270] <= 7; grid[271] <= 3; grid[272] <= 3; grid[273] <= 0; grid[274] <= 3; grid[275] <= 7; grid[276] <= 7; grid[277] <= 7;
            grid[282] <= 7; grid[283] <= 3; grid[284] <= 3; grid[285] <= 3; grid[286] <= 0; grid[287] <= 0; grid[288] <= 3; grid[289] <= 3; grid[290] <= 3; grid[291] <= 7;
            grid[296] <= 3; grid[297] <= 3; grid[298] <= 3; grid[299] <= 0; grid[300] <= 0; grid[301] <= 0; grid[302] <= 0; grid[303] <= 3; grid[304] <= 3; grid[305] <= 3;
        end
    end
    else if (P == SPSR) begin
        
    end
    else if (P == DPIG) begin
        
    end
end
//End of Game

// Score
integer i;
always @(score) begin
    scorebroad[6]=0;
    scorebroad[5]=0;
    scorebroad[4]=0;
    scorebroad[3]=0;
    scorebroad[2]=0;
    scorebroad[1]=0;
    scorebroad[0]=0;
    for(i=23;i>=0;i=i-1)begin
        if(scorebroad[0]>=5)begin
            scorebroad[0]=scorebroad[0]+3;
        end
        if(scorebroad[1]>=5)begin
            scorebroad[1]=scorebroad[1]+3;
        end
        if(scorebroad[2]>=5)begin
            scorebroad[2]=scorebroad[2]+3;
        end
        if(scorebroad[3]>=5)begin
            scorebroad[3]=scorebroad[3]+3;
        end
        if(scorebroad[4]>=5)begin
            scorebroad[4]=scorebroad[4]+3;
        end
        if(scorebroad[5]>=5)begin
            scorebroad[5]=scorebroad[5]+3;
        end
        if(scorebroad[6]>=5)begin
            scorebroad[6]=scorebroad[6]+3;
        end
        scorebroad[0]=scorebroad[0]<<1;
        scorebroad[0][0]=scorebroad[1][3];
        scorebroad[1]=scorebroad[1]<<1;
        scorebroad[1][0]=scorebroad[2][3];
        scorebroad[2]=scorebroad[2]<<1;
        scorebroad[2][0]=scorebroad[3][3];
        scorebroad[3]=scorebroad[3]<<1;
        scorebroad[3][0]=scorebroad[4][3];
        scorebroad[4]=scorebroad[4]<<1;
        scorebroad[4][0]=scorebroad[5][3];
        scorebroad[5]=scorebroad[5]<<1;
        scorebroad[5][0]=scorebroad[6][3];
        scorebroad[6]=scorebroad[6]<<1;
        scorebroad[6][0]=score[i];
    end
end 
// End of score

//P == Initialize game counter
always @(posedge clk ) begin
    if (~reset_n) begin
        init_counter <= 0;
    end 
    else if (P == SPIG) begin
        init_counter <= (init_counter == initial_time) ? init_counter : init_counter + 1;
    end
    else begin
        init_counter <= 0;
    end
end
// end of initialize game counter

//P == clear line counter
always @(posedge clk ) begin
    if (~reset_n || P == IDLE) begin
        cl_counter <= 0;
    end 
    else if (P == SPCL) begin
        cl_counter <= (cl_counter == 3) ? cl_counter : cl_counter + 1;
    end
    else begin
        cl_counter <= 0;
    end
end
// end of clear line counter

//Random tetromino logic
always @(posedge clk ) begin
    if (~reset_n || P == IDLE) begin
        // tetromino_ctr <= init_tetro_counter * 7 - 1 + 5 - 1;
        tetromino_ctr <= 10;
    end 
    else if ((P == SPGP) && (P_next == SPPP)) begin
        tetromino_ctr <= (tetromino_ctr == 104) ? 0 : tetromino_ctr + 1;
    end
    else if ((SP_hold && (holded == 0)) && (pre_holded_idx == 128)) begin
        tetromino_ctr <= (tetromino_ctr == 104) ? 0 : tetromino_ctr + 1;
    end
    else if ((P == SPPM) && (P_next == SPIG)) begin
        // tetromino_ctr <= init_tetro_counter * 7 - 1 + 5 - 1;
        tetromino_ctr <= 10;
    end
end
always @(posedge clk ) begin
    if (~reset_n || P == IDLE) begin
        init_tetro_counter <= 2;
    end 
    else if (P == SPCL) begin
        init_tetro_counter <= (init_tetro_counter == 13) ? 2 : init_tetro_counter + 1;
    end
    else begin
        init_tetro_counter <= 2;
    end
end
//End of Random tetromino logic

//Fall counter
always @(posedge clk ) begin
    if (~reset_n || P == IDLE) begin
        fall_counter <= 0;
        speed_num <= 110_000_000;
    end
    else if (P == SPFL) begin
        if (!btn_level[3] && btn_pressed[1]) begin
            fall_counter <= 15_000_000;
            speed_num <= 25_000_000;
        end
        else if (!btn_level[3] && btn_released[1]) begin
            speed_num <= 110_000_000;
        end
        else if (SP_ctclkrt || SP_clkrt) begin
            fall_counter <= 0;
        end
        else begin
            fall_counter <= (fall_counter == speed_num) ? 0 : fall_counter + 1;
        end
    end
    else begin
        fall_counter <= 0;
        speed_num <= 70_000_000;
    end
end
//End of fall counter

//t_spin_counter counter
always @(posedge clk ) begin
    if (~reset_n || P == SPIG) begin
        t_spin_counter <= t_spin_time;
        t_spin_type <= 0;
    end
    else if (t_spin_single) begin
        t_spin_type <= 1;
        t_spin_counter <= 0;
    end
    else if (t_spin_double) begin
        t_spin_type <= 2;
        t_spin_counter <= 0;
    end
    else if (t_spin_triple) begin
        t_spin_type <= 3;
        t_spin_counter <= 0;
    end
    else if (t_spin_type && t_spin_period) begin
        t_spin_counter <= (t_spin_counter < t_spin_time) ? t_spin_counter + 1 : t_spin_counter;
    end
    else if (t_spin_type && !t_spin_period) begin
        t_spin_type <= 0;
    end
    else begin
        t_spin_counter <= t_spin_time;
    end
end
//End of t_spin_counter

// random_obst_counter
always @(posedge clk ) begin
    if (~reset_n || P == IDLE) begin
        random_obst_counter <= 0;
    end 
    else if (P == SPCL) begin
        random_obst_counter <= (random_obst_counter == 3) ? 0 : random_obst_counter + 1;
    end
end

//
always @(posedge clk ) begin
    if (~reset_n || P == SPIG) begin
        first_holded <= 0;
    end
    else if (first_hold) begin
        first_holded <= 1;
    end
end

// scoreboard
always @(posedge clk ) begin
    if (~reset_n || P == SPIG) begin
        number_HPOS <= 225;
        number_VPOS <= 175;
        score_picture_HPOS <= 200;
        score_picture_VPOS <= 125;
    end
    else if (P == SPSR || P_next == SPSR) begin
        number_HPOS <= 110;
        number_VPOS <= 170;
        score_picture_HPOS <= 85;
        score_picture_VPOS <= 120;
    end
    else begin
        number_HPOS <= 225;
        number_VPOS <= 175;
        score_picture_HPOS <= 200;
        score_picture_VPOS <= 125;
    end
end

// ------------------------------------------------------------------------


endmodule
