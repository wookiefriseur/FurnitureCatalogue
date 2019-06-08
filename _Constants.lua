-- constants for filtering 

FURC_NONE               = 1
FURC_FAVE               = FURC_NONE +1
FURC_CRAFTING           = FURC_FAVE +1
FURC_CRAFTING_KNOWN     = FURC_CRAFTING +1
FURC_CRAFTING_UNKNOWN   = FURC_CRAFTING_KNOWN +1
FURC_VENDOR             = FURC_CRAFTING_UNKNOWN +1
FURC_PVP                = FURC_VENDOR +1
FURC_CROWN              = FURC_PVP +1
FURC_RUMOUR             = FURC_CROWN +1
FURC_LUXURY             = FURC_RUMOUR +1
FURC_OTHER              = FURC_LUXURY +1
FURC_ROLIS              = FURC_OTHER +1
FURC_DROP               = FURC_ROLIS +1
FURC_WRIT_VENDOR        = FURC_DROP +1
FURC_JUSTICE            = FURC_WRIT_VENDOR +1
FURC_FISHING            = FURC_JUSTICE +1
FURC_GUILDSTORE         = FURC_FISHING +1
FURC_FESTIVAL_DROP      = FURC_GUILDSTORE +1
FURC_EMPTY_STRING       = ""