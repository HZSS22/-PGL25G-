module mask_top (
    input        clk_50m,        // 50MHzϵͳʱ��
    input        rst_n,          // ϵͳ��λ
    // ��ʵ����ͷ�ӿ�
    input        cam_pclk,       // ����ͷ����ʱ��
    input        cam_vsync,      // ����ͷ��ͬ��
    input        cam_href,       // ����ͷ��ͬ��
    input [7:0]  cam_data,       // ����ͷ����
    // I2C�ӿڣ����ӵ�K230��
    input        i2c_scl,        // I2Cʱ��
    inout        i2c_sda,        // I2C����
    // ����ͷ����I2C�ӿ�
    output       cam_scl,        // ����ͷ����ʱ��
    inout        cam_sda,        // ����ͷ��������
    // DVP����ӿڣ����ӵ�K230��
    output       dvp_pclk,       // ����ʱ�����
    output       dvp_vsync,      // ��ͬ�����
    output       dvp_href,       // ��ͬ�����
    output [7:0] dvp_data        // �����������
);

// I2C�ӻ�ģ��
wire [7:0] reg_addr;
wire [7:0] reg_data;
wire       reg_wr;

i2c_slave u_i2c_slave (
    .clk      (clk_50m),
    .rst_n    (rst_n),
    .scl      (i2c_scl),
    .sda      (i2c_sda),
    .reg_addr (reg_addr),
    .reg_data (reg_data),
    .reg_wr   (reg_wr)
);

// ���üĴ����洢
reg [7:0] cam_reg [0:255];
integer i;  // ���ڳ�ʼ��ѭ��

always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        // ��ʼ�����мĴ���Ϊ0
        for (i = 0; i < 256; i = i + 1)
            cam_reg[i] <= 8'h0;
        
        // �����ض��Ĵ�����Ĭ��ֵ��ʹ��ʮ����������
        cam_reg[18] <= 8'h06; // COM7: ���RGB565��ʽ (0x12 = 18)
        // �������������������Ҫ��ʼ���ļĴ���
    end else if (reg_wr) begin
        cam_reg[reg_addr] <= reg_data;
    end
end

// ʵ��������ͷ����ģ��
wire init_done;  // ����ͷ��ʼ�����

ov7725_dri u_ov7725_dri (
    .clk      (clk_50m),
    .rst_n    (rst_n),
    .init_done(init_done),
    .cam_scl  (cam_scl),
    .cam_sda  (cam_sda)
);

// ����ͷ�ɼ�����ģ��
wire [10:0] h_pixel;
wire [10:0] v_pixel;
wire [27:0] ddr3_addr_max;
wire        cmos_frame_vsync;
wire        cmos_frame_href;
wire        cmos_frame_valid;
wire [15:0] cmos_frame_data;

cmos_data_top u_cmos_data_top (
    .rst_n            (rst_n),
    .lcd_id           (16'h0),        // δʹ��
    .h_disp           (11'd640),      // ˮƽ�ߴ磨�ɴӼĴ�����̬���ã�
    .v_disp           (11'd480),      // ��ֱ�ߴ�
    .cam_pclk         (cam_pclk),
    .cam_vsync        (cam_vsync),
    .cam_href         (cam_href),
    .cam_data         (cam_data),
    .h_pixel          (h_pixel),
    .v_pixel          (v_pixel),
    .ddr3_addr_max    (ddr3_addr_max),
    .cmos_frame_vsync (cmos_frame_vsync),
    .cmos_frame_href  (cmos_frame_href),
    .cmos_frame_valid (cmos_frame_valid),
    .cmos_frame_data  (cmos_frame_data)
);

// DVP����ģ��
dvp_tx u_dvp_tx (
    .clk          (cam_pclk),         // ʹ������ͷ����ʱ��
    .rst_n        (rst_n),
    .vsync_i      (cmos_frame_vsync),
    .href_i       (cmos_frame_href),
    .data_valid_i (cmos_frame_valid),
    .data_i       (cmos_frame_data),  // 16λ����������
    .dvp_pclk     (dvp_pclk),
    .dvp_vsync    (dvp_vsync),
    .dvp_href     (dvp_href),
    .dvp_data     (dvp_data)
);

endmodule