---@mod kitty-scrollback.keymaps
local ksb_api = require('kitty-scrollback.api')
local ksb_util = require('kitty-scrollback.util')
local plug = ksb_util.plug_mapping_names

---@type KsbPrivate
local p ---@diagnostic disable-line: unused-local

---@type KsbOpts
local opts ---@diagnostic disable-line: unused-local

local M = {}

local function set_default(modes, lhs, rhs, keymap_opts)
  for _, mode in pairs(modes) do
    if vim.fn.hasmapto(rhs, mode) == 0 then
      vim.keymap.set(mode, lhs, rhs, keymap_opts)
    end
  end
end

-- If current word is surrounded by single quote, return entire chunk.
-- Otherwise copy the current word based only on whitespace delimiters.
function CopyCurrentChunkOrWord()
  -- Get the cursor position (row, column)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  -- Get the line under the cursor
  local line = vim.api.nvim_get_current_line()

  col = col + 1
  local current_char = line:sub(col, col)

  -- Move backwards to find the previous single quote (opening quote)
  local prev_sq_col = col - 1
  while prev_sq_col > 0 do
    if line:sub(prev_sq_col, prev_sq_col) == "'" then
      break
    else
      prev_sq_col = prev_sq_col - 1
    end
  end
  if prev_sq_col == 0 then
    prev_sq_col = -1
  end

  -- Move forwards to find the next single quote (closing quote)
  local next_sq_col = col + 1
  while next_sq_col <= #line do
    if line:sub(next_sq_col, next_sq_col) == "'" then
      break
    else
      next_sq_col = next_sq_col + 1
    end
  end
  if next_sq_col > #line then
    next_sq_col = -1
  end

  if current_char == "'" then
    if prev_sq_col ~= -1 then
      -- 'xxx...yyy'^    where '^ is signle-quote current character
      local chunk = line:sub(prev_sq_col, col)
      vim.fn.setreg('+', chunk)
      return
    elseif next_sq_col ~= -1 then
      -- '^xxx...yyy'     where '^ is single-quote current character
      local chunk = line:sub(col, next_sq_col)
      vim.fn.setreg('+', chunk)
      return
    end
  else
    if prev_sq_col ~= -1 and next_sq_col ~= -1 then
      -- 'xxx...^...yyy'   where ^ is non-single-quote current character
      local chunk = line:sub(prev_sq_col, next_sq_col)
      vim.fn.setreg('+', chunk)
      return
    end
  end

  ---------------------------------------------------
  -- Single quote NOT found in this line.
  -- Fall back to word selection based on whitespace.
  ---------------------------------------------------

  if current_char:match("%s") then
    vim.fn.setreg('+', " ")
    return
  end

  -- Move backwards to find the previous white-space
  local prev_ws_col = col - 1
  while prev_ws_col > 0 do
    if not line:sub(prev_ws_col, prev_ws_col):match("%s") then
      prev_ws_col = prev_ws_col - 1
    else
      break
    end
  end
  if prev_ws_col == 0 then
    prev_ws_col = -1
  end

  -- Move forwards to find the next white-space
  local next_ws_col = col + 1
  while next_ws_col <= #line do
    if not line:sub(next_ws_col, next_ws_col):match("%s") then
      next_ws_col = next_ws_col + 1
    else
      break
    end
  end
  if next_ws_col > #line then
    next_ws_col = -1
  end

  if prev_ws_col ~= -1 then
    if next_ws_col ~= -1 then
      -- 000 xxx^yyy 111   where ^ is non-single-quote current character
      local word = line:sub(prev_ws_col + 1, next_ws_col - 1)
      vim.fn.setreg('+', word)
    else
      -- 000 xxx^yyy|      where | is end of line
      local word = line:sub(prev_ws_col + 1)
      vim.fn.setreg('+', word)
    end
  else
    if next_ws_col ~= -1 then
      -- |xxx^yyy 111      where | is start of line
      local word = line:sub(1, next_ws_col - 1)
      vim.fn.setreg('+', word)
    else
      -- |xxx^yyy|         where | is start/end of line
      local word = line:sub(1)
      vim.fn.setreg('+', word)
    end
  end
