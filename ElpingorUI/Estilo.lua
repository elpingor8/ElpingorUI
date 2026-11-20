-- ElpingorUI · Estilo de la Clásica (3.0): BetterBlizzFrames con el mismo aspecto que el resto de
-- ElpingorUI (EllesmereUI): Expressway Bold, barras pixels-dark, color de clase, bronce oscuro,
-- sin iconos de rol/líder, sin brillos (tamaño y borde en su lugar), auras importantes grandes,
-- tu interrupción en la barra del enemigo y pérdida de control con icono de interrupción aparte.
-- Se aplica UNA vez por versión (ElpingorUIDB.bbfEstilo). Si cambia algo, pide recargar una vez,
-- porque BBF lee parte de sus ajustes al cargar. Después se puede cambiar todo en /bbf.
-- La misma lista está en herramientas\patch_v42.py (una prueba comprueba que coinciden).

local P = "|cff0cd29fElpingorUI|r: "
local VERSION = 34  -- 34: barra del objetivo otra vez pegada a su marco (Elpingor, 17-11); 33: barra del enemigo a la altura de su marco; 32: auras más grandes y barra del enemigo grande en el centro (31: pérdida de control)

-- pixels-dark de EllesmereUI no está en LibSharedMedia: la registramos para BBF.
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
if LSM then
    LSM:Register("statusbar", "Pixels Dark (EUI)", [[Interface\AddOns\EllesmereUI\media\textures\pixels-dark.tga]])
end

local FONT, TEX = "Expressway Bold", "Pixels Dark (EUI)"
ElpingorUI_BBF_ESTILO = {
    hasSaved = true, skipUpdateMsg = true,
    changeUnitFrameFont = true, changeUnitFrameValueFont = true, changePartyFrameFont = true,
    changeActionBarFont = true,
    unitFrameFont = FONT, unitFrameValueFont = FONT, partyFrameFont = FONT, actionBarFont = FONT,
    unitFrameFontOutline = "OUTLINE", unitFrameValueFontOutline = "OUTLINE",
    partyFrameFontOutline = "OUTLINE", actionBarFontOutline = "OUTLINE",
    changeUnitFrameHealthbarTexture = true, changeUnitFrameManabarTexture = true,
    changeUnitFrameCastbarTexture = true, changeRaidFrameHealthbarTexture = true,
    unitFrameHealthbarTexture = TEX, unitFrameManabarTexture = TEX, unitFrameCastbarTexture = TEX,
    unitFrameCastbarNonInterruptibleTexture = TEX, raidFrameHealthbarTexture = TEX,
    classColorFrames = true,
    darkModeUi = true, darkModeColor = 0.55, darkModeUnitFrames = false, darkModeCastbars = false,
    darkModeActionBars = true, darkModeUiAura = true, darkModeMinimap = true, darkModeGameTooltip = true,
    darkerBronzeUnitFrames = true,
    noPortraitModes = false, noPortraitPixelBorder = false,
    hideGroupIndicator = true, hidePlayerLeaderIcon = true, hideTargetLeaderIcon = true,
    hideFocusLeaderIcon = true, hidePlayerRoleIcon = true, hidePartyRoles = true,
    targetAuraGlows = false, focusAuraGlows = false, playerAuraGlows = false,
    displayDispelGlowAlways = false, hideCombatGlow = true, hidePlayerRestGlow = true,
    hideThreatOnFrame = true, hideAllAbsorbGlow = true, hideActionBarBigProcGlow = true,
    formatStatusBarText = true,
    overShields = true, overShieldsUnitFrames = true, overShieldsCompactUnitFrames = true,
    absorbIndicator = true,
    changePartyFrameRangeAlpha = true, partyFrameRangeAlpha = 0.45,
    playerAuraFiltering = true, importantAurasFirst = true, auraHighlightScale = 1.4,
    enlargedAuraSize = 1.5, targetAndFocusSmallAuraScale = 1.0, hidePurgeTexture = false,
    -- 32: barra del enemigo suelta, grande, a la derecha de su marco (centro de la pantalla)
    targetDetachCastbar = false, targetStaticCastbar = false, targetCastBarXPos = 0, targetCastBarYPos = 0,   -- 19-11: él lo reseteó (debajo del objetivo)
    targetCastBarWidth = 150, targetCastBarHeight = 10, targetCastBarScale = 1, targetCastBarIconScale = 1,
    targetCastBarTimer = false, castBarInterruptIconScale = 1.3,
    enableLoCFrame = true, lossOfControlShowSecondIcon = true, lossOfControlSecondIconInterruptsOnly = true,
    hideLossOfControlFrameBg = true, hideLossOfControlFrameLines = true, lossOfControlFont = FONT,
    castBarInterruptIconEnabled = true, castBarInterruptIconTarget = true, castBarInterruptIconFocus = true,
    castBarInterruptIconDisplayCD = true, castBarInterruptIconShowActiveOnly = false, interruptIconBorder = true,
    playerCastBarWidth = 220, playerCastBarHeight = 16, playerCastBarShowIcon = true,
    playerCastBarIconScale = 1.1, playerCastBarTimer = true, castbarPixelBorder = true,
    castbarPixelBorderIcons = true, hideCastbarTextBorder = true, hideCastFinishSparkles = true,
}

