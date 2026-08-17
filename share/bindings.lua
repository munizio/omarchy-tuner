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
-- omarchy-tuner:end
