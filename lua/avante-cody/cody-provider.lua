local log = require("avante-cody.util.log")

local LOG_SCOPE = "cody-provider"

-- Documentation for setting up Sourcegraph Cody
--- Generating an access token: https://sourcegraph.com/docs/cli/how-tos/creating_an_access_token

---@class avante_cody.AvanteProviderFunctor
local CodyProvider = {}

---@class avante_cody.AvanteProviderOpts All fields are optional as they'll be merged with defaults
---@field disable_tools? boolean
---@field endpoint? string
---@field api_key_name? string
---@field max_tokens? integer
---@field max_output_tokens? integer
---@field stream? boolean
---@field topK? integer
---@field topP? integer
---@field model? string
---@field proxy? string
---@field allow_insecure? boolean
---@field timeout? integer
---@field temperature? number
---@field cody_context? table
---@field role_map? table

---@class avante_cody.AvanteProviderFunctor
---@field disable_tools integer
---@field endpoint string
---@field api_key_name string
---@field max_tokens integer
---@field max_output_tokens integer
---@field stream boolean
---@field topK integer
---@field topP integer
---@field model string
---@field proxy string | nil
---@field allow_insecure boolean
---@field timeout integer
---@field temperature integer
---@field cody_context table
---@field role_map table

local default_opts = {
    use_xml_format = true,
    disable_tools = false,
    endpoint = "https://sourcegraph.com",
    api_key_name = "SRC_ACCESS_TOKEN",
    max_tokens = 30000,
    max_output_tokens = 4000,
    stream = true,
    topK = -1,
    topP = -1,
    model = "anthropic::2024-10-22::claude-3-7-sonnet-latest",
    proxy = nil,
    allow_insecure = false, -- Allow insecure server connections
    timeout = 30000, -- Timeout in milliseconds
    temperature = 0,
    cody_context = {},
    role_map = {
        user = "human",
        assistant = "assistant",
        system = "system",
    },
}

---@param opts? avante_cody.AvanteProviderOpts Options to override defaults
---@return avante_cody.AvanteProviderFunctor
function CodyProvider:new(opts)
    -- Create a new instance with default options
    local instance_opts = vim.deepcopy(default_opts)

    -- Override with any user-provided options
    if opts then
        instance_opts = vim.tbl_deep_extend("force", instance_opts, opts)
    end

    -- Create the provider instance with metatable for inheritance
    local cody_provider = setmetatable(instance_opts, { __index = self })

    -- Initialize the context for this instance
    cody_provider.cody_context = {}

    return cody_provider
end

function CodyProvider:transform_tool(tool)
    local input_schema_properties = {}
    local required = {}
    for _, field in ipairs(tool.param.fields) do
        input_schema_properties[field.name] = {
            type = field.type,
            description = field.description,
        }
        if not field.optional then
            table.insert(required, field.name)
        end
    end
    local res = {
        type = "function",
        ["function"] = {
            name = tool.name,
            description = tool.description,
        },
    }
    if vim.tbl_count(input_schema_properties) > 0 then
        res["function"].parameters = {
            type = "object",
            properties = input_schema_properties,
            required = required,
            additionalProperties = false,
        }
    end
    return res
end

function CodyProvider:parse_context_messages(context)
    local codebase_context = {}

    for _, blob in ipairs(context) do
        local path = blob.blob.path
        local file_content = blob.chunkContent

        table.insert(codebase_context, {
            speaker = self.role_map.user,
            text = "FILEPATH: " .. path .. "\nCode:\n" .. file_content,
            -- text = "FILEPATH: " .. vim.inspect(blob),
        })
        table.insert(codebase_context, {
            speaker = self.role_map.assistant,
            text = "Ok.",
        })
    end

    return codebase_context
end

function CodyProvider:parse_messages(opts)
    local messages = {
        { role = "system", text = opts.system_prompt },
    }

    vim.iter(self:parse_context_messages(self.cody_context)):each(function(msg)
        table.insert(messages, msg)
    end)

    vim.iter(opts.messages):each(function(msg)
        table.insert(messages, { speaker = self.role_map[msg.role], text = msg.content })
    end)

    if opts.tool_histories then
        for _, tool_history in ipairs(opts.tool_histories) do
            table.insert(messages, {
                speaker = "user",
                content = tool_history.tool_result.content,
                tool_call_id = tool_history.tool_result.tool_use_id,
            })
        end
    end

    return messages
end

function CodyProvider:parse_response_without_stream(data, state, opts)
    local json = vim.json.decode(data)
    local completion = json.completion
    local tool_calls = json.tool_calls
    local stopReason = json.stopReason
    local usage = json.usage

    opts.on_chunk(completion or "")

    if stopReason == "tool_use" then
        vim.schedule(function()
            local tools = {}

            for _, tool in ipairs(tool_calls) do
                table.insert(tools, {
                    id = tool.id,
                    name = tool["function"].name,
                    input_json = tool["function"].arguments,
                })
            end

            opts.on_stop({
                reason = "tool_use",
                usage = usage,
                tool_use_list = tools,
            })
        end)

        return
    end

    opts.on_stop({})
