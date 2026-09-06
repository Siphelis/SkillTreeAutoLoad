local locale = GetLocale()
if locale ~= "esES" and locale ~= "esMX" then return end

local L = SkillTreeAutoLoad.L

L.BTN_ACTIVATE = "Activar"
L.BTN_PANEL_MENU = "..."
L.MENU_NEW_SAVE = "Nuevo guardado"
L.MENU_NEW_GROUP = "Nuevo grupo"
L.UNGROUPED = "Sin categoría"
L.EMPTY_LIST = "Ningún guardado. Usa el menú '...' para registrar el estado actual del árbol."

L.ROW_ACTIVE = "Activo"
L.ROW_READ_FAILED = "Lectura imposible"
L.ROW_COST = "%d nodo(s) - %s Soul Ashes"

L.TOOLTIP_READ_FAILED = "No se puede leer el árbol."
L.TOOLTIP_COST = "Coste para activar: %s Soul Ashes"
L.TOOLTIP_MISSING = "Te faltan %s Soul Ashes"

L.PROMPT_NEW_SAVE = "Nombre del nuevo guardado:"
L.PROMPT_NEW_GROUP = "Nombre del nuevo grupo:"
L.PROMPT_RENAME = "Nuevo nombre:"
L.PROMPT_RENAME_GROUP = "Nuevo nombre del grupo:"
L.POPUP_OK = "Aceptar"
L.POPUP_CANCEL = "Cancelar"
L.POPUP_YES = "Sí"
L.POPUP_NO = "No"

L.MENU_RENAME = "Renombrar"
L.MENU_MOVE = "Mover a un grupo"
L.MENU_UPDATE = "Actualizar (estado actual)"
L.MENU_DELETE = "Eliminar"
L.MENU_RENAME_GROUP = "Renombrar el grupo"
L.MENU_DELETE_GROUP = "Eliminar el grupo"

L.CONFIRM_DELETE_SAVE = "¿Eliminar el guardado '%s'?"
L.CONFIRM_DELETE_GROUP = "¿Eliminar el grupo '%s'? Sus guardados volverán a '%s'."

L.DEFAULT_SAVE_NAME = "Guardado sin nombre"

L.MSG_ALREADY_ACTIVE = "'%s' ya está completamente activo."
L.MSG_APPLIED = "'%s' aplicado: %d nodo(s), %s Soul Ashes gastadas. Haz clic en 'Apply Changes' para confirmar."
L.MSG_READ_FAILED = "No se puede leer el árbol."
L.MSG_ACTIVATION_FAILED = "No se puede activar: %s"
L.MSG_CAPTURE_FAILED = "Captura imposible: %s"
L.MSG_UPDATE_FAILED = "Actualización imposible: %s"
L.MSG_MULTICHOICE = "Nodo de elección múltiple detectado: será ignorado por los guardados."
L.MSG_NO_PROJECTEBONHOLD = "ProjectEbonhold no encontrado: el panel no se mostrará."
L.MSG_NO_SENDTOSERVER = "Falta ProjectEbonhold.sendToServer: el puente con el servidor está inactivo."
L.MSG_NO_LOADOUT_ID = "Identidad del loadout desconocida: abre el árbol una vez antes de activar un guardado."
L.MSG_MIGRATED = "Guardados de %s trasladados a la cuenta: %d importado(s), %d ya presente(s)."

L.ERR_NO_DATABASE = "TalentDatabase no disponible"
L.ERR_TREE_NOT_READY = "árbol no inicializado"
L.ERR_NO_SETTER = "UpdateTotalSoulPoints no disponible"
L.ERR_READ_TREE = "no se puede leer el árbol"
L.ERR_READ_BALANCE = "saldo ilegible"
L.ERR_ENCODE = "codificación imposible"
L.ERR_NO_IMPORT_BUTTON = "botón de importación no encontrado"
L.ERR_NO_IMPORT_POPUP = "ventana de importación no disponible"
L.ERR_REREAD_TREE = "no se puede releer el árbol"
L.ERR_MISMATCH = "el árbol no coincide con el objetivo tras la importación"
