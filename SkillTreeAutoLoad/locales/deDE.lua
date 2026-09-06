if GetLocale() ~= "deDE" then return end

local L = SkillTreeAutoLoad.L

L.BTN_ACTIVATE = "Aktivieren"
L.BTN_PANEL_MENU = "..."
L.MENU_NEW_SAVE = "Neuer Speicherstand"
L.MENU_NEW_GROUP = "Neue Gruppe"
L.UNGROUPED = "Ohne Kategorie"
L.EMPTY_LIST = "Noch kein Speicherstand. Nutze das Menü '...', um den aktuellen Zustand des Baums zu sichern."

L.ROW_ACTIVE = "Aktiv"
L.ROW_READ_FAILED = "Lesen fehlgeschlagen"
L.ROW_COST = "%d Knoten - %s Soul Ashes"

L.TOOLTIP_READ_FAILED = "Baum kann nicht gelesen werden."
L.TOOLTIP_COST = "Kosten zum Aktivieren: %s Soul Ashes"
L.TOOLTIP_MISSING = "Dir fehlen %s Soul Ashes"

L.PROMPT_NEW_SAVE = "Name des neuen Speicherstands:"
L.PROMPT_NEW_GROUP = "Name der neuen Gruppe:"
L.PROMPT_RENAME = "Neuer Name:"
L.PROMPT_RENAME_GROUP = "Neuer Gruppenname:"
L.POPUP_OK = "OK"
L.POPUP_CANCEL = "Abbrechen"
L.POPUP_YES = "Ja"
L.POPUP_NO = "Nein"

L.MENU_RENAME = "Umbenennen"
L.MENU_MOVE = "In eine Gruppe verschieben"
L.MENU_UPDATE = "Aktualisieren (aktueller Zustand)"
L.MENU_DELETE = "Löschen"
L.MENU_RENAME_GROUP = "Gruppe umbenennen"
L.MENU_DELETE_GROUP = "Gruppe löschen"

L.CONFIRM_DELETE_SAVE = "Speicherstand '%s' löschen?"
L.CONFIRM_DELETE_GROUP = "Gruppe '%s' löschen? Ihre Speicherstände werden nach '%s' verschoben."

L.DEFAULT_SAVE_NAME = "Unbenannter Speicherstand"

L.MSG_ALREADY_ACTIVE = "'%s' ist bereits vollständig aktiv."
L.MSG_APPLIED = "'%s' angewendet: %d Knoten, %s Soul Ashes ausgegeben. Klicke auf 'Apply Changes' zum Bestätigen."
L.MSG_READ_FAILED = "Baum kann nicht gelesen werden."
L.MSG_ACTIVATION_FAILED = "Aktivierung nicht möglich: %s"
L.MSG_CAPTURE_FAILED = "Erfassung fehlgeschlagen: %s"
L.MSG_UPDATE_FAILED = "Aktualisierung fehlgeschlagen: %s"
L.MSG_MULTICHOICE = "Auswahlknoten erkannt: er wird von den Speicherständen ignoriert."
L.MSG_NO_PROJECTEBONHOLD = "ProjectEbonhold nicht gefunden: das Fenster wird nicht angezeigt."
L.MSG_NO_SENDTOSERVER = "ProjectEbonhold.sendToServer fehlt: die Serverbrücke ist inaktiv."
L.MSG_NO_LOADOUT_ID = "Loadout-Kennung unbekannt: öffne den Talentbaum einmal, bevor du einen Speicherstand aktivierst."
L.MSG_MIGRATED = "Speicherstände von %s auf das Konto übernommen: %d importiert, %d bereits vorhanden."

L.ERR_NO_DATABASE = "TalentDatabase nicht verfügbar"
L.ERR_TREE_NOT_READY = "Talentbaum nicht bereit"
L.ERR_NO_SETTER = "UpdateTotalSoulPoints nicht verfügbar"
L.ERR_READ_TREE = "Baum kann nicht gelesen werden"
L.ERR_READ_BALANCE = "Guthaben nicht lesbar"
L.ERR_ENCODE = "Kodierung fehlgeschlagen"
L.ERR_NO_IMPORT_BUTTON = "Import-Schaltfläche nicht gefunden"
L.ERR_NO_IMPORT_POPUP = "Import-Fenster nicht verfügbar"
L.ERR_REREAD_TREE = "Baum kann nicht erneut gelesen werden"
L.ERR_MISMATCH = "der Baum entspricht nach dem Import nicht dem Ziel"
