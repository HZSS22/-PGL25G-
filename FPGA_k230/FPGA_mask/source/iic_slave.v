module i2c_slave (
    input        clk,         // 系统时钟
    input        rst_n,       // 复位信号
    // I2C接口
    input        scl,         // I2C时钟
    inout        sda,         // I2C数据
    // 配置寄存器接口
    output reg   [7:0] reg_addr,  // 寄存器地址
    output reg   [7:0] reg_data,  // 寄存器数据
    output reg         reg_wr     // 写使能
);

// 状态定义
localparam IDLE    = 3'b000;
localparam ADDR    = 3'b001;
localparam ACK1    = 3'b010;
localparam REG     = 3'b011;
localparam ACK2    = 3'b100;
localparam DATA    = 3'b101;
localparam ACK3    = 3'b110;

// 寄存器定义
reg [2:0] state;
reg [2:0] bit_cnt;
reg [7:0] shift_reg;
reg       sda_out;
reg       sda_dir;  // 0: input, 1: output

// 同步SCL和SDA信号
reg [2:0] scl_sync;
reg [2:0] sda_sync;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        scl_sync <= 3'b000;
        sda_sync <= 3'b000;
    end else begin
        scl_sync <= {scl_sync[1:0], scl};
        sda_sync <= {sda_sync[1:0], sda};
    end
end

wire scl_rising = (scl_sync[2:1] == 2'b01);
wire scl_falling = (scl_sync[2:1] == 2'b10);
wire sda_in = sda_sync[2];

assign sda = sda_dir ? sda_out : 1'bz;

// 主状态机 - 完全按位处理
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        sda_dir <= 0;
        sda_out <= 1;
        bit_cnt <= 0;
        shift_reg <= 0;
        reg_addr <= 0;
        reg_data <= 0;
        reg_wr <= 0;
    end else begin
        reg_wr <= 0;  // 默认为无写操作
        
        // 检测起始条件 (SCL高电平时SDA下降沿)
        if (scl_rising && sda_in == 1'b0 && state == IDLE) begin
            state <= ADDR;
            bit_cnt <= 0;
            shift_reg <= 0;
        end
        
        // 检测停止条件 (SCL高电平时SDA上升沿)
        if (scl_rising && sda_in == 1'b1 && state != IDLE) begin
            state <= IDLE;
            sda_dir <= 0;
        end
        
        // 在SCL下降沿处理数据位
        if (scl_falling) begin
            case (state)
                IDLE: begin
                    // 空闲状态不执行操作
                end
                    
                ADDR: begin
                    // 逐位接收从机地址
                    case (bit_cnt)
                        0: shift_reg[7] <= sda_in;
                        1: shift_reg[6] <= sda_in;
                        2: shift_reg[5] <= sda_in;
                        3: shift_reg[4] <= sda_in;
                        4: shift_reg[3] <= sda_in;
                        5: shift_reg[2] <= sda_in;
                        6: shift_reg[1] <= sda_in;
                        7: begin
                            shift_reg[0] <= sda_in;
                            state <= ACK1;
                        end
                    endcase
                    if (bit_cnt < 7) bit_cnt <= bit_cnt + 1;
                end
                
                ACK1: begin
                    // 地址匹配检查 (以7'h30为例)
                    if (shift_reg[7:1] == 7'h30) begin
                        sda_dir <= 1;
                        sda_out <= 0;  // 发送ACK
                    end
                    state <= shift_reg[0] ? IDLE : REG; // R/W位判断
                    bit_cnt <= 0;
                end
                
                REG: begin
                    // 逐位接收寄存器地址
                    case (bit_cnt)
                        0: shift_reg[7] <= sda_in;
                        1: shift_reg[6] <= sda_in;
                        2: shift_reg[5] <= sda_in;
                        3: shift_reg[4] <= sda_in;
                        4: shift_reg[3] <= sda_in;
                        5: shift_reg[2] <= sda_in;
                        6: shift_reg[1] <= sda_in;
                        7: begin
                            shift_reg[0] <= sda_in;
                            state <= ACK2;
                        end
                    endcase
                    if (bit_cnt < 7) bit_cnt <= bit_cnt + 1;
                end
                
                ACK2: begin
                    sda_dir <= 1;
                    sda_out <= 0;  // 发送ACK
                    reg_addr <= shift_reg; // 保存寄存器地址
                    state <= DATA;
                    bit_cnt <= 0;
                end
                
                DATA: begin
                    // 逐位接收数据
                    case (bit_cnt)
                        0: shift_reg[7] <= sda_in;
                        1: shift_reg[6] <= sda_in;
                        2: shift_reg[5] <= sda_in;
                        3: shift_reg[4] <= sda_in;
                        4: shift_reg[3] <= sda_in;
                        5: shift_reg[2] <= sda_in;
                        6: shift_reg[1] <= sda_in;
                        7: begin
                            shift_reg[0] <= sda_in;
                            state <= ACK3;
                        end
                    endcase
                    if (bit_cnt < 7) bit_cnt <= bit_cnt + 1;
                end
                
                ACK3: begin
                    sda_dir <= 1;
                    sda_out <= 0;  // 发送ACK
                    reg_data <= shift_reg; // 保存接收数据
                    reg_wr <= 1;   // 触发写操作
                    state <= IDLE;  // 返回空闲状态
                end
            endcase
        end
    end
end

endmodule