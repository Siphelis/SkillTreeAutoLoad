# 🌳 SkillTreeAutoLoad

**Restore your Skill Tree in a single click.**

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a-00A2FF?style=flat-square)
![Server Ebonhold](https://img.shields.io/badge/Server-Ebonhold-6E44FF?style=flat-square)
![Lua](https://img.shields.io/badge/Lua-100%25-2C2D72?style=flat-square&logo=lua&logoColor=white)
[![Latest release](https://img.shields.io/github/v/release/Siphelis/SkillTreeAutoLoad?style=flat-square&color=40C463&label=release)](https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest)
[![License](https://img.shields.io/badge/License-PolyForm%20Strict%201.0.0-E5534B?style=flat-square)](LICENSE.md)

Every run makes you stronger, but the Skill Tree still has to be rebuilt. SkillTreeAutoLoad
remembers it exactly as it stands. Once you have enough Soul Ashes, a single click puts every
node back in place. Spend your time playing, not repeating the same clicks.

**English** | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Table of Contents

- [🔥 Why this addon](#-why-this-addon)
- [✨ Features](#-features)
- [📋 Requirements](#-requirements)
- [💾 Installation](#-installation)
- [🚀 Quick start](#-quick-start)
- [🧭 The panel](#-the-panel)
- [👁 Previewing a save](#-previewing-a-save)
- [🔄 Activating a save](#-activating-a-save)
- [📂 Your saves](#-your-saves)
- [💡 Good to know](#-good-to-know)
- [🧱 Code anatomy](#-code-anatomy)
- [🌍 Languages](#-languages)
- [📜 License](#-license)
- [🙏 Credits](#-credits)

---

## 🔥 Why this addon

Rebuilding the Skill Tree by hand means finding hundreds of nodes and selecting them one by
one without choosing the wrong rank. It is repetitive work that keeps you away from the game.

SkillTreeAutoLoad saves the tree once you are happy with it and restores that configuration
whenever you need it, including every node and rank.

## ✨ Features

| | |
|---|---|
| 💾 | **Save the tree exactly as it stands** — create as many named saves as you need |
| 🖱 | **Restore any save with one click** — every node is selected at the correct rank |
| ⚡ | **Choose full or progressive activation for each save** — wait for the full cost or spend what you can now |
| 👁 | **Preview a save directly on the tree** — missing nodes are highlighted and framed on hover |
| 📊 | **Track progress at a glance** — each row fills according to the Soul Ashes already invested |
| 📁 | **Organize saves into groups** — rename, move, or delete them whenever you like |
| 💰 | **Track the Soul Ashes cost in real time** — hover to see the exact amount missing |
| 🪟 | **Use a compact, collapsible panel** — place it inside the Skill Tree or beside the window |
| 👥 | **Use your saves across the account** — every character shares the same list |
| 🌍 | **Play in four languages** — the addon follows your game client's language |

## 📋 Requirements

| | |
|---|---|
| **Game** | World of Warcraft 3.3.5a on the **Ebonhold** server |
| **Integration** | ProjectEbonhold, included with the Ebonhold client; no separate addon required |

## 💾 Installation

1. Download the latest archive from the [Releases page](https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest).
2. Extract the `SkillTreeAutoLoad` folder into `Interface/AddOns/` of your Ebonhold client.
3. Restart the game, then open the Skill Tree: the panel appears alongside it.

> [!IMPORTANT]
> After installing, restart the game completely. A plain `/reload` is not enough, and your
> saves would not be kept.

## 🚀 Quick start

1. Open the Skill Tree and select the nodes you want as usual.
2. Click **`...`** at the top right of the panel, choose **New save**, and give it a name.
3. When you need to rebuild the tree, click **Activate** next to the save. The nodes will be
   restored exactly as you saved them.
4. Click **Apply Changes** in ProjectEbonhold to send the changes to the server.

> [!NOTE]
> Open the Skill Tree at least once per session before activating a save. The addon needs to
> read its current state first.

## 🧭 The panel

The panel appears and disappears with the Skill Tree window.

| Control | What it does |
|---|---|
| **`<>`** (top left) | Moves the panel to the other side of the window. Its position is remembered. |
| **`-` / `+`** (top left) | Collapses the panel to a tab or expands it again. |
| **`...`** (top right) | Creates a save or group and controls compact mode and automatic framing. |
| **Group header** (right-click) | Renames or deletes the group. Its saves return to *Uncategorized*. |
| **Activate** (on a row) | Restores the save to the displayed tree. |
| **Progressive · ON/OFF** (on a row) | Chooses the activation mode for that save. The setting is remembered. |
| **`...`** (on a row) | Renames, moves, updates, or deletes the save. |
| **Save row** (hover) | Shows progress and cost details, highlights missing nodes, and previews their location. |

By default, the panel sits beside the Skill Tree. **Compact mode** places it over the inside
edge of the tree and recenters the usable view around it. The panel can be collapsed in either
mode, and its side, size state, and display settings are remembered.

Each row shows the state of its save:

- 🟢 **Active** — every node in the save is already selected.
- 🟡 In **full mode**, **`Nodes: N — Cost: X Soul Ashes`** shows everything still required.
- 🟡 In **progressive mode**, the row shows what the next click can activate, or how many Soul
  Ashes are missing for the next available node.
- The background fill shows overall progress based on the Soul Ashes invested in the save, not
  merely the number of completed nodes.

The cost updates automatically whenever your Soul Ashes balance changes, so you immediately
know when a save becomes available.

## 👁 Previewing a save

Hover over a save to reveal its missing nodes directly on the Skill Tree. In full mode, every
missing node is highlighted in amber. In progressive mode, nodes that can be activated by the
next click appear in green, while later nodes remain amber.

The addon smoothly pans and zooms to frame the relevant part of the tree, then restores your
previous view when you leave the panel. Directional arrows show how many saved nodes remain
outside the visible area. Automatic movement can be disabled with **Frame the tree on hover**
in the panel menu; node highlighting remains available.

## 🔄 Activating a save

Each save has its own activation mode, selected with the **Progressive · ON/OFF** control.

### Full mode

This is the default. **Activate** remains unavailable until you can afford every missing node
and rank in the save. One click restores the entire configuration.

### Progressive mode

Progressive mode lets you build toward an expensive save over several runs. Each click spends
as much as your current balance allows, always choosing the cheapest available rank while
respecting the tree's prerequisites. If nothing can be activated yet, the row shows the amount
missing for the next available node.

After either mode applies nodes, a chat message summarizes what was added and the Soul Ashes
spent. Click **Apply Changes** to confirm the result in ProjectEbonhold.

- ✅ **Existing nodes are never removed.** Activation only adds the nodes that are missing.
- 💰 **The cost is shown in advance.** The button remains greyed out while your balance is too
  low in full mode; progressive mode remains available whenever at least one rank is affordable.
- 🔁 **Your Soul Ashes balance updates immediately**, without reloading the interface.

## 📂 Your saves

Saves belong to your **account**, so every character shares the same list.

If you used a version older than 1.5, your previous saves were tied to individual characters.
They are transferred to the account automatically the first time each character logs in.
Nothing is overwritten: identical saves are skipped, while saves with the same name but
different contents are added as `Name (Character)`.

> [!NOTE]
> Creating, renaming, moving, or deleting a save reloads the interface. This is intentional:
> the game writes your saves to disk at that point, protecting them from an unexpected crash.

## 💡 Good to know

- **Multiple-choice nodes are not saved.** The addon warns you once per session when it finds
  one.
- **Infinite nodes remain manual choices.** They are excluded from saves, but their current
  ranks and Soul Ashes costs are still included when the addon calculates your balance.
- **Permanent nodes are never changed.** A save only contains the choices you made yourself.
- **Nodes missing from the displayed tree are reported.** They cannot be highlighted, framed,
  or activated until they are available in the current tree.
- **Updating a save cannot silently remove part of it.** If the current tree contains fewer
  nodes than the existing save, the addon asks for confirmation before replacing it.
- **No data is shared or exported.** Your saves remain on your computer, and no build code is
  generated.

## 🧱 Code anatomy

```
SkillTreeAutoLoad/
├── SkillTreeAutoLoad.toc   metadata and load order
├── init.lua                namespace, colors, chat logging
├── locales/                enUS · frFR · deDE · esES
└── modules/
    ├── core.lua            reading the tree, cost planning, applying a save
    ├── plan.lua            progress calculation and progressive activation planning
    ├── overlay.lua         colored node markers on the Skill Tree
    ├── view.lua            preview framing, camera transitions and off-screen arrows
    ├── data.lua            saves, groups, account storage and migration
    ├── bridge.lua          server dialogue
    ├── menus.lua           dropdowns and popups
    ├── ui.lua              panel layout, save rows and activation controls
    └── main.lua            startup
```

## 🌍 Languages

🇬🇧 English · 🇫🇷 French · 🇩🇪 German · 🇪🇸 Spanish

The addon follows your game client's language automatically.

## 📜 License

SkillTreeAutoLoad is free and will remain so. It is published under the
[PolyForm Strict License 1.0.0](LICENSE.md): you may use it for noncommercial purposes, but you
may **not sell, modify, or redistribute it**. This includes publishing it on an addon site,
bundling it in a pack, or distributing a modified version. Ask for permission before any such
use.

## 🙏 Credits

Addon by **Siphelis**.
Built against ProjectEbonhold, the client-side interface of the Ebonhold server.
