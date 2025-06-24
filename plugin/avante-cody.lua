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
        local args = vim.split(opts.args or "", "%s+")
        local provider_name = args[1]
        local data_type = args[2]
        require("avante-cody").print_last_parse_curl_args(provider_name, data_type)
    end, {
        nargs = "*", -- Optional argument
        complete = function(arg_lead, _cmd_line, _cursor_pos)
            local args = vim.split(_cmd_line or "", "%s+")
            local arg_count = #args - 1 -- Subtract 1 for the command itself

            if arg_count == 1 or (arg_count == 2 and arg_lead ~= "") then
                -- First argument: provider completion
                local providers =
                    vim.tbl_keys(_G.AvanteCody and _G.AvanteCody.event_debuggers or {})
                return vim.tbl_filter(function(provider)
                    return provider:find(arg_lead, 1, true) == 1
                end, providers)
            elseif arg_count == 2 or (arg_count == 3 and arg_lead ~= "") then
                -- Second argument: input/output completion
                local options = { "input", "output" }
                return vim.tbl_filter(function(option)
                    return option:find(arg_lead, 1, true) == 1
                end, options)
            end

            return {}
        end,
        desc = "Print last parse curl args for provider (default: sg-claude-4)",
    })

    vim.api.nvim_create_user_command("AvanteCodyPrintParseResponse", function(opts)
        local args = vim.split(opts.args or "", "%s+")
        local provider_name = args[1]
        require("avante-cody").print_parse_response(provider_name)
    end, {
        nargs = "*", -- Multiple optional arguments
        complete = function(arg_lead, _cmd_line, _cursor_pos)
            local args = vim.split(_cmd_line or "", "%s+")
            local arg_count = #args - 1 -- Subtract 1 for the command itself

            if arg_count == 1 or (arg_count == 2 and arg_lead ~= "") then
                -- First argument: provider completion
                local providers =
                    vim.tbl_keys(_G.AvanteCody and _G.AvanteCody.event_debuggers or {})
                return vim.tbl_filter(function(provider)
                    return provider:find(arg_lead, 1, true) == 1
                end, providers)
            elseif arg_count == 2 or (arg_count == 3 and arg_lead ~= "") then
                -- Second argument: input/output completion
                local options = { "input", "output" }
                return vim.tbl_filter(function(option)
                    return option:find(arg_lead, 1, true) == 1
                end, options)
            end

            return {}
        end,
        desc = "Print parse response for provider (default: sg-claude-4). Second arg: 'input' or 'output' (default: output)",
    })

    vim.api.nvim_create_user_command("AvanteCodyListProviders", function()
        require("avante-cody").list_providers()
    end, {
        desc = "List all available provider names",
    })
end
