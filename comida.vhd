library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity comida is
    Port (
        clk        : in  STD_LOGIC;
        reset_n    : in  STD_LOGIC;
        comer      : in  STD_LOGIC;
        cabeza_x   : in  integer range 0 to 7;
        cabeza_y   : in  integer range 0 to 7;
        comida_x   : out integer range 0 to 7;
        comida_y   : out integer range 0 to 7;
        comida_led : out STD_LOGIC_VECTOR(7 downto 0);
        led_comida : out STD_LOGIC   -- 0 = encendido
    );
end comida;

architecture Behavioral of comida is
    signal pos_x : integer range 0 to 7 := 5;
    signal pos_y : integer range 0 to 7 := 5;
    signal counter : unsigned(31 downto 0) := (others => '0');
    signal led_timer : integer range 0 to 25000000 := 0; -- 0.5s a 50MHz
    signal led_state : std_logic := '1'; -- Inicialmente apagado
    signal comer_sync : std_logic := '0';
begin
    -- Sincronización de la señal comer
    process(clk)
    begin
        if rising_edge(clk) then
            comer_sync <= comer;
        end if;
    end process;

    -- Generador pseudoaleatorio y control del LED
    process(clk)
        variable need_new_pos : boolean := false;
    begin
        if rising_edge(clk) then
            counter <= counter + 1;
            
            -- Control del LED de comida
            if led_timer > 0 then
                led_timer <= led_timer - 1;
                led_state <= '0'; -- Encender LED
            else
                led_state <= '1'; -- Apagar LED
            end if;
            
            if reset_n = '0' then
                pos_x <= 5;
                pos_y <= 5;
                led_timer <= 0;
                led_state <= '1';
                need_new_pos := false;
            else
                -- Detección del flanco ascendente de comer
                if comer_sync = '1' and comer = '0' then
                    led_timer <= 25000000; -- Encender por 0.5s
                    need_new_pos := true;
                end if;
                
                -- Generar nueva posición solo cuando sea necesario
                if need_new_pos then
                    pos_x <= to_integer(counter(3 downto 1)) mod 8;
                    pos_y <= to_integer(counter(4 downto 2)) mod 8;
                    
                    -- Verificar que no coincida con la cabeza
                    if not (pos_x = cabeza_x and pos_y = cabeza_y) then
                        need_new_pos := false;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- Salidas
    comida_x <= pos_x;
    comida_y <= pos_y;
    led_comida <= led_state;
    
    -- Generar señal LED para la comida
    process(pos_x)
    begin
        comida_led <= (others => '0');
        comida_led(pos_x) <= '1';
    end process;
end Behavioral;