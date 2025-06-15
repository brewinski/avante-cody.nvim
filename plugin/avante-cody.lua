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
end
