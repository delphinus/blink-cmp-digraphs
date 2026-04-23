--- @class blink-cmp-digraphs.FilterItem
--- @field digraph string
--- @field char string
--- @field charnr integer

--- @class blink-cmp-digraphs.Options
--- @field filter? fun(item: blink-cmp-digraphs.FilterItem): boolean

local M = {}

--- @type blink-cmp-digraphs.Options
local default_opts = {
  filter = function(item)
    return item.charnr >= 0x20
  end,
}

--- @param filter fun(item: blink-cmp-digraphs.FilterItem): boolean
--- @return blink.cmp.CompletionItem[]
local function build_items(filter)
  local items = {}
  -- Reuse one table to avoid creating garbage on every iteration.
  local view = { digraph = "", char = "", charnr = 0 }
  for _, pair in ipairs(vim.fn.digraph_getlist(true)) do
    local digraph, char = pair[1], pair[2]
    local charnr = vim.fn.char2nr(char)
    view.digraph, view.char, view.charnr = digraph, char, charnr
    if filter(view) then
      table.insert(items, {
        label = digraph .. " " .. vim.fn.strtrans(char),
        labelDetails = { detail = ("U+%04X"):format(charnr) },
        filterText = digraph,
        insertText = char,
      })
    end
  end
  return items
end

--- @param opts? blink-cmp-digraphs.Options
--- @return blink-cmp-digraphs.Source
function M.new(opts)
  opts = vim.tbl_deep_extend("keep", opts or {}, default_opts)
  vim.validate { filter = { opts.filter, "function" } }
  local self = setmetatable({}, { __index = M })
  self.items = build_items(opts.filter)
  return self
end

--- @return boolean
function M:enabled()
  return vim.fn.exists "*digraph_getlist" == 1
end

--- @param _ blink.cmp.Context
--- @param callback fun(response?: blink.cmp.CompletionResponse): nil
--- @return fun(): nil cancel
function M:get_completions(_, callback)
  callback {
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    -- Deepcopy because blink.cmp may mutate items.
    items = vim.deepcopy(self.items),
  }
  return function() end
end

return M
