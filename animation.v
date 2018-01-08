module top
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		KEY,							// On Board Keys
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input [3:0] KEY;

						
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	
	wire resetn;
	
	assign resetn = KEY[0];
	
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;


	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "field.mif";
			
	
	wire [15:0] address;
	wire [2:0] out;
	
	
	assign writeEn = 1'b1;

	//KEY[3] is user input
	assign user = ~KEY[3];

	wire plot, countenable, done_draw, done_wait, done_update, update, wait_countenable, done_erase, erase;
	wire rate, pause_countenable, done_pause, got_rate, score, done_score;
	wire plot_bat, countenable_bat, wait_countenable_bat, update_bat, erase_bat, erase_ball;
	wire done_draw_bat, done_wait_bat, done_erase_bat, done_update_bat, done_erase_ball;
	wire plot_fly, countenable_fly, wait_countenable_fly, update_fly, erase_fly;
	wire done_draw_fly, done_wait_fly, done_erase_fly, done_update_fly;
	wire done_erase_start, done_start, start, erase_start;
	wire draw_done, done_draw_done;

	wire [3:0] batnum;
	wire [3:0] ball;
	wire [3:0] flynum;
	wire [3:0] game;

	datapath u1(resetn, CLOCK_50, plot, countenable, wait_countenable, update, erase, rate, pause_countenable,
			 	done_draw, done_wait, done_update, done_erase, done_pause, got_rate, x, y, colour, ball,
			 	plot_bat, countenable_bat, wait_countenable_bat, update_bat, erase_bat, score, erase_ball, game,
				done_draw_bat, done_wait_bat, done_erase_bat, done_update_bat, batnum, done_score, done_erase_ball, plot_fly,
			 	countenable_fly, wait_countenable_fly, update_fly, erase_fly, done_draw_fly, done_wait_fly, done_erase_fly, done_update_fly,
			 	flynum, done_start, done_erase_start, start, erase_start, draw_done, done_draw_done);

	controlpath u2(resetn, CLOCK_50, done_draw, done_wait, done_update, done_erase, got_rate, done_pause, ball, user, done_bat,
					plot, countenable, wait_countenable, update, erase, rate, pause_countenable,
					plot_bat, countenable_bat, wait_countenable_bat, update_bat, erase_bat, score, erase_ball, game,
					done_draw_bat, done_wait_bat, done_erase_bat, done_update_bat, batnum, done_score, done_erase_ball, plot_fly, countenable_fly,
					wait_countenable_fly, update_fly, erase_fly, done_draw_fly, done_wait_fly, done_erase_fly, done_update_fly, flynum,
					done_start, done_erase_start, start, erase_start, draw_done, done_draw_done);
					

endmodule

//counts in a rectangle for printing
module rectangleCounter (resetn, enableCounter, width, height, clock, x, y, done);
	input enableCounter, clock, resetn;
	input[7:0] width;
	input[6:0] height;
	output reg done; //signal that indicates if counter is done
	output reg [7:0] x;
	output reg [6:0] y;

	always @ (posedge clock) 
	begin
		if (!resetn || !enableCounter)
			begin
				x <= 0;
				y <= 0;
				done <= 0;
			end
		
		else if (enableCounter)
		begin
			if (y == (height - 1) && x == (width - 1))
				begin
				x <= 0;
				y <= 0;
				done <= 1;
				end
			else if (x != (width - 1))
				begin
					x <= x + 1;
				end
			else if (x == (width - 1))
				begin
					y <= y + 1;
					x <= 0;
				end
		end
	end
endmodule

//counter for image address
module imageCounter(maxpixel, resetn, enable, clock, address);
	input [7:0] maxpixel;
	input clock, enable, resetn;
	output reg [7:0] address;

	always @ (posedge clock) 
	begin
		address <= 0;
		if (!resetn || !enable)
			begin
			address <= 0;
			end
		else if (enable && address > maxpixel) //end of image
			begin
			address <= 0;
			end
		else if (enable)
		begin
			address <= address + 1;
		end
	end
endmodule

