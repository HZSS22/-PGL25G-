module cmos_data_top(
    input                 rst_n            ,  
    input       [15:0]    lcd_id           ,  
    input       [10:0]    h_disp           ,  
    input       [10:0]    v_disp           ,      
    //����ͷ�ӿ�                           
    input                 cam_pclk         ,  
    input                 cam_vsync        ,  
    input                 cam_href         ,  
    input       [7:0]     cam_data         ,                      
    //�û��ӿ� 
    output      [10:0]    h_pixel          ,  
    output      [10:0]    v_pixel          ,      
    output      [27:0]    ddr3_addr_max    ,    
    output                cmos_frame_vsync ,  
    output                cmos_frame_href   ,  
    output                cmos_frame_valid ,  
    output      [15:0]    cmos_frame_data    
    );

//wire define       
wire         data_valid;         //�����ü�������ͷ���� 
wire  [15:0] wr_data;            //û�о����ü�������ͷ���� 
wire  [15:0] rgb_data;           // RGB565����
wire         rgb_valid;          // RGB������Ч�ź�
wire         gray_valid;         // �Ҷ�������Ч�ź�
wire  [7:0]  gray_data;          // 8λ�Ҷ�����
wire  [15:0] gray_data_16bit;    // 16λ�Ҷ����ݣ�RGB565��ʽ��

//*****************************************************
//**                    main code
//*****************************************************   

//����ͷ���ݲü�ģ��
cmos_tailor  u_cmos_tailor(
    .rst_n                 (rst_n),  
    .lcd_id                (lcd_id),
    .cam_pclk              (cam_pclk),
    .cam_vsync             (cmos_frame_vsync),
    .cam_href              (cmos_frame_href),
    .cam_data              (wr_data), 
    .cam_data_valid        (data_valid),
    .h_disp                (h_disp),
    .v_disp                (v_disp),  
    .h_pixel               (h_pixel),
    .v_pixel               (v_pixel), 
    .ddr3_addr_max         (ddr3_addr_max),
    .cmos_frame_valid      (rgb_valid),     // ��Ϊ�ڲ��ź�     
    .cmos_frame_data       (rgb_data)       // RGB565����
);

//����ͷ���ݲɼ�ģ��
cmos_capture_data u_cmos_capture_data(
    .rst_n                 (rst_n),
    .cam_pclk              (cam_pclk),   
    .cam_vsync             (cam_vsync),
    .cam_href              (cam_href),
    .cam_data              (cam_data),           
    .cmos_frame_vsync      (cmos_frame_vsync),
    .cmos_frame_href       (cmos_frame_href),
    .cmos_frame_valid      (data_valid),     
    .cmos_frame_data       (wr_data)             
);

// RGB565ת�Ҷ�ģ��
rgb2gray u_rgb2gray(
    .clk          (cam_pclk),       // ʹ������ͷ����ʱ��
    .rst_n        (rst_n),          // ��λ�ź�
    .data_valid   (rgb_valid),      // ʹ�òü����������Ч�ź�
    .rgb_data     (rgb_data),       // RGB565��������
    .gray_valid   (gray_valid),      // �Ҷ�������Ч�ź�
    .gray_data    (gray_data)       // 8λ�Ҷ����
);

// ��8λ�Ҷ�תΪ16λRGB565�Ҷȸ�ʽ
assign gray_data_16bit = {
    gray_data[7:3],  // R (5-bit)
    gray_data[7:2],  // G (6-bit)
    gray_data[7:3]   // B (5-bit)
};

// ����Ҷ�����
assign cmos_frame_data = gray_valid ? gray_data_16bit : 16'h0000;
assign cmos_frame_valid = gray_valid;

endmodule