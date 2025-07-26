module mask_top (
    input        clk_50m,        // 50MHz系统时钟
    input        rst_n,          // 系统复位
    // 真实摄像头接口
    input        cam_pclk,       // 摄像头像素时钟
    input        cam_vsync,      // 摄像头场同步
    input        cam_href,       // 摄像头行同步
    input [7:0]  cam_data,       // 摄像头数据
    // I2C接口（连接到K230）
    input        i2c_scl,        // I2C时钟
    inout        i2c_sda,        // I2C数据
    // 摄像头配置I2C接口
    output       cam_scl,        // 摄像头配置时钟
    inout        cam_sda,        // 摄像头配置数据
    // DVP输出接口（连接到K230）
    output       dvp_pclk,       // 像素时钟输出
    output       dvp_vsync,      // 场同步输出
    output       dvp_href,       // 行同步输出
    output [7:0] dvp_data        // 像素数据输出
);

// I2C从机模块
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

// 配置寄存器存储
reg [7:0] cam_reg [0:255];
integer i;  // 用于初始化循环

always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        // 初始化所有寄存器为0
        for (i = 0; i < 256; i = i + 1)
            cam_reg[i] <= 8'h0;
        
        // 设置特定寄存器的默认值（使用十进制索引）
        cam_reg[18] <= 8'h06; // COM7: 输出RGB565格式 (0x12 = 18)
        // 可以在这里添加其他需要初始化的寄存器
    end else if (reg_wr) begin
        cam_reg[reg_addr] <= reg_data;
    end
end

// 实例化摄像头驱动模块
wire init_done;  // 摄像头初始化完成

ov7725_dri u_ov7725_dri (
    .clk      (clk_50m),
    .rst_n    (rst_n),
    .init_done(init_done),
    .cam_scl  (cam_scl),
    .cam_sda  (cam_sda)
);

// 摄像头采集处理模块
wire [10:0] h_pixel;
wire [10:0] v_pixel;
wire [27:0] ddr3_addr_max;
wire        cmos_frame_vsync;
wire        cmos_frame_href;
wire        cmos_frame_valid;
wire [15:0] cmos_frame_data;

cmos_data_top u_cmos_data_top (
    .rst_n            (rst_n),
    .lcd_id           (16'h0),        // 未使用
    .h_disp           (11'd640),      // 水平尺寸（可从寄存器动态配置）
    .v_disp           (11'd480),      // 垂直尺寸
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

// DVP发送模块
dvp_tx u_dvp_tx (
    .clk          (cam_pclk),         // 使用摄像头像素时钟
    .rst_n        (rst_n),
    .vsync_i      (cmos_frame_vsync),
    .href_i       (cmos_frame_href),
    .data_valid_i (cmos_frame_valid),
    .data_i       (cmos_frame_data),  // 16位处理后的数据
    .dvp_pclk     (dvp_pclk),
    .dvp_vsync    (dvp_vsync),
    .dvp_href     (dvp_href),
    .dvp_data     (dvp_data)
);

endmodule