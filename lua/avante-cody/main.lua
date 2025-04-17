local log = require("avante-cody.util.log")
local state = require("avante-cody.state")
local provider_facotry = require("avante-cody.cody-provider")

-- internal methods
local main = {}

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
--
---@param scope string: internal identifier for logging purposes.
---@private
function main.toggle(scope)
    if state.get_enabled(state) then
        log.debug(scope, "avante-cody is now disabled!")

        return main.disable(scope)
    end

    log.debug(scope, "avante-cody is now enabled!")

    main.enable(scope)
end

--- Initializes the plugin, sets event listeners and internal state.
---
--- @param scope string: internal identifier for logging purposes.
---@private
function main.enable(scope)
    if state.get_enabled(state) then
        log.debug(scope, "avante-cody is already enabled")

        return
    end

    state.set_enabled(state)

    -- saves the state globally to `_G.AvanteCody.state`
    state.save(state)
end

--- Disables the plugin for the given tab, clear highlight groups and autocmds, closes side buffers and resets the internal state.
---
--- @param scope string: internal identifier for logging purposes.
---@private
function main.disable(scope)
    if not state.get_enabled(state) then
        log.debug(scope, "avante-cody is already disabled")

        return
    end

    state.set_disabled(state)

    -- saves the state globally to `_G.AvanteCody.state`
    state.save(state)
end

--- Disables the plugin for the given tab, clear highlight groups and autocmds, closes side buffers and resets the internal state.
---
--- @param provider_name string: internal identifier for logging purposes.
--- @param provider_opts AvanteCodyProviderOpts: internal identifier for logging purposes.
---@private
function main.register_provider(provider_name, provider_opts)
    local cody_provider = provider_facotry:new(provider_opts)

    local config = require("avante.config")
    config._defaults.vendors[provider_name] = cody_provider
end

return main
