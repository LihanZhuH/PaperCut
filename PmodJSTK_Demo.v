`timescale 1ns / 1ps
// Project Name: Splatoon
// Team members: Lihan Zhu, Haoqin Deng
// Email: lihanzhu@usc.edu, haoqinde@usc.edu
// Acknowledgement: we used PmodJSTK module provided by Xilinx and VGA module provided by Professor Puvvada.


// ============================================================================== 
// 										  Define Module
// ==============================================================================
module PmodJSTK_Demo(
    CLK,
    RST,
    MISO,
	SW,
    SS,
    MOSI,
    SCLK,
    LED,
	AN,
	SEG,
	MISO_D,
	SS_D,
	MOSI_D,
	SCLK_D,
	vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b, btnL, btnR, 
	St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar
    );

	// ===========================================================================
	// 										Port Declarations
	// ===========================================================================
			input CLK;					// 100Mhz onboard clock
			input RST;					// Button D
			input MISO;					// Master In Slave Out, Pin 3, Port JA
			input [7:0] SW;			// Switches 2, 1, and 0
			output SS;					// Slave Select, Pin 1, Port JA
			output MOSI;				// Master Out Slave In, Pin 2, Port JA
			output SCLK;				// Serial Clock, Pin 4, Port JA
			output [2:0] LED;			// LEDs 2, 1, and 0
			output [3:0] AN;			// Anodes for Seven Segment Display
			output [6:0] SEG;			// Cathodes for Seven Segment Display

	// newly declared variables for JD
			input MISO_D;
			output SS_D;
			output MOSI_D;
			output SCLK_D;
	// newly declared variables for VGA
			input btnL, btnR; // SW0 DELETED HERE
			output St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar;
			output vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b;
			reg vga_r, vga_g, vga_b;
	// ===========================================================================
	// 							  Parameters, Regsiters, and Wires
	// ===========================================================================
			wire SS;						// Active low
			wire MOSI;					// Data transfer from master to slave
			wire SCLK;					// Serial clock that controls communication
			reg [2:0] LED;				// Status of PmodJSTK buttons displayed on LEDs
			wire [3:0] AN;				// Anodes for Seven Segment Display
			wire [6:0] SEG;			// Cathodes for Seven Segment Display

			// Holds data to be sent to PmodJSTK
			wire [7:0] sndData;

			// Signal to send/receive data to/from PmodJSTK
			wire sndRec;

			// Data read from PmodJSTK
			wire [39:0] jstkData;

			// Signal carrying output data that user selected
			wire [9:0] posData;

	// newly declared variables for JD
			wire SS_D;
			wire MOSI_D;
			wire SCLK_D;
			reg [2:0] LED_d;				// Status of PmodJSTK buttons displayed on LEDs

			// Holds data to be sent to PmodJSTK
			wire [7:0] sndData_D;

			// Signal to send/receive data to/from PmodJSTK
			wire sndRec_D;

			// Data read from PmodJSTK
			wire [39:0] jstkData_D;

			wire [9:0] dirA;
			wire [9:0] dirD;
			wire [9:0] tempA;
			wire [9:0] tempD;

	// ===========================================================================
	// 										Implementation
	// ===========================================================================


			//-----------------------------------------------
			//  	  			PmodJSTK Interface
			//-----------------------------------------------
			PmodJSTK PmodJSTK_Int(
					.CLK(CLK),
					.RST(RST),
					.sndRec(sndRec),
					.DIN(sndData),
					.MISO(MISO),
					.SS(SS),
					.SCLK(SCLK),
					.MOSI(MOSI),
					.DOUT(jstkData)
			);

			// REVISION OF ABOVE
			PmodJSTK PmodJSTK_Int2(
					.CLK(CLK),
					.RST(RST),
					.sndRec(sndRec_D),
					.DIN(sndData_D),
					.MISO(MISO_D),
					.SS(SS_D),
					.SCLK(SCLK_D),
					.MOSI(MOSI_D),
					.DOUT(jstkData_D)
			);


			//-----------------------------------------------
			//  		Seven Segment Display Controller
			//-----------------------------------------------
			ssdCtrl DispCtrl(
					.CLK(CLK),
					.RST(RST),
					.DIN(posData),
					.AN(AN),
					.SEG(SEG)
			);

			//-----------------------------------------------
			//  			 Send Receive Generator
			//-----------------------------------------------
			ClkDiv_5Hz genSndRec(
					.CLK(CLK),
					.RST(RST),
					.CLKOUT(sndRec)
			);

			// COPY OF ABOVE
			ClkDiv_5Hz genSndRec2(
					.CLK(CLK),
					.RST(RST),
					.CLKOUT(sndRec_D)
			);

			//................................................. VGA block
			//.................................................
			// .................................................
			// Use state of switch 0 to select output of X position or Y position data to SSD
			assign tempA = (SW[0] == 1'b1) ? {jstkData[9:8], jstkData[23:16]} : {jstkData[25:24], jstkData[39:32]};

			localparam
				// DIRECTIONS
				STILL = 3'b000,
				LEFT = 3'b001,
				RIGHT = 3'b010,
				UP = 3'b011,
				DOWN = 3'b100,
				LOWTH = 350,
				UPTH = 650;


			// for player 1 .................................
			wire [2:0] dir;

			wire [9: 0] tempLR;
			assign tempLR = {jstkData_D[25:24], jstkData_D[39:32]};
			
			wire [9: 0] tempUD;
			assign tempUD = {jstkData_D[9:8], jstkData_D[23:16]};

			wire [9:0] distLR;
			wire [9:0] distUP;
			assign distLR = (tempLR > 500) ? tempLR - 500 : 500 - tempLR;
			assign distUP = (tempUD > 500) ? tempUD - 500 : 500 - tempUD;

			assign dir = 	(distLR < 100 && distUP < 100) ? STILL :
							(distLR > distUP && tempLR >= UPTH) ? RIGHT :
							(distLR > distUP && tempLR <= LOWTH) ? LEFT :
							(distLR < distUP && tempUD >= UPTH) ? UP : DOWN;

			wire shoot1, shoot2;
			assign shoot2 = jstkData[1];
			assign shoot1 = jstkData_D[1];

			// for player 2 .................................
			wire [2:0] dir2;

			wire [9: 0] tempLR2;
			assign tempLR2 = {jstkData[25:24], jstkData[39:32]};
			
			wire [9: 0] tempUD2;
			assign tempUD2 = {jstkData[9:8], jstkData[23:16]};

			wire [9:0] distLR2;
			wire [9:0] distUP2;
			assign distLR2 = (tempLR2 > 500) ? tempLR2 - 500 : 500 - tempLR2;
			assign distUP2 = (tempUD2 > 500) ? tempUD2 - 500 : 500 - tempUD2;

			assign dir2 = 	(distLR2 < 100 && distUP2 < 100) ? STILL :
							(distLR2 > distUP2 && tempLR2 >= UPTH) ? RIGHT :
							(distLR2 > distUP2 && tempLR2 <= LOWTH) ? LEFT :
							(distLR2 < distUP2 && tempUD2 >= UPTH) ? UP : DOWN;

			

		// ..............................................
					
			wire reset, clk, board_clk;
			BUF BUF2 (reset, SW[7]);
			BUF BUF1 (board_clk, CLK); 	
			
			reg [27:0]	DIV_CLK;
			always @ (posedge board_clk, posedge reset)  
			begin : CLOCK_DIVIDER
				if (reset)
						DIV_CLK <= 0;
				else
					DIV_CLK <= DIV_CLK + 1'b1;
			end	

			assign	clk = DIV_CLK[1];
			assign 	{St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar} = {5'b11111};
		
			wire inDisplayArea;
			wire [9:0] CounterX;
			wire [9:0] CounterY;
			hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));

			reg [9:0] positionY;
			reg [9:0] positionX;
			reg [9:0] positionY2;
			reg [9:0] positionX2;

			reg [2:0] shootDir1;
			reg [2:0] shootDir2;

			initial begin
				shootDir1 = RIGHT;
				shootDir2 = LEFT;
			end

			localparam
				QEMPTY = 3'b000,
				QRED_FILL = 3'b001,
				QRED_PATH = 3'b010,
				QGREEN_FILL = 3'b011,
				QGREEN_PATH = 3'b100;


		// COLOR BEGIN _______________________________________________________
		// .............................................................
		// _____________________________________________________________			
			localparam
				CEMPTY = 2'b00,
				CRED = 2'b01,
				CGREEN = 2'b10,
				CBLUE = 2'b11;

			wire [1:0] colorState1;
			assign colorState1 = 	SW[0] && SW[1] ? CBLUE :
									~SW[0] && SW[1] ? CRED :
									SW[0] && ~SW[1] ? CGREEN : CEMPTY;

			wire[1:0] colorState2;
			assign colorState2 =	SW[2] && SW[3] ? CBLUE :
									~SW[2] && SW[3] ? CRED :
									SW[2] && ~SW[3] ? CGREEN : CEMPTY;
		// COLOR END_______________________________________________________
		// .............................................................
		// _____________________________________________________________


			integer k;
			integer q;
			reg [1:0] board [0:10] [0:10]; // 10 * 10
			initial begin
				for (k = 0; k <= 10; k = k + 1)
					for (q = 0; q <= 10; q = q + 1)
						board[k][q] = CEMPTY;
			end

			localparam
				GINIT = 2'b00,
				GPLAY = 2'b01,
				GEND = 2'b10;

			reg [1:0] gameState;
			initial begin
				gameState = GINIT;
			end
			// clock counter
			reg [9:0] counter;
			initial begin 
				counter = 60;
			end

			/* State transition */
			always @(posedge DIV_CLK[25]) begin
				if (gameState == GPLAY) begin
					if (counter > 0) begin
						counter <= counter - 1;
					end
				end
				
			end
			
			assign posData = counter; 
			integer i, j;
			reg[9:0] count1, count2;
			reg [1:0] winner;
			initial begin 
				winner = 2'b00;
				count1 = 0;
				count2 = 0;
			end

			always @(posedge DIV_CLK[21]) begin
				if (reset) begin
					gameState <= GINIT;
				end
				else if (gameState == GINIT) begin
					positionX <= 40;
					positionY <= 40;
					positionX2 <= 70;
					positionY2 <= 70;
					board[{5'b00000, positionX[9:5]}][{ 5'b00000, positionY[9:5]}] = colorState1;
					board[{5'b00000, positionX2[9:5]}][{ 5'b00000, positionY2[9:5]}] = colorState2;

					if (jstkData_D[2] && jstkData[2] && colorState1 != CEMPTY && colorState2 != CEMPTY && colorState1 != colorState2) begin
						gameState <= GPLAY;
					end
				end
				else if (gameState == GPLAY) begin

					// game ends
					if (counter == 0) begin
						gameState <= GEND;
					end

					// player1 moves
					if (dir == UP)
						positionY <= positionY - 2;
					else if (dir == DOWN)
						positionY <= positionY + 2;
					else if (dir == LEFT)
						positionX <= positionX - 2;
					else if (dir == RIGHT)
						positionX <= positionX + 2;	

					// Counts area
					if (dir != STILL) begin
						if (board[{5'b00000, positionX[9:5]}][{ 5'b00000, positionY[9:5]}] == CEMPTY) begin
							count1 <= count1 + 1;
						end
						else if (board[{5'b00000, positionX[9:5]}][{ 5'b00000, positionY[9:5]}] == colorState2) begin
							count1 <= count1 + 1;
							count2 <= count2 - 1;
						end
					end

					if (dir2 != STILL) begin
						if (board[{5'b00000, positionX2[9:5]}][{ 5'b00000, positionY2[9:5]}] == CEMPTY) begin
							count2 <= count2 + 1;
						end
						else if (board[{5'b00000, positionX2[9:5]}][{ 5'b00000, positionY2[9:5]}] == colorState1) begin
							count2 <= count2 + 1;
							count1 <= count1 - 1;
						end
					end

					// player2 moves
					if (dir2 == UP)
						positionY2 <= positionY2 - 2;
					else if (dir2 == DOWN)
						positionY2 <= positionY2 + 2;
					else if (dir2 == LEFT)
						positionX2 <= positionX2 - 2;
					else if (dir2 == RIGHT)
						positionX2 <= positionX2 + 2;	

					// Stores previous direction
					shootDir1 = (dir != STILL) ? dir : shootDir1;
					shootDir2 = (dir2 != STILL) ? dir2 : shootDir2;

					// Player 1 shoots
					if (shoot1) begin
						case (shootDir1)
							UP: begin
								board[{5'b00000, positionX[9:5]}][{ 5'b00000, positionY[9:5]} - 2] <= colorState1;

								if (board[{5'b00000, positionX[9:5]}][{ 5'b00000, positionY[9:5]} - 2] == CEMPTY) begin
									count1 <= count1 + 1;
								end
								else if (board[{5'b00000, positionX[9:5]}][{ 5'b00000, positionY[9:5]} - 2] == colorState2) begin
									count1 <= count1 + 1;
									count2 <= count2 - 1;
								end 

							end
							DOWN: begin
								board[{5'b00000, positionX[9:5]}][{ 5'b00000, positionY[9:5]} + 2] <= colorState1;

								if (board[{5'b00000, positionX[9:5]}][{ 5'b00000, positionY[9:5]} + 2] == CEMPTY) begin
									count1 <= count1 + 1;
								end
								else if (board[{5'b00000, positionX[9:5]}][{ 5'b00000, positionY[9:5]} + 2] == colorState2) begin
									count1 <= count1 + 1;
									count2 <= count2 - 1;
								end 
							end
							LEFT: begin
								board[{5'b00000, positionX[9:5]} - 2][{ 5'b00000, positionY[9:5]}] <= colorState1;

								if (board[{5'b00000, positionX[9:5]} - 2][{ 5'b00000, positionY[9:5]}] == CEMPTY) begin
									count1 <= count1 + 1;
								end
								else if (board[{5'b00000, positionX[9:5]} - 2][{ 5'b00000, positionY[9:5]}] == colorState2) begin
									count1 <= count1 + 1;
									count2 <= count2 - 1;
								end 
							end
							RIGHT: begin
								board[{5'b00000, positionX[9:5]} + 2][{ 5'b00000, positionY[9:5]}] <= colorState1;

								if (board[{5'b00000, positionX[9:5]} + 2][{ 5'b00000, positionY[9:5]}] == CEMPTY) begin
									count1 <= count1 + 1;
								end
								else if (board[{5'b00000, positionX[9:5]} + 2][{ 5'b00000, positionY[9:5]}] == colorState2) begin
									count1 <= count1 + 1;
									count2 <= count2 - 1;
								end 
							end
						endcase
					end

					// Player 2 shoots
					if (shoot2) begin
						case (shootDir2)
							UP: begin
								board[{5'b00000, positionX2[9:5]}][{ 5'b00000, positionY2[9:5]} - 2] <= colorState2;

								if (board[{5'b00000, positionX2[9:5]}][{ 5'b00000, positionY2[9:5]} - 2] == CEMPTY) begin
									count2 <= count2 + 1;
								end
								else if (board[{5'b00000, positionX2[9:5]}][{ 5'b00000, positionY2[9:5]} - 2] == colorState1) begin
									count2 <= count2 + 1;
									count1 <= count1 - 1;
								end 
							end
							DOWN: begin
								board[{5'b00000, positionX2[9:5]}][{ 5'b00000, positionY2[9:5]} + 2] <= colorState2;

								if (board[{5'b00000, positionX2[9:5]}][{ 5'b00000, positionY2[9:5]} + 2] == CEMPTY) begin
									count2 <= count2 + 1;
								end
								else if (board[{5'b00000, positionX2[9:5]}][{ 5'b00000, positionY2[9:5]} + 2] == colorState1) begin
									count2 <= count2 + 1;
									count1 <= count1 - 1;
								end 
							end
							LEFT: begin
								board[{5'b00000, positionX2[9:5]} - 2][{ 5'b00000, positionY2[9:5]}] <= colorState2;

								if (board[{5'b00000, positionX2[9:5]} - 2][{ 5'b00000, positionY2[9:5]}] == CEMPTY) begin
									count2 <= count2 + 1;
								end
								else if (board[{5'b00000, positionX2[9:5]} - 2][{ 5'b00000, positionY2[9:5]}] == colorState1) begin
									count2 <= count2 + 1;
									count1 <= count1 - 1;
								end 
							end
							RIGHT: begin
								board[{5'b00000, positionX2[9:5]} + 2][{ 5'b00000, positionY2[9:5]}] <= colorState2;

								if (board[{5'b00000, positionX2[9:5]} + 2][{ 5'b00000, positionY2[9:5]}] == CEMPTY) begin
									count2 <= count2 + 1;
								end
								else if (board[{5'b00000, positionX2[9:5]} + 2][{ 5'b00000, positionY2[9:5]}] == colorState1) begin
									count2 <= count2 + 1;
									count1 <= count1 - 1;
								end 
							end
						endcase
					end

					// Boundaries
					if (positionX < 3)
						positionX <= 3;
					if (positionX > 349)
						positionX <= 349;
					if (positionY < 3) 
						positionY <= 3;
					if (positionY > 349)
						positionY <= 349;

					if (positionX2 < 3)
						positionX2 <= 3;
					if (positionX2 > 349)
						positionX2 <= 349;
					if (positionY2 < 3) 
						positionY2 <= 3;
					if (positionY2 > 349)
						positionY2 <= 349;

				
					board[{5'b00000, positionX[9:5]}][{ 5'b00000, positionY[9:5]}] <= colorState1;
					board[{5'b00000, positionX2[9:5]}][{ 5'b00000, positionY2[9:5]}] <= colorState2;
				end
				else if (gameState == GEND) begin
				

					if (count1 > count2) begin
						winner <= 2'b01;
					end
					else if (count1 < count2) begin
						winner <= 2'b10;
					end
					else begin
						winner <= 2'b11;
					end
				end
				
			end

			wire [9:0] currentX1;
			wire [9:0] currentY1;
			wire [9:0] currentX2;
			wire [9:0] currentY2;
			wire checkPos;
			assign currentX1 = {5'b00000, positionX[9:5]};
			assign currentY1 = {5'b00000, positionY[9:5]};
			assign currentX2 = {5'b00000, positionX2[9:5]};
			assign currentY2 = { 5'b00000, positionY2[9:5]};

			assign checkPos = ((currentX1 == {5'b00000, CounterX[9:5]}) && (currentY1 == {5'b00000, CounterY[9:5]})) 
					 || ((currentX2 == {5'b00000, CounterX[9:5]}) && (currentY2 == {5'b00000, CounterY[9:5]}));

			wire R = 	(CounterX > 353 || CounterY > 353) ? 0 :
						((checkPos && gameState != GINIT) || CounterX[4:0] == 5'b00000 || CounterY[4:0] == 5'b00000) ? 1 :
						(board[{5'b00000, CounterX[9:5]}][{5'b00000, CounterY[9:5]}] == CRED);
			wire G = 	(CounterX > 353 || CounterY > 353) ? 0 :
						((checkPos && gameState != GINIT) || CounterX[4:0] == 5'b00000 || CounterY[4:0] == 5'b00000) ? 1 : 
					 	(board[{5'b00000, CounterX[9:5]}][{5'b00000, CounterY[9:5]}] == CGREEN); 
			wire B = 	(CounterX > 353 || CounterY > 353) ? 0 :
						((checkPos && gameState != GINIT) || CounterX[4:0] == 5'b00000 || CounterY[4:0] == 5'b00000) ? 1 : 
					 	(board[{5'b00000, CounterX[9:5]}][{5'b00000, CounterY[9:5]}] == CBLUE);
			
		

			always @(posedge clk)
			begin
				vga_r <= R & inDisplayArea;
				vga_g <= G & inDisplayArea;
				vga_b <= B & inDisplayArea;
			end
			//..................................................
			//..................................................

			
			// Data to be sent to PmodJSTK, lower two bits will turn on leds on PmodJSTK
			assign sndData = (winner == 2'b10) ? {8'b100000, 2'b11} : {8'b100000, 2'b00};
			assign sndData_D = (winner == 2'b01) ? {8'b100000, 2'b11} : {8'b100000, 2'b00};

			// Assign PmodJSTK button status to LED[2:0]
			always @(sndRec or RST or jstkData) begin
					if(RST == 1'b1) begin
							LED <= 3'b000;
					end
					else begin
							LED <= {jstkData[1], {jstkData[2], jstkData[0]}};
					end
			end

			

endmodule
