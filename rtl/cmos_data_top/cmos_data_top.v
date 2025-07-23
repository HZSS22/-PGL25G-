module cmos_data_top(
    input                 rst_n            ,
    input       [15:0]    lcd_id           ,
    input       [10:0]    h_disp           ,
    input       [10:0]    v_disp           ,     
    input                 cam_pclk         ,
    input                 cam_vsync        ,
    input                 cam_href         ,
    input       [7:0]     cam_data         ,                      
    output      [10:0]    h_pixel          ,
    output      [10:0]    v_pixel          ,    
    output      [27:0]    ddr3_addr_max     , 
    output                cmos_frame_vsync ,
    output                cmos_frame_href  ,
    output                cmos_frame_valid ,
    output       [15:0]   cmos_frame_data     
);

// 新增灰度转换信号
wire         gray_valid;
wire  [7:0]  gray_data;
wire  [15:0] gray_data_16bit;  // 8位转16位

// 实例化灰度转换模块
rgb_to_gray u_rgb_to_gray(
    .clk          (cam_pclk),
    .rst_n        (rst_n),
    .rgb565       (wr_data),
    .pixel_valid  (data_valid),
    .use_precise  (1'b1),       // 使用精确算法
    .r_coeff      (8'd77),      // R分量系数
    .g_coeff      (8'd150),     // G分量系数
    .b_coeff      (8'd29),      // B分量系数
    .gray         (gray_data),
    .gray_valid   (gray_valid)
);

// 将8位灰度数据转为16位（高8位=低8位）
assign gray_data_16bit = {gray_data, gray_data};

// 其他模块保持不变
wire         data_valid;
wire  [15:0] wr_data;

cmos_tailor u_cmos_tailor(
    .rst_n            (rst_n),
    .lcd_id           (lcd_id),
    .cam_pclk         (cam_pclk),
    .cam_vsync        (cmos_frame_vsync),
    .cam_href         (cmos_frame_href),
    .cam_data         (gray_valid ? gray_data_16bit : wr_data), // 灰度优先
    .cam_data_valid   (gray_valid ? gray_valid : data_valid),
    .h_disp           (h_disp),
    .v_disp           (v_disp),  
    .h_pixel          (h_pixel),
    .v_pixel          (v_pixel), 
    .ddr3_addr_max    (ddr3_addr_max),
    .cmos_frame_valid (cmos_frame_valid),     
    .cmos_frame_data  (cmos_frame_data)                
);

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
       
endmodule