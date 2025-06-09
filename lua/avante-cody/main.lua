local provider_facotry = require("avante-cody.cody-provider")
local log = require("avante-cody.util.log")

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
    config._defaults.providers[provider_name] = cody_provider
end

--- @param config avante_cody.Config
function main.configure_ratelimit_protections(config)
    --- trigger the override function for summarize_memory and summarize_chat_thread
    --- reduce the number of api requests
    config.override.avante_llm_summarize_memory_fn(config)
    config.override.avante_llm_summarize_chat_thread_fn(config)
end

return main
