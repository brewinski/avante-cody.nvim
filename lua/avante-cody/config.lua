local log = require("avante-cody.util.log")
local overrides = require("avante-cody.overides")

local AvanteCody = {}

--- @class avante_cody.ConfigOverrides
--- @field avante_llm_summarize_chat_thread boolean
--- @field avante_llm_summarize_chat_thread_fn function
--- @field avante_llm_summarize_memory boolean
--- @field avante_llm_summarize_memory_fn function

---@alias avante_cody.SourcographSubscriptionType "free" | "pro" | "enterprise-starter" | "enterprise"
--- AvanteCody configuration with its default values.
---
---@class avante_cody.Config
---@field debug boolean Debug mode
---@field override avante_cody.ConfigOverrides
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
AvanteCody.options = {
    -- Prints useful logs about what event are triggered, and reasons actions are executed.
    debug = false,
    providers = {},
    override = {
        avante_llm_summarize_chat_thread = true,
        avante_llm_summarize_chat_thread_fn = overrides.summarize_chat_thread_fn,
        avante_llm_summarize_memory = true,
        avante_llm_summarize_memory_fn = overrides.summarize_memory_fn,
    },
    logfile = "",
}

---@private
local defaults = vim.deepcopy(AvanteCody.options)

--- Defaults AvanteCody options by merging user provided options with the default plugin values.
---
---@param options table Module config table. See |AvanteCody.options|.
---
---@private
function AvanteCody.defaults(options)
    AvanteCody.options = vim.deepcopy(vim.tbl_deep_extend("keep", options or {}, defaults or {}))

    -- let your user know that they provided a wrong value, this is reported when your plugin is executed.
    assert(
        type(AvanteCody.options.debug) == "boolean",
        "`debug` must be a boolean (`true` or `false`)."
    )

    return AvanteCody.options
end

--- Define your avante-cody setup.
---
---@param options avante_cody.Config Module config table. See |AvanteCody.options|.
---
---@usage `require("avante-cody").setup()` (add `{}` with your |AvanteCody.options| table)
function AvanteCody.setup(options)
    AvanteCody.options = AvanteCody.defaults(options or {})

    log.warn_deprecation(AvanteCody.options)

    return AvanteCody.options
end

return AvanteCody
