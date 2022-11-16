LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY Lab2 IS
    PORT ( clk     : IN  STD_LOGIC ;
           reset_l : IN  STD_LOGIC ;
           sw      : IN  STD_LOGIC_VECTOR (1 DOWNTO 0) ;
           r       : OUT STD_LOGIC_VECTOR (3 DOWNTO 0) ;
           g       : OUT STD_LOGIC_VECTOR (3 DOWNTO 0) ;
           b       : OUT STD_LOGIC_VECTOR (3 DOWNTO 0) ;
           hs      : OUT STD_LOGIC ;
           vs      : OUT STD_LOGIC);
END Lab2;

ARCHITECTURE mine OF Lab2 IS

    COMPONENT clk_wiz_0
    PORT (clk_out1 : OUT STD_LOGIC;
          clk_in1  : IN  STD_LOGIC);
    END COMPONENT;
    
    SIGNAL vga_clk      : STD_LOGIC ;
    SIGNAL reset_l_tmp  : STD_LOGIC ;
    SIGNAL reset_l_sync : STD_LOGIC ;
    SIGNAL sw_sync      : STD_LOGIC_VECTOR (1 DOWNTO 0) ;
    SIGNAL h            : STD_LOGIC_VECTOR (10 DOWNTO 0) ;
    SIGNAL v            : STD_LOGIC_VECTOR (9 DOWNTO 0) ;
    SIGNAL r_int        : STD_LOGIC_VECTOR (3 DOWNTO 0) ;
    SIGNAL g_int        : STD_LOGIC_VECTOR (3 DOWNTO 0) ;
    SIGNAL b_int        : STD_LOGIC_VECTOR (3 DOWNTO 0) ;
    SIGNAL hs_int       : STD_LOGIC ;
    SIGNAL vs_int       : STD_LOGIC ;
    
BEGIN

    mydcml:clk_wiz_0
    PORT MAP(clk_out1 => vga_clk ,
             clk_in1  => clk) ;

-- reset_l synchronizer 
    resetlsync: PROCESS(vga_clk)
    BEGIN
        IF(vga_clk'EVENT AND vga_clk = '1') THEN
            reset_l_tmp <= reset_l ;
            reset_l_sync <= reset_l_tmp ;
        END IF ;
    END PROCESS resetlsync;
    
-- input switch register
    swreg: PROCESS(vga_clk)
    BEGIN
        IF(vga_clk'EVENT AND vga_clk = '1') THEN
            sw_sync <= sw;
        END IF;
    END PROCESS swreg;
             
-- h counter
    hcounter: PROCESS(vga_clk)
    BEGIN
        IF(vga_clk'EVENT AND vga_clk = '1') THEN 
            IF(reset_l_sync = '0') THEN 
                h <= "00000000000" ; 
            ELSIF(reset_l_sync = '1' AND h < 1055) THEN
                h <= h + 1;
            ELSIF(reset_l_sync = '1' AND h = 1055) THEN
                h <= "00000000000" ;
            END IF ; 
        END IF ;
    END PROCESS hcounter;
    
-- v counter
    vcounter: PROCESS(vga_clk)
    BEGIN   
        IF(vga_clk'EVENT AND vga_clk = '1') THEN 
            IF (reset_l_sync = '0') THEN
                v <= "0000000000" ; 
            ELSIF (reset_l_sync = '1' AND h = 1055 AND v < 627) THEN
                v <= v + 1;
            ELSIF (reset_l_sync = '1' AND v = 627) THEN
                v <= "0000000000";
            END IF ; 
        END IF;
    END PROCESS vcounter;
    
-- combinational logic 
    comblogic : PROCESS(h, v, sw_sync)
    BEGIN   
        IF(h < 128) THEN
            hs_int <= '1';
        ELSE
            hs_int <= '0';
        END IF;
        
        IF(v > 623) THEN
            vs_int <= '1';
        ELSE
            vs_int <= '0';
        END IF;
        
        r_int <= "0000";
        g_int <= "0000";
        b_int <= "0000";
        IF((h < 216 OR h > 1015) AND (v < 23 OR v > 622)) THEN
            r_int <= "0000";
            g_int <= "0000";
            b_int <= "0000";
        ELSIF(sw_sync = "00" AND h > 215 AND h < 1016 AND v > 22 AND v < 623) THEN --logic 1 pure color
            r_int <= "0100";
            g_int <= "1110";
            b_int <= "0101";
        ELSIF(sw_sync = "01" AND h > 215 AND h < 1016 AND v > 22 AND v < 623) THEN --logic 2 vercital colors
            IF(h > 215 AND h < 600) THEN
                r_int <= h(0) & h(1) & h(2) & h(3);
                g_int <= h(1) & h(3) & h(2) & h(4);
                b_int <= h(2) & h(4) & h(3) & h(1);
            ELSIF(h > 599 AND h < 1016) THEN
                r_int <= v(0) & v(1) & v(2) & v(3);
                g_int <= v(1) & v(3) & v(2) & v(4);
                b_int <= v(2) & v(4) & v(3) & v(1);
            END IF;   
        ELSIF(sw_sync = "10" AND h > 215 AND h < 1016 AND v > 22 AND v < 623) THEN --logic 3 horizontal colors
            IF(v > 22 AND v < 300) THEN
                r_int <= h(0) & h(1) & v(2) & v(3);
                g_int <= h(1) & h(3) & v(2) & v(4);
                b_int <= h(1) & h(3) & v(2) & v(4);
            ELSIF(v > 299 AND v < 623) THEN
                r_int <= v(0) & v(1) & h(2) & h(3);
                g_int <= v(1) & v(3) & h(2) & h(4);
                b_int <= v(1) & v(3) & h(2) & h(4);
            END IF;
        ELSIF(sw_sync = "11" AND h > 215 AND h < 1016 AND v > 22 AND v < 623) THEN --logic 4 four squares colors
            IF(h > 215 AND h < 801 AND v > 22 AND v < 300) THEN
                r_int <= "0100";
                g_int <= "1110";
                b_int <= "0101";
            ELSIF(h > 215 AND h < 801 AND v > 299 AND v < 623) THEN
                r_int <= "1000";
                g_int <= "1000";
                b_int <= "0001";
            ELSIF(h > 800 AND h < 1016 AND v > 22 AND v < 300) THEN
                r_int <= "1000";
                g_int <= "1010";
                b_int <= "1101";
            ELSIF(h > 800 AND h < 1016 AND v > 299 AND v < 623) THEN
                r_int <= "1001";
                g_int <= "0010";
                b_int <= "1100";
            END IF; 
        END IF;
    END PROCESS comblogic;
    
-- output register
    outputregister: PROCESS(vga_clk)
    BEGIN
        IF(vga_clk'EVENT AND vga_clk = '1') THEN 
            IF(reset_l_sync = '0') THEN
                r <= "0000";
                g <= "0000";
                b <= "0000";
                hs <= '0';
                vs <= '0';
            ELSE
                r <= r_int;
                g <= g_int;
                b <= b_int;
                hs <= hs_int;
                vs <= vs_int;
            END IF;
        END IF;
    END PROCESS outputregister;
    
END mine;