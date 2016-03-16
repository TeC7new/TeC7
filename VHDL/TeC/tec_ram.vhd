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
-- TeC RAM
--
library IEEE;
use std.textio.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;

entity TEC_RAM is
  port (
    P_CLK  : in  std_logic;
    P_ADDR : in  std_logic_vector(7 downto 0);
    P_DOUT : out std_logic_vector(7 downto 0);
    P_DIN  : in  std_logic_vector(7 downto 0);
    P_RW   : in  std_logic;
    P_MR   : in  std_logic;

    P_PNA  : in  std_logic_vector(7 downto 0);  -- �p�l���A�h���X
    P_PND  : in  std_logic_vector(7 downto 0);  -- �p�l���p�f�[�^����
    P_SEL  : in  std_logic_vector(2 downto 0);  -- ���[�^���[�X�C�b�`�̈ʒu
    P_WRITE: in  std_logic;                     -- �p�l���������ݐM��
    P_MMD  : out std_logic_vector(7 downto 0);  -- �p�l���p�f�[�^�o��

    P_MODE : in  std_logic_vector(1 downto 0)   -- 0,1:�ʏ�, 2:�f��1, 3:�f��2
-- �f��1 : �d�q�I���S�[���v���O�������͍�
-- �f��2 : �d�q�I���S�[���v���O�����ƃf�[�^�����͍�
  );
end TEC_RAM;

architecture BEHAVE of TEC_RAM is
  subtype word is std_logic_vector(7 downto 0);
  type memory is array(0 to 1023) of word;
  function read_file (fname : in string) return memory is
    file data_in : text is in fname;
    variable line_in: line;
    variable ram : memory;
    begin
      for i in 0 to 1023 loop
        readline (data_in, line_in);
		  read(line_in, ram(i));
      end loop;
      return ram;
    end function;
  signal mem : memory := read_file("tec_ram.txt");

  signal deca   : std_logic;                    -- CPU �̃A�h���X�f�R�[�h����
  signal wea    : std_logic;                    -- CPU ���������ݐM��
  signal addr10a: std_logic_vector(9 downto 0); -- CPU ���A�h���X
  signal decb   : std_logic;                    -- �p�l���̃A�h���X�f�R�[�h����
  signal web    : std_logic;                    -- �p�l�����������ݐM��
  signal addr10b: std_logic_vector(9 downto 0); -- �p�l�����A�h���X

  begin
    -- �A�h���X�����b�`����(BLOCK RAM�ɂȂ�)
    process(P_CLK)
      begin
        if (P_CLK'event and P_CLK='0') then
          addr10a <= P_MODE & P_ADDR;
          addr10b <= P_MODE & P_PNA;
        end if;
      end process;

    -- �ǂݏo������ 
    P_DOUT <= mem( conv_integer(addr10a) );
    P_MMD  <= mem( conv_integer(addr10b) );

    -- �������ݐ���
    process(P_CLK)
      begin
        if (P_CLK'event and P_CLK='0') then
          if (wea='1') then
            mem( conv_integer(addr10a) ) <= P_DIN;
          elsif (web='1') then
            mem( conv_integer(addr10b) ) <= P_PND;
          end if;
        end if;
      end process;

    -- MODE=0,1 �̎��� E0H�`FFH ���������ݕs��
    -- MODE=2   �̎��́A������ 80H�`BFH ���������ݕs��
    -- MODE=3   �̎��́A�X�ɉ����� 00H�`7FH ���������ݕs��

    -- CPU ����̏������ݐ���
    wea <= P_MR and P_RW and deca;
    process(P_MODE, addr10a(7), addr10a(6), addr10a(5))
      begin
        case P_MODE is
          when "00" =>
            deca <= not addr10a(7) or not addr10a(6) or not addr10a(5);
          when "01" =>
            deca <= not addr10a(7) or not addr10a(6) or not addr10a(5);
          when "10" =>
            deca <= not addr10a(7) or (addr10a(6) and not addr10a(5));
          when others =>
            deca <= addr10a(7) and addr10a(6) and not addr10a(5);
        end case;
    end process;

    -- �p�l������̏������ݐ���
    web    <= P_WRITE and P_SEL(2) and not P_SEL(1) and P_SEL(0) and decb;
    process(P_MODE, addr10b(7), addr10b(6), addr10b(5))
      begin
        case P_MODE is
          when "00" =>
            decb <= not addr10b(7) or not addr10b(6) or not addr10b(5);
          when "01" =>
            decb <= not addr10b(7) or not addr10b(6) or not addr10b(5);
          when "10" =>
            decb <= not addr10b(7) or (addr10b(6) and not addr10b(5));
          when others =>
            decb <= addr10b(7) and addr10b(6) and not addr10b(5);
        end case;
    end process;

  end BEHAVE;
