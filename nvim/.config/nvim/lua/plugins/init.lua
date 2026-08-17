return {
  { import = "nvchad.blink.lazyspec" },
  {
    "stevearc/conform.nvim",
    event = "BufWritePre", -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "rust",
        "css",
        "json",
        "bash",
        "blade",
        "php",
        "php_only",
        "vue",
        "javascript",
        "typescript",
      },
      highlight = {
        enable = true,
      },
    },
    config = function(_, opts)
      require "configs.treesitter"(opts)
    end,
  },

  {
    "mg979/vim-visual-multi", -- Plugin repository
    event = "VeryLazy", -- Load the plugin when Neovim is idle
  },
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonInstallAll" },
    -- mason.nvim has no `ensure_installed` setting of its own — it silently
    -- ignores unknown keys, so this list only takes effect via the
    -- :MasonInstallAll command defined below.
    config = function(_, opts)
      require("mason").setup(opts)

      vim.api.nvim_create_user_command("MasonInstallAll", function()
        local registry = require "mason-registry"
        registry.refresh(function()
          for _, name in ipairs(opts.ensure_installed or {}) do
            local ok, pkg = pcall(registry.get_package, name)
            if not ok then
              vim.notify("mason: unknown package " .. name, vim.log.levels.WARN)
            elseif not pkg:is_installed() then
              pkg:install()
            end
          end
        end)
      end, { desc = "Install every package listed in ensure_installed" })
    end,
    opts = {
      ensure_installed = {
        "lua-language-server",
        "stylua",
        "html-lsp",
        "css-lsp",
        "typescript-language-server",
        "phpactor",
        "ast-grep",
        "bash-language-server",
        "deno",
        "json-lsp",
        "python-lsp-server",
        "rust-analyzer",
        "clangd",
        "prettierd",
        "black",
        "isort",
        "pint",
        "beautysh",
        "intelephense",
        "vue-language-server",
        "tailwindcss-language-server",
      },
    },
  },
}
