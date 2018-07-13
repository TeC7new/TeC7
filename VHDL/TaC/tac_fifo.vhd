--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2018 by
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
-- TaC/tac_fifo.vhd : FIFO
--
-- 2018.07.13           : �ꉞ�̊���
-- 2018.04.02           : �����o�[�W����
--
-- $Id
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all;
--use ieee.numeric_std.all;
use ieee.math_real.all;

entity TAC_FIFO is
  generic (
    width     : integer :=8;
    depth     : integer :=15;
    threshold : integer :=7
    );
  port (
    P_CLK   : in  std_logic;
    P_RESET : in  std_logic;

    P_FULL  : out std_logic;
    P_WRITE : in  std_logic;
    P_DIN   : in  std_logic_vector(width-1 downto 0);

    P_EMPTY : out std_logic;
    P_READ  : in  std_logic;
    P_DOUT  : out std_logic_vector(width-1 downto 0)
  );
end TAC_FIFO;

architecture BEHAVE of TAC_FIFO is
  constant ptrW : integer := integer(ceil(log2(real(depth))));
  constant cntW : integer := integer(ceil(log2(real(depth+1))));
  
  subtype Word is std_logic_vector(width-1 downto 0);
  type Fifo is array(0 to depth-1) of Word;
  signal i_buf   : Fifo;

  signal i_cnt   : std_logic_vector(cntW-1 downto 0);
  signal i_wPtr  : std_logic_vector(ptrW-1 downto 0);
  signal i_rPtr  : std_logic_vector(ptrW-1 downto 0);
  signal i_empty : std_logic;
  signal i_write : std_logic;
  signal i_read  : std_logic;

begin
  i_empty <= '1' when (i_cnt = 0) else '0';
  P_EMPTY <= i_empty;
  P_FULL  <= '1' when (i_cnt >= threshold) else '0';
  P_DOUT  <= i_buf(conv_integer(i_rPtr));
  i_write <= P_WRITE when (i_cnt /= depth) else '0';
  i_read  <= P_READ  and not i_empty;

  -- i_cnt
  process(P_RESET, P_CLK)
  begin
    if (P_RESET='0') then
      i_cnt  <= (others => '0');
    elsif (P_CLK'event and P_CLK='1') then
      if (i_read='1' and i_write='0') then
        i_cnt <= i_cnt - 1;
      elsif (i_read='0' and i_write='1') then
        i_cnt <= i_cnt + 1;
      end if;
    end if;
  end process;

  -- i_wPtr
  process(P_RESET, P_CLK)
  begin
    if (P_RESET='0') then
      i_wPtr <= (others => '0');
    elsif (P_CLK'event and P_CLK='1') then
      if (i_write='1') then
        i_buf(conv_integer(i_wPtr)) <= P_DIN;
        if (i_wPtr /= depth-1) then
          i_wPtr <= i_wPtr + 1;
        else
          i_wPtr <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  -- i_rPtr
  process(P_RESET, P_CLK)
  begin
    if (P_RESET='0') then
      i_rPtr <= (others => '0');
    elsif (P_CLK'event and P_CLK='1') then
      if (i_read='1') then
        if (i_rPtr /= depth-1) then
          i_rPtr <= i_rPtr + 1;
        else
          i_rPtr <= (others => '0');
        end if;
      end if;
    end if;
  end process;

end BEHAVE;
