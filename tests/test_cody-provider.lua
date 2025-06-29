local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality
local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local tools = {
    {
        description = "List files and directories in a given path in current project scope",
        name = "ls",
        param = {
            fields = {
                {
                    description = "Relative path to the project directory",
                    name = "rel_path",
                    type = "string",
                },
                {
                    description = "Maximum depth of the directory",
                    name = "max_depth",
                    type = "integer",
                },
            },
            type = "table",
        },
        returns = {
            {
                description = "List of file paths and directorie paths in the given directory",
                name = "entries",
                type = "string[]",
            },
        },
    },
}

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
        local provider = avante_config._defaults.providers["avante-cody"]

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

T["cody-provider:parse_curl_args()"] = new_set()

T["cody-provider:parse_curl_args()"]["configuration is added to the curl request and the correct headers are set."] = function()
    --- @type avante_cody.AvanteProviderOpts
    local config = {
        endpoint = "https://myinstance.sourcegraph.com",
        max_tokens = 10000,
        max_output_tokens = 3000,
        stream = false,
        topK = -2,
        topP = -2,
        model = "anthropic::2024-10-22::claude-sonnet-4-latest-random",
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

    -- assert that the system message is correctly formatted with cache_control
    eq(result.body.messages[1], {
        speaker = "system",
        content = {
            {
                type = "text",
                text = "this is a system prompt",
                cache_control = { type = "ephemeral" },
            },
        },
    })
end

T["cody-provider:parse_curl_args()"]["tools are parsed from avantes format to sourcegraph format."] = function()
    --- @type avante_cody.AvanteProviderOpts
    local config = {}

    local input = {
        system_prompt = "this is a system prompt",
        messages = {
            { role = "user", content = "this is a user message" },
        },
        tools = tools,
    }

    child.lua(setup_plugin_script(config))

    -- read avante config value
    ---@type avante_cody.CodyProviderCurlArgs
    local result = child.lua(parse_curl_args_script(test_api_key, input))

    -- expect tools to be appended to the curl request body with cache_control on the last tool.
    eq(result.body.tools, {
        {
            ["function"] = {
                description = "List files and directories in a given path in current project scope",
                name = "ls",
                parameters = {
                    additionalProperties = false,
                    properties = {
                        max_depth = {
                            description = "Maximum depth of the directory",
                            type = "integer",
                        },
                        rel_path = {
                            description = "Relative path to the project directory",
                            type = "string",
                        },
                    },
                    required = { "rel_path", "max_depth" },
                    type = "object",
                },
            },
            type = "function",
            cache_control = { type = "ephemeral" },
        },
    })
end

T["cody-provider:parse_curl_args()"]["system prompt is appended as the leading message and tool result message is appended after the assistant tool call."] = function()
    --- @type avante_cody.AvanteProviderOpts
    local config = {}

    local input = {
        system_prompt = "this is a system prompt",
        messages = {
            { role = "user", content = "this is a user message" },
            {
                role = "assistant",
                content = {
                    {
                        type = "tool_use",
                        id = "toolu_016sbqPrbG5pim5mKgZu4vgx",
                        input = '{ rel_path = ".", max_depth = 1 }',
                        name = "ls",
                    },
                },
            },
            {
                role = "user",
                content = {
                    {
                        type = "tool_result",
                        tool_use_id = "toolu_016sbqPrbG5pim5mKgZu4vgx",
                        content = '[".","stylua.toml","readme.md","changelog.md","license","funding.yml","makefile"]',
                    },
                },
            },
            {
                role = "assistant",
                content = {
                    {
                        type = "tool_use",
                        id = "toolu_016twZUJ28kG35dLwdSfxDEi",
                        input = '{ rel_path = ".", max_depth = 1 }',
                        name = "ls",
                    },
                },
            },
            {
                role = "user",
                content = {
                    {
                        type = "tool_result",
                        tool_use_id = "toolu_016twZUJ28kG35dLwdSfxDEi",
                        content = '[".","stylua.toml","README.md","Makefile","CHANGELOG.md","LICENSE","FUNDING.yml"]',
                    },
                },
            },
        },
        tools = tools,
    }

    -- {
    --     tool_result = {
    --         content = '[".","stylua.toml","README.md","Makefile","CHANGELOG.md","LICENSE","FUNDING.yml"]',
    --         is_error = false,
    --         tool_use_id = "toolu_016twZUJ28kG35dLwdSfxDEi",
    --     },
    --     tool_use = {
    --         id = "toolu_016twZUJ28kG35dLwdSfxDEi",
    --         input_json = '{"rel_path": ".", "max_depth": 1}',
    --         name = "ls",
    --     },
    -- },
    child.lua(setup_plugin_script(config))

    -- read avante config value
    ---@type avante_cody.CodyProviderCurlArgs
    local result = child.lua(parse_curl_args_script(test_api_key, input))

    -- assert that the system message is correctly formatted
    local system_prompt = result.body.messages[1]
    eq(system_prompt, {
        speaker = "system",
        content = {
            {
                type = "text",
                text = "this is a system prompt",
                cache_control = { type = "ephemeral" },
            },
        },
    })

    -- existing messages should come after the system prompt
    local user_message = result.body.messages[2]
    eq(user_message, {
        speaker = "human",
        content = {
            {
                type = "text",
                text = "this is a user message",
            },
        },
    })

    -- tool use messages should be appended at the end and should be in the correct order.
    -- Assistant tool call message should always be followed by a user tool result message
    local tool_use_1 = result.body.messages[3]
    local tool_result_1 = result.body.messages[4]
    eq(tool_use_1, {
        speaker = "assistant",
        content = {
            { type = "text", text = "Ok. I'll run this now." },
            {
                type = "tool_call",
                tool_call = {
                    id = "toolu_016sbqPrbG5pim5mKgZu4vgx",
                    name = "ls",
                    arguments = vim.json.encode('{ rel_path = ".", max_depth = 1 }'),
                },
            },
        },
    })

    eq(tool_result_1, {
        speaker = "human",
        content = {
            {
                type = "tool_result",
                tool_result = {
                    id = "toolu_016sbqPrbG5pim5mKgZu4vgx",
                    content = '[".","stylua.toml","readme.md","changelog.md","license","funding.yml","makefile"]',
                },
            },
        },
    })

    -- tool use messages should be added in order. I expect to see the second tool call and result in positions 5 and 6
    local tool_use_2 = result.body.messages[5]
    local tool_result_2 = result.body.messages[6]
    eq(tool_use_2, {
        speaker = "assistant",
        content = {
            {
                type = "text",
                text = "Ok. I'll run this now.",
                cache_control = { type = "ephemeral" },
            },
            {
                type = "tool_call",
                tool_call = {
                    id = "toolu_016twZUJ28kG35dLwdSfxDEi",
                    name = "ls",
                    arguments = vim.json.encode('{ rel_path = ".", max_depth = 1 }'),
                },
            },
        },
    })

    eq(tool_result_2, {
        speaker = "human",
        content = {
            {
                type = "tool_result",
                tool_result = {
                    id = "toolu_016twZUJ28kG35dLwdSfxDEi",
                    content = '[".","stylua.toml","README.md","Makefile","CHANGELOG.md","LICENSE","FUNDING.yml"]',
                },
            },
        },
    })
end

-- T["cody-provider:parse_curl_args()"]["thinking messages are excluded from the final output"] = function()
--     --- @type avante_cody.AvanteProviderOpts
--     local config = {}
--
--     local input = {
--         system_prompt = "this is a system prompt",
--         messages = {
--             {
--                 msg = {
--                     content = "<task>if a tree falls in the forest, does it make a sound?</task>",
--                     role = "user",
--                 },
--             },
--             -- Thinking message
--             {
--                 role = "assistant",
--                 content = {
--                     {
--                         type = "thinking",
--                         thinking = "This is a classic philosophical question about perception and reality.",
--                         signature = "",
--                     },
--                 },
--             },
--             -- Normal assistant response
--             { role = "assistant", content = "I found 3 files in the directory." },
--         },
--     }
--
--     child.lua(setup_plugin_script(config))
--
--     -- read avante config value
--     ---@type avante_cody.CodyProviderCurlArgs
--     local result = child.lua(parse_curl_args_script(test_api_key, input))
--
--     -- check system prompt
--     local system_prompt = result.body.messages[1]
--     eq(system_prompt, { speaker = "system", text = "this is a system prompt" })
--
--     -- check user message
--     local user_message = result.body.messages[2]
--     eq(
--         user_message,
--         { speaker = "human", text = "if a tree falls in the forest, does it make a sound?" }
--     )
--
--     -- check normal assistant response
--     local msg1 = result.body.messages[3]
--     eq(msg1, { speaker = "assistant", text = "I found 3 files in the directory." })
--
--     -- ensure thinking message is excluded
--     eq(#result.body.messages, 2)
-- end

T["cody-provider:parse_curl_args()"]["correctly parses assistant tool calls and user tool results from message content"] = function()
    --- @type avante_cody.AvanteProviderOpts
    local config = {}

    local input = {
        system_prompt = "this is a system prompt",
        messages = {
            -- User normal message
            { role = "user", content = "Can you list the files in the current directory?" },
            -- Assistant tool call in content
            {
                role = "assistant",
                content = {
                    {
                        id = "tool_call_123456",
                        name = "ls",
                        input = {
                            rel_path = ".",
                            max_depth = 1,
                        },
                        type = "tool_use",
                    },
                },
            },
            -- User tool result in content
            {
                role = "user",
                content = {
                    {
                        tool_use_id = "tool_call_123456",
                        content = '["file1.txt", "file2.lua", "README.md"]',
                        type = "tool_result",
                    },
                },
            },
            -- Normal assistant response
            { role = "assistant", content = "I found 3 files in the directory." },
            -- Another tool call sequence
            {
                role = "assistant",
                content = {
                    {
                        id = "tool_call_abcdef",
                        name = "grep",
                        input = {
                            query = "function",
                            rel_path = "src",
                        },
                        type = "tool_use",
                    },
                },
            },
            -- Response to second tool call
            {
                role = "user",
                content = {
                    {
                        tool_use_id = "tool_call_abcdef",
                        content = "src/main.lua:10:function setup()\nsrc/utils.lua:5:function helper()",
                        type = "tool_result",
                    },
                },
            },
        },
        tools = tools,
    }

    child.lua(setup_plugin_script(config))

    -- read avante config value
    ---@type avante_cody.CodyProviderCurlArgs
    local result = child.lua(parse_curl_args_script(test_api_key, input))

    -- check system prompt
    local system_prompt = result.body.messages[1]
    eq(system_prompt, {
        speaker = "system",
        content = {
            {
                type = "text",
                text = "this is a system prompt",
                cache_control = { type = "ephemeral" },
            },
        },
    })

    -- check first user message
    local msg1 = result.body.messages[2]
    eq(msg1, {
        speaker = "human",
        content = {
            {
                type = "text",
                text = "Can you list the files in the current directory?",
            },
        },
    })

    -- check assistant tool call
    local tool_call_msg = result.body.messages[3]
    eq(tool_call_msg.speaker, "assistant")
    eq(type(tool_call_msg.content), "table")
    eq(tool_call_msg.content[1].type, "text")
    eq(tool_call_msg.content[2].type, "tool_call")
    eq(tool_call_msg.content[2].tool_call.id, "tool_call_123456")
    eq(tool_call_msg.content[2].tool_call.name, "ls")
    -- Check if arguments is valid JSON with correct content
    local args = vim.json.decode(tool_call_msg.content[2].tool_call.arguments)
    eq(args.rel_path, ".")
    eq(args.max_depth, 1)

    -- check user tool result
    local tool_result_msg = result.body.messages[4]
    eq(tool_result_msg.speaker, "human")
    eq(type(tool_result_msg.content), "table")
    eq(tool_result_msg.content[1].type, "tool_result")
    eq(tool_result_msg.content[1].tool_result.id, "tool_call_123456")
    eq(tool_result_msg.content[1].tool_result.content, '["file1.txt", "file2.lua", "README.md"]')

    -- check second tool call
    local tool_call_msg2 = result.body.messages[5]
    eq(type(tool_call_msg2.content), "table")
    eq(tool_call_msg2.content[1].type, "text")
    eq(tool_call_msg2.content[1].text, "I found 3 files in the directory.")
    eq(tool_call_msg2.content[2].type, "tool_call")

    eq(tool_call_msg2.speaker, "assistant")
    eq(tool_call_msg2.content[2].tool_call.id, "tool_call_abcdef")
    eq(tool_call_msg2.content[2].tool_call.name, "grep")
    local args2 = vim.json.decode(tool_call_msg2.content[2].tool_call.arguments)
    eq(args2.query, "function")
    eq(args2.rel_path, "src")

    -- check second tool result
    local tool_result_msg2 = result.body.messages[6]
    eq(tool_result_msg2.speaker, "human")
    eq(tool_result_msg2.content[1].tool_result.id, "tool_call_abcdef")
    eq(
        tool_result_msg2.content[1].tool_result.content,
        "src/main.lua:10:function setup()\nsrc/utils.lua:5:function helper()"
    )
end

local parse_response_script = function(ctx, data_stream, event_state)
    return string.format(
        [[
        local avante_config = require('avante.config')
        local provider = avante_config._defaults.providers["avante-cody"]

        local result = {}

        local opts = {
            on_stop = function(s_opts) 
                table.insert(result, { on_stop = s_opts })
            end,

            on_chunk = function(c_opts) 
                table.insert(result, { on_chunk = c_opts })
            end,

            on_messages_add = function(msg) 
                table.insert(result, { on_messages_add = msg })
            end
        }

        provider.parse_response(
            provider,
            %s,
            '%s',
            "%s",
            opts
        )

        return result
    ]],
        vim.inspect(ctx, { newline = "" }),
        data_stream,
        event_state
    )
end

T["cody-provider:parse_response()"] = new_set()

T["cody-provider:parse_response()"]["reports API error message in call to on_stop"] = function()
    local config = {}
    child.lua(setup_plugin_script(config))

    local result = child.lua(parse_response_script({}, '{ error = "API error" }', "error"))

    -- Verify that on_stop is called with the API error
    eq(result[1], {
        on_stop = {
            error = 'error: { error = "API error" }',
            reason = "error",
        },
    })
end

T["cody-provider:parse_response()"]["handles delta_thinking messages correctly"] = function()
    local config = {}
    child.lua(setup_plugin_script(config))

    local ctx = {}
    local data_stream =
        '{ "delta_thinking": "This is a philosophical question about perception and reality." }'
    local event_state = "completion"

    -- Call parse_response with delta_thinking data
    local result = child.lua(parse_response_script(ctx, data_stream, event_state))

    -- Verify that on_chunk is called with the delta_thinking content
    eq(result[1], { on_chunk = "This is a philosophical question about perception and reality." })

    -- Verify that on_messages_add is called with the delta_thinking content
    local message_add = result[2]
    local expected_message = {
        is_user_submission = false,
        message = {
            content = {
                {
                    signature = "",
                    thinking = "This is a philosophical question about perception and reality.",
                    type = "thinking",
                },
            },
            role = "assistant",
        },
        state = "generating",
        uuid = "cb9c1a5b-6910-4fb2-b457-a9c72a392d90",
        visible = true,
    }

    -- Exclude timestamp from comparison
    message_add.on_messages_add[1].timestamp = nil
    expected_message.timestamp = nil

    eq(message_add.on_messages_add[1], expected_message)

    -- Verify that the thinking message is added to the context
    -- eq(ctx.reasonging_content, "This is a philosophical question about perception and reality.")
end

T["test environment variable endpoint resolution"] = function()
    child.restart({ "-u", "tests/minimal_init.lua" })

    local cody_provider = require("avante-cody.cody-provider")

    -- Test direct endpoint resolution from environment variable
    local test_endpoint = "https://my-enterprise.sourcegraphcloud.com"

    -- Create a mock environment with test values
    local function mock_getenv(name)
        if name == "SRC_ENDPOINT" then
            return test_endpoint
        end
        return nil -- Return nil for unknown env vars in test
    end

    -- Temporarily replace os.getenv for this test
    local original_getenv = os.getenv
    -- Use rawset to avoid duplicate-set-field warning
    rawset(os, "getenv", mock_getenv)

    local provider = cody_provider:new({
        endpoint = "SRC_ENDPOINT",
        api_key_name = "SRC_ACCESS_TOKEN",
    })

    local resolved_endpoint = provider:resolve_env_value("SRC_ENDPOINT")
    eq(resolved_endpoint, test_endpoint)

    -- Clean up
    rawset(os, "getenv", original_getenv)
end

T["test cmd: command resolution"] = function()
    child.restart({ "-u", "tests/minimal_init.lua" })

    local cody_provider = require("avante-cody.cody-provider")

    local provider = cody_provider:new({
        endpoint = "cmd:echo https://test.sourcegraph.com",
        api_key_name = "SRC_ACCESS_TOKEN",
    })

    local resolved_endpoint = provider:resolve_env_value("cmd:echo https://test.sourcegraph.com")
    eq(resolved_endpoint, "https://test.sourcegraph.com")
end

T["test fallback to original endpoint when env vars not found"] = function()
    child.restart({ "-u", "tests/minimal_init.lua" })

    local cody_provider = require("avante-cody.cody-provider")

    local provider = cody_provider:new({
        endpoint = "https://fallback.sourcegraph.com",
        api_key_name = "SRC_ACCESS_TOKEN",
    })

    local resolved_endpoint = provider:resolve_env_value("https://fallback.sourcegraph.com")
    eq(resolved_endpoint, "https://fallback.sourcegraph.com")
end

T["test env: prefix resolution"] = function()
    child.restart({ "-u", "tests/minimal_init.lua" })

    local cody_provider = require("avante-cody.cody-provider")

    -- Test env: prefix resolution
    local test_endpoint = "https://env-prefix.sourcegraph.com"

    -- Create a mock environment with test values
    local function mock_getenv_env_prefix(name)
        if name == "SRC_ENDPOINT" then
            return test_endpoint
        end
        return nil -- Return nil for unknown env vars in test
    end

    -- Temporarily replace os.getenv for this test
    local original_getenv = os.getenv
    -- Use rawset to avoid duplicate-set-field warning
    rawset(os, "getenv", mock_getenv_env_prefix)

    local provider = cody_provider:new({
        endpoint = "env:SRC_ENDPOINT",
        api_key_name = "SRC_ACCESS_TOKEN",
    })

    local resolved_endpoint = provider:resolve_env_value("env:SRC_ENDPOINT")
    eq(resolved_endpoint, test_endpoint)

    -- Clean up
    rawset(os, "getenv", original_getenv)
end

return T
