--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2002-2011 by
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
-- TeC Interrupt Controller VHDL Source Code
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

library work;

entity TEC_INTC is
  port ( P_CLK   : in  std_logic;                        -- Clock
         P_RESET : in  std_logic;                        -- Reset
         P_LI    : in  std_logic;                        -- Instruction fetch
         P_MR    : in  std_logic;                        -- Memory Request

         P_INT0  : in  std_logic;                        -- INT0 (Timer)
         P_INT1  : in  std_logic;                        -- INT1 (SIO TdR)
         P_INT2  : in  std_logic;                        -- INT2 (SIO TdX)
         P_INT3  : in  std_logic;                        -- INT3 (Console)

         P_INTR  : out std_logic;                        -- Interrupt
         P_VECT  : out std_logic_vector(1 downto 0)      -- �����ݔԍ�
        );
end TEC_INTC;

architecture RTL of TEC_INTC is
signal I_INT0 : std_logic;                               -- INT0 �̓��b�`����
signal I_INT3 : std_logic;                               -- INT3 �̓��b�`����

begin
  P_INTR <= I_INT0 or P_INT1 or  P_INT2 or  I_INT3;

  process(I_INT0, P_INT1, P_INT2)                        -- ���荞�ݔԍ������߂�
  begin                                                  --   �v���C�I���e�B
    if (I_INT0='1') then                                 --     �G���R�[�_
      P_VECT <= "00";
    elsif (P_INT1='1') then
      P_VECT <= "01";
    elsif (P_INT2='1') then
      P_VECT <= "10";
    else
      P_VECT <= "11";
    end if;
  end process;

  -- INT0, INT3 �̓��b�`����(CPU ���F�������玩���I�Ƀ��Z�b�g����)
  process(P_CLK, P_RESET)
  begin
    if (P_RESET='0') then
      I_INT0 <= '0';
      I_INT3 <= '0';
    elsif (P_CLK' event and P_CLK='1') then
      if (P_INT0='1') then                               -- INT0 �����b�`����
        I_INT0 <= '1';
      elsif (P_MR='0' and P_LI='1') then                 -- CPU �� INT0 ��F��
        I_INT0 <= '0';                                   --   ���Z�b�g����
      end if;
      if (P_INT3='1') then                               -- INT3 �����b�`����
        I_INT3 <= '1';
      elsif (P_MR='0' and P_LI='1' and I_INT0='0'        -- CPU �� INT3 ��F��
             and P_INT1='0' and P_INT2='0') then
        I_INT3 <= '0';                                   --   ���Z�b�g����
      end if;
    end if;
  end process;
  
end RTL;