//counts a square for printing
module XYcounter (resetn, enableCounter, pixel, clock, x, y, done);
	input enableCounter, clock, resetn;
	input [3:0] pixel; //pixel is the width of the ball
	output reg done; //signal that indicates if counter is done
	output reg [3:0] x, y;

	always @ (posedge clock) 
	begin
		if (!resetn || !enableCounter)
			begin
				x <= 0;
				y <= 0;
				done <= 0;
			end
		
		else if (enableCounter)
		begin
			if (y == (pixel - 1) && x == (pixel - 1))
				begin
				x <= 0;
				y <= 0;
				done <= 1;
				end
			else if (x != (pixel - 1))
				begin
					x <= x + 1;
				end
			else if (x == (pixel - 1))
				begin
					y <= y + 1;
					x <= 0;
				end
		end
	end
endmodule

//address translator for 160x120	
module address_translator(x, y, address);
	input [7:0] x;
	input [6:0] y;

	output reg [14:0] address;

	wire [15:0] res_160x120 = ({1'b0, y, 7'd0} + {1'b0, y, 5'd0} + {1'b0, x});

	always @(*)
	begin
		address = res_160x120[14:0];
	end
endmodule

//mux that stores the coordinates and size of the six ball images
module infoMux(image, pixel, maxpixel, x, y);
	input [3:0] image;
	output reg [3:0] pixel;
	output reg [7:0] x;
	output reg [6:0] y;
	output reg [7:0] maxpixel;

	parameter [3:0] ballone = 4'b0000, //0
						 balltwo = 4'b0010, //2
						 ballthree = 4'b0100, //4
						 ballfour = 4'b0110, //6
						 ballfive = 4'b1000, //8
						 ballsix = 4'b1010; //10
	
	always @ (*)
	begin
	case (image)
		ballone:
			begin
			pixel = 4'b0101;
			maxpixel = 8'b00011000;
			x = 8'b01010111;
			y = 7'b0110010;
			end
		balltwo:
			begin
			pixel = 4'b0111;
			maxpixel = 8'b00110000;
			x = 8'b01011011;
			y = 7'b0110110;
			end
		ballthree:
			begin
			pixel = 4'b1001;
			maxpixel = 8'b01010000;
			x = 8'b01011011;
			y = 7'b0111110;
			end
		ballfour:
			begin
			pixel = 4'b1011;
			maxpixel = 8'b01111000;
			x = 8'b01011000;
			y = 7'b1001000;
			end
		ballfive:
			begin
			pixel = 4'b1101;
			maxpixel = 8'b10101000;
			x = 8'b01010011;
			y = 7'b1010100;
			end
		ballsix:
			begin
			pixel = 4'b1111;
			maxpixel = 8'b11100000;
			x = 8'b01001011;
			y = 7'b1100001;
			end
		default:
			begin
			pixel = 4'b0000;
			maxpixel = 8'b00000000;
			x = 8'b00000000;
			y = 7'b0000000;
			end
	 endcase
end
endmodule

//mux that chooses colour to output based on ball number
module selectColour(image, ball_out1, ball_out2, ball_out3, ball_out4, ball_out5, ball_out6, ball_colour);
	input[2:0] ball_out1, ball_out2, ball_out3, ball_out4, ball_out5, ball_out6;
	input [3:0] image;
	output reg [2:0] ball_colour;

	parameter [3:0] ball_one = 4'b0000, //0
					 ball_two = 4'b0010, //2
					 ball_three = 4'b0100, //4
					 ball_four = 4'b0110, //6
					 ball_five = 4'b1000, //8
					 ball_six = 4'b1010; //10
	
	always @ (*)
	begin
	case (image)
		ball_one:
			begin
			ball_colour = ball_out1;
			end
		ball_two:
			begin
			ball_colour = ball_out2;
			end
		ball_three:
			begin
			ball_colour = ball_out3;
			end
		ball_four:
			begin
			ball_colour = ball_out4;
			end
		ball_five:
			begin
			ball_colour = ball_out5;
			end
		ball_six:
			begin
			ball_colour = ball_out6; 
			end
		default:
			begin
			ball_colour = 3'b000;
			end
	 endcase
end

endmodule

/////////////////////////BAT MODULES/////////////////////////

//mux that stores the coordinates and size of the three bat images
module BATinfoMux(image, pixel, maxpixel, x, y);
	input [3:0] image;
	output reg [5:0] pixel;
	output reg [7:0] x;
	output reg [6:0] y;
	output reg [11:0] maxpixel;

	parameter [3:0] batone = 4'b0000, //0
						 battwo = 4'b0010, //2
						 batthree = 4'b0100; //4
	
	always @ (*)
	begin
	case (image)
		batone:
			begin
			pixel = 6'b110011;
			maxpixel = 12'b101000101000;
			x = 8'b00101110;
			y = 7'b1000101;
			end
		battwo:
			begin
			pixel = 6'b101101;
			maxpixel = 12'b011111101000;
			x = 8'b00101001;
			y = 7'b1001011;
			end
		batthree:
			begin
			pixel = 6'b100101;
			maxpixel = 12'b010101011000;
			x = 8'b00100000;
			y = 7'b1010011;
			end
		default:
			begin
			pixel = 6'b0;
			maxpixel = 12'b0;
			x = 8'b0;
			y = 7'b0;
			end
	 endcase
end
endmodule

//mux that chooses colour to output based on bat number
module BATselectColour(image, bat_out1, bat_out2, bat_out3, bat_colour);
	input[2:0] bat_out1, bat_out2, bat_out3;
	input [3:0] image;
	output reg [2:0] bat_colour;

	parameter [3:0] bat_one = 4'b0000, //0
					 bat_two = 4'b0010, //2
					 bat_three = 4'b0100;
	
	always @ (*)
	begin
	case (image)
		bat_one:
			begin
			bat_colour = bat_out1;
			end
		bat_two:
			begin
			bat_colour = bat_out2;
			end
		bat_three:
			begin
			bat_colour = bat_out3;
			end
		default:
			begin
			bat_colour = 3'b000;
			end
	 endcase
end

endmodule

//counts in a sqaure for printing the bat
module BATXYcounter (resetn, enableCounter, pixel, clock, x, y, done);
	input enableCounter, clock, resetn;
	input [5:0] pixel; //pixel is the width of the bat
	output reg done; //signal that indicates if counter is done
	output reg [5:0] x, y;

	always @ (posedge clock) 
	begin
		if (!resetn || !enableCounter)
			begin
				x <= 0;
				y <= 0;
				done <= 0;
			end
		
		else if (enableCounter)
		begin
			if (y == (pixel - 1) && x == (pixel - 1))
				begin
				x <= 0;
				y <= 0;
				done <= 1;
				end
			else if (x != (pixel - 1))
				begin
					x <= x + 1;
				end
			else if (x == (pixel - 1))
				begin
					y <= y + 1;
					x <= 0;
				end
		end
	end
endmodule

//counter for bat image address
module BATimageCounter(maxpixel, resetn, enable, clock, address);
	input [11:0] maxpixel;
	input clock, enable, resetn;
	output reg [11:0] address;

	always @ (posedge clock) 
	begin
		address <= 0;
		if (!resetn || !enable)
			begin
			address <= 0;
			end
		else if (enable && address > maxpixel) //end of image
			begin
			address <= 0;
			end
		else if (enable)
		begin
			address <= address + 1;
		end
	end
endmodule

////////////////FLYING AWAY BALL MODULES////////////////////////////

//mux that stores the coordinates and size of the five flying away ball images
module FLYinfoMux(image, pixel, maxpixel, x, y);
	input [3:0] image;
	output reg [3:0] pixel;
	output reg [7:0] x;
	output reg [6:0] y;
	output reg [6:0] maxpixel;

	parameter [3:0] flyone = 4'b0000, //0
					flytwo = 4'b0010, //2
					flythree = 4'b0100, //4
					flyfour = 4'b0110, //6
					flyfive = 4'b1000; //8
	
	always @ (*)
	begin
	case (image)
		flyone:
			begin
			pixel = 4'b1011;
			maxpixel = 7'b1111000;
			x = 8'b00101001;
			y = 7'b0111111;
			end
		flytwo:
			begin
			pixel = 4'b1001;
			maxpixel = 7'b1010000;
			x = 8'b00100001;
			y = 7'b0101111;
			end
		flythree:
			begin
			pixel = 4'b0111;
			maxpixel = 7'b0110000;
			x = 8'b00011000;
			y = 7'b0100000;
			end
		flyfour:
		begin
			pixel = 4'b0101;
			maxpixel = 7'b0011000;
			x = 8'b00001101;
			y = 7'b0010000;
		end
		flyfive:
		begin
			pixel = 4'b0011;
			maxpixel = 7'b0001000;
			x = 8'b00000101;
			y = 7'b0001010;
		end
		default:
			begin
			pixel = 6'b0;
			maxpixel = 12'b0;
			x = 8'b0;
			y = 7'b0;
			end
	 endcase
end
endmodule

//mux that selects the colour to output based on the ball number
module FLYselectColour(image, fly_out1, fly_out2, fly_out3, fly_out4, fly_out5, fly_colour);
	input[2:0] fly_out1, fly_out2, fly_out3, fly_out4, fly_out5;
	input [3:0] image;
	output reg [2:0] fly_colour;

	parameter [3:0] fly_one = 4'b0000, //0
					fly_two = 4'b0010, //2
					fly_three = 4'b0100, //4
					fly_four = 4'b0110, //6
					fly_five = 4'b1000; //8
	
	always @ (*)
	begin
	case (image)
		fly_one:
			begin
			fly_colour = fly_out1;
			end
		fly_two:
			begin
			fly_colour = fly_out2;
			end
		fly_three:
			begin
			fly_colour = fly_out3;
			end
		fly_four:
			begin
			fly_colour = fly_out4;
			end
		fly_five:
			begin
			fly_colour = fly_out5;
			end
		default:
			begin
			fly_colour = 3'b000;
			end
	 endcase
end

endmodule

//counts in a square for printing the balls
module FLYXYcounter (resetn, enableCounter, pixel, clock, x, y, done);
	input enableCounter, clock, resetn;
	input [3:0] pixel; //pixel is the width of the ball
	output reg done; //signal that indicates if counter is done
	output reg [3:0] x, y;

	always @ (posedge clock) 
	begin
		if (!resetn || !enableCounter)
			begin
				x <= 0;
				y <= 0;
				done <= 0;
			end
		
		else if (enableCounter)
		begin
			if (y == (pixel - 1) && x == (pixel - 1))
				begin
				x <= 0;
				y <= 0;
				done <= 1;
				end
			else if (x != (pixel - 1))
				begin
					x <= x + 1;
				end
			else if (x == (pixel - 1))
				begin
					y <= y + 1;
					x <= 0;
				end
		end
	end
endmodule

//counter for image address
module FLYimageCounter(maxpixel, resetn, enable, clock, address);
	input [6:0] maxpixel;
	input clock, enable, resetn;
	output reg [6:0] address;

	always @ (posedge clock) 
	begin
		address <= 0;
		if (!resetn || !enable)
			begin
			address <= 0;
			end
		else if (enable && address > maxpixel) //end of image
			begin
			address <= 0;
			end
		else if (enable)
		begin
			address <= address + 1;
		end
	end
endmodule

////////////////SCORE MODULES////////////////////////

//counts the address for the score images
module scoreImageCounter(maxpixel, resetn, enable, clock, address);
	input [4:0] maxpixel;
	input clock, enable, resetn;
	output reg [4:0] address;

	always @ (posedge clock) 
	begin
		address <= 0;
		if (!resetn || !enable)
			begin
			address <= 0;
			end
		else if (enable && address > maxpixel) //end of image
			begin
			address <= 0;
			end
		else if (enable)
		begin
			address <= address + 1;
		end
	end
endmodule

//mux that selects the correct score colour based on the ball number
module scoreSelectColour(ball, score_colour_hit, score_colour_miss, score_colour);
	input [3:0] ball;
	input [2:0] score_colour_hit, score_colour_miss;
	output reg [2:0] score_colour;

parameter [3:0] ball_one = 4'b0000, //0
					 ball_two = 4'b0010, //2
					 ball_three = 4'b0100, //4
					 ball_four = 4'b0110, //6
					 ball_five = 4'b1000, //8
					 ball_six = 4'b1010; //10
	
	//ball one to five all miss, only ball six counts as a hit
	always @ (*)
	begin
	case (ball)
		ball_one:
			begin
			score_colour = score_colour_miss;
			end
		ball_two:
			begin
			score_colour = score_colour_miss;
			end
		ball_three:
			begin
			score_colour = score_colour_miss;
			end
		ball_four:
			begin
			score_colour = score_colour_miss;
			end
		ball_five:
			begin
			score_colour = score_colour_miss;
			end
		ball_six:
			begin
			score_colour = score_colour_hit; 
			end
		default:
			begin
			score_colour = 3'b000;
			end
	 endcase
end

endmodule

//mux that stores the coordinates and size of the ten coordinates of the score board
module scoreInfoMux(game, pixel_score, maxpixel_score, xin_score, yin_score);
	input [3:0] game;
	output reg [7:0] xin_score;
	output reg [6:0] yin_score;
	output reg [4:0] maxpixel_score; //always 24
	output reg [3:0] pixel_score; //always 5

parameter [3:0] gameone = 4'b0001, //1
				gametwo = 4'b0010, //2
				gamethree = 4'b0011, //3
				gamefour = 4'b0100, //4
				gamefive = 4'b0101, //5
				gamesix = 4'b0110, //6
				gameseven = 4'b0111, //7
				gameeight = 4'b01000, //8
				gamenine = 4'b1001, //9
				gameten = 4'b1010; //10

	
	always @ (*)
	begin
	case (game)
		gameone:
			begin
			pixel_score = 4'b0101;
			maxpixel_score = 5'b11000;
			xin_score = 8'b00111110;
			yin_score = 7'b0001100;
			end
		gametwo:
			begin
			pixel_score = 4'b0101;
			maxpixel_score = 5'b11000;
			xin_score = 8'b01000110;
			yin_score = 7'b0001100;
			end
		gamethree:
			begin
			pixel_score = 4'b0101;
			maxpixel_score = 5'b11000;
			xin_score = 8'b01001110;
			yin_score = 7'b0001100;
			end
		gamefour:
			begin
			pixel_score = 4'b0101;
			maxpixel_score = 5'b11000;
			xin_score = 8'b01010110;
			yin_score = 7'b0001100;
			end
		gamefive:
			begin
			pixel_score = 4'b0101;
			maxpixel_score = 5'b11000;
			xin_score = 8'b01011110;
			yin_score = 7'b0001100;
			end
		gamesix:
			begin
			pixel_score = 4'b0101;
			maxpixel_score = 5'b11000;
			xin_score = 8'b00111110;
			yin_score = 7'b0010100;
			end
		gameseven:
			begin
			pixel_score = 4'b0101;
			maxpixel_score = 5'b11000;
			xin_score = 8'b01000110;
			yin_score = 7'b0010100;
			end
		gameeight:
			begin
			pixel_score = 4'b0101;
			maxpixel_score = 5'b11000;
			xin_score = 8'b01001110;
			yin_score = 7'b0010100;
			end
		gamenine:
			begin
			pixel_score = 4'b0101;
			maxpixel_score = 5'b11000;
			xin_score = 8'b01010110;
			yin_score = 7'b0010100;
			end
		gameten:
			begin
			pixel_score = 4'b0101;
			maxpixel_score = 5'b11000;
			xin_score = 8'b01011110;
			yin_score = 7'b0010100;
			end

	endcase
	end
	
endmodule

/////////////////////////BALL SPEED GAME LOGIC/////////////////////////

module ballSpeeds (speedCases, ballSpeed);
	input [1:0] speedCases; //Condition (generated by LFSR) for the different speed cases
	output reg [1:0] ballSpeed;
	//Speeds in mph
	parameter [1:0] SPEED1 = 2'b00, SPEED2 = 2'b01, SPEED3 = 2'b10, SPEED4 = 2'b11;

	//Choosing different travel times
	always @ (*) 
	begin
		case (speedCases)
			2'b00: ballSpeed = SPEED1; 
			2'b01: ballSpeed = SPEED2; 
			2'b10: ballSpeed = SPEED3; 
			2'b11: ballSpeed = SPEED4; 
			default: ballSpeed = SPEED1; 
		endcase
	end
endmodule

module mux4to1 (ballSpeed, out);
	//Choose the max count for the rate divider based on ball speed
	input [1:0] ballSpeed;
	output reg [24:0] out;

	always @(*)
		begin
			case (ballSpeed)
				2'b00: out = 25'b0001111010000100100000000; //0.4s
				2'b01: out = 25'b0011110100001001000000000; //0.8s
				2'b10: out = 25'b0101101110001101100000000; //1.2s
				2'b11: out = 25'b1001100010010110100000000; //1.6s
				default: out = 25'b0;
			endcase
		end
endmodule

//Random number generator for the different speeds
module LFSR (clock, rngOut);
	input clock;
	output reg [7:0] rngOut = 255; //Initial value
	wire feedback = rngOut[7];

	always @(posedge clock)
	begin
		rngOut[0] <= feedback;
		rngOut[1] <= rngOut[0];
		rngOut[2] <= rngOut[1] ^ feedback;
		rngOut[3] <= rngOut[2] ^ feedback;
		rngOut[4] <= rngOut[3] ^ feedback;
		rngOut[5] <= rngOut[4];
		rngOut[6] <= rngOut[5];
		rngOut[7] <= rngOut[6];
	end

endmodule

