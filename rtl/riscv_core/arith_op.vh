
`define ALU_FUNC_BIT 5
`define add `ALU_FUNC_BIT'b0000
`define sub `ALU_FUNC_BIT'b0001
`define lt `ALU_FUNC_BIT'b0010
`define ltu `ALU_FUNC_BIT'b0011
`define op_xor `ALU_FUNC_BIT'b0100
`define op_or `ALU_FUNC_BIT'b0101
`define op_and `ALU_FUNC_BIT'b0110
`define sll `ALU_FUNC_BIT'b0111
`define srl `ALU_FUNC_BIT'b1000
`define sra `ALU_FUNC_BIT'b1001
`define eq  `ALU_FUNC_BIT'b1010

`define neq  `ALU_FUNC_BIT'b11010
`define ge  `ALU_FUNC_BIT'b10010
`define geu  `ALU_FUNC_BIT'b10011

`define Br_OP_BIT 3
`define Br_Lt `Br_OP_BIT'b001
`define Br_Ltu `Br_OP_BIT'b011
`define Br_Ge `Br_OP_BIT'b101
`define Br_Geu `Br_OP_BIT'b111

`define Br_Eq `Br_OP_BIT'b010
`define Br_NEq `Br_OP_BIT'b110
