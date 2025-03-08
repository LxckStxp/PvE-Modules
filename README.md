Below is the `README.md` in plaintext with GitHub Markdown formatting preserved, ready for you to copy and paste directly into your GitHub repository. It’s the same content as before, just presented without the code block wrapper so you can grab it easily.

---

# PvE System

A simple PvE cheat for Roblox games.

## Loadstring

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/PvE-Modules/main/PVESystem/main.lua"))()
```

## Features

- **NPC ESP**: Highlights enemies in red.
- **Aimbot**: Locks onto visible NPCs with right-click (skips walls, switches if target dies).
- **Item ESP**: Middle-click to toggle tracking on small models/parts (≤10 studs).
- **UI**: Toggle ESP, aimbot, item tracking, and set max distance.

## Usage

1. Inject the loadstring using a Roblox executor.
2. Controls:
   - **Right-Click**: Aimbot on nearest visible NPC.
   - **Middle-Click**: Toggle ESP on/off for a model/part.
3. Open the UI to toggle features or adjust distance (100-2000 studs).

## Notes

- Aimbot avoids walls and auto-switches targets.
- Item ESP tracks only the exact object clicked (if small enough).
- Works in most PvE Roblox games.

## Disclaimer

For educational use only. Respect Roblox's Terms of Service.
