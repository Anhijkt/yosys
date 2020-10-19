(* abc9_lut=1, lib_whitebox *)
module LUT4(input A, B, C, D, output Z);
	parameter INIT = "0x0000";
`include "parse_init.vh"
	localparam initp = parse_init(INIT);
	wire [7:0] s3 = D ?     initp[15:8] :    initp[7:0];
	wire [3:0] s2 = C ?       s3[ 7:4]  :       s3[3:0];
	wire [1:0] s1 = B ?       s2[ 3:2]  :       s2[1:0];
	assign Z =      A ?          s1[1]  :         s1[0];

	// Per-input delay differences are considered 'interconnect'
	// so not known yet
	specify
		(A => Z) = 233;
		(B => Z) = 233;
		(C => Z) = 233;
		(D => Z) = 233;
	endspecify

endmodule

// This is a placeholder for ABC9 to extract the area/delay
//   cost of 5-input LUTs and is not intended to be instantiated
(* abc9_lut=2 *)
module \$__ABC9_LUT5 (input SEL, D, C, B, A, output Z);
	specify
		(SEL => Z) = 171;
		(D => Z) = 303;
		(C => Z) = 311;
		(B => Z) = 309;
		(A => Z) = 306;
	endspecify
endmodule

// Two LUT4s and MUX2
module WIDEFN9(input A0, B0, C0, D0, A1, B1, C1, D1, SEL, output Z);
	parameter INIT0 = "0x0000";
	parameter INIT1 = "0x0000";
	wire z0, z1;
	LUT4 #(.INIT(INIT0)) lut4_0 (.A(A0), .B(B0), .C(C0), .D(D0), .Z(z0));
	LUT4 #(.INIT(INIT1)) lut4_1 (.A(A1), .B(B1), .C(C1), .D(D1), .Z(z1));
	assign Z = SEL ? z1 : z0;
endmodule

(* abc9_box, lib_whitebox *)
module INV(input A, output Z);
	assign Z = !A;

	specify
		(A => Z) = 10;
	endspecify
endmodule

// Bidirectional IO buffer
module BB(input T, I, output O,
	(* iopad_external_pin *) inout B);
	assign B = T ? 1'bz : O;
	assign I = B;
endmodule

// Input buffer
module IB(
	(* iopad_external_pin *) input I,
	output O);
	assign O = I;
endmodule

// Output buffer
module OB(input I,
	(* iopad_external_pin *) output O);
	assign O = I;
endmodule

// Output buffer with tristate
module OBZ(input I, T,
	(* iopad_external_pin *) output O);
	assign O = T ? 1'bz : I;
endmodule

// Constants
module VLO(output Z);
	assign Z = 1'b0;
endmodule

module VHI(output Z);
	assign Z = 1'b1;
endmodule

// Vendor flipflops
// (all have active high clock, enable and set/reset - use INV to invert)

// Async preset
(* abc9_box, lib_whitebox *)
module FD1P3BX(input D, CK, SP, PD, output reg Q);
	parameter GSR = "DISABLED";
	initial Q = 1'b1;
	always @(posedge CK or posedge PD)
		if (PD)
			Q <= 1'b1;
		else if (SP)
			Q <= D;
	specify
		$setup(D, posedge CK, 0);
		$setup(SP, posedge CK, 212);
		$setup(PD, posedge CK, 224);
`ifndef YOSYS
		if (PD) (posedge CLK => (Q : 1)) = 0;
`else
		if (PD) (PD => Q) = 0; 	// Technically, this should be an edge sensitive path
								// but for facilitating a bypass box, let's pretend it's
								// a simple path
`endif
		if (!PD && SP) (posedge CK => (Q : D)) = 336;
	endspecify
endmodule

// Async clear
(* abc9_box, lib_whitebox *)
module FD1P3DX(input D, CK, SP, CD, output reg Q);
	parameter GSR = "DISABLED";
	initial Q = 1'b0;
	always @(posedge CK or posedge CD)
		if (CD)
			Q <= 1'b0;
		else if (SP)
			Q <= D;
	specify
		$setup(D, posedge CK, 0);
		$setup(SP, posedge CK, 212);
		$setup(CD, posedge CK, 224);
`ifndef YOSYS
		if (CD) (posedge CLK => (Q : 0)) = 0;
`else
		if (CD) (CD => Q) = 0; 	// Technically, this should be an edge sensitive path
								// but for facilitating a bypass box, let's pretend it's
								// a simple path
