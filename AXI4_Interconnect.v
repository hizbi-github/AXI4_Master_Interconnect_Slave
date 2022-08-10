`timescale 1ns / 1ns

// Task 2 Data Transfer between AXI4 based BRAM Slave and AXI4 based Master
// Hizbullah Khan
// [FA19-BCE-080]

module AXI4_Interconnect(clk, rst,

                         M1_ACLK, M1_ARESET, Master_1_Set, Master_1_Release,
                         M1_ARID, M1_ARADDR, M1_ARBURST, M1_ARVALID, M1_ARREADY, M1_ARLEN, M1_ARSIZE, // Read Address Channel
                         M1_RID, M1_RDATA, M1_RLAST, M1_RVALID, M1_RREADY, M1_RRESP,		          // Read Data Channel
                         M1_AWID, M1_AWADDR, M1_AWBURST, M1_AWVALID, M1_AWREADY, M1_AWLEN, M1_AWSIZE, // Write Address Channel
                         M1_WID, M1_WDATA, M1_WLAST, M1_WVALID, M1_WREADY, 				              // Write Data Channel
                         M1_BID, M1_BRESP, M1_BVALID, M1_BREADY,							          // Write Response Channel

                         M2_ACLK, M2_ARESET, Master_2_Set, Master_2_Release,
                         M2_ARID, M2_ARADDR, M2_ARBURST, M2_ARVALID, M2_ARREADY, M2_ARLEN, M2_ARSIZE,  // Read Address Channel
                         M2_RID, M2_RDATA, M2_RLAST, M2_RVALID, M2_RREADY, M2_RRESP,		           // Read Data Channel
                         M2_AWID, M2_AWADDR, M2_AWBURST, M2_AWVALID, M2_AWREADY, M2_AWLEN, M2_AWSIZE,  // Write Address Channel
                         M2_WID, M2_WDATA, M2_WLAST, M2_WVALID, M2_WREADY, 				               // Write Data Channel
                         M2_BID, M2_BRESP, M2_BVALID, M2_BREADY,                                               // Write Response Channel

                         S_ACLK, S_ARESET,
                         S_ARID, S_ARADDR, S_ARBURST, S_ARVALID, S_ARREADY, S_ARLEN, S_ARSIZE,	       // Read Address Channel
                         S_RID, S_RDATA, S_RLAST, S_RVALID, S_RREADY, S_RRESP,		                   // Read Data Channel
                         S_AWID, S_AWADDR, S_AWBURST, S_AWVALID, S_AWREADY, S_AWLEN, S_AWSIZE,         // Write Address Channel
                         S_WID, S_WDATA, S_WLAST, S_WVALID, S_WREADY, 			                       // Write Data Channel
                         S_BID, S_BRESP, S_BVALID, S_BREADY);							               // Write Response Channel

parameter memWidth = 8;
parameter memDepth = 32;
parameter addressLength = 5;		// Calculated by taking (log2) of "memDepth"
			
input clk;
input rst;

/////////// Interconnect's Circular Arbitration Ports ///////////

output [0:0] Master_1_Set;
input [0:0] Master_1_Release;
output [0:0] Master_2_Set;
input [0:0] Master_2_Release;

/////////// Master 1 Ports ///////////

output M1_ACLK;
output M1_ARESET;

input [3:0] M1_ARID;
input [addressLength-1:0] M1_ARADDR;	// Read Address Channel
input [1:0] M1_ARBURST;
input [0:0] M1_ARVALID;
output [0:0] M1_ARREADY;
input [7:0] M1_ARLEN;
input [2:0] M1_ARSIZE;

output [3:0] M1_RID;
output [memWidth-1:0] M1_RDATA;			// Read Data Channel
output [0:0] M1_RLAST;
output [0:0] M1_RVALID;
input [0:0] M1_RREADY;
output [1:0] M1_RRESP;

input [3:0] M1_AWID;
input [addressLength-1:0] M1_AWADDR;	// Write Address Channel
input [1:0] M1_AWBURST;
input [0:0] M1_AWVALID;
output [0:0] M1_AWREADY;
input [7:0] M1_AWLEN;
input [2:0] M1_AWSIZE;

input [3:0] M1_WID;
input [memWidth-1:0] M1_WDATA;		// Write Data Channel
input [0:0] M1_WVALID;
output [0:0] M1_WREADY;
input [0:0] M1_WLAST;

output [3:0] M1_BID;
output [1:0] M1_BRESP;						// Write Response Channel
output [0:0] M1_BVALID;
input [0:0] M1_BREADY;

/////////// Master 2 Ports ///////////

output M2_ACLK;
output M2_ARESET;

input [3:0] M2_ARID;
input [addressLength-1:0] M2_ARADDR;	// Read Address Channel
input [1:0] M2_ARBURST;
input [0:0] M2_ARVALID;
output [0:0] M2_ARREADY;
input [7:0] M2_ARLEN;
input [2:0] M2_ARSIZE;

output [3:0] M2_RID;
output [memWidth-1:0] M2_RDATA;			// Read Data Channel
output [0:0] M2_RLAST;
output [0:0] M2_RVALID;
input [0:0] M2_RREADY;
output [1:0] M2_RRESP;

input [3:0] M2_AWID;
input [addressLength-1:0] M2_AWADDR;	// Write Address Channel
input [1:0] M2_AWBURST;
input [0:0] M2_AWVALID;
output [0:0] M2_AWREADY;
input [7:0] M2_AWLEN;
input [2:0] M2_AWSIZE;

input [3:0] M2_WID;
input [memWidth-1:0] M2_WDATA;		// Write Data Channel
input [0:0] M2_WVALID;
output [0:0] M2_WREADY;
input [0:0] M2_WLAST;

output [3:0] M2_BID;
output [1:0] M2_BRESP;						// Write Response Channel
output [0:0] M2_BVALID;
input [0:0] M2_BREADY;

// Slave Wires

output S_ACLK;
output S_ARESET;

output [3:0] S_ARID;
output [addressLength-1:0] S_ARADDR;		// Read Address Channel
output [1:0] S_ARBURST;
output [0:0] S_ARVALID;
input [0:0] S_ARREADY;
output [7:0] S_ARLEN;	
output [2:0] S_ARSIZE;

input [3:0] S_RID;
input [memWidth-1:0] S_RDATA;		// Read Data Channel
input [0:0] S_RLAST;
input [0:0] S_RVALID;
output [0:0] S_RREADY;
input [1:0] S_RRESP;

output [3:0] S_AWID;
output [addressLength-1:0] S_AWADDR;		// Write Address Channel
output [1:0] S_AWBURST;
output [0:0] S_AWVALID;
input [0:0] S_AWREADY;
output [7:0] S_AWLEN;
output [2:0] S_AWSIZE;

output [3:0] S_WID;
output [memWidth-1:0] S_WDATA;				// Write Data Channel
output [0:0] S_WVALID;
input [0:0] S_WREADY;
output [0:0] S_WLAST;

input [3:0] S_BID;
input [1:0] S_BRESP;							// Write Response Channel
input [0:0] S_BVALID;
output [0:0] S_BREADY;

/////////// Round Robin Arbitration Signals & Logic ///////////

localparam totalMasters = 3;    // For two Masters (not using '0' index for Masters, hence actual Masters + 1).

reg [(totalMasters-1):0] masterIndex = 3'bZ;            // Keeps track of all the Masters.
reg [(totalMasters-1):0] currentMaster = 3'bZ;          // Master that currently has the access to the slave.
reg [0:0] setMastersAccess [0:(totalMasters-1)];        // Array of outgoing signals (one for each Master).
reg [0:0] releaseMastersAccess [0:(totalMasters-1)];    // Array of incoming signals (one from each Master).

reg [(totalMasters-1):0] Master_1 = 3'b001;     // Master 1 ID
reg [(totalMasters-1):0] Master_2 = 3'b010;     // Master 2 ID
//reg [(totalMasters-1):0] Master_3 = 3'b011;     // Master 3 ID 
//reg [(totalMasters-1):0] Master_4 = 3'b100;     // Master 4 ID 
//reg [(totalMasters-1):0] Master_5 = 3'b101;     // Master 5 ID 

assign Master_1_Set = setMastersAccess[1];      // Sending the access signals to Master 1.
assign Master_2_Set = setMastersAccess[2];      // Sending the access signals to Master 2.

always @ (posedge clk)
begin
    if (rst != 1'b0)       
    begin
        releaseMastersAccess[1] <= Master_1_Release;        // Reading release signals from Master 1.
        releaseMastersAccess[2] <= Master_2_Release;        // Reading release signals from Master 2.
    end
end

always @ (posedge clk)
begin
    if (rst == 1'b0)        // Setting all output signals to low on reset (active low)
    begin
        setMastersAccess[1] <= 1'bZ;
        setMastersAccess[2] <= 1'bZ;
        masterIndex <= 1;               // Prioritizing Master 1 to have first access to the Slave when starting.
        currentMaster <= Master_1;      // Doesn't need to be set now to grant priority. It just removes clashes 
        //currentMaster <= 3'bZ;        // in the signals when simulating. The wavedform will look clean.
    end
end

always @ (posedge clk)
begin
    if (rst != 1'b0)
    begin
       if (releaseMastersAccess[masterIndex] == 1'b0)
        begin
            setMastersAccess[masterIndex] <= 1'b1;      // Signal the Master that its their turn.
            currentMaster <= masterIndex;               // Allow the interconnection between the Master and the Slave
        end
        else if (releaseMastersAccess[masterIndex] == 1'b1)     // If the current Master no longer needs the access,
        begin                                                   // then grant access to the next Master.
            setMastersAccess[masterIndex] <= 1'b0;              // Signal the current Master that their turn is 
                                                                // indeed over.
            //currentMaster <= 3'bZ;               // Remove the interconnection between the Master and the Slave

            if (masterIndex < (totalMasters - 1))               
            begin
                masterIndex <= masterIndex + 1;                 // Move onto the next Master...
                currentMaster <= masterIndex + 1;               
            end
            else
            begin
                masterIndex <= 1;
                currentMaster <= 1;
            end
        end
    end
end

/////////// Master and Slave's Clock & Reset are always Assigned/Enabled ///////////

assign S_ACLK = clk;
assign S_ARESET = rst;

assign M1_ACLK = clk;
assign M1_ARESET = rst;

assign M2_ACLK = clk;
assign M2_ARESET = rst;

/////////// Master 1 and Master 2's Connection to Slave ///////////

/////////// Read Address Channel ///////////

assign S_ARID = (currentMaster == Master_1) ? M1_ARID : (currentMaster == Master_2) ? M2_ARID : 4'bZ;
assign S_ARADDR = (currentMaster == Master_1) ? M1_ARADDR : (currentMaster == Master_2) ? M2_ARADDR : 5'bZ;
assign S_ARBURST = (currentMaster == Master_1) ? M1_ARBURST : (currentMaster == Master_2) ? M2_ARBURST : 2'bZ;
assign S_ARVALID = (currentMaster == Master_1) ? M1_ARVALID : (currentMaster == Master_2) ? M2_ARVALID : 1'bZ;
assign S_ARLEN = (currentMaster == Master_1) ? M1_ARLEN : (currentMaster == Master_2) ? M2_ARLEN : 8'bZ;
assign S_ARSIZE = (currentMaster == Master_1) ? M1_ARSIZE : (currentMaster == Master_2) ? M2_ARSIZE : 3'bZ;

assign M1_ARREADY = (currentMaster == Master_1) ? S_ARREADY : 1'bZ;
assign M2_ARREADY = (currentMaster == Master_2) ? S_ARREADY : 1'bZ;

/////////// Read Data Channel ///////////

assign M1_RID = (currentMaster == Master_1) ? S_RID : 4'bZ;
assign M1_RDATA = (currentMaster == Master_1) ? S_RDATA : 8'bZ;
assign M1_RLAST = (currentMaster == Master_1) ? S_RLAST : 1'bZ;
assign M1_RVALID = (currentMaster == Master_1) ? S_RVALID : 1'bZ;
assign M1_RRESP = (currentMaster == Master_1) ? S_RRESP : 2'bZ;

assign M2_RID = (currentMaster == Master_2) ? S_RID : 4'bZ;
assign M2_RDATA = (currentMaster == Master_2) ? S_RDATA : 8'bZ;
assign M2_RLAST = (currentMaster == Master_2) ? S_RLAST : 1'bZ;
assign M2_RVALID = (currentMaster == Master_2) ? S_RVALID : 1'bZ;
assign M2_RRESP = (currentMaster == Master_2) ? S_RRESP : 2'bZ;

assign S_RREADY = (currentMaster == Master_1) ? M1_RREADY : (currentMaster == Master_2) ? M2_RREADY : 1'bZ;

/////////// Write Address Channel ///////////

assign S_AWID = (currentMaster == Master_1) ? M1_AWID : (currentMaster == Master_2) ? M2_AWID : 4'bZ;
assign S_AWADDR = (currentMaster == Master_1) ? M1_AWADDR : (currentMaster == Master_2) ? M2_AWADDR : 5'bZ;
assign S_AWBURST = (currentMaster == Master_1) ? M1_AWBURST : (currentMaster == Master_2) ? M2_AWBURST : 2'bZ;
assign S_AWVALID = (currentMaster == Master_1) ? M1_AWVALID : (currentMaster == Master_2) ? M2_AWVALID : 1'bZ;
assign S_AWLEN = (currentMaster == Master_1) ? M1_AWLEN : (currentMaster == Master_2) ? M2_AWLEN : 8'bZ;
assign S_AWSIZE = (currentMaster == Master_1) ? M1_AWSIZE : (currentMaster == Master_2) ? M2_AWSIZE : 3'bZ;

assign M1_AWREADY = (currentMaster == Master_1) ? S_AWREADY : 1'bZ;
assign M2_AWREADY = (currentMaster == Master_2) ? S_AWREADY : 1'bZ;

/////////// Write Data Channel ///////////

assign S_WID = (currentMaster == Master_1) ? M1_WID : (currentMaster == Master_2) ? M2_WID : 4'bZ;
assign S_WDATA = (currentMaster == Master_1) ? M1_WDATA : (currentMaster == Master_2) ? M2_WDATA : 8'bZ;
assign S_WVALID = (currentMaster == Master_1) ? M1_WVALID : (currentMaster == Master_2) ? M2_WVALID : 1'bZ;
assign S_WLAST = (currentMaster == Master_1) ? M1_WLAST : (currentMaster == Master_2) ? M2_WLAST : 1'bZ;

assign M1_WREADY = (currentMaster == Master_1) ? S_WREADY : 1'bZ;
assign M2_WREADY = (currentMaster == Master_2) ? S_WREADY : 1'bZ;

/////////// Write Response Channel ///////////

assign M1_BID = (currentMaster == Master_1) ? S_BID : 4'bZ;
assign M1_BRESP = (currentMaster == Master_1) ? S_BRESP : 2'bZ;
assign M1_BVALID = (currentMaster == Master_1) ? S_BVALID : 1'bZ;

assign M2_BID = (currentMaster == Master_2) ? S_BID : 4'bZ;
assign M2_BRESP = (currentMaster == Master_2) ? S_BRESP : 2'bZ;
assign M2_BVALID = (currentMaster == Master_2) ? S_BVALID : 1'bZ;

assign S_BREADY = (currentMaster == Master_1) ? M1_BREADY : (currentMaster == Master_2) ? M2_BREADY : 1'bZ;

endmodule

























/////////// Original Interconnect Circular Arbiter (didn't work as intended) ///////////

//always @ (posedge clk)
//begin
//    if (rst != 1'b0)
//    begin
//         if ((Master_1_Release == 1'b0) && (nextMaster == Master_2))
//        begin
//            Master_1_Set <= 1'b1;
//            Master_2_Set <= 1'b0;
//            currentMaster <= Master_1;
//        end
//        else
//        begin
//            Master_1_Set <= 1'b0;
//            currentMaster <= Master_2;
//            nextMaster <= Master_1;
//        end

//         if ((Master_2_Release == 1'b0) && (nextMaster == Master_1))
//        begin
//            Master_2_Set <= 1'b1;
//            Master_1_Set <= 1'b0;
//            currentMaster <= Master_2;
//        end
//        else
//        begin
//            Master_2_Set <= 1'b0;
//            currentMaster <= Master_1;
//            nextMaster <= Master_2;
//        end
//    end
//end



/////////// Original Single Master and Slave Interconnection Template ///////////

//assign M_ACLK = clk;

//assign M_ARESET = rst;

//assign S_ARID = M_ARID;
//assign S_ARADDR = M_ARADDR;
//assign S_ARBURST = M_ARBURST;
//assign S_ARVALID = M_ARVALID;
//assign M_ARREADY = S_ARREADY;
//assign S_ARLEN = M_ARLEN;
//assign S_ARSIZE = M_ARSIZE;

//assign M_RID = S_RID;
//assign M_RDATA = S_RDATA;
//assign M_RLAST = S_RLAST;
//assign M_RVALID = S_RVALID;
//assign S_RREADY = M_RREADY;
//assign M_RRESP = S_RRESP;

//assign S_AWID = M_AWID;
//assign S_AWADDR = M_AWADDR;
//assign S_AWBURST = M_AWBURST;
//assign S_AWVALID = M_AWVALID;
//assign M_AWREADY = S_AWREADY;
//assign S_AWLEN = M_AWLEN;
//assign S_AWSIZE = M_AWSIZE;

//assign S_WID = M_WID;
//assign S_WDATA = M_WDATA;
//assign S_WVALID = M_WVALID;
//assign M_WREADY = S_WREADY;
//assign S_WLAST = M_WLAST;

//assign M_BID = S_BID;
//assign M_BRESP = S_BRESP;
//assign M_BVALID = S_BVALID;
//assign S_BREADY = M_BREADY;

/////////// Ternary Assignment Template ///////////

//(currentMaster == Master_1) ?  : (currentMaster == Master_2) ?  : 5'bZ;

//(currentMaster == Master_1) ?  : 4'bZ;