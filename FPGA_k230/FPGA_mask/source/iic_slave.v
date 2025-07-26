module i2c_slave (
    input        clk,         // ϵͳʱ��
    input        rst_n,       // ��λ�ź�
    // I2C�ӿ�
    input        scl,         // I2Cʱ��
    inout        sda,         // I2C����
    // ���üĴ����ӿ�
    output reg   [7:0] reg_addr,  // �Ĵ�����ַ
    output reg   [7:0] reg_data,  // �Ĵ�������
    output reg         reg_wr     // дʹ��
);

// ״̬����
localparam IDLE    = 3'b000;
localparam ADDR    = 3'b001;
localparam ACK1    = 3'b010;
localparam REG     = 3'b011;
localparam ACK2    = 3'b100;
localparam DATA    = 3'b101;
localparam ACK3    = 3'b110;

// �Ĵ�������
reg [2:0] state;
reg [2:0] bit_cnt;
reg [7:0] shift_reg;
reg       sda_out;
reg       sda_dir;  // 0: input, 1: output

// ͬ��SCL��SDA�ź�
reg [2:0] scl_sync;
reg [2:0] sda_sync;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        scl_sync <= 3'b000;
        sda_sync <= 3'b000;
    end else begin
        scl_sync <= {scl_sync[1:0], scl};
        sda_sync <= {sda_sync[1:0], sda};
    end
end

wire scl_rising = (scl_sync[2:1] == 2'b01);
wire scl_falling = (scl_sync[2:1] == 2'b10);
wire sda_in = sda_sync[2];

assign sda = sda_dir ? sda_out : 1'bz;

// ��״̬�� - ��ȫ��λ����
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        sda_dir <= 0;
        sda_out <= 1;
        bit_cnt <= 0;
        shift_reg <= 0;
        reg_addr <= 0;
        reg_data <= 0;
        reg_wr <= 0;
    end else begin
        reg_wr <= 0;  // Ĭ��Ϊ��д����
        
        // �����ʼ���� (SCL�ߵ�ƽʱSDA�½���)
        if (scl_rising && sda_in == 1'b0 && state == IDLE) begin
            state <= ADDR;
            bit_cnt <= 0;
            shift_reg <= 0;
        end
        
        // ���ֹͣ���� (SCL�ߵ�ƽʱSDA������)
        if (scl_rising && sda_in == 1'b1 && state != IDLE) begin
            state <= IDLE;
            sda_dir <= 0;
        end
        
        // ��SCL�½��ش�������λ
        if (scl_falling) begin
            case (state)
                IDLE: begin
                    // ����״̬��ִ�в���
                end
                    
                ADDR: begin
                    // ��λ���մӻ���ַ
                    case (bit_cnt)
                        0: shift_reg[7] <= sda_in;
                        1: shift_reg[6] <= sda_in;
                        2: shift_reg[5] <= sda_in;
                        3: shift_reg[4] <= sda_in;
                        4: shift_reg[3] <= sda_in;
                        5: shift_reg[2] <= sda_in;
                        6: shift_reg[1] <= sda_in;
                        7: begin
                            shift_reg[0] <= sda_in;
                            state <= ACK1;
                        end
                    endcase
                    if (bit_cnt < 7) bit_cnt <= bit_cnt + 1;
                end
                
                ACK1: begin
                    // ��ַƥ���� (��7'h30Ϊ��)
                    if (shift_reg[7:1] == 7'h30) begin
                        sda_dir <= 1;
                        sda_out <= 0;  // ����ACK
                    end
                    state <= shift_reg[0] ? IDLE : REG; // R/Wλ�ж�
                    bit_cnt <= 0;
                end
                
                REG: begin
                    // ��λ���ռĴ�����ַ
                    case (bit_cnt)
                        0: shift_reg[7] <= sda_in;
                        1: shift_reg[6] <= sda_in;
                        2: shift_reg[5] <= sda_in;
                        3: shift_reg[4] <= sda_in;
                        4: shift_reg[3] <= sda_in;
                        5: shift_reg[2] <= sda_in;
                        6: shift_reg[1] <= sda_in;
                        7: begin
                            shift_reg[0] <= sda_in;
                            state <= ACK2;
                        end
                    endcase
                    if (bit_cnt < 7) bit_cnt <= bit_cnt + 1;
                end
                
                ACK2: begin
                    sda_dir <= 1;
                    sda_out <= 0;  // ����ACK
                    reg_addr <= shift_reg; // ����Ĵ�����ַ
                    state <= DATA;
                    bit_cnt <= 0;
                end
                
                DATA: begin
                    // ��λ��������
                    case (bit_cnt)
                        0: shift_reg[7] <= sda_in;
                        1: shift_reg[6] <= sda_in;
                        2: shift_reg[5] <= sda_in;
                        3: shift_reg[4] <= sda_in;
                        4: shift_reg[3] <= sda_in;
                        5: shift_reg[2] <= sda_in;
                        6: shift_reg[1] <= sda_in;
                        7: begin
                            shift_reg[0] <= sda_in;
                            state <= ACK3;
                        end
                    endcase
                    if (bit_cnt < 7) bit_cnt <= bit_cnt + 1;
                end
                
                ACK3: begin
                    sda_dir <= 1;
                    sda_out <= 0;  // ����ACK
                    reg_data <= shift_reg; // �����������
                    reg_wr <= 1;   // ����д����
                    state <= IDLE;  // ���ؿ���״̬
                end
            endcase
        end
    end
end

endmodule