`timescale 1ns/1ps
`include "student_cfg.svh"   // данные студента

// Модель APB-мастера (bus functional model).
// Формирует сигналы шины APB с помощью задач apb_write / apb_read.
module apb_master
#(
  parameter [31:0] BASE_ADDR = 32'h7000_0000  // базовый адрес устройства на шине
)
(
  input  logic        pclk,     // синхросигнал
  input  logic        presetn,  // сброс (инверсный)
  output logic        psel,     // выбор устройства
  output logic        penable,  // фаза ACCESS
  output logic        pwrite,   // 1 - запись, 0 - чтение
  output logic [31:0] paddr,    // адрес
  output logic [31:0] pwdata,   // данные для записи
  input  logic        pready,   // готовность slave
  input  logic        pslverr,  // ошибка slave
  input  logic [31:0] prdata,   // прочитанные данные
  output logic        done      // 1 - тест закончен
);

  logic last_slverr;            // значение pslverr в последней транзакции

  // ---------------- запись ----------------
  task apb_write(input [31:0] addr, input [31:0] data);
    begin
      wait ((penable == 0) && (pready == 0));
      @(posedge pclk);
      psel  <= 1'b1;            // фаза SETUP
      paddr <= addr;
      pwdata <= data;
      pwrite <= 1'b1;
      @(posedge pclk);
      penable <= 1'b1;          // фаза ACCESS
      @(posedge pclk);
      wait (pready == 1'b1);
      last_slverr = pslverr;
      @(posedge pclk);
      psel    <= 1'b0;
      penable <= 1'b0;
      pwrite  <= 1'b0;
      @(posedge pclk);
    end
  endtask

  // ---------------- чтение ----------------
  task apb_read(input [31:0] addr, output logic [31:0] data);
    begin
      wait ((penable == 0) && (pready == 0));
      @(posedge pclk);
      psel   <= 1'b1;           // фаза SETUP
      pwrite <= 1'b0;
      paddr  <= addr;
      @(posedge pclk);
      penable <= 1'b1;          // фаза ACCESS
      @(posedge pclk);
      wait (pready == 1'b1);
      last_slverr = pslverr;
      @(posedge pclk);
      data <= prdata;
      psel    <= 1'b0;
      penable <= 1'b0;
      @(posedge pclk);
    end
  endtask

  // ---------------- проверка прочитанного значения ----------------
  integer errors = 0;           // счетчик ошибок

  task apb_read_check(input [31:0] addr, input [31:0] expected);
    logic [31:0] got;
    begin
      apb_read(addr, got);
      if (got === expected)
        $display("[MASTER] PASS: addr=0x%h data=0x%h", addr, got);
      else begin
        errors = errors + 1;
        $display("[MASTER] FAIL: addr=0x%h expected=0x%h got=0x%h", addr, expected, got);
      end
    end
  endtask

  // ---------------- тестовая последовательность ----------------
  initial begin
    psel    = 1'b0;
    penable = 1'b0;
    pwrite  = 1'b0;
    paddr   = '0;
    pwdata  = '0;
    done    = 1'b0;
    last_slverr = 1'b0;

    wait (presetn === 1'b1);          // ждем снятия сброса
    repeat (5) @(posedge pclk);

    // --- 1. запись данных студента в регистры 0x0, 0x4, 0x8, 0xC ---
    apb_write(BASE_ADDR + 32'h0, `STUDENT_NUMBER);
    apb_write(BASE_ADDR + 32'h4, `STUDENT_DATE);
    apb_write(BASE_ADDR + 32'h8, `STUDENT_SURNAME);
    apb_write(BASE_ADDR + 32'hC, `STUDENT_NAME);

    // --- 2. чтение и проверка ---
    apb_read_check(BASE_ADDR + 32'h0, `STUDENT_NUMBER);
    apb_read_check(BASE_ADDR + 32'h4, `STUDENT_DATE);
    apb_read_check(BASE_ADDR + 32'h8, `STUDENT_SURNAME);
    apb_read_check(BASE_ADDR + 32'hC, `STUDENT_NAME);

    // --- 3. регистр register_with_some_name (смещение 0x10) ---
    apb_write(BASE_ADDR + 32'h10, 32'h1234_5678);   // бит 0 = 0
    apb_read_check(BASE_ADDR + 32'h10, 32'hAAAA_AAAA);
    apb_write(BASE_ADDR + 32'h10, 32'h1);           // бит 0 = 1
    apb_read_check(BASE_ADDR + 32'h10, 32'h5555_5555);

    // --- 4. обращение по несуществующему адресу -> pslverr ---
    apb_write(BASE_ADDR + 32'h20, 32'hDEAD_BEEF);
    if (last_slverr !== 1'b1) begin
      errors = errors + 1;
      $display("[MASTER] FAIL: pslverr was not set for bad address");
    end else
      $display("[MASTER] PASS: pslverr set for bad address");

    if (errors == 0) $display("[MASTER] TEST PASSED");
    else             $display("[MASTER] TEST FAILED, errors = %0d", errors);

    repeat (10) @(posedge pclk);
    done = 1'b1;
  end

endmodule
