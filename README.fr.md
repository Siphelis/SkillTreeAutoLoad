# 🌳 SkillTreeAutoLoad

**Votre Soul Tree, remise en place d'un seul clic.**

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a-00A2FF?style=flat-square)
![Serveur Ebonhold](https://img.shields.io/badge/Serveur-Ebonhold-6E44FF?style=flat-square)
![Lua](https://img.shields.io/badge/Lua-100%25-2C2D72?style=flat-square&logo=lua&logoColor=white)
[![Dernière version](https://img.shields.io/github/v/release/Siphelis/SkillTreeAutoLoad?style=flat-square&color=40C463&label=version)](https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest)
[![Licence](https://img.shields.io/badge/Licence-PolyForm%20Strict%201.0.0-E5534B?style=flat-square)](LICENSE.md)

Chaque run vous rend plus fort — encore faut-il remonter l'arbre. SkillTreeAutoLoad sauvegarde
votre Soul Tree telle qu'elle est, et dès que vous avez les Soul Ashes, un clic replace chaque
nœud là où vous l'aviez laissé. Le temps passe à jouer, pas à recliquer.

[English](README.md) | **Français** | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Sommaire

- [🔥 Pourquoi cet addon](#-pourquoi-cet-addon)
- [✨ Fonctionnalités](#-fonctionnalités)
- [📋 Prérequis](#-prérequis)
- [💾 Installation](#-installation)
- [🚀 Prise en main](#-prise-en-main)
- [🧭 Le panneau](#-le-panneau)
- [🔄 Activer une sauvegarde](#-activer-une-sauvegarde)
- [📂 Vos sauvegardes](#-vos-sauvegardes)
- [💡 Bon à savoir](#-bon-à-savoir)
- [🧱 Anatomie du code](#-anatomie-du-code)
- [🌍 Langues](#-langues)
- [📜 Licence](#-licence)
- [🙏 Crédits](#-crédits)

---

## 🔥 Pourquoi cet addon

Remonter la Soul Tree à la main, c'est retrouver et cliquer des centaines de nœuds les uns
après les autres, sans se tromper de rang. C'est le seul moment du jeu où il ne se passe rien.

SkillTreeAutoLoad prend une photo de l'arbre quand il vous convient, et remet cet état exact
en place quand vous le demandez — nœuds et rangs compris.

## ✨ Fonctionnalités

| | |
|---|---|
| 💾 | **Photographiez l'arbre tel quel** — autant de sauvegardes que vous voulez, chacune nommée |
| 🖱 | **Un clic pour en retrouver une** — chaque nœud est resélectionné pour vous, au bon rang |
| 📁 | **Des groupes** pour ranger vos sauvegardes, avec renommage, déplacement et suppression |
| 💰 | **Coût en Soul Ashes en direct**, mis à jour au fil de vos gains, avec le manque exact au survol |
| 👥 | **Partagées par tout le compte** — tous vos personnages voient la même liste |
| 🌍 | **Quatre langues**, selon votre client de jeu |

## 📋 Prérequis

| | |
|---|---|
| **Jeu** | World of Warcraft 3.3.5a sur le serveur **Ebonhold** |
| **Dépendance** | Aucune |

## 💾 Installation

1. Téléchargez la dernière archive depuis la [page des Releases](https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest).
2. Extrayez le dossier `SkillTreeAutoLoad` dans `Interface/AddOns/` de votre client Ebonhold.
3. Relancez le jeu, puis ouvrez la Soul Tree : le panneau apparaît à côté.

> [!IMPORTANT]
> Après l'installation, relancez complètement le jeu. Un simple `/reload` ne suffit pas, et vos
> sauvegardes ne seraient pas conservées.

## 🚀 Prise en main

1. Ouvrez la Soul Tree et sélectionnez les nœuds voulus, comme d'habitude.
2. Cliquez sur **`...`** en haut à droite du panneau → **Nouvelle sauvegarde**, puis nommez-la.
3. Plus tard, quand l'arbre est à refaire et que vous avez les Soul Ashes, cliquez sur
   **Activer** sur cette ligne : il est reconstitué tel que vous l'aviez laissé.
4. Appuyez sur **Apply Changes** de ProjectEbonhold pour l'envoyer au serveur.

> [!NOTE]
> Ouvrez la Soul Tree une fois par session avant d'activer une sauvegarde : l'addon a besoin de
> la voir s'ouvrir pour savoir où vous en êtes.

## 🧭 Le panneau

Le panneau s'affiche et se masque en même temps que la fenêtre Soul Tree.

| Contrôle | Effet |
|---|---|
| **`<>`** (en haut à gauche) | Bascule le panneau de l'autre côté de la fenêtre. Mémorisé. |
| **`...`** (en haut à droite) | Menu du panneau : **Nouvelle sauvegarde** (capture l'arbre tel quel), **Nouveau groupe** |
| **En-tête de groupe** (clic droit) | Renommer ou supprimer le groupe. Ses sauvegardes retombent dans *Sans catégorie* |
| **Activer** (sur une ligne) | Remet la sauvegarde dans l'arbre affiché |
| **`...`** (sur une ligne) | **Renommer** · **Déplacer vers un groupe** · **Mettre à jour (état actuel)** · **Supprimer** |

Chaque ligne dit où vous en êtes :

- 🟢 **Actif** — la sauvegarde est déjà entièrement sélectionnée, rien à faire.
- 🟡 **`N nœud(s) — X Soul Ashes`** — ce que sa remise en place ajouterait, et ce qu'elle coûterait.
- Le bouton **Activer** reste grisé tant que vous ne pouvez pas payer. Survolez la ligne pour
  connaître le manque exact.

La ligne de coût se met à jour toute seule au fil de vos Soul Ashes : vous voyez une
sauvegarde devenir accessible pendant que vous jouez.

## 🔄 Activer une sauvegarde

Un clic sur **Activer** et l'arbre se remplit : chaque nœud de la sauvegarde est resélectionné,
au bon rang. Le chat vous annonce ce qui a été posé et ce que ça a coûté. Il ne reste qu'à
appuyer sur **Apply Changes**.

- ✅ **Rien de ce que vous aviez n'est retiré.** Une activation ne fait qu'ajouter : vos nœuds
  déjà acquis restent en place, quoi qu'il arrive.
- 💰 **Le coût est annoncé d'avance** et le bouton reste grisé tant que vous ne pouvez pas
  payer — pas de mauvaise surprise.
- 🔁 Votre solde de Soul Ashes se corrige tout seul dans la foulée, sans recharger l'interface.

## 📂 Vos sauvegardes

Elles appartiennent au **compte** : tous vos personnages voient la même liste, et ce que vous
enregistrez sur l'un se retrouve chez les autres.

Si vous veniez d'une version antérieure à la 1.5, vos anciennes sauvegardes étaient propres à
chaque personnage. Elles sont reprises automatiquement à sa première connexion, sans que rien
ne soit jamais écrasé : une sauvegarde déjà présente à l'identique est ignorée, et un homonyme
au contenu différent arrive sous `Nom (Personnage)`.

> [!NOTE]
> Créer, renommer, déplacer ou supprimer une sauvegarde recharge l'interface. C'est voulu :
> c'est le seul moment où le jeu écrit vos sauvegardes sur le disque, elles sont donc à l'abri
> d'un plantage.

## 💡 Bon à savoir

- **Les nœuds à choix multiple sont ignorés** par les sauvegardes. L'addon vous prévient une
  fois par session lorsqu'il en rencontre un.
- **Les nœuds permanents ne craignent rien.** Une sauvegarde ne peut contenir que ce que vous
  aviez choisi vous-même : activer une sauvegarde ne prend jamais cette décision à votre place.
- **Rien n'est partagé ni exporté.** Vos sauvegardes restent chez vous ; il n'y a aucun code de
  build à copier-coller.

## 🧱 Anatomie du code

```
SkillTreeAutoLoad/
├── SkillTreeAutoLoad.toc   métadonnées et ordre de chargement
├── init.lua                espace de noms, couleurs, messages de chat
├── locales/                enUS · frFR · deDE · esES
└── modules/
    ├── core.lua            lecture de l'arbre, calcul du coût, application d'une sauvegarde
    ├── data.lua            sauvegardes, groupes, stockage compte et migration
    ├── bridge.lua          dialogue avec le serveur
    ├── menus.lua           menus déroulants et popups
    ├── ui.lua              le panneau lui-même
    └── main.lua            démarrage
```

## 🌍 Langues

🇬🇧 Anglais · 🇫🇷 Français · 🇩🇪 Allemand · 🇪🇸 Espagnol

L'addon suit automatiquement la langue de votre client de jeu.

## 📜 Licence

SkillTreeAutoLoad est gratuit, et le restera. Il est publié sous la
[PolyForm Strict License 1.0.0](LICENSE.md) : vous pouvez l'utiliser pour tout usage non
commercial, mais vous ne pouvez **ni le revendre, ni le modifier, ni le redistribuer** — cela
inclut le republier sur un site d'addons, l'intégrer à un pack, ou faire circuler une copie
modifiée. Pour l'un de ces usages, demandez d'abord.

## 🙏 Crédits

Addon par **Siphelis**.
Développé face à ProjectEbonhold, l'interface cliente du serveur Ebonhold.
