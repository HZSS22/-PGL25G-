module cmos_data_top(
    input                 rst_n            ,  
    input       [15:0]    lcd_id           ,  
    input       [10:0]    h_disp           ,  
    input       [10:0]    v_disp           ,      
    //摄像头接口                           
    input                 cam_pclk         ,  
    input                 cam_vsync        ,  
    input                 cam_href         ,  
    input       [7:0]     cam_data         ,                      
    //用户接口 
    output      [10:0]    h_pixel          ,  
    output      [10:0]    v_pixel          ,      
    output      [27:0]    ddr3_addr_max    ,    
    output                cmos_frame_vsync ,  
    output                cmos_frame_href   ,  
    output                cmos_frame_valid ,  
    output      [15:0]    cmos_frame_data    
    );

//wire define       
wire         data_valid;         //经过裁剪的摄像头数据 
wire  [15:0] wr_data;            //没有经过裁剪的摄像头数据 
wire  [15:0] rgb_data;           // RGB565数据
wire         rgb_valid;          // RGB数据有效信号
wire         gray_valid;         // 灰度数据有效信号
wire  [7:0]  gray_data;          // 8位灰度数据
wire  [15:0] gray_data_16bit;    // 16位灰度数据（RGB565格式）

//*****************************************************
//**                    main code
//*****************************************************   

//摄像头数据裁剪模块
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
    .cmos_frame_valid      (rgb_valid),     // 改为内部信号     
    .cmos_frame_data       (rgb_data)       // RGB565数据
);

//摄像头数据采集模块
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

// RGB565转灰度模块
rgb2gray u_rgb2gray(
    .clk          (cam_pclk),       // 使用摄像头像素时钟
    .rst_n        (rst_n),          // 复位信号
    .data_valid   (rgb_valid),      // 使用裁剪后的数据有效信号
    .rgb_data     (rgb_data),       // RGB565输入数据
    .gray_valid   (gray_valid),      // 灰度数据有效信号
    .gray_data    (gray_data)       // 8位灰度输出
);

// 将8位灰度转为16位RGB565灰度格式
assign gray_data_16bit = {
    gray_data[7:3],  // R (5-bit)
    gray_data[7:2],  // G (6-bit)
    gray_data[7:3]   // B (5-bit)
};

// 输出灰度数据
assign cmos_frame_data = gray_valid ? gray_data_16bit : 16'h0000;
assign cmos_frame_valid = gray_valid;

endmodule