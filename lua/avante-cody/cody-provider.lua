local log = require("avante-cody.util.log")
local HistoryMessage = require("avante.history.message")
local JsonParser = require("avante.libs.jsonparser")
local Utils = require("avante.utils")

local LOG_SCOPE = "cody-provider"

-- Documentation for setting up Sourcegraph Cody
--- Generating an access token: https://sourcegraph.com/docs/cli/how-tos/creating_an_access_token

---@class avante_cody.AvanteProviderFunctor
local CodyProvider = {}

---@class avante_cody.AvanteProviderOpts All fields are optional as they'll be merged with defaults
---@field disable_tools? boolean
---@field endpoint? string
---@field api_key_name? string
---@field context_window? integer
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
---@field disable_tools boolean
---@field endpoint string
---@field api_key_name string
---@field context_window integer
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
    max_tokens = 100000,
    context_window = 150000,
    max_output_tokens = 64000,
    stream = true,
    topK = -1,
    topP = -1,
    model = "anthropic::2024-10-22::claude-sonnet-4-latest",
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

---@param event_debugger? avante_cody.EventDebugger
---@param opts? avante_cody.AvanteProviderOpts Options to override defaults
---@return avante_cody.AvanteProviderFunctor
function CodyProvider:new(opts, event_debugger)
    -- Create a new instance with default options
    local instance_opts = vim.deepcopy(default_opts)

    -- Override with any user-provided options
    if opts then
        instance_opts = vim.tbl_deep_extend("force", instance_opts, opts)
    end

    -- Create the provider instance with metatable for inheritance
    local cody_provider = setmetatable(instance_opts, { __index = self })

    cody_provider.parse_curl_args = function(provider, curl_opts)
        if getmetatable(self) ~= CodyProvider then
            setmetatable(instance_opts, { __index = CodyProvider })
        end

        if getmetatable(provider) ~= CodyProvider then
            setmetatable(provider, { __index = CodyProvider })
        end

        provider.event_debugger = event_debugger
        self.event_debugger = event_debugger

        return self.parse_curl_args(self, provider, curl_opts)
    end

    -- Initialize the context for this instance
    cody_provider.cody_context = {}
    cody_provider.event_debugger = event_debugger

    return cody_provider
end

function CodyProvider:transform_tool(tool)
    local input_schema_properties, required =
        Utils.llm_tool_param_fields_to_json_schema(tool.param.fields)
    local parameters = nil
    if not vim.tbl_isempty(input_schema_properties) then
        parameters = {
            type = "object",
            properties = input_schema_properties,
            required = required,
            additionalProperties = false,
        }
    end
    local res = {
        type = "function",
        ["function"] = {
            name = tool.name,
            description = tool.get_description and tool.get_description() or tool.description,
            parameters = parameters,
        },
    }
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
---@param opts? { is_thinking_model?: boolean }
function CodyProvider:add_user_tool_result(messages, msg, msg_content, opts)
    opts = opts or { is_thinking_model = false }

    local tool_result_message = {
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
    }

    -- BUGFIX: add a message after tool result for thinkng models to avoid anthropic reqirement to add thinking messages.
    -- Sourcegraph API doesn't support thinking messages, (AFAIK)
    if opts.is_thinking_model then
        table.insert(
            tool_result_message.content,
            { type = "text", text = "Ok. This is the result of the tool." }
        )
    end

    table.insert(messages, tool_result_message)
end

