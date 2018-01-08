
/////////////////////////CONTROL PATH/////////////////////////


module controlpath(resetn, clock, done_draw, done_wait, done_update, done_erase, got_rate, done_pause, ball, user, done_bat,//inputs
					plot, countenable, wait_countenable, update, erase, rate, pause_countenable,
					plot_bat, countenable_bat, wait_countenable_bat, update_bat, erase_bat, score, erase_ball, game,
					done_draw_bat, done_wait_bat, done_erase_bat, done_update_bat, batnum, done_score, done_erase_ball, plot_fly, countenable_fly,
					wait_countenable_fly, update_fly, erase_fly, done_draw_fly, done_wait_fly, done_erase_fly, done_update_fly, flynum,
					done_start, done_erase_start, start, erase_start, draw_done, done_draw_done); //outputs

	input [3:0] ball; //the ball number
	input [3:0] batnum; //the bat number
	input [3:0] flynum; //the flying ball number
	input [3:0] game; //the game number

	input resetn, clock, done_draw, done_wait, done_update, done_erase, got_rate, done_pause, done_bat, done_score;
	input user; //user input signal
	input done_draw_bat, done_wait_bat, done_erase_bat, done_update_bat, done_erase_ball;
	input done_draw_fly, done_wait_fly, done_erase_fly, done_update_fly;
	input done_start, done_erase_start, done_draw_done;
	output reg start, erase_start, draw_done;
	output reg plot, countenable, wait_countenable, update, erase, rate, pause_countenable, score;
	output reg plot_bat, countenable_bat, wait_countenable_bat, update_bat, erase_bat, erase_ball;
	output reg plot_fly, countenable_fly, wait_countenable_fly, update_fly, erase_fly;
	
	reg [4:0] current, next;
	
	localparam START = 5'b00000,
			   PAUSE = 5'b10001,
			   RATE = 5'b00001,
			   DRAW = 5'b00010,
			   WAIT = 5'b00011,
			   ERASE = 5'b00100,
			   UPDATE = 5'b00101,
			   SCORE = 5'b00110, 
			   BAT_DRAW = 5'b00111,
			   BAT_WAIT = 5'b01000,
			   BAT_ERASE = 5'b01001,
			   BAT_UPDATE = 5'b01010,
			   ERASE_BALL = 5'b01011,
			   FLY_DRAW = 5'b01100,
			   FLY_WAIT = 5'b01101,
			   FLY_ERASE = 5'b01110,
			   FLY_UPDATE = 5'b01111,
			   DONE = 5'b10000,
			   ERASE_START = 5'b10010;
			
	
		// State Table
	always@(*) begin
		case (current)
			
			//print the start screen
			START: next = (done_start && user) ? ERASE_START : START; 
			
			//draw over start screen to background
			ERASE_START: next = (done_erase_start) ? PAUSE : ERASE_START;

			//pause for two seconds before start
			PAUSE: next = (done_pause) ? RATE : PAUSE;

			//get rate for ball
			RATE: next = (got_rate) ? DRAW : RATE;

			//draw ball
			DRAW: 	
			begin
			if(done_draw)
				next = WAIT;
			else if(!done_draw)
				next = DRAW;
			end

			//wait for a certain rate
			WAIT: //only allow user input during wait
			begin
			if(user)
				next = BAT_DRAW;
			else if(done_wait)
				next = ERASE;
			else if(!done_wait)
				next = WAIT;			
			end

			//erase ball
			ERASE:
			begin
			if(done_erase)
				next = UPDATE;
			else if(!done_erase)
				next = ERASE;			
			end

			//update the ball number and coordinate to draw next ball
			UPDATE:
			begin
			if(done_update && ball > 4'b1010) //at last ball so go to score
				next = SCORE;
			else if(done_update && ball < 4'b1010) //not done cycle so directly draw with same rate
				next = DRAW;
			else
				next = UPDATE; //not done update so stay at same state
			end

			//same logic as ball
			BAT_DRAW:
			begin
			if(done_draw_bat)
				next = BAT_WAIT;
			else if(!done_draw_bat)
				next = BAT_DRAW;
			end
			
			BAT_WAIT:
			begin
			if(done_wait_bat)
				next = BAT_ERASE;
			else if(!done_wait_bat)
				next = BAT_WAIT;
			end

			BAT_ERASE:
			begin
			if(done_erase_bat)
				next = BAT_UPDATE;
			else if(!done_erase_bat)
				next = BAT_ERASE;
			end

			BAT_UPDATE: 
			begin
			if(done_update_bat && !(batnum < 4'b0100)) //reached the third bat
				begin
				next = ERASE_BALL;
				end
			else if(done_update_bat && batnum < 4'b0100) //not done cycle so keep drawing bat
				begin
				next = BAT_DRAW;
				end
			else if(!done_update_bat)
				next = BAT_UPDATE; //not done update so stay at same state
			end
			
			//update and draw the score
			SCORE:
			begin
			if(done_score && game < 4'b1010 && ball == 4'b1010) //Home run, go to ball flying away
				next = FLY_DRAW;
			else if (done_score && game < 4'b1010 && ball < 4'b1010)
				next = PAUSE; //Missed, go to next game
			else if(done_score && !(game < 4'b1010))
				next = DONE;	//at game 10 so go to end screen
			else if(!done_score)
				next = SCORE;
			end
			
			//erase the left over ball
			ERASE_BALL: 	
			begin
			if(done_erase_ball)
				next = SCORE;
			else if(!done_erase_ball)
				next = ERASE_BALL;
			end

			//same logic as ball
			FLY_DRAW: //Draw the flying away ball
			begin
				if (done_draw_fly)
					next = FLY_WAIT;
				else if (!done_draw_fly)
					next = FLY_DRAW;	
			end

			FLY_WAIT: //Wait time between drawing balls
			begin
				if (done_wait_fly)
					next = FLY_ERASE;
				else if (!done_wait_fly) 
					next = FLY_WAIT;
			end

			FLY_ERASE: //erase flying balls
			begin
				if(done_erase_fly)
					next = FLY_UPDATE;
				else if(!done_erase_fly)
					next = FLY_ERASE;
			end

			FLY_UPDATE: 
			begin
				if(done_update_fly && !(flynum < 4'b1000)) //reached the fifth flying ball
					begin
					next = PAUSE; //Back to next throw
					end
				else if(done_update_fly && flynum < 4'b1000) //not done cycle so keep drawing flying ball
					begin
					next = FLY_DRAW;
					end
				else if(!done_update_fly)
					next = FLY_UPDATE; //not done update so stay at same state
			end

			//done game so draw end screen
			DONE:
			begin
				if(done_draw_done && user) //restart the game
					next = PAUSE;
				else if(done_draw_done)
					next = DONE;
				else if(!done_draw_done)
					next  = DONE;
			end

			default: next = START;

		endcase
	end
	
	always@(*) begin
		// Setting all signals to 0 at first
		plot = 1'b0;
		countenable = 1'b0;
		wait_countenable = 1'b0;
		update = 1'b0;
		erase = 1'b0;
		pause_countenable = 1'b0;
		rate = 1'b0;
		plot_bat = 1'b0;
		countenable_bat = 1'b0;
		wait_countenable_bat = 1'b0;
		update_bat = 1'b0;
		erase_bat = 1'b0;
		score = 1'b0;
		erase_ball = 1'b0;
		plot_fly = 1'b0;
		countenable_fly = 1'b0;
		wait_countenable_fly = 1'b0;
		update_fly = 1'b0;
		erase_fly = 1'b0;
		start = 1'b0;
		erase_start = 1'b0;
		draw_done = 1'b0;
		

		case (current)
			START: begin
				start = 1'b1;
			end
			ERASE_START: begin
				erase_start = 1'b1;
			end
			PAUSE: begin
				pause_countenable = 1'b1;
			end
			RATE: begin
				rate = 1'b1;
			end
			DRAW: begin
				plot = 1'b1;
				countenable = 1'b1;
			end
			WAIT: begin
				wait_countenable = 1'b1;
			end
			ERASE: begin
				erase = 1'b1;
			end
			UPDATE: begin
				update = 1'b1;
			end
			BAT_DRAW: begin
				plot_bat = 1'b1;
				countenable_bat = 1'b1;
			end
			BAT_WAIT: begin
				wait_countenable_bat = 1'b1;
			end
			BAT_ERASE: begin
				erase_bat = 1'b1;
			end
			BAT_UPDATE: begin
				update_bat = 1'b1;
			end
			SCORE: begin
				score = 1'b1;
			end
			ERASE_BALL: begin
				erase_ball = 1'b1;
			end
			FLY_DRAW: begin
				plot_fly = 1'b1;
				countenable_fly = 1'b1;
			end
			FLY_WAIT: begin
				wait_countenable_fly = 1'b1;
			end
			FLY_ERASE: begin
				erase_fly = 1'b1;
			end
			FLY_UPDATE: begin
				update_fly = 1'b1;
			end
			DONE: begin
				draw_done = 1'b1;
			end
			default: begin
		draw_done = 1'b0;
		plot = 1'b0;
		countenable = 1'b0;
		wait_countenable = 1'b0;
		update = 1'b0;
		erase = 1'b0;
		pause_countenable = 1'b0;
		rate = 1'b0;
		plot_bat = 1'b0;
		countenable_bat = 1'b0;
		wait_countenable_bat = 1'b0;
		update_bat = 1'b0;
		erase_bat = 1'b0;
		score = 1'b0;
		erase_ball = 1'b0;
		plot_fly = 1'b0;
		countenable_fly = 1'b0;
		wait_countenable_fly = 1'b0;
		update_fly = 1'b0;
		erase_fly = 1'b0;
		start = 1'b0;
		erase_start = 1'b0;

			end
		endcase
	end

	always@(posedge clock) begin
		if (!resetn)
			current <= START;
		else
			current <= next;
	end
endmodule
