-- ElpingorUI · Kicks del grupo (Elpingor, 21-11): un icono a la derecha de cada marco de grupo con el
-- corte de su clase (Patada, Zurrar, Contrahechizo, Choque de tierra...). Brillante = listo;
-- gris con el reloj girando = gastado. Se entera cuando alguien lo lanza (UNIT_SPELLCAST_SUCCEEDED).
-- Si el juego da el hechizo como valor secreto, ese uso no se ve (no se puede leer).
-- /ekicks enciende o apaga los iconos.

local P = "|cff0cd29fElpingorUI|r: "

-- clase -> { hechizo para el icono, segundos }; ALT: otros cortes que también cuentan
local POR_CLASE = {
    ROGUE   = { 1766, 10 },    -- Patada
    WARRIOR = { 6552, 10 },    -- Zurrar
    MAGE    = { 2139, 24 },    -- Contrahechizo
    SHAMAN  = { 8042, 6 },     -- Choque de tierra
    WARLOCK = { 19244, 24 },   -- Bloqueo de hechizo (manáfago)
    PRIEST  = { 15487, 45 },   -- Silencio (sombras)
    DRUID   = { 16979, 15 },   -- Carga feral
    PALADIN = { 96231, 15 },   -- Reprender (si existe)
    DEATHKNIGHT = { 47528, 10 },
}
local ALT = { [72] = 12 }      -- Golpe con escudo (guerrero)

local function Nombre(id)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    return GetSpellInfo and (GetSpellInfo(id)) or nil
end

-- nombre del hechizo -> segundos (todas las ranks tienen el mismo nombre)
local CD = {}
local function Preparar()
    for _, v in pairs(POR_CLASE) do local n = Nombre(v[1]); if n then CD[n] = v[2] end end
    for id, s in pairs(ALT) do local n = Nombre(id); if n then CD[n] = s end end
end

local function Secreto(v) return issecretvalue and issecretvalue(v) end
local function On() return not (ElpingorUIDB and ElpingorUIDB.kicksOff) end

local iconos = {}      -- unidad -> frame
local hasta = {}       -- GUID -> GetTime() en que vuelve a estar listo

-- Busca el marco de grupo visible de cada unidad pedida (EllesmereUI o Blizzard), sea cual sea su nombre.
-- 23-11: UNA sola pasada por todos los marcos para todas las unidades (antes era una pasada entera por
-- cada miembro, hasta 5 seguidas en cada cambio de grupo y pantalla de carga: posible tirón).
local function MarcosDe(quiero)
    local mejor, area = {}, {}
    local function Mirar(f)
        if f:IsForbidden() or not f.GetAttribute or not f:IsVisible() then return end
        local u = f:GetAttribute("unit")
        if type(u) ~= "string" or not quiero[u] then return end
        -- solo marcos de grupo: fuera el marco del jugador, el objetivo y el foco
        if f == PlayerFrame or f == TargetFrame or f == FocusFrame then return end
        local n = f:GetName() or ""
        if n:find("^EllesmereUIUnitFrames") or n:find("^Player") then return end
        local w, h = f:GetSize()
        if Secreto(w) or Secreto(h) or type(w) ~= "number" or type(h) ~= "number" then return end
        if w * h > (area[u] or 0) and w < 400 then mejor[u], area[u] = f, w * h end
    end
    local f = EnumerateFrames()
    while f do
        pcall(Mirar, f)
        f = EnumerateFrames(f)
    end
    return mejor
end

local function MarcoDe(unit) return MarcosDe({ [unit] = true })[unit] end

local function Icono(unit)
    local b = iconos[unit]
    if not b then
        b = CreateFrame("Frame", nil, UIParent)
        b:SetFrameStrata("MEDIUM")
        b.tex = b:CreateTexture(nil, "ARTWORK")
        b.tex:SetAllPoints()
        b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
        b.cd:SetAllPoints()
        b.cd:SetHideCountdownNumbers(false)
        b.cd:SetScript("OnCooldownDone", function() b.tex:SetDesaturated(false); b:SetAlpha(1) end)
        iconos[unit] = b
    end
    return b
end

