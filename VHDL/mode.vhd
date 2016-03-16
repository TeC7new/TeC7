--
-- TaC7 VHDL Source Code
--    Tokuyama kousen Educational Computer 16 bit Version
--
-- Copyright (C) 2011 by
--                      Dept. of Computer Science and Electronic Engineering,
--                      Tokuyama College of Technology, JAPAN
--
--   ��L���쌠�҂́CFree Software Foundation �ɂ���Č��J����Ă��� GNU ��ʌ�
-- �O���p�����_�񏑃o�[�W�����Q�ɋL�q����Ă�������𖞂����ꍇ�Ɍ���C�{�\�[�X
-- �R�[�h(�{�\�[�X�R�[�h�����ς������̂��܂ށD�ȉ����l)���g�p�E�����E���ρE�Ĕz
-- �z���邱�Ƃ𖳏��ŋ�������D
--
--   �{�\�[�X�R�[�h�́��S���̖��ۏ؁��Œ񋟂������̂ł���B��L���쌠�҂����
-- �֘A�@�ցE�l�͖{�\�[�X�R�[�h�Ɋւ��āC���̓K�p�\�����܂߂āC�����Ȃ�ۏ�
-- ���s��Ȃ��D�܂��C�{�\�[�X�R�[�h�̗��p�ɂ�蒼�ړI�܂��͊ԐړI�ɐ�����������
-- �鑹�Q�Ɋւ��Ă��C���̐ӔC�𕉂�Ȃ��D
--
--

--
--  mode.vhd : �W�����p�[�̃Z�b�e�B���O���烂�[�h�����߂�
--
--
-- 2011.09.18           : �V�K�쐬
--
-- $Id
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity MODE is
  port (
         P_CLK    : in    std_logic;
         P_LOCKED : in    std_logic;
         P_JP     : inout std_logic_vector(1 downto 0);
         P_MODE   : out   std_logic_vector(1 downto 0);
         P_RESET  : out   std_logic
       );
end MODE;

architecture RTL of MODE is
  -- FSM state
  constant INIT  : std_logic_vector(2 downto 0) := "000";
  constant TEMP  : std_logic_vector(2 downto 0) := "001";
  constant TeC   : std_logic_vector(2 downto 0) := "100";
  constant TaC   : std_logic_vector(2 downto 0) := "101";
  constant DEMO1 : std_logic_vector(2 downto 0) := "110";
  constant DEMO2 : std_logic_vector(2 downto 0) := "111";

  -- FSM
  signal i_fsm   : std_logic_vector(2 downto 0);

  begin
    P_RESET <= i_fsm(2);                           -- mode is determined
    P_MODE  <= i_fsm(1 downto 0);                  -- mode

    process(P_CLK, P_LOCKED)
      begin
        if (P_LOCKED='0') then
          i_fsm <= INIT;
          P_JP  <= "ZZ";
        elsif (P_CLK'event and P_CLK='1') then
          if (i_fsm=INIT) then                     -- Initial state
            if (P_JP="10") then
              i_fsm <= TeC;                        -- TeC mode
            elsif (P_JP="01") then
              i_fsm <= TaC;                        -- TaC mode
            else
              i_fsm <= TEMP;                       -- DEMO mode candidate
              P_JP <= "0Z";                        -- output to jumper
            end if;
          elsif (i_fsm=TEMP) then                  -- DEMO mode candidate state
            if (P_JP="01") then   
              i_fsm <= DEMO1;                      --   DEMO mode 1
            else
              i_fsm <= DEMO2;                      --   DEMO mode 2
            end if;
            P_JP <= "ZZ";                          --   switch off output
          end if;
        end if;
      end process;
end RTL;