`endif
		if (!CD && SP) (posedge CK => (Q : D)) = 336;
	endspecify
endmodule

// Sync clear
(* abc9_flop, lib_whitebox *)
module FD1P3IX(input D, CK, SP, CD, output reg Q);
	parameter GSR = "DISABLED";
	initial Q = 1'b0;
	always @(posedge CK)
		if (CD)
			Q <= 1'b0;
		else if (SP)
			Q <= D;
	specify
		$setup(D, posedge CK, 0);
		$setup(SP, posedge CK, 212);
		$setup(CD, posedge CK, 224);
		if (!CD && SP) (posedge CK => (Q : D)) = 336;
	endspecify
endmodule

// Sync preset
(* abc9_flop, lib_whitebox *)
module FD1P3JX(input D, CK, SP, PD, output reg Q);
	parameter GSR = "DISABLED";
	initial Q = 1'b1;
	always @(posedge CK)
		if (PD)
			Q <= 1'b1;
		else if (SP)
			Q <= D;
	specify
		$setup(D, posedge CK, 0);
		$setup(SP, posedge CK, 212);
		$setup(PD, posedge CK, 224);
		if (!PD && SP) (posedge CK => (Q : D)) = 336;
	endspecify
endmodule

// LUT4 with LUT3 tap for CCU2 use only
(* lib_whitebox *)
module LUT4_3(input A, B, C, D, output Z, Z3);
	parameter INIT = "0x0000";
`include "parse_init.vh"
	localparam initp = parse_init(INIT);
	wire [7:0] s3 = D ?     initp[15:8] :     initp[7:0];
	wire [3:0] s2 = C ?        s3[ 7:4] :        s3[3:0];
	wire [1:0] s1 = B ?        s2[ 3:2] :        s2[1:0];
	assign Z =      A ?           s1[1] :          s1[0];

	wire [3:0] s2_3 = C ?   initp[ 7:4] :     initp[3:0];
	wire [1:0] s1_3 = B ?    s2_3[ 3:2] :      s2_3[1:0];
	assign Z3 =       A ?       s1_3[1] :        s1_3[0];

endmodule

// Carry primitive (incoporating two LUTs)
(* abc9_box, lib_whitebox *)
module CCU2(
	(* abc9_carry *) input CIN,
	input A1, B1, C1, D1, A0, B0, C0, D0,
	output S1, S0,
	(* abc9_carry *) output COUT);
	parameter INJECT = "YES";
	parameter INIT0 = "0x0000";
	parameter INIT1 = "0x1111";

	localparam inject_p = (INJECT == "YES") ? 1'b1 : 1'b0;

	wire LUT3_0, LUT4_0, LUT3_1, LUT4_1, carry_0;
	LUT4_3 #(.INIT(INIT0)) lut0 (.A(A0), .B(B0), .C(C0), .D(D0), .Z(LUT4_0), .Z3(LUT3_0));
	LUT4_3 #(.INIT(INIT1)) lut1 (.A(A1), .B(B1), .C(C1), .D(D1), .Z(LUT4_1), .Z3(LUT3_1));

	assign S0 = LUT4_0 ^ (CIN & ~inject_p);
	assign carry_0 = LUT4_0 ? CIN : (LUT3_0 & ~inject_p);
	assign S1 = LUT4_1 ^ (carry_0 & ~inject_p);
	assign COUT = LUT4_1 ? carry_0 : (LUT3_1 & ~inject_p);

	specify
		(A0 => S0) = 233;
		(B0 => S0) = 233;
		(C0 => S0) = 233;
		(D0 => S0) = 233;
		(CIN => S0) = 228;
		(A0 => S1) = 481;
		(B0 => S1) = 481;
		(C0 => S1) = 481;
		(D0 => S1) = 481;
		(A1 => S1) = 233;
		(B1 => S1) = 233;
		(C1 => S1) = 233;
		(D1 => S1) = 233;
		(CIN => S1) = 307;
		(A0 => COUT) = 347;
		(B0 => COUT) = 347;
		(C0 => COUT) = 347;
		(D0 => COUT) = 347;
		(A1 => COUT) = 347;
		(B1 => COUT) = 347;
		(C1 => COUT) = 347;
		(D1 => COUT) = 347;
		(CIN => COUT) = 59;
	endspecify

endmodule

