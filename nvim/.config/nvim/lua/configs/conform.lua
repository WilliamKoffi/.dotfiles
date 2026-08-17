local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettierd" },
    vue = { "prettierd" },
    html = { "prettierd" },
    javascript = { "prettierd" },
    typescript = { "prettierd" },
    javascriptreact = { "prettierd" },
    php = { "pint" },
    rust = { "rustfmt" },
    cpp = { "clang-format" },
    python = { "isort", "black" },
    sh = { "beautysh" },
  },

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_format = "fallback",
  },
}

return options
