# 🌳 SkillTreeAutoLoad

**Stellt euren Skill Tree mit einem Klick wieder her.**

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a-00A2FF?style=flat-square)
![Server Ebonhold](https://img.shields.io/badge/Server-Ebonhold-6E44FF?style=flat-square)
![Lua](https://img.shields.io/badge/Lua-100%25-2C2D72?style=flat-square&logo=lua&logoColor=white)
[![Neueste Version](https://img.shields.io/github/v/release/Siphelis/SkillTreeAutoLoad?style=flat-square&color=40C463&label=Version)](https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest)
[![Lizenz](https://img.shields.io/badge/Lizenz-PolyForm%20Strict%201.0.0-E5534B?style=flat-square)](LICENSE.md)

Jeder Run macht euch stärker — doch der Baum muss trotzdem immer wieder aufgebaut werden.
SkillTreeAutoLoad merkt sich euren Skill Tree genau so, wie er ist. Sobald ihr genügend Soul
Ashes habt, bringt ein Klick jeden Knoten zurück an seinen Platz. Verbringt eure Zeit mit
Spielen, nicht mit erneutem Anklicken.

[English](README.md) | [Français](README.fr.md) | **Deutsch** | [Español](README.es.md)

---

## Inhaltsverzeichnis

- [🔥 Warum dieses Addon](#-warum-dieses-addon)
- [✨ Funktionen](#-funktionen)
- [📋 Voraussetzungen](#-voraussetzungen)
- [💾 Installation](#-installation)
- [🚀 Schnelleinstieg](#-schnelleinstieg)
- [🧭 Das Panel](#-das-panel)
- [👁 Vorschau eines Speicherstands](#-vorschau-eines-speicherstands)
- [🔄 Einen Speicherstand aktivieren](#-einen-speicherstand-aktivieren)
- [📂 Eure Speicherstände](#-eure-speicherstände)
- [💡 Gut zu wissen](#-gut-zu-wissen)
- [🧱 Aufbau des Codes](#-aufbau-des-codes)
- [🌍 Sprachen](#-sprachen)
- [📜 Lizenz](#-lizenz)
- [🙏 Danksagung](#-danksagung)

---

## 🔥 Warum dieses Addon

Den Skill Tree von Hand neu aufzubauen bedeutet, Hunderte von Knoten einzeln zu suchen und
auszuwählen, ohne sich beim Rang zu vertun. Eine eintönige Aufgabe, die euch unnötig vom
eigentlichen Spiel abhält.

SkillTreeAutoLoad speichert den Baum, sobald er euren Vorstellungen entspricht, und stellt
diese Konfiguration bei Bedarf wieder her — einschließlich aller Knoten und Ränge.

## ✨ Funktionen

| | |
|---|---|
| 💾 | **Speichert den Baum genau so, wie er ist** — erstellt beliebig viele benannte Speicherstände |
| 🖱 | **Stellt einen Speicherstand mit einem Klick wieder her** — jeder Knoten landet im richtigen Rang |
| ⚡ | **Wählt für jeden Speicherstand die vollständige oder schrittweise Aktivierung** — wartet auf die Gesamtkosten oder gebt sofort aus, was verfügbar ist |
| 👁 | **Zeigt Speicherstände direkt im Baum an** — fehlende Knoten werden beim Überfahren markiert und eingerahmt |
| 📊 | **Erkennt den Fortschritt auf einen Blick** — jede Zeile füllt sich entsprechend den bereits investierten Soul Ashes |
| 📁 | **Ordnet eure Speicherstände in Gruppen** — umbenennen, verschieben und löschen inklusive |
| 💰 | **Seht die Kosten in Soul Ashes in Echtzeit** — der fehlende Betrag erscheint beim Überfahren |
| 🪟 | **Nutzt ein kompaktes, einklappbares Panel** — platziert es im Skill Tree oder neben dem Fenster |
| 👥 | **Nutzt eure Speicherstände accountweit** — alle Charaktere teilen dieselbe Liste |
| 🌍 | **Spielt in vier Sprachen** — das Addon folgt automatisch eurem Spielclient |

## 📋 Voraussetzungen

| | |
|---|---|
| **Spiel** | World of Warcraft 3.3.5a auf dem Server **Ebonhold** |
| **Integration** | ProjectEbonhold, im Ebonhold-Client enthalten; kein zusätzliches Addon erforderlich |

## 💾 Installation

1. Ladet das neueste Archiv von der [Releases-Seite](https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest) herunter.
2. Entpackt den Ordner `SkillTreeAutoLoad` nach `Interface/AddOns/` eures Ebonhold-Clients.
3. Startet das Spiel neu und öffnet den Skill Tree: das Panel erscheint daneben.

> [!IMPORTANT]
> Startet das Spiel nach der Installation vollständig neu. Ein einfaches `/reload` genügt
> nicht, und eure Speicherstände würden nicht erhalten bleiben.

## 🚀 Schnelleinstieg

1. Öffnet den Skill Tree und wählt wie gewohnt die gewünschten Knoten.
2. Klickt oben rechts im Panel auf **`...`**, wählt **Neuer Speicherstand** und gebt ihm einen
   Namen.
3. Wenn ihr den Baum später neu aufbauen müsst, klickt beim gewünschten Speicherstand auf
   **Aktivieren**. Die Knoten werden so gesetzt, wie ihr sie gespeichert habt.
4. Klickt in ProjectEbonhold auf **Apply Changes**, um die Änderungen an den Server zu senden.

> [!NOTE]
> Öffnet den Skill Tree mindestens einmal pro Sitzung, bevor ihr einen Speicherstand aktiviert.
> Das Addon muss zuerst seinen aktuellen Zustand einlesen.

## 🧭 Das Panel

Das Panel wird gemeinsam mit dem Skill-Tree-Fenster ein- und ausgeblendet.

| Bedienelement | Wirkung |
|---|---|
| **`<>`** (oben links) | Verschiebt das Panel auf die andere Seite des Fensters. Die Position wird gespeichert. |
| **`-` / `+`** (oben links) | Klappt das Panel zu einer Lasche ein oder wieder aus. |
| **`...`** (oben rechts) | Erstellt Speicherstände oder Gruppen und steuert Kompaktmodus und automatische Einrahmung. |
| **Gruppenkopf** (Rechtsklick) | Gruppe umbenennen oder löschen. Ihre Speicherstände kehren zu *Ohne Kategorie* zurück. |
| **Aktivieren** (in einer Zeile) | Stellt den Speicherstand im angezeigten Baum wieder her. |
| **Schrittweise · AN/AUS** (in einer Zeile) | Legt den Aktivierungsmodus dieses Speicherstands fest. Die Einstellung wird gespeichert. |
| **`...`** (in einer Zeile) | Speicherstand umbenennen, verschieben, aktualisieren oder löschen. |
| **Speicherstandzeile** (Überfahren) | Zeigt Fortschritt und Kosten, markiert fehlende Knoten und zeigt ihre Position im Baum. |

Standardmäßig befindet sich das Panel neben dem Skill Tree. Der **Kompaktmodus** legt es über
den inneren Rand des Baums und richtet den nutzbaren Bereich daran aus. Das Panel lässt sich in
beiden Modi einklappen; Seite, Zustand und Anzeigeoptionen werden gespeichert.

Jede Zeile zeigt den Zustand des Speicherstands:

- 🟢 **Aktiv** — alle Knoten des Speicherstands sind bereits ausgewählt.
- 🟡 Im **vollständigen Modus** zeigt **`N Knoten — X Soul Ashes`** alles an, was noch fehlt.
- 🟡 Im **schrittweisen Modus** zeigt die Zeile, was der nächste Klick aktivieren kann, oder wie
  viele Soul Ashes für den nächsten verfügbaren Knoten fehlen.
- Die Füllung der Zeile zeigt den Gesamtfortschritt anhand der bereits investierten Soul Ashes,
  nicht nur anhand der abgeschlossenen Knoten.

Die Kosten werden automatisch aktualisiert, sobald sich euer Guthaben an Soul Ashes ändert. So
seht ihr sofort, wann ein Speicherstand verfügbar wird.

## 👁 Vorschau eines Speicherstands

Fahrt über einen Speicherstand, um seine fehlenden Knoten direkt im Skill Tree zu sehen. Im
vollständigen Modus werden alle fehlenden Knoten bernsteinfarben markiert. Im schrittweisen
Modus erscheinen die beim nächsten Klick aktivierbaren Knoten grün; spätere Knoten bleiben
bernsteinfarben.

Das Addon verschiebt und zoomt die Ansicht sanft zum relevanten Teil des Baums und stellt eure
vorherige Ansicht wieder her, sobald ihr das Panel verlasst. Richtungspfeile zeigen, wie viele
gespeicherte Knoten außerhalb des sichtbaren Bereichs liegen. Die automatische Bewegung lässt
sich im Panel-Menü mit **Baum beim Überfahren einpassen** deaktivieren; die Markierungen bleiben
weiterhin sichtbar.

## 🔄 Einen Speicherstand aktivieren

Jeder Speicherstand besitzt einen eigenen Aktivierungsmodus, der über
**Schrittweise · AN/AUS** ausgewählt wird.

### Vollständiger Modus

Dies ist die Standardeinstellung. **Aktivieren** bleibt deaktiviert, bis ihr alle fehlenden
Knoten und Ränge bezahlen könnt. Ein Klick stellt anschließend die gesamte Konfiguration her.

### Schrittweiser Modus

Im schrittweisen Modus könnt ihr über mehrere Runs auf einen teuren Speicherstand hinarbeiten.
Jeder Klick gibt so viel von eurem aktuellen Guthaben aus wie möglich. Dabei wird stets der
günstigste verfügbare Rang gewählt und alle Voraussetzungen des Baums werden eingehalten. Kann
noch nichts aktiviert werden, zeigt die Zeile den fehlenden Betrag für den nächsten verfügbaren
Knoten.

Nach jeder Aktivierung fasst eine Chatnachricht die hinzugefügten Knoten und ausgegebenen Soul
Ashes zusammen. Klickt anschließend in ProjectEbonhold auf **Apply Changes**, um das Ergebnis zu
bestätigen.

- ✅ **Bereits ausgewählte Knoten werden nie entfernt.** Die Aktivierung fügt nur fehlende
  Knoten hinzu.
- 💰 **Die Kosten werden im Voraus angezeigt.** Im vollständigen Modus bleibt die Schaltfläche
  ausgegraut, solange das Guthaben nicht ausreicht; im schrittweisen Modus wird sie aktiv,
  sobald mindestens ein Rang bezahlbar ist.
- 🔁 **Euer Guthaben an Soul Ashes wird sofort aktualisiert**, ohne die Oberfläche neu zu laden.

## 📂 Eure Speicherstände

Die Speicherstände gehören zu eurem **Account**: Alle Charaktere teilen dieselbe Liste.

Wenn ihr eine Version vor 1.5 verwendet habt, waren eure alten Speicherstände an einzelne
Charaktere gebunden. Beim ersten Login des jeweiligen Charakters werden sie automatisch in den
Account übertragen. Dabei wird nichts überschrieben: Ein identischer Speicherstand wird
übersprungen, ein gleichnamiger mit anderem Inhalt als `Name (Charakter)` hinzugefügt.

> [!NOTE]
> Beim Erstellen, Umbenennen, Verschieben oder Löschen eines Speicherstands wird die Oberfläche
> neu geladen. Das ist beabsichtigt: Das Spiel schreibt die Daten dabei auf die Festplatte und
> schützt sie so vor einem Absturz.

## 💡 Gut zu wissen

- **Knoten mit Mehrfachauswahl werden nicht gespeichert.** Das Addon warnt euch einmal pro
  Sitzung, wenn es einen solchen Knoten findet.
- **Unendliche Knoten bleiben eine manuelle Entscheidung.** Sie werden nicht gespeichert, ihre
  aktuellen Ränge und Kosten in Soul Ashes fließen jedoch in die Berechnung des Guthabens ein.
- **Permanente Knoten werden nie verändert.** Ein Speicherstand enthält ausschließlich die
  Entscheidungen, die ihr selbst getroffen habt.
- **Knoten, die im angezeigten Baum fehlen, werden gemeldet.** Sie können weder markiert noch
  eingerahmt oder aktiviert werden, solange sie im aktuellen Baum nicht verfügbar sind.
- **Beim Aktualisieren kann ein Speicherstand nicht unbemerkt kleiner werden.** Enthält der
  aktuelle Baum weniger Knoten als der vorhandene Speicherstand, fragt das Addon vor dem
  Ersetzen nach einer Bestätigung.
- **Es werden keine Daten geteilt oder exportiert.** Eure Speicherstände bleiben auf eurem
  Computer; es wird kein Build-Code erzeugt.

## 🧱 Aufbau des Codes

```
SkillTreeAutoLoad/
├── SkillTreeAutoLoad.toc   Metadaten und Ladereihenfolge
├── init.lua                Namensraum, Farben, Chat-Ausgaben
├── locales/                enUS · frFR · deDE · esES
└── modules/
    ├── core.lua            Baum lesen, Kosten planen, Speicherstand anwenden
    ├── plan.lua            Fortschrittsberechnung und Planung der schrittweisen Aktivierung
    ├── overlay.lua         farbige Knotenmarkierungen im Skill Tree
    ├── view.lua            Vorschau, Kamerabewegungen und Pfeile für Knoten außerhalb der Ansicht
    ├── data.lua            Speicherstände, Gruppen, Account-Ablage und Migration
    ├── bridge.lua          Serverdialog
    ├── menus.lua           Dropdowns und Popups
    ├── ui.lua              Panelanordnung, Speicherstandzeilen und Aktivierungssteuerung
    └── main.lua            Start
```

## 🌍 Sprachen

🇬🇧 Englisch · 🇫🇷 Französisch · 🇩🇪 Deutsch · 🇪🇸 Spanisch

Das Addon folgt automatisch der Sprache eures Spielclients.

## 📜 Lizenz

SkillTreeAutoLoad ist kostenlos und bleibt es. Es wird unter der
[PolyForm Strict License 1.0.0](LICENSE.md) veröffentlicht: Ihr dürft es für nichtkommerzielle
Zwecke verwenden, aber **weder verkaufen noch verändern noch weiterverbreiten**. Dazu zählen
auch die Veröffentlichung auf einer Addon-Seite, die Aufnahme in ein Paket und die Verbreitung
einer veränderten Version. Für jede andere Nutzung ist vorher eine Genehmigung einzuholen.

## 🙏 Danksagung

Addon von **Siphelis**.
Entwickelt für ProjectEbonhold, die clientseitige Oberfläche des Ebonhold-Servers.
