module rgb2gray(
    input               clk,            // 像素时钟
    input               rst_n,          // 复位信号
    input               data_valid,     // 输入数据有效信号
    input       [15:0]  rgb_data,       // RGB565输入数据
    output reg          gray_valid,     // 灰度数据有效信号
    output reg  [7:0]   gray_data       // 8位灰度输出
);

// 提取RGB分量
wire [7:0] red, green, blue;

// 提取并扩展RGB分量
assign red   = {rgb_data[15:11], rgb_data[13:11]}; // R分量(5->8位)
assign green = {rgb_data[10:5],  rgb_data[6:5]};   // G分量(6->8位)
assign blue  = {rgb_data[4:0],   rgb_data[2:0]};   // B分量(5->8位)

// 灰度计算公式: Gray = 0.299*R + 0.587*G + 0.114*B
// 定点数实现: Gray = (77*R + 150*G + 29*B) >> 8
reg [16:0] gray_temp;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        gray_valid <= 1'b0;
        gray_data  <= 8'd0;
        gray_temp  <= 17'd0;
    end
    else if(data_valid) begin
        // 灰度计算流水线
        gray_temp <= red * 8'd77 + green * 8'd150 + blue * 8'd29;
        gray_data <= gray_temp[15:8]; // 右移8位
        gray_valid <= 1'b1;
    end
    else begin
        gray_valid <= 1'b0;
    end
end

endmodule