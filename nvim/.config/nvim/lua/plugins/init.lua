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
    -- nvim-treesitter `main`. Parsers and queries are installed per language
    -- into stdpath("data")/site, so a language missing from this list has no
    -- queries at all -- unlike `master`, where every query sat on the rtp.
    -- Run :TSInstallAll after changing it. Highlighting is started by
    -- NvChad's FileType autocmd, so there is no `highlight` option here.
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false, -- upstream states the `main` rewrite does not support lazy-loading
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "luadoc",
        "vimdoc",
        "printf",
        "html",
        "rust",
        "css",
        "json",
        "toml",
        "bash",
        "blade",
        "php",
        "php_only",
        "phpdoc",
        "vue",
        "javascript",
        "typescript",
        "comment",
        "regex",
      },
    },
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
