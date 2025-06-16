-- You can use this loaded variable to enable conditional parts of your plugin.
if _G.AvanteCodyLoaded then
    return
end

_G.AvanteCodyLoaded = true

-- Useful if you want your plugin to be compatible with older (<0.7) neovim versions
if vim.fn.has("nvim-0.7") == 0 then
    vim.cmd("command! AvanteCody lua require('avante-cody').toggle()")
else
    vim.api.nvim_create_user_command("AvanteCodyDebugToggle", function()
        require("avante-cody").toggle_debug()
    end, {})

    vim.api.nvim_create_user_command("AvanteCodyLogfileToggle", function()
        require("avante-cody").toggle_logfile()
    end, {})

    vim.api.nvim_create_user_command("AvanteCodyPrintLastParseCurlArgs", function(opts)
        require("avante-cody").print_last_parse_curl_args(opts.args)
    end, {
        nargs = "?", -- Optional argument
        complete = function(arg_lead, _cmd_line, _cursor_pos)
            local providers = vim.tbl_keys(_G.AvanteCody and _G.AvanteCody.event_debuggers or {})
            return vim.tbl_filter(function(provider)
                return provider:find(arg_lead, 1, true) == 1
            end, providers)
        end,
        desc = "Print last parse curl args for provider (default: sg-claude-4)",
    })

    vim.api.nvim_create_user_command("AvanteCodyPrintParseResponse", function(opts)
        require("avante-cody").print_parse_response(opts.args)
    end, {
        nargs = "?", -- Optional argument
        complete = function(arg_lead, _cmd_line, _cursor_pos)
            local providers = vim.tbl_keys(_G.AvanteCody and _G.AvanteCody.event_debuggers or {})
            return vim.tbl_filter(function(provider)
                return provider:find(arg_lead, 1, true) == 1
            end, providers)
        end,
        desc = "Print parse response for provider (default: sg-claude-4)",
    })

    vim.api.nvim_create_user_command("AvanteCodyListProviders", function()
        require("avante-cody").list_providers()
    end, {
        desc = "List all available provider names",
    })
end
