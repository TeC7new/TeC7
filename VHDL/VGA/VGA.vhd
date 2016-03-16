--
-- TeC7 VHDL Source Code
--
-- VGA interface
--
-- 2016. 1. 8 process �̃Z���V�r���e�B�[���X�g�C���iwarning �΍�), �d��
-- 2011. 2. 7 �G���Y�G���W�j�A�����O�������

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity VGA is
    Port ( P_CLK   : in std_logic; -- VGA ����p
           P_CLK_CPU : in std_logic; -- CPU bus �p VideoRAM Access clock
			  P_RESET : in std_logic;  -- RESET
           P_WE : in std_logic;
           P_ADDR : in std_logic_vector(10 downto 0);
           P_DIN : in std_logic_vector(7 downto 0);
           P_DOUT : out std_logic_vector(7 downto 0);
           R,G,B : out std_logic;
           HS,VS : out std_logic
    );
end VGA;

architecture Behavioral of VGA is

-- �����M���p�o�b�t�@
signal S_HS : std_logic;
signal S_VS : std_logic;
-- �f���M���p�o�b�t�@
signal r_buf : std_logic;
signal g_buf : std_logic;
signal b_buf : std_logic;
-- �J�E���^
signal CNT_P : std_logic_vector(9 downto 0);    -- ���� pixel �J�E���^
signal CNT_L : std_logic_vector(9 downto 0);    -- ���� line �J�E���^
signal CNT_PC : std_logic_vector(3 downto 0);   -- ���� pixel �J�E���^
signal CNT_LC : std_logic_vector(4 downto 0);   -- ���� line �J�E���^
signal CNT_VA : std_logic_vector(10 downto 0);  -- VRAM address �J�E���^
signal CNT_CU : std_logic_vector(25 downto 0);  -- �J�[�\���̃u�����N�p
-- ���W�X�^
signal CNT_VA_prev : std_logic_vector(10 downto 0); -- �s���� VRAM address 
signal outbuf : std_logic_vector(7 downto 0);   -- �t�H���g1�񕪃V�t�g���W�X�^
signal COLOR : std_logic_vector(7 downto 0) := "00001111";  -- �����F�ݒ�
signal CX    : std_logic_vector(6 downto 0) := "0000000";   -- �J�[�\��X���W
signal CY    : std_logic_vector(4 downto 0) := "00000";     -- �J�[�\��y���W
signal CXV   : std_logic_vector(6 downto 0) := "0000000";   -- �J�[�\��X���W
signal CYV   : std_logic_vector(4 downto 0) := "00000";     -- �J�[�\��y���W
signal CA    : std_logic_vector(10 downto 0);
signal CAY   : std_logic_vector(10 downto 0);
-- �C�l�[�u��
signal vram_en : std_logic; -- VRAM enable
signal font_ld : std_logic; -- FONT ROM output load
signal h_act_work : std_logic; -- �����\���G���A
signal h_act : std_logic_vector(3 downto 0); -- �����\���G���A�x����
signal v_act : std_logic; -- �����\���G���A
signal v_vact : std_logic; -- ���������\���G���A
signal h_end : std_logic; -- �����\���G���A����������
signal v_up : std_logic; -- CNT_L �J�E���g�A�b�v
-- ���̑��M����
signal CODE : std_logic_vector(7 downto 0); -- ���� code
signal LINE : std_logic_vector(7 downto 0); -- �Ђƕ����P�� FONT data
signal cur  : std_logic;                    -- �J�[�\����\������^�C�~���O

-- ����ݒ�l
constant CX_ADDR : integer := 2045; -- 0x7FD
constant CY_ADDR : integer := 2046; -- 0x7FE
constant COLOR_ADDR : integer := 2047; -- 0x7FF
constant H_WIDTH : integer := 798;
constant H_ACTIVE : integer := 640;
constant H_SYNC_START : integer := H_ACTIVE + 5 + 15;
-- "+5" �� Active �G���A�̒x�����ԕ�
constant H_SYNC_END : integer := H_SYNC_START + 96;
constant CNT_PC_MAX : integer := 8;
constant CNT_PC_EN : integer := 1;
constant CNT_PC_LD : integer := CNT_PC_EN + 2;
constant V_WIDTH : integer := 525;
constant V_ACTIVE : integer := 475;
constant V_SYNC_START : integer := V_ACTIVE + 2 + 10;
-- "+2" �� Active �G���A�� 480 �ɑ΂��� 5 [line] �s���̂��߂̒���
-- ��ʏ㕔�� 3 [line] ������ 2[line] �}���Œ���
constant V_SYNC_END : integer := V_SYNC_START + 2;
constant V_SYNC_P : integer := H_SYNC_START;
constant V_VACTIVE : integer := 16;
constant CNT_LC_MAX : integer := 19;

signal logic0, logic1 : std_logic;

---- �g�p����R���|�[�l���g�̐錾 ---
-- VideoRAM
component VideoRAM
    Port ( P_CLKA : in std_logic;
           P_EN : in std_logic;
           P_ADDRA : in std_logic_vector(10 downto 0);
           P_DOUTA : out std_logic_vector(7 downto 0);
   
           P_CLKB : in std_logic;
           P_WE : in std_logic;
           P_ADDRB : in std_logic_vector(10 downto 0);
           P_DIN : in std_logic_vector(7 downto 0);
           P_DOUTB : out std_logic_vector(7 downto 0)
   );
end component;
-- CharaGeneROM
component CharGene
  port (
    P_CLK  : in std_logic;
    P_CODE : in std_logic_vector(7 downto 0);
    P_HEIGHT : in  std_logic_vector(3 downto 0);
    P_DOUT : out std_logic_vector(7 downto 0)
  );
end component;

begin
    logic0 <= '0';
    logic1 <= '1';

    -- �e�R���|�[�l���g�Ɛڑ�  
    -- VideoRAM
    vram : VideoRAM
        port map (
            P_CLKA => P_CLK,
            P_EN => vram_en,
            P_ADDRA => CNT_VA,
            P_DOUTA => CODE,
            
            P_CLKB => P_CLK_CPU,
            P_WE => P_WE,
            P_ADDRB => P_ADDR,
            P_DIN => P_DIN,
            P_DOUTB => P_DOUT
        );
    
    -- CharGeneROM�h�G
    cgrom: CharGene
        port map (
            P_CLK  => P_CLK,
            P_CODE => CODE,
            P_HEIGHT => CNT_LC(3 downto 0),
            P_DOUT => LINE
        );

    -- �F�ݒ背�W�X�^ (COLOR: bit7/4=-, bit6/2=R, bit5/1=G, bit4/0=B)
    --  upper = �w�i�F ("0000"=��(Default), "0111"=��)
    --  lower = �����F ("0000"=��         , "0111"=��(Default))
    process(P_RESET, P_CLK_CPU)
    begin
        if (P_RESET = '0') then
            COLOR <= "00000111";
        elsif (P_CLK_CPU = '1' and P_CLK_CPU'event) then
            if (P_WE = logic1 and P_ADDR = COLOR_ADDR) then
                COLOR <= P_DIN;
            end if;
        end if;
    end process;

    -- �J�[�\���A�h���X
    process(P_RESET, P_CLK_CPU)
    begin
        if (P_RESET = '0') then
            CX <= "0000000";
            CY <= "00000";
        elsif (P_CLK_CPU = '1' and P_CLK_CPU'event) then
            if (P_WE = logic1 and P_ADDR = CX_ADDR) then
                CX <= P_DIN(6 downto 0);
            elsif (P_WE = logic1 and P_ADDR = CY_ADDR) then
                CY <= P_DIN(4 downto 0);
            end if;
        end if;
    end process;

    -- ���� pixel �J�E���^ (CNT_P)
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (CNT_P = (H_WIDTH - 1)) then
                CNT_P <= (others => '0');
            else
                CNT_P <= CNT_P + '1';
            end if;
        end if;
    end process;

    -- ���������M�� (S_HS)
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (CNT_P = (H_SYNC_START - 1)) then
                S_HS <= logic1;
            elsif (CNT_P = (H_SYNC_END - 1)) then
                S_HS <= logic0;
            else
                S_HS <= S_HS;
            end if;
        end if;
    end process;

    HS <= not S_HS;
    h_act_work <= logic1 when (CNT_P <= (H_ACTIVE - 1)) else logic0;
    v_up <= logic1 when (CNT_P = (H_WIDTH - 1)) else logic0;

    -- �����\���L���G���A
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            h_act <= h_act(2 downto 0) & h_act_work;
        end if;
    end process;
    
    h_end <= not h_act_work and h_act(0); 

    -- ���� pixel �J�E���^ (CNT_PC)
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (h_act_work = logic1 and v_vact = logic1) then
                if (CNT_PC = (CNT_PC_MAX - 1)) then
                    CNT_PC <= (others => '0');
                else
                    CNT_PC <= CNT_PC + '1';
                end if;
            else
                CNT_PC <= (others => '0');
            end if;
        end if;
    end process;

    vram_en <= logic1 when (CNT_PC = CNT_PC_EN) else logic0;
    font_ld <= logic1 when (CNT_PC = CNT_PC_LD) else logic0;

    -- �J�[�\���\��
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
          if (CNT_CU=50000000) then                 -- �J�[�\���u�����N����
            CNT_CU <= (others => '0');
          else
            CNT_CU <= CNT_CU + 1;
          end if;
        end if;
    end process;

    -- �J�[�\���A�h���X
    CA  <= (CYV & "000000")+("00" & CYV & "0000") + ("0000" & CXV);

    process(P_CLK)
    begin
        if (P_CLK='1' and P_CLK'event) then
          CXV <= CX;   -- CPU �N���b�N����VGA �N���b�N�ɋ��n��
          CYV <= CY;   -- (���̕����̓^�C�~���O���񂪖�������Ȃ��̂ŁA
                       --  UCF�t�@�C����TIG(�^�C�~���O����)�������Ă���)

          if (vram_en=logic1) then
            if (CNT_VA=CA and CNT_CU(25 downto 23)>="011") then
              cur <= logic1;                        -- �J�[�\����\������ׂ�
            else
              cur <= logic0;
            end if;
          end if;
        end if;
    end process;

    -- FONT �f�[�^�o�� ���񁨒���ϊ�
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (font_ld = logic1) then
              if (cur=logic0) then
                outbuf <= LINE;
              else
                outbuf <= not LINE;                 -- ���[�o�[�X�ŃJ�[�\���\��
              end if;
            else
                outbuf <= outbuf(6 downto 0) & '0';
            end if;
        end if;
    end process;

    -- VGA �o�� (R/G/B) �F�ݒ聕�o��
    --process(P_CLK)
    process(h_act, v_act, outbuf, color, logic0, logic1)
    begin
        --if (P_CLK = '1' and P_CLK'event) then
            if (h_act(3) = logic1 and v_act = logic1) then
                if (outbuf(7) = logic1) then -- FONT �F�ݒ�
                    r_buf <= COLOR(2);
                    g_buf <= COLOR(1);
                    b_buf <= COLOR(0);
                else                         -- �w�i�F�ݒ�
                    r_buf <= COLOR(6);
                    g_buf <= COLOR(5);
                    b_buf <= COLOR(4);
                end if;
            else                             -- ����ȊO�͍� (R/G/B = "0")
                r_buf <= logic0;
                g_buf <= logic0;
                b_buf <= logic0;
            end if; 
        --end if;
    end process;

    R <= r_buf;
    G <= g_buf;
    B <= b_buf;

    -- VRAM address �J�E���^ (CNT_VA)
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (v_act = logic0) then
                CNT_VA <= (others => '0');
            elsif (h_end = logic1 and CNT_LC /= (V_VACTIVE - 1)) then
                CNT_VA <= CNT_VA_prev;
            elsif (vram_en =logic1) then
                CNT_VA <= CNT_VA + '1';
            else
                CNT_VA <= CNT_VA;
            end if;
        end if;
    end process;

    -- VRAM address �J�E���^ �����l (CNT_VA_prev)
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (v_act = logic0) then
                CNT_VA_prev <= (others => '0');
            elsif (h_end = logic1 and CNT_LC = (V_VACTIVE - 1)) then
                CNT_VA_prev <= CNT_VA;
            else
                CNT_VA_prev <= CNT_VA_prev;
            end if;
        end if;
    end process;

    -- ���� line �J�E���^ (CNT_L)
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (v_up = logic1) then
                if (CNT_L = (V_WIDTH - 1)) then
                    CNT_L <= (others => '0');
                else
                    CNT_L <= CNT_L + '1';
                end if;
            else
                CNT_L <= CNT_L;
            end if;
        end if;
    end process;

    -- ���������M�� (S_VS)
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (CNT_L = (V_SYNC_START - 1) and  CNT_P = (V_SYNC_P - 1)) then
                S_VS <= logic1;
            elsif (CNT_L = (V_SYNC_END - 1) and  CNT_P = (V_SYNC_P - 1)) then
                S_VS <= logic0;
            else
                S_VS <= S_VS;
            end if;
        end if;
    end process;

    VS <= not S_VS;
    v_act <= logic1 when (CNT_L <= (V_ACTIVE - 1)) else logic0;

    -- ���� line �J�E���^ (CNT_LC)
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (v_act = logic1) then
                if (v_up = logic1) then
                    if (CNT_LC = (CNT_LC_MAX - 1)) then
                        CNT_LC <= (others => '0');
                    else
                        CNT_LC <= CNT_LC + '1';
                    end if;
                else
                    CNT_LC <= CNT_LC;
                end if;
            else
                CNT_LC <= (others => '0');
            end if;
        end if;
    end process;

    v_vact <= logic1 when (CNT_LC <= (V_VACTIVE - 1) and v_act = logic1) else logic0;

end Behavioral;
