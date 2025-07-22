module cmos_data_top(
    // ϵͳ�ź�
    input                 rst_n,             // ��λ�ź�
    input       [15:0]    lcd_id,            // LCD����ID��
    input       [10:0]    h_disp,            // LCD��ˮƽ�ֱ���
    input       [10:0]    v_disp,            // LCD����ֱ�ֱ���      
    
    // ����ͷ�ӿ�                           
    input                 cam_pclk,          // cmos��������ʱ��
    input                 cam_vsync,         // cmos��ͬ���ź�
    input                 cam_href,          // cmos��ͬ���ź�
    input       [7:0]     cam_data,                      
    
    // �û��ӿ� 
    output      [10:0]    h_pixel,           // ����ddr3��ˮƽ�ֱ���
    output      [10:0]    v_pixel,           // ����ddr3�Ĵ�ֱ�ֱ���    
    output      [27:0]    ddr3_addr_max,     // ����DDR3������д��ַ 
    output                cmos_frame_vsync,  // ֡��Ч�ź�    
    output                cmos_frame_href,   // ����Ч�ź�
    output                cmos_frame_valid,  // ������Чʹ���ź�
    output      [15:0]    cmos_frame_data,  // ��Ч����
    
    // ��̬��������
    input                 region_config_en,
    input       [10:0]    region_left,
    input       [10:0]    region_right,
    input       [10:0]    region_top,
    input       [10:0]    region_bottom,
    
    // ������ýӿ�
    input       [3:0]     kernel_sel,
    input signed [7:0]    kernel_data_0,
    input signed [7:0]    kernel_data_1,
    input signed [7:0]    kernel_data_2,
    input signed [7:0]    kernel_data_3,
    input signed [7:0]    kernel_data_4,
    input signed [7:0]    kernel_data_5,
    input signed [7:0]    kernel_data_6,
    input signed [7:0]    kernel_data_7,
    input signed [7:0]    kernel_data_8,
    input                 kernel_config_en,
    
    // �������������
    output                obj_detected,      // ��������ɱ�־
    output      [10:0]    obj_x,             // ��������X����
    output      [10:0]    obj_y,             // ��������Y����
    output      [7:0]     binary_out,        // ��ֵ�����
    output      [7:0]     debug_data         // ��������
);

// �ڲ��źŶ���
wire         data_valid;         // �����ü�������ͷ������Ч�ź�
wire  [15:0] wr_data;            // δ�����ü�������ͷ���� 
wire  [15:0] conv_data;         // �������������
wire         conv_valid;        // ���������Ч�ź�

wire  [15:0] processed_data;   // Ԥ������RGB565����
wire         processed_valid;   // Ԥ����������Ч�ź�

//*****************************************************
//**                   ��Ҫģ��ʵ����
//*****************************************************   

// ����ͷ���ݲɼ�ģ��
cmos_capture_data u_cmos_capture_data(
    .rst_n            (rst_n),
    .cam_pclk         (cam_pclk),   
    .cam_vsync        (cam_vsync),
    .cam_href         (cam_href),
    .cam_data         (cam_data),           
    .cmos_frame_vsync (cmos_frame_vsync),
    .cmos_frame_href  (cmos_frame_href),
    .cmos_frame_valid (data_valid),     
    .cmos_frame_data  (wr_data)             
);

// ����ͷ���ݲü�ģ��
cmos_tailor u_cmos_tailor(
    .rst_n            (rst_n),  
    .lcd_id           (lcd_id),
    .cam_pclk         (cam_pclk),
    .cam_vsync        (cmos_frame_vsync),
    .cam_href         (cmos_frame_href),
    .cam_data         (wr_data), 
    .cam_data_valid   (data_valid),
    .h_disp           (h_disp),
    .v_disp           (v_disp),  
    .h_pixel          (h_pixel),
    .v_pixel          (v_pixel), 
    .ddr3_addr_max    (ddr3_addr_max),
    .cmos_frame_valid (data_valid),     
    .cmos_frame_data  (wr_data),
    .region_config_en (region_config_en),
    .region_left      (region_left),
    .region_right     (region_right),
    .region_top       (region_top),
    .region_bottom    (region_bottom)
);

// ͼ��������ģ��
image_convolution u_image_convolution(
    .clk              (cam_pclk),
    .rst_n            (rst_n),
    .data_valid       (data_valid),
    .pixel_in         (wr_data),
    .conv_valid       (conv_valid),
    .pixel_out        (conv_data),
    .kernel_sel       (kernel_sel),
    .kernel_data_0    (kernel_data_0),
    .kernel_data_1    (kernel_data_1),
    .kernel_data_2    (kernel_data_2),
    .kernel_data_3    (kernel_data_3),
    .kernel_data_4    (kernel_data_4),
    .kernel_data_5    (kernel_data_5),
    .kernel_data_6    (kernel_data_6),
    .kernel_data_7    (kernel_data_7),
    .kernel_data_8    (kernel_data_8),
    .kernel_config_en (kernel_config_en)
);

// ����ͼ��Ԥ����ģ�飨�ҶȻ�+��Ե���+��ֵ����
image_preprocess u_image_preprocess(
    .clk             (cam_pclk),
    .rst_n           (rst_n),
    .pixel_valid     (data_valid),
    .rgb565          (wr_data),
    .binary_out      (binary_out),
    .debug_data      (debug_data)
);

// ����������ģ��
object_detect u_object_detect(
    .clk            (cam_pclk),
    .rst_n          (rst_n),
    .pixel_valid    (data_valid),
    .binary_in      (binary_out),
    .obj_detected   (obj_detected),
    .obj_x          (obj_x),
    .obj_y          (obj_y)
);

// �������ѡ��
assign cmos_frame_valid = kernel_config_en ? conv_valid : data_valid;
assign cmos_frame_data = kernel_config_en ? conv_data : wr_data;

endmodule