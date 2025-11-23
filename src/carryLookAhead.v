module carryLookAhead#(
    parameter N = 32,
    parameter BLOCK = 4
)(
    input wire [N-1:0]a, b,
    input wire cin,
    output wire [N-1:0]sum,
    output wire cout
);

    localparam NUM_BLOCK = (N + BLOCK - 1) / BLOCK;
    wire [N-1:0]p, g;
    wire [NUM_BLOCK-1:0]P, G;
    wire [NUM_BLOCK:0]C;
    reg prod;
    reg [N:0]c;
    reg [NUM_BLOCK-1:0]P_reg, G_reg;
    genvar i;
    integer j, k, l, start, end_;

    generate
        for(i = 0; i < N; i = i + 1) begin : BIT_PG
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
        end
    endgenerate

    always @(*) begin
        for (j = 0; j < NUM_BLOCK; j = j + 1) begin
            P_reg[j] = 1'b1;
            G_reg[j] = 1'b0;

            start = j * BLOCK;
            end_ = (start + BLOCK - 1 < N) ? start + BLOCK - 1 : N - 1;

            for (k = start; k <= end_; k = k + 1) begin
                P_reg[j] = P_reg[j] & p[k];
            end

            G_reg[j] = 1'b0;
            for(k = start; k <= end_; k = k + 1) begin
                prod = 1'b1;
                for (l = k + 1; l <= end_; l = l + 1) begin
                    prod = prod & p[l];
                end
                G_reg[j] = G_reg[j] | (g[k] & prod);
            end
        end
    end

    assign P = P_reg;
    assign G = G_reg;
    assign C[0] = cin;

    generate
        for(i = 0; i < NUM_BLOCK; i = i + 1) begin
            assign C[i + 1] = G[i] | (P[i] & C[i]);
        end
    endgenerate

    always @(*) begin
        c[0] = cin;
        for (j = 0; j < NUM_BLOCK; j = j + 1) begin                
            start = j * BLOCK;
            end_ = (start + BLOCK - 1 < N) ? start + BLOCK - 1 : N-1;
            c[start] = C[j];

            for (k = start; k <= end_; k = k + 1) begin
                c[k + 1] = g[k] | (p[k] & c[k]);
            end
        end
    end

    generate
        for(i = 0; i < N; i = i + 1) begin : SUM_BITS
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
    assign cout = c[N];
    
endmodule