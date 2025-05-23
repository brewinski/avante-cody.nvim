local log = require("avante-cody.util.log")

local LOG_SCOPE = "overrides"

local overrides = {}

---@description Override the summarize_chat_thread_title function to reduce api ratelimit requests
---@param config avante_cody.Config
function overrides.summarize_chat_thread_fn(config)
    if not config.override.avante_llm_summarize_chat_thread then
        return
    end

    log.debug(LOG_SCOPE, "overriding summarize_memory")

    local llm = require("avante.llm")

    llm.summarize_chat_thread_title = function(_, cb)
        -- prevent API calls for chat titles
        cb("untitled")
    end
end

---@param config avante_cody.Config
function overrides.summarize_memory_fn(config)
    if not config.override.avante_llm_summarize_memory then
        return
    end

    log.debug(LOG_SCOPE, "overriding summarize_memory")

    local llm = require("avante.llm")

    llm.summarize_memory = function(_, _, cb)
        cb(nil)
    end
end

return overrides
