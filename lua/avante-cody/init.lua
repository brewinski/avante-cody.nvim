local main = require("avante-cody.main")
local config = require("avante-cody.config")

local AvanteCody = {}

-- setup AvanteCody options and merge them with user provided ones.
function AvanteCody.setup(opts)
    _G.AvanteCody.config = config.setup(opts)

    if not opts then
        return
    end

    local providers = opts.providers or {}
    for provider_name, provider_opts in pairs(providers) do
        main.register_provider(provider_name, provider_opts)
    end
end

_G.AvanteCody = AvanteCody

return _G.AvanteCody
