# Thank-You Robot v4 "Cute": print files

About 172 mm tall, 100 mm wide base. **137 g of PLA, about 16.5 h of printing** (PrusaSlicer: 0.2 mm layers, 3 walls, 15 % gyroid infill). The sign is 3 mm laser-cut plywood.

![render](renders/realistic_coral.png)

## Print list (`stl/`, already in print orientation)

| File | Qty | Colour | Grams |
|---|---|---|---|
| `base_shell` | 1 | main white | 29.6 |
| `base_floor` | 1 | **translucent / clear** (the glow comes through it) | 13.7 |
| `body` | 1 | accent colour | 22.8 |
| `head_front` | 1 | main white | 25.8 |
| `head_back` | 1 | main white | 19.8 |
| `face_plate` | 1 | black | 5.9 |
| `cheek` | **2** | pink | 0.1 each |
| `ear_ring` | **2** | translucent | 2.6 each |
| `ear_cap` | **2** | accent colour | 0.8 each |
| `antenna_stem` | 1 | accent colour | 0.9 |
| `antenna_ball` | 1 | translucent | 1.9 |
| `arm_right`, `arm_left` | 1 each | main white | 4.9 each |
| `sign` | 1 | *only if you print it instead of using wood* | 6.9 |

**Wooden sign:** cut `laser/sign_outline.svg` (or `.dxf`, 76 × 34 mm with two 2.2 mm holes) from 3 mm plywood. The hands hold it: each edge slides into a hand slot and is locked with an M2×16 screw and nut. The NFC sticker goes on the back. When the arm servos move, the sign lifts with them.

Print `fit_tests/` first (7 small pieces, 16 g in total). `stl_50pct/` is a half-size mockup for checking the look only: no electronics fit at that size.

## Electronics

| Part | Qty | Where |
|---|---|---|
| Arduino Nano V3 | 1 | Base: slides into the two grooved blocks on the floor |
| SG90 servo | 3 | Body: 1 for the head (top plate), 1 per arm (lying flat in the side pads) |
| WS2812B 16-LED ring | 1 | Base: glued on the floor, LEDs facing **down** through the translucent floor |
| 5 mm addressable RGB LED (PL9823 / WS2812D) | 3 | 1 behind each ear ring, 1 in the antenna ball |
| VL53L0X | 1 | Base: glued inside the front wall, looking out through the small window |
| 18650 cell + single holder | 1 | Base: on the two rails above the LED ring |
| USB-C 18650 charger + 5V boost board (IP5306 type, 2A) | 1 | Base: on the floor at the back, USB-C through the bottom slot |
| KCD11 mini rocker switch | 1 | Base: back wall, above the USB-C port |
| 0.96" SSD1306 OLED, I²C | 1 | Head: glass in the pocket behind the face plate |
| NTAG213 sticker | 1 | Back of the wooden sign |
| 1000 µF capacitor, 330 Ω resistor | 1 each | On the 5V rail / the LED data line |
| M3×10 screws | 8 | 4 floor → base, 4 base → body |
| M3×12 screws | 4 | Head back → head front |
| M2×16 screws + nuts | 2 | Hands → sign |

## Wiring

| Signal | Nano pin |
|---|---|
| Head servo | D9 |
| Left arm servo | D10 |
| Right arm servo | D11 |
| LED chain: 330 Ω → ring DIN, ring DOUT → left ear → right ear → antenna | D6 |
| OLED + VL53L0X (I²C) | A4 SDA, A5 SCL |
| 5V rail | charger 5V out → switch → servos, LEDs, OLED, sensor, Nano 5V |

Five wires go up to the head: 5V, GND, SDA, SCL and the LED data line.

## Notes

- The arms and sign are one rigid piece on two coaxial servos. Mount them with both servos at 90°, arms straight forward, sign just above the base. Always move the servos as a pair (left = 90 − x, right = 90 + x). The sign can lift up to 18° before it touches the head, and only 2° down before it touches the base. Don't turn the head while the sign is lifted.
- Limit the head to about ±40°.
- A 3000 mAh cell gives an estimated 10–12 hours. The robot runs and charges at the same time while plugged into USB-C.
- To reprogram the Nano, remove the 4 floor screws.

Model source: `robot_cute.scad` (OpenSCAD 2021+). `openscad -D 'part="body"' -o body.stl robot_cute.scad`
