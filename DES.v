module DES(
	input wire 	i_Clk,
	input wire	i_Start,
	input wire	i_Reset,

	input wire	i_Dec,

	input wire	[63:0] i_Data,
	input wire 	[63:0] i_Key,

	output wire	[63:0] o_Data,
	output wire		   o_fBusy,	//RUN
	output wire		   o_fDone		//DONE
);

	//Parameter
	parameter IDLE	= 2'd0;
	parameter ROUND	= 2'd1;
	parameter END	= 2'd2;

	//registers
	reg [31:0]	c_L		, c_R;
	reg [ 1:0] 	c_State	, n_State;
	reg [55:0] 	c_Key	, n_Key;
	reg [31:0]	n_L		, n_R;
	reg [ 3:0]	c_round, n_round;
	
	// Data wires
	wire [63:0] ip_in;
	wire [63:0]	ip_out;
	wire [47:0] etable_in;
	wire [47:0] etable_out;
	wire [47:0]	e_xor_roundkey;
	wire [47:0] sbox_in;
	wire [31:0]	sbox_out;
	wire [31:0] ptable_in;
	wire [31:0]	ptable_out;
	wire [31:0] p_xor_c_L;
	wire [63:0] inv_ip_in;
	wire [63:0] inv_ip_out;

	//key wires
	wire [63:0] pc1_in;
	wire [55:0]	pc1_out;
	wire [55:0]	left_shift;
	wire [55:0]	right_shift;
	wire [55:0] pc2_in;
	wire [47:0] roundkey;
	wire [47:0]	pc2_out;


