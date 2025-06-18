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

function EventDebugger:print_on_curl_args(data_type, index)
    if not index or index == 0 then
        index = #self.parse_curl_args
    end

    log.debug("EventDebugger" .. self.provider_name, "index: %s", index)

    if not data_type or data_type == "" then
        data_type = "outputs"
    end

    log.debug("EventDebugger" .. self.provider_name, "key: %s", data_type)

    log.print(
        "EventDebugger" .. self.provider_name,
        "curl_args: %s",
        vim.inspect(self.parse_curl_args[index][data_type])
    )
end

function EventDebugger:on_parse_response(inputs)
    table.insert(self.parse_response, inputs)
    return #self.parse_response
end

function EventDebugger:print_on_parse_response()
    log.print(
        "EventDebugger" .. self.provider_name,
        "parse_response: %s",
        vim.inspect(self.parse_response, { depth = 5 })
    )
end

return EventDebugger
