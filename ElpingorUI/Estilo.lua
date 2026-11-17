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
    targetDetachCastbar = false, targetStaticCastbar = false, targetCastBarXPos = 65, targetCastBarYPos = 276,
    targetCastBarWidth = 260, targetCastBarHeight = 22, targetCastBarScale = 1, targetCastBarIconScale = 1.6,
    targetCastBarTimer = true, castBarInterruptIconScale = 1.3,
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

local cambios = 0
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "ElpingorUI" then cambios = Aplicar() end
        return
    end
    if C_AddOns.IsAddOnLoaded("BetterBlizzFrames") then EngancharTiempos() end
    if cambios > 0 then
        print(P .. "estilo de la Clásica aplicado a BetterBlizzFrames (" .. cambios .. " ajustes).")
        StaticPopup_Show("ELPINGORUI_RECARGAR_ESTILO")
        cambios = 0
    end
end)