--- Add an assistant tool call message to the message list
---@param messages ParsedMessage[] The messages table to append to
---@param msg CodyMessage The original message from the assistant
---@param msg_content CodyToolMessageContent The content portion of the message
function CodyProvider:add_assistant_tool_call(messages, msg, msg_content)
    local assistant_message = { type = "text", text = "Ok. I'll run this now." }

    local tool_use_message = {
        speaker = self.role_map[msg.role],
        content = {
            assistant_message,
            {
                type = "tool_call",
                tool_call = {
                    id = msg_content.id,
                    name = msg_content.name,
                    arguments = vim.json.encode(msg_content.input),
                },
            },
        },
    }

    -- when the prev message is an assistan message, we'll replace it with the tool use message and combine it
    -- into a single mesage group
    local prev_message_is_assistant = messages[#messages].speaker == self.role_map.assistant
        and messages[#messages].content[1].type == "text"
        and #messages[#messages].content == 1

    if prev_message_is_assistant then
        assistant_message.text = messages[#messages].content[1].text
            or ("I'll use the " .. msg_content.name .. " tool.")
        messages[#messages] = tool_use_message
        return
    end

    -- otherwise append the tool use message.
    table.insert(messages, tool_use_message)
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
    local tool_metadata = {
        is_thinking_model = false,
    }

    local messages = {
        {
            speaker = self.role_map.system,
            content = {
                {
                    type = "text",
                    text = opts.system_prompt,
                    cache_control = { type = "ephemeral" },
                },
            },
        },
    }

    vim.iter(self:parse_context_messages(self.cody_context)):each(function(msg)
        table.insert(messages, msg)
    end)

    vim.iter(opts.messages):each(function(msg)
        -- Case 1: Plain text content
        if type(msg.content) ~= "table" then
            -- BUGFIX: handle messages with empty content by dropping the message.
            if msg.content:match("^%s*$") then -- checks if string is empty or only whitespace
                return
            end

            table.insert(messages, {
                speaker = self.role_map[msg.role],
                content = {
                    { type = "text", text = msg.content },
                },
            })
            return
        end

        -- Table-type content (tool calls or results)
        local msg_content = msg.content[1]

        --- Case 2: Thinking message
        if msg_content.type == "thinking" then
            tool_metadata.is_thinking_model = true
            -- skip thinking messages
            return
        end

        -- Case 3: Tool call
        if msg_content.type == "tool_use" then
            self:add_assistant_tool_call(messages, msg, msg_content)
        end

        -- Case 4: Tool result
        if msg_content.type == "tool_result" then
            self:add_user_tool_result(messages, msg, msg_content, tool_metadata)
        end
    end)

    -- add cache control flag to the final message
    local found = false
    -- reverse itterate through messages until we find the last assistant message.
    for i = #messages, 1, -1 do
        if found then
            break
        end
        local message = messages[i]
        local content = message.content

        if message.speaker == self.role_map.assistant then
            for j = #content, 1, -1 do
                local item = content[j]
                if item.type == "text" then
                    item.cache_control = { type = "ephemeral" }
                    found = true
                    break
                end
            end
        end
    end

    return messages
end

function CodyProvider:parse_response_without_stream(data, state, opts)
    local json = vim.json.decode(data)
    local completion = json.completion
    local tool_calls = json.tool_calls
    local stopReason = json.stopReason
    ---@type avante_cody.CodyUsage
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
    local jsn = JsonParser.parse(tool_use.input_json)
    local msg = HistoryMessage:new("assistant", {
        type = "tool_use",
        name = tool_use.name,
        id = tool_use.id,
        input = jsn or {},
    }, {
        state = state,
        uuid = tool_use.uuid,
        turn_id = tool_use.turn_id,
    })
    tool_use.uuid = msg.uuid
    tool_use.state = state
    if opts.on_messages_add then
        opts.on_messages_add({ msg })
    end
    if state == "generating" then
        opts.on_stop({ reason = "tool_use", streaming_tool_use = true })
    end
end

function CodyProvider:add_text_message(ctx, text, state, opts)
    if ctx.content == nil then
        ctx.content = ""
    end
    ctx.content = ctx.content .. text

    local msg = HistoryMessage:new("assistant", ctx.content, {
        state = state,
        turn_id = ctx.turn_id,
        uuid = ctx.content_uuid,
    })

    ctx.content_uuid = msg.uuid
    if opts.on_messages_add then
        opts.on_messages_add({ msg })
    end
end

function CodyProvider:add_thinking_message(ctx, text, state, opts)
    if ctx.reasonging_content == nil then
        ctx.reasonging_content = ""
    end

    ctx.reasonging_content = ctx.reasonging_content .. text
    local msg = HistoryMessage:new("assistant", {
        type = "thinking",
        thinking = ctx.reasonging_content,
        signature = "",
    }, {
        state = state,
        turn_id = ctx.turn_id,
        uuid = ctx.reasonging_content_uuid,
    })
    ctx.reasonging_content_uuid = msg.uuid
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

---@class avante_cody.CodyUsageDetails
---@field cached_tokens? integer Number of tokens that were cached
---@field cache_creation_input_tokens? integer Number of input tokens used to create cache

---@class avante_cody.CodyUsage
---@field completion_tokens? integer Number of tokens in the completion
---@field prompt_tokens? integer Number of tokens in the prompt
---@field total_tokens? integer Total number of tokens used
---@field credits? integer Number of credits consumed
---@field prompt_tokens_details? avante_cody.CodyUsageDetails Additional details about prompt tokens

---@class avante_cody.AvanteOnStopOpts
---@field reason? string
---@field error? string
---@field tool_use_list? table
---@field usage? avante_cody.CodyUsage
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
    if self.event_debugger then
        self.event_debugger:on_parse_response({
            ctx = ctx,
            data_stream = data_stream,
            event_state = event_state,
            opts = opts,
        })
    end

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
        self:finish_pending_messages(ctx, opts)
        log.error(
            LOG_SCOPE,
            "parse_response: error: %s",
            vim.inspect({
                data_stream = data_stream,
            }, { newline = "" })
        )
        local usage = nil
        -- TODO: move error checking into a function
        local is_prompt_length_error = string.match(data_stream, "prompt is too long")
        if is_prompt_length_error then
            usage = {
                prompt_tokens = self.context_window,
                completion_tokens = self.context_window,
            }
        end
        opts.on_stop({
            reason = "error",
            error = string.format("error: %s", data_stream),
            usage = usage,
        })
        return
    end

    if data_stream == nil or data_stream == "" then
        log.debug(LOG_SCOPE, "parse_response: data_stream is empty")
        return
    end

    local json = vim.json.decode(data_stream)
    local delta = json.deltaText
    local delta_thinking = json.delta_thinking
    local tool_use = json.delta_tool_calls
    local stopReason = json.stopReason
    ---@type avante_cody.CodyUsage
    local usage = json.usage

    if delta_thinking ~= nil and delta_thinking ~= "" then
        if opts.on_chunk then
            opts.on_chunk(delta_thinking)
        end
        self:add_thinking_message(ctx, delta_thinking, "generating", opts)
    end

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
        self:finish_pending_messages(ctx, opts)
        -- TODO: add function for calculating usage.
        local total_usage = {
            prompt_tokens = usage.prompt_tokens
                + usage.prompt_tokens_details.cache_creation_input_tokens
                + usage.prompt_tokens_details.cached_tokens,
            completion_tokens = usage.completion_tokens,
        }
        -- vim.print(vim.inspect(usage, { newline = "" }))
        opts.on_stop({
            reason = "tool_use",
            usage = total_usage,
            tool_use_list = ctx.tool_use,
        })
        return
    end

    if stopReason == "end_turn" then
        self:finish_pending_messages(ctx, opts)
        local total_usage = {
            prompt_tokens = usage.prompt_tokens
                + usage.prompt_tokens_details.cache_creation_input_tokens
                + usage.prompt_tokens_details.cached_tokens,
            completion_tokens = usage.completion_tokens,
        }
        -- vim.print(vim.inspect(usage, { newline = "" }))
        opts.on_stop({ reason = "complete", useage = total_usage })
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

---Resolve environment variable or command for a value
---@param value string The value to resolve (env var name or cmd: command)
---@return string|nil The resolved value
function CodyProvider:resolve_env_value(value)
    if type(value) ~= "string" then
        return value
    end
    -- Check if it starts with 'cmd:' for command execution
    if value:match("^cmd:") then
        local cmd = value:sub(5) -- Remove 'cmd:' prefix
        local handle = io.popen(cmd)
        if handle then
            local result = handle:read("*line")
            handle:close()
            return result and result:gsub("%s+$", "") or nil -- trim trailing whitespace
        end
        return nil
    end

    -- Check if it starts with 'env:' for explicit env var
    if value:match("^env:") then
        return os.getenv(value:sub(5))
    end
    -- Try to resolve as environment variable if not a URL
    if not value:match("^https?://") then
        local env_value = os.getenv(value)
        if env_value then
            return env_value
        end
    end
    -- Otherwise return the original value
    return value
end

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

    -- Resolve endpoint with potential environment variables
    s1.endpoint = self:resolve_env_value(s1.endpoint)

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
function CodyProvider:parse_curl_args(provider, code_opts)
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
        -- add cache control to the final tool
        local last_tool = tools[#tools]
        last_tool.cache_control = { type = "ephemeral" }
    end

    local messages = provider:parse_messages(code_opts)

    if provider.event_debugger then
        provider.event_debugger:on_parse_curl_args(
            { code_opts = code_opts },
            { messages = messages }
        )
    end

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
