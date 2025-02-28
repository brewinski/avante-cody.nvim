local main = require("avante-cody.main")
local config = require("avante-cody.config")

local AvanteCody = {}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function AvanteCody.toggle()
    if _G.AvanteCody.config == nil then
        _G.AvanteCody.config = config.options
    end

    main.toggle("public_api_toggle")
end

--- Initializes the plugin, sets event listeners and internal state.
function AvanteCody.enable(scope)
    if _G.AvanteCody.config == nil then
        _G.AvanteCody.config = config.options
    end

    main.toggle(scope or "public_api_enable")
end

--- Disables the plugin, clear highlight groups and autocmds, closes side buffers and resets the internal state.
function AvanteCody.disable()
    main.toggle("public_api_disable")
end

-- setup AvanteCody options and merge them with user provided ones.
function AvanteCody.setup(opts)
    _G.AvanteCody.config = config.setup(opts)
end

_G.AvanteCody = AvanteCody

return _G.AvanteCody
