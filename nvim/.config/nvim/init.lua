vim.wo.relativenumber = true

vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

-- Enable line wrapping
vim.opt.wrap = true -- Enable line wrapping
vim.opt.linebreak = true -- Break lines at convenient points
vim.opt.breakindent = true -- Indent wrapped lines
vim.opt.rtp:prepend(lazypath)
vim.opt.list = true -- Enable the display of whitespace characters
vim.opt.listchars = {
  tab = "🞂 ", -- Display tabs as a specific character followed by a space
  trail = "•", -- Display trailing spaces as a dot
}
vim.opt.scrolloff = 8 -- Set the number of lines to keep above and below the cursor when scrolling
vim.opt.sidescroll = 8 -- Set the number of columns to scroll horizontally when the cursor reaches the edge of the window

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "nvchad.autocmds"

vim.schedule(function()
  require "mappings"
end)
