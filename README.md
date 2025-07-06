# 🐍 Snake Game in VHDL

This is a VHDL implementation of the classic Snake game on an FPGA board using a Cyclone IV. The snake is displayed on an 8x8 LED matrix, and the score is shown on a 4-digit 7-segment display.

---

## 🧠 Features

- Implemented using **Finite State Machines (FSM)**
- Score increases by **10 points per food**
- No wall collision or death detection
- Displayed on an **8x8 LED matrix**
- Score shown on **4-digit 7-segment display**
- Designed for **Cyclone IV FPGA**

---

## 🔧 Requirements

- **FPGA:** Cyclone IV
- **Software:** Quartus II (Intel FPGA IDE)
- **Hardware:**
  - 8x8 LED Matrix
  - 4-digit 7-segment display
  - Push buttons or switches for direction input and play 

---

## 📁 File Overview

| File                    | Description                                  |
|-------------------------|----------------------------------------------|
| `snake_basic.vhd`       | Main logic for the snake movement and control |
| `comida.vhd`            | Handles food generation and 8x8 LED matrix display |
| `puntaje_controller.vhd`| Displays the score on a 4-digit 7-segment display |

---

## ▶️ How to Run

1. Open the project in **Quartus II**
2. Compile all `.vhd` files
3. Program the FPGA (Cyclone IV)
4. Watch the snake game on the 8x8 matrix
5. Score will increase by 10 with each food item

> **Note:** The game has no collision detection. The snake cannot die and continues moving.

---

## 📄 License

This project is open-source and licensed under the MIT License.

---

## 🧑‍💻 Author

Kenya Marisol Vázquez Salto  
Student at ESCOM-IPN  
💻 Learning VHDL and digital design
