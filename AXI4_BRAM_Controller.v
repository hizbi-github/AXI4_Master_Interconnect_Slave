`timescale 1ns / 1ns
//`include "BRAM.v"

// Task 2 Data Transfer between AXI4 based BRAM Slave and AXI4 based Master
// Hizbullah Khan
// [FA19-BCE-080]

module AXI4_BRAM_Controller(ACLK, ARESET,
							ARID, ARADDR, ARBURST, ARVALID, ARREADY, ARLEN, ARSIZE,		// Read Address Channel
							RID, RDATA, RLAST, RVALID, RREADY, RRESP,					// Read Data Channel
							AWID, AWADDR, AWBURST, AWVALID, AWREADY, AWLEN, AWSIZE, 	// Write Address Channel
							WID, WDATA, WLAST, WVALID, WREADY, 							// Write Data Channel
							BID, BRESP, BVALID, BREADY);								// Write Response Channel
			
parameter memWidth = 8;
parameter memDepth = 32;
parameter addressLength = 5;			// Calculated by taking (log2) of "memDepth"
parameter readAddressStart = 0;
parameter readAddressEnd = 9;
			
input ACLK;
input ARESET;

input [3:0] ARID;
input [addressLength-1:0] ARADDR;		// Read Address Channel
input [1:0] ARBURST;
input [0:0] ARVALID;
output reg [0:0] ARREADY;
input [7:0] ARLEN;	// ARLEN contains the number of beats minus one. Slave uses this information to generate response data beats matching ARLEN + 1
input [2:0] ARSIZE;

output reg [3:0] RID;
output reg [memWidth-1:0] RDATA;		// Read Data Channel
output reg [0:0] RLAST;
output reg [0:0] RVALID;
input [0:0] RREADY;
output reg [1:0] RRESP;

input [3:0] AWID;
input [addressLength-1:0] AWADDR;		// Write Address Channel
input [1:0] AWBURST;
input [0:0] AWVALID;
output reg [0:0] AWREADY;
input [7:0] AWLEN;
input [2:0] AWSIZE;

input [3:0] WID;
input [memWidth-1:0] WDATA;				// Write Data Channel
input [0:0] WVALID;
output reg [0:0] WREADY;
input [0:0] WLAST;

output reg [3:0] BID;
output reg [1:0] BRESP;					// Write Response Channel
output reg [0:0] BVALID;
input [0:0] BREADY;

/* Handshake Logic
   Data Transfer Logic
   Etc..... */

reg [0:0] readEnable = 1'bZ;
reg [0:0] writeEnable = 1'bZ;
reg [addressLength-1:0] readAddressBRAM;
reg [addressLength-1:0] writeAddressBRAM;
reg [3:0] readTransactionID = 4'bZ;
reg [0:0] readAddressChannelEnabled = 1'bZ;
reg [0:0] readChannelEnabled = 1'bZ;
reg [3:0] writeTransactionID = 4'bZ;
reg [0:0] writeAddressChannelEnabled = 1'bZ;
reg [0:0] writeChannelEnabled = 1'bZ;
reg [0:0] writeResponseChannelEnabled = 1'bZ;
reg [2:0] readBurstTypeState = 3'bZ;
reg [2:0] writeBurstTypeState = 3'bZ;
reg [1:0] readStatusRRESP = 2'bZ;
reg [1:0] writeStatusBRESP = 2'bZ;

reg [0:0] firstTimeInitBRAMAddress = 1'bZ;

reg [memWidth-1:0] BRAM [0:memDepth-1];		// BRAM used for storing the data.

initial
begin//"../"
	$readmemh("../initMem.txt", BRAM, readAddressStart, readAddressEnd);		// Initialize the BRAM.
end

generate            // Maps all the elements of the above array to a wire. Only possible way to dump the
  genvar index;     // values of array into a VCD file.
  for(index=0; index<10; index=index+1) 
  begin: register
    wire [7:0] wireOfBRAM;
    assign wireOfBRAM = BRAM[index];
  end
endgenerate

