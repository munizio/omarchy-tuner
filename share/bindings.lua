-- omarchy-tuner:begin
-- Note: SUPER+ALT+RETURN was previously bound to Tmux (omarchy-launch-terminal-tmux).
hl.unbind("SUPER + ALT + RETURN")
o.bind("SUPER + ALT + RETURN", "Sessionizer", "omarchy-launch-tui --app-id=org.omarchy.sessionizer sessionizer")

-- Workspace navigation without Super. Super+number / Super+Tab stay as-is.
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind("CTRL + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
end
o.bind("CTRL + H", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("CTRL + L", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))

-- Side button (BTN_SIDE / mouse:275) + horizontal flick → workspace.
-- mouse:276 is the other side button. Consumes the click (no browser back).
local workspace_flick = { origin = nil, min = 50 }
o.bind("mouse:275", nil, function()
  workspace_flick.origin = hl.get_cursor_pos()
end)
o.bind("mouse:275", "Flick workspace", function()
  local origin, pos = workspace_flick.origin, hl.get_cursor_pos()
  workspace_flick.origin = nil
  if not origin or not pos then
    return
  end
  local dx, dy = pos.x - origin.x, pos.y - origin.y
  if math.abs(dx) < workspace_flick.min or math.abs(dx) < math.abs(dy) then
    return
  end
  if dx > 0 then
    hl.dispatch(hl.dsp.focus({ workspace = "e-1" }))
  else
    hl.dispatch(hl.dsp.focus({ workspace = "e+1" }))
  end
end, { release = true })
-- omarchy-tuner:end
