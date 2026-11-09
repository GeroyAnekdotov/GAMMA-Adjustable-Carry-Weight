-- Runs the addon and selected GAMMA scripts with Lua doubles for X-Ray, MCM UI,
-- and persistent configuration. The assertions exercise the public callback paths.
local path = "gacw/additional_carry_weight"
local difficulty_weight = 40
local in_level = true
local mod_enabled = true
local config_values = {}
local disk_values = {}

-- Returns a shallow copy of the flat configuration store for a save or reload.
local function copy(values)
    local result = {}
    for key, value in pairs(values) do result[key] = value end
    return result
end

-- Fails with the scenario name and both values when an expectation differs.
local function equal(actual, expected, context)
    assert(actual == expected, string.format("%s: expected %s, got %s", context, expected, tostring(actual)))
end

-- Silences routine GAMMA and MCM log output in the harness.
function printf() end
-- Turns a formatted script error into a test failure.
function printe(...) error(string.format(...)) end
-- Supplies an empty object for an INI file outside the tested setting path.
function ini_file() return {} end
-- Returns an INI double backed by the active and persisted configuration tables.
function ini_file_ex()
    return {
        -- Reports the section as present to skip first-run engine setup.
        section_exist = function() return true end,
        -- Reads a stored section/key pair or returns the supplied default.
        r_value = function(_, section, key, _, default)
            local value = config_values[section .. ":" .. key]
            if value ~= nil then return value end
            return default
        end,
        -- Writes the value to the current session's configuration.
        w_value = function(_, section, key, value) config_values[section .. ":" .. key] = value end,
        -- Snapshots the session values for the next simulated process start.
        save = function() disk_values = copy(config_values) end
    }
end

