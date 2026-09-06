# 🌳 SkillTreeAutoLoad

**Your Soul Tree, back in place in a single click.**

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a-00A2FF?style=flat-square)
![Server Ebonhold](https://img.shields.io/badge/Server-Ebonhold-6E44FF?style=flat-square)
![Lua](https://img.shields.io/badge/Lua-100%25-2C2D72?style=flat-square&logo=lua&logoColor=white)
[![Latest release](https://img.shields.io/github/v/release/Siphelis/SkillTreeAutoLoad?style=flat-square&color=40C463&label=release)](https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest)
[![License](https://img.shields.io/badge/License-PolyForm%20Strict%201.0.0-E5534B?style=flat-square)](LICENSE.md)

Every run makes you stronger — but the tree still has to go back up. SkillTreeAutoLoad saves
your Soul Tree exactly as it stands, and the moment you have the Soul Ashes, one click puts
every node back where you left it. Spend your time playing, not re-clicking.

**English** | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Table of Contents

- [🔥 Why this addon](#-why-this-addon)
- [✨ Features](#-features)
- [📋 Requirements](#-requirements)
- [💾 Installation](#-installation)
- [🚀 Quick start](#-quick-start)
- [🧭 The panel](#-the-panel)
- [🔄 Activating a save](#-activating-a-save)
- [📂 Your saves](#-your-saves)
- [💡 Good to know](#-good-to-know)
- [🧱 Code anatomy](#-code-anatomy)
- [🌍 Languages](#-languages)
- [📜 License](#-license)
- [🙏 Credits](#-credits)

---

## 🔥 Why this addon

Rebuilding the Soul Tree by hand means hunting down and clicking hundreds of nodes, one after
another, and getting every rank right. It is the one stretch of the game where nothing is
actually happening.

SkillTreeAutoLoad takes a snapshot of the tree while it suits you, and puts that exact state
back whenever you ask — nodes, ranks and all.

## ✨ Features

| | |
|---|---|
| 💾 | **Snapshot the tree as it stands** — as many saves as you want, each with its own name |
| 🖱 | **One click to bring one back** — every node is re-selected for you, at the right rank |
| 📁 | **Groups** to keep your saves tidy, with rename, move and delete menus |
| 💰 | **Live cost in Soul Ashes**, updated as you earn them, with the exact shortfall on hover |
| 👥 | **Shared across your whole account** — every character sees the same list |
| 🌍 | **Four languages**, following your game client |

## 📋 Requirements

| | |
|---|---|
| **Game** | World of Warcraft 3.3.5a on the **Ebonhold** server |
| **Dependency** | None |

## 💾 Installation

1. Download the latest archive from the [Releases page](https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest).
2. Extract the `SkillTreeAutoLoad` folder into `Interface/AddOns/` of your Ebonhold client.
3. Restart the game, then open the Soul Tree: the panel appears alongside it.

> [!IMPORTANT]
> After installing, restart the game completely. A plain `/reload` is not enough, and your
> saves would not be kept.

## 🚀 Quick start

1. Open the Soul Tree and select the nodes you want, as usual.
2. Click **`...`** at the top right of the panel → **New save**, and name it.
3. Later, when the tree has to be built again and you have the Soul Ashes, click **Activate**
   on that row: it is restored exactly as you left it.
4. Press ProjectEbonhold's **Apply Changes** to send it to the server.

> [!NOTE]
> Open the Soul Tree once per session before activating a save: the addon needs to watch it
> open to know where you stand.

## 🧭 The panel

The panel shows and hides together with the Soul Tree window.

| Control | What it does |
|---|---|
| **`<>`** (top left) | Flips the panel to the other side of the tree window. Remembered. |
| **`...`** (top right) | Panel menu: **New save** (captures the tree as it is now), **New group** |
| **Group header** (right-click) | Rename or delete the group. Its saves fall back to *Uncategorized* |
| **Activate** (on a row) | Puts the save back into the tree on screen |
| **`...`** (on a row) | **Rename** · **Move to a group** · **Update (current state)** · **Delete** |

Each row tells you where you stand:

- 🟢 **Active** — the save is already fully selected, nothing to do.
- 🟡 **`N node(s) — X Soul Ashes`** — what putting it back would add, and what it would cost.
- The **Activate** button stays greyed out until you can afford it. Hover the row for the
  exact shortfall.

The cost line updates on its own as your Soul Ashes change, so you can watch a save come into
reach while you play.

## 🔄 Activating a save

One click on **Activate** and the tree fills back in: every node in the save is re-selected, at
the right rank. Chat tells you what was put back and what it cost. All that is left is to press
**Apply Changes**.

- ✅ **Nothing you had is taken away.** Activating only ever adds: the nodes you already own
  stay exactly where they are, whatever happens.
- 💰 **The cost is announced up front**, and the button stays greyed out until you can afford
  it — no bad surprises.
- 🔁 Your Soul Ashes balance corrects itself right after, with no interface reload.

## 📂 Your saves

They belong to the **account**: every character sees the same list, and what you save on one
turns up on the others.

If you are coming from a version older than 1.5, your old saves were tied to each character.
They are picked up automatically the first time that character logs in, and nothing is ever
overwritten: an identical save is skipped, and a same-name save with different content arrives
as `Name (Character)`.

> [!NOTE]
> Creating, renaming, moving or deleting a save reloads the interface. That is on purpose: it
> is the only moment the game writes your saves to disk, so they are safe from a crash.

## 💡 Good to know

- **Multiple-choice nodes are ignored** by saves. The addon warns you once per session when it
  meets one.
- **Permanent nodes are safe.** A save can only contain what you chose yourself: activating one
  never makes that decision for you.
- **Nothing is shared or exported.** Your saves stay with you; there is no build code to copy
  or paste.

## 🧱 Code anatomy

```
SkillTreeAutoLoad/
├── SkillTreeAutoLoad.toc   metadata and load order
├── init.lua                namespace, colors, chat logging
├── locales/                enUS · frFR · deDE · esES
└── modules/
    ├── core.lua            reading the tree, cost planning, applying a save
    ├── data.lua            saves, groups, account storage and migration
    ├── bridge.lua          server dialogue
    ├── menus.lua           dropdowns and popups
    ├── ui.lua              the panel itself
    └── main.lua            startup
```

## 🌍 Languages

🇬🇧 English · 🇫🇷 French · 🇩🇪 German · 🇪🇸 Spanish

The addon follows your game client's language automatically.

## 📜 License

SkillTreeAutoLoad is free to use, and stays that way. It is published under the
[PolyForm Strict License 1.0.0](LICENSE.md): you may use it for any noncommercial purpose, but
you may **not sell it, modify it, or redistribute it** — that includes republishing it on an
addon site, bundling it into a pack, or passing around a changed copy. If you want to do any
of those, ask first.

## 🙏 Credits

Addon by **Siphelis**.
Built against ProjectEbonhold, the client-side interface of the Ebonhold server.
