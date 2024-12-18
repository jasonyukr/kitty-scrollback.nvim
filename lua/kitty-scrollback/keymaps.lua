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

function CopyCurrentWordAndQuit()
  -- Get the cursor position (row, column)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  -- Get the line under the cursor
  local line = vim.api.nvim_get_current_line()
  -- Get the start and end of the current word using only whitespace delimiters
  local start_col, end_col = col, col
  -- Move start_col leftwards to find the first non-whitespace character
  while start_col > 1 and not line:sub(start_col-1, start_col-1):match("%s") do
    start_col = start_col - 1
  end
  -- Move end_col rightwards to find the first whitespace character
  while end_col <= #line and not line:sub(end_col, end_col):match("%s") do
    end_col = end_col + 1
  end
  -- Extract the word based on the columns
  local word = line:sub(start_col, end_col - 1)
  -- Copy the word to the system clipboard (requires clipboard support in Neovim)
  vim.fn.setreg('+', word)
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

  vim.api.nvim_set_keymap('n', '<c-c>', ':lua CopyCurrentWordAndQuit()<CR>', { noremap = true, silent = true })
  -- Ctrl-^ is bound to Ctrl-Enter in kitty config
  vim.api.nvim_set_keymap('n', '<c-^>', ':lua CopyCurrentWordAndQuit()<CR>', { noremap = true, silent = true })
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
