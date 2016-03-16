--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2002 - 2013 by
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
-- TaC/tac_intc.vhd : Interrupt Controler
--
-- 2013.01.06           : TaC-CPU V2 �Ή�
-- 2012.01.22           : entity ��������
-- 2011.06.16           : TeC7 �p�ɏ���������
-- 2010.07.20           : Subversion �ɂ��Ǘ����J�n
--
-- $Id
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity TAC_INTC is
  port (
         P_CLK      : in  std_logic;
         P_RESET    : in  std_logic;
         P_DOUT     : out std_logic_vector(15 downto 0);
         P_VR       : in  std_logic;
         P_INTR     : out std_logic;
         P_INT_BIT  : in  std_logic_vector(15 downto 0)
       );
end TAC_INTC;

architecture RTL of TAC_INTC is

-- register
signal intReg  : std_logic_vector(15 downto 0);
signal intInp  : std_logic_vector(15 downto 0);
signal intInpD : std_logic_vector(15 downto 0);

-- signal
signal intSnd  : std_logic_vector(15 downto 0);
signal intMsk  : std_logic_vector(15 downto 1);

begin
  -- synchronize with CLK
  process(P_RESET, P_CLK)
  begin
    if (P_RESET='0') then
      intInp <= "0000000000000000";
    elsif (P_CLK'event and P_CLK='1') then
      intInp <= P_INT_BIT;
    end if;
  end process;

  -- edge trigger
  process(P_RESET, P_CLK)
  begin
    if (P_RESET='0') then
      intReg  <= "0000000000000000";
      intInpD <= "0000000000000000";
    elsif (P_CLK'event and P_CLK='1') then
      intReg <= (intReg and not intSnd) or
                (intInp and (intInpD xor intInp));
      intInpD <= intInp;
    end if;
  end process;

  -- select send signal
  intMsk(1) <= intReg(0);
  intMsk(15 downto 2) <= intMsk(14 downto 1) or intReg(14 downto 1);
  intSnd <= intReg and (not (intMsk & "0")) when (P_VR='1') else
            "0000000000000000";

  -- to cpu
  P_INTR  <= '0' when (intReg = 0) else '1';
  P_DOUT(15 downto 5) <= "11111111111";
  P_DOUT(4 downto 1) <=
            "0000" when (intReg(0)  = '1') else  -- Int0
            "0001" when (intReg(1)  = '1') else  -- Int1
            "0010" when (intReg(2)  = '1') else  -- Int2
            "0011" when (intReg(3)  = '1') else  -- Int3
            "0100" when (intReg(4)  = '1') else  -- Int4
            "0101" when (intReg(5)  = '1') else  -- Int5
            "0110" when (intReg(6)  = '1') else  -- Int6
            "0111" when (intReg(7)  = '1') else  -- Int7
            "1000" when (intReg(8)  = '1') else  -- Int8
            "1001" when (intReg(9)  = '1') else  -- Int9
            "1010" when (intReg(10) = '1') else  -- Int10
            "1011" when (intReg(11) = '1') else  -- Int11
            "1100" when (intReg(12) = '1') else  -- Int12
            "1101" when (intReg(13) = '1') else  -- Int13
            "1110" when (intReg(14) = '1') else  -- Int14
            "1111";                              -- Int15
  P_DOUT(0) <= '0';
end RTL;

