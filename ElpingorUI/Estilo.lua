-- ElpingorUI · Estilo de la Clásica (3.0): BetterBlizzFrames con el mismo aspecto que el resto de
-- ElpingorUI (EllesmereUI): Expressway Bold, barras pixels-dark, color de clase, bronce oscuro,
-- sin iconos de rol/líder, sin brillos (tamaño y borde en su lugar), auras importantes grandes,
-- tu interrupción en la barra del enemigo y pérdida de control con icono de interrupción aparte.
-- Se aplica UNA vez por versión (ElpingorUIDB.bbfEstilo). Si cambia algo, pide recargar una vez,
-- porque BBF lee parte de sus ajustes al cargar. Después se puede cambiar todo en /bbf.
-- La misma lista está en herramientas\patch_v42.py (una prueba comprueba que coinciden).

local P = "|cff0cd29fElpingorUI|r: "
local VERSION = 35  -- 35: dragón de élite en el retrato del jugador (Elpingor, 21-11); 34: barra del objetivo otra vez pegada a su marco (Elpingor, 17-11); 33: barra del enemigo a la altura de su marco; 32: auras más grandes y barra del enemigo grande en el centro (31: pérdida de control)

-- pixels-dark de EllesmereUI no está en LibSharedMedia: la registramos para BBF.
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
if LSM then
    LSM:Register("statusbar", "Pixels Dark (EUI)", [[Interface\AddOns\EllesmereUI\media\textures\pixels-dark.tga]])
end

-- 27-11: EllesmereUI (actualización del 27-11) quitó Expressway.TTF: «Expressway» es ahora EUI Highway.ttf.
-- La letra se pide por su NOMBRE a LibSharedMedia (vale con la versión vieja y la nueva de EllesmereUI);
-- si no está, el archivo nuevo. Todos los archivos de ElpingorUI la piden aquí.
local LETRA_VIEJA = [[Interface\AddOns\EllesmereUI\media\fonts\Expressway.TTF]]
local LETRA_NUEVA = [[Interface\AddOns\EllesmereUI\media\fonts\EUI Highway.ttf]]
function ElpingorUI_Letra()
    local f = LSM and LSM:Fetch("font", "Expressway", true)
    return f or LETRA_NUEVA
end
-- Rutas viejas guardadas en los ajustes de EllesmereUI (letra de marcos y nombres): se cambian por la buena.
do
    local buena = ElpingorUI_Letra()
    if buena ~= LETRA_VIEJA then
        local vista = {}
        local function Cambiar(t, nivel)
            if nivel > 12 or vista[t] then return end
            vista[t] = true
            for k, v in pairs(t) do
                if type(v) == "table" then Cambiar(v, nivel + 1)
                elseif type(v) == "string" and v:lower() == LETRA_VIEJA:lower() then t[k] = buena end
            end
        end
        if type(EllesmereUIDB) == "table" then pcall(Cambiar, EllesmereUIDB, 0) end
    end
end

local FONT, TEX = "Expressway", "Pixels Dark (EUI)"
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
    darkModeActionBars = true, darkModeUiAura = true,
    darkModeMinimap = false, darkModeGameTooltip = false,   -- 23-11: minimapa y tooltip los lleva EllesmereUI (decidido el 22-11)
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
    -- 35: el dragón de élite alrededor del retrato del jugador (lo tenía puesto él a mano en /bbf)
    playerEliteFrame = true, playerEliteFrameMode = 1,
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
local sinLetra = false -- 26-11: si SetFont falla una vez (letra no encontrada), no se reintenta
local function FuenteEUI() return ElpingorUI_Letra() end
local function TiempoConEstilo(bar)
    local t = bar and bar.Timer
    if not (t and t.GetFont) then return end
    local path, size, flags = t:GetFont()
    local mia = FuenteEUI()
    if path ~= mia and not sinLetra then
        if not t:SetFont(mia, size or 12, flags ~= "" and flags or "OUTLINE") then sinLetra = true end
    end
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

-- 26-11: la tecla de los botones de acción («1», «s-1», «Mou…») seguía con la letra fina del juego
-- (BBF solo cambia el nombre de la macro y la cantidad). Se le pone Expressway con el mismo tamaño.
local BARRAS = { "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton",
    "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button", "PetActionButton",
    "StanceButton" }
local function TeclaConEstilo(b)
    local hk = b and (b.HotKey or (b.GetName and _G[(b:GetName() or "") .. "HotKey"]))
    if not (hk and hk.GetFont) then return end
    local path, size, flags = hk:GetFont()
    local mia = FuenteEUI()
    if path ~= mia and not sinLetra then
        if not hk:SetFont(mia, size or 11, flags ~= "" and flags or "OUTLINE") then sinLetra = true end
    end
end
local function TodasLasTeclas()
    for _, pre in ipairs(BARRAS) do
        for i = 1, 12 do TeclaConEstilo(_G[pre .. i]) end
    end
end
do
    local t = CreateFrame("Frame")
    t:RegisterEvent("PLAYER_LOGIN")
    t:RegisterEvent("UPDATE_BINDINGS")
    t:SetScript("OnEvent", function(_, event)
        TodasLasTeclas()
        if event == "PLAYER_LOGIN" then
            if type(ActionButton_UpdateHotkeys) == "function" then
                hooksecurefunc("ActionButton_UpdateHotkeys", TeclaConEstilo)
            end
            C_Timer.After(2, TodasLasTeclas) -- por si otro addon la cambia al entrar
        end
    end)
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
