--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2012 by
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
-- TaC/tac_ps2.vhd : TaC PS/2 interface
--
-- 2012.01.22           : entity ���A������
-- 2012.01.20           : �쑺�N�̃R�[�h����荞��
--
-- $Id
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity TAC_PS2 is
    Port (
      P_CLK     : in std_logic;                       -- 50MHz
      P_RESET   : in std_logic;                       -- Reset    
      P_IOW     : in std_logic;                       -- I/O Write
      P_IOR     : in std_logic;                       -- I/O Read
      P_EN      : in std_logic;                       -- Enable
      P_ADDR    : in std_logic;                       -- Address
      P_DOUT    : out std_logic_vector(7 downto 0);   -- Data Output
      P_DIN     : in std_logic_vector(7 downto 0);    -- Data Input
      P_PS2D    : inout std_logic;                    -- PS/2 Data
      P_PS2C    : inout std_logic;                    -- PS/2 Clock
      P_INT_W   : out std_logic;                      -- PS/2 ���M���荞��
      P_INT_R   : out std_logic                       -- PS/2 ��M���荞��
    );
end TAC_PS2;

architecture Behavioral of TAC_PS2 is

signal PS2D_host : std_logic;

-- 50M Hz �N���b�N �� PS2C �� ����
signal PS2C_buf : std_logic_vector(1 downto 0);       -- �O��ƍ����PS2C�̒l

-- Address Decode
signal IOW_PS2_Dat  : std_logic;                      -- Write Data
signal IOR_PS2_Dat  : std_logic;                      -- Read Data
signal IOW_PS2_Ctl  : std_logic;                      -- Control (Write)
signal IOR_PS2_Sta  : std_logic;                      -- Status (Read)


-- �f�o�C�X����̎�M�p
signal R_D_Reg      : std_logic_vector(7 downto 0);
signal R_S_Reg      : std_logic_vector(7 downto 0);   -- �V�t�g���W�X�^
signal R_Full       : std_logic;                      -- ��M���� = 1
signal R_Ena        : std_logic;                      -- Read Enable
signal R_Int_Ena    : std_logic;                      -- ���荞�݋���
signal R_bitcnt     : std_logic_vector(3 downto 0);   -- ��M�r�b�g�J�E���^
signal R_WaitCnt    : std_logic_vector(12 downto 0);
signal R_Parity     : std_logic;

-- �f�o�C�X�ւ̑��M�p
signal W_D_Reg      : std_logic_vector(7 downto 0);
signal W_S_Reg      : std_logic_vector(7 downto 0);   -- �V�t�g���W�X�^
signal W_Full       : std_logic;                      -- ���M���� = 0
signal W_Ena        : std_logic;                      -- Write Enable
signal W_Int_Ena    : std_logic;                      -- ���荞�݋���
signal W_bitcnt     : std_logic_vector(3 downto 0);   -- ���M�r�b�g�J�E���^
signal W_State      : std_logic_vector( 1 downto 0 );
signal W_Wait_Cnt   : std_logic_vector(12 downto 0);
signal W_Parity     : std_logic;

begin
    P_PS2C <= '0' when ( W_Ena = '1' and W_State = "00" ) else 'Z' ;
    P_PS2D <= '0' when ( PS2D_host = '0' and W_Ena = '1' and
                            W_State = "01" and W_bitcnt<10 ) else 'Z' ;
    
    IOW_PS2_Dat <= P_IOW    and P_EN and not P_ADDR;
    IOR_PS2_Dat <= P_IOR    and P_EN and not P_ADDR;
    IOW_PS2_Ctl <= P_IOW    and P_EN and     P_ADDR;
    IOR_PS2_Sta <= P_IOR    and P_EN and     P_ADDR;

    P_INT_W <= (not W_Full) and W_Int_Ena;
    P_INT_R <=      R_Full  and R_Int_Ena;

    -- Data Bus
    process(IOR_PS2_Dat , IOR_PS2_Sta , R_D_Reg , W_Full , R_Full )
    begin
        if( IOR_PS2_Dat = '1' ) then
            P_DOUT <= R_D_Reg;
        else
            if( IOR_PS2_Sta = '1' ) then
                P_DOUT(7) <= not W_Full;
                P_DOUT(6) <=     R_Full;
            else
                P_DOUT(7) <= '0';
                P_DOUT(6) <= '0';
            end if;
            P_DOUT(5 downto 0) <= "000000";
        end if;
    end process;
    
    -- Ctl
    process(P_CLK, P_RESET)
    begin
        if(P_RESET = '0' ) then
            W_Int_Ena <= '0';
            R_Int_Ena <= '0';
        elsif(P_CLK'event and P_CLK = '1') then
            if( IOW_PS2_Ctl = '1' ) then    
                W_Int_Ena <= P_DIN(7);  
                R_Int_Ena <= P_DIN(6);
            end if;
        end if;
    end process;
    
    -- 2�̃N���b�N�Ԃœ������Ƃ�
    process(P_CLK , P_RESET)
    begin
        if(P_RESET = '0' ) then
            PS2C_buf <= "11";
        elsif(P_CLK'event and P_CLK = '1') then
            PS2C_buf <=  P_PS2C & PS2C_buf(1);
        end if;
    end process;
    
    
    -- Write (���M)
    process(P_CLK, P_RESET)
    begin
        if( P_RESET = '0' ) then
            W_Full  <= '0';
            W_D_Reg <= "00000000";
        elsif( P_CLK'event and P_CLK='1' ) then
            if( IOW_PS2_Dat = '1' ) then
                W_D_Reg <= P_DIN;
                W_Full <= '1';
            elsif( W_Ena = '0' ) then
                W_Full <= '0';
            end if;
        end if;
    end process;
    
    process(P_CLK, P_RESET)
    begin
        if( P_RESET = '0' ) then
            W_State <= "00";
            W_Ena       <= '0';
            W_Wait_Cnt <= "0000000000000";
            W_bitcnt <= "0000";
            PS2D_host <= '0';
            W_S_Reg <= "00000000";
            W_Parity <= '1';
        elsif( P_CLK'event and P_CLK = '1' ) then
            if( W_Ena = '1' ) then
                -- �o��
                case W_State is
                    when "00" =>
                        if( W_Wait_Cnt = 5010 ) then
                            -- 100usec�ȏ�҂�����
                            -- ���M �v��
                            W_State <= "01";
                        else
                            W_Wait_Cnt <= W_Wait_Cnt + '1';
                        end if;
                    when "01" =>
                        if( PS2C_buf = "01" ) then  -- �l�K�e�B�u�G�b�W
                            if( W_bitcnt < 8 ) then
                                PS2D_host <= W_S_Reg(0); -- �f�[�^�o��
                                -- �p���e�B�v�Z
                                W_Parity <= W_Parity xor W_S_Reg(0);
                                W_S_Reg <= '0' & W_S_Reg(7 downto 1);
                            elsif( W_bitcnt = 8 ) then
                                -- �p���e�B �r�b�g ���M
                                PS2D_host <= W_Parity;
                            elsif( W_bitcnt = 9 ) then
                                PS2D_host <= 'Z';
                            else
                                if( P_PS2D = '0' ) then
                                    -- ACK
                                    W_State <= "10";
                                end if;
                            end if;
                            W_bitcnt <= W_bitcnt + '1';
                        end if;
                    when others =>
                        if( P_PS2D = '1' ) then
                            -- ���M �I��
                            W_Ena <= '0';
                        end if;
                    end case;
            elsif( W_Full = '1' ) then
                W_Ena <= '1';
                W_State <= "00";
                W_S_Reg <= W_D_Reg;
                W_Parity <= '1';
                W_Wait_Cnt <= "0000000000000";
                W_bitcnt <= "0000";
                PS2D_host <= '0';
            end if;
        end if;
    end process;
    
    -- Read (��M)
    process(P_CLK, P_RESET)
    begin
        if( P_RESET = '0' ) then
            R_Full      <= '0';
            R_D_Reg <= "00000000";
            R_WaitCnt <= "0000000000000";
        elsif( P_CLK'event and P_CLK = '1' ) then
            if( PS2C_buf = "01" and R_bitcnt = "1000" and
                R_WaitCnt > 5009 and R_Parity = P_PS2D ) then
                -- �p���e�B �� ������
                R_Full <= '1';
                R_D_Reg <= R_S_Reg;
                R_WaitCnt <= "0000000000000";
            elsif( IOR_PS2_Dat = '1' ) then
                R_Full <= '0';
            elsif( R_WaitCnt < 5010 ) then
                R_WaitCnt <= R_WaitCnt + '1';
            end if;
        end if;
    end process;
        
    process(P_RESET, P_CLK)
    begin
        if( P_RESET = '0' ) then
            R_S_Reg <= "00000000";
            R_Ena <= '0';
            R_bitcnt <= "0000";
        elsif( P_CLK = '1' and P_CLK'event ) then
            if( W_Ena = '1' ) then
                R_Ena <= '0';
                R_bitcnt <= "0000";
            elsif( PS2C_buf = "01" ) then   -- �l�K�e�B�u �G�b�W
                -- ��M ����
                if( R_Ena = '1' ) then
                    if( R_bitcnt < 8 ) then
                        -- �V�t�g���W�X�^�Ƀf�[�^����
                        R_S_Reg(7 downto 0) <= P_PS2D & R_S_Reg(7 downto 1);
                        R_Parity <= R_Parity xor P_PS2D; -- �p���e�B�v�Z
                        R_bitcnt <= R_bitcnt + '1';
                    else
                        -- ��M �I��
                        R_Ena <= '0';
                        R_bitcnt <= "0000";
                    end if;
                elsif( P_PS2D = '0') then
                    -- ��M �J�n
                    R_Ena <= '1';
                    R_bitcnt <= "0000";
                    R_Parity <= '1';
                end if;
            end if;
        end if;
    end process;
end Behavioral;
