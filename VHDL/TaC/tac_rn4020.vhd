--
-- TaC VHDL Source Code
--    Tokuyama kousen Educational Computer 16 bit Version
--
-- Copyright (C) 2017 by
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
--  TaC/tac_RN4020.vhd : RN4020 �C���^�t�F�[�X
--
-- 2017.05.09          : �V�K�쐬
--
-- $Id
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity TAC_RN4020 is
  port ( P_CLK     : in  std_logic;                      -- 49.1520MHz
         P_RESET   : in  std_logic;                      -- Reset
         P_IOW     : in  std_logic;                      -- I/O Write
         P_IOR     : in  std_logic;                      -- I/O Read
         P_EN      : in  std_logic;                      -- Enable
         P_ADDR    : in  std_logic_vector(1 downto 0);   -- Address(2 downto 1)
         P_DOUT    : out std_logic_vector(7 downto 0);   -- Data Output
         P_DIN     : in  std_logic_vector(7 downto 0);   -- Data Input
         P_INT_TxD : out std_logic;                      -- ���M���荞��
         P_INT_RxD : out std_logic;                      -- ��M���荞��

         P_TxD     : out std_logic;                      -- �V���A���o��
         P_RxD     : in  std_logic;                      -- �V���A������
         P_CTS     : in  std_logic;                      -- Clear To Send
         P_RTS     : out std_logic;                      -- Request To Send

         P_SW      : out std_logic;                      -- RN4020_SW
         P_CMD     : out std_logic;                      -- RN4020_CMD/MLDP
         P_HW      : out std_logic                       -- RN4020_HW
       );
end TAC_RN4020;

architecture RTL of TAC_RN4020 is

-- Address decode
signal i_en_sio    : std_logic;
signal i_en_cmd    : std_logic;

-- Internal bus
signal i_data      : std_logic_vector(7 downto 0);
signal i_cts       : std_logic;
signal i_rts       : std_logic;

-- Registers
signal i_cmd       : std_logic_vector(3 downto 0) := "0001";

-- SIO
component TAC_SIO
  port ( P_CLK     : in  std_logic;                      -- 49.1520MHz
         P_RESET   : in  std_logic;                      -- Reset
         P_IOW     : in  std_logic;                      -- I/O Write
         P_IOR     : in  std_logic;                      -- I/O Read
         P_EN      : in  std_logic;                      -- Enable
         P_ADDR    : in  std_logic;                      -- Address
         P_DOUT    : out std_logic_vector(7 downto 0);   -- Data Output
         P_DIN     : in  std_logic_vector(7 downto 0);   -- Data Input
         P_INT_TxD : out std_logic;                      -- SIO ���M���荞��
         P_INT_RxD : out std_logic;                      -- SIO ��M���荞��

         P_TxD     : out std_logic;                      -- �V���A���o��
         P_RxD     : in  std_logic;                      -- �V���A������
         P_CTS     : in  std_logic;                      -- Clear To Send
         P_RTS     : out std_logic;                      -- Request To Send

         P_BAUDIV  : in  std_logic_vector(12 downto 0)   -- Baud Divsior
       );
end component;

begin
  -- Address decoder
  i_en_sio <= (not P_ADDR(1)) and P_EN;
  i_en_cmd <= '1' when (P_ADDR="10" and P_EN='1') else '0';
  
  -- Data Bus
  P_DOUT <= i_data when i_en_sio='1' else
            "0000"&i_cmd when i_en_cmd='1' else "00000000";

  -- CMD
  P_SW  <= i_cmd(0);
  P_CMD <= i_cmd(1);
  P_HW  <= i_cmd(2);
    
  process (P_CLK, P_RESET)
  begin
    if (P_RESET='0') then
      i_cmd <= "0001";
    elsif (P_CLK'event and P_CLK='1') then
      if (P_IOW='1' and i_en_cmd='1') then
        i_cmd <= P_DIN(3 downto 0);
      end if;
    end if;
  end process;

  -- SIO
  i_cts <= (not i_cmd(3)) or P_CTS;     -- �n�[�h�E�F�A�t���[����OFF�Ȃ�펞ON
  P_RTS <= (not i_cmd(3)) or i_rts;     -- �n�[�h�E�F�A�t���[����OFF�Ȃ�펞ON

  TAC_SIO1 : TAC_SIO
  port map (
         P_CLK      => P_CLK,
         P_RESET    => P_RESET,
         P_IOW      => P_IOW,
         P_IOR      => P_IOR,
         P_EN       => i_en_sio,
         P_ADDR     => P_ADDR(0),
         P_DOUT     => i_data,
         P_DIN      => P_DIN,
         P_INT_TxD  => P_INT_TxD,
         P_INT_RxD  => P_INT_RxD,
         P_TxD      => P_TxD,
         P_RxD      => P_RxD,
         P_CTS      => i_cts,
         P_RTS      => i_rts,
         P_BAUDIV   => "0000110101011"  -- 115,200 baud
       );
end RTL;
