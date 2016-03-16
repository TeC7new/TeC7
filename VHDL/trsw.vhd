--
-- TaC VHDL Source Code
--    Tokuyama kousen Educational Computer 16 bit Version
--
-- Copyright (C) 2002-2010 by
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
--  trsw.vhd : push �X�C�b�`�̓��͂��A�`���^�����O�̂Ȃ��g���K�M���ɕϊ�����
--
--
-- 2010.07.20           : Subversion �ɂ��Ǘ����J�n
--
-- $Id
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity TRSW is
  port ( P_CLK    : in  std_logic;                      -- CLK
         P_RESET  : in  std_logic;                      -- Reset
         P_S      : in  std_logic;                      -- Switch(INPUT)
         P_SMP    : in  std_logic;                      -- Sample(20ms)
         P_RPT    : in  std_logic;                      -- Repeate
         P_Q      : out std_logic                       -- Q(OUTPUT)
       );
end TRSW;

architecture RTL of TRSW is

-- Flip Flop
signal I_PREV     : std_logic;
signal I_CNT1     : std_logic_vector(3 downto 0);      -- ���s�[�g�J�n�^�C�}
signal I_CNT2     : std_logic_vector(1 downto 0);      -- ���s�[�g�Ԋu�^�C�}

begin
  P_Q <= P_SMP and P_S and (not I_PREV);

  process(P_CLK, P_RESET)
  begin
    if (P_RESET='0') then
      I_PREV  <= '0';
      I_CNT1  <= "0000";
      I_CNT2  <= "00";
    elsif (P_CLK' event and P_CLK='1') then
      if (P_SMP='1') then
        if (P_S='1') then
          if (I_PREV='0') then
            I_PREV  <= '1';
          elsif (I_CNT1="1111") then
            if (I_CNT2="00") then
              I_PREV  <= '0';
            end if;
            I_CNT2 <= I_CNT2 + 1;
          elsif (P_RPT='1') then
            I_CNT1 <= I_CNT1 + 1;
          end if;
        else
          I_PREV    <= '0';
          I_CNT1    <= "0000";
          I_CNT2    <= "00";
        end if;
      end if;
    end if;
  end process;

end RTL;

