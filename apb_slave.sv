`timescale 1ns/1ps

// APB slave (версия 2). Карта регистров (адрес = paddr[7:0]):
//   0x00 - номер студента в списке группы
//   0x04 - дата дд.мм.гггг
//   0x08 - первые 4 буквы фамилии (ASCII)
//   0x0C - первые 4 буквы имени (ASCII)
//   0x10 - register_with_some_name: запись 0 в бит 0 -> hAAAA_AAAA, запись 1 -> h5555_5555
module apb_slave
(
  input  logic        pclk,     // синхросигнал
  input  logic        presetn,  // сброс (инверсный)
  input  logic [31:0] paddr,    // адрес обращения
  input  logic [31:0] pwdata,   // данные для записи
  input  logic        psel,     // признак выбора устройства
  input  logic        penable,  // признак активной транзакции
  input  logic        pwrite,   // признак операции записи
  output logic        pready,   // готовность от устройства
  output logic        pslverr,  // признак ошибки при обращении
  output logic [31:0] prdata    // прочитанные данные
);

  logic [31:0] reg_student_number;    // 0x00
  logic [31:0] reg_date;              // 0x04
  logic [31:0] reg_surname;           // 0x08
  logic [31:0] reg_name;              // 0x0C
  logic [31:0] register_with_some_name; // 0x10

  // признак: адрес принадлежит одному из регистров
  wire addr_valid = (paddr[7:0] == 8'h00) || (paddr[7:0] == 8'h04) ||
                    (paddr[7:0] == 8'h08) || (paddr[7:0] == 8'h0C) ||
                    (paddr[7:0] == 8'h10);

  // Конечный автомат APB
  enum logic [1:0] {
    APB_SETUP,      // ожидание фазы SETUP
    APB_W_ENABLE,   // фаза ACCESS для записи
    APB_R_ENABLE    // фаза ACCESS для чтения
  } apb_st;

  always @(posedge pclk)
    if (!presetn) begin
      prdata  <= '0;
      pslverr <= 1'b0;
      pready  <= 1'b0;
      reg_student_number <= '0;
      reg_date    <= '0;
      reg_surname <= '0;
      reg_name    <= '0;
      register_with_some_name <= 32'hAAAA_AAAA;
      apb_st  <= APB_SETUP;
    end
    else begin
      case (apb_st)

        APB_SETUP: begin : apb_setup_st
          prdata  <= '0;
          pready  <= 1'b0;
          pslverr <= 1'b0;                 // ошибка живет один такт (в шаблоне не сбрасывалась)
          if (psel && !penable) begin      // фаза SETUP обнаружена
            if (pwrite) apb_st <= APB_W_ENABLE;
            else        apb_st <= APB_R_ENABLE;
          end
        end : apb_setup_st

        APB_W_ENABLE: begin : apb_w_en_st
          if (psel && penable && pwrite) begin
            pready <= 1'b1;
            if (addr_valid)
              $display("[%0t] SLAVE: WRITE addr=0x%h data=0x%h", $time, paddr, pwdata);
            case (paddr[7:0])
              8'h00: reg_student_number <= pwdata;
              8'h04: reg_date           <= pwdata;
              8'h08: reg_surname        <= pwdata;
              8'h0C: reg_name           <= pwdata;
              8'h10: // логика определяется ЗАПИСЫВАЕМЫМ значением pwdata[0]
                register_with_some_name <= pwdata[0] ? 32'h5555_5555 : 32'hAAAA_AAAA;
              default: begin
                pslverr <= 1'b1;
                $display("[%0t] SLAVE: WRITE ERROR, bad addr=0x%h", $time, paddr);
              end
            endcase
          end
          apb_st <= APB_SETUP;
        end : apb_w_en_st

        APB_R_ENABLE: begin : apb_r_en_st
          if (psel && penable && !pwrite) begin
            pready <= 1'b1;
            if (addr_valid)
              $display("[%0t] SLAVE: READ  addr=0x%h", $time, paddr);
            case (paddr[7:0])
              8'h00: prdata <= reg_student_number;
              8'h04: prdata <= reg_date;
              8'h08: prdata <= reg_surname;
              8'h0C: prdata <= reg_name;
              8'h10: prdata <= register_with_some_name;
              default: begin
                pslverr <= 1'b1;
                $display("[%0t] SLAVE: READ ERROR, bad addr=0x%h", $time, paddr);
              end
            endcase
          end
          apb_st <= APB_SETUP;
        end : apb_r_en_st

        default: begin
          pslverr <= 1'b1;
          apb_st  <= APB_SETUP;
        end
      endcase
    end

endmodule
