-- ElpingorUI · Tick de energía (Elpingor, 20-11): la energía sube a golpes cada 2 segundos.
-- Una rayita recorre tu barra de energía y llega al final justo cuando entra el siguiente golpe,
-- para guardar energía antes de abrir o de la patada. Solo con energía (pícaro, druida gato).
-- Se sincroniza con el primer golpe que ve (+20, o +40 con Subidón de adrenalina) y sigue
-- contando aunque estés lleno. Si en 10 s no ve ningún golpe, se esconde (la energía no va a ticks).
-- /etick enciende o apaga la rayita.

local P = "|cff0cd29fElpingorUI|r: "
local TICK = 2.0
local ENERGIA = Enum and Enum.PowerType and Enum.PowerType.Energy or 3

local ultimo, anterior, visto = nil, nil, nil
local raya, barra

local function On()
    return not (ElpingorUIDB and ElpingorUIDB.tickOff)
end

local function Barra()
    local pf = PlayerFrame
    local b = pf and pf.PlayerFrameContent and pf.PlayerFrameContent.PlayerFrameContentMain
        and pf.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea
        and pf.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar
    return b or _G.PlayerFrameManaBar
end

local function Crear()
    barra = Barra()
    if not barra or raya then return end
    raya = CreateFrame("Frame", nil, barra)
    raya:SetFrameLevel(barra:GetFrameLevel() + 5)
    raya:SetSize(3, 1)
    local t = raya:CreateTexture(nil, "OVERLAY")
    t:SetAllPoints()
    t:SetColorTexture(1, 1, 1, 0.95)
    raya:Hide()
    raya:SetScript("OnUpdate", function(self)
        local now = GetTime()
        if not ultimo or now - (visto or 0) > 10 and UnitPower("player", ENERGIA) < UnitPowerMax("player", ENERGIA) then
            self:Hide(); return
        end
        local p = ((now - ultimo) % TICK) / TICK
        local w = barra:GetWidth() or 0
        self:ClearAllPoints()
        self:SetPoint("TOP", barra, "TOPLEFT", w * p, 0)
        self:SetPoint("BOTTOM", barra, "BOTTOMLEFT", w * p, 0)
    end)
end

local function Activa()
    return On() and UnitPowerType("player") == ENERGIA
end

local function Refrescar()
    Crear()
    if not raya then return end
    if Activa() and ultimo then raya:Show() else raya:Hide() end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("UNIT_DISPLAYPOWER")
ev:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
ev:SetScript("OnEvent", function(_, event, unit, tipo)
    if event == "UNIT_POWER_FREQUENT" then
        if tipo ~= "ENERGY" then return end
        local e = UnitPower("player", ENERGIA)
        if anterior then
            local d = e - anterior
            if (d >= 18 and d <= 22) or (d >= 38 and d <= 42) then
                local now = GetTime()
                ultimo, visto = now, now
                if Activa() and raya and not raya:IsShown() then raya:Show() end
            end
        end
        anterior = e
        return
    end
    if event == "UNIT_DISPLAYPOWER" and unit ~= "player" then return end
    anterior = UnitPower("player", ENERGIA)
    Refrescar()
end)

SLASH_ELPINGORTICK1 = "/etick"
SlashCmdList.ELPINGORTICK = function()
    ElpingorUIDB = ElpingorUIDB or {}
    ElpingorUIDB.tickOff = not ElpingorUIDB.tickOff or nil
    Refrescar()
    print(P .. "tick de energía " .. (On() and "encendido." or "apagado."))
end