local function Colocar()
    for _, b in pairs(iconos) do b:Hide() end
    if not On() or not IsInGroup() or IsInRaid() then return end
    local UNIDADES = { "player", "party1", "party2", "party3", "party4" }
    local quiero = {}
    for _, unit in ipairs(UNIDADES) do
        local _, clase = UnitClass(unit)
        if UnitExists(unit) and clase and POR_CLASE[clase] then quiero[unit] = true end
    end
    if not next(quiero) then return end
    local marcos = MarcosDe(quiero)
    for _, unit in ipairs(UNIDADES) do
        if quiero[unit] then
            local _, clase = UnitClass(unit)
            local info = POR_CLASE[clase]
            local marco = marcos[unit]
            if marco then
                local b = Icono(unit)
                local h = marco:GetHeight()
                if Secreto(h) or not h or h <= 0 then h = 30 end
                local s = math.max(math.min(h * 0.6, 28), 16)
                b:SetSize(s, s)
                b:ClearAllPoints()
                b:SetPoint("LEFT", marco, "RIGHT", 3, 0)
                b:SetFrameLevel((marco:GetFrameLevel() or 1) + 5)
                local tex = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(info[1])
                    or (GetSpellTexture and GetSpellTexture(info[1]))
                b.tex:SetTexture(tex or 134400)
                local g = UnitGUID(unit)
                local fin = g and not Secreto(g) and hasta[g]
                local dur = CD[Nombre(info[1]) or ""] or info[2]
                if fin and fin > GetTime() then
                    b.cd:SetCooldown(fin - dur, dur)
                    b.tex:SetDesaturated(true); b:SetAlpha(0.8)
                else
                    b.cd:Clear(); b.tex:SetDesaturated(false); b:SetAlpha(1)
                end
                b:Show()
            end
        end
    end
end

local function Lanzado(unit, spellID)
    if Secreto(spellID) or not spellID then return end
    local n = Nombre(spellID)
    local s = n and CD[n]
    if not s then return end
    local g = UnitGUID(unit)
    if g and not Secreto(g) then hasta[g] = GetTime() + s end
    local b = iconos[unit]
    if b and b:IsShown() then
        b.tex:SetTexture((C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)) or b.tex:GetTexture())
        b.cd:SetCooldown(GetTime(), s)
        b.tex:SetDesaturated(true); b:SetAlpha(0.8)
    end
end

local pendiente = false
local function ColocarLuego()
    if pendiente then return end
    pendiente = true
    C_Timer.After(0.5, function() pendiente = false; Colocar() end)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("GROUP_ROSTER_UPDATE")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "party1", "party2", "party3", "party4")
ev:SetScript("OnEvent", function(_, event, unit, _, spellID)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        pcall(Lanzado, unit, spellID)
        return
    end
    if event == "PLAYER_LOGIN" then Preparar() end
    ColocarLuego()
    C_Timer.After(3, Colocar)   -- los marcos de grupo a veces se crean tarde
end)

SLASH_ELPINGORKICKS1 = "/ekicks"
SlashCmdList.ELPINGORKICKS = function(msg)
    if msg == "prueba" then
        for _, unit in ipairs({ "player", "party1", "party2", "party3", "party4" }) do
            if UnitExists(unit) then
                local _, clase = UnitClass(unit)
                local m = MarcoDe(unit)
                print(P .. unit .. " " .. tostring(clase) .. " -> " .. (m and (m:GetName() or tostring(m)) or "SIN MARCO")
                    .. (iconos[unit] and iconos[unit]:IsShown() and " (icono visible)" or ""))
            end
        end
        print(P .. "en grupo: " .. tostring(IsInGroup()) .. ", banda: " .. tostring(IsInRaid()) .. ", nombres: " .. tostring(next(CD) ~= nil) .. ", encendido: " .. tostring(On()))
        local ok, err = pcall(Colocar)
        if not ok then print(P .. "error al colocar los kicks: " .. tostring(err)) end
        return
    end
    ElpingorUIDB = ElpingorUIDB or {}
    ElpingorUIDB.kicksOff = not ElpingorUIDB.kicksOff or nil
    print(P .. "kicks del grupo " .. (On() and "encendidos." or "apagados."))
    local ok, err = pcall(Colocar)
    if not ok then print(P .. "error al colocar los kicks: " .. tostring(err)) end
end
