-- ElpingorUI · Corte (Elpingor, 20-11): para cortar en el momento justo.
--   · Barra de lanzamiento del enemigo (objetivo, foco y placas): una raya al 80 % y el porcentaje
--     del lanzamiento a la derecha. El número se pone verde al pasar el 80 %: es el momento de la
--     patada. En canalizados no sale (se pueden cortar en cualquier momento).
--   · Marcos de grupo: vida en porcentaje (una sola vez; luego se respeta lo que elijas en Opciones).
-- /ecorte enciende o apaga la raya y el porcentaje.

local P = "|cff0cd29fElpingorUI|r: "
local MARCA = 0.80
local FUENTE = [[Interface\AddOns\EllesmereUI\media\fonts\Expressway.TTF]]

local function On()
    return not (ElpingorUIDB and ElpingorUIDB.corteOff)
end

-- En PvP algunos valores pueden ser secretos: no se leen ni se comparan, solo se deja la raya.
local function Secreto(v)
    return issecretvalue and issecretvalue(v)
end

local function Porcentaje(bar)
    local v = bar:GetValue()
    local lo, hi = bar:GetMinMaxValues()
    if Secreto(v) or Secreto(lo) or Secreto(hi) or not (v and lo and hi) or hi <= lo then return end
    return (v - lo) / (hi - lo)
end

local function Pintar(bar)
    local m = bar.eCorte
    if not m then return end
    local canal = bar.channeling
    if Secreto(canal) then canal = false end
    local u = bar.unit
    local amigo = type(u) == "string" and not Secreto(u) and UnitExists(u) and not UnitCanAttack("player", u)
    if not On() or canal or amigo then
        m.raya:Hide(); m.txt:Hide()
        return
    end
    local w = bar:GetWidth() or 0
    if Secreto(w) or w <= 0 then return end
    m.raya:ClearAllPoints()
    m.raya:SetPoint("TOP", bar, "TOPLEFT", w * MARCA, 0)
    m.raya:SetPoint("BOTTOM", bar, "BOTTOMLEFT", w * MARCA, 0)
    m.raya:Show()
    local ok, p = pcall(Porcentaje, bar)
    if ok and p then
        m.txt:SetText(math.floor(p * 100 + 0.5) .. "%")
        if p >= MARCA then m.txt:SetTextColor(0.2, 1, 0.2) else m.txt:SetTextColor(1, 0.85, 0.2) end
        m.txt:Show()
    else
        m.txt:Hide()
    end
end

local function Enganchar(bar)
    if not bar or bar.eCorte or not bar.HookScript then return end
    local m = {}
    m.raya = bar:CreateTexture(nil, "OVERLAY", nil, 7)
    m.raya:SetColorTexture(1, 1, 1, 0.9)
    m.raya:SetWidth(2)
    m.raya:Hide()
    m.txt = bar:CreateFontString(nil, "OVERLAY")
    local h = bar:GetHeight()
    if Secreto(h) or type(h) ~= "number" then h = 10 end
    local alto = math.max(math.floor(h * 0.9), 9)
    if not m.txt:SetFont(FUENTE, alto, "OUTLINE") then m.txt:SetFontObject(GameFontHighlightSmall) end
    m.txt:SetPoint("RIGHT", bar, "RIGHT", -2, 0)
    m.txt:Hide()
    bar.eCorte = m
    bar:HookScript("OnShow", Pintar)
    bar:HookScript("OnUpdate", Pintar)
end

local function EngancharMarcos()
    Enganchar(_G.TargetFrameSpellBar)
    Enganchar(_G.FocusFrameSpellBar)
end

local function EngancharPlaca(unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    local uf = plate and plate.UnitFrame
    if not uf or not UnitCanAttack("player", unit) then return end
    Enganchar(uf.castBar or uf.CastBar)
end

-- Vida de los marcos de grupo en porcentaje, una sola vez: los de Blizzard (CVar) y los de
-- EllesmereUI (healthTextMode en los perfiles de ElpingorUI, que es lo que se ve en grupo).
StaticPopupDialogs["ELPINGORUI_RECARGAR_GRUPO"] = {
    text = "ElpingorUI: marcos de grupo actualizados (vida en %% y barra de maná/energía).\nRecarga una vez para verlo.",
    button1 = "Recargar", button2 = "Luego",
    OnAccept = function() ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}
local function VidaGrupo()
    ElpingorUIDB = ElpingorUIDB or {}
    if ElpingorUIDB.grupoPorciento2 or not ElpingorUIDB.instalado then return end
    SetCVar("raidFramesHealthText", "perc")
    local cambio = false
    local eui = EllesmereUIDB
    if type(eui) == "table" and type(eui.profiles) == "table" then
        for nombre, perfil in pairs(eui.profiles) do
            if type(nombre) == "string" and nombre:find("^Elpingor") and type(perfil) == "table" then
                perfil.addons = perfil.addons or {}
                local rf = perfil.addons.EllesmereUIRaidFrames or {}
                perfil.addons.EllesmereUIRaidFrames = rf
                if rf.healthTextMode == nil or rf.healthTextMode == "none" then
                    rf.healthTextMode = "percent"
                    if nombre == eui.activeProfile then cambio = true end
                end
            end
        end
    end
    ElpingorUIDB.grupoPorciento2 = true
    if cambio then StaticPopup_Show("ELPINGORUI_RECARGAR_GRUPO") end
end

-- 21-11: barra de maná/energía/ira en todos los del grupo (en Clásica casi todos cuentan como DPS,
-- y EllesmereUI solo la enseñaba a sanadores y tanques).
local function ManaGrupo()
    ElpingorUIDB = ElpingorUIDB or {}
    if ElpingorUIDB.grupoMana1 or not ElpingorUIDB.instalado then return end
    local cambio = false
    local eui = EllesmereUIDB
    if type(eui) == "table" and type(eui.profiles) == "table" then
        for nombre, perfil in pairs(eui.profiles) do
            if type(nombre) == "string" and nombre:find("^Elpingor") and type(perfil) == "table" then
                perfil.addons = perfil.addons or {}
                local rf = perfil.addons.EllesmereUIRaidFrames or {}
                perfil.addons.EllesmereUIRaidFrames = rf
                if not (rf.powerShowForDPS and rf.powerShowForHealer and rf.powerShowForTank) then
                    rf.powerShowForDPS, rf.powerShowForHealer, rf.powerShowForTank = true, true, true
                    if not rf.powerHeight or rf.powerHeight < 6 then rf.powerHeight = 8 end
                    if nombre == eui.activeProfile then cambio = true end
                end
            end
        end
    end
    ElpingorUIDB.grupoMana1 = true
    if cambio then StaticPopup_Show("ELPINGORUI_RECARGAR_GRUPO") end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("NAME_PLATE_UNIT_ADDED")
ev:SetScript("OnEvent", function(_, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        EngancharPlaca(unit)
    elseif event == "PLAYER_LOGIN" then
        VidaGrupo()
        ManaGrupo()
        EngancharMarcos()
    else
        EngancharMarcos()
    end
end)

SLASH_ELPINGORCORTE1 = "/ecorte"
SlashCmdList.ELPINGORCORTE = function()
    ElpingorUIDB = ElpingorUIDB or {}
    ElpingorUIDB.corteOff = not ElpingorUIDB.corteOff or nil
    print(P .. "raya del 80 % y porcentaje en la barra del enemigo " .. (On() and "encendidos." or "apagados."))
end
