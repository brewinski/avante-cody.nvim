local main = require("avante-cody.main")
local config = require("avante-cody.config")
local log = require("avante-cody.util.log")
local event_debugger = require("avante-cody.event-debugger")

local AvanteCody = {
    event_debuggers = {},
}

-- setup AvanteCody options and merge them with user provided ones.
function AvanteCody.setup(opts)
    _G.AvanteCody.config = config.setup(opts)

    if not opts then
        return
    end

    main.configure_ratelimit_protections(_G.AvanteCody.config)

    local providers = opts.providers or {}
    for provider_name, provider_opts in pairs(providers) do
        local event_dbg = event_debugger:new(provider_name)
        _G.AvanteCody.event_debuggers[provider_name] = event_dbg

        main.register_provider(provider_name, provider_opts, event_dbg)
    end
end

-- toggle AvanteCody debug mode
function AvanteCody.toggle_debug()
    -- toggle debug mode. setup must have already been called for this command to work.
    assert(
        _G.AvanteCody.config,
        "AvanteCody.config is not initialized. Please call AvanteCody.setup() first."
    )

    _G.AvanteCody.config.debug = not _G.AvanteCody.config.debug
    log.print("AvanteCody.toggle_debug", "debug is now %s", _G.AvanteCody.config.debug)
end

-- toggle AvanteCody logfile mode
function AvanteCody.toggle_logfile()
    -- toggle debug mode. setup must have already been called for this command to work.
    assert(
        _G.AvanteCody.config,
        "AvanteCody.config is not initialized. Please call AvanteCody.setup() first."
    )

    _G.AvanteCody.config.logfile = not _G.AvanteCody.config.logfile
    log.print(
        "AvanteCody.toggle_logfile",
        "logfile is now %s",
        vim.inspect(_G.AvanteCody.config.logfile)
    )
end

function AvanteCody.print_last_parse_curl_args(provider_name, data_type)
    -- Default to "sg-claude-4" for backward compatibility
    provider_name = provider_name or "sg-claude-4"
    -- Default to "output" for backward compatibility
    data_type = data_type or "outputs"

    log.print(
        "avantecody.print_parse_response",
        "provider_name: %s",
        provider_name,
        "data_type: %s",
        data_type
    )

    local event_dbg = _G.AvanteCody.event_debuggers[provider_name]
    if not event_dbg then
        log.error(
            "AvanteCody.print_last_parse_curl_args",
            "Provider '%s' not found. Available providers: %s",
            provider_name,
            vim.tbl_keys(_G.AvanteCody.event_debuggers)
        )
        return
    end

    event_dbg:print_on_curl_args(data_type)
end

function AvanteCody.print_parse_response(provider_name)
    -- Default to "sg-claude-4" for backward compatibility
    provider_name = provider_name or "sg-claude-4"

    log.print("avantecody.print_parse_response", "provider_name: %s", provider_name)

    local event_dbg = _G.AvanteCody.event_debuggers[provider_name]
    if not event_dbg then
        log.error(
            "AvanteCody.print_parse_response",
            "Provider '%s' not found. Available providers: %s",
            provider_name,
            vim.tbl_keys(_G.AvanteCody.event_debuggers)
        )
        return
    end

    event_dbg:print_on_parse_response()
end

function AvanteCody.list_providers()
    local providers = vim.tbl_keys(_G.AvanteCody.event_debuggers)
    if #providers == 0 then
        log.print(
            "AvanteCody.list_providers",
            "No providers found. Make sure to call AvanteCody.setup() first."
        )
        return
    end

    log.print("AvanteCody.list_providers", "Available providers: %s", table.concat(providers, ", "))
end

_G.AvanteCody = AvanteCody

return _G.AvanteCody
