local log = require("avante-cody.util.log")

--- @class avante_cody.EventDebugger
--- @field provider_name string
--- @field parse_curl_args table
--- @field parse_response table
local EventDebugger = {}

function EventDebugger:new(provider_name)
    local o = {
        provider_name = provider_name,
        parse_curl_args = {},
        parse_response = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function EventDebugger:on_parse_curl_args(inputs, outputs)
    table.insert(self.parse_curl_args, { inputs = inputs, outputs = outputs })
    return #self.parse_curl_args
end

function EventDebugger:print_on_curl_args(index, key)
    if not index or index == 0 then
        index = #self.parse_curl_args
    end

    log.debug("EventDebugger" .. self.provider_name, "index: %s", index)

    if not key or key == "" then
        key = "outputs"
    end

    log.debug("EventDebugger" .. self.provider_name, "key: %s", key)

    log.print(
        "EventDebugger" .. self.provider_name,
        "curl_args: %s",
        vim.inspect(self.parse_curl_args[index][key])
    )
end

function EventDebugger:on_parse_response(inputs, outputs)
    table.insert(self.parse_response, { inputs = inputs, outputs = outputs })
    return #self.parse_response
end

function EventDebugger:print_on_parse_response()
    log.print(
        "EventDebugger" .. self.provider_name,
        "response: %s",
        vim.inspect(self.parse_response)
    )
end

return EventDebugger
