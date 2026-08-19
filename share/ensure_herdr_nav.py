#!/usr/bin/env python3
# Rewrite a herdr config.toml [keys] table: workspace next/prev on
# prefix+j / prefix+k, and drop those chords (plus the shifted forms)
# from every other action. Omarchy's close_tab is prefix+k; restore
# herdr's prefix+shift+x. Omarchy's close_workspace is prefix+shift+k;
# restore herdr's prefix+shift+d.
import os
import pathlib
import re
import sys
import tomllib

path = pathlib.Path(sys.argv[1])
check = os.environ.get("CHECK") == "1"

wanted = {
    "next_workspace": ["prefix+j", "alt+down"],
    "previous_workspace": ["prefix+k", "alt+up"],
}
chords = {"prefix+j", "prefix+k", "prefix+shift+j", "prefix+shift+k"}
fallbacks = {
    "close_tab": "prefix+shift+x",
    "close_workspace": "prefix+shift+d",
}

table_re = re.compile(r"^\[keys\]\s*(#.*)?$")
other_re = re.compile(r"^\[")
assign_re = re.compile(r"^(\s*)([A-Za-z0-9_]+)\s*=\s*(.*)$")


def parse_rhs(rhs: str):
    try:
        return tomllib.loads("v = " + rhs)["v"]
    except tomllib.TOMLDecodeError:
        return object()


def dump_rhs(val) -> str:
    if isinstance(val, str):
        return f'"{val}"'
    if isinstance(val, list):
        inner = ", ".join(f'"{x}"' for x in val)
        return f"[{inner}]"
    raise TypeError(val)


def drop_chords(val):
    if isinstance(val, str):
        return "" if val in chords else val
    if isinstance(val, list):
        kept = [x for x in val if x not in chords]
        if not kept:
            return ""
        if len(kept) == 1:
            return kept[0]
        return kept
    return val


if path.is_file():
    text = path.read_text()
    newline = "\n" if "\r\n" not in text else "\r\n"
    lines = text.splitlines()
else:
    newline = "\n"
    lines = []

in_table = False
found_table = False
seen = set()
action = "ok"
out = []


def insert_wanted() -> None:
    global action
    for key, val in wanted.items():
        if key not in seen:
            out.append(f"{key} = {dump_rhs(val)}")
            seen.add(key)
            if action == "ok":
                action = "added"


for line in lines:
    if table_re.match(line):
        in_table = True
        found_table = True
        out.append(line)
        continue
    if in_table and other_re.match(line):
        blanks = []
        while out and out[-1] == "":
            blanks.append(out.pop())
        insert_wanted()
        out.extend(reversed(blanks))
        in_table = False
    m = assign_re.match(line) if in_table else None
    if m:
        indent, key, rhs = m.group(1), m.group(2), m.group(3)
        val = parse_rhs(rhs)
        if key in wanted:
            seen.add(key)
            if val == wanted[key]:
                out.append(line)
            else:
                out.append(f"{indent}{key} = {dump_rhs(wanted[key])}")
                action = "updated"
            continue
        new = drop_chords(val)
        if new != val:
            if new == "" and key in fallbacks:
                new = fallbacks[key]
            out.append(f"{indent}{key} = {dump_rhs(new)}")
            action = "updated"
            continue
    out.append(line)

if found_table:
    insert_wanted()
else:
    if out and out[-1] != "":
        out.append("")
    out.append("[keys]")
    insert_wanted()

if action == "ok":
    print("ok")
    raise SystemExit(0)

if check:
    print("missing" if action == "added" else "stale")
    raise SystemExit(0)

path.parent.mkdir(parents=True, exist_ok=True)
body = newline.join(out)
if not body.endswith(newline):
    body += newline
path.write_text(body)
print(action)
