local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local entry_display = require 'telescope.pickers.entry_display'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local builtin = require 'telescope.builtin'
local pnpmw = require 'pnpm_workspace'

local ext_config = {
  separator = '  |  ',
  label_width = nil, -- auto-computed from package names when nil
  exclude = {}, -- list of lua patterns matched against package name or path
}

local function filter_projects(projects)
  if not ext_config.exclude or #ext_config.exclude == 0 then
    return projects
  end
  local filtered = {}
  for _, p in ipairs(projects) do
    local excluded = false
    for _, pattern in ipairs(ext_config.exclude) do
      if p.name:match(pattern) or p.path:match(pattern) then
        excluded = true
        break
      end
    end
    if not excluded then
      table.insert(filtered, p)
    end
  end
  return filtered
end

local function find_packages(opts)
  opts = opts or {}

  local projects = pnpmw.list_projects()

  if projects == nil or #projects == 0 then
    vim.notify('telescope-pnpm-workspace: no packages found', vim.log.levels.WARN)
    return
  end

  projects = filter_projects(projects)

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
    separator = ext_config.separator,
    items = {
      { width = ext_config.label_width or max_width },
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

  projects = filter_projects(projects)
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
  setup = function(user_config)
    ext_config = vim.tbl_deep_extend('force', ext_config, user_config or {})
  end,
  exports = {
    find_packages = find_packages,
    get_entry_maker = get_entry_maker,
  },
}
