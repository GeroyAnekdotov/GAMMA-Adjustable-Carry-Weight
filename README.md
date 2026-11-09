# GAMMA Adjustable Carry Weight

A small quality-of-life mod for S.T.A.L.K.E.R. GAMMA 0.9.5. Set how many extra kilograms you can carry from the Mod Configuration Menu (MCM).

## Installation

1. Download `GAMMA_Adjustable_Carry_Weight_v1.0.0_MO2.zip` from the [v1.0.0 release](https://github.com/GeroyAnekdotov/GAMMA-Adjustable-Carry-Weight/releases/tag/v1.0.0).
2. In Mod Organizer 2, select **Install a new mod from an archive**, choose the ZIP, and enable the mod in your GAMMA profile.
3. Launch GAMMA through MO2.

## Configuration

Open **Mod Configuration Menu → GAMMA 0.9.5 Adjustable Carry Weight**. Set **Additional Carry Weight (kg)** and select **Apply**. The slider goes from 0 to 1000 kg in 10 kg steps, with 0 kg as the default. MCM remembers the value across restarts and applies it when you load an existing save. The menu is available in English and Russian.

If your inventory limit is 43 kg, +100 kg brings it to about 143 kg with the same gear and effects. GAMMA still applies its own overload margin to the movement limit.

## Compatibility

Built for GAMMA 0.9.5 with its bundled MCM and shared weight registry. The bonus combines with Strength, equipment, artefacts and temporary effects through GAMMA's existing calculations. Carry-weight mods that directly overwrite the actor's limits can replace the result. With a higher capacity, the same carried load can also change Strength and Endurance experience because GAMMA uses the load-to-capacity ratio.

## Uninstallation

Exit the game, then disable or remove the mod in MO2. The bonus is stored by MCM and adds no data to your saves. Re-enabling the mod can restore the last setting if MCM kept it.

## Development story

> This mod was developed in approximately 5 minutes by an elite development team consisting of ChatGPT and Codex. Apparently, sometimes things just work.

That was the initial development time. Testing, documentation and release preparation came afterward.

## Credits

- **GeroyAnekdotov** — Project idea, direction, and in-game testing.
- **ChatGPT** — Research, technical planning, and development assistance.
- **Codex** — Code implementation, debugging, and documentation.

[Project credits](CREDITS.md)

## Source and testing

The project uses the [MIT License](LICENSE). See the [research notes](docs/RESEARCH.md) and [test plan](docs/TESTING.md) for implementation details. Run `python build.py` with Python 3.10 or later to build the installation ZIP in `dist/`.
