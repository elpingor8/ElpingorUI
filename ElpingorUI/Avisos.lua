-- ElpingorUI · Avisos PvP (3.0)
--   1. Pérdida de control: la caja de Blizzard (Modo edición) con nuestro estilo: Expressway Bold,
--      borde bronce y fondo oscuro. Sin brillos.
--   2. Tu sanador en CC: en arena y campo de batalla, si el sanador de tu grupo (rol asignado) tiene
--      un control (categoría CROWD_CONTROL del juego), sale su icono grande arriba en el centro con
--      borde rojo Horda, el nombre del sanador y un sonido. Si el juego no da el rol, no sale nada.
-- /esanador enciende o apaga el aviso del sanador.

local P = "|cff0cd29fElpingorUI|r: "
local BRONCE = { 0.72, 0.55, 0.30 }
local ROJO = { 0.91, 0.18, 0.16 } -- rojo Horda #E82E2A

local function Fuente()
    -- La de EllesmereUI si está registrada en LibSharedMedia; si no, la de Blizzard.
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local f = LSM and LSM:Fetch("font", "Expressway Bold", true)
    return f or [[Interface\AddOns\EllesmereUI\media\fonts\Expressway Bold.ttf]]
end

local function Borde(frame, color, grosor)
    if frame._eBorde then return frame._eBorde end
    -- Cuatro tiras lisas, sin BackdropTemplate: el Backdrop de Blizzard hace cuentas con el ancho del
    -- marco y, colgado del icono de pérdida de control, ese ancho es un «número secreto» y da error
    -- (Backdrop.lua:226, 12 veces el 18-11). Las tiras solo se anclan: no leen ningún tamaño.
    local b = CreateFrame("Frame", nil, frame)
    b:SetPoint("TOPLEFT", -grosor, grosor)
    b:SetPoint("BOTTOMRIGHT", grosor, -grosor)
    b:SetFrameLevel(frame:GetFrameLevel() + 2)
    local function Tira(p1, p2, alto, ancho)
        local t = b:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(color[1], color[2], color[3], 1)
        t:SetPoint(p1, b, p1)
        t:SetPoint(p2, b, p2)
        if alto then t:SetHeight(alto) else t:SetWidth(ancho) end
    end
    Tira("TOPLEFT", "TOPRIGHT", grosor)
    Tira("BOTTOMLEFT", "BOTTOMRIGHT", grosor)
    Tira("TOPLEFT", "BOTTOMLEFT", nil, grosor)
    Tira("TOPRIGHT", "BOTTOMRIGHT", nil, grosor)
    frame._eBorde = b
    return b
end

-------------------------------------------------------------------------------
--  1. Pérdida de control con nuestro estilo
-------------------------------------------------------------------------------
local function EstiloPerdidaControl()
    local f = LossOfControlFrame
    if not f or f._eEstilo then return end
    f._eEstilo = true
    local font = Fuente()
    for _, fs in ipairs({ f.AbilityName, f.TimeLeft and f.TimeLeft.NumberText, f.TimeLeft and f.TimeLeft.SecondsText }) do
        if type(fs) == "table" and fs.SetFont then
            local _, size = fs:GetFont()
            fs:SetFont(font, size or 16, "OUTLINE")
        end
    end
    -- El fondo y las líneas rojas los quita BBF (hideLossOfControlFrameBg/Lines en Estilo.lua):
    -- BBF los vuelve a poner en cada pérdida de control, así que aquí no se tocan.
    if f.Icon then
        f.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local fondo = f:CreateTexture(nil, "BACKGROUND", nil, -1)
        fondo:SetColorTexture(0, 0, 0, 0.6)
        fondo:SetPoint("TOPLEFT", f.Icon, "TOPLEFT", -4, 4)
        fondo:SetPoint("BOTTOMRIGHT", (f.TimeLeft or f.Icon), "BOTTOMRIGHT", 8, -4)
        local holder = CreateFrame("Frame", nil, f)
        holder:SetAllPoints(f.Icon)
        Borde(holder, BRONCE, 2)
    end
end

-------------------------------------------------------------------------------
--  1b. Avisos de Battle.net y del servidor («World refresh in 10 Minutes», amigos que se conectan):
--      Blizzard los pone junto al chat; aquí van arriba en el centro, donde se leen sin tapar nada.
-------------------------------------------------------------------------------
-- Blizzard lo coloca con su sistema de alertas (no siempre con SetPoint del propio recuadro) y el
-- recuadro puede no existir al entrar: un vigilante comprueba ~10 veces por segundo, SOLO mientras se ve,
-- si está arriba en el centro, y si no lo sube (2.ª versión, 16-11: la 1.ª no lo movía en el juego).
local AVISO_Y = -150
local function EnSuSitio(f)
    local p, rel, rp, x, y = f:GetPoint(1)
    return f:GetNumPoints() == 1 and p == "TOP" and rel == UIParent and rp == "TOP" and x == 0 and y == AVISO_Y
