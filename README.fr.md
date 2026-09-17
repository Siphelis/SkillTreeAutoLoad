# 🌳 SkillTreeAutoLoad

**Retrouvez votre Skill Tree en un clic.**

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a-00A2FF?style=flat-square)
![Serveur Ebonhold](https://img.shields.io/badge/Serveur-Ebonhold-6E44FF?style=flat-square)
![Lua](https://img.shields.io/badge/Lua-100%25-2C2D72?style=flat-square&logo=lua&logoColor=white)
[![Dernière version](https://img.shields.io/github/v/release/Siphelis/SkillTreeAutoLoad?style=flat-square&color=40C463&label=version)](https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest)
[![Licence](https://img.shields.io/badge/Licence-PolyForm%20Strict%201.0.0-E5534B?style=flat-square)](LICENSE.md)

Chaque run vous rend plus puissant — mais il faut toujours reconstruire l'arbre.
SkillTreeAutoLoad mémorise votre Skill Tree tel quel. Dès que vous avez suffisamment de
Soul Ashes, un clic suffit pour replacer chaque nœud au bon endroit. Passez votre temps à
jouer, pas à tout recliquer.

[English](README.md) | **Français** | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Sommaire

- [🔥 Pourquoi cet addon](#-pourquoi-cet-addon)
- [✨ Fonctionnalités](#-fonctionnalités)
- [📋 Prérequis](#-prérequis)
- [💾 Installation](#-installation)
- [🚀 Prise en main](#-prise-en-main)
- [🧭 Le panneau](#-le-panneau)
- [👁 Prévisualiser une sauvegarde](#-prévisualiser-une-sauvegarde)
- [🔄 Activer une sauvegarde](#-activer-une-sauvegarde)
- [📂 Vos sauvegardes](#-vos-sauvegardes)
- [💡 Bon à savoir](#-bon-à-savoir)
- [🧱 Anatomie du code](#-anatomie-du-code)
- [🌍 Langues](#-langues)
- [📜 Licence](#-licence)
- [🙏 Crédits](#-crédits)

---

## 🔥 Pourquoi cet addon

Reconstruire le Skill Tree à la main, c'est retrouver des centaines de nœuds et les sélectionner
un à un, sans se tromper de rang. Une tâche répétitive qui vous éloigne inutilement du jeu.

SkillTreeAutoLoad enregistre l'arbre lorsqu'il vous convient, puis restaure cette configuration
à la demande — nœuds et rangs compris.

## ✨ Fonctionnalités

| | |
|---|---|
| 💾 | **Enregistrez l'arbre tel quel** — créez autant de sauvegardes nommées que vous le souhaitez |
| 🖱 | **Restaurez une sauvegarde en un clic** — chaque nœud est sélectionné au bon rang |
| ⚡ | **Choisissez un mode complet ou progressif pour chaque sauvegarde** — attendez le coût total ou dépensez ce que vous pouvez immédiatement |
| 👁 | **Prévisualisez une sauvegarde directement sur l'arbre** — les nœuds manquants sont surlignés et cadrés au survol |
| 📊 | **Suivez votre progression d'un coup d'œil** — chaque ligne se remplit selon les Soul Ashes déjà investies |
| 📁 | **Classez vos sauvegardes par groupes** — renommez-les, déplacez-les ou supprimez-les facilement |
| 💰 | **Suivez le coût en Soul Ashes en temps réel** — le montant manquant apparaît au survol |
| 🪟 | **Utilisez un panneau compact et repliable** — placez-le dans le Skill Tree ou à côté de la fenêtre |
| 👥 | **Retrouvez vos sauvegardes sur tout le compte** — tous vos personnages partagent la même liste |
| 🌍 | **Profitez de quatre langues** — l'addon suit automatiquement celle de votre client |

## 📋 Prérequis

| | |
|---|---|
| **Jeu** | World of Warcraft 3.3.5a sur le serveur **Ebonhold** |
| **Intégration** | ProjectEbonhold, inclus avec le client Ebonhold ; aucun addon supplémentaire requis |

## 💾 Installation

1. Téléchargez la dernière archive depuis la [page des Releases](https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest).
2. Extrayez le dossier `SkillTreeAutoLoad` dans `Interface/AddOns/` de votre client Ebonhold.
3. Relancez le jeu, puis ouvrez le Skill Tree : le panneau apparaît à côté.

> [!IMPORTANT]
> Après l'installation, relancez complètement le jeu. Un simple `/reload` ne suffit pas, et vos
> sauvegardes ne seraient pas conservées.

## 🚀 Prise en main

1. Ouvrez le Skill Tree et sélectionnez les nœuds voulus, comme d'habitude.
2. Cliquez sur **`...`** en haut à droite du panneau, choisissez **Nouvelle sauvegarde**, puis
   donnez-lui un nom.
3. Lorsque vous devrez reconstruire l'arbre, cliquez sur **Activer** en face de la sauvegarde :
   les nœuds seront replacés comme vous les aviez laissés.
4. Cliquez sur **Apply Changes** dans ProjectEbonhold pour envoyer les changements au serveur.

> [!NOTE]
> Ouvrez le Skill Tree au moins une fois par session avant d'activer une sauvegarde. L'addon doit
> d'abord lire son état actuel.

## 🧭 Le panneau

Le panneau s'affiche et se masque avec la fenêtre du Skill Tree.

| Contrôle | Effet |
|---|---|
| **`<>`** (en haut à gauche) | Déplace le panneau de l'autre côté de la fenêtre. Sa position est mémorisée. |
| **`-` / `+`** (en haut à gauche) | Replie le panneau sous forme d'onglet ou l'ouvre de nouveau. |
| **`...`** (en haut à droite) | Crée une sauvegarde ou un groupe et règle le mode compact et le cadrage automatique. |
| **En-tête de groupe** (clic droit) | Permet de renommer ou de supprimer le groupe. Ses sauvegardes retournent dans *Sans catégorie*. |
| **Activer** (sur une ligne) | Replace la sauvegarde dans l'arbre affiché. |
| **Progressif · OUI/NON** (sur une ligne) | Choisit le mode d'activation de cette sauvegarde. Le réglage est mémorisé. |
| **`...`** (sur une ligne) | Permet de renommer, déplacer, mettre à jour ou supprimer la sauvegarde. |
| **Ligne d'une sauvegarde** (survol) | Affiche sa progression et son coût, surligne les nœuds manquants et prévisualise leur position. |

Par défaut, le panneau se place à côté du Skill Tree. Le **mode compact** le superpose au bord
intérieur de l'arbre et recentre la zone visible autour de lui. Le panneau peut être replié
dans les deux modes ; son côté, son état et ses options d'affichage sont mémorisés.

Chaque ligne indique l'état de la sauvegarde :

- 🟢 **Active** — tous les nœuds de la sauvegarde sont déjà sélectionnés.
- 🟡 En **mode complet**, **`Nœuds : N — Coût : X Soul Ashes`** indique tout ce qu'il reste à
  obtenir.
- 🟡 En **mode progressif**, la ligne indique ce que le prochain clic peut activer ou le nombre
  de Soul Ashes manquant pour atteindre le prochain nœud disponible.
- Le remplissage de la ligne représente la progression globale selon les Soul Ashes déjà
  investies, et non simplement le nombre de nœuds terminés.

Le coût est actualisé automatiquement lorsque votre solde de Soul Ashes évolue. Vous voyez
ainsi immédiatement lorsqu'une sauvegarde devient accessible.

## 👁 Prévisualiser une sauvegarde

Survolez une sauvegarde pour afficher ses nœuds manquants directement sur le Skill Tree. En
mode complet, ils apparaissent tous en ambre. En mode progressif, les nœuds que le prochain clic
peut activer apparaissent en vert ; ceux qui devront attendre restent en ambre.

L'addon déplace et ajuste progressivement la vue pour cadrer la partie utile de l'arbre, puis
restaure votre vue lorsque vous quittez le panneau. Des flèches indiquent combien de nœuds de
la sauvegarde se trouvent encore hors de l'écran. Vous pouvez désactiver le mouvement avec
**Cadrer l'arbre au survol** dans le menu du panneau ; le surlignage reste actif.

## 🔄 Activer une sauvegarde

Chaque sauvegarde possède son propre mode d'activation, sélectionné avec le réglage
**Progressif · OUI/NON**.

### Mode complet

Il s'agit du mode par défaut. Le bouton **Activer** reste indisponible tant que vous ne pouvez
pas payer tous les nœuds et rangs manquants. Un clic restaure alors la configuration entière.

### Mode progressif

Le mode progressif permet d'avancer vers une sauvegarde coûteuse sur plusieurs runs. Chaque
clic dépense autant que votre solde le permet, en choisissant toujours le rang accessible le
moins cher et en respectant les prérequis de l'arbre. Si rien ne peut encore être activé, la
ligne indique le montant nécessaire pour atteindre le prochain nœud disponible.

Après une activation, quel que soit le mode choisi, un message dans le chat récapitule les
nœuds ajoutés et les Soul Ashes dépensées. Cliquez ensuite sur **Apply Changes** dans
ProjectEbonhold pour confirmer le résultat.

- ✅ **Aucun nœud déjà sélectionné n'est retiré.** L'activation ajoute uniquement les nœuds
  manquants.
- 💰 **Le coût est indiqué à l'avance.** En mode complet, le bouton reste grisé tant que votre
  solde est insuffisant ; en mode progressif, il devient disponible dès qu'au moins un rang
  peut être payé.
- 🔁 **Votre solde de Soul Ashes est mis à jour immédiatement**, sans rechargement de
  l'interface.

## 📂 Vos sauvegardes

Les sauvegardes sont liées à votre **compte** : tous vos personnages partagent la même liste.

Si vous utilisiez une version antérieure à la 1.5, vos anciennes sauvegardes étaient propres à
chaque personnage. Elles sont transférées automatiquement vers le compte lors de la première
connexion du personnage concerné. Rien n'est écrasé : une sauvegarde strictement identique est
ignorée, tandis qu'une sauvegarde portant le même nom mais contenant un autre arbre est ajoutée
sous la forme `Nom (Personnage)`.

> [!NOTE]
> La création, le renommage, le déplacement ou la suppression d'une sauvegarde recharge
> l'interface. Ce comportement est volontaire : le jeu écrit alors vos sauvegardes sur le
> disque afin de les protéger en cas de plantage.

## 💡 Bon à savoir

- **Les nœuds à choix multiple ne sont pas enregistrés.** L'addon vous avertit une fois par
  session lorsqu'il en rencontre un.
- **Les nœuds infinis restent des choix manuels.** Ils ne sont pas enregistrés, mais leurs
  rangs actuels et leur coût en Soul Ashes sont pris en compte dans le calcul de votre solde.
- **Les nœuds permanents ne sont jamais modifiés.** Une sauvegarde contient uniquement les
  choix que vous avez effectués vous-même.
- **Les nœuds absents de l'arbre affiché sont signalés.** Ils ne peuvent être ni surlignés, ni
  cadrés, ni activés tant qu'ils ne sont pas disponibles dans l'arbre actuel.
- **La mise à jour d'une sauvegarde ne peut pas la réduire silencieusement.** Si l'arbre actuel
  contient moins de nœuds que la sauvegarde existante, l'addon demande une confirmation avant
  de la remplacer.
- **Aucune donnée n'est partagée ni exportée.** Vos sauvegardes restent sur votre ordinateur ;
  aucun code de build n'est généré.

## 🧱 Anatomie du code

```
SkillTreeAutoLoad/
├── SkillTreeAutoLoad.toc   métadonnées et ordre de chargement
├── init.lua                espace de noms, couleurs, messages de chat
├── locales/                enUS · frFR · deDE · esES
└── modules/
    ├── core.lua            lecture de l'arbre, calcul du coût, application d'une sauvegarde
    ├── plan.lua            calcul de la progression et planification de l'activation progressive
    ├── overlay.lua         marqueurs colorés sur les nœuds du Skill Tree
    ├── view.lua            cadrage de l'aperçu, transitions de la vue et flèches hors écran
    ├── data.lua            sauvegardes, groupes, stockage compte et migration
    ├── bridge.lua          dialogue avec le serveur
    ├── menus.lua           menus déroulants et popups
    ├── ui.lua              disposition du panneau, lignes et commandes d'activation
    └── main.lua            démarrage
```

## 🌍 Langues

🇬🇧 Anglais · 🇫🇷 Français · 🇩🇪 Allemand · 🇪🇸 Espagnol

L'addon suit automatiquement la langue de votre client de jeu.

## 📜 Licence

SkillTreeAutoLoad est gratuit et le restera. Il est publié sous la
[PolyForm Strict License 1.0.0](LICENSE.md) : vous pouvez l'utiliser à des fins non
commerciales, mais vous ne pouvez **ni le vendre, ni le modifier, ni le redistribuer**. Cela
inclut sa publication sur un site d'addons, son intégration à un pack ou la diffusion d'une
version modifiée. Pour tout autre usage, demandez d'abord l'autorisation.

## 🙏 Crédits

Addon créé par **Siphelis**.
Développé pour ProjectEbonhold, l'interface cliente du serveur Ebonhold.
