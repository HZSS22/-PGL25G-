
module rgb2gray(
    input               clk,            // 像素时钟
    input               rst_n,          // 复位信号
    input               data_valid,     // 输入数据有效信号
    input       [15:0]  rgb_data,       // RGB565输入数据
    output reg          gray_valid,     // 灰度数据有效信号
    output reg  [7:0]   gray_data       // 8位灰度输出
);

// 内部信号定义
reg  [15:0] rgb_data_d;      // 输入数据寄存器
reg         data_valid_d;    // 有效信号寄存器

// 灰度计算中间变量
wire [7:0] red, green, blue;
wire [15:0] gray_temp;

// 提取RGB分量(从RGB565)
assign red   = {rgb_data_d[15:11], rgb_data_d[13:11]}; // R分量(5->8位)
assign green = {rgb_data_d[10:5],  rgb_data_d[6:5]};   // G分量(6->8位)
assign blue  = {rgb_data_d[4:0],   rgb_data_d[2:0]};   // B分量(5->8位)

// 灰度计算公式: Gray = 0.299*R + 0.587*G + 0.114*B
// 使用定点数运算，避免浮点数
assign gray_temp = (red * 77 + green * 150 + blue * 29) >> 8;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rgb_data_d <= 16'd0;
        data_valid_d <= 1'b0;
        gray_valid <= 1'b0;
        gray_data <= 8'd0;
    end
    else begin
        // 流水线第一级：寄存输入
        rgb_data_d <= rgb_data;
        data_valid_d <= data_valid;
        
        // 流水线第二级：输出结果
        gray_valid <= data_valid_d;
        gray_data <= gray_temp[7:0];
    end
end

endmodule