end
local function Poner(f)
    f:ClearAllPoints()
    f:SetPoint("TOP", UIParent, "TOP", 0, AVISO_Y)
end
local vigia = CreateFrame("Frame")
local acum = 0
vigia:SetScript("OnUpdate", function(_, dt)
    acum = acum + dt
    if acum < 0.1 then return end
    acum = 0
    if InCombatLockdown() then return end
    local f = BNToastFrame
    if f and f:IsShown() and not EnSuSitio(f) then Poner(f) end
    -- 21-11: el aviso seguía encima del chat. Blizzard cuelga sus avisos del chat de ChatAlertFrame
    -- (pegado encima del chat): se sube ese soporte arriba en el centro y los avisos van con él.
    local c = ChatAlertFrame
    if c and not c:IsForbidden() then
        local p, rel, rp, x, y = c:GetPoint(1)
        if not (c:GetNumPoints() == 1 and p == "TOP" and rel == UIParent and rp == "TOP" and x == 0 and y == AVISO_Y - 60) then
            c:ClearAllPoints()
            c:SetPoint("TOP", UIParent, "TOP", 0, AVISO_Y - 60)
        end
    end
end)
-- 21-11: seguía saliendo en la esquina. EllesmereUIChat guarda su propia posición del aviso
-- (toastPosition, arriba a la izquierda) y lo vuelve a poner ahí en cada aviso. Se le cambia esa
-- posición guardada a arriba en el centro: así EllesmereUI lo coloca donde queremos y no hay pelea.
local function CentrarToast()
    local d = _G._ECHAT_DB
    local cfg = type(d) == "table" and type(d.profile) == "table" and d.profile.chat
    if type(cfg) ~= "table" then return end
    local p = cfg.toastPosition
    if type(p) ~= "table" or p.point ~= "TOP" or p.y ~= AVISO_Y or p.x ~= 0 then
        cfg.toastPosition = { point = "TOP", relPoint = "TOP", x = 0, y = AVISO_Y }
    end
end

-- 21-11 (3.ª vez): ni BNToastFrame ni ChatAlertFrame eran el aviso del «World refresh». En vez de
-- adivinar su nombre, se busca por su TEXTO: una vez por segundo se miran los marcos visibles colgados
-- de UIParent (y sus hijos, 3 niveles); el que diga «World refresh in N Minutes» o «The world around you
-- will refresh» se sube arriba en el centro. Su nombre se apunta en ElpingorUIDB.avisoRefresco.
local function TieneTexto(f, prof)
    for _, r in ipairs({ f:GetRegions() }) do
        if r.GetObjectType and r:GetObjectType() == "FontString" and r:IsVisible() then
            local t = r:GetText()
            if type(t) == "string" and not (issecretvalue and issecretvalue(t))
                and (t:find("^World refresh in %d+ Minute") or t:find("world around you will refresh")) then
                return true
            end
        end
    end
    if prof > 0 then
        for _, c in ipairs({ f:GetChildren() }) do
            if c:IsVisible() and TieneTexto(c, prof - 1) then return true end
        end
    end
end
local refresco
local buscador = CreateFrame("Frame")
local acum2 = 0
buscador:SetScript("OnUpdate", function(_, dt)
    acum2 = acum2 + dt
    if acum2 < 1 then return end
    acum2 = 0
    if InCombatLockdown() then return end
    -- 21-11: ya se sabe su nombre (apuntado la primera vez): se usa directamente y no se busca más.
    if not refresco and ElpingorUIDB and type(ElpingorUIDB.avisoRefresco) == "string" then
        local g = _G[ElpingorUIDB.avisoRefresco]
        if type(g) == "table" and g.IsForbidden and not g:IsForbidden() then refresco = g end
    end
    if refresco then
        if refresco:IsShown() and not refresco:IsProtected() and not EnSuSitio(refresco) then Poner(refresco) end
        return
    end
    -- Con el mapa abierto no se busca (el aviso no sale ahí y el mapa ya pesa bastante).
    if WorldMapFrame and WorldMapFrame:IsShown() then return end
    for _, f in ipairs({ UIParent:GetChildren() }) do
        -- 21-11: lo prohibido se descarta ANTES de tocarlo (GetSize sobre un marco prohibido daba
        -- error una vez por segundo: 4929 veces en una sesión).
        if not f:IsForbidden() and f:IsVisible() and not f:IsProtected() then
        -- Solo marcos pequeños (un aviso): nunca el chat ni un contenedor grande.
        local w, h = f:GetSize()
        local pequeno = type(w) == "number" and type(h) == "number" and not (issecretvalue and (issecretvalue(w) or issecretvalue(h)))
            and w < 600 and h < 250
        if pequeno then
            local ok, si = pcall(TieneTexto, f, 3)
            if ok and si then
                refresco = f
                ElpingorUIDB = ElpingorUIDB or {}
                ElpingorUIDB.avisoRefresco = f:GetName() or "sin nombre"
                Poner(f)
                return
            end
        end
        end
    end
end)

