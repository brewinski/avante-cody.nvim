local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality
local starts_with = MiniTest.expect.starts_with
local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local test_api_key = "sgp_test-token"

--- @param provider_opts avante_cody.AvanteProviderOpts
local setup_plugin_script = function(provider_opts)
    return string.format(
        [[
        require('avante-cody').setup({
            providers = {
              ['avante-cody'] = %s
            },
        })
    ]],
        vim.inspect(provider_opts, { newline = "" })
    )
end

--- @param input table
--- @param api_key string
local parse_curl_args_script = function(api_key, input)
    return string.format(
        [[
        local avante_config = require('avante.config')
        local provider = avante_config._defaults.vendors["avante-cody"]

        provider.parse_api_key = function() return "%s" end

        return provider.parse_curl_args(
            provider,
            %s
        )
    ]],
        api_key,
        vim.inspect(input, { newline = "" })
    )
end

local T = new_set({
    hooks = {
        -- This will be executed before every (even nested) case
        pre_case = function()
            -- Restart child process with custom 'init.lua' script
            child.restart({ "-u", "scripts/minimal_init.lua" })
        end,
        -- This will be executed one after all tests from this set are finished
        post_once = child.stop,
    },
})

T["cody-provider"] = new_set()

T["cody-provider"]["provider configuration is added to the curl request and the correct headers are set."] = function()
    --- @type avante_cody.AvanteProviderOpts
    local config = {
        endpoint = "https://myinstance.sourcegraph.com",
        max_tokens = 10000,
        max_output_tokens = 3000,
        stream = false,
        topK = -2,
        topP = -2,
        model = "anthropic::2024-10-22::claude-3-7-sonnet-latest-random",
        timeout = 5000,
        allow_insecure = true,
        temperature = 0.5,
    }

    local input = {
        system_prompt = "this is a system prompt",
        messages = {},
    }

    child.lua(setup_plugin_script(config))

    -- read avante config value
    ---@type avante_cody.CodyProviderCurlArgs
    local result = child.lua(parse_curl_args_script(test_api_key, input))

    -- assert the configuraion values are correct
    eq(type(result), "table")

    eq(
        result.url,
        "https://myinstance.sourcegraph.com/.api/completions/stream?api-version=7&client-name=vscode&client-version=1.34.3"
    )
    eq(result.body.maxTokensToSample, config.max_output_tokens)
    eq(result.body.model, config.model)
    eq(result.body.stream, config.stream)
    eq(result.body.topK, config.topK)
    eq(result.body.topP, config.topP)
    eq(result.body.temperature, config.temperature)
    eq(result.timeout, config.timeout)
    eq(result.insecure, config.allow_insecure)
    eq(result.timeout, config.timeout)

    -- assert the headers are correct, including the api key
    eq(result.headers.Authorization, "token " .. test_api_key)
end

-- T["cody-provider"]["will parse curl args correctly"] = function()
--     local test_input = {
--         messages = {
--             { role = "user", content = "this is a user message" },
--             { role = "assistant", content = "this is an assistant message" },
--             { role = "system", content = "this is a system message" },
--         },
--         tool_histories = {
--             {
--                 tool_result = {
--                     content = '[".","stylua.toml","README.md","Makefile","CHANGELOG.md","LICENSE","FUNDING.yml"]',
--                     is_error = false,
--                     tool_use_id = "toolu_01HrktowMGZPYa31ZWuvgUfn",
--                 },
--                 tool_use = {
--                     id = "toolu_01HrktowMGZPYa31ZWuvgUfn",
--                     input_json = '{"rel_path": ".", "max_depth": 1}',
--                     name = "ls",
--                 },
--             },
--         },
--         tools = {
--             {
--                 description = 'Fast file pattern matching using glob patterns like "**/*.js", in current project scope',
--                 func = nil,
--                 name = "glob",
--                 param = {
--                     fields = {
--                         {
--                             description = "Glob pattern",
--                             name = "pattern",
--                             type = "string",
--                         },
--                         {
--                             description = "Relative path to the project directory, as cwd",
--                             name = "rel_path",
--                             type = "string",
--                         },
--                     },
--                     type = "table",
--                 },
--                 returns = {
--                     {
--                         description = "List of matched files",
--                         name = "matches",
--                         type = "string",
--                     },
--                     {
--                         description = "Error message",
--                         name = "err",
--                         optional = true,
--                         type = "string",
--                     },
--                 },
--             },
--         },
--     }
--
--     local expect = {
--         body = {
--             maxTokensToSample = 4000,
--             messages = {
--                 {
--                     speaker = "human",
--                     text = "this is a user message",
--                 },
--                 {
--                     speaker = "assistant",
--                     text = "this is an assistant message",
--                 },
--                 {
--                     speaker = "system",
--                     text = "this is a system message",
--                 },
--             },
--             model = "anthropic::2024-10-22::claude-3-7-sonnet-latest",
--             stream = true,
--             topK = -1,
--             topP = -1,
--         },
--         headers = {
--             Authorization = "token sgp_test-token",
--             ["Content-Type"] = "application/json",
--         },
--         insecure = false,
--         timeout = 30000,
--         url = "https://sourcegraph.com/.api/completions/stream?api-version=7&client-name=vscode&client-version=1.34.3",
--     }
--
--     local script = string.format(
--         [[
--         local avante_config = require('avante.config')
--         local provider = avante_config._defaults.vendors["avante-cody"]
--
--         provider.parse_api_key = function() return "sgp_test-token" end
--
--         return provider.parse_curl_args(
--             provider,
--             %s
--         )
--     ]],
--         vim.inspect(test_input, { newline = "" })
--     )
--
--     child.lua([[require('avante-cody').setup({
--         providers = {
--           ['avante-cody'] = {
--             endpoint = 'https://sourcegraph.com',
--           },
--         },
--     })]])
--
--     -- read avante config value
--     local output = child.lua(script)
--
--     -- assert the value, and the type
--     eq(output, expect)
-- end

return T