always @ (posedge ACLK)
begin
	if (ARESET != 1'b0)
	begin
		if (readEnable == 1'b1)
		begin
			RDATA <= BRAM[readAddressBRAM];	// Read from the BRAM
		end

		else
		begin
			RDATA <= 8'bZ;
		end
		
		if (writeEnable == 1'b1)
		begin
			BRAM[writeAddressBRAM] <= WDATA;	// Write to the BRAM
		end
	end
end

always @ (posedge ACLK)
begin
	if (ARESET == 1'b0)			// Setting all output signals to low on reset (active low)
	begin
		ARREADY <= 1'bZ;
		RVALID <= 1'bZ;
		BVALID <= 1'bZ;
		RID <= 4'bZ;
		RDATA <= 8'bZ;
		RLAST <= 1'bZ;
		RVALID <= 1'bZ;
		RRESP <= 2'bZ;			
		AWREADY <= 1'bZ;
		WREADY <= 1'bZ;
		BID <= 4'bZ;
		BRESP <= 2'bZ;			
		BVALID <= 1'bZ;
		readEnable <= 1'b0;
		writeEnable <= 1'b0;
		readAddressBRAM <= 5'bZ;
		writeAddressBRAM <= 5'bZ;
		readTransactionID <= 4'bz;		
		writeTransactionID <= 4'bz;		
		readAddressChannelEnabled <= 1'b1;
		writeAddressChannelEnabled <= 1'b1;
	end
end

always @ (posedge ACLK)
begin
	if (ARESET != 1'b0)
	begin
		if (readAddressChannelEnabled == 1'b1)
		begin
			ARREADY <= 1'b1;
			RID <= 4'bZ;
			RRESP <= 2'bZ;					
			RLAST <= 1'b0;

			if ((ARVALID == 1'b1) && (ARSIZE == 3'b000))	// Size of '0' means the size of each Beat is 1 Byte or 8 bits.
			begin
				readTransactionID <= ARID;
				readAddressBRAM <= ARADDR;
				readBurstTypeState <= ARBURST;
				readEnable <= 1'b1;
				RVALID <= 1'b1;	
				RLAST <= 1'b0;
				readAddressChannelEnabled <= 1'b0;
				readChannelEnabled <= 1'b1;
			end
		end
	end
end

always @ (posedge ACLK)
begin
	if (ARESET != 1'b0)
	begin
		if (readChannelEnabled == 1'b1)
		begin
			ARREADY <= 1'b0;	
			RID <= readTransactionID;
			RRESP <= 2'b00;					// OKAY Response

			case (readBurstTypeState)		// Switching through the three Burst types.

				2'b00:	// FIXED Burst Type
				begin
					if (RREADY == 1'b1)
					begin
						readAddressBRAM <= ARADDR;
						RLAST <= 1'b0;
					end
				end

				2'b01:	// INCREMENT Burst Type
				begin
					if (RREADY == 1'b1)
					begin
						readAddressBRAM <= readAddressBRAM + 1;

						if (readAddressBRAM >= ARADDR + ARLEN)		
						begin
							readAddressChannelEnabled <= 1'b1;
							RVALID <= 1'b0;
							RLAST <= 1'b1;
							readEnable <= 1'b0;
							readAddressBRAM <= 5'bZ;
							readChannelEnabled <= 1'b0;
						end
					end
				end

				2'b10:	// WRAP Burst Type
				begin
					if (RREADY == 1'b1)
					begin
						readAddressBRAM <= readAddressBRAM + 1;

						if (readAddressBRAM >= ARADDR + ARLEN)		
						begin
							readAddressBRAM <= ARADDR;
						end
					end
				end
			endcase
		end
	end
end

always @ (posedge ACLK)
begin
	if (ARESET != 1'b0)
	begin
		if (writeAddressChannelEnabled == 1'b1)
		begin
			AWREADY <= 1'b1;
			BID <= 4'bZ;
			BVALID <= 1'b0; 
			BRESP <= 2'bZ;

			if ((AWVALID == 1'b1) && (AWSIZE == 3'b000))
			begin
				firstTimeInitBRAMAddress <= 1'b1;
				WREADY <= 1'b1;
				writeTransactionID <= AWID;
				writeBurstTypeState <= AWBURST;
				writeEnable <= 1'b1;
				writeAddressChannelEnabled <= 1'b0;
				writeChannelEnabled = 1'b1;
				AWREADY <= 1'b0;
			end
		end
	end
end

always @ (posedge ACLK)
begin
	if (ARESET != 1'b0)
	begin
		if (writeChannelEnabled == 1'b1)
		begin
			if ((firstTimeInitBRAMAddress == 1'b1) && (WVALID == 1'b1))
			begin
				writeAddressBRAM <= AWADDR;
				firstTimeInitBRAMAddress <= 1'b0;
			end

			case (writeBurstTypeState)
				2'b00:	// FIXED Burst Type
				begin
					writeAddressBRAM <= AWADDR;
				end 

				2'b01:	// INCREMENT Burst Type
				begin
					if ((WVALID == 1'b1) && (WID == writeTransactionID))
					begin
						if (writeAddressBRAM < AWADDR + AWLEN)	
						begin
							writeAddressBRAM <= writeAddressBRAM + 1;
						end		
					end

					if (writeAddressBRAM >= AWADDR + AWLEN)
					begin
						writeResponseChannelEnabled <= 1'b1;
						writeStatusBRESP <= 2'b00;		// Write Response = Okay/Successfull 
						//writeStatusBRESP <= 2'b10;		// Write Response = Slave Error 
						WREADY <= 1'b0;
						writeEnable <= 1'b0;
						writeAddressBRAM <= 5'bZ;
						writeChannelEnabled <= 1'b0;
					end
				end

				2'b10:	// WRAP Burst Type
				begin
					if ((WVALID == 1'b1) && (WID == writeTransactionID))
					begin
						if (writeAddressBRAM < AWADDR + AWLEN)	
						begin
							writeAddressBRAM <= writeAddressBRAM + 1;
						end		
					end

					if (writeAddressBRAM >= AWADDR + AWLEN)
					begin
						writeAddressBRAM <= AWADDR;
					end
				end
			endcase
		end
	end
end

always @ (posedge ACLK)
begin
	if (ARESET != 1'b0)			
	begin
		if (writeResponseChannelEnabled == 1'b1)
		begin
			BID <= writeTransactionID;
			BVALID <= 1'b1;

			if (BREADY == 1'b1)
			begin
				writeAddressChannelEnabled <= 1'b1;
				BRESP <= writeStatusBRESP;
				writeResponseChannelEnabled <= 1'b0;
			end
		end
	end
end

endmodule

























/*

master 
	|
interconnect
	|
slave

*/



/////////// Original Slave Logic (will not work) ///////////

//always @ (posedge ACLK) 
//begin
//	case (readChannelState)		// Switching from Read Address Channel to Read Data Channel.
//		1:			// Read Address Channel
//		begin
//			ARREADY <= 1'b1;
//			RLAST <= 1'b0;
//			readBurstTypeState <= ARBURST;

//			if ((ARVALID == 1'b1) && (ARSIZE == 3'b000))	// Size of '0' means the size of each Beat is 1 Byte or 8 bits.
//			begin
//				//ARREADY <= 1'b1;
//				readAddressBRAM <= ARADDR;
//				readChannelState <= 2;
//				readEnable <= 1'b1;
//			end
//		end 

//		2:			// Read Data Channel
//		begin
//			ARREADY <= 1'b0;	// Should be zero in the final design.
//			RVALID <= 1'b1;	
//			//readEnable <= 1'b1;
							
//			if (RREADY == 1'b1)
//			begin
//				RLAST <= 1'b1;
//				//RDATA <= BRAM[readAddressBRAM];
//				readEnable <= 1'b0;

//				RRESP <= 2'b00;					// OKAY Response

//				case (readBurstTypeState)		// Switching through the three Burst types.

//					2'b00:	// FIXED Burst Type
//					begin
//						readAddressBRAM <= ARADDR;
//						RLAST <= 1'b0;
//					end

//					2'b01:	// INCREMENT Burst Type
//					begin
//						readAddressBRAM <= readAddressBRAM + 1;

//						if (readAddressBRAM < ARADDR + ARLEN)		// 4 + 1 = 5...1 2 3 4 5
//						begin
//							RLAST <= 1'b0;
//							readEnable <= 1'b1;
//						end
//					end

//					2'b10:	// WRAP Burst Type
//					begin
//						readAddressBRAM <= readAddressBRAM + 1;

//						if (readAddressBRAM < ARADDR + ARLEN)		// 4 + 1 = 5...1 2 3 4 5
//						begin
//							RLAST <= 1'b0;
//						end

//						else
//						begin
//							readAddressBRAM <= ARADDR;
//						end
//					end
//				endcase
//			end
//		end
//	endcase
//end

//always @ (posedge ACLK)
//begin
//	case (writeChannelState)		// Switching from Write Address Channel to Write Data Channel.
//		1:			// Write Address Channel
//		begin
//			AWREADY <= 1'b0;

//			if ((AWVALID == 1'b1) && (AWSIZE == 3'b000))
//			begin
//				AWREADY <= 1'b1;
//				writeAddressBRAM <= AWADDR;
//				writeBurstTypeState <= AWBURST;

//				writeChannelState <= 2;
//			end
//		end 

//		2:			// Write Data Channel
//		begin
//			AWREADY <= 1'b0;

//			if (WVALID == 1'b1) 
//			begin
//				WREADY <= 1'b1;

//				if (WDATA !== 8'bX)
//				begin
//					writeChannelState <= 3;

//					case (writeBurstTypeState)
//						2'b00:	// FIXED Burst Type
//						begin
//							//BRAM[writeAddressBRAM] <= WDATA;
//							writeEnable <= 1'b1;

//							writeAddressBRAM <= AWADDR;

//							writeChannelState <= 2;
//						end 

//						2'b01:	// INCREMENT Burst Type
//						begin
//							//BRAM[writeAddressBRAM] <= WDATA;
//							writeEnable <= 1'b1;
							
//							if (writeAddressBRAM < AWADDR + AWLEN)		// 4 + 1 = 5...1 2 3 4 5
//							begin
//								writeAddressBRAM <= writeAddressBRAM + 1;

//								writeChannelState <= 2;
//							end
//						end

//						2'b10:	// WRAP Burst Type
//						begin
//							//BRAM[writeAddressBRAM] <= WDATA;
//							writeEnable <= 1'b1;

//							if (writeAddressBRAM < AWADDR + AWLEN)		// 4 + 1 = 5...1 2 3 4 5
//							begin
//								writeAddressBRAM <= writeAddressBRAM + 1;

//								writeChannelState <= 2;
//							end

//							else
//							begin
//								writeAddressBRAM <= AWADDR;
//							end
//						end
//					endcase
//				end
//			end
//		end

//		3:			// Write Response Channel
//		begin
//			BVALID <= 1'b1;

//			if (BREADY == 1'b1)
//			begin
//				BRESP <= 2'b00;
//			end
//		end
//	endcase
//end

//always @ (posedge ACLK)		// Read Channel State Control Block
//begin
//	//if ((ARVALID == 1'b1) && (ARSIZE == 3'b000))		// Size of '0' means the size of each Beat is 1 Byte or 8 bits.
//	//begin
//	//	readChannelState <= 2;
//	//end

//	if (RREADY == 1'b1)
//	begin
//		readChannelState <= 0;

//		if (readBurstTypeState == 2'b00)	// FIXED Burst Type
//		begin
//			readChannelState <= 2;
//		end

//		if (readBurstTypeState == 2'b01)	// INCREMENT Burst Type
//		begin
//			if (readAddressBRAM < ARADDR + ARLEN)		// 4 + 1 = 5...1 2 3 4 5
//			begin
//				readChannelState <= 2;
//			end
//		end

//		if (readBurstTypeState == 2'b10)	// WRAP Burst Type
//		begin
//			if (readAddressBRAM < ARADDR + ARLEN)		// 4 + 1 = 5...1 2 3 4 5
//			begin
//				readChannelState <= 2;
//			end

//			else
//			begin
//				readChannelState <= 2;
//			end
//		end
//	end
//end

//always @ (posedge ACLK)		// Write Channel State Control Block
//begin
//	if (AWVALID == 1'b1)
//	begin
//		writeChannelState <= 2;
//	end

//	if (AWSIZE == 3'b000)				// Size of '0' means the size of each Beat is 1 Byte or 8 bits.
//	begin
//		if (WVALID == 1'b1)
//		begin
//			writeChannelState <= 1;

//			if (writeBurstTypeState == 2'b00)	// FIXED Burst Type
//			begin
//				writeChannelState <= 2;
//			end

//			if (writeBurstTypeState == 2'b01)	// INCREMENT Burst Type
//			begin
//				if (writeAddressBRAM < AWADDR + AWLEN)		
//				begin
//					writeChannelState <= 2;
//				end
//			end

//			if (writeBurstTypeState == 2'b10)	// WRAP Burst Type
//			begin
//				if (writeAddressBRAM < AWADDR + AWLEN)		
//				begin
//					writeChannelState <= 2;
//				end

//				else
//				begin
//					writeChannelState <= 2;
//				end
//			end
//		end
//	end
//end

//assign wiredAddressBRAM = readAddressBRAM;		// Just for testing...



/////////// First Slave Logic (will not work) ///////////

//always @ (posedge ACLK) 
//begin
//	//ARREADY <= 1'b0;

//	if (ARVALID == 1'b1 && RREADY == 1'b0)
//	begin
//		ARREADY <= 1'b1;
//		addressBRAM <= ARADDR;
//	end

//	//else
//	//begin
//	//	ARREADY <= 1'b0;
//	//end 
//end

//always @ (posedge ACLK) 
//begin
//	if (ARREADY == 1'b1)
//	begin
//		if (ARSIZE == 3'b000)		// Size of '0' means the size of each Beat is 1 Byte.
//		begin
//			RVALID <= 1'b1;	
//			RDATA <= outputBRAM;
//			//RRESP = 2'b00;	// Will be implemented later.

//			if (RREADY == 1'b1)
//			begin
//				RLAST <= 1'b1;
//				if ((addressBRAM - ARADDR) + 1 < ARLEN + 1)		// 4 + 1 = 5...1 2 3 4 5
//				begin
//					addressBRAM <= addressBRAM + 1;
//					RLAST <= 1'b0;
//				end
//			end
//		end
//	end
//end

