local log = require("avante-cody.util.log")
local state = require("avante-cody.state")
local provider_facotry = require("avante-cody.cody-provider")

-- internal methods
local main = {}

--- Disables the plugin for the given tab, clear highlight groups and autocmds, closes side buffers and resets the internal state.
---
--- @param provider_name string: internal identifier for logging purposes.
--- @param provider_opts avante_cody.AvanteProviderOpts: provider configuration options.
---@private
function main.register_provider(provider_name, provider_opts)
    local cody_provider = provider_facotry:new(provider_opts)

    local config = require("avante.config")
    config._defaults.vendors[provider_name] = cody_provider
end

return main
