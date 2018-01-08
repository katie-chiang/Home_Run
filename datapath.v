
/////////////////////////DATA PATH/////////////////////////

module datapath(resetn, clock, plot, countenable, wait_countenable, update, erase, rate, pause_countenable,
			 done_draw, done_wait, done_update, done_erase, done_pause, got_rate, xvga, yvga, colourvga, ball,
			 	plot_bat, countenable_bat, wait_countenable_bat, update_bat, erase_bat, score, erase_ball, game,
			done_draw_bat, done_wait_bat, done_erase_bat, done_update_bat, batnum, done_score, done_erase_ball, plot_fly,
			countenable_fly, wait_countenable_fly, update_fly, erase_fly, done_draw_fly, done_wait_fly, done_erase_fly, done_update_fly
			,flynum, done_start, done_erase_start, start, erase_start, draw_done, done_draw_done);
	
	input resetn, plot, countenable, wait_countenable, update, erase, rate, pause_countenable;
	input plot_bat, countenable_bat, wait_countenable_bat, update_bat, erase_bat, score, erase_ball;
	input plot_fly, countenable_fly, wait_countenable_fly, update_fly, erase_fly;
	input clock;
	input start, erase_start, draw_done;

	/////////////DRAW/////////////

	output done_draw;
	wire [2:0] colourin;
	wire [3:0] xcount, ycount;
	wire [7:0] xin;
	wire [6:0] yin;

	reg [7:0] xout;
	reg [6:0] yout;
	reg [2:0] colourout;

	wire [3:0] pixel;
	wire [7:0] address_ball;
	wire [7:0] maxpixel;

	wire [2:0] ball_out1, ball_out2, ball_out3, ball_out4, ball_out5, ball_out6, ball_colour;

	//ball one is 5x5
	ball_one b1(address_ball, clock, ball_out1);

	//ball two is 7x7
	ball_two b2(address_ball, clock, ball_out2);

	//ball three is 9x9
	ball_three b3(address_ball, clock, ball_out3);

	//ball four is 11x11
	ball_four b4(address_ball, clock, ball_out4);
	
	//ball five is 13x13
	ball_five b5(address_ball, clock, ball_out5);
	
	//ball six is 15x15
	ball_six b6(address_ball, clock, ball_out6);
	
	XYcounter x(resetn, countenable, pixel, clock, xcount, ycount, done_draw);
	imageCounter i(maxpixel, resetn, countenable, clock, address_ball);
	infoMux m(ball, pixel, maxpixel, xin, yin);
	selectColour s(ball, ball_out1, ball_out2, ball_out3, ball_out4, ball_out5, ball_out6, ball_colour);

	always @ (*) begin
	
		if (!resetn) begin
			xout = 8'b0;
			yout = 7'b0;
			colourout <= 3'b0;
		end 
		else
			if (plot) begin
				xout = xin + xcount;
				yout = yin + ycount;
				colourout = ball_colour;
			end
	end


	/////////////UPDATE/////////////
	
	output reg done_update;
	output reg [3:0] ball;
	always@(posedge clock) begin
		if(!resetn)
			begin
			ball <= 0;
			done_update <= 0;
			end
		else if(update && ball > 4'b1010)	//0~10 only even
			begin
			ball <= 0; //back to ball 0
			done_update <= 1;
			end
		else if(pause_countenable)
			begin
			ball <= 0;
			end
		else if(!update)
			begin
			ball <= ball;
			done_update <= 0;
			end
		else if(update)
			begin
			ball <= ball + 1;
			done_update <= 1;
			end
	end

	/////////////GAME COUNTER/////////////
	output reg [3:0] game; //game goes from 0~10
	always @ (posedge clock)
	begin
		if(!resetn)
			game <= 0;
		else if(batnum > 4'b0100)
			game <= game + 1;
		else if(ball > 4'b1010)
			game <= game + 1;
		else
			game <= game;
	end

	/////////////RATE/////////////
	output reg got_rate;

	wire [1:0] ballSpeed;
	wire [24:0] ratewire;
	wire [7:0] speedCases;

	reg [24:0] rateuse; //rate that is being used
	//put it into wait to use it for intervals of drawing

	always@(*) begin
		if(!resetn)
			begin
			rateuse = 0;
			got_rate = 0;
			end
		else if(!rate)
			begin
			rateuse = rateuse;
			got_rate = 0;
			end
		else if(rate)
			begin
			rateuse = ratewire;
			got_rate = 1;
			end
	end

	LFSR rng (.clock(clock), .rngOut(speedCases));
	ballSpeeds speed (.speedCases(speedCases[1:0]), .ballSpeed(ballSpeed));
	mux4to1 mux (.ballSpeed(ballSpeed), .out(ratewire));

	/////////////WAIT/////////////
	output reg done_wait;

	reg [24:0] counter;

	always @ (posedge clock)
	begin
		if (!resetn)
			begin
			counter <= 25'b0;
			done_wait <= 0;
			end
		else if (wait_countenable && counter == rateuse) //Reset counter
			begin
			counter <= 25'b0;
			done_wait <= 1;
			end
		else if(wait_countenable)
			begin
			counter <= counter + 1;
			done_wait <= 0;
			end
	end


	/////////////ERASE/////////////
	output done_erase;

	wire [3:0] xcount_erase, ycount_erase;
	wire [15:0] back_address;
	wire [2:0] back_colour;

	//counts in a square 
	XYcounter c2(resetn, erase, pixel, clock, xcount_erase , ycount_erase, done_erase);

	//translate xy coordinate into address for field
	address_translator a1(xout_wire, yout_wire, back_address);

	//backgorund memory is stored here
	//160x120
	field background(back_address, clock, back_colour);

	reg [7:0] xout_wire;
	reg [6:0] yout_wire;
	reg [7:0] xout_b;
	reg [6:0] yout_b;
	reg [2:0] colourout_b;

	always @ (*) begin
		if (!resetn) begin
			xout_b = 8'b0;
			yout_b = 7'b0;
			colourout_b = 3'b0;
		end 
		else
			if (erase) begin
				xout_wire = xin + xcount_erase;
				yout_wire = yin + ycount_erase;
				xout_b = xin + xcount_erase;
				yout_b = yin + ycount_erase;
				colourout_b = back_colour;
			end
	end


	/////////////PAUSE/////////////
	output done_pause;
	reg [26:0] counter_pause;
	
	//pause for two seoconds

	always @ (posedge clock)
	begin
		if (!resetn || !pause_countenable)
			begin
			counter_pause <= 26'b0;
			end
		else if (pause_countenable && counter_pause == 27'b101111101011110000100000000)
			begin
			counter_pause <= 26'b0;
			end
		else if(pause_countenable)
			begin
			counter_pause <= counter_pause + 1;
			end
	end

	assign done_pause = (counter_pause == 27'b101111101011110000100000000) ? 1 : 0;
	
	//////////////////////////BAT/////////////////////////////

	/////////////DRAW_BAT/////////////

	output done_draw_bat;
	wire [5:0] xcount_bat, ycount_bat;
	wire [8:0] xin_bat;
	wire [7:0] yin_bat;

	reg [8:0] xout_bat;
	reg [7:0] yout_bat;
	reg [2:0] colourout_bat;

	wire [5:0] pixel_bat;
	wire [11:0] address_bat;
	wire [11:0] maxpixel_bat;

	wire [2:0] bat_out1, bat_out2, bat_out3, bat_colour;

	bat_one bb1(address_bat, clock, bat_out1);

	bat_two bb2(address_bat, clock, bat_out2);

	bat_three bb3(address_bat, clock, bat_out3);
	
	BATXYcounter bx(resetn, countenable_bat, pixel_bat, clock, xcount_bat, ycount_bat, done_draw_bat);
	BATimageCounter bi(maxpixel_bat, resetn, countenable_bat, clock, address_bat);
	BATinfoMux bm(batnum, pixel_bat, maxpixel_bat, xin_bat, yin_bat);
	BATselectColour bs(batnum, bat_out1, bat_out2, bat_out3, bat_colour);

	always @ (*) begin
	
		if (!resetn) begin
			xout_bat = 8'b0;
			yout_bat = 7'b0;
			colourout_bat = 3'b0;
		end 
		else
			if (plot_bat) begin
				xout_bat = xin_bat + xcount_bat;
				yout_bat = yin_bat + ycount_bat;
				colourout_bat = bat_colour;
			end
	end

	/////////////BAT_UPDATE/////////////
	
	output reg done_update_bat;
	output reg [3:0] batnum;
	always@(posedge clock) begin
		batnum <= 0;
		done_update_bat <= 0;
		if(!resetn)
			begin
			batnum <= 0;
			done_update_bat <= 0;
			end
		else if(update_bat && batnum > 4'b0100)	
			begin
			batnum <= 0; 
			done_update_bat <= 1;
			end
		else if(!update_bat)
			begin
			batnum <= batnum;
			done_update_bat <= 0;
			end
		else if(update_bat)
			begin
			batnum <= batnum + 1;
			done_update_bat <= 1;
			end
	end

	/////////////BAT_WAIT/////////////
	output reg done_wait_bat;
	reg [21:0] counter_bat;

	always @ (posedge clock)
	begin
		if (!resetn)
			begin
			counter_bat <= 22'b0;
			done_wait_bat <= 0;
			end
		else if (wait_countenable_bat && counter_bat == 22'b1101010110011111100000) //Reset counter
			begin
			counter_bat <= 22'b0;
			done_wait_bat <= 1;
			end
		else if(wait_countenable_bat)
			begin
			counter_bat <= counter_bat + 1;
			done_wait_bat <= 0;
			end
	end


	/////////////BAT_ERASE/////////////
	output done_erase_bat;

	wire [5:0] xcount_erase_bat, ycount_erase_bat;
	wire [15:0] back_address_bat;
	wire [2:0] back_colour_bat;

	//counts in a square 
	BATXYcounter c3(resetn, erase_bat, pixel_bat, clock, xcount_erase_bat, ycount_erase_bat, done_erase_bat);

	//translate xy coordinate into address for field
	address_translator a3(xout_wire_bat, yout_wire_bat, back_address_bat);

	//backgorund memory is stored here
	//160x120
	field background2(back_address_bat, clock, back_colour_bat);
	

	reg [7:0] xout_wire_bat;
	reg [6:0] yout_wire_bat;
	reg [7:0] xout_b_bat;
	reg [6:0] yout_b_bat;
	reg [2:0] colourout_b_bat;

	always @ (*) begin
		if (!resetn) begin
			xout_b_bat = 8'b0;
			yout_b_bat = 7'b0;
			colourout_b_bat = 3'b0;
		end 
		else
			if (erase_bat) begin
				xout_wire_bat = xin_bat + xcount_erase_bat;
				yout_wire_bat = yin_bat + ycount_erase_bat;
				xout_b_bat = xin_bat + xcount_erase_bat;
				yout_b_bat = yin_bat + ycount_erase_bat;
				colourout_b_bat = back_colour_bat;
			end
	end
	
	/////////////SCORE/////////////

	output done_score;

	wire [4:0] address_score;
	wire [2:0] score_colour_miss, score_colour_hit, score_colour;
	wire [4:0] maxpixel_score;
	wire [3:0] pixel_score;
	wire [3:0] xcount_score, ycount_score;

	wire [7:0] xin_score;
	wire [6:0] yin_score; 

	reg [7:0] xout_score;
	reg [6:0] yout_score;
	reg [2:0] colourout_score;

	//instatiate ROM blocks for score for miss and hit
	score_hit h1(address_score, clock, score_colour_hit);
	score_miss m1(address_score, clock, score_colour_miss);


	XYcounter xcc(resetn, score, pixel_score, clock, xcount_score, ycount_score, done_score);

	scoreImageCounter ia(maxpixel_score, resetn, score, clock, address_score);
	//depends on which game it is to get the x and y coordinates
	scoreInfoMux ms(game, pixel_score, maxpixel_score, xin_score, yin_score);

	//depends on the ball number to decide if it misses or hits
	scoreSelectColour scc(ball, score_colour_hit, score_colour_miss, score_colour);


	always @ (*) begin
	
		if (!resetn) begin
			xout_score = 8'b0;
			yout_score = 7'b0;
			colourout_score = 3'b0;
		end 
		else
			if (score) begin
				xout_score = xin_score + xcount_score;
				yout_score = yin_score + ycount_score;
				colourout_score = score_colour;
			end
	end

	/////////////ERASE BALL/////////////
 	output done_erase_ball;

	wire [3:0] xcount_erase_ball, ycount_erase_ball;
	wire [15:0] back_address_ball;
	wire [2:0] back_colour_ball;

	//counts in a square 
	XYcounter cc2(resetn, erase_ball, pixel, clock, xcount_erase_ball , ycount_erase_ball, done_erase_ball);

	//translate xy coordinate into address for field
	address_translator aa1(xout_wire_ball, yout_wire_ball, back_address_ball);

	//backgorund memory is stored here
	//160x120
	field backgrounddd(back_address_ball, clock, back_colour_ball);

	reg [7:0] xout_wire_ball;
	reg [6:0] yout_wire_ball;
	reg [7:0] xout_b_ball;
	reg [6:0] yout_b_ball;
	reg [2:0] colourout_b_ball;

	always @ (*) begin
		if (!resetn) begin
			xout_b_ball = 8'b0;
			yout_b_ball = 7'b0;
			colourout_b_ball = 3'b0;
		end 
		else
			if (erase_ball) begin
				xout_wire_ball = xin + xcount_erase_ball;
				yout_wire_ball = yin + ycount_erase_ball;
				xout_b_ball = xin + xcount_erase_ball;
				yout_b_ball = yin + ycount_erase_ball;
				colourout_b_ball = back_colour_ball;
			end
	end

	////////////////////////FLYING BALL/////////////////////////////

	/////////////DRAW_FLY///////////
	output done_draw_fly;
	wire [3:0] xcount_fly, ycount_fly;
	wire [8:0] xin_fly;
	wire [7:0] yin_fly;

	reg [8:0] xout_fly;
	reg [7:0] yout_fly;
	reg [2:0] colourout_fly;

	wire [3:0] pixel_fly;
	wire [6:0] address_fly;
	wire [6:0] maxpixel_fly;

	wire [2:0] fly_out1, fly_out2, fly_out3, fly_out4, fly_out5, fly_colour;

	fly_one f1(address_fly, clock, fly_out1);
	fly_two f2(address_fly, clock, fly_out2);
	fly_three f3(address_fly, clock, fly_out3);
	fly_four f4(address_fly, clock, fly_out4);
	fly_five f5(address_fly, clock, fly_out5);
	
	XYcounter bxf(resetn, countenable_fly, pixel_fly, clock, xcount_fly, ycount_fly, done_draw_fly);
	imageCounter bif(maxpixel_fly, resetn, countenable_fly, clock, address_fly);
	FLYinfoMux bmf(flynum, pixel_fly, maxpixel_fly, xin_fly, yin_fly);
	FLYselectColour bsf(flynum, fly_out1, fly_out2, fly_out3, fly_out4, fly_out5, fly_colour);

	always @ (*) begin
	
		if (!resetn) begin
			xout_fly <= 8'b0;
			yout_fly <= 7'b0;
			colourout_fly <= 3'b0;
		end 
		else
			if (plot_fly) begin
				xout_fly <= xin_fly + xcount_fly;
				yout_fly <= yin_fly + ycount_fly;
				colourout_fly <= fly_colour;
			end
	end

	/////////////UPDATE FLY/////////////
	
	output reg done_update_fly;
	output reg [3:0] flynum;
	always@(posedge clock) begin
		flynum <= 0;
		done_update_fly <= 0;
		if(!resetn)
			begin
			flynum <= 0;
			done_update_fly <= 0;
			end
		else if(update_fly && flynum > 4'b1000)
			begin
			flynum <= 0; 
			done_update_fly <= 1;
			end
		else if(!update_fly)
			begin
			flynum <= flynum;
			done_update_fly <= 0;
			end
		else if(update_fly)
			begin
			flynum <= flynum + 1;
			done_update_fly <= 1;
			end
	end

	/////////////WAIT FLY/////////////
	output reg done_wait_fly;
	reg [23:0] counter_fly;

	always @ (posedge clock)
	begin
		if (!resetn)
			begin
			counter_fly <= 24'b0;
			done_wait_fly <= 0;
			end
		else if (wait_countenable_fly && counter_fly == 24'b111001001110000111000000) //Reset counter
			begin
			counter_fly <= 24'b0;
			done_wait_fly <= 1;
			end
		else if(wait_countenable_fly)
			begin
			counter_fly <= counter_fly + 1;
			done_wait_fly <= 0;
			end
	end


	/////////////ERASE FLY/////////////
	output done_erase_fly;

	wire [3:0] xcount_erase_fly, ycount_erase_fly;
	wire [15:0] back_address_fly;
	wire [2:0] back_colour_fly;

	//counts in a square 
	XYcounter c2f(resetn, erase_fly, pixel, clock, xcount_erase_fly , ycount_erase_fly, done_erase_fly);

	//translate xy coordinate into address for field
	address_translator a1f(xout_wire_fly, yout_wire_fly, back_address_fly);

	//backgorund memory is stored here
	//160x120
	field background2f(back_address_fly, clock, back_colour_fly);
	

	reg [7:0] xout_wire_fly;
	reg [6:0] yout_wire_fly;
	reg [7:0] xout_b_fly;
	reg [6:0] yout_b_fly;
	reg [2:0] colourout_b_fly;

	always @ (*) begin
		if (!resetn) begin
			xout_b_fly <= 8'b0;
			yout_b_fly <= 7'b0;
			colourout_b_fly <= 3'b0;
		end 
		else
			if (erase_fly) begin
				xout_wire_fly <= xin_fly + xcount_erase_fly;
				yout_wire_fly <= yin_fly + ycount_erase_fly;
				xout_b_fly <= xin_fly + xcount_erase_fly;
				yout_b_fly <= yin_fly + ycount_erase_fly;
				colourout_b_fly <= back_colour_fly;
			end
	end

	////////////////START///////////////////

	output done_start;


	reg [7:0] xout_start;
	reg [6:0] yout_start;
	reg [2:0] colourout_start;

	wire [7:0] xin_start;
	wire [6:0] yin_start;
	wire [2:0] start_colour;
	wire [15:0] address_start;

	wire [7:0] width_screen;
	wire [6:0] height_screen;

	assign width_screen = 8'b10100000; //160
	assign height_screen = 7'b1111000;  //120

	//gets the x and y coordinates (counts in a rectangle)
	rectangleCounter rc1(resetn, start, width_screen, height_screen, clock, xin_start, yin_start, done_start);

	//put the xy coordinates in to get the address
	address_translator aa2(xin_start, yin_start, address_start);

	//put address into ROM block to get the colour of the start screen
	start sss(address_start, clock, start_colour);
		

	always @ (*) begin
	
		if (!resetn) begin
			xout_start = 8'b0;
			yout_start = 7'b0;
			colourout_start = 3'b0;
		end 
		else
			if (start) begin
				xout_start = xin_start;
				yout_start = yin_start;
				colourout_start = start_colour;
			end
	end

	///////////////ERASE START//////////////

	output done_erase_start;

	reg [7:0] xout_start_erase;
	reg [6:0] yout_start_erase;
	reg [2:0] colourout_start_erase;

	wire [7:0] xin_start_erase;
	wire [6:0] yin_start_erase;
	wire [2:0] erase_start_colour;
	wire [15:0] address_start_erase;

	//gets the x and y coordinates (counts in a rectangle)
	rectangleCounter rc2(resetn, erase_start, width_screen, height_screen, clock, xin_start_erase, yin_start_erase, done_erase_start);

	//put the xy coordinates in to get the address
	address_translator aa3(xin_start_erase, yin_start_erase, address_start_erase);

	//put address into ROM block to get the colour
	field background4(address_start_erase, clock, erase_start_colour);
		

	always @ (*) begin
	
		if (!resetn) begin
			xout_start_erase = 8'b0;
			yout_start_erase = 7'b0;
			colourout_start_erase = 3'b0;
		end 
		else
			if (erase_start) begin
				xout_start_erase = xin_start_erase;
				yout_start_erase = yin_start_erase;
				colourout_start_erase = erase_start_colour;
			end
	end

	///////////////DONE//////////////

	output done_draw_done;

	reg [7:0] xout_done;
	reg [6:0] yout_done;
	reg [2:0] colourout_done;

	wire [7:0] xin_done;
	wire [6:0] yin_done;
	wire [2:0] done_colour;
	wire [15:0] address_done;

	//gets the x and y coordinates (counts in a rectangle)
	rectangleCounter rc5(resetn, draw_done, width_screen, height_screen, clock, xin_done, yin_done, done_draw_done);

	//put the xy coordinates in to get the address
	address_translator aa5(xin_done, yin_done, address_done);

	//put address into ROM block to get the colour
	done ssss(address_done, clock, done_colour);
		

	always @ (*) begin
	
		if (!resetn) begin
			xout_done = 8'b0;
			yout_done = 7'b0;
			colourout_done = 3'b0;
		end 
		else
			if (draw_done) begin
				xout_done = xin_done;
				yout_done = yin_done;
				colourout_done = done_colour;
			end
	end



	/////////////////////////OUTPUT MUX/////////////////////////////

	//mux to decide what colour and xy to output
	//depending on which state it is in

	reg [7:0] xvga_d;
	reg [6:0] yvga_d;
	output reg [2:0] colourvga;
	
	always @ (*)
	begin
	if(!resetn)
		begin
		xvga_d = 0;
		yvga_d = 0;
		colourvga = 0;
		end
	else if(plot)
		begin
		xvga_d = xout;
		yvga_d = yout;
		colourvga = colourout;
		end
	else if(erase)
		begin
		xvga_d = xout_b;
		yvga_d = yout_b;
		colourvga = colourout_b;
		end
	else if(plot_bat)
		begin
		xvga_d = xout_bat;
		yvga_d = yout_bat;
		colourvga = colourout_bat;
		end
	else if(erase_bat)
		begin
		xvga_d = xout_b_bat;
		yvga_d = yout_b_bat;
		colourvga = colourout_b_bat;
		end
	else if(score)
		begin
		xvga_d = xout_score;
		yvga_d = yout_score;
		colourvga = colourout_score;
		end
	else if(erase_ball)
		begin
		xvga_d = xout_b_ball;
		yvga_d = yout_b_ball;
		colourvga = colourout_b_ball;
		end
	else if (plot_fly)
		begin
		xvga_d = xout_fly;
		yvga_d = yout_fly;
		colourvga = colourout_fly;
		end
	else if (erase_fly)
		begin
		xvga_d = xout_b_fly;
		yvga_d = yout_b_fly;
		colourvga = colourout_b_fly;
		end
	else if(start)
		begin
		xvga_d = xout_start;
		yvga_d = yout_start;
		colourvga = colourout_start;
		end
	else if(erase_start)
		begin
		xvga_d = xout_start_erase;
		yvga_d = yout_start_erase;
		colourvga = colourout_start_erase;
		end
	else if(draw_done)
		begin
			xvga_d = xout_done;
			yvga_d = yout_done;
			colourvga = colourout_done;
		end
	end
	
	//delay x and y coordinates by two clock edges

	reg [7:0] xvga_dd;
	reg [6:0] yvga_dd;
	
	always @ (posedge clock)
	begin
		xvga_dd <= xvga_d;
		yvga_dd <= yvga_d;	
	
	end
	
	output reg [7:0] xvga;
	output reg [6:0] yvga;
	
	always @ (posedge clock)
	begin
		xvga <= xvga_dd;
		yvga <= yvga_dd;	
	
	end



endmodule