-------------------------------------------------------------------------------
--  2. Tu sanador en CC
-------------------------------------------------------------------------------
local aviso
local function CrearAviso()
    aviso = CreateFrame("Frame", "ElpingorUISanadorCC", UIParent)
    aviso:SetSize(52, 52)
    aviso:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    aviso:SetFrameStrata("HIGH")
    aviso.tex = aviso:CreateTexture(nil, "ARTWORK")
    aviso.tex:SetAllPoints()
    aviso.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    aviso.cd = CreateFrame("Cooldown", nil, aviso, "CooldownFrameTemplate")
    aviso.cd:SetAllPoints()
    aviso.cd:SetDrawEdge(false)
    Borde(aviso, ROJO, 2)
    aviso.txt = aviso:CreateFontString(nil, "OVERLAY")
    aviso.txt:SetFont(Fuente(), 15, "OUTLINE")
    aviso.txt:SetPoint("TOP", aviso, "BOTTOM", 0, -6)
    aviso.txt:SetTextColor(ROJO[1], ROJO[2], ROJO[3])
    aviso:Hide()
end

local function EnPvP()
    local dentro, tipo = IsInInstance()
    return dentro and (tipo == "arena" or tipo == "pvp")
end

local function EsSanador(unit)
    if not UnitExists(unit) then return false end
    local rol = UnitGroupRolesAssigned(unit)
    if issecretvalue and issecretvalue(rol) then return false end
    return rol == "HEALER"
end

-- Primer control del sanador (categoría del juego, sin listas de hechizos).
local function AurasSecretas()
    return C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() or false
end

local function ControlDe(unit)
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return end
    if AurasSecretas() then return end -- con las auras restringidas el juego no deja leerlas: no se avisa
    local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, 1, "HARMFUL|CROWD_CONTROL")
    if ok then return aura end
end

local sanador, sonado
local function Comprobar()
    if not aviso then return end
    if (ElpingorUIDB and ElpingorUIDB.sanadorOff) or not EnPvP() or not sanador
        or UnitIsUnit(sanador, "player") then
        aviso:Hide(); sonado = nil
        return
    end
    local aura = ControlDe(sanador)
    if not aura then aviso:Hide(); sonado = nil; return end
    aviso.tex:SetTexture(aura.icon)
    if aura.auraInstanceID and C_UnitAuras.GetAuraDuration and aviso.cd.SetCooldownFromDurationObject then
        local ok, d = pcall(C_UnitAuras.GetAuraDuration, sanador, aura.auraInstanceID)
        if ok and d then aviso.cd:SetCooldownFromDurationObject(d) else aviso.cd:Clear() end
    end
    aviso.txt:SetText((UnitName(sanador) or "Sanador") .. " en CC")
    aviso:Show()
    if not sonado then
        sonado = true
        PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
    end
end

local function BuscarSanador()
    sanador = nil
    local n = GetNumGroupMembers() or 0
    local pref = IsInRaid() and "raid" or "party"
    for i = 1, (pref == "party" and math.min(n, 4) or n) do
        local u = pref .. i
        if EsSanador(u) and not UnitIsUnit(u, "player") then sanador = u; break end
    end
    Comprobar()
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("GROUP_ROSTER_UPDATE")
ev:RegisterEvent("PLAYER_ROLES_ASSIGNED")
ev:RegisterEvent("UNIT_AURA")
ev:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        CrearAviso()
        EstiloPerdidaControl()
        pcall(CentrarToast)
        C_Timer.After(2, function() pcall(CentrarToast) end) -- por si EllesmereUIChat crea su base tarde
        return
    end
    if event == "UNIT_AURA" then
        if sanador and unit == sanador then Comprobar() end
        return
    end
    BuscarSanador()
end)

SLASH_ELPINGORSANADOR1 = "/esanador"
SlashCmdList.ELPINGORSANADOR = function()
    ElpingorUIDB = ElpingorUIDB or {}
    ElpingorUIDB.sanadorOff = not ElpingorUIDB.sanadorOff or nil
    Comprobar()
    print(P .. "aviso de «tu sanador en CC» " .. (ElpingorUIDB.sanadorOff and "apagado." or "encendido."))
end
