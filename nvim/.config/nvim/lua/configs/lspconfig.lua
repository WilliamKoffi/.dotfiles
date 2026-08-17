-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"

-- EXAMPLE
local servers = { "html", "cssls", "ast_grep", "bashls", "jsonls", "pylsp", "intelephense" }
local nvlsp = require "nvchad.configs.lspconfig"

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

-- configuring single server, example: typescript
lspconfig.denols.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
  single_file_support = false,
}

lspconfig.volar.setup {
  on_attach = function(client, bufnr)
    for _, c in ipairs(vim.lsp.get_clients()) do
      if c.name == "denols" then
        vim.notify("denols is running, skipping ts_ls setup", vim.log.levels.WARN)
        client.stop()
        return
      end
    end
    nvlsp.on_attach(client, bufnr)
  end,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
  init_options = {
    vue = {
      -- disable hybrid mode
      hybridMode = false,
    },
  },
}

lspconfig.ts_ls.setup {
  on_attach = function(client, bufnr)
    for _, c in ipairs(vim.lsp.get_clients()) do
      if c.name == "denols" or c.name == "volar" then
        vim.notify(c.name .. " is running, skipping ts_ls setup", vim.log.levels.WARN)
        client.stop()
        return
      end
    end
    nvlsp.on_attach(client, bufnr)
  end,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  root_dir = lspconfig.util.root_pattern "package.json",
  single_file_support = true,
}

lspconfig.phpactor.setup {
  root_dir = function(_)
    return vim.uv.cwd()
  end,
  on_init = nvlsp.on_init,
  on_attach = nvlsp.on_attach,
  capabilities = nvlsp.capabilities,
  init_options = {
    ["language_server.diagnostics_on_update"] = false,
    ["language_server.diagnostics_on_open"] = false,
    ["language_server.diagnostics_on_save"] = false,
    ["language_server_phpstan.enabled"] = false,
    ["language_server_psalm.enabled"] = false,
  },
}
