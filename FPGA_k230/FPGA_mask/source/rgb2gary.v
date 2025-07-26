module rgb2gray(
    input               clk,            // ����ʱ��
    input               rst_n,          // ��λ�ź�
    input               data_valid,     // ����������Ч�ź�
    input       [15:0]  rgb_data,       // RGB565��������
    output reg          gray_valid,     // �Ҷ�������Ч�ź�
    output reg  [7:0]   gray_data       // 8λ�Ҷ����
);

// ��ȡRGB����
wire [7:0] red, green, blue;

// ��ȡ����չRGB����
assign red   = {rgb_data[15:11], rgb_data[13:11]}; // R����(5->8λ)
assign green = {rgb_data[10:5],  rgb_data[6:5]};   // G����(6->8λ)
assign blue  = {rgb_data[4:0],   rgb_data[2:0]};   // B����(5->8λ)

// �Ҷȼ��㹫ʽ: Gray = 0.299*R + 0.587*G + 0.114*B
// ������ʵ��: Gray = (77*R + 150*G + 29*B) >> 8
reg [16:0] gray_temp;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        gray_valid <= 1'b0;
        gray_data  <= 8'd0;
        gray_temp  <= 17'd0;
    end
    else if(data_valid) begin
        // �Ҷȼ�����ˮ��
        gray_temp <= red * 8'd77 + green * 8'd150 + blue * 8'd29;
        gray_data <= gray_temp[15:8]; // ����8λ
        gray_valid <= 1'b1;
    end
    else begin
        gray_valid <= 1'b0;
    end
end

endmodule