end

function CopyCurrentChunkOrWordAndQuit()
  CopyCurrentChunkOrWord()
  -- Quit nvim
  ksb_util.quitall()
end

local function set_global_defaults()
  set_default({ 'v' }, '<leader>Y', plug.VISUAL_YANK_LINE, {})
  set_default({ 'v' }, '<leader>y', plug.VISUAL_YANK, {})
  set_default({ 'n' }, '<leader>Y', plug.NORMAL_YANK_END, {})
  set_default({ 'n' }, '<leader>y', plug.NORMAL_YANK, {})
  set_default({ 'n' }, '<leader>yy', plug.YANK_LINE, {})

  set_default({ 'n' }, 'q', plug.CLOSE_OR_QUIT_ALL, {})
  -- set_default({ 'n', 't', 'i' }, '<c-c>', plug.QUIT_ALL, {})

  -- set_default({ 'v' }, '<c-cr>', plug.EXECUTE_VISUAL_CMD, {})
  set_default({ 'v' }, '<s-cr>', plug.PASTE_VISUAL_CMD, {})

  vim.api.nvim_set_keymap('n', '<c-c>', ':lua CopyCurrentChunkOrWordAndQuit()<CR>', { noremap = true, silent = true })
  -- Ctrl-^ is bound to Ctrl-Enter in kitty config
  vim.api.nvim_set_keymap('n', '<c-^>', ':lua CopyCurrentChunkOrWordAndQuit()<CR>', { noremap = true, silent = true })
end

local function set_local_defaults()
  set_default({ '' }, 'g?', plug.TOGGLE_FOOTER, {})
  -- set_default({ 'n', 'i' }, '<c-cr>', plug.EXECUTE_CMD, {})
  set_default({ 'n', 'i' }, '<s-cr>', plug.PASTE_CMD, {})
end

M.setup = function(private, options)
  p = private ---@diagnostic disable-line: unused-local
  opts = options

  if opts.keymaps_enabled then
    vim.keymap.set(
      { 'n' },
      plug.CLOSE_OR_QUIT_ALL,
      vim.schedule_wrap(ksb_api.close_or_quit_all),
      {}
    )
    vim.keymap.set({ 'n', 't', 'i' }, plug.QUIT_ALL, ksb_api.quit_all, {})

    vim.keymap.set({ 'v' }, plug.YANK_LINE, '"+Y', {})
    vim.keymap.set({ 'v' }, plug.VISUAL_YANK, '"+y', {})
    vim.keymap.set({ 'v' }, plug.EXECUTE_VISUAL_CMD, ksb_api.execute_visual_command, {})
    vim.keymap.set({ 'v' }, plug.PASTE_VISUAL_CMD, ksb_api.paste_visual_command, {})
    vim.keymap.set({ 'n' }, plug.NORMAL_YANK_END, '"+y$', {})
    vim.keymap.set({ 'n' }, plug.NORMAL_YANK, '"+y', {})
    vim.keymap.set({ 'n' }, plug.YANK_LINE, '"+yy', {})

    set_global_defaults()
  end
end

M.set_buffer_local_keymaps = function(bufid)
  if not opts.keymaps_enabled then
    return
  end
  bufid = bufid or true

  if opts.keymaps_enabled then
    set_local_defaults()
    vim.keymap.set({ 'n', 'i' }, plug.EXECUTE_CMD, ksb_api.execute_command, { buffer = bufid })
    vim.keymap.set({ 'n', 'i' }, plug.PASTE_CMD, ksb_api.paste_command, { buffer = bufid })
    vim.keymap.set({ '' }, plug.TOGGLE_FOOTER, ksb_api.toggle_footer, { buffer = bufid })
  end
end

return M
