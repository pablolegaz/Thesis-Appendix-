# Variable dictionary

| Group | Variables | Meaning |
|---|---|---|
| Power faults | `PSF`, `Batt` | Power-supply short and battery state. |
| Switch faults | `SW1`--`SW8` | Control-module switch state: `ok` or `det` (detached). |
| Cable faults | `C1`--`C8`, `CL` | Inter-module cables and cable-to-load: `ok` or `bro` (broken). |
| Lamp fault | `LF` | Load lamp fault: `ok` or `bro`. |
| Voltage states | `V0`--`V8` | Internal voltage propagation states: `v12` or `v0`. |
| Visual observations | `OPSU`, `I1`--`I8`, `OLa`, `OLi` | Power LED, switch LEDs, lamp, and lamp indicator observations. |
| Measurement observations | `MB`, `M1`--`M8`, `MPS` | Multimeter-style measurement evidence. |
| Output metrics | `belief`, `plausibility`, `width`, `empty_set_mass`, ranks | Diagnostic result quantities exported by the MATLAB scripts. |
