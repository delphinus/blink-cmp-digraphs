# blink-cmp-digraphs

A [blink.cmp](https://github.com/Saghen/blink.cmp) source for Vim digraphs.

When you type two characters in insert mode, this source suggests the
corresponding [digraph](https://neovim.io/doc/user/digraph.html) — a special
character such as `œ`, `é`, `»`, `→`, `≤`, `±`, `α`, `©`, `¥`, `☺`, etc.
Inspired by [dmitmel/cmp-digraphs](https://github.com/dmitmel/cmp-digraphs)
but rewritten as a native blink.cmp source with no nvim-cmp dependency and no
legacy fallbacks (modern Neovim only).

## Examples

| type | inserts | name |
|------|:-------:|------|
| `oe` | `œ` | latin small ligature oe |
| `e'` | `é` | e with acute |
| `>>` | `»` | right-pointing double angle quotation mark |
| `Co` | `©` | copyright sign |
| `Ye` | `¥` | yen sign |
| `=e` | `€` | euro sign |
| `*a` | `α` | greek small letter alpha |
| `->` | `→` | rightwards arrow |
| `=<` | `≤` | less-than or equal to |
| `+-` | `±` | plus-minus sign |
| `0u` | `☺` | white smiling face |

Run `:digraphs` to see the full table built into Neovim.

## Requirements

Neovim with `digraph_getlist()` (introduced in 0.10).

## Installation

### lazy.nvim

```lua
{
  "saghen/blink.cmp",
  dependencies = {
    { "delphinus/blink-cmp-digraphs", version = "*" },
  },
  opts = {
    sources = {
      default = { "digraphs", "lsp", "path", "snippets", "buffer" },
      providers = {
        digraphs = {
          name = "Digraphs",
          module = "blink-cmp-digraphs",
          -- Required so the source fires for digraphs whose first character
          -- is non-keyword, e.g. `->` or `+-`. blink.cmp's keyword bound stays
          -- at length 0 in those cases, so `min_keyword_length = 1` would
          -- cause the provider to be skipped entirely.
          min_keyword_length = 0,
          -- Recommended so digraph candidates rank above LSP/buffer matches
          -- when both characters are keyword chars (e.g. `Ye`, `oe`, `Co`).
          score_offset = 50,
        },
      },
    },
  },
}
```

## Required provider settings

These two settings together make the source behave correctly across all
digraph shapes:

### `min_keyword_length = 0`

blink.cmp computes a keyword-text bound around the cursor and refuses to call
a provider whose `min_keyword_length` exceeds the current bound length. For
digraphs whose **both** characters are non-keyword (e.g. `->`, `+-`, `<<`),
the bound never grows past length 0 — it would be skipped if
`min_keyword_length >= 1`.

This source registers every digraph first character as a trigger character
and pre-filters items by the up-to-two characters before the cursor, so
invoking the provider with an empty bound is safe; we read the prefix from
the line ourselves.

### `score_offset = 50`

When both characters of a digraph are keyword chars (e.g. `Ye` for `¥`,
`oe` for `œ`, `Co` for `©`), the typed prefix also matches many LSP and
buffer items. Without a score offset, those matches dominate the menu and
the digraph candidate is pushed below the visible cutoff.

`50` is a starting point — adjust to taste against your other providers'
offsets.

## Options

| key | type | default | description |
|-----|------|---------|-------------|
| `filter` | `fun(item) -> boolean` | `function(item) return item.charnr >= 0x20 end` | Predicate to keep an item. `item` has `digraph` (string), `char` (string), `charnr` (integer codepoint). The default hides control characters. |

Example — keep only the digraphs whose codepoint is in the BMP:

```lua
providers = {
  digraphs = {
    name = "Digraphs",
    module = "blink-cmp-digraphs",
    min_keyword_length = 0,
    score_offset = 50,
    opts = {
      filter = function(item)
        return item.charnr >= 0x20 and item.charnr <= 0xFFFF
      end,
    },
  },
}
```

## How it works

On creation the source enumerates `vim.fn.digraph_getlist(true)` once and
collects:

- The completion items themselves (label, filterText, insertText, etc.).
- The set of unique first characters of every digraph (~80 chars), exposed
  via `get_trigger_characters()` so non-keyword openers fire the provider.

On every invocation `get_completions` reads up to two characters before the
cursor, filters the items to those whose digraph starts with that prefix,
and returns each match with `textEdit.range` spanning the matched prefix.
`is_incomplete_forward` and `is_incomplete_backward` are set so blink.cmp
re-queries on every keystroke, recomputing the prefix.

## License

MIT
