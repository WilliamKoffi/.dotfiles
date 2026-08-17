-- Tree-sitter query compatibility shim for Neovim 0.12.
--
-- Neovim 0.11 deprecated and 0.12 removed the `all = false` option of
-- `vim.treesitter.query.add_predicate` / `add_directive`. Handlers now always
-- receive `match[capture_id]` as a *list* of TSNode; the legacy mode passed a
-- single TSNode.
--
-- nvim-treesitter's `master` branch (archived 2025-05-18) still registers its
-- predicates and directives with `{ force = true, all = false }` and indexes
-- `match[id]` as a bare node. On 0.12 that node is a table, so the first
-- `node:range()` / `node:type()` blows up with
--
--   vim/treesitter.lua:197: attempt to call method 'range' (a nil value)
--
-- surfacing from the async parse scheduler. Reproduced with a PHP heredoc,
-- whose `php_only/injections.scm` uses `(#downcase! @injection.language)`.
--
-- Rather than patch every call site, wrap the registration functions: when a
-- caller asks for the removed `all = false` semantics, hand its handler a
-- legacy single-node match. Any plugin still on the old contract is fixed.
--
-- Must be required before lazy.nvim loads plugins.

local query = require "vim.treesitter.query"

local function legacy(handler)
  return function(match, pattern, source, pred, metadata)
    local single = {}
    for id, nodes in pairs(match) do
      single[id] = nodes[1]
    end
    return handler(single, pattern, source, pred, metadata)
  end
end

local function wrap(name)
  local original = query[name]
  query[name] = function(pred_name, handler, opts)
    if type(opts) == "table" and opts.all == false then
      handler = legacy(handler)
      opts = { force = opts.force }
    end
    return original(pred_name, handler, opts)
  end
end

wrap "add_predicate"
wrap "add_directive"
