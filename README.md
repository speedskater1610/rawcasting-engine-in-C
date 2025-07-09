# Raycaster Console Game (C, Windows)

This is a simple first-person raycasting engine written in C, running entirely in the Windows console. Inspired by early 3D games like Wolfenstein 3D, it simulates a 3D environment using 2D map data and ASCII shading in a console buffer.

---

## Features

- Raycasting rendering engine (ASCII-based)
- Customizable controls
- Centered crosshair
- In-game menu for:
  - Changing key bindings
  - Adjusting difficulty level
- Simple 2D map with walls and open spaces
- Placeholder shooting mechanic
- Basic enemy data structure (for future expansion)

---

## Default Controls

| Action        | Key       |
|---------------|-----------|
| Move Forward  | `W`       |
| Move Backward | `S`       |
| Turn Left     | `A`       |
| Turn Right    | `D`       |
| Fire Weapon   | `Spacebar` (not implemented yet) |
| Open Menu     | `M`       |

These can be changed in-game using the menu.

---

## Requirements

- Windows operating system
- C compiler (e.g., GCC via MinGW)
- Console with Unicode support

---

## Building

Compile with GCC using:

```bash
gcc -o raycaster.exe raycaster.c -lm
