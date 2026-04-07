local _projects_cache = nil

vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = 'package.json',
  callback = function()
    _projects_cache = nil
  end,
  group = vim.api.nvim_create_augroup('PnpmWorkspaceCache', { clear = true }),
})

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
  if _projects_cache then
    return _projects_cache
  end

  if vim.fn.executable 'pnpm' == 0 then
    vim.notify('telescope-pnpm-workspace: pnpm not found in PATH', vim.log.levels.ERROR)
    return
  end

  local handle = io.popen 'pnpm list --recursive --json --depth -1'

  if handle == nil then
    vim.notify('telescope-pnpm-workspace: failed to run pnpm list', vim.log.levels.ERROR)
    return
  end

  local config = get_pnpm_config()

  -- pnpm list json output is different when shared-workspace-lockfile is set to false
  local not_swl = config ~= nil and config['shared-workspace-lockfile'] == false

  local output = handle:read '*a'

  handle:close()

  local pattern = not_swl and '%b[]' or '%b{}'

  local projects = {}
  for block in output:gmatch(pattern) do
    local decoded = vim.fn.json_decode(block)
    local project = not_swl and decoded[1] or decoded

    table.insert(projects, project)
  end

  _projects_cache = projects
  return projects
end

local function is_pnpm_workspace()
  local path = vim.fn.getcwd()
  while path ~= '/' do
    if
      vim.fn.filereadable(path .. '/pnpm-workspace.yaml') == 1
      or vim.fn.filereadable(path .. '/pnpm-workspace.yml') == 1
    then
      return true
    end
    path = vim.fn.fnamemodify(path, ':h')
  end
  return false
end

local M = {}

M.list_projects = list_projects
M.get_pnpm_config = get_pnpm_config
M.is_pnpm_workspace = is_pnpm_workspace

return M
