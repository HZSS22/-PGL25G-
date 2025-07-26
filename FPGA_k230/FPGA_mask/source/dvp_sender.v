module dvp_tx(
    input         clk,           // 像素时钟 (25MHz)
    input         rst_n,         // 复位信号
    // 图像输入接口
    input         vsync_i,       // 输入场同步
    input         href_i,        // 输入行同步
    input         data_valid_i,  // 数据有效
    input  [15:0] data_i,        // 输入像素数据 (RGB565)
    // DVP输出接口
    output        dvp_pclk,      // 像素时钟输出
    output        dvp_vsync,     // 场同步输出
    output        dvp_href,      // 行同步输出
    output [7:0]  dvp_data       // 像素数据输出 (8位)
);

// 寄存器定义
reg [3:0] state;
reg [7:0] data_out;
reg vsync_reg, href_reg;
reg [3:0] cnt;  // 位计数器

// 状态定义
localparam IDLE  = 4'b0001;
localparam HIGH  = 4'b0010;  // 发送高字节
localparam LOW   = 4'b0100;  // 发送低字节
localparam WAIT  = 4'b1000;  // 等待下一个数据

// 输出时钟直接连接
assign dvp_pclk = clk;

// DVP输出信号
assign dvp_vsync = vsync_reg;
assign dvp_href  = href_reg;
assign dvp_data  = data_out;

// 主状态机
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        data_out <= 8'h00;
        vsync_reg <= 1'b0;
        href_reg <= 1'b0;
        cnt <= 4'd0;
    end else begin
        // 同步信号直通
        vsync_reg <= vsync_i;
        href_reg <= href_i;
        
        case(state)
            IDLE: begin
                data_out <= 8'h00;
                cnt <= 4'd0;
                if (data_valid_i) begin
                    state <= HIGH;
                    // 准备输出高字节
                    data_out[7] <= data_i[15];
                end
            end
            HIGH: begin
                if (cnt < 4'd7) begin
                    cnt <= cnt + 1'b1;
                    // 逐位输出高字节
                    case(cnt)
                        4'd0: data_out[6] <= data_i[14];
                        4'd1: data_out[5] <= data_i[13];
                        4'd2: data_out[4] <= data_i[12];
                        4'd3: data_out[3] <= data_i[11];
                        4'd4: data_out[2] <= data_i[10];
                        4'd5: data_out[1] <= data_i[9];
                        4'd6: data_out[0] <= data_i[8];
                    endcase
                end else begin
                    state <= LOW;
                    cnt <= 4'd0;
                    // 准备输出低字节的第一位
                    data_out[7] <= data_i[7];
                end
            end
            LOW: begin
                if (cnt < 4'd7) begin
                    cnt <= cnt + 1'b1;
                    // 逐位输出低字节
                    case(cnt)
                        4'd0: data_out[6] <= data_i[6];
                        4'd1: data_out[5] <= data_i[5];
                        4'd2: data_out[4] <= data_i[4];
                        4'd3: data_out[3] <= data_i[3];
                        4'd4: data_out[2] <= data_i[2];
                        4'd5: data_out[1] <= data_i[1];
                        4'd6: data_out[0] <= data_i[0];
                    endcase
                end else begin
                    if (data_valid_i) begin
                        state <= HIGH;
                        cnt <= 4'd0;
                        // 准备输出下一个高字节的第一位
                        data_out[7] <= data_i[15];
                    end else begin
                        state <= IDLE;
                        data_out <= 8'h00;
                    end
                end
            end
            default: state <= IDLE;
        endcase
    end
end

endmodule