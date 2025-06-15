local log = {}

local longest_scope = 15

--- @class FileWriter
--- @field filename string | nil
--- @field file file* | nil
local FileWriter = {
    file = nil,
    filepath = nil,
    log_scope = "file-writer",
}

function FileWriter:new()
    local log_directory = vim.fn.stdpath("data")
    local log_file = "avante-cody.nvim.log"
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.filepath = string.format("%s/%s", log_directory, log_file)
    return o
end

function FileWriter:open()
    -- if the file is already open, close it.
    if self.file then
        self.file:close()
        self.file = nil
    end

    if not self.filepath or self.filepath == "" then
        return
    end

    local file = assert(io.open(self.filepath, "a"))

    self.file = file

    log.print(self.log_scope, string.format("log file opened/created at %s", self.filepath))
end

function FileWriter:write(str)
    if not self.file then
        self:open()
    end

    if self.file then
        self.file:write(str)
        self.file:flush()
    end
end

function FileWriter:close()
    if self.file then
        self.file:close()
        self.file = nil
    end
end

local writer = nil

--- prints only if debug is true.
---
---@param scope string: the scope from where this function is called.
---@param str string: the formatted string.
---@param ... any: the arguments of the formatted string.
---@private
function log.print(scope, str, ...)
    return log.notify(scope, vim.log.levels.DEBUG, true, str, ...)
end

--- prints only if debug is true.
---
---@param scope string: the scope from where this function is called.
---@param str string: the formatted string.
---@param ... any: the arguments of the formatted string.
---@private
function log.debug(scope, str, ...)
    return log.notify(scope, vim.log.levels.DEBUG, false, str, ...)
end

--- prints only if error is true.
---
---@param scope string: the scope from where this function is called.
---@param str string: the formatted string.
---@param ... any: the arguments of the formatted string.
---@private
function log.error(scope, str, ...)
    return log.notify(scope, vim.log.levels.ERROR, false, str, ...)
end

--- prints only if debug is true.
---
---@param scope string: the scope from where this function is called.
---@param level string: the log level of vim.notify.
---@param verbose boolean: when false, only prints when config.debug is true.
---@param str string: the formatted string.
---@param ... any: the arguments of the formatted string.
---@private
function log.notify(scope, level, verbose, str, ...)
    if string.len(scope) > longest_scope then
        longest_scope = string.len(scope)
    end

    for i = longest_scope, string.len(scope), -1 do
        if i < string.len(scope) then
            scope = string.format("%s ", scope)
        else
            scope = string.format("%s", scope)
        end
    end

    -- write to log file if provided.
    if _G.AvanteCody.config.logfile then
        if not writer then
            writer = FileWriter:new()
        end

        writer:write(
            string.format(
                "[avante-cody.nvim@%s] level=%s message=%s\n",
                scope,
                level,
                string.format(str, ...)
            )
        )
    end

    -- if debug is false, don't print.
    if not verbose and _G.AvanteCody.config ~= nil and not _G.AvanteCody.config.debug then
        return
    end

    vim.notify(
        string.format("[avante-cody.nvim@%s] %s", scope, string.format(str, ...)),
        level,
        { title = "avante-cody.nvim" }
    )
end

--- analyzes the user provided `setup` parameters and sends a message if they use a deprecated option, then gives the new option to use.
---
---@param options table: the options provided by the user.
---@private
function log.warn_deprecation(options)
    local uses_deprecated_option = false
    local notice = "is now deprecated, use `%s` instead."
    local root_deprecated = {
        foo = "bar",
        bar = "baz",
    }

    for name, warning in pairs(root_deprecated) do
        if options[name] ~= nil then
            uses_deprecated_option = true
            log.notify(
                "deprecated_options",
                vim.log.levels.WARN,
                true,
                string.format("`%s` %s", name, string.format(notice, warning))
            )
        end
    end

    if uses_deprecated_option then
        log.notify(
            "deprecated_options",
            vim.log.levels.WARN,
            true,
            "sorry to bother you with the breaking changes :("
        )
        log.notify(
            "deprecated_options",
            vim.log.levels.WARN,
            true,
            "use `:h AvanteCody.options` to read more."
        )
    end
end

return log