local function Aplicar()
    ElpingorUIDB = ElpingorUIDB or {}
    local db = BetterBlizzFramesDB
    if type(db) ~= "table" or (ElpingorUIDB.bbfEstilo or 0) >= VERSION then return 0 end
    -- Solo con ElpingorUI instalada («Volver a mi interfaz» borra la instalación).
    if not ElpingorUIDB.instalado then return 0 end
    local n = 0
    for k, v in pairs(ElpingorUI_BBF_ESTILO) do
        if db[k] ~= v then db[k] = v; n = n + 1 end
    end
    ElpingorUIDB.bbfEstilo = VERSION
    ElpingorUIDB.bbfKickSeeded = true -- el icono de interrupción ya va en esta lista
    return n
end

StaticPopupDialogs["ELPINGORUI_RECARGAR_ESTILO"] = {
    text = "ElpingorUI: estilo de la interfaz Clásica aplicado.\nRecarga una vez para verlo completo.",
    button1 = "Recargar", button2 = "Luego",
    OnAccept = function() ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

-- El tiempo de las barras de lanzamiento («7.4»): BBF le pone siempre Friz Quadrata (fijo en su código,
-- sin opción). Cada vez que sale una barra se le pone Expressway Bold con el mismo tamaño.
local function FuenteEUI()
    local f = LSM and LSM:Fetch("font", FONT, true)
    return f or [[Interface\AddOns\EllesmereUI\media\fonts\Expressway Bold.ttf]]
end
local function TiempoConEstilo(bar)
    local t = bar and bar.Timer
    if not (t and t.GetFont) then return end
    local path, size, flags = t:GetFont()
    local mia = FuenteEUI()
    if path ~= mia then t:SetFont(mia, size or 12, flags ~= "" and flags or "OUTLINE") end
end
local function EngancharTiempos()
    for _, n in ipairs({ "PlayerCastingBarFrame", "PetCastingBarFrame", "TargetFrameSpellBar", "FocusFrameSpellBar" }) do
        local bar = _G[n]
        if bar and not bar._eTiempo then
            bar._eTiempo = true
            bar:HookScript("OnShow", TiempoConEstilo)
            TiempoConEstilo(bar)
        end
    end
end

-- OneForAll en prueba (Elpingor, 19-11): se queda solo con lo que no hace ya otro addon del paquete
-- (diario de mazmorras, equipo, talentos, entrenador, libros, profesiones, mapa). Lo que repite
-- EllesmereUI, BlizzMove, Lueur, LootTriage o ForeverLootSparkles, apagado. OneForAll carga antes
-- (OptionalDeps) y lee sus ajustes en PLAYER_LOGIN, así que no hace falta recargar.
-- Una sola vez: si luego cambias algo en /ofa, se respeta.
local OFA = {
    -- Interfaz y chat: EllesmereUI (bolsas, minimapa, chat, barra de datos)
    cameraZoom = false, bagSlots = false, quiverAmmo = false, infoBar = false, hideErrors = false,
    mmCollect = false, mmSquare = false, copyChat = false, chatHide = false, chatHistory = false,
    moveWindows = false, resizeWindows = false,          -- BlizzMove
    -- Botín y vendedores
    quickLoot = false, autoRepair = false, sellJunk = false, lootFeed = false,
    bagsFull = false,                                    -- LootTriage
    -- Misiones: Questie y RestedXP
    autoAccept = false, autoTurnIn = false, questXP = false, questMarks = false,
    questSparkles = false,                               -- ForeverLootSparkles
    nodeGlow = false,                                    -- Lueur
    questSellCoin = true,
    -- Tooltips: lo útil de OneForAll
    bossDrops = true, gearValue = true, recipeTip = true, unitTarget = true,
    shortStats = false, deValue = false, tipMouse = false,
    -- Social: nada automático en su nombre
    thanksBuff = false, inviteOn = false, keywordOn = false, duelOn = false, guildMap = false,
    -- Mapa
    mapLandmarks = true, lmDungeons = true, lmFlight = true, lmTransport = true, lmTransitions = true,
    mapBooks = true, mapQuests = false, mapZoneLevel = true, mapButton = true,
    flightMapNow = true, flightTimes = true,
    -- Marcos: BetterBlizzFrames y EllesmereUI
    classColors = false, classBright = false,
    -- Hechizos y avisos
    spellbookTrainer = true, lowRank = true,
    buffReminder = false,                                -- EllesmereUI Aura Buff Reminders
    durability = true,
}

local function ConfigurarOneForAll()
    if not C_AddOns.IsAddOnLoaded("OneForAll") or type(OneForAllDB) ~= "table" then return end
    if not ElpingorUIDB.instalado or ElpingorUIDB.ofaConfig then return end
    OneForAllDB.qol = OneForAllDB.qol or {}
    for k, v in pairs(OFA) do OneForAllDB.qol[k] = v end
    OneForAllDB.profileReceive = nil
    ElpingorUIDB.ofaConfig = true
    print(P .. "OneForAll configurado para convivir con el resto del paquete.")
end

local cambios = 0
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "ElpingorUI" then
            cambios = Aplicar()
            -- Bolsas y micromenú (abajo a la derecha) solo al pasar el ratón (Elpingor, 18-11).
            -- Una sola vez: si luego lo quitas en BBF, se respeta.
            local db = BetterBlizzFramesDB
            if type(db) == "table" and ElpingorUIDB.instalado and not ElpingorUIDB.bbfMicroRaton then
                if not db.fadeMicroMenu then db.fadeMicroMenu = true; cambios = cambios + 1 end
                db.fadeMicroMenuExceptQueue = true -- el ojo de la cola de BG sigue visible
                ElpingorUIDB.bbfMicroRaton = true
            end
            ConfigurarOneForAll()
        end
        return
    end
    if C_AddOns.IsAddOnLoaded("BetterBlizzFrames") then EngancharTiempos() end
    if cambios > 0 then
        print(P .. "estilo de la Clásica aplicado a BetterBlizzFrames (" .. cambios .. " ajustes).")
        StaticPopup_Show("ELPINGORUI_RECARGAR_ESTILO")
        cambios = 0
    end
end)

-- 2026-11-20 · Números de los dots en las placas (BetterBlizzPlates) con nuestra letra.
-- BBP ya tiene elegida Expressway Bold (npAuraCdFont), pero lee la letra al cargarse, antes que
-- EllesmereUI (que es quien la registra): no la encuentra y se queda con la de Blizzard (Friz).
-- Al entrar, con todo ya cargado, le pedimos que vuelva a leer sus ajustes y repinte las placas.
-- Solo si el usuario tiene activada esa letra en BBP; no se toca ningún archivo de BBP.
local letraDots = CreateFrame("Frame")
letraDots:RegisterEvent("PLAYER_LOGIN")
letraDots:SetScript("OnEvent", function()
    local db = BetterBlizzPlatesDB
    if type(BBP) ~= "table" or type(BBP.RefreshAllNameplateAuras) ~= "function" or type(db) ~= "table" then return end
    if not db.enableNameplateAuraCustomisation then return end
    if not (db.npAuraCdFontEnabled or db.npAuraStackFontEnabled) then return end
    BBP.RefreshAllNameplateAuras()
end)
