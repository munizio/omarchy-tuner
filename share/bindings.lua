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
-- Adjacent IDs, no wrap. One empty workspace past the occupied range is allowed.
-- mouse:276 is the other side button. Consumes the click (no browser back).
local workspace_flick = { origin = nil, min = 50 }

local function occupied_workspace_range()
  local min_id, max_id
  for _, ws in ipairs(hl.get_workspaces()) do
    if not ws.special and not ws.is_empty then
      if not min_id or ws.id < min_id then
        min_id = ws.id
      end
      if not max_id or ws.id > max_id then
        max_id = ws.id
      end
    end
  end
  return min_id, max_id
end

local function flick_workspace(delta)
  local ws = hl.get_active_workspace()
  if not ws or ws.special or not ws.id then
    return
  end
  local target = ws.id + delta
  if target < 1 then
    return
  end
  local min_occ, max_occ = occupied_workspace_range()
  if min_occ then
    if target < min_occ - 1 or target > max_occ + 1 then
      return
    end
  elseif target ~= 1 then
    return
  end
  hl.dispatch(hl.dsp.focus({ workspace = tostring(target) }))
end

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
    flick_workspace(-1)
  else
    flick_workspace(1)
  end
end, { release = true })
-- omarchy-tuner:end
