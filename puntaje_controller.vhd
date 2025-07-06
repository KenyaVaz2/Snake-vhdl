library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity puntaje_controller is
    Port (
        cl k            : in  STD_LOGIC;
        reset_n        : in  STD_LOGIC;
        comer          : in  STD_LOGIC;
        puntaje_out    : out integer range 0 to 9999
    ); 
end puntaje_controller;

architecture Behavioral of puntaje_controller is
    signal puntaje_reg : integer range 0 to 9999 := 0;
    signal comer_sync : std_logic_vector(2 downto 0) := "000";
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Sincronización y detección de flanco
            comer_sync <= comer_sync(1 downto 0) & comer;
            
            if reset_n = '0' then
                puntaje_reg <= 0;
            elsif comer_sync(2 downto 1) = "01" then -- Flanco ascendente
                -- Incremento de 100 puntos con rollover
                if puntaje_reg <= 9900 then
                    puntaje_reg <= puntaje_reg + 100;
                else
                    puntaje_reg <= 0; -- Reset al llegar al máximo
                end if;
            end if;
        end if;
    end process;
    
    puntaje_out <= puntaje_reg;
end Behavioral;