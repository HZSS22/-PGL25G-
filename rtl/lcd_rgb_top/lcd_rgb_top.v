module lcd_rgb_top(
    input              sys_clk,
    input              sys_rst_n,
    input              sys_init_done,
    input       [15:0] lcd_id,
    output             lcd_hs,
    output             lcd_vs,
    output             lcd_de,
    inout       [23:0] lcd_rgb,      // 24位RGB总线
    output             lcd_bl,
    output             lcd_rst,
    output             lcd_pclk,
    output             lcd_clk,
    output             out_vsync,
    input       [10:0] h_disp,
    input       [10:0] v_disp,
    output      [10:0] pixel_xpos,
    output      [10:0] pixel_ypos,
    input       [15:0] data_in,     // 输入数据（16位）
    input              data_req
);

// 修复1：正确定义RGB565信号
wire [15:0] lcd_rgb_565;  // 声明为16位向量

// 灰度显示处理
reg [23:0] lcd_rgb_reg;
always @(posedge lcd_clk) begin
    if(data_req) begin
        // 灰度模式：将8位数据复制到RGB三个通道
        lcd_rgb_reg[23:16] <= data_in[7:0]; // R通道
        lcd_rgb_reg[15:8]  <= data_in[7:0]; // G通道
        lcd_rgb_reg[7:0]   <= data_in[7:0]; // B通道
    end
end

// 修复2：统一RGB输出路径
assign lcd_rgb = lcd_de ? lcd_rgb_reg : 24'bz;  // 使用灰度处理后的信号

//*****************************************************
//**                    main code
//***************************************************** 

// 区分大小屏的读请求 
assign data_req = (lcd_id == 16'h4342) ? data_req_small : data_req_big;   
 
// 区分大小屏的数据 
wire [15:0] lcd_data = (lcd_id == 16'h4342) ? data_in : lcd_data_w;  

// 修复3：移除错误的位置选择代码
// 原错误代码已移除：
// assign lcd_rgb_o = {lcd_rgb_565[15:11],3'b000,...}; 

// 像素数据方向切换
// 已整合到上面的assign lcd_rgb = ...;

// 修复4：添加必要的信号声明
wire [15:0] lcd_data_w;      // 大屏数据
wire data_req_small;         // 小屏数据请求
wire data_req_big;           // 大屏数据请求

// 时钟分频模块    
clk_div u_clk_div(
    .clk                    (sys_clk  ),
    .rst_n                  (sys_rst_n),
    .lcd_id                 (lcd_id   ),
    .lcd_pclk               (lcd_clk  )
);  

// 读LCD ID模块
rd_id u_rd_id(
    .clk                    (sys_clk  ),
    .rst_n                  (sys_rst_n),
    .lcd_rgb                (lcd_rgb),  // 直接使用24位总线
    .lcd_id                 (lcd_id   )
);  

// lcd驱动模块
lcd_driver u_lcd_driver(           
    .lcd_pclk       (lcd_clk),    
    .rst_n          (sys_rst_n & sys_init_done), 
    .lcd_id         (lcd_id),   
    .lcd_hs         (lcd_hs),       
    .lcd_vs         (lcd_vs),       
    .lcd_de         (lcd_de),       
    .lcd_rgb        (lcd_rgb_565),  // 16位RGB565输出
    .lcd_bl         (lcd_bl),
    .lcd_rst        (lcd_rst),
    .lcd_clk        (lcd_pclk),
    
    .pixel_data     (lcd_data), 
    .data_req       (data_req_small),
    .out_vsync      (out_vsync),
    .h_disp         (h_disp),
    .v_disp         (v_disp), 
    .pixel_xpos     (pixel_xpos), 
    .pixel_ypos     (pixel_ypos)
); 
 
// lcd显示模块 
lcd_display u_lcd_display(          
    .lcd_clk        (lcd_clk),    
    .sys_rst_n      (sys_rst_n & sys_init_done),
    .lcd_id         (lcd_id),  
    
    .pixel_xpos     (pixel_xpos),
    .pixel_ypos     (pixel_ypos),
    .h_disp         (h_disp),
    .v_disp         (v_disp), 	
    .cmos_data      (data_in),
    .lcd_data       (lcd_data_w),    
    .data_req       (data_req_big)
);   
               
endmodule