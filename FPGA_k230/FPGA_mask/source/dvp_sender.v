module dvp_tx(
    input         clk,           // ����ʱ�� (25MHz)
    input         rst_n,         // ��λ�ź�
    // ͼ������ӿ�
    input         vsync_i,       // ���볡ͬ��
    input         href_i,        // ������ͬ��
    input         data_valid_i,  // ������Ч
    input  [15:0] data_i,        // ������������ (RGB565)
    // DVP����ӿ�
    output        dvp_pclk,      // ����ʱ�����
    output        dvp_vsync,     // ��ͬ�����
    output        dvp_href,      // ��ͬ�����
    output [7:0]  dvp_data       // ����������� (8λ)
);

// �Ĵ�������
reg [3:0] state;
reg [7:0] data_out;
reg vsync_reg, href_reg;
reg [3:0] cnt;  // λ������

// ״̬����
localparam IDLE  = 4'b0001;
localparam HIGH  = 4'b0010;  // ���͸��ֽ�
localparam LOW   = 4'b0100;  // ���͵��ֽ�
localparam WAIT  = 4'b1000;  // �ȴ���һ������

// ���ʱ��ֱ������
assign dvp_pclk = clk;

// DVP����ź�
assign dvp_vsync = vsync_reg;
assign dvp_href  = href_reg;
assign dvp_data  = data_out;

// ��״̬��
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        data_out <= 8'h00;
        vsync_reg <= 1'b0;
        href_reg <= 1'b0;
        cnt <= 4'd0;
    end else begin
        // ͬ���ź�ֱͨ
        vsync_reg <= vsync_i;
        href_reg <= href_i;
        
        case(state)
            IDLE: begin
                data_out <= 8'h00;
                cnt <= 4'd0;
                if (data_valid_i) begin
                    state <= HIGH;
                    // ׼��������ֽ�
                    data_out[7] <= data_i[15];
                end
            end
            HIGH: begin
                if (cnt < 4'd7) begin
                    cnt <= cnt + 1'b1;
                    // ��λ������ֽ�
                    case(cnt)
                        4'd0: data_out[6] <= data_i[14];
                        4'd1: data_out[5] <= data_i[13];
                        4'd2: data_out[4] <= data_i[12];
                        4'd3: data_out[3] <= data_i[11];
                        4'd4: data_out[2] <= data_i[10];
                        4'd5: data_out[1] <= data_i[9];
                        4'd6: data_out[0] <= data_i[8];
                    endcase
                end else begin
                    state <= LOW;
                    cnt <= 4'd0;
                    // ׼��������ֽڵĵ�һλ
                    data_out[7] <= data_i[7];
                end
            end
            LOW: begin
                if (cnt < 4'd7) begin
                    cnt <= cnt + 1'b1;
                    // ��λ������ֽ�
                    case(cnt)
                        4'd0: data_out[6] <= data_i[6];
                        4'd1: data_out[5] <= data_i[5];
                        4'd2: data_out[4] <= data_i[4];
                        4'd3: data_out[3] <= data_i[3];
                        4'd4: data_out[2] <= data_i[2];
                        4'd5: data_out[1] <= data_i[1];
                        4'd6: data_out[0] <= data_i[0];
                    endcase
                end else begin
                    if (data_valid_i) begin
                        state <= HIGH;
                        cnt <= 4'd0;
                        // ׼�������һ�����ֽڵĵ�һλ
                        data_out[7] <= data_i[15];
                    end else begin
                        state <= IDLE;
                        data_out <= 8'h00;
                    end
                end
            end
            default: state <= IDLE;
        endcase
    end
end

endmodule