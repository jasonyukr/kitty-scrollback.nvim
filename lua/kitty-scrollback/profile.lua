---@mod kitty-scrollback.profile
local M = {}

local enabled = vim.env.KITTY_SCROLLBACK_NVIM_PROFILE == '1'
local uv = vim.uv or vim.loop
local state = {
  events = {},
  flushed = false,
}

local function encode_json(data)
  if vim.json and vim.json.encode then
    return vim.json.encode(data)
  end
  return vim.fn.json_encode(data)
end

local function mkdir_parent(path)
  local dir = vim.fn.fnamemodify(path, ':h')
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, 'p')
  end
end

---@param python_profile table|nil
M.setup = function(python_profile)
  if not enabled then
    return
  end
  state.start_ns = state.start_ns or uv.hrtime()
  if type(python_profile) == 'table' and type(python_profile.events) == 'table' then
    for _, event in ipairs(python_profile.events) do
      table.insert(state.events, event)
    end
  end
end

---@param event table
M.record = function(event)
  if not enabled then
    return
  end
  state.start_ns = state.start_ns or uv.hrtime()
  local item = vim.tbl_extend('force', {
    source = 'lua',
    at_ms = math.floor((uv.hrtime() - state.start_ns) / 1000) / 1000,
  }, event)
  table.insert(state.events, item)
end

---@param metadata table|nil
M.flush = function(metadata)
  if not enabled or state.flushed then
    return
  end
  state.flushed = true
  local path = vim.fn.stdpath('state') .. '/kitty-scrollback-profile.jsonl'
  local payload = vim.tbl_extend('force', metadata or {}, {
    timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    events = state.events,
  })
  mkdir_parent(path)
  local file = io.open(path, 'a')
  if file then
    file:write(encode_json(payload), '\n')
    file:close()
  end
end

return M