-- Iterates a snapshot of keys in the order given by the engine-style comparator.
function spairs(values, comparator)
    local keys = {}
    for key in pairs(values) do keys[#keys + 1] = key end
    table.sort(keys,
        -- Adapts the table-aware comparator to Lua's two-key sort callback.
        function(left, right) return comparator(values, left, right) end)
    local index = 0
    -- Yields the next sorted key and its current value.
    return function()
        index = index + 1
        local key = keys[index]
        if key then return key, values[key] end
    end
end

-- Orders script callbacks by their registration index.
function sort_func_values_ascend(values, left, right) return values[left] < values[right] end

-- Forwards callback registration to the installed GAMMA dispatcher.
function RegisterScriptCallback(...) axr_main.callback_set(...) end
-- Removes a registered listener through the installed dispatcher.
function UnregisterScriptCallback(...) axr_main.callback_unset(...) end
-- Creates a named callback channel through the installed dispatcher.
function AddScriptCallback(...) axr_main.callback_add(...) end
-- Sends an event and its arguments through the installed dispatcher.
function SendScriptCallback(...) axr_main.make_callback(...) end
-- Clears a table in place so other references see the cleared cache.
function empty_table(values)
    for key in pairs(values) do values[key] = nil end
end

-- Stands in for GUI updates and dialog closing outside the assertions.
local function no_op() end
-- Returns translation keys unchanged for deterministic MCM sorting.
local function identity(value) return value end
-- Supplies a dummy packed color for widget setup.
function GetARGB() return 0 end
-- Returns a fixed engine uptime in milliseconds for MCM's session handling.
function time_continual() return 1000 end
-- Supplies a placeholder flag mask because the virtual file list ignores flags.
function bit_or() return 0 end
-- Keeps the test value within the given inclusive bounds.
function clamp(value, min, max) return math.max(min, math.min(max, value)) end
-- Rounds a test value to the requested number of decimal places.
function round_idp(value, places)
    local factor = 10 ^ places
    return math.floor(value * factor + 0.5) / factor
end
-- Splits MCM paths into their non-empty components.
function str_explode(value, separator)
    local parts = {}
    for part in value:gmatch("[^" .. separator .. "]+") do parts[#parts + 1] = part end
    return parts
end

-- Captures the caller's script namespace for a stub engine class declaration.
function class(name)
    local env = getfenv(2)
    -- Installs a table for the named class so MCM can define its methods.
    return function() env[name] = {} end
end

game = { translate_string = identity }
-- Reports whether MCM should dispatch changes to a loaded level.
level = { present = function() return in_level end }
-- Selects MCM's standard-width layout in the harness.
utils_xml = { is_widescreen = function() return false end }
-- Supplies the fixed difficulty baseline to the shared weight registry.
game_difficulties = { get_game_factor = function() return difficulty_weight end }
FS = { FS_ListFiles = 1, FS_RootOnly = 2 }
-- Exposes the addon's MCM provider through a simulated virtual filesystem.
function getFS()
    return {
        -- Returns the simulated discovery listing for MCM's script scan.
        file_list_open_ex = function()
            return {
                -- Reports one matching file only when the addon is enabled.
                Size = function() return mod_enabled and 1 or 0 end,
                -- Returns the metadata for the listing's only entry.
                GetAt = function()
                    return {
                        -- Identifies the addon script that MCM will load.
                        NameShort = function() return "gacw_mcm.script" end,
                        -- Reports a non-empty file so MCM includes it.
                        Size = function() return 1 end
                    }
                end
            }
        end
    }
end

-- Compiles and executes the named script in an engine-style namespace.
local function load_script(name)
    local module = setmetatable({}, { __index = _G })
    _G[name] = module
    local chunk = assert(loadstring(sources[name], "@" .. name .. ".script"))
    setfenv(chunk, module)()
end

-- Simulates a fresh game process with saved configuration and the chosen callback order.
local function start(core_first, with_mod)
    config_values = copy(disk_values)
    mod_enabled = with_mod
    db = {}
    in_level = false
    load_script("axr_main")
    load_script("weight")
    load_script("gacw_mcm")
    load_script("ui_mcm")
    if with_mod then
        load_script("gacw_core")
        if core_first then gacw_core.on_game_start() end
    end
    weight.on_game_start()
    if with_mod and not core_first then gacw_core.on_game_start() end
end

-- Creates a new actor at the difficulty defaults and dispatches its startup events.
local function load_actor()
    in_level = true
    db.actor = {
        carry = difficulty_weight,
        walk = difficulty_weight + 2 * math.ceil(difficulty_weight * 0.2),
        writes = 0,
        -- Stores the raw inventory limit and records the engine setter call.
        set_actor_max_weight = function(self, value)
            self.carry = value
            self.writes = self.writes + 1
        end,
        -- Stores the raw threshold used by the movement condition.
        set_actor_max_walk_weight = function(self, value) self.walk = value end
    }
    SendScriptCallback("actor_on_first_update")
    SendScriptCallback("actor_on_update")
end

-- Checks the two raw actor limits after the named scenario.
local function expect_limits(carry, walk, context)
    equal(db.actor.carry, carry, context .. " carry limit")
    equal(db.actor.walk, walk, context .. " walk limit")
end

-- Queues a slider value, runs the installed MCM Apply path and checks persistence.
local function apply(value)
    local gui = setmetatable({ _Cap = {}, UpdatePending = no_op, On_Cancel = no_op },
        { __index = ui_mcm.UI_MCM })
    local setting = gui:GetOption(path)
    local previous = db.actor and db.actor.carry
    gui:CacheValue("gacw", setting.id, value, setting)
    if db.actor then equal(db.actor.carry, previous, "pending value") end
    gui:On_Accept()
    equal(disk_values["mcm:" .. path], value, "saved MCM value")
end

start(true, true)
load_actor()
expect_limits(40, 56, "default")
equal(db.actor.writes, 0, "default actor writes")
equal(ui_mcm.get(path), 0, "registered MCM default")
local setting = ui_mcm.UI_MCM:GetOption(path)
equal(setting.type, "track", "MCM option type")
equal(setting.min, 0, "MCM minimum")
equal(setting.max, 1000, "MCM maximum")
equal(setting.step, 10, "MCM step")

for _, value in ipairs({50, 1000, 100, 250, 0}) do
    apply(value)
    local carry = 40 + value
    expect_limits(carry, carry + 2 * math.ceil(carry * 0.2), "Apply " .. value)
end

apply(100)
local writes = db.actor.writes
SendScriptCallback("actor_on_update")
equal(db.actor.writes, writes, "one-shot callback unregistered")
for _ = 1, 5 do
    load_actor()
    expect_limits(140, 196, "actor re-created")
end

weight.add_weight("haruka_strength_modifier_base", 8, true)
weight.multiply_weight("haruka_strength_modifier_mul", 1.25, true)
weight.add_weight("af_lucifer_weight", 15, true)
expect_limits(173, 243, "Strength and artefact perk")
local outfit, backpack, artefact, temporary = 12, 8, 4, 3
local gear_and_effects = outfit + backpack + artefact + temporary
equal(db.actor.carry + gear_and_effects, 200, "modelled displayed limit with equipment and effects")
assert(270 <= db.actor.walk + gear_and_effects and 271 > db.actor.walk + gear_and_effects)
weight.remove_weight("af_lucifer_weight")
expect_limits(158, 222, "artefact perk removed")
apply(0)
expect_limits(58, 82, "reset preserves Strength")

apply(250)
start(false, true)
load_actor()
expect_limits(290, 406, "fresh Lua state and alternate callback order")
start(false, false)
load_actor()
expect_limits(40, 56, "mod disabled with saved setting")
start(true, true)
load_actor()
expect_limits(290, 406, "mod re-enabled with saved setting")

db.actor = nil
in_level = false
apply(100)
load_actor()
expect_limits(140, 196, "Apply at the main menu then load")

local original_mcm = ui_mcm
for _, case in ipairs({{"broken", 0}, {false, 0}, {0/0, 0}, {math.huge, 0},
    {-50, 0}, {5000, 1000}, {"30", 30}, {251.4, 251}}) do
    config_values["mcm:" .. path] = case[1]
    equal(gacw_mcm.get_bonus(), case[2], "malformed or out-of-range option")
end
-- Simulates a configuration read that throws inside MCM.
ui_mcm = { get = function() error("configuration read failed") end }
equal(gacw_mcm.get_bonus(), 0, "read error fallback")
ui_mcm = nil
SendScriptCallback("on_option_change")
expect_limits(40, 56, "missing MCM removes only our existing bonus")
ui_mcm = original_mcm
local original_weight = weight
weight = nil
-- Call the mod's one-shot path without a registry. The installed registry's own
-- option callback still exists in this fixture and is unrelated to this guard.
load_actor()
expect_limits(40, 56, "missing weight API")
weight = original_weight

print(jit.version .. " integration passed with installed MCM, callback dispatcher and weight registry.")
