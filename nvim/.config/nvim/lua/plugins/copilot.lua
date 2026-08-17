return {
  "github/copilot.vim",
  lazy = false, -- This tells Lazy.nvim to always load this plugin
  -- Must be set before copilot.vim's plugin file installs its <Tab> mapping.
  init = function()
    vim.g.copilot_no_tab_map = true
  end,
  config = function()
    vim.keymap.set("i", "<C-F>", 'copilot#Accept("\\<CR>")', {
      expr = true,
      replace_keycodes = false,
    })
  end,
}
