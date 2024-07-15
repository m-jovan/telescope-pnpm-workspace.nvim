local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local entry_display = require 'telescope.pickers.entry_display'
local conf = require('telescope.config').values
local pnpmw = require 'pnpm_workspace'

local function find_packages(opts)
  opts = opts or {}

  local projects = pnpmw.list_projects()

  if projects == nil or #projects == 0 then
    print 'No packages found. Make sure you are in a pnpm workspace'
    return
  end

  pickers
    .new(opts, {
      prompt_title = 'Find packages in pnpm workspace',
      finder = finders.new_table {
        results = projects,
        entry_maker = function(entry)
          return {
            value = entry.path,
            display = entry.name,
            ordinal = entry.path,
          }
        end,
      },
      sorter = conf.generic_sorter(opts),
      previewer = conf.file_previewer(opts),
    })
    :find()
end

local display = entry_display.create {
  separator = '  |  ',
  items = {
    { width = 20 },
    { remaining = true },
  },
}

local function get_entry_maker(opts)
  opts = opts or {}
  local projects = pnpmw.list_projects()

  if projects == nil or #projects == 0 or vim.fn.getcwd() ~= projects[1].path then
    return
  end

  return function(entry)
    local label, path

    for _, project in pairs(projects) do
      local project_workspace_path = project.path:sub(project.path:match '.*()/.*/' + 1)

      if vim.startswith(entry, project_workspace_path) then
        label = project.name
        path = entry:sub(#project_workspace_path + 2)
        break
      end
    end

    return {
      value = entry,
      display = opts.display or display {
        label or projects[1].name,
        path or entry,
      },
      ordinal = entry,
    }
  end
end

return require('telescope').register_extension {
  exports = {
    find_packages = find_packages,
    get_entry_maker = get_entry_maker,
  },
}
