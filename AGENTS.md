# GAMMA Adjustable Carry Weight

- Follow the global rules and the parent `../AGENTS.md` when available.
- Target S.T.A.L.K.E.R. Anomaly GAMMA 0.9.5 and its bundled MCM. Keep the mod isolated in `mod/gamedata`. Keep Lua code, comments and documentation in English. Maintain both MCM translations.
- Start every `.lua` and `.script` file with a short English header describing its responsibilities. Document every function immediately above its definition, including local functions and anonymous callbacks in tests. Explain purpose, parameters, return values and important side effects where applicable. Document weight composition, idempotence, GAMMA and MCM interactions, and compatibility decisions at the relevant functions. Update comments with the behavior they describe.
- Treat the installed game, MO2 mods, profiles, Overwrite and saves as read-only. Use installed sources for research and keep them out of the package.
- `VERSION` is this project's release version. Use Semantic Versioning, preserve previous packages in `dist/`, and assign a new version before distributing changed gameplay files.
- Run the LuaJIT suite against the active GAMMA scripts with Lupa 2.6. See `docs/TESTING.md` for the command and the in-game checks.
- Only build an installable release when requested. `python build.py` verifies the local ZIP in `dist/` and hands that same ZIP to the parent's `_tools/deliver_mo2.py` through `deliver_mo2_zip(path)`. Only the shared helper may write to its configured MO2 downloads directory. Keep the local ZIP if delivery fails or the helper is absent. Check-only runs never deliver.
- Keep source, test and reference files out of MO2 ZIPs. Do not commit, push or publish without an explicit request.
