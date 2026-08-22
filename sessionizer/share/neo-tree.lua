-- Wipe the leftover [No Name] buffer Neo-tree creates when nvim starts on a
-- directory (`nvim .`, which sessionizer sends). Opening a file uses bufadd
-- rather than :edit, so the empty buffer stays listed and bufferline shows it.
-- optional = true: do not install neo-tree; only attach if the extra is already on.
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    optional = true,
    opts = {
      event_handlers = {
        {
          event = "file_opened",
          handler = function()
            vim.schedule(function()
              for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if
                  vim.api.nvim_buf_is_valid(buf)
                  and vim.bo[buf].buflisted
                  and vim.api.nvim_buf_get_name(buf) == ""
                  and vim.bo[buf].buftype == ""
                  and not vim.bo[buf].modified
                then
                  vim.api.nvim_buf_delete(buf, { force = true })
                end
              end
            end)
          end,
        },
      },
    },
  },
}
