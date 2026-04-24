--- @class BlinkCmpDigraphs.FilterItem
--- @field digraph string
--- @field char string
--- @field charnr integer

--- @class BlinkCmpDigraphs.Options
--- @field filter? fun(item: BlinkCmpDigraphs.FilterItem): boolean

local M = {}

--- @type BlinkCmpDigraphs.Options
local default_opts = {
  filter = function(item)
    return item.charnr >= 0x20
  end,
}

--- @class BlinkCmpDigraphs.RawItem
--- @field digraph string
--- @field char string
--- @field charnr integer
--- @field label string
--- @field detail string

--- @param filter fun(item: BlinkCmpDigraphs.FilterItem): boolean
--- @return BlinkCmpDigraphs.RawItem[], string[]
local function build_items(filter)
  local items = {}
  local first_chars_seen = {}
  local first_chars = {}
  local view = { digraph = "", char = "", charnr = 0 }
  for _, pair in ipairs(vim.fn.digraph_getlist(true)) do
    local digraph, char = pair[1], pair[2]
    local charnr = vim.fn.char2nr(char)
    view.digraph, view.char, view.charnr = digraph, char, charnr
    if filter(view) then
      table.insert(items, {
        digraph = digraph,
        char = char,
        charnr = charnr,
        label = digraph .. " " .. vim.fn.strtrans(char),
        detail = ("U+%04X"):format(charnr),
      })
      local first = digraph:sub(1, 1)
      if not first_chars_seen[first] then
        first_chars_seen[first] = true
        table.insert(first_chars, first)
      end
    end
  end
  return items, first_chars
end

--- @param opts? BlinkCmpDigraphs.Options
function M.new(opts)
  opts = vim.tbl_deep_extend("keep", opts or {}, default_opts)
  vim.validate { filter = { opts.filter, "function" } }
  local self = setmetatable({}, { __index = M })
  self.items, self.trigger_characters = build_items(opts.filter)
  return self
end

--- @return boolean
function M:enabled()
  return vim.fn.exists "*digraph_getlist" == 1
end

--- @return string[]
function M:get_trigger_characters()
  return self.trigger_characters
end

--- @param ctx blink.cmp.Context
--- @param callback fun(response?: blink.cmp.CompletionResponse): nil
--- @return fun(): nil cancel
function M:get_completions(ctx, callback)
  local col = ctx.cursor[2]
  -- Read up to 2 characters before the cursor. Digraphs are exactly 2
  -- characters, so this is the prefix to filter against.
  local prefix = ctx.line:sub(math.max(1, col - 1), col)
  -- Suppress when the prefix is the tail of a longer identifier (e.g. typing
  -- `vim.` should not surface the `m.` digraph). Only fire when the char
  -- immediately before the prefix is whitespace, a separator, or start of
  -- line.
  local before_col = col - #prefix
  local before = before_col > 0 and ctx.line:sub(before_col, before_col) or ""
  if prefix == "" or before:match "[%w_]" then
    callback {
      is_incomplete_forward = false,
      is_incomplete_backward = false,
      items = {},
    }
    return function() end
  end

  local row = ctx.cursor[1] - 1
  local edit_range = {
    start = { line = row, character = math.max(0, col - #prefix) },
    ["end"] = { line = row, character = col },
  }

  local matches = {}
  for _, raw in ipairs(self.items) do
    if raw.digraph:sub(1, #prefix) == prefix then
      table.insert(matches, {
        label = raw.label,
        labelDetails = { detail = raw.detail },
        filterText = raw.digraph,
        textEdit = { range = edit_range, newText = raw.char },
      })
    end
  end

  callback {
    -- Re-query on every keystroke so the prefix recomputes.
    is_incomplete_forward = true,
    is_incomplete_backward = true,
    items = matches,
  }
  return function() end
end

return M
