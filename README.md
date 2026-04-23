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
| `e?` | `é` | e with acute |
| `>>` | `»` | right-pointing double angle quotation mark |
| `Co` | `©` | copyright sign |
| `=Y` | `¥` | yen sign |
| `*a` | `α` | greek small letter alpha |
| `->` | `→` | rightwards arrow |
| `<=` | `≤` | less-than or equal to |
| `+-` | `±` | plus-minus sign |
| `So` | `☺` | white smiling face |

Run `:digraphs` to see the full table built into Neovim.

## Requirements

Neovim with `digraph_getlist()` (introduced in 0.10).

## Installation

### lazy.nvim

```lua
{
  "saghen/blink.cmp",
  dependencies = { "delphinus/blink-cmp-digraphs" },
  opts = {
    sources = {
      default = { "digraphs", "lsp", "path", "snippets", "buffer" },
      providers = {
        digraphs = {
          name = "Digraphs",
          module = "blink-cmp-digraphs",
          min_keyword_length = 1,
        },
      },
    },
  },
}
```

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
    min_keyword_length = 1,
    opts = {
      filter = function(item)
        return item.charnr >= 0x20 and item.charnr <= 0xFFFF
      end,
    },
  },
}
```

## License

MIT
