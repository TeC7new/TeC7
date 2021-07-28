--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2011-2019 by
--                      Dept. of Computer Science and Electronic Engineering,
--                      Tokuyama College of Technology, JAPAN
--
--   Free Software Foundation  GNU 
-- 
-- ()
-- 
--
--   
-- 
-- 
-- 
--
--

--
-- TaC/tac_mmu.vhd : TaC Memory Management Unit Source Code
--
-- 2019.12.19           : CPU
-- 2019.07.30           : 
-- 2019.01.22           : 
--

library IEEE;
use IEEE.std_logic_1164.ALL;
use ieee.std_logic_unsigned.all;

entity TAC_MMU is
  Port ( P_CLK      : in  std_logic;
         P_RESET    : in  std_logic;
         P_EN       : in  std_logic;
         P_IOW      : in  std_logic;
         P_MMU_MR   : in  std_logic;                     -- Memory Request(CPU)
         P_BT       : in  std_logic;                     -- Byte access
         P_PR       : in  std_logic;                     -- Privilege mode
         P_STOP     : in  std_logic;                     -- Panel RUN F/F
         P_VIO_INT  : out std_logic;                     -- Memory Vio inter
         P_ADR_INT  : out std_logic;                     -- Bad Address inter
         P_MR       : out std_logic;                     -- Memory Request
         P_ADDR     : out std_logic_vector(15 downto 0); -- Physical address
         P_MMU_ADDR : in  std_logic_vector(15 downto 0); -- Virtual address
         P_DIN      : in  std_logic_vector(15 downto 0); -- New TLB field
         P_DOUT     : out std_logic_vector(15 downto 0); -- Entry 
         P_IOR      : out std_logic                      -- Interrupt
       );
end TAC_MMU;

architecture Behavioral of TAC_MMU is
signal i_en  : std_logic;                                -- Enable resister
--signal i_b   : std_logic_vector(15 downto 0);            -- Base  register
--signal i_l   : std_logic_vector(15 downto 0);            -- Limit register
signal i_act : std_logic;                                -- Activate MMU
signal i_mis : std_logic;                                -- TLB miss
signal i_adr : std_logic;                                -- Bad Address
 
subtype TLB_field is std_logic_vector(23 downto 0);     
--page [xxxx xxxx] ctrl [x '0' V R D R W X] frame [xxxx xxxx] total 24bit 
type TLB_array is array(0 to 7) of TLB_field;           --array of 24bit * 8 

signal TLB : TLB_array;                                 --TLB
signal key_page : std_logic_vector(7 downto 0);         --page num of key
signal offset : std_logic_vector(7 downto 0);
signal tar_field : TLB_field;                           --TLB field gotten with key
signal tar_frame : std_logic_vector(7 downto 0);        --frame num gotten with key
signal entry : std_logic_vector(15 downto 0);           --ctrl + frame num
signal index : std_logic_vector(10 downto 0);           --page num index + page num
signal flag : std_logic;                                --update flag

begin 

  key_page <= P_MMU_ADDR(15 downto 8);                        
  offset <= P_MMU_ADDR(7 downto 0);
  tar_frame <= tar_field(7 downto 0);
        
--pick up TLB_field
  tar_field <= TLB(0) when key_page=TLB(0)(23 downto 16) else
            TLB(1) when key_page=TLB(1)(23 downto 16) else
            TLB(2) when key_page=TLB(2)(23 downto 16) else
            TLB(3) when key_page=TLB(3)(23 downto 16) else
            TLB(4) when key_page=TLB(4)(23 downto 16) else
            TLB(5) when key_page=TLB(5)(23 downto 16) else
            TLB(6) when key_page=TLB(6)(23 downto 16) else
            TLB(7) when key_page=TLB(7)(23 downto 16) else
				"XXXXXXXXX1XXXXXXXXXXXXXX"; -- pagemiss
  
  --ready to update entry
  process(P_CLK)
  begin 
    if(P_RESET='0') then
      i_en <= '0';
      flag <= '0';
    elsif (P_CLK'event and P_CLK='1') then
      if(P_EN='1' and P_IOW='1') then 
        if(P_MMU_ADDR(2)='1') then    --when MMU mode is paging
          i_en <= '1';
        elsif(P_MMU_ADDR(1)='0') then    
          entry <= P_DIN;
        else
          index <= P_DIN;
          flag <= '1';
        end if;
      else  
        flag <= '0';
      end if;
    end if;
  end process;

  --update entry 
  --need to change R, D bit on memory before replacing old entry
  process(P_CLK)
  begin
    if(P_CLK'event and P_CLK='1') then
      if(flag='1') then
        if(index(10 downto 8)="000") then
          TLB(0)(23 downto 16) <= index(7 downto 0);
          TLB(0)(15 downto 0) <= entry;
        elsif (index(10 downto 8)="001") then
          TLB(1)(23 downto 16) <= index(7 downto 0);
          TLB(1)(15 downto 0) <= entry;
        elsif (index(10 downto 8)="010") then
          TLB(2)(23 downto 16) <= index(7 downto 0);
          TLB(2)(15 downto 0) <= entry;
        elsif (index(10 downto 8)="011") then
          TLB(3)(23 downto 16) <= index(7 downto 0);
          TLB(3)(15 downto 0) <= entry;
        elsif (index(10 downto 8)="100") then
          TLB(4)(23 downto 16) <= index(7 downto 0);
          TLB(4)(15 downto 0) <= entry;
        elsif (index(10 downto 8)="101") then
          TLB(5)(23 downto 16) <= index(7 downto 0);
          TLB(5)(15 downto 0) <= entry;
        elsif (index(10 downto 8)="110") then
          TLB(6)(23 downto 16) <= index(7 downto 0);
          TLB(6)(15 downto 0) <= entry;
        elsif (index(10 downto 8)="111") then
          TLB(7)(23 downto 16) <= index(7 downto 0);
          TLB(7)(15 downto 0) <= entry;
        end if;
      end if;
    end if;
  end process;

  i_act <= (not P_PR) and (not P_STOP) and P_MMU_MR and i_en;
  i_mis <= tar_field(14);   --ato nanika
  i_adr <= P_MMU_ADDR(0) and i_act and not P_BT;
  P_ADDR <= tar_field & offset;
  P_MR <= P_MMU_MR and (not i_mis);
  P_VIO_INT <= i_mis;
  P_ADR_INT <= i_adr;
--begin
  --process(P_RESET, P_CLK)
  --begin
    --if (P_RESET='0') then
      --i_b <= "0000000000000000";
      --i_l <= "0000000000000000";
      --i_en <= '0';
    --elsif (P_CLK'event and P_CLK='1') then
      --if (P_EN='1' and P_IOW='1') then
        --if (P_MMU_ADDR(2)='0') then
          --i_en <= P_DIN(0);
        --elsif (P_MMU_ADDR(1)='0') then
          --i_b <= P_DIN;
        --else
          --i_l <= P_DIN;
        --end if;
      --end if;
    --end if;
  --end process;

  --i_act <= (not P_PR) and (not P_STOP) and P_MMU_MR and i_en;
  --i_vio <= '1' when (P_MMU_ADDR>=i_l and i_act='1') else '0';
  --i_adr <= P_MMU_ADDR(0) and i_act and not P_BT;
  --P_ADDR <= (P_MMU_ADDR + i_b) when (i_act='1') else P_MMU_ADDR;
  --P_MR <= P_MMU_MR and (not i_vio);
  --P_VIO_INT <= i_vio;
  --P_ADR_INT <= i_adr;

end Behavioral;
