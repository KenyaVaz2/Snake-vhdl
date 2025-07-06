library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity snake_basic is
    Port (
        -- Entradas
        clk           : in  STD_LOGIC;  -- Reloj 50 MHz
        reset_n       : in  STD_LOGIC;  -- Reset activo en bajo
        enter_raw     : in  STD_LOGIC;  -- Botón enter
        arriba_raw    : in  STD_LOGIC;  -- Botón arriba
        izquierda_raw : in  STD_LOGIC;  -- Botón izquierda
        derecha_raw   : in  STD_LOGIC;  -- Botón derecha
        abajo_raw     : in  STD_LOGIC;  -- Botón abajo
        
        -- Salidas para matriz LED
        filas         : out STD_LOGIC_VECTOR(7 downto 0);  -- Filas matriz 8x8
        columnas      : out STD_LOGIC_VECTOR(7 downto 0);  -- Columnas matriz 8x8
        led_comida    : out STD_LOGIC;  -- LED indicador de comida
        
        -- Salidas para display 7 segmentos (4 dígitos)
        seg7_catodos : out STD_LOGIC_VECTOR(6 downto 0);  -- Segmentos a-g
        seg7_anodos  : out STD_LOGIC_VECTOR(3 downto 0)   -- Habilitación de dígitos
    );
end snake_basic;

architecture Behavioral of snake_basic is
    -- Configuración de velocidad (3 movimientos/segundo)
    constant MOVEMENT_SPEED : integer := 6000000;  -- 50MHz/3 ≈ 16,666,667
    
    -- Estados del juego
    type state_type is (WAIT_START, MOVE_UP, MOVE_LEFT, MOVE_RIGHT, MOVE_DOWN);
    signal state : state_type := WAIT_START;
    
    -- Matriz LED
    type matriz_8x8 is array(0 to 7) of STD_LOGIC_VECTOR(7 downto 0);
    signal led_matrix : matriz_8x8 := (others => (others => '0'));
    
    -- Control de visualización
    signal refresh_counter : integer range 0 to 1023 := 0;
    signal fila_actual : integer range 0 to 7 := 0;
    
    -- Serpiente
    constant MAX_LENGTH : integer := 64;
    type body_element is record
        x : integer range 0 to 7;
        y : integer range 0 to 7;
    end record;
    type body_array_type is array (0 to MAX_LENGTH-1) of body_element;
    signal snake_body : body_array_type;
    signal body_length : integer range 2 to MAX_LENGTH := 2;
    
    -- Control de movimiento
    signal move_counter : integer range 0 to MOVEMENT_SPEED := 0;
    signal move_enable : std_logic := '0';
    signal current_direction : STD_LOGIC_VECTOR(1 downto 0) := "00";
    
    -- Sistema de botones
    signal enter_db, arriba_db, izquierda_db, derecha_db, abajo_db : std_logic;
    signal enter_sync, arriba_sync, izquierda_sync, derecha_sync, abajo_sync : std_logic_vector(2 downto 0) := (others => '0');
    signal enter_counter, arriba_counter, izquierda_counter, derecha_counter, abajo_counter : integer range 0 to 100000 := 0;
    
    -- Comida
    signal comida_x_int, comida_y_int : integer range 0 to 7 := 0;
    signal comida_led_int : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal comer : std_logic := '0';
    signal led_comida_int : std_logic;
    
    -- Puntaje y display
    signal puntaje : integer range 0 to 9999 := 0;
    signal display_counter : integer range 0 to 50000 := 0;
    signal digit_select : integer range 0 to 3 := 0;
    signal bcd_digit : integer range 0 to 9 := 0;
    
    component comida
        Port (
            clk        : in  STD_LOGIC;
            reset_n    : in  STD_LOGIC;
            comer      : in  STD_LOGIC;
            cabeza_x   : in  integer range 0 to 7;
            cabeza_y   : in  integer range 0 to 7;
            comida_x   : out integer range 0 to 7;
            comida_y   : out integer range 0 to 7;
            comida_led : out STD_LOGIC_VECTOR(7 downto 0);
            led_comida : out STD_LOGIC
        );
    end component;

