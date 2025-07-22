module cmos_data_top(
    // 系统信号
    input                 rst_n,             // 复位信号
    input       [15:0]    lcd_id,            // LCD屏的ID号
    input       [10:0]    h_disp,            // LCD屏水平分辨率
    input       [10:0]    v_disp,            // LCD屏垂直分辨率      
    
    // 摄像头接口                           
    input                 cam_pclk,          // cmos数据像素时钟
    input                 cam_vsync,         // cmos场同步信号
    input                 cam_href,          // cmos行同步信号
    input       [7:0]     cam_data,                      
    
    // 用户接口 
    output      [10:0]    h_pixel,           // 存入ddr3的水平分辨率
    output      [10:0]    v_pixel,           // 存入ddr3的垂直分辨率    
    output      [27:0]    ddr3_addr_max,     // 存入DDR3的最大读写地址 
    output                cmos_frame_vsync,  // 帧有效信号    
    output                cmos_frame_href,   // 行有效信号
    output                cmos_frame_valid,  // 数据有效使能信号
    output      [15:0]    cmos_frame_data,  // 有效数据
    
    // 动态区域配置
    input                 region_config_en,
    input       [10:0]    region_left,
    input       [10:0]    region_right,
    input       [10:0]    region_top,
    input       [10:0]    region_bottom,
    
    // 卷积配置接口
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
    
    // 新增物体检测输出
    output                obj_detected,      // 物体检测完成标志
    output      [10:0]    obj_x,             // 物体中心X坐标
    output      [10:0]    obj_y,             // 物体中心Y坐标
    output      [7:0]     binary_out,        // 二值化输出
    output      [7:0]     debug_data         // 调试数据
);

// 内部信号定义
wire         data_valid;         // 经过裁剪的摄像头数据有效信号
wire  [15:0] wr_data;            // 未经过裁剪的摄像头数据 
wire  [15:0] conv_data;         // 卷积处理后的数据
wire         conv_valid;        // 卷积数据有效信号

wire  [15:0] processed_data;   // 预处理后的RGB565数据
wire         processed_valid;   // 预处理数据有效信号

//*****************************************************
//**                   主要模块实例化
//*****************************************************   

// 摄像头数据采集模块
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

// 摄像头数据裁剪模块
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

// 图像卷积处理模块
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

// 新增图像预处理模块（灰度化+边缘检测+二值化）
image_preprocess u_image_preprocess(
    .clk             (cam_pclk),
    .rst_n           (rst_n),
    .pixel_valid     (data_valid),
    .rgb565          (wr_data),
    .binary_out      (binary_out),
    .debug_data      (debug_data)
);

// 新增物体检测模块
object_detect u_object_detect(
    .clk            (cam_pclk),
    .rst_n          (rst_n),
    .pixel_valid    (data_valid),
    .binary_in      (binary_out),
    .obj_detected   (obj_detected),
    .obj_x          (obj_x),
    .obj_y          (obj_y)
);

// 数据输出选择
assign cmos_frame_valid = kernel_config_en ? conv_valid : data_valid;
assign cmos_frame_data = kernel_config_en ? conv_data : wr_data;

endmodule