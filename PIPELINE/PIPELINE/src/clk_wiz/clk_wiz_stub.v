// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.1.1 (lin64) Build 3900603 Fri Jun 16 19:30:25 MDT 2023
// Date        : Wed Mar 20 16:31:39 2024
// Host        : BrunoLaptop running 64-bit Ubuntu 22.04.4 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/bruno/Documents/Facultad/5to_anio/Arquitectura_de_Computadoras/Ejercicios_Verilog/sources/PIPELINE_Test/PIPELINE/src/clk_wiz/clk_wiz_stub.v
// Design      : clk_wiz
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tcpg236-3
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz(clk_out, reset, locked, clk_in)
/* synthesis syn_black_box black_box_pad_pin="reset,locked,clk_in" */
/* synthesis syn_force_seq_prim="clk_out" */;
  output clk_out /* synthesis syn_isclock = 1 */;
  input reset;
  output locked;
  input clk_in;
endmodule
