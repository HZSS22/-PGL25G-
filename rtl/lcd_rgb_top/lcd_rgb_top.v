module lcd_rgb_top(
    input              sys_clk,
    input              sys_rst_n,
    input              sys_init_done,
    input       [15:0] lcd_id,
    output             lcd_hs,
    output             lcd_vs,
    output             lcd_de,
    inout       [23:0] lcd_rgb,      // 24λRGB����
    output             lcd_bl,
    output             lcd_rst,
    output             lcd_pclk,
    output             lcd_clk,
    output             out_vsync,
    input       [10:0] h_disp,
    input       [10:0] v_disp,
    output      [10:0] pixel_xpos,
    output      [10:0] pixel_ypos,
    input       [15:0] data_in,     // �������ݣ�16λ��
    input              data_req
);

// �޸�1����ȷ����RGB565�ź�
wire [15:0] lcd_rgb_565;  // ����Ϊ16λ����

// �Ҷ���ʾ����
reg [23:0] lcd_rgb_reg;
always @(posedge lcd_clk) begin
    if(data_req) begin
        // �Ҷ�ģʽ����8λ���ݸ��Ƶ�RGB����ͨ��
        lcd_rgb_reg[23:16] <= data_in[7:0]; // Rͨ��
        lcd_rgb_reg[15:8]  <= data_in[7:0]; // Gͨ��
        lcd_rgb_reg[7:0]   <= data_in[7:0]; // Bͨ��
    end
end

// �޸�2��ͳһRGB���·��
assign lcd_rgb = lcd_de ? lcd_rgb_reg : 24'bz;  // ʹ�ûҶȴ������ź�

//*****************************************************
//**                    main code
//***************************************************** 

// ���ִ�С���Ķ����� 
assign data_req = (lcd_id == 16'h4342) ? data_req_small : data_req_big;   
 
// ���ִ�С�������� 
wire [15:0] lcd_data = (lcd_id == 16'h4342) ? data_in : lcd_data_w;  

// �޸�3���Ƴ������λ��ѡ�����
// ԭ����������Ƴ���
// assign lcd_rgb_o = {lcd_rgb_565[15:11],3'b000,...}; 

// �������ݷ����л�
// �����ϵ������assign lcd_rgb = ...;

// �޸�4����ӱ�Ҫ���ź�����
wire [15:0] lcd_data_w;      // ��������
wire data_req_small;         // С����������
wire data_req_big;           // ������������

// ʱ�ӷ�Ƶģ��    
clk_div u_clk_div(
    .clk                    (sys_clk  ),
    .rst_n                  (sys_rst_n),
    .lcd_id                 (lcd_id   ),
    .lcd_pclk               (lcd_clk  )
);  

// ��LCD IDģ��
rd_id u_rd_id(
    .clk                    (sys_clk  ),
    .rst_n                  (sys_rst_n),
    .lcd_rgb                (lcd_rgb),  // ֱ��ʹ��24λ����
    .lcd_id                 (lcd_id   )
);  

// lcd����ģ��
lcd_driver u_lcd_driver(           
    .lcd_pclk       (lcd_clk),    
    .rst_n          (sys_rst_n & sys_init_done), 
    .lcd_id         (lcd_id),   
    .lcd_hs         (lcd_hs),       
    .lcd_vs         (lcd_vs),       
    .lcd_de         (lcd_de),       
    .lcd_rgb        (lcd_rgb_565),  // 16λRGB565���
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
 
// lcd��ʾģ�� 
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