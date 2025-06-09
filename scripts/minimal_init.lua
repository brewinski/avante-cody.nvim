-- Add current directory to 'runtimepath' to be able to use 'lua' files
vim.cmd([[let &rtp.=','.getcwd()]])

-- Set up 'mini.test' and 'mini.doc' only when calling headless Neovim (like with `make test` or `make documentation`)
if #vim.api.nvim_list_uis() == 0 then
    -- Add 'mini.nvim' to 'runtimepath' to be able to use 'mini.test'
    -- Assumed that 'mini.nvim' is stored in 'deps/mini.nvim'
    vim.cmd("set rtp+=deps/mini.nvim")
    -- add avante to the runtimepath to be able to test config.
    vim.cmd("set rtp+=deps/avante.nvim")
    -- add plenary to the runtime path to test config
    vim.cmd("set rtp+=deps/plenary.nvim")

    -- Set up 'mini.test'
    require("mini.test").setup()

    -- Set up 'mini.doc'
    require("mini.doc").setup()
end
