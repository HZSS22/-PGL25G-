
module rgb2gray(
    input               clk,            // ����ʱ��
    input               rst_n,          // ��λ�ź�
    input               data_valid,     // ����������Ч�ź�
    input       [15:0]  rgb_data,       // RGB565��������
    output reg          gray_valid,     // �Ҷ�������Ч�ź�
    output reg  [7:0]   gray_data       // 8λ�Ҷ����
);

// �ڲ��źŶ���
reg  [15:0] rgb_data_d;      // �������ݼĴ���
reg         data_valid_d;    // ��Ч�źżĴ���

// �Ҷȼ����м����
wire [7:0] red, green, blue;
wire [15:0] gray_temp;

// ��ȡRGB����(��RGB565)
assign red   = {rgb_data_d[15:11], rgb_data_d[13:11]}; // R����(5->8λ)
assign green = {rgb_data_d[10:5],  rgb_data_d[6:5]};   // G����(6->8λ)
assign blue  = {rgb_data_d[4:0],   rgb_data_d[2:0]};   // B����(5->8λ)

// �Ҷȼ��㹫ʽ: Gray = 0.299*R + 0.587*G + 0.114*B
// ʹ�ö��������㣬���⸡����
assign gray_temp = (red * 77 + green * 150 + blue * 29) >> 8;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rgb_data_d <= 16'd0;
        data_valid_d <= 1'b0;
        gray_valid <= 1'b0;
        gray_data <= 8'd0;
    end
    else begin
        // ��ˮ�ߵ�һ�����Ĵ�����
        rgb_data_d <= rgb_data;
        data_valid_d <= data_valid;
        
        // ��ˮ�ߵڶ�����������
        gray_valid <= data_valid_d;
        gray_data <= gray_temp[7:0];
    end
end

endmodule