/////////////flipflop
	always @(posedge i_Clk or negedge i_Reset)	begin
		if(!i_Reset)	begin
			c_State	= 2'b0;
			c_L 	= 32'b0;
			c_R		= 32'b0;
			c_Key 	= 56'b0;
			c_round	= 4'b0;
			end
		else	begin
			c_State	= n_State;
			c_L		= n_L;
			c_R		= n_R;
			c_Key	= n_Key;
			c_round	= n_round;
			end
	end

	always @(*)	begin
		n_State	= c_State;
		case (c_State)
			IDLE	: 	if(i_Start)							n_State	=	ROUND;
			ROUND	:	if(c_round == 4'd15)				n_State = 	END;
			END		:										n_State =	IDLE;
		endcase
	end

	always@(*)	begin
		n_round = 4'd0;
		if(c_State == ROUND)	n_round = c_round + 1'b1;
	end
	
	assign o_fDone = (c_State == END );
	assign o_fBusy = (c_State == ROUND);

//////////////////////////////////////////////////////data operation///////////////////////////////////////////////////////////////////
	assign ip_in 	= i_Data;
	assign ip_out 	= {	ip_in[6],	ip_in[14],	ip_in[22],	ip_in[30],	ip_in[38],	ip_in[46],	ip_in[54],	ip_in[62],
						ip_in[4],	ip_in[12],	ip_in[20],	ip_in[28],	ip_in[36],	ip_in[44],	ip_in[52],	ip_in[60],
						ip_in[2],	ip_in[10],	ip_in[18],	ip_in[26],	ip_in[34],	ip_in[42],	ip_in[50],	ip_in[58],
						ip_in[0],	ip_in[ 8],	ip_in[16],	ip_in[24],	ip_in[32],	ip_in[40],	ip_in[48],	ip_in[56],
						ip_in[7],	ip_in[15],	ip_in[23],	ip_in[31],	ip_in[39],	ip_in[47],	ip_in[55],	ip_in[63],
						ip_in[5],	ip_in[13],	ip_in[21],	ip_in[29],	ip_in[37],	ip_in[45],	ip_in[53],	ip_in[61],
						ip_in[3],	ip_in[11],	ip_in[19],	ip_in[27],	ip_in[35],	ip_in[43],	ip_in[51],	ip_in[59],
						ip_in[1],	ip_in[ 9],	ip_in[17],	ip_in[25],	ip_in[33],	ip_in[41],	ip_in[49],	ip_in[57]};

	assign etable_in = c_R;
	assign etable_out = {		etable_in[ 0],	etable_in[31],	etable_in[30],	etable_in[29],	etable_in[28],	etable_in[27],
								etable_in[28],	etable_in[27],	etable_in[26],	etable_in[25],	etable_in[24],	etable_in[23],
								etable_in[24],	etable_in[23],	etable_in[22],	etable_in[21],	etable_in[20],	etable_in[19],
								etable_in[20],	etable_in[19],	etable_in[18],	etable_in[17],	etable_in[16],	etable_in[15],
								etable_in[16],	etable_in[15],	etable_in[14],	etable_in[13],	etable_in[12],	etable_in[11],
								etable_in[12],	etable_in[11],	etable_in[10],	etable_in[ 9],	etable_in[ 8],	etable_in[ 7],
								etable_in[ 8],	etable_in[ 7],	etable_in[ 6],	etable_in[ 5],	etable_in[ 4],	etable_in[ 3],
								etable_in[ 4],	etable_in[ 3],	etable_in[ 2],	etable_in[ 1],	etable_in[ 0],	etable_in[31]};
	
	assign e_xor_roundkey = etable_out ^ roundkey;

	assign sbox_in = e_xor_roundkey;
	SBOX sbox (.i_Sbox(sbox_in),.o_Sbox(sbox_out));

	assign ptable_in = sbox_out;
	assign ptable_out = {		ptable_in[16],	ptable_in[25],	ptable_in[12],	ptable_in[11],	ptable_in[ 3],	ptable_in[20],	ptable_in[ 4],	ptable_in[15],
								ptable_in[31],	ptable_in[17],	ptable_in[ 9],	ptable_in[ 6],	ptable_in[27],	ptable_in[14],	ptable_in[ 1],	ptable_in[22],
								ptable_in[30],	ptable_in[24],	ptable_in[ 8],	ptable_in[18],	ptable_in[ 0],	ptable_in[ 5],	ptable_in[29],	ptable_in[23],
								ptable_in[13],	ptable_in[19],	ptable_in[ 2],	ptable_in[26],	ptable_in[10],	ptable_in[21],	ptable_in[28],	ptable_in[ 7]}; 

	assign p_xor_c_L = ptable_out ^ c_L;


	assign inv_ip_in = {c_R,c_L};
	assign inv_ip_out = {	inv_ip_in[24], inv_ip_in[56], inv_ip_in[16], inv_ip_in[48],	inv_ip_in[8],  inv_ip_in[40], inv_ip_in[0], inv_ip_in[32],
							inv_ip_in[25], inv_ip_in[57], inv_ip_in[17], inv_ip_in[49],	inv_ip_in[9],  inv_ip_in[41], inv_ip_in[1], inv_ip_in[33],
							inv_ip_in[26], inv_ip_in[58], inv_ip_in[18], inv_ip_in[50],	inv_ip_in[10], inv_ip_in[42], inv_ip_in[2], inv_ip_in[34],
							inv_ip_in[27], inv_ip_in[59], inv_ip_in[19], inv_ip_in[51], inv_ip_in[11], inv_ip_in[43], inv_ip_in[3], inv_ip_in[35],
							inv_ip_in[28], inv_ip_in[60], inv_ip_in[20], inv_ip_in[52], inv_ip_in[12], inv_ip_in[44], inv_ip_in[4], inv_ip_in[36],
							inv_ip_in[29], inv_ip_in[61], inv_ip_in[21], inv_ip_in[53],	inv_ip_in[13], inv_ip_in[45], inv_ip_in[5], inv_ip_in[37],
							inv_ip_in[30], inv_ip_in[62], inv_ip_in[22], inv_ip_in[54], inv_ip_in[14], inv_ip_in[46], inv_ip_in[6], inv_ip_in[38],
							inv_ip_in[31], inv_ip_in[63], inv_ip_in[23], inv_ip_in[55], inv_ip_in[15], inv_ip_in[47], inv_ip_in[7], inv_ip_in[39]};

	assign o_Data = inv_ip_out;

	always@(*)	begin
		n_L = ip_out [63:32];
		n_R = ip_out [31:0];
			case(c_State)
				ROUND	:	begin
					n_L = c_R;
					n_R = p_xor_c_L;
					end
			endcase
	end


////////////////////////////////////////////////////key operation/////////////////////////////////////////////////////////////////////////////////////////////

	assign pc1_in = i_Key;
	assign pc1_out = {	pc1_in[ 7],	pc1_in[15],	pc1_in[23],	pc1_in[31],	pc1_in[39],	pc1_in[47],	pc1_in[55],
						pc1_in[63],	pc1_in[ 6],	pc1_in[14],	pc1_in[22],	pc1_in[30],	pc1_in[38],	pc1_in[46],
						pc1_in[54],	pc1_in[62],	pc1_in[ 5],	pc1_in[13],	pc1_in[21],	pc1_in[29],	pc1_in[37],
						pc1_in[45],	pc1_in[53],	pc1_in[61],	pc1_in[ 4],	pc1_in[12],	pc1_in[20],	pc1_in[28],
						pc1_in[ 1],	pc1_in[ 9],	pc1_in[17],	pc1_in[25],	pc1_in[33],	pc1_in[41],	pc1_in[49],
						pc1_in[57],	pc1_in[ 2],	pc1_in[10],	pc1_in[18],	pc1_in[26],	pc1_in[34],	pc1_in[42],
						pc1_in[50],	pc1_in[58],	pc1_in[ 3],	pc1_in[11],	pc1_in[19],	pc1_in[27],	pc1_in[35],
						pc1_in[43],	pc1_in[51],	pc1_in[59],	pc1_in[36],	pc1_in[44],	pc1_in[52],	pc1_in[60]};



	assign left_shift 	= (c_round == 0 || c_round == 1 || c_round == 8 || c_round == 15)	? {c_Key[54:28], c_Key[55], c_Key[26:0], c_Key[27]} : {c_Key[53:28], c_Key[55:54], c_Key[25:0], c_Key[27:26]};
	assign right_shift 	= (c_round == 0) ? c_Key : (c_round == 1 || c_round == 8 || c_round == 15) ? {c_Key[28], c_Key[55:29], c_Key[0], c_Key[27:1]} : {c_Key[29:28], c_Key[55:30], c_Key[1:0], c_Key[27:2]};

	assign pc2_in = (!i_Dec) ? left_shift : right_shift;
	assign pc2_out = {	pc2_in[42],	pc2_in[39],	pc2_in[45],	pc2_in[32],	pc2_in[55],	pc2_in[51],	pc2_in[53],	pc2_in[28],
						pc2_in[41],	pc2_in[50],	pc2_in[35],	pc2_in[46],	pc2_in[33],	pc2_in[37],	pc2_in[44],	pc2_in[52],
						pc2_in[30],	pc2_in[48],	pc2_in[40],	pc2_in[49],	pc2_in[29],	pc2_in[36],	pc2_in[43],	pc2_in[54],
						pc2_in[15],	pc2_in[ 4],	pc2_in[25],	pc2_in[19],	pc2_in[ 9],	pc2_in[ 1],	pc2_in[26],	pc2_in[16],
						pc2_in[ 5],	pc2_in[11],	pc2_in[23],	pc2_in[ 8],	pc2_in[12],	pc2_in[ 7],	pc2_in[17],	pc2_in[ 0],
						pc2_in[22],	pc2_in[ 3],	pc2_in[10],	pc2_in[14],	pc2_in[ 6],	pc2_in[20],	pc2_in[27],	pc2_in[24]};

	assign roundkey = pc2_out;

	always@(*)	begin
		n_Key = c_Key;
		case(c_State)
				IDLE	:	begin
					n_Key = pc1_out;
					end
				ROUND	:	begin
					if(!i_Dec)	n_Key = left_shift;
					else		n_Key = right_shift;
				end
			endcase
	end	

endmodule

