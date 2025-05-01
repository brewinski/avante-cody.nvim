local log = require("avante-cody.util.log")
local HistoryMessage = require("avante.history_message")

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

---@class CodeContextBlob
---@field blob table Information about the code file
---@field blob.path string Path to the code file
---@field chunkContent string Content of the code chunk

--- Parse codebase context into conversation messages
---@param context CodeContextBlob[] List of code context blobs
---@return ParsedMessage[] List of parsed context messages
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

--- Add a user tool result message to the message list
---@param messages ParsedMessage[] The messages table to append to
---@param msg CodyMessage The original message from the user
---@param msg_content CodyToolMessageContent The content portion of the message
function CodyProvider:add_user_tool_result(messages, msg, msg_content)
    table.insert(messages, {
        speaker = self.role_map[msg.role],
        content = {
            {
                type = "tool_result",
                tool_result = {
                    id = msg_content.tool_use_id,
                    content = msg_content.content,
                },
            },
        },
    })
end

--- Add an assistant tool call message to the message list
---@param messages ParsedMessage[] The messages table to append to
---@param msg CodyMessage The original message from the assistant
---@param msg_content CodyToolMessageContent The content portion of the message
function CodyProvider:add_assistant_tool_call(messages, msg, msg_content)
    table.insert(messages, {
        speaker = self.role_map[msg.role],
        content = {
            { type = "text", text = "call this tool for me" },
            {
                type = "tool_call",
                tool_call = {
                    id = msg_content.id,
                    name = msg_content.name,
                    arguments = vim.json.encode(msg_content.input),
                },
            },
        },
    })
end

--- Process and append tool histories to the messages list
---@param messages ParsedMessage[] The messages table to append to
---@param tool_histories CodyToolHistory[] List of tool history entries to process
function CodyProvider:append_tool_histories(messages, tool_histories)
    for _, tool_history in ipairs(tool_histories) do
        -- Create and append assistant message with tool call
        local assistant_message = {
            speaker = "assistant",
            content = {
                { type = "text", text = "call this tool for me" },
                {
                    type = "tool_call",
                    tool_call = {
                        id = tool_history.tool_use.id,
                        name = tool_history.tool_use.name,
                        arguments = tool_history.tool_use.input_json,
                    },
                },
            },
        }

        -- Create and append human message with tool result
        local human_message = {
            speaker = "user",
            content = {
                {
                    type = "tool_result",
                    tool_result = {
                        id = tool_history.tool_result.tool_use_id,
                        content = tool_history.tool_result.content,
                    },
                },
            },
        }

        -- Add both messages to the conversation
        table.insert(messages, assistant_message)
        table.insert(messages, human_message)
    end
end

---@class CodyToolMessageContent
---@field id string The ID of the tool call
---@field name string The name of the tool
---@field input table|string The input to the tool
---@field tool_use_id string ID of the tool use (for tool results)
---@field content string Content of the tool result

---@class CodyMessage
---@field role string The role of the message sender (user, assistant, system)
---@field content string|table Either a string for plain text or a table for tool calls/results
---

---@class CodyToolHistory
---@field tool_use table Information about the tool use
---@field tool_use.id string ID of the tool use
---@field tool_use.name string Name of the tool
---@field tool_use.input_json string JSON string of the tool arguments
---@field tool_result table Information about the tool result
---@field tool_result.tool_use_id string ID of the associated tool use
---@field tool_result.content string Content of the tool result

---@class ParseMessagesOpts
---@field system_prompt string The system prompt text
---@field messages CodyMessage[] List of messages in the conversation
---@field tool_histories? CodyToolHistory[] Optional list of tool use histories

---@class ParsedMessage
---@field speaker string The speaker role mapped to Cody format
---@field text? string The message text (for plain text messages)
---@field content? table The content for tool calls or results

--- Parse conversation messages into the format required by Cody API
---@param opts ParseMessagesOpts Options containing the conversation data
---@return ParsedMessage[] List of parsed messages in Cody format
function CodyProvider:parse_messages(opts)
    local messages = {
        { speaker = self.role_map.system, text = opts.system_prompt },
    }

    vim.iter(self:parse_context_messages(self.cody_context)):each(function(msg)
        table.insert(messages, msg)
    end)

    vim.iter(opts.messages):each(function(msg)
        -- Case 1: Plain text content
        if type(msg.content) ~= "table" then
            table.insert(messages, {
                speaker = self.role_map[msg.role],
                text = msg.content,
            })
            return
        end

        -- Table-type content (tool calls or results)
        local msg_content = msg.content[1]

        if msg.role == "user" then
            -- User tool result
            self:add_user_tool_result(messages, msg, msg_content)
        else
            -- Assistant tool call
            self:add_assistant_tool_call(messages, msg, msg_content)
        end
    end)

    if opts.tool_histories then
        self:append_tool_histories(messages, opts.tool_histories)
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

