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

## Usage

### Find packages

Find packages in the pnpm workspace and open the package directory. Names of the packages are shown per `package.json` name field.

Via command:

```VimL
:Telescope pnpm_workspace find_packages
```

Via keymap:

```lua
vim.keymap.set('n', '<leader>fp', function() require('telescope').extensions.pnpm_workspace.find_packages() end)
```

### Use custom entry maker

You can use the custom entry maker to customize the way search results are displayed. With a default entry maker, the search results are displayed as file path which is not very readable in a monorepo. The custom entry maker adds a label with the package name and the file path from the package root.

Telescope builtins as `find_files` and `live_grep` can be easily extended with the custom entry maker.

```lua
vim.keymap.set('n', '<leader>sf', function()
    local entry_maker = require('telescope').extensions.pnpm_workspace.get_entry_maker()
    require('telescope.builtin').find_files({
        entry_maker = entry_maker
    })
end)
```

Customize the display to your needs:

```lua
vim.keymap.set('n', '<leader>sf', function()
    local entry_display = require 'telescope.pickers.entry_display'

    local display = entry_display.create {
        separator = ' | ',        -- Separator between the lable and the file path
        items = {
            { width: 20 },        -- Label width (set to your needs per min/max package name length)
            { remaining = true }, -- File path width
        }
    }

    -- pass the display to the entry maker factory as opts
    local entry_maker = require('telescope').extensions.pnpm_workspace.get_entry_maker({display = display})

    require('telescope.builtin').find_files({
        entry_maker = entry_maker
    })
end)
```

In case entry maker cannot find packages or build the entry, it will fallback to the default entry maker.
