`timescale 1ns / 1ns

// Task 2 Data Transfer between AXI4 based BRAM Slave and AXI4 based Master
// Hizbullah Khan
// [FA19-BCE-080]

module AXI4_Write_BRAM(ACLK, ARESET, SET_ACCESS, RELEASE_ACCESS,
					   ARID, ARADDR, ARBURST, ARVALID, ARREADY, ARLEN, ARSIZE,		// Read Address Channel
					   RID, RDATA, RLAST, RVALID, RREADY, RRESP,				    // Read Data Channel
					   AWID, AWADDR, AWBURST, AWVALID, AWREADY, AWLEN, AWSIZE, 	    // Write Address Channel
					   WID, WDATA, WLAST, WVALID, WREADY, 							// Write Data Channel
					   BID, BRESP, BVALID, BREADY);									// Write Response Channel
			
parameter memWidth = 8;
parameter memDepth = 32;
parameter addressLength = 5;		// Calculated by taking (log2) of "memDepth"
			
input ACLK;
input ARESET;
input [0:0] SET_ACCESS;
output reg [0:0] RELEASE_ACCESS = 1'bZ;

output reg [3:0] ARID;
output reg [addressLength-1:0] ARADDR;	// Read Address Channel
output reg [1:0] ARBURST;
output reg [0:0] ARVALID;
input [0:0] ARREADY;
output reg [7:0] ARLEN;
output reg [2:0] ARSIZE;

input [3:0] RID;
input [memWidth-1:0] RDATA;			// Read Data Channel
input [0:0] RLAST;
input [0:0] RVALID;
output reg [0:0] RREADY;
input [1:0] RRESP;

output reg [3:0] AWID;
output reg [addressLength-1:0] AWADDR;	// Write Address Channel
output reg [1:0] AWBURST;
output reg [0:0] AWVALID;
input [0:0] AWREADY;
output reg [7:0] AWLEN;
output reg [2:0] AWSIZE;

output reg [3:0] WID;
output reg [memWidth-1:0] WDATA;		// Write Data Channel
output reg [0:0] WVALID;
input [0:0] WREADY;
output reg [0:0] WLAST;

input [3:0] BID;
input [1:0] BRESP;						// Write Response Channel
input [0:0] BVALID;
output reg [0:0] BREADY;

/* Handshake Logic
   Data Transfer Logic
   Etc..... */
  
/* Will read co-efficients of a polynomial from the BRAM,
	add a scalar quantity to each of the co-efficients,
	then write back the new co-efficients into the BRAM. */

reg [7:0] coefficientsPoly [0:3];
reg [addressLength-1:0] readAddressARRAY;
reg [addressLength-1:0] writeAddressARRAY;
reg [3:0] readTransactionID = 4'bZ;
reg [0:0] readAddressChannelEnabled = 1'bZ;
reg [0:0] readChannelEnabled = 1'bZ;
reg [3:0] writeTransactionID = 4'bZ;
reg [0:0] writeAddressChannelEnabled = 1'bZ;
reg [0:0] writeChannelEnabled = 1'bZ;
reg [0:0] writeResponseChannelEnabled = 1'bZ;
reg [0:0] performOperations = 1'bZ;
reg [1:0] writeStatusBRESP = 1'bZ;

reg [0:0] resetReleaseAccess = 1'bZ;
reg [0:0] doReadAddressStall = 1'bZ;
reg [0:0] doWriteDataStall = 1'bZ;
integer delayReadCyclesCounter = 0;
integer delayWriteCyclesCounter = 0;
reg [0:0] firstTimeInitArrayAddress = 1'bZ; 
integer arrayIndex = 0;		// For iterating through the array when modifying it arithmetically.

generate            // Maps all the elements of the above array to a wire. Only possible way to dump the
  genvar index;     // values of array into a VCD file.
  for(index=0; index<4; index=index+1) 
  begin: register
    wire [7:0] wireOfPoly;
    assign wireOfPoly = coefficientsPoly[index];
  end
endgenerate

always @ (posedge ACLK)
begin
	if (ARESET == 1'b0)			// Setting all output signals to low on reset (active low)
	begin
		ARID <= 4'bZ;
		ARADDR <= 5'bZ;
		ARBURST <= 2'bZ;
		ARVALID <= 1'bZ;
		ARLEN <= 8'bZ;
		ARSIZE <= 3'bZ;
		RREADY <= 1'bZ;
		coefficientsPoly[0] <= 2;
		coefficientsPoly[1] <= 5;
		coefficientsPoly[2] <= 4;
		coefficientsPoly[3] <= 3;
		AWID <= 4'bZ;
		AWADDR <= 5'bZ;
		AWBURST <= 2'bZ;
		AWVALID <= 1'bZ;
		AWLEN <= 8'bZ;
		AWSIZE <= 3'bZ;
		WID <= 4'bZ;
		WDATA <= 8'bZ;
		WVALID <= 1'bZ;
		WLAST <= 1'bZ;
		BREADY <= 1'bZ;
		readAddressARRAY <= 5'bZ;
		writeAddressARRAY <= 5'bZ;
		readTransactionID <= 4'b0000;		// Starting with ARID of zero and incrementing it after each whole transaction.
		writeTransactionID <= 4'b0000;		// Starting with AWID of zero and incrementing it after each whole transaction.
		writeAddressChannelEnabled <= 1'b1; // Enable this to start with Write Transaction.
        RELEASE_ACCESS <= 1'b0;
		//doReadAddressStall <= 1'b1;       // Enable this to start with Read Transaction.
	end
end

always @ (posedge ACLK)
begin
	if ((ARESET != 1'b0) && (SET_ACCESS == 1'b1))
	begin
		if (doReadAddressStall == 1'b1)		// Stalling for 1 clock cycles before starting the read address transaction.
		begin
			//if (delayReadCyclesCounter >= 2)      // Don't need the Delays when using Interconnect Arbitration.
			//begin
			//	readAddressChannelEnabled <= 1'b1;
			//	delayReadCyclesCounter <= 0;
			//	doReadAddressStall <= 1'b0;
			//end
			//else
			//begin
			//	delayReadCyclesCounter <= delayReadCyclesCounter + 1;
			//end
				
            readAddressChannelEnabled <= 1'b1;
			BREADY <= 1'b0;	
            doReadAddressStall <= 1'b0;
		end
	end
end

always @ (posedge ACLK)
begin
	if ((ARESET != 1'b0) && (SET_ACCESS == 1'b1))
	begin
		if (doWriteDataStall == 1'b1)		// Stalling for 1 clock cycle before starting the write data transaction.
		begin
			//if (delayWriteCyclesCounter >= 1)		// Don't need the Delays when using Interconnect Arbitration.
			//begin
			//	doWriteDataStall <= 1'b0;
			//	delayWriteCyclesCounter <= 0;
			//end
			//else
			//begin
			//	delayWriteCyclesCounter <= delayWriteCyclesCounter + 1;
			//end
			
			AWVALID <= 1'b0;
			WID <= writeTransactionID;
			WVALID <= 1'b1;
			WLAST <= 1'b0;
			writeAddressARRAY <= 0;
			writeChannelEnabled <= 1'b1;
			doWriteDataStall <= 1'b0;
		end
	end
end

always @ (posedge ACLK)
begin
	if ((ARESET != 1'b0) && (SET_ACCESS == 1'b1))
	begin
		if (readAddressChannelEnabled == 1'b1)
		begin
			ARID <= readTransactionID;
			ARADDR <= 5'b00000;
			ARLEN <= 8'b00000011;    // ARLEN + 1 Beats in a single burst requested.
			ARSIZE <= 3'b000;        // Size of each Beat = 1 Byte. There are specific codes for each size.
			ARBURST <= 2'b01;        // 00 -> FIXED, 01 -> INCREMENT, 10 -> WRAP.
			ARVALID <= 1'b1;

			if (ARREADY == 1'b1)
			begin
				firstTimeInitArrayAddress <= 1'b1;
				RREADY <= 1'b1;
				readChannelEnabled <= 1'b1;
				readAddressChannelEnabled <= 1'b0;
			end
		end
	end
end

always @ (posedge ACLK)
begin
	if ((ARESET != 1'b0) && (SET_ACCESS == 1'b1))			
	begin
		if (readChannelEnabled == 1'b1)
		begin
			ARVALID <= 1'b0;

			if ((firstTimeInitArrayAddress == 1'b1) && (RVALID == 1'b1))
			begin
				readAddressARRAY <= 0;
				firstTimeInitArrayAddress <= 1'b0;
			end

			coefficientsPoly[readAddressARRAY] <= RDATA;	// Store the incoming data from the Slave.

			case (ARBURST)
				
				2'b00:	// FIXED Burst Type
				begin
					readAddressARRAY <= readAddressARRAY;
				end 

				2'b01:	// INCREMENT Burst Type
				begin			
					if ((RVALID == 1'b1) && (RRESP == 2'b00) && (RID == readTransactionID))
					begin
						if (readAddressARRAY < ARLEN)		
						begin
							readAddressARRAY <= readAddressARRAY + 1;
						end
					end
					
					if (readAddressARRAY >= ARLEN)
					begin
						//readAddressChannelEnabled <= 1'b1;	// Enable this for multiple seperate read transactions.
						performOperations <= 1'b1;
						ARID <= 4'bZ;
						ARADDR <= 5'bZ;
						ARLEN <= 8'bZ;    
						ARSIZE <= 3'bZ;       
						ARBURST <= 2'bZ;
						RREADY <= 1'b0; 
						readAddressARRAY <= 5'bZ;
						readChannelEnabled <= 1'b0;
						readTransactionID <= readTransactionID + 1;
					end
				end

				2'b10:	// WRAP Burst Type
				begin
					if ((RVALID == 1'b1) && (RRESP == 2'b00) && (RID == readTransactionID))
					begin
						if (readAddressARRAY < ARLEN)		
						begin
							readAddressARRAY <= readAddressARRAY + 1;
						end
					end
					
					if (readAddressARRAY >= ARLEN)
					begin
						readAddressARRAY <= 0;
					end
				end
			endcase	
		end
	end
end

always @ (posedge ACLK)	// I was working on write channel and streamlining it...
begin
	if ((ARESET != 1'b0) && (SET_ACCESS == 1'b1))			
	begin
		if (writeAddressChannelEnabled == 1'b1)
		begin
			AWID <= writeTransactionID;
			AWADDR <= 5'b00000;
			AWLEN <= 8'b00000011;    // AWLEN + 1 Beats in a single burst requested.
			AWSIZE <= 3'b000;        // Size of each Beat = 1 Byte. There are specific codes for each size.
			AWBURST <= 2'b01;        // 00 -> FIXED, 01 -> INCREMENT, 10 -> WRAP.
			AWVALID <= 1'b1;
			WLAST <= 1'b0;
			
			if (AWREADY == 1'b1)
			begin
				doWriteDataStall <= 1'b1;
				writeAddressChannelEnabled <= 1'b0;
			end
		end
	end
end

always @ (posedge ACLK)
begin
	if ((ARESET != 1'b0) && (SET_ACCESS == 1'b1))			
	begin
		if (writeChannelEnabled == 1'b1)
		begin
			AWVALID <= 1'b0;

			WDATA <= coefficientsPoly[writeAddressARRAY];

			case (AWBURST)
				
				2'b00:	// FIXED Burst Type
				begin
					readAddressARRAY <= readAddressARRAY;
				end 

				2'b01:	// INCREMENT Burst Type
				begin					
					if (WREADY == 1'b1) 
					begin
						writeAddressARRAY <= writeAddressARRAY + 1;

						if (writeAddressARRAY >= AWLEN)
						begin	
							writeResponseChannelEnabled <= 1'b1;
							WLAST <= 1'b1;
							WVALID <= 1'b0;
							writeAddressARRAY <= 5'bZ;
							writeChannelEnabled <= 1'b0;
						end
					end
				end

				2'b10:	// WRAP Burst Type
				begin
					if (WREADY == 1'b1) 
					begin
						writeAddressARRAY <= writeAddressARRAY + 1;

						if (writeAddressARRAY >= AWLEN)
						begin	
							writeAddressARRAY <= 0;
						end
					end
				end
			endcase	
		end
	end
end

always @ (posedge ACLK)
begin
	if ((ARESET != 1'b0) && (SET_ACCESS == 1'b1))			
	begin
		if (writeResponseChannelEnabled == 1'b1)
		begin
			AWID <= 4'bZ;
			AWADDR <= 5'bZ;
			AWLEN <= 8'bZ;    
			AWSIZE <= 3'bZ;       
			AWBURST <= 2'bZ; 
			WID <= 4'bZ;
			WDATA <= 8'bZ;
			WLAST <= 1'b0;

			BREADY <= 1'b1;

			if ((BVALID == 1'b1) && (BID == writeTransactionID))
			begin
				//doReadAddressStall <= 1'b1;                   // For Read -> Write Transactions and so on.
                //writeAddressChannelEnabled <= 1'b1;             // (Default) For repeated Write Transactions.
				writeStatusBRESP <= BRESP;
				WDATA <= 8'bZ;
				writeTransactionID <= writeTransactionID + 1;
				RELEASE_ACCESS <= 1'b1;							// Signal the Interconnect for the end of Slave Access turn.
				resetReleaseAccess <= 1'b1;						// Lower the Release signal again for the next Slave Access turn.
				writeResponseChannelEnabled <= 1'b0;
			end
		end
	end
end

always @ (posedge ACLK)
begin
	if (ARESET != 1'b0)		
	begin
		if (resetReleaseAccess == 1'b1)
		begin
            writeAddressChannelEnabled <= 1'b1;             // (Default) For repeated Write Transactions.
			BREADY <= 1'b0;	
			RELEASE_ACCESS <= 1'b0;
			resetReleaseAccess <= 1'b0;
		end
	end
end

always @ (posedge ACLK)	// Custom Mathematical Operation on the Polynomial's Coefficients
begin
	if ((performOperations == 1'b1) && (SET_ACCESS == 1'b1))
	begin
		for (arrayIndex=0; arrayIndex<4; arrayIndex=arrayIndex+1)
		begin
			coefficientsPoly[arrayIndex] <= coefficientsPoly[arrayIndex] + 2;
		end

		writeAddressChannelEnabled <= 1'b1;
		performOperations <= 1'b0;
	end
end

endmodule