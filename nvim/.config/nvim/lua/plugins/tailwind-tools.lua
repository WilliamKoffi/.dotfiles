return {
  {
    "luckasRanarison/tailwind-tools.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    -- Resolved lazily: a top-level require here would run while lazy.nvim is
    -- importing plugin specs, forcing NvChad's LSP module to load at startup.
    opts = function()
      local nvlsp = require "nvchad.configs.lspconfig"
      return {
        server = {
          override = true,
          on_attach = nvlsp.on_attach,
          on_init = nvlsp.on_init,
          capabilities = nvlsp.capabilities,
        },
      }
    end,
  },
}
