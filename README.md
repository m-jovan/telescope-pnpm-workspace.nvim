# telescope-pnpm-workspace.nvim

Neovim telescope extension for easier traversing through pnpm workspace by either searching for packages or having a more readable file search.

## Installation

Install the plugin with your preferred package manager:

**Lazy**

```lua
{
    'm-jovan/telescope-pnpm-workspace.nvim'
}
```

**Packer**

```lua
use 'm-jovan/telescope-pnpm-workspace.nvim'
```

## Setup

After telescope setup (`require('telescope').setup()`) load the extension with:

```lua
require('telescope').load_extension('pnpm_workspace')
```

### Configuration

Options can be set under the `pnpm_workspace` key in `telescope.setup`:

```lua
require('telescope').setup {
  extensions = {
    pnpm_workspace = {
      separator  = '  |  ',  -- separator between label and file path
      label_width = nil,     -- fixed label column width; nil = auto (longest package name)
      exclude = {},          -- lua patterns matched against package name or path
    }
  }
}
```

**`exclude` examples:**

```lua
exclude = { '^private%-', 'apps/mobile' }
```

## Usage

### Find packages

Browse all packages in the workspace. Selecting a package opens `find_files` scoped to that package.

Via command:

```VimL
:Telescope pnpm_workspace find_packages
```

Via keymap:

```lua
vim.keymap.set('n', '<leader>fp', function()
  require('telescope').extensions.pnpm_workspace.find_packages()
end)
```

### Use custom entry maker

Makes `find_files` and `live_grep` display results as `[package-name] | path/from/package/root` instead of full file paths — much more readable in a monorepo.

```lua
vim.keymap.set('n', '<leader>sf', function()
  local entry_maker = require('telescope').extensions.pnpm_workspace.get_entry_maker()
  require('telescope.builtin').find_files({ entry_maker = entry_maker })
end)
```

To override the display for a specific keymap, pass a custom `entry_display`:

```lua
vim.keymap.set('n', '<leader>sf', function()
  local entry_display = require 'telescope.pickers.entry_display'

  local display = entry_display.create {
    separator = ' | ',
    items = {
      { width = 20 },        -- fixed label width
      { remaining = true },
    }
  }

  local entry_maker = require('telescope').extensions.pnpm_workspace.get_entry_maker({ display = display })
  require('telescope.builtin').find_files({ entry_maker = entry_maker })
end)
```

`get_entry_maker` returns `nil` when called outside a pnpm workspace, causing Telescope to fall back to its default entry maker automatically.