end

function CodyProvider.parse_response(_, ctx, data_stream, event_state, opts)
    log.debug(
        LOG_SCOPE,
        "parse_response: args: %s",
        vim.inspect({
            data_stream = data_stream,
            event_state = event_state,
            opts = opts,
            ctx = ctx,
        }, { newline = "" })
    )

    if event_state == "done" then
        opts.on_stop({})
        return
    end

    if event_state == "error" then
        log.error(
            LOG_SCOPE,
            "parse_response: error: %s",
            vim.inspect({
                data_stream = data_stream,
            }, { newline = "" })
        )
        opts.on_stop({ error = string.format("error: %s", data_stream) })
        return
    end

    if data_stream == nil or data_stream == "" then
        log.debug(LOG_SCOPE, "parse_response: data_stream is empty")
        return
    end

    local json = vim.json.decode(data_stream)
    local delta = json.deltaText
    local tool_use = json.delta_tool_calls
    local stopReason = json.stopReason
    local usage = json.usage

    if delta ~= nil and delta ~= "" then
        opts.on_chunk(delta)
    end

    if tool_use and tool_use[1] then
        log.debug(
            LOG_SCOPE,
            "parse_response: tool_use: %s",
            vim.inspect(tool_use, { newline = "" })
        )
        ctx.tool_use = ctx.tool_use
            or {
                {
                    id = "",
                    name = "",
                    input_json = "",
                },
            }

        local tool_use_ctx = ctx.tool_use
        local current_tool = tool_use_ctx[1]
        local tool = tool_use[1]

        current_tool.id = current_tool.id .. tool.id
        current_tool.name = current_tool.name .. tool["function"].name
        current_tool.input_json = current_tool.input_json .. tool["function"].arguments

        ctx.tool_use[1] = current_tool
    end

    if stopReason == "tool_use" then
        opts.on_stop({
            reason = "tool_use",
            usage = usage,
            tool_use_list = ctx.tool_use,
        })
        return
    end

    if stopReason == "end_turn" then
        -- opts.on_chunk('\n\n## context files:\n  - ' .. table.concat(M.get_context_file_list(M.cody_context), '\n  - '))
        opts.on_stop({ reason = "complete", useage = usage })
        return
    end
end

CodyProvider.BASE_PROVIDER_KEYS = {
    "endpoint",
    "model",
    "deployment",
    "api_version",
    "proxy",
    "allow_insecure",
    "api_key_name",
    "timeout",
    -- internal
    "local",
    "_shellenv",
    "tokenizer_id",
    "use_xml_format",
    "role_map",
}

function CodyProvider:parse_config(opts)
    local s1 = {}
    local s2 = {}

    for key, value in pairs(opts) do
        if vim.tbl_contains(self.BASE_PROVIDER_KEYS, key) then
            s1[key] = value
        else
            s2[key] = value
        end
    end

    return s1,
        vim.iter(s2)
            :filter(function(_, v)
                return type(v) ~= "function"
            end)
            :fold({}, function(acc, k, v)
                acc[k] = v
                return acc
            end)
end

function CodyProvider.parse_curl_args(provider, code_opts)
    log.debug(LOG_SCOPE, "parse_curl_args: args: %s", vim.inspect(code_opts, { newline = "" }))
    local base, body_opts = provider:parse_config(provider)

    local api_key = provider:parse_api_key()
    if api_key == nil then
        -- if no api key is available, make a request with a empty api key.
        api_key = ""
    end

    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "token " .. api_key,
    }

    local tools = nil
    if not provider.disable_tools and code_opts.tools then
        tools = {}
        for _, tool in ipairs(code_opts.tools) do
            table.insert(tools, provider:transform_tool(tool))
        end
    end

    local messages = provider:parse_messages(code_opts)

    return {
        -- url = base.endpoint .. '/.api/llm/chat/completions',
        url = base.endpoint
            .. "/.api/completions/stream?api-version=7&client-name=vscode&client-version=1.34.3",
        timeout = base.timeout,
        insecure = false,
        headers = headers,
        body = vim.tbl_deep_extend("force", {
            model = base.model,
            temperature = body_opts.tmemperature,
            topK = body_opts.topK,
            topP = body_opts.topP,
            maxTokensToSample = provider.max_output_tokens,
            stream = provider.stream,
            messages = messages,
            tools = tools,
        }, {}),
    }
end

function CodyProvider:is_disable_stream()
    return false
end

function CodyProvider:on_error() end

return CodyProvider