// Packed flipflop
module OXIDE_FF(input CLK, LSR, CE, DI, M, output reg Q);
	parameter GSR = "ENABLED";
	parameter [127:0] CEMUX = "1";
	parameter CLKMUX = "CLK";
	parameter LSRMUX = "LSR";
	parameter REGDDR = "DISABLED";
	parameter SRMODE = "LSR_OVER_CE";
	parameter REGSET = "RESET";
	parameter [127:0] LSRMODE = "LSR";

	wire muxce;
	generate
		case (CEMUX)
			"1": assign muxce = 1'b1;
			"0": assign muxce = 1'b0;
			"INV": assign muxce = ~CE;
			default: assign muxce = CE;
		endcase
	endgenerate

	wire muxlsr = (LSRMUX == "INV") ? ~LSR : LSR;
	wire muxclk = (CLKMUX == "INV") ? ~CLK : CLK;
	wire srval;
	generate
		if (LSRMODE == "PRLD")
			assign srval = M;
		else
			assign srval = (REGSET == "SET") ? 1'b1 : 1'b0;
	endgenerate

	initial Q = srval;

	generate
		if (REGDDR == "ENABLED") begin
			if (SRMODE == "ASYNC") begin
				always @(posedge muxclk, negedge muxclk, posedge muxlsr)
					if (muxlsr)
						Q <= srval;
					else if (muxce)
						Q <= DI;
			end else begin
				always @(posedge muxclk, negedge muxclk)
					if (muxlsr)
						Q <= srval;
					else if (muxce)
						Q <= DI;
			end
		end else begin
			if (SRMODE == "ASYNC") begin
				always @(posedge muxclk, posedge muxlsr)
					if (muxlsr)
						Q <= srval;
					else if (muxce)
						Q <= DI;
			end else begin
				always @(posedge muxclk)
					if (muxlsr)
						Q <= srval;
					else if (muxce)
						Q <= DI;
			end
		end
	endgenerate
endmodule

// Packed combinational logic (for post-pnr sim)
module OXIDE_COMB(
	input A, B, C, D, // LUT inputs
	input SEL, // mux select input
	input F1, // output from LUT 1 for mux
	input FCI, // carry input
	input WAD0, WAD1, WAD2, WAD3, // LUTRAM write address inputs
	input WD, // LUTRAM write data input
	input WCK, WRE, // LUTRAM write clock and enable
	output F, // LUT/carry output
	output OFX // mux output
);
	parameter MODE = "LOGIC"; // LOGIC, CCU2, DPRAM
	parameter [15:0] INIT = 16'h0000;
	parameter INJECT = "YES";

	localparam inject_p = (INJECT == "YES") ? 1'b1 : 1'b0;

	reg [15:0] lut = INIT;

	wire [7:0] s3 = D ?     INIT[15:8] :     INIT[7:0];
	wire [3:0] s2 = C ?       s3[ 7:4] :       s3[3:0];
	wire [1:0] s1 = B ?       s2[ 3:2] :       s2[1:0];
	wire Z =        A ?          s1[1] :         s1[0];

	wire [3:0] s2_3 = C ?   INIT[ 7:4] :     INIT[3:0];
	wire [1:0] s1_3 = B ?   s2_3[ 3:2] :     s2_3[1:0];
	wire Z3 =         A ?      s1_3[1] :       s1_3[0];

	generate
		if (MODE == "DPRAM") begin
			always @(posedge WCK)
				if (WRE)
					lut[{WAD3, WAD2, WAD1, WAD0}] <= WD;
		end
		if (MODE == "CCU2") begin
			assign F = Z ^ (FCI & ~inject_p);
			assign FCO = Z ? FCI : (Z3 & ~inject_p);
		end else begin
			assign F = Z;
		end
	endgenerate

	assign OFX = SEL ? F1 : F;

endmodule

// LUTRAM
module DPR16X4(
	input [3:0] RAD, DI, WAD,
	input WRE, WCK,
	output [3:0] DO
);
	parameter INITVAL = "0x0000000000000000";
`include "parse_init.vh"
	localparam [63:0] parsed_init = parse_init_64(INITVAL);

	reg [3:0] mem[0:15];
	integer i;
	initial begin
		for (i = 0; i < 15; i++)
			mem[i] = parsed_init[i * 4 +: 4];
	end

	always @(posedge WCK)
		if (WRE)
			mem[WAD] <= DI;
	assign DO = mem[RAD];
endmodule
