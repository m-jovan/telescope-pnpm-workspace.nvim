local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local entry_display = require 'telescope.pickers.entry_display'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local builtin = require 'telescope.builtin'
local pnpmw = require 'pnpm_workspace'

local function find_packages(opts)
  opts = opts or {}

  local projects = pnpmw.list_projects()

  if projects == nil or #projects == 0 then
    vim.notify('telescope-pnpm-workspace: no packages found', vim.log.levels.WARN)
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
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          builtin.find_files { cwd = selection.value }
        end)
        return true
      end,
    })
    :find()
end

local function make_display(projects)
  local max_width = 0
  for _, p in ipairs(projects) do
    if #p.name > max_width then
      max_width = #p.name
    end
  end
  return entry_display.create {
    separator = '  |  ',
    items = {
      { width = max_width },
      { remaining = true },
    },
  }
end

local function get_entry_maker(opts)
  opts = opts or {}

  if not pnpmw.is_pnpm_workspace() then
    return
  end

  local projects = pnpmw.list_projects()

  if projects == nil or #projects == 0 then
    return
  end

  local display = opts.display or make_display(projects)

  return function(entry)
    local label, path

    for _, project in pairs(projects) do
      local match_pos = project.path:match '.*()/.*/';
      if match_pos then
        local project_workspace_path = project.path:sub(match_pos + 1)
        if vim.startswith(entry, project_workspace_path) then
          label = project.name
          path = entry:sub(#project_workspace_path + 2)
          break
        end
      end
    end

    return {
      value = entry,
      display = display {
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
