local NS = SkillTreeAutoLoad

NS.L = {
    BTN_ACTIVATE = "Activate",
    BTN_PANEL_MENU = "...",
    MENU_NEW_SAVE = "New save",
    MENU_NEW_GROUP = "New group",
    BTN_MENU = "...",
    BTN_SIDE = "<>",
    UNGROUPED = "Uncategorized",
    EMPTY_LIST = "No save yet. Use the '...' menu to store the current state of the tree.",

    ROW_ACTIVE = "Active",
    ROW_READ_FAILED = "Read failed",
    ROW_COST = "%d node(s) - %s Soul Ashes",

    TOOLTIP_READ_FAILED = "Unable to read the tree.",
    TOOLTIP_COST = "Cost to activate: %s Soul Ashes",
    TOOLTIP_MISSING = "You are short %s Soul Ashes",

    PROMPT_NEW_SAVE = "Name of the new save:",
    PROMPT_NEW_GROUP = "Name of the new group:",
    PROMPT_RENAME = "New name:",
    PROMPT_RENAME_GROUP = "New group name:",
    POPUP_OK = "OK",
    POPUP_CANCEL = "Cancel",
    POPUP_YES = "Yes",
    POPUP_NO = "No",

    MENU_RENAME = "Rename",
    MENU_MOVE = "Move to a group",
    MENU_UPDATE = "Update (current state)",
    MENU_DELETE = "Delete",
    MENU_RENAME_GROUP = "Rename group",
    MENU_DELETE_GROUP = "Delete group",

    CONFIRM_DELETE_SAVE = "Delete the save '%s'?",
    CONFIRM_DELETE_GROUP = "Delete the group '%s'? Its saves will move back to '%s'.",

    DEFAULT_SAVE_NAME = "Unnamed save",

    MSG_ALREADY_ACTIVE = "'%s' is already fully active.",
    MSG_APPLIED = "'%s' applied: %d node(s), %s Soul Ashes spent. Click 'Apply Changes' to confirm.",
    MSG_READ_FAILED = "Unable to read the tree.",
    MSG_ACTIVATION_FAILED = "Cannot activate: %s",
    MSG_CAPTURE_FAILED = "Capture failed: %s",
    MSG_UPDATE_FAILED = "Update failed: %s",
    MSG_MULTICHOICE = "Multiple-choice node detected: it will be ignored by saves.",
    MSG_NO_PROJECTEBONHOLD = "ProjectEbonhold not found: the panel will not be shown.",
    MSG_NO_SENDTOSERVER = "ProjectEbonhold.sendToServer missing: the server bridge is inactive.",
    MSG_NO_LOADOUT_ID = "Unknown loadout identity: open the Skill Tree once before activating a save.",
    MSG_MIGRATED = "Saves of %s moved to the account: %d imported, %d already present.",

    ERR_NO_DATABASE = "TalentDatabase unavailable",
    ERR_TREE_NOT_READY = "Skill Tree not ready",
    ERR_NO_SETTER = "UpdateTotalSoulPoints unavailable",
    ERR_READ_TREE = "unable to read the tree",
    ERR_READ_BALANCE = "unable to read the balance",
    ERR_ENCODE = "encoding failed",
    ERR_NO_IMPORT_BUTTON = "import button not found",
    ERR_NO_IMPORT_POPUP = "import popup unavailable",
    ERR_REREAD_TREE = "unable to re-read the tree",
    ERR_MISMATCH = "the tree does not match the target after import",
}
