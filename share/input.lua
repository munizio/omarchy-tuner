-- omarchy-tuner:begin
-- Caps Lock as Ctrl (replaces Omarchy compose:caps).
-- Pointer: natural scroll, disable touchpad while typing, two-finger
-- click for right-click, no tap-to-click.
hl.config({
  input = {
    kb_options = "ctrl:nocaps",
    natural_scroll = true,
    touchpad = {
      natural_scroll = true,
      disable_while_typing = true,
      clickfinger_behavior = true,
      tap_to_click = false,
    },
  },
})
-- omarchy-tuner:end
