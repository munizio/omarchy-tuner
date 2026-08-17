-- Ctrl+F opens the sessionizer. Inside tmux / herdr, the multiplexer
-- root C-f bind usually fires first; this is the fallback outside both.
vim.keymap.set("n", "<C-f>", function()
  if vim.env.TMUX or vim.env.HERDR_ENV == "1" then
    vim.fn.jobstart({ "sessionizer" }, { detach = true })
  else
    vim.cmd("silent !sessionizer")
    vim.cmd("redraw!")
  end
end, { desc = "Sessionizer", silent = true })

return {}
