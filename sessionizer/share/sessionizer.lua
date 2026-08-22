-- Ctrl+F opens the sessionizer. Inside tmux, the multiplexer root C-f
-- bind usually fires first; this is the fallback outside tmux.
vim.keymap.set("n", "<C-f>", function()
  if vim.env.TMUX then
    vim.fn.jobstart({ "sessionizer" }, { detach = true })
  else
    vim.cmd("silent !sessionizer")
    vim.cmd("redraw!")
  end
end, { desc = "Sessionizer", silent = true })

return {}
