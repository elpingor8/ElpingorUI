-- ElpingorUI · Interrupción (2.4): tu interrupción vive en la barra de lanzamiento del enemigo.
--   Moderna (EllesmereUI): icono de tu interrupción (patada, contrahechizo, Bloqueo de hechizo...)
--     a la derecha de la barra de lanzamiento del objetivo y del foco, con barrido y segundos que
--     faltan. Se oculta si el hechizo no se puede cortar o si el que lanza no es enemigo.
--     El color de «interrupción lista» y la marca de cuándo vuelve ya los pone EllesmereUI.
--   Clásica (BetterBlizzFrames): enciende UNA vez el icono equivalente de BBF (objetivo y foco);
--     después se puede cambiar en /bbf y no se vuelve a tocar.
-- /einterrupcion enciende o apaga el icono de la Moderna.

local P = "|cff0cd29fElpingorUI|r: "
local UNITS = {
    target = "EllesmereUIUnitFrames_Target",
    focus  = "EllesmereUIUnitFrames_Focus",
}
local icons = {} -- unidad -> icono

local function On()
    return not (ElpingorUIDB and ElpingorUIDB.interrupcionOff)
end

local function KickSpell()
    return EllesmereUI and EllesmereUI.GetActiveKickSpell and EllesmereUI.GetActiveKickSpell()
end

local function Update(icon)
    local castbar = icon:GetParent()
    local unit = icon.unit
    local spell = KickSpell()
    if not On() or not spell or not castbar:IsShown() or not UnitExists(unit)
        or not UnitCanAttack("player", unit) then
        icon:Hide()
        return
    end
    local tex = (C_Spell and C_Spell.GetSpellTexture or GetSpellTexture)(spell)
    if tex then icon.tex:SetTexture(tex) end
    -- Tamaño: el alto de la barra, sin bajar de 16 (que se vea en 4K).
    local h = castbar:GetHeight()
    if (issecretvalue and issecretvalue(h)) or type(h) ~= "number" then h = 16 end
    h = math.max(h, 16)
    icon:SetSize(h, h)
    local cd = C_Spell.GetSpellCooldownDuration and C_Spell.GetSpellCooldownDuration(spell)
    if cd and icon.cd.SetCooldownFromDurationObject then
        icon.cd:SetCooldownFromDurationObject(cd)
    else
        icon.cd:Clear()
    end
    -- notInterruptible puede ser un valor secreto: SetAlphaFromBoolean lo acepta sin leerlo.
    -- Nunca comparar un secreto (ni con ~=): en PvP daría error. type() sí se puede, como hace EllesmereUI.
    local ni = castbar.notInterruptible
    if type(ni) ~= "nil" and icon.SetAlphaFromBoolean then
        icon:SetAlphaFromBoolean(ni, 0, 1)
    else
        icon:SetAlpha(1)
    end
    icon:Show()
end

local function UpdateAll()
    for _, icon in pairs(icons) do Update(icon) end
end

local function Build(unit, castbar)
    local icon = CreateFrame("Frame", nil, castbar)
    icon.unit = unit
    icon:SetPoint("LEFT", castbar, "RIGHT", 3, 0)
    icon:SetFrameLevel(castbar:GetFrameLevel() + 5)
    -- Borde negro de 1 px, como el resto de EllesmereUI.
    local bg = icon:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0, 0, 0, 1)
    bg:SetAllPoints()
    icon.tex = icon:CreateTexture(nil, "ARTWORK")
    icon.tex:SetPoint("TOPLEFT", 1, -1)
    icon.tex:SetPoint("BOTTOMRIGHT", -1, 1)
    icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon.cd = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cd:SetAllPoints(icon.tex)
    icon.cd:SetDrawEdge(false)
    icon.cd:SetHideCountdownNumbers(false)
    icon:Hide()
    castbar:HookScript("OnShow", function() Update(icon) end)
    castbar:HookScript("OnHide", function() icon:Hide() end)
    icons[unit] = icon
end

local function Hook()
    for unit, name in pairs(UNITS) do
        local f = _G[name]
        if not icons[unit] and f and f.Castbar then Build(unit, f.Castbar) end
    end
end

-- Clásica: el icono propio de BetterBlizzFrames, encendido una sola vez.
local function SeedBBF()
    ElpingorUIDB = ElpingorUIDB or {}
    local db = BetterBlizzFramesDB
    if ElpingorUIDB.bbfKickSeeded or type(db) ~= "table" then return end
    if not ElpingorUIDB.instalado then return end -- solo con ElpingorUI instalada
    db.castBarInterruptIconEnabled = true
    db.castBarInterruptIconTarget = true
    db.castBarInterruptIconFocus = true
    db.castBarInterruptIconDisplayCD = true
    db.castBarInterruptIconShowActiveOnly = false
    ElpingorUIDB.bbfKickSeeded = true
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
ev:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
ev:RegisterEvent("UNIT_PET")
ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        -- Antes del PLAYER_LOGIN de BBF, para que lea ya el ajuste encendido.
        if arg1 == "ElpingorUI" then SeedBBF() end
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        Hook()
        C_Timer.After(2, function() Hook(); UpdateAll() end)
        return
    end
    if event == "UNIT_PET" and arg1 ~= "player" then return end
    if (event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE") then
        -- Un fotograma después, cuando la barra ya ha guardado el nuevo estado.
        local icon = icons[arg1]
        if icon then C_Timer.After(0, function() Update(icon) end) end
        return
    end
    UpdateAll()
end)

SLASH_ELPINGORINTERRUPCION1 = "/einterrupcion"
SLASH_ELPINGORINTERRUPCION2 = "/einterrupción"
SlashCmdList.ELPINGORINTERRUPCION = function()
    ElpingorUIDB = ElpingorUIDB or {}
    ElpingorUIDB.interrupcionOff = not ElpingorUIDB.interrupcionOff or nil
    UpdateAll()
    print(P .. "icono de tu interrupción en la barra del enemigo " .. (On() and "encendido." or "apagado."))
end
