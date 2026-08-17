return {
  "rmagatti/auto-session",
  lazy = false,
  -- Must be set before auto-session reads it; chadrc.lua runs too late.
  init = function()
    vim.opt.sessionoptions:append "localoptions"
  end,
  opts = {
    log_level = "info",
    auto_restore_last_session = true,
    auto_create = true,
    auto_restore = true,
    auto_save = true,
    root_dir = vim.fn.expand(os.getenv "HOME" .. "/.cache/nvim/sessions/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t")),

    -- A restored session already carries its own window layout, so only open
    -- the file tree when there was nothing to restore.
    --
    -- It must not open before UIEnter: NvChad gates its `User FilePost` event
    -- on the current buffer having a real file name, and a nofile tree buffer
    -- in that slot closes the gate for good -- nvim-lspconfig then never loads
    -- and no language server ever attaches.
    no_restore_cmds = {
      function()
        local function open()
          pcall(vim.cmd, "NvimTreeOpen")
        end
        if vim.v.vim_did_enter == 1 then
          vim.schedule(open)
        else
          vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = vim.schedule_wrap(open) })
        end
      end,
    },

    -- Use session-lens for searching saved sessions
    session_lens = {
      load_on_setup = true,
      picker_opts = { border = true, previewer = false },
    },
  },
}