function CodyProvider:add_tool_use_message(tool_use, state, opts)
    local jsn = nil
    if state == "generated" then
        jsn = vim.json.decode(tool_use.input_json)
    end
    local msg = HistoryMessage:new({
        role = "assistant",
        content = {
            {
                type = "tool_use",
                name = tool_use.name,
                id = tool_use.id,
                input = jsn or {},
            },
        },
    }, {
        state = state,
        uuid = tool_use.uuid,
    })
    tool_use.uuid = msg.uuid
    tool_use.state = state
    if opts.on_messages_add then
        opts.on_messages_add({ msg })
    end
end

function CodyProvider:add_text_message(ctx, text, state, opts)
    if ctx.content == nil then
        ctx.content = ""
    end
    ctx.content = ctx.content .. text
    local msg = HistoryMessage:new({
        role = "assistant",
        content = ctx.content,
    }, {
        state = state,
        uuid = ctx.content_uuid,
    })
    ctx.content_uuid = msg.uuid
    if opts.on_messages_add then
        opts.on_messages_add({ msg })
    end
end

function CodyProvider:finish_pending_messages(ctx, opts)
    if ctx.content ~= nil and ctx.content ~= "" then
        self:add_text_message(ctx, "", "generated", opts)
    end
    if ctx.tool_use_list then
        for _, tool_use in ipairs(ctx.tool_use_list) do
            if tool_use.state == "generating" then
                self:add_tool_use_message(tool_use, "generated", opts)
            end
        end
    end
end

---@class avante_cody.AvanteOnStopOpts
---@field reason? string
---@field error? string
---@field tool_use_list? table
---@field usage? table
---@field stopReason? string
---

---@class avante_cody.AvanteParseResponseOpts
---@field on_stop fun(opts: {})
---@field on_chunk fun(chunk: string)

---@param ctx any
---@param data_stream string
---@param event_state string
---@param opts avante_cody.AvanteParseResponseOpts
function CodyProvider.parse_response(self, ctx, data_stream, event_state, opts)
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
        self:finish_pending_messages(ctx, opts)
        if opts.on_stop then
            opts.on_stop({})
        end
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
        opts.on_stop({ reason = "error", error = string.format("error: %s", data_stream) })
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
        if opts.on_chunk then
            opts.on_chunk(delta)
        end

        self:add_text_message(ctx, delta, "generating", opts)
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
        self:add_tool_use_message(current_tool, "generating", opts)
    end

    if stopReason == "tool_use" then
        local prev_tool_use = ctx.tool_use[1]
        self:add_tool_use_message(prev_tool_use, "generated", opts)
        -- self:finish_pending_messages(ctx, opts)
        opts.on_stop({
            reason = "tool_use",
            usage = usage,
            tool_use_list = ctx.tool_use,
        })
        return
    end

    if stopReason == "end_turn" then
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

---@class avante_cody.CodyProviderCodyTool
---@field name string
---@field description string
---@field parameters { type: string, properties: { [string]: { type: string, description: string }, additionalProperties: boolean, required: string[] } }
---@field type string
---@field id string

---@class avante_cody.CodyProviderCurlHeaders
---@field Content-Type string
---@field Authorization string
---
---@class avante_cody.CodyProviderCurlMessages
---@field speaker string
---@field text string
---
---@class avante_cody.CodyProviderCurlBody
---@field model string
---@field messages avante_cody.CodyProviderCurlMessages
---@field temperature number
---@field topK integer
---@field topP number
---@field stream boolean
---@field maxTokensToSample integer
---@field tools { type: string, ["function"]: avante_cody.CodyProviderCodyTool }[]
---
---@class avante_cody.CodyProviderCurlArgs
---@field url string
---@field timeout integer
---@field headers avante_cody.CodyProviderCurlHeaders
---@field body avante_cody.CodyProviderCurlBody
---@field insecure boolean

--- @return avante_cody.CodyProviderCurlArgs
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
        url = base.endpoint
            .. "/.api/completions/stream?api-version=7&client-name=vscode&client-version=1.34.3",
        timeout = base.timeout,
        insecure = base.allow_insecure,
        headers = headers,
        body = vim.tbl_deep_extend("force", {
            model = base.model,
            temperature = body_opts.temperature,
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
