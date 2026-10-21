----------------------------------------------------------------------------------
-- Company: 
-- Engineers: Moneeb, Elias
-- 
-- Create Date: 10/08/2026 03:45:32 PM
-- Design Name: 
-- Module Name: TransmitterGateware - Behavioral
-- Project Name: 
-- Target Devices: MicroNova Mercury2
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TransmitterBoard is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        sendTransmission    : in  STD_LOGIC;
        transmissionWireBusy     : out STD_LOGIC; 
        transmissionWireOutput   : out STD_LOGIC;
        
        -- header fields
        destinationID     : in  STD_LOGIC_VECTOR(3 downto 0);
        sourceID   : in  STD_LOGIC_VECTOR(3 downto 0);
        priorityClass     : in  STD_LOGIC_VECTOR(1 downto 0);
        sequence     : in  STD_LOGIC_VECTOR(7 downto 0);
        payloadLength : in  STD_LOGIC_VECTOR(10 downto 0);
        
        --payload bounds
        payloadData : in STD_LOGIC_VECTOR(7 downto 0);
        nextBytePayloadData : out STD_LOGIC
        -- we are going to have to send the payload data byte by byte,
        -- because of that, we will have to read each incoming Byte of the payload
        
        
        
    );
end TransmitterBoard;

-- okay so, from my understnanding, which isn't much, heres what has to happen:
-- From the spreadsheet I made detailing the header fields, payload and CRC, we will
-- have to transmit them over the wire to the receiver. So, the best course of action will
-- be to do it in different states. We start idle, listening for any tramission request.
-- When received, we start seanding all of the header fields (dest,source,class,etc). Once done
-- we move onto sending the payload and once that is done, we send the CRC-16. Once finished
-- we go back to idle and wait for another transmission and loop all over again

architecture Behavioral of TransmitterBoard is
    type stateType is (Idle, SendHeader, SendPayload, SendCRC);
    signal state : stateType := Idle;
    
    -- for the header 
    signal headerReg : STD_LOGIC_VECTOR(31 downto 0); -- 32 Bit register
    signal bitIndex : integer range 0 to 31 := 31; --start at bit 31 MSB
    
    -- for the payload 
    signal payloadReg : STD_LOGIC_VECTOR(7 downto 0);
    signal payloadBytesRemaining  : unsigned(10 downto 0); 
    
    -- for the CRC-16 
    signal CRCReg          : STD_LOGIC_VECTOR(15 downto 0) := (others => '1');
    

begin
    process(clk, reset)
        variable nextCRCBit : STD_LOGIC;
        -- allegedly, we need the bit to be a variable so that it can update the moment its changed
        -- which is very good for us because we want the fastest thing
    begin
        if reset = '1' then
            -- initilization
            state <= Idle;
            transmissionWireBusy <= '0';
            transmissionWireOutput <= '0';
            
            headerReg <= (others => '0');
            CRCReg <= (others => '1');
            nextBytePayloadData <= '0';
            
            bitIndex <= 31;     -- restart at msb for each packet
            
        elsif falling_edge(clk) then --falling edge allows for read on rising edge
           nextBytePayloadData <= '0';  --needs to be reset after each request
           
            case state is
                when Idle =>
                    transmissionWireOutput <= '0';
                    if sendTransmission = '1' then
                        transmissionWireBusy <= '1';
                        -- start transmission
                        
                        payloadBytesRemaining <= unsigned(payloadLength);
                        headerReg <= destinationID & sourceID &             --destinationID 31-28, sourceID 27-24
                        priorityClass & sequence & payloadLength & "000";   -- priorityClass 23-22, sequence 21-14, payloadLength 13-3, "000" 2-0.
                        
                        
                        CRCReg <= (others => '1'); 
                        bitIndex <= 31; -- im hoping that we don't need this because
                        -- they are already reset to these values whneever we reset
                        -- but ill keep them just in case
                        
                     
                        
                        state <= SendHeader;
                    else
                        transmissionWireBusy <= '0';
                    end if;

                when SendHeader =>
                    transmissionWireOutput <= headerReg(bitIndex);      --output will decrement through headerReg
                    
                    -- need to start with CRC16 with current data now
                    -- we are comparing the current bits to see if they are different
                    -- if they're different, we store it as a 1
                    
                    nextCRCBit := CRCReg(15) xor headerReg(bitIndex);
                    
                    CRCReg <= CRCReg(14 downto 0) & '0';
                    if nextCRCBit = '1' then
                        -- that 1021 is speical because its the CRC16 polynomial
                        -- (x^16 + x^12 + x^5 + 1) written in hexadecimal
                        CRCReg <= (CRCReg(14 downto 0) & '0') xor x"1021"; 
                    end if;
                    
                                 
                    if bitIndex = 0 then
                        if payloadBytesRemaining = 0 then   -- prevent sending if empty
                            bitIndex <= 15;
                            state <= sendCRC;
                        else
                            nextBytePayloadData <= '1';
                            bitIndex <= 7;
                            state <= SendPayload;       --state change upon completion
                        end if;
                    else
                        bitIndex <= bitIndex - 1;
                    end if;

                when SendPayload =>
                    
                    if bitIndex = 7 then
                        -- checking if its the first clock cycle of a new byte
                        payloadReg <= payloadData;
                        transmissionWireOutput <= payloadData(7);
                        nextCrcBit  := CRCReg(15) xor payloadData(7);
                    else
                        transmissionWireOutput <= payloadReg(bitIndex);
                        nextCrcBit  := CRCReg(15) xor payloadReg(bitIndex);
                    end if;
                    
                    
                    
                    -- this is exactly the same thing we did last state,
                    -- need to do it again for payload data now
                    CRCReg <= CRCReg(14 downto 0) & '0';
                    if nextCRCBit = '1' then
                        CRCReg <= (CRCReg(14 downto 0) & '0') xor x"1021"; 
                    end if;
                    
                    
                    if bitIndex = 0 then
                        if payloadBytesRemaining = 0 then
                            bitIndex <= 15; 
                            state <= SendCRC;
                        else
                            payloadBytesRemaining <= payloadBytesRemaining - 1;
                            nextBytePayloadData <= '1'; 
                            bitIndex <= 7;
                        end if;
                    else
                        bitIndex <= bitIndex - 1;
                    end if;

                when SendCRC =>
                    transmissionWireOutput <= CRCReg(bitIndex);
                    
                    if bitIndex = 0 then
                        state <= Idle;
                    else
                        bitIndex <= bitIndex - 1;
                    end if;
            end case;
        end if;
    end process;
end Behavioral;