-- This file needs to have the same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

-- Base46 Configuration
M.base46 = {
  theme = "catppuccin",
  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },
}

-- Neovim Options
local opt = {
  guicursor = "n-v-c:block-Cursor/lCursor-blinkon0", -- Set cursor to block and enable blinking
  -- spell = true, -- Enable spell checking
  -- spelllang = { "en_us", "fr" }, -- Set spell check language
  sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions", -- Session options
}

-- Apply Neovim options
for key, value in pairs(opt) do
  vim.opt[key] = value
end

-- Autocommands
vim.api.nvim_create_autocmd("FileType", {
  pattern = "vue",
  callback = function()
    vim.bo.commentstring = "<!-- %s -->" -- Set commentstring for Vue files
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "php",
  callback = function()
    -- Set the commentstring for PHP files
    vim.bo.commentstring = "// %s"
  end,
})

-- The file explorer is opened by auto-session's `no_restore_cmds` instead of a
-- VimEnter autocmd, so it does not race the session restore for the layout.

-- Plugin Configurations
require("nvim-tree").setup {
  filters = {
    git_ignored = false, -- Set to false to show git ignored files
  },
}

-- Notifications
vim.notify = require "notify"

-- Custom Commands
vim.api.nvim_create_user_command("CopyRelativePath", require("resources.helpers").copy_relative_path_to_clipboard, {})

-- Set clipboard to use xclip
vim.opt.clipboard = "unnamedplus" -- Use the system clipboard
vim.g.clipboard = {
  name = "xclip",
  copy = {
    ["+"] = "xclip -selection clipboard -i",
    ["*"] = "xclip -selection clipboard -i",
  },
  paste = {
    ["+"] = "xclip -selection clipboard -o",
    ["*"] = "xclip -selection clipboard -o",
  },
  cache_enabled = true,
}

return M
