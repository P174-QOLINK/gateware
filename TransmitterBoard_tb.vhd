----------------------------------------------------------------------------------
-- Company: GMU 
-- Engineer:
-- 
-- Create Date: 10/12/2026 
-- Design Name: 
-- Module Name: TransmitterBoard_tb - Behavioral
-- Project Name: 
-- Target Devices: MicroNova Mercury2
-- Tool Versions: 
-- Description: 
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;



entity TransmitterBoard_tb is
--  Port ( );
end TransmitterBoard_tb;

architecture Behavioral of TransmitterBoard_tb is
    -- INPUT signalS
    signal clk_tb: std_logic:= '0'; --Start clock at 0
    signal rst_tb: std_logic:= '0'; 
    signal sendTransmission_tb: std_logic;
    -- INPUT HeaderFields
    signal destinationID_tb: STD_LOGIC_VECTOR(3 downto 0);
    signal sourceID_tb:  STD_LOGIC_VECTOR(3 downto 0);
    signal priorityClass_tb: STD_LOGIC_VECTOR(1 downto 0);
    signal sequence_tb: STD_LOGIC_VECTOR(7 downto 0);
    signal payloadLength_tb: STD_LOGIC_VECTOR(10 downto 0);
    -- INPUT payload bound
    signal payloadData_tb: std_logic_vector(7 downto 0);
    
    -- OUTPUT signals
    signal transmissionWireBusy_tb, transmissionWireOutput_tb: std_logic;
    -- OUTPUT payload bound
    signal nextBytePayloadData_tb: std_logic;
    
    --CLK Period for freq: 50 Hz
    constant CLK_PERIOD : time := 20 ns;

    
    
begin

    -- Instantiate Devide Undet Test
    dut: entity work.TransmitterBoard
        port map(
            clk => clk_tb,
            reset => rst_tb,
            sendTransmission => sendTransmission_tb,
            transmissionWireBusy => transmissionWireBusy_tb,
            transmissionWireOutput => transmissionWireOutput_tb,
            destinationID => destinationID_tb,
            sourceID => sourceID_tb,
            priorityClass => priorityClass_tb,
            sequence => sequence_tb,
            payloadLength => payloadLength_tb,
            payloadData => payloadData_tb,
            nextBytePayloadData => nextBytePayloadData_tb
            );
    clock_signal: Process
    begin
        clk_tb<='0';
        wait for CLK_PERIOD / 2;
        
        clk_tb<='1';
        wait for CLK_PERIOD / 2;
    end process clock_signal;
    
    --test
    stimuli: process
    begin
    
    -- Test 1: Reset
    rst_tb <= '1';
    sendTransmission_tb <= '0';

    wait for 40 ns;

    assert transmissionWireBusy_tb = '0'
        report "FAIL: Transmitter is busy after reset"
        severity error;

    assert transmissionWireOutput_tb = '0'
        report "FAIL: Output not cleared after reset"
        severity error;

    report "PASS: test completed";

    rst_tb <= '0';
    
    
    
    end process;
end Behavioral;
