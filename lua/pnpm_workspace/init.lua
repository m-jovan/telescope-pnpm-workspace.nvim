local function get_pnpm_config()
  local config_handle = io.popen 'pnpm config list --json'

  if config_handle == nil then
    return
  end

  local read_config = config_handle:read '*a'

  config_handle:close()
  return vim.fn.json_decode(read_config)
end

local function list_projects()
  local handle = io.popen 'pnpm list --recursive --json --depth -1'

  if handle == nil then
    return
  end

  local config = get_pnpm_config()

  -- pnpm list json output is different when shared-workspace-lockfile is set to false
  local not_swl = config ~= nil and config['shared-workspace-lockfile'] == false

  local output = handle:read '*a'

  local pattern = not_swl and '%b[]' or '%b{}'

  local projects = {}
  for block in output:gmatch(pattern) do
    local decoded = vim.fn.json_decode(block)
    local project = not_swl and decoded[1] or decoded

    table.insert(projects, project)
  end

  handle:close()

  return projects
end

local M = {}

M.list_projects = list_projects
M.get_pnpm_config = get_pnpm_config

return M
