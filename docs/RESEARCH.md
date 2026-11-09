# Carry weight in GAMMA 0.9.5

## Sources and scope

The MO2 profile `G.A.M.M.A` and its enabled file providers were inspected for this analysis. The highest-priority enabled English `_game_version.xml` in Massive Text Overhaul identifies the pack as 0.9.5. The game log reported Modded Exes MT-TEST 2026.05.15. The weight method names were also found in the installed `AnomalyDX11AVX.exe`. The C++ behavior below comes from the matching upstream tag. The profile and physical files establish expected providers. This source inspection was separate from the author's in-game testing.

| Installed file | Provider and use |
| --- | --- |
| `scripts/weight.script` | GAMMA Arti Recipes Overhaul wins over Perk-Based Artefacts and Haruka Skill System. It holds the keyed adders and multipliers and writes both actor limits. |
| `scripts/haru_skills.script` and `configs/plugins/skills/skill_haruka.ltx` | GAMMA Skill System Balance supplies the Strength formula and load/update callbacks. |
| `scripts/perk_based_artefacts.script` | GAMMA Artefacts Reinvention uses the shared registry for perks such as Lucifer's weight bonus. Other artefacts use equipment stats from the GAMMA configs. |
| `scripts/ui_inventory.script` | GAMMA Accurate Defense Values wins over GAMMA UI and the sorting-tabs providers in the inspected profile. |
| `scripts/ui_mcm.script` and `configs/text/{eng,rus}/ui_st_mcm.xml` | RavenAscendant MCM. MO2 metadata names `MCM_1.7.2fix.7z` and the installed script declares `VERSION = "1.7.1"`. |
| `scripts/axr_main.script` | Loose game file that discovers modules and dispatches callbacks in registration order. |

GAMMA Outfits Balances patches equipment carry stats. Coffee in the Zone and the DLTX Minimodpack include `boost_max_weight` consumable entries. HUD Icons Time, Fair Fast Travel, Ledge Grabbing and Outfits Affects Movespeed read one of the actor limits for their own calculations. The Lua scan found the three listed `weight.script` providers writing the two actor limits among installed MO2 mods. The unpacked base Anomaly reference also writes them when setting up gameplay difficulty. The base `game_difficulties.script` and actor binder were consulted as reference because the matching loose installed files were absent.

## Base values and bonuses

The installed `weight.script` starts with the gameplay difficulty's carry factor. Its `add_weight(key, amount, force)` and `multiply_weight(key, multiplier, force)` maintain independent keys. `remove_weight(key)` removes a key and recalculates. A recompute sets both actor fields using the following formulas.

```text
carry_base = difficulty_weight * product(weight_multipliers) + sum(weight_adders)
walk_base  = carry_base + 2 * ceil(carry_base * 0.2)
```

Haruka loads saved skill levels and builds the corresponding stats on game load. The installed balance config gives Strength level `L` an adder of `8 + 0.0125 * L` kg and a multiplier of `0.5 + 0.035 * L`. The stats update runs on an actor update timer with a 1182 ms interval and updates the two Strength keys. The same code computes load divided by carry capacity for Strength and Endurance experience. A higher capacity therefore changes those experience gains for the same load.

The inventory Lua display starts at `get_actor_max_weight()`, adds the outfit and backpack getters for slots 7 and 13, sums the configured carry weight of belt artefacts scaled by condition, and adds active boosters of type 4. It displays the result rounded to one decimal. Native movement uses the actor's walk base plus the active native carry boost, equipped outfit and backpack modifiers, and the condition-scaled belt artefact modifiers. The single-player stop condition compares actual inventory mass with this effective movement limit. The display and native code read different outfit/backpack fields, which can differ for gear that supplies different values. [Native movement and equipment](https://github.com/themrdemonized/xray-monolith/blob/2026.5.15/src/xrGame/Actor_Movement.cpp), [Overload and boosters](https://github.com/themrdemonized/xray-monolith/blob/2026.5.15/src/xrGame/ActorCondition.cpp)

| Lua methods | Behavior in the reference engine |
| --- | --- |
| `get_actor_max_weight`, `set_actor_max_weight` | Read and assign the actor inventory's raw maximum. The getter omits gear and boosters. |
| `get_actor_max_walk_weight`, `set_actor_max_walk_weight` | Read and assign the actor condition's raw movement threshold. The engine adds gear and boosters later. |
| `get_additional_max_weight`, `set_additional_max_weight` | Read and assign `m_additional_weight2` on an outfit or backpack. |
| `get_additional_max_walk_weight`, `set_additional_max_walk_weight` | Read and assign `m_additional_weight` on an outfit or backpack. Native actor carry and movement calculations use this field. |

These are absolute setters. Actor fields are overwritten by the next shared weight recompute, while item setters change equipment stats. The native `BoostMaxWeight` method adjusts an aggregate that the inspected Lua inventory reads through the active booster table. A direct adjustment of that aggregate would miss the inventory display path. [Lua exports](https://github.com/themrdemonized/xray-monolith/blob/2026.5.15/src/xrGame/script_game_object_script3.cpp), [Getter and setter implementations](https://github.com/themrdemonized/xray-monolith/blob/2026.5.15/src/xrGame/script_game_object_inventory_owner.cpp), [Condition bindings](https://github.com/themrdemonized/xray-monolith/blob/2026.5.15/src/xrGame/ActorCondition_script.cpp)

## Integration and limits

The core uses one unique key in the existing registry and forces replacement when applying a positive value. At 0 it removes its own key if previously applied. The registry still owns both setters, so a later Strength or artefact-perk refresh includes the addon. Equipment swaps and temporary effects flow through the existing game code.

The module applies after `actor_on_first_update` through a one-shot `actor_on_update` callback, after the registry has initialized its difficulty base. `on_option_change` applies a saved change to the active actor. In the main menu, MCM saves the value and the next actor load reads it. The installed MCM gathers `*mcm.script` providers, accepts `sh = true` for a top-level options panel, and saves standard controls in the `[mcm]` section of `axr_options.ltx` before dispatching the change event. The standard `track` control displays the numeric value in a label. The addon uses that single setting without a separate numeric entry field. [MCM author documentation](https://github.com/RAX-Anomaly/Anomaly-Mod-Configuration-Menu/blob/main/README.md)

With unchanged equipment, Strength and effects, an MCM value `B` increases the displayed carry limit by `B` kg. The hard stop increases by `B + 2 * (ceil((carry_base + B) * 0.2) - ceil(carry_base * 0.2))`. At the slider's 10 kg increments this is `1.4 * B` for the installed formula. For instance, +100 kg on the slider moves the hard stop by +140 kg. This preserves the stock overload calculation and avoids intercepting the registry's private recompute function.

A direct setter from another mod can override the shared result until the next registry recompute. The same applies to a gameplay difficulty change that writes the two actor fields directly. Replacing `weight.script` with incompatible semantics or replacing the inventory script with one that ignores the actor field can change the effect. Addons that use distinct keys in the same registry should compose by construction. Compatibility with other mods and game modes still needs a live test if the profile differs from the inspected setup.
