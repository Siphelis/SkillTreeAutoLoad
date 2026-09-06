# 🌳 SkillTreeAutoLoad

**Euer Soul Tree, mit einem einzigen Klick wieder an Ort und Stelle.**

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a-00A2FF?style=flat-square)
![Server Ebonhold](https://img.shields.io/badge/Server-Ebonhold-6E44FF?style=flat-square)
![Lua](https://img.shields.io/badge/Lua-100%25-2C2D72?style=flat-square&logo=lua&logoColor=white)
[![Neueste Version](https://img.shields.io/github/v/release/Siphelis/SkillTreeAutoLoad?style=flat-square&color=40C463&label=Version)](https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest)
[![Lizenz](https://img.shields.io/badge/Lizenz-PolyForm%20Strict%201.0.0-E5534B?style=flat-square)](LICENSE.md)

Jeder Run macht euch stärker — nur muss der Baum danach wieder aufgebaut werden.
SkillTreeAutoLoad speichert euren Soul Tree genau so, wie er ist, und sobald ihr die Soul Ashes
habt, setzt ein Klick jeden Knoten dorthin zurück, wo ihr ihn verlassen habt. Verbringt eure
Zeit mit Spielen, nicht mit Klicken.

[English](README.md) | [Français](README.fr.md) | **Deutsch** | [Español](README.es.md)

---

## Inhaltsverzeichnis

- [🔥 Warum dieses Addon](#-warum-dieses-addon)
- [✨ Funktionen](#-funktionen)
- [📋 Voraussetzungen](#-voraussetzungen)
- [💾 Installation](#-installation)
- [🚀 Schnelleinstieg](#-schnelleinstieg)
- [🧭 Das Panel](#-das-panel)
- [🔄 Einen Speicherstand aktivieren](#-einen-speicherstand-aktivieren)
- [📂 Eure Speicherstände](#-eure-speicherstände)
- [💡 Gut zu wissen](#-gut-zu-wissen)
- [🧱 Aufbau des Codes](#-aufbau-des-codes)
- [🌍 Sprachen](#-sprachen)
- [📜 Lizenz](#-lizenz)
- [🙏 Danksagung](#-danksagung)

---

## 🔥 Warum dieses Addon

Den Soul Tree von Hand wieder aufzubauen heißt, Hunderte von Knoten einzeln zu suchen und
anzuklicken, ohne sich im Rang zu vertun. Es ist der einzige Abschnitt des Spiels, in dem
nichts passiert.

SkillTreeAutoLoad macht eine Momentaufnahme des Baums, wenn er euch gefällt, und stellt genau
diesen Zustand wieder her, sobald ihr es verlangt — Knoten und Ränge inklusive.

## ✨ Funktionen

| | |
|---|---|
| 💾 | **Den Baum so festhalten, wie er ist** — beliebig viele Speicherstände, jeder mit eigenem Namen |
| 🖱 | **Ein Klick holt einen zurück** — jeder Knoten wird für euch neu gesetzt, im richtigen Rang |
| 📁 | **Gruppen**, um Ordnung zu halten, mit Umbenennen, Verschieben und Löschen |
| 💰 | **Kosten in Soul Ashes in Echtzeit**, mitlaufend, mit der genauen Differenz beim Überfahren |
| 👥 | **Accountweit geteilt** — jeder Charakter sieht dieselbe Liste |
| 🌍 | **Vier Sprachen**, passend zu eurem Spielclient |

## 📋 Voraussetzungen

| | |
|---|---|
| **Spiel** | World of Warcraft 3.3.5a auf dem Server **Ebonhold** |
| **Abhängigkeit** | Keine |

## 💾 Installation

1. Ladet das neueste Archiv von der [Releases-Seite](https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest) herunter.
2. Entpackt den Ordner `SkillTreeAutoLoad` nach `Interface/AddOns/` eures Ebonhold-Clients.
3. Startet das Spiel neu und öffnet den Soul Tree: das Panel erscheint daneben.

> [!IMPORTANT]
> Startet das Spiel nach der Installation vollständig neu. Ein einfaches `/reload` genügt
> nicht, und eure Speicherstände würden nicht erhalten bleiben.

## 🚀 Schnelleinstieg

1. Öffnet den Soul Tree und wählt wie gewohnt die gewünschten Knoten.
2. Klickt oben rechts im Panel auf **`...`** → **Neuer Speicherstand**, und benennt ihn.
3. Später, wenn der Baum neu aufgebaut werden muss und ihr die Soul Ashes habt, klickt in
   dieser Zeile auf **Aktivieren**: er wird wiederhergestellt, genau wie ihr ihn verlassen habt.
4. Drückt **Apply Changes** von ProjectEbonhold, um ihn an den Server zu schicken.

> [!NOTE]
> Öffnet den Soul Tree einmal pro Sitzung, bevor ihr einen Speicherstand aktiviert: das Addon
> muss ihn aufgehen sehen, um zu wissen, wo ihr steht.

## 🧭 Das Panel

Das Panel erscheint und verschwindet zusammen mit dem Soul-Tree-Fenster.

| Bedienelement | Wirkung |
|---|---|
| **`<>`** (oben links) | Klappt das Panel auf die andere Seite des Fensters. Wird gemerkt. |
| **`...`** (oben rechts) | Panel-Menü: **Neuer Speicherstand** (nimmt den Baum so auf, wie er ist), **Neue Gruppe** |
| **Gruppenkopf** (Rechtsklick) | Gruppe umbenennen oder löschen. Ihre Speicherstände fallen zurück auf *Ohne Kategorie* |
| **Aktivieren** (in einer Zeile) | Setzt den Speicherstand in den angezeigten Baum zurück |
| **`...`** (in einer Zeile) | **Umbenennen** · **In eine Gruppe verschieben** · **Aktualisieren (aktueller Zustand)** · **Löschen** |

Jede Zeile zeigt euch, wo ihr steht:

- 🟢 **Aktiv** — der Speicherstand ist bereits vollständig gesetzt, nichts zu tun.
- 🟡 **`N Knoten — X Soul Ashes`** — was das Zurücksetzen hinzufügen und was es kosten würde.
- Der Knopf **Aktivieren** bleibt ausgegraut, solange ihr es euch nicht leisten könnt. Fahrt
  über die Zeile, um zu sehen, wie viel genau fehlt.

Die Kostenzeile aktualisiert sich von selbst, während sich eure Soul Ashes ändern — ihr seht
also beim Spielen zu, wie ein Speicherstand in Reichweite rückt.

## 🔄 Einen Speicherstand aktivieren

Ein Klick auf **Aktivieren**, und der Baum füllt sich wieder: jeder Knoten des Speicherstands
wird neu gesetzt, im richtigen Rang. Der Chat sagt euch, was gesetzt wurde und was es gekostet
hat. Bleibt nur noch **Apply Changes**.

- ✅ **Nichts, was ihr hattet, wird weggenommen.** Aktivieren fügt immer nur hinzu: eure bereits
  erworbenen Knoten bleiben, wo sie sind, was auch passiert.
- 💰 **Die Kosten stehen vorher fest**, und der Knopf bleibt ausgegraut, solange ihr sie nicht
  tragen könnt — keine bösen Überraschungen.
- 🔁 Euer Soul-Ashes-Guthaben korrigiert sich gleich danach von selbst, ohne Neuladen der
  Oberfläche.

## 📂 Eure Speicherstände

Sie gehören dem **Account**: jeder Charakter sieht dieselbe Liste, und was ihr auf einem
speichert, taucht bei den anderen auf.

Kommt ihr von einer Version älter als 1.5, hingen eure alten Speicherstände an je einem
Charakter. Sie werden bei dessen erstem Login automatisch übernommen, und nichts wird je
überschrieben: ein identischer Speicherstand wird übersprungen, ein gleichnamiger mit anderem
Inhalt kommt als `Name (Charakter)` an.

> [!NOTE]
> Anlegen, Umbenennen, Verschieben oder Löschen eines Speicherstands lädt die Oberfläche neu.
> Das ist Absicht: nur in diesem Moment schreibt das Spiel eure Speicherstände auf die
> Festplatte, sie sind damit vor einem Absturz sicher.

## 💡 Gut zu wissen

- **Knoten mit Mehrfachauswahl werden ignoriert.** Das Addon warnt euch einmal pro Sitzung,
  wenn es einem begegnet.
- **Permanente Knoten sind sicher.** Ein Speicherstand kann nur enthalten, was ihr selbst
  gewählt habt: ihn zu aktivieren trifft diese Entscheidung nie für euch.
- **Nichts wird geteilt oder exportiert.** Eure Speicherstände bleiben bei euch; es gibt keinen
  Build-Code zum Kopieren.

## 🧱 Aufbau des Codes

```
SkillTreeAutoLoad/
├── SkillTreeAutoLoad.toc   Metadaten und Ladereihenfolge
├── init.lua                Namensraum, Farben, Chat-Ausgaben
├── locales/                enUS · frFR · deDE · esES
└── modules/
    ├── core.lua            Baum lesen, Kosten planen, Speicherstand anwenden
    ├── data.lua            Speicherstände, Gruppen, Account-Ablage und Migration
    ├── bridge.lua          Serverdialog
    ├── menus.lua           Dropdowns und Popups
    ├── ui.lua              das Panel selbst
    └── main.lua            Start
```

## 🌍 Sprachen

🇬🇧 Englisch · 🇫🇷 Französisch · 🇩🇪 Deutsch · 🇪🇸 Spanisch

Das Addon folgt automatisch der Sprache eures Spielclients.

## 📜 Lizenz

SkillTreeAutoLoad ist kostenlos und bleibt es. Es erscheint unter der
[PolyForm Strict License 1.0.0](LICENSE.md): Ihr dürft es zu jedem nichtkommerziellen Zweck
verwenden, es aber **weder verkaufen noch verändern noch weiterverbreiten** — dazu zählt auch,
es auf einer Addon-Seite erneut zu veröffentlichen, in ein Paket zu bündeln oder eine geänderte
Kopie herumzureichen. Wollt ihr eines davon, fragt vorher.

## 🙏 Danksagung

Addon von **Siphelis**.
Entwickelt gegen ProjectEbonhold, die clientseitige Oberfläche des Ebonhold-Servers.
