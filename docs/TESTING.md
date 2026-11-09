# Verification

## Automated checks completed

The LuaJIT suite ran both addon modules with the installed `weight.script`, `ui_mcm.script` and `axr_main.script`. X-Ray objects, GUI plumbing, the virtual filesystem and the persistent config backend were represented by test doubles. It exercised MCM discovery, slider metadata, the real MCM Apply code, write-before-notify ordering, 0/50/1000 kg, 100 → 250 → 0, five actor recreations, both callback registration orders, Strength and artefact-perk recalculation, session restart with restored config, a disabled/re-enabled session, Apply in the main menu, malformed settings, and unavailable MCM or registry API. Equipment and temporary effects were covered as a formula model. Both language XML files parsed with their expected encodings and matching IDs.

Install Lupa 2.6 into a Python test environment. Replace the placeholders with the active GAMMA source files from the profile under test. The suite reads these files from the user's installation.

```powershell
python -m pip install lupa==2.6
python tests/run.py `
  --weight-script '<active weight.script>' `
  --mcm-script '<active ui_mcm.script>' `
  --axr-main '<active axr_main.script>'
```

| Source used in the suite | SHA-256 |
| --- | --- |
| `weight.script` | `50dbf8092727a0a8e0e479413c4b91098dfd72231ba8c644b67aca1c0839a956` |
| `ui_mcm.script` | `28c99faa086d833f08bb09749b7bff02cd2e3a397e3ab1c6ffddb33d07a58fda` |
| `axr_main.script` | `f10a322d083a88c8a3c17e8289af98f512a77ac672b282bde3dd1548efe75753` |

The build additionally verifies the ZIP member list, CRCs and byte-for-byte agreement with `mod/gamedata` and `LICENSE`.

## In-game plan

GeroyAnekdotov confirmed in-game testing on GAMMA 0.9.5. The scenarios below are a reproduction checklist. Individual in-game results were not recorded here. Use a test MO2 profile and a separate save. Use the same actor, Strength level, outfit, backpack, artefacts and booster state for each baseline comparison. Keep God Mode off for the overload checks. Record the displayed maximum, the tested inventory mass, movement outcome and any errors from the X-Ray log.

| Scenario | Expected result |
| --- | --- |
| MO2 installation and MCM | MO2 accepts the archive root. Both languages show the section, a legible label and the 0–1000 kg slider in 10 kg steps. |
| Default 0 kg | The displayed maximum and the movement threshold match the same setup with the addon disabled. |
| +50 kg | Apply, return to the inventory and confirm the maximum rises by 50 kg. Walk with a load above the old stop threshold. |
| +1000 kg | The inventory shows a 1000 kg increase without truncation. Movement works above the old threshold. |
| +100 → +250 → 0 kg | Each Apply updates the current actor. The displayed maximum is baseline +100, then +250, then baseline. |
| Save and reload | Reload the same save five times at +100. The displayed maximum stays baseline +100. |
| Restart | Exit to desktop, relaunch via MO2 and load the save. MCM and the actor retain the selected bonus. |
| Change backpack and outfit | Each gear change produces its normal capacity delta at 0 and at +100. |
| Change Strength | Compare before and after a level-up with a fixed addon setting. The Strength recalculation preserves the addon bonus. |
| Artefacts and timed effects | Equip/remove a carry artefact and test a carry-weight consumable through expiry. Compare effect deltas at 0 and +100. |
| Hard movement limit | With gear and effects fixed, find the baseline threshold by changing carried mass. At +100 the cutoff is 140 kg higher. Check just below and above the new threshold. |
| Change location | Cross a level boundary at +100. Confirm the destination keeps one copy of the bonus. |
| Existing save | Load a save created before installing the addon. Confirm the stored MCM setting applies on load. |
| Disable and re-enable | Exit, disable the addon and reload at baseline. Exit, re-enable and confirm that the retained MCM setting applies once. |
| Apply at the main menu | Apply +50 before loading a save and verify the displayed maximum on arrival. |

The in-game UI, actual player movement, MO2 virtual overlay, save serialization and level-transition callbacks were not exercised by the LuaJIT suite.
