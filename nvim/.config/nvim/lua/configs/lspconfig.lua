-- load defaults i.e lua_lsp
-- This also sets capabilities and on_init globally via vim.lsp.config("*", ...)
-- and applies NvChad's on_attach from a single LspAttach autocmd, so individual
-- servers below never need to pass any of the three.
require("nvchad.configs.lspconfig").defaults()

-- Servers that need nothing beyond nvim-lspconfig's shipped configuration.
--
-- denols and ts_ls are both enabled: upstream resolves the conflict in their
-- root_dir callbacks by comparing the nearest deno.json/deno.lock against the
-- nearest package-manager lockfile, and whichever loses simply never attaches.
vim.lsp.enable {
  "html",
  "cssls",
  "ast_grep",
  "bashls",
  "jsonls",
  "pylsp",
  "intelephense",
  "denols",
  "ts_ls",
  -- vue_ls 3.x dropped takeover mode; it handles the template/style side of
  -- .vue files only. TypeScript inside .vue additionally needs ts_ls (or
  -- vtsls) running @vue/typescript-plugin, which is not installed here.
  "vue_ls",
}

vim.lsp.config("phpactor", {
  root_dir = function(_, on_dir)
    on_dir(vim.uv.cwd())
  end,
  init_options = {
    ["language_server.diagnostics_on_update"] = false,
    ["language_server.diagnostics_on_open"] = false,
    ["language_server.diagnostics_on_save"] = false,
    ["language_server_phpstan.enabled"] = false,
    ["language_server_psalm.enabled"] = false,
  },
})

vim.lsp.enable "phpactor"