begin
    -- Instancia del módulo de comida
    u_comida: comida port map(
        clk => clk,
        reset_n => reset_n,
        comer => comer,
        cabeza_x => snake_body(0).x,
        cabeza_y => snake_body(0).y,
        comida_x => comida_x_int,
        comida_y => comida_y_int,
        comida_led => comida_led_int,
        led_comida => led_comida_int
    );

    led_comida <= led_comida_int;

    -- Proceso de antirrebote para botones
    process(clk)
        constant DEBOUNCE_TIME : integer := 50000;  -- ~1ms a 50MHz
    begin
        if rising_edge(clk) then
            -- Sincronización de botones
            enter_sync <= enter_sync(1 downto 0) & (not enter_raw);
            arriba_sync <= arriba_sync(1 downto 0) & (not arriba_raw);
            izquierda_sync <= izquierda_sync(1 downto 0) & (not izquierda_raw);
            derecha_sync <= derecha_sync(1 downto 0) & (not derecha_raw);
            abajo_sync <= abajo_sync(1 downto 0) & (not abajo_raw);
            
            -- Lógica antirrebote para cada botón
            if enter_sync(2) /= enter_db then
                if enter_counter = DEBOUNCE_TIME then 
					 enter_db <= enter_sync(2); end if;
                enter_counter <= enter_counter + 1;
            else enter_counter <= 0; end if;
            
            if arriba_sync(2) /= arriba_db then
                if arriba_counter = DEBOUNCE_TIME then 
					 arriba_db <= arriba_sync(2); end if;
                arriba_counter <= arriba_counter + 1;
            else arriba_counter <= 0; end if;
            
            if izquierda_sync(2) /= izquierda_db then
                if izquierda_counter = DEBOUNCE_TIME then 
					 izquierda_db <= izquierda_sync(2); end if;
                izquierda_counter <= izquierda_counter + 1;
            else izquierda_counter <= 0; end if;
            
            if derecha_sync(2) /= derecha_db then
                if derecha_counter = DEBOUNCE_TIME then derecha_db <= derecha_sync(2); end if;
                derecha_counter <= derecha_counter + 1;
            else derecha_counter <= 0; end if;
            
            if abajo_sync(2) /= abajo_db then
                if abajo_counter = DEBOUNCE_TIME then abajo_db <= abajo_sync(2); end if;
                abajo_counter <= abajo_counter + 1;
            else abajo_counter <= 0; end if;
        end if;
    end process;

    -- Divisor de frecuencia para movimiento de la serpiente
    process(clk)
    begin
        if rising_edge(clk) then
            if move_counter = MOVEMENT_SPEED then
                move_counter <= 0;
                move_enable <= '1';
            else
                move_counter <= move_counter + 1;
                move_enable <= '0';
            end if;
        end if;
    end process;

    -- Lógica principal del juego FMS 
    process(clk)
        variable new_head_x, new_head_y : integer range 0 to 7;
        variable grow_snake : boolean := false;
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                -- Reset del juego
                state <= WAIT_START;
                body_length <= 2;
                snake_body(0).x <= 3;  -- Cabeza inicial
                snake_body(0).y <= 3;
                snake_body(1).x <= 2;  -- Cola inicial
                snake_body(1).y <= 3;
                current_direction <= "10";  -- Dirección inicial: derecha
                comer <= '0';
                puntaje <= 0;
            else
                comer <= '0';  -- Resetear señal de comer cada ciclo
                
                case state is
                    when WAIT_START =>
                        if enter_db = '1' then
                            state <= MOVE_RIGHT;  -- Comenzar movimiento automático
                        end if;
                        
                    when MOVE_UP | MOVE_LEFT | MOVE_RIGHT | MOVE_DOWN =>
                        if move_enable = '1' then
                            -- Determinar nueva posición de cabeza
                            case current_direction is
                                when "00" =>  -- Arriba
                                    new_head_y := (snake_body(0).y - 1) mod 8;
                                    new_head_x := snake_body(0).x;
                                when "01" =>  -- Izquierda
                                    new_head_x := (snake_body(0).x - 1) mod 8;
                                    new_head_y := snake_body(0).y;
                                when "10" =>  -- Derecha
                                    new_head_x := (snake_body(0).x + 1) mod 8;
                                    new_head_y := snake_body(0).y;
                                when "11" =>  -- Abajo
                                    new_head_y := (snake_body(0).y + 1) mod 8;
                                    new_head_x := snake_body(0).x;
                                when others =>
                                    null;
                            end case;

                            -- Verificar si come comida
                            grow_snake := (new_head_x = comida_x_int and new_head_y = comida_y_int);
                            
                            if grow_snake then
                                comer <= '1';
                                -- Incrementar puntaje (100 puntos por comida)
                                if puntaje <= 9900 then
                                    puntaje <= puntaje + 100;
                                else
                                    puntaje <= 0;  -- Resetear al llegar a 9999
                                end if;
                                -- Hacer crecer la serpiente
                                if body_length < MAX_LENGTH then
                                    body_length <= body_length + 1;
                                end if;
                            end if;

                            -- Mover el cuerpo
                            for i in MAX_LENGTH-1 downto 1 loop
                                if i < body_length then
                                    snake_body(i) <= snake_body(i-1);
                                end if;
                            end loop;

                            -- Actualizar posición de la cabeza
                            snake_body(0).x <= new_head_x;
                            snake_body(0).y <= new_head_y;

                            -- Cambiar dirección si hay nueva entrada
                            if arriba_db = '1' and current_direction /= "11" then
                                current_direction <= "00";
                                state <= MOVE_UP;
                            elsif izquierda_db = '1' and current_direction /= "10" then
                                current_direction <= "01";
                                state <= MOVE_LEFT;
                            elsif derecha_db = '1' and current_direction /= "01" then
                                current_direction <= "10";
                                state <= MOVE_RIGHT;
                            elsif abajo_db = '1' and current_direction /= "00" then
                                current_direction <= "11";
                                state <= MOVE_DOWN;
                            end if;
                        end if;
                        
                    when others =>
                        state <= WAIT_START;
                end case;
            end if;
        end if;
    end process;

    -- Proceso para actualizar matriz LED
    process(clk)
    begin
        if rising_edge(clk) then
            -- Limpiar matriz primero
            led_matrix <= (others => (others => '0'));
            
            -- Dibujar serpiente
            for i in 0 to MAX_LENGTH-1 loop
                if i < body_length then
                    led_matrix(snake_body(i).y)(snake_body(i).x) <= '1';
                end if;
            end loop;
        end if;
    end process;

    -- Proceso para visualización en matriz LED
    process(clk)
    begin
        if rising_edge(clk) then
            refresh_counter <= refresh_counter + 1;
            
            if refresh_counter = 1023 then
                refresh_counter <= 0;
                
                -- Activar fila actual
                filas <= (others => '1');
                filas(fila_actual) <= '0';
                
                -- Mostrar serpiente y comida
                if fila_actual = comida_y_int then
                    columnas <= led_matrix(fila_actual) or comida_led_int;
                else
                    columnas <= led_matrix(fila_actual);
                end if;
                
                -- Avanzar a siguiente fila
                if fila_actual = 7 then
                    fila_actual <= 0;
                else
                    fila_actual <= fila_actual + 1;
                end if;
            end if;
        end if;
    end process;

    -- Control del display de 7 segmentos
    process(clk)
        variable thousands, hundreds, tens, ones : integer range 0 to 9;
    begin
        if rising_edge(clk) then
            -- Convertir puntaje a dígitos BCD
            thousands := puntaje / 1000;
            hundreds := (puntaje / 100) mod 10;
            tens := (puntaje / 10) mod 10;
            ones := puntaje mod 10;
            
            -- Multiplexación de dígitos (refresco a ~1kHz)
            if display_counter = 50000 then
                display_counter <= 0;
                
                -- Rotar entre los 4 dígitos
                case digit_select is
                    when 0 =>
                        bcd_digit <= thousands;
                        seg7_anodos <= "0111";  -- Activar primer dígito
                        digit_select <= 1;
                    when 1 =>
                        bcd_digit <= hundreds;
                        seg7_anodos <= "1011";  -- Activar segundo dígito
                        digit_select <= 2;
                    when 2 =>
                        bcd_digit <= tens;
                        seg7_anodos <= "1101";  -- Activar tercer dígito
                        digit_select <= 3;
                    when 3 =>
                        bcd_digit <= ones;
                        seg7_anodos <= "1110";  -- Activar cuarto dígito
                        digit_select <= 0;
                    when others =>
                        digit_select <= 0;
                end case;
                
                -- Decodificador BCD a 7 segmentos (ánodo común)
                case bcd_digit is
                    when 0 => seg7_catodos <= "1000000"; -- 0
                    when 1 => seg7_catodos <= "1111001"; -- 1
                    when 2 => seg7_catodos <= "0100100"; -- 2
                    when 3 => seg7_catodos <= "0110000"; -- 3
                    when 4 => seg7_catodos <= "0011001"; -- 4
                    when 5 => seg7_catodos <= "0010010"; -- 5
                    when 6 => seg7_catodos <= "0000010"; -- 6
                    when 7 => seg7_catodos <= "1111000"; -- 7
                    when 8 => seg7_catodos <= "0000000"; -- 8
                    when 9 => seg7_catodos <= "0010000"; -- 9
                    when others => seg7_catodos <= "1111111"; -- Apagado
                end case;
            else
                display_counter <= display_counter + 1;
            end if;
        end if;
    end process;
end Behavioral;