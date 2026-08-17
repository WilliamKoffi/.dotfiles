return {
  "saecki/crates.nvim",
  ft = { "toml" },
  opts = {
    -- Completion is served by crates.nvim's in-process LSP server, which
    -- blink.cmp picks up like any other LSP source. The `completion.cmp`
    -- path would need nvim-cmp, which this config does not use.
    lsp = {
      enabled = true,
      actions = true,
      completion = true,
      hover = true,
    },
  },
}
