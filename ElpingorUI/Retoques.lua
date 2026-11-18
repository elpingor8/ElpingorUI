-- ElpingorUI · Retoques (antes el addon ElpingorRetoques 1.9): retoques hechos desde fuera de otros addons, para que sus
-- actualizaciones no los borren (antes se editaba su código y se perdía).
--
-- 1) Contador de misión de las nameplates ("4/12") en amarillo, como el nombre de los mobs
--    de misión. EllesmereUI lo crea en blanco (NameplateFrame:UpdateQuestText, questText).
--    Se engancha a cada placa (hooksecurefunc sobre su UpdateQuestText) y se pinta al crearse.

local YELLOW_R, YELLOW_G, YELLOW_B = 1, 0.82, 0
local hooked = setmetatable({}, { __mode = "k" })

local function PlatesNS()
    local m = EllesmereUI and EllesmereUI._ModuleNS
    return m and m.EllesmereUINameplates
end

local function Paint(plate)
    local fs = plate and plate.questText
    if fs then fs:SetTextColor(YELLOW_R, YELLOW_G, YELLOW_B, 1) end
end

local function HookPlate(plate)
    if hooked[plate] or type(plate.UpdateQuestText) ~= "function" then return end
    hooked[plate] = true
    hooksecurefunc(plate, "UpdateQuestText", Paint)
    Paint(plate)
end

local function Scan()
    local ns = PlatesNS()
    if not (ns and ns.plates) then return end
    for _, plate in pairs(ns.plates) do HookPlate(plate) end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("NAME_PLATE_UNIT_ADDED")
ev:SetScript("OnEvent", function()
    -- EllesmereUI monta la placa en este mismo evento: repasar justo después.
    C_Timer.After(0, Scan)
end)

-- 2) Ventana «Attune: Next» legible al desplegarla. Attune la pinta con un fondo negro al 28 %
--    (sin opción) y queda en la misma capa que Questie, que está justo debajo en la columna
--    derecha: al abrirla, el texto de las dos se mezclaba. Se le añade un fondo negro casi opaco
--    detrás del suyo y se sube a la capa HIGH para que tape a Questie mientras está abierta.
local ATTUNE_BG_ALPHA = 0.88
local function FixAttune()
    local f = _G.AttuneNextFrame
    if not f or f._elpingorBg then return end
    local bg = f:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints()
    bg:SetColorTexture(0.03, 0.03, 0.035, ATTUNE_BG_ALPHA)
    f._elpingorBg = bg
    f:SetFrameStrata("HIGH")
end
if type(_G.Attune_NextFrameEnsure) == "function" then
    hooksecurefunc("Attune_NextFrameEnsure", FixAttune)
end
local evA = CreateFrame("Frame")
evA:RegisterEvent("PLAYER_ENTERING_WORLD")
evA:SetScript("OnEvent", function()
    FixAttune()
    C_Timer.After(5, FixAttune)   -- Attune crea la ventana unos segundos después de entrar
end)

-- 3) Barra exacta de la varita (y de arco, arma de fuego o arrojadiza). El temporizador de
--    EllesmereUI empezaba ~0,4 s antes de que saliera cada disparo y se vaciaba ~0,6 s antes del
--    siguiente (vídeo del 2026-11-08: un disparo cada 1,8 s, la barra marcaba ~1,2 s), porque no
--    cuenta el medio segundo que la varita apunta con el personaje quieto. Esta barra arranca en el
--    momento en que sale el disparo (UNIT_SPELLCAST_SUCCEEDED del jugador) y dura lo que tarda el
--    siguiente: la velocidad del arma, corregida con lo que mide entre disparos seguidos.
--    Va en el mismo sitio que el temporizador de EllesmereUI (su fila azul está apagada; varita y
--    cuerpo a cuerpo nunca van a la vez). Mismo estilo: 240 × 10, borde bronce, chispa.
local SHOT_IDS = { [5019] = true, [75] = true, [2764] = true, [3018] = true }  -- Disparar (varita), Disparo automático, Lanzar, Disparar (arco/arma)
local SHOT_NAMES = {}
for id in pairs(SHOT_IDS) do
    local name = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)) or (GetSpellInfo and GetSpellInfo(id))
    if name then SHOT_NAMES[name] = true end
end
-- 280 × 14: llena el hueco entre el marco del jugador y el del objetivo (bordes interiores a ±150)
-- dejando 10 de margen a cada lado (petición del usuario, 2026-11-09). Igual que la barra dorada.
local W, H, X, Y = 280, 14, 0, -95
local BLUE = { 0.267, 0.729, 0.898 }
local BRONZE = { 0.34, 0.257, 0.194 }
local TEX = "Interface\\AddOns\\EllesmereUI\\media\\textures\\pixels-dark.tga"

local wand = CreateFrame("Frame", "ElpingorWandBar", UIParent)
wand:SetSize(W, H)
wand:SetPoint("CENTER", UIParent, "CENTER", X, Y)
wand:SetFrameStrata("MEDIUM")
wand:Hide()
local bg = wand:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(); bg:SetColorTexture(0, 0, 0, 0.7)
local function Edge(p1, p2, w, h)
    local t = wand:CreateTexture(nil, "BORDER")
    t:SetColorTexture(BRONZE[1], BRONZE[2], BRONZE[3], 1)
    t:SetPoint(p1, wand, p1, 0, 0); t:SetPoint(p2, wand, p2, 0, 0)
    if w then t:SetWidth(w) else t:SetHeight(h) end
end
Edge("TOPLEFT", "TOPRIGHT", nil, 1); Edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
Edge("TOPLEFT", "BOTTOMLEFT", 1, nil); Edge("TOPRIGHT", "BOTTOMRIGHT", 1, nil)
-- Dos fases (petición del usuario tras el vídeo del 2026-11-09): AZUL = recargando, te puedes mover;
-- ROJO = el último medio segundo antes del disparo, hay que estar quieto (WoW Forever: la varita y el
-- disparo automático necesitan 0,5 s parado). Si te mueves en el rojo, el disparo se retrasa y la barra
-- se queda en rojo entero hasta que sale.
local AIM = 0.5
local RED = { 0.85, 0.15, 0.12 }
-- El rojo se ve SIEMPRE (2026-11-09, el usuario quiere verlo venir): la parte izquierda del relleno,
-- la que corresponde al último medio segundo, va pintada en rojo desde que empieza el ciclo; el azul se
-- vacía hacia ella y, al llegar, sigue vaciándose el rojo. Debajo, la misma zona en rojo tenue para
-- que se vea dónde está aunque el relleno ya haya pasado.
local zone = wand:CreateTexture(nil, "ARTWORK", nil, 1)     -- zona roja tenue (fondo)
zone:SetColorTexture(RED[1], RED[2], RED[3], 0.3)
zone:SetPoint("TOPLEFT", wand, "TOPLEFT", 1, -1); zone:SetPoint("BOTTOMLEFT", wand, "BOTTOMLEFT", 1, 1)
local fill = wand:CreateTexture(nil, "ARTWORK", nil, 2)     -- relleno azul
fill:SetTexture(TEX); fill:SetVertexColor(BLUE[1], BLUE[2], BLUE[3], 1)
fill:SetPoint("TOPLEFT", wand, "TOPLEFT", 1, -1); fill:SetPoint("BOTTOMLEFT", wand, "BOTTOMLEFT", 1, 1)
local redFill = wand:CreateTexture(nil, "ARTWORK", nil, 3)  -- tramo rojo del relleno (encima del azul)
redFill:SetTexture(TEX); redFill:SetVertexColor(RED[1], RED[2], RED[3], 1)
redFill:SetPoint("TOPLEFT", wand, "TOPLEFT", 1, -1); redFill:SetPoint("BOTTOMLEFT", wand, "BOTTOMLEFT", 1, 1)
local aimW = 1
local spark = wand:CreateTexture(nil, "OVERLAY")
spark:SetColorTexture(1, 1, 1, 0.9); spark:SetSize(2, H)
spark:SetPoint("CENTER", fill, "RIGHT", 0, 0)

local shotAt, dur, learned, lastShot, repeating = 0, 1.5, nil, nil, false
-- En combate el juego da la velocidad del arma como "valor secreto" (no se puede comparar ni
-- operar: error de BugSack del 2026-11-08). Se lee fuera de combate y se guarda; en combate se usa
-- la guardada y, sobre todo, lo medido entre disparos.
local cachedSpeed = 1.5
local function IsSecret(v) return type(issecretvalue) == "function" and issecretvalue(v) end
local function RefreshSpeed()
    local ok, s = pcall(UnitRangedDamage, "player")
    if not ok or IsSecret(s) or type(s) ~= "number" then return end
    local ok2, good = pcall(function() return s > 0.3 and s < 10 end)
    if ok2 and good then
        -- La velocidad de ataque cambió (otra varita, rapidez…): el ciclo medido cambia en proporción.
        if learned and cachedSpeed and cachedSpeed > 0 and math.abs(s - cachedSpeed) > 0.01 then
            learned = learned * s / cachedSpeed
        end
        cachedSpeed = s
    end
end
local function WeaponSpeed() return cachedSpeed end
local function OnShot()
    local now = GetTime()
    if lastShot and now - lastShot < 0.25 then return end   -- el mismo disparo por dos vías
    local speed = WeaponSpeed()
    if lastShot then
        local gap = now - lastShot
        -- Disparos seguidos sin moverse: lo que de verdad tarda el ciclo. Un hueco mayor es que te
        -- moviste (el disparo esperó); uno algo menor, rapidez: también cuenta (velocidad de ataque).
        if gap >= speed * 0.6 and gap <= speed + 0.8 and not (learned and gap > learned * 1.15) then
            learned = learned and (learned * 0.6 + gap * 0.4) or gap
        end
    end
    lastShot = now
    shotAt = now
    dur = learned or speed
    aimW = math.max(1, (W - 2) * math.min(1, AIM / dur))
    zone:SetWidth(aimW)
    wand:Show()
end
local waitPulse = 0
wand:SetScript("OnUpdate", function(_, elapsed)
    local left = dur - (GetTime() - shotAt)
    if left <= 0 then
        spark:Hide()
        fill:SetWidth(0.01)
        if repeating then
            -- El disparo no ha salido aún: te moviste en el rojo. Barra entera en rojo (latiendo) hasta que salga.
            waitPulse = waitPulse + elapsed
            redFill:SetWidth(W - 2)
            redFill:SetAlpha(0.6 + 0.4 * math.abs(math.sin(waitPulse * 5)))
        else
            redFill:SetWidth(0.01)
            if left < -0.4 then wand:Hide() end
        end
        return
    end
    waitPulse = 0
    redFill:SetAlpha(1)
    spark:Show()
    local fw = math.max(0.01, (W - 2) * left / dur)        -- se vacía de derecha a izquierda
    fill:SetWidth(fw)                                       -- azul: te puedes mover
    redFill:SetWidth(math.max(0.01, math.min(aimW, fw)))   -- rojo: el último medio segundo, visible desde el principio
end)

local evW = CreateFrame("Frame")
evW:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
evW:RegisterEvent("START_AUTOREPEAT_SPELL")
evW:RegisterEvent("STOP_AUTOREPEAT_SPELL")
evW:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
evW:RegisterEvent("PLAYER_ENTERING_WORLD")
evW:RegisterEvent("PLAYER_REGEN_ENABLED")
evW:SetScript("OnEvent", function(_, event, _, _, spellID)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED" then
        RefreshSpeed()
        return
    end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local ok, hit = pcall(function()
            if SHOT_IDS[spellID] then return true end
            local name = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)) or (GetSpellInfo and GetSpellInfo(spellID))
            return name and SHOT_NAMES[name] or false
        end)
        if ok and hit then OnShot() end
    elseif event == "START_AUTOREPEAT_SPELL" then
        repeating = true
    elseif event == "STOP_AUTOREPEAT_SPELL" then
        repeating = false
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        learned = nil   -- otra varita u otra arma: volver a medir
        RefreshSpeed()
    end
end)

-- 4) Questie marca las misiones del paso actual de RestedXP (2026-11-09). RestedXP numera sus pasos
--    (p. ej. 112) y Questie ordena por nivel, así que no se sabía cuál de la lista era la del paso.
--    Las misiones de los pasos activos de la guía (RXP.currentGuide.steps[i].active, sus elementos
--    con questId) se marcan en el rastreador de Questie con una franja dorada detrás del título y una
--    barrita dorada a la izquierda. Se repasa dos veces por segundo (solo líneas de título).
local GOLD = { 1, 0.82, 0 }
-- Solo el PASO ACTUAL de la guía (RXPCData.currentStep, el número que se ve en RestedXP). Los pasos
-- «sticky» (los que la guía deja abiertos en segundo plano hasta terminar una misión, p. ej. «mata/
-- recoge mientras vas») también están activos y antes se marcaban: la marca se quedaba pegada a la
-- misión de la mina aunque RestedXP ya mandara a Orgrimmar. Si el paso actual no tiene misión (un
-- viaje), no se marca nada.
local function RXPQuestSet()
    local set, any = {}, false
    local g = RXP and RXP.currentGuide
    if not (g and g.steps) then return set, false end
    local idx = tonumber(RXPCData and RXPCData.currentStep)
    local step = idx and g.steps[idx]
    if step and step.sticky then step = nil end
    if not step then
        for _, s in ipairs(g.steps) do       -- respaldo: el primer paso activo que no sea «sticky»
            if s.active and not s.sticky and not s.completed then step = s; break end
        end
    end
    if step and step.elements then
        for _, el in ipairs(step.elements) do
            local id = el.questId
            if type(id) == "number" and not el.completed then set[id] = true; any = true end
        end
    end
    return set, any
end
local function MarkLine(line, on)
    local hl = line._elpRXP
    if not hl then
        if not on then return end
        hl = {}
        hl.bg = line:CreateTexture(nil, "BACKGROUND")
        hl.bg:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.16)
        hl.bg:SetPoint("TOPLEFT", line, "TOPLEFT", -2, 1); hl.bg:SetPoint("BOTTOMRIGHT", line, "BOTTOMRIGHT", 2, -1)
        hl.bar = line:CreateTexture(nil, "ARTWORK")
        hl.bar:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
        hl.bar:SetPoint("TOPRIGHT", line, "TOPLEFT", -2, 1); hl.bar:SetPoint("BOTTOMRIGHT", line, "BOTTOMLEFT", -2, -1)
        hl.bar:SetWidth(3)
        line._elpRXP = hl
    end
    hl.bg:SetShown(on); hl.bar:SetShown(on)
end
local linePool
local function MarkRXPQuests()
    if not linePool then
        local ok, mod = pcall(function() return QuestieLoader and QuestieLoader:ImportModule("TrackerLinePool") end)
        if not (ok and mod and mod.ForEachQuestTitleLine) then return end
        linePool = mod
    end
    local set = RXPQuestSet()
    pcall(linePool.ForEachQuestTitleLine, function(line)
        local q = line.Quest
        MarkLine(line, line:IsShown() and q and set[q.Id] and true or false)
    end)
end
if QuestieLoader and RXP then
    C_Timer.NewTicker(0.5, MarkRXPQuests)
end

-- 6) RestedXP con la letra de toda la interfaz (Expressway Bold), en la ventana de la guía, el cuadro
--    del paso y la flecha (2026-11-09). RestedXP toma la letra de su tema (theme.font → addon.font);
--    se cambia en todos sus temas (v1 y v2) al cargar, antes de que dibuje, y otra vez después de
--    cada carga de tema por si eligió uno personalizado.
local RXP_FONT = "Interface\\AddOns\\EllesmereUI\\media\\fonts\\Expressway Bold.ttf"
local function FontRXPThemes()
    if not RXP then return end
    for _, list in ipairs({ RXP.themes, RXP.v2 and RXP.v2.themes }) do
        if type(list) == "table" then
            for _, th in pairs(list) do
                if type(th) == "table" then th.font = RXP_FONT end
            end
        end
    end
    if type(RXP.activeTheme) == "table" then RXP.activeTheme.font = RXP_FONT end
    RXP.font = RXP_FONT
end
FontRXPThemes()
if RXP and type(RXP.LoadActiveTheme) == "function" then
    hooksecurefunc(RXP, "LoadActiveTheme", FontRXPThemes)
end
if RXP and RXP.v2 and type(RXP.v2.ConvertThemes) == "function" then
    hooksecurefunc(RXP.v2, "ConvertThemes", FontRXPThemes)
end
-- La flecha recibe su letra en RXP.SetupArrow, que corre al arrancar RestedXP, antes de que cargue este
-- addon (por eso en 1.8 la flecha seguía igual). Se le pone directamente al texto de la flecha al
-- entrar y cada vez que RestedXP la vuelve a montar.
local function FontRXPArrow()
    local af = RXP and RXP.arrowFrame
    if af and af.text then
        local _, size, flags = af.text:GetFont()
        af.text:SetFont(RXP_FONT, size or 9, flags or "OUTLINE")
    end
end
if RXP and type(RXP.SetupArrow) == "function" then
    hooksecurefunc(RXP, "SetupArrow", FontRXPArrow)
end
local evF = CreateFrame("Frame")
evF:RegisterEvent("PLAYER_ENTERING_WORLD")
evF:SetScript("OnEvent", function()
    FontRXPThemes()
    FontRXPArrow()
    C_Timer.After(2, FontRXPArrow)
end)

-- 5) Marco del jugador: «nivel | nombre» como el del objetivo (v30), pero a nivel 60 solo el nombre
--    (2026-11-09). EllesmereUI no tiene opción de ocultar el nivel máximo, así que cuando el marco
--    aplica su texto (frame._applyTextTags) y el personaje está a 60, se vuelve a aplicar con "name".
--    No toca los ajustes guardados: va por personaje aunque compartan perfil.
local MAX_LEVEL = 60
local reapplying = false
local function AtMax()
    local ok, lvl = pcall(UnitLevel, "player")
    if not ok or IsSecret(lvl) then return false end
    local ok2, r = pcall(function() return lvl >= MAX_LEVEL end)
    return ok2 and r
end
local function FixPlayerName(frame, left, right, center)
    if reapplying or not AtMax() then return end
    if left ~= "levelname" and left ~= "namelevel" and left ~= "level" then return end
    reapplying = true
    pcall(frame._applyTextTags, "name", right or "both", center or "none")
    reapplying = false
end
local function HookPlayerFrame()
    local f = _G.EllesmereUIUnitFrames_Player
    if not (f and type(f._applyTextTags) == "function") or f._elpLevelHook then return end
    f._elpLevelHook = true
    hooksecurefunc(f, "_applyTextTags", function(...) FixPlayerName(f, select(1, ...)) end)
    -- Aplicar ya con lo que diga el perfil.
    local m = EllesmereUI and EllesmereUI._ModuleNS and EllesmereUI._ModuleNS.EllesmereUIUnitFrames
    local s = m and m.db and m.db.profile and m.db.profile.player
    if s then FixPlayerName(f, s.leftTextContent, s.rightTextContent, s.centerTextContent) end
end
local evL = CreateFrame("Frame")
evL:RegisterEvent("PLAYER_ENTERING_WORLD")
evL:RegisterEvent("PLAYER_LEVEL_UP")
evL:SetScript("OnEvent", function()
    C_Timer.After(1, HookPlayerFrame)
    C_Timer.After(1.5, function()
        local f = _G.EllesmereUIUnitFrames_Player
        local m = EllesmereUI and EllesmereUI._ModuleNS and EllesmereUI._ModuleNS.EllesmereUIUnitFrames
        local s = m and m.db and m.db.profile and m.db.profile.player
        if f and s then FixPlayerName(f, s.leftTextContent, s.rightTextContent, s.centerTextContent) end
    end)
end)

-- 7) Barras de tiempo de RestedXP sin errores (2026-11-16). RestedXP guarda sus barras de LibCandyBar en
--    una lista propia y las vuelve a usar cuando están ocultas, pero al terminar (bar:Stop) LibCandyBar
--    las recicla: borra sus datos (data = nil) y su OnHide, y las presta a otros addons (Capping).
--    Resultado en BugSack: «attempt to perform indexed assignment on field 'data'» (Capping/LibCandyBar,
--    al reusarla RestedXP) y «Cannot anchor to itself» (RXPGuides/Timers.lua: la misma barra en dos
--    filas). Arreglo: cuando para una barra de RestedXP, se saca del reciclaje de LibCandyBar (vuelve a
--    ser solo de RestedXP), se le ponen datos limpios y se ejecuta su OnHide, que la quita de su lista.
local LCB = LibStub and LibStub("LibCandyBar-3.0", true)
local function EsDeRXP(bar)
    local cont = RXPFrame and RXPFrame.BarContainer
    if not (cont and cont.bars) then return false end
    for _, b in pairs(cont.bars) do if b == bar then return true end end
    return false
end
--    2026-11-18: seguía saliendo con los vuelos. Al aterrizar, RestedXP solo OCULTA la barra del vuelo (la
--    quita de su lista) y la barra sigue contando; cuando se acaba, LibCandyBar la recicla y aquí ya no se
--    reconocía como de RestedXP. Ahora se apuntan todas las barras que devuelve RXP.StartTimer (mias) y
--    se rescatan siempre; además, antes de cada StartTimer se repasa que ninguna esté sin datos.
if LCB and LCB.RegisterCallback and LCB.barCache then
    local dueno = {}
    local mias = setmetatable({}, { __mode = "k" })   -- barras que son de RestedXP
    local onHideRXP                                    -- el OnHide que RestedXP pone a sus barras
    local function Rescatar(bar)
        LCB.barCache[bar] = nil
        bar.data = bar.data or { LCBiconPosition = "LEFT", LCBiconVisible = true,
            LCBtimeVisible = true, LCBlabelVisible = true }
        if onHideRXP and not bar:GetScript("OnHide") then bar:SetScript("OnHide", onHideRXP) end
    end
    LCB.RegisterCallback(dueno, "LibCandyBar_Stop", function(_, bar)
        local listada = EsDeRXP(bar)
        if not (listada or mias[bar]) then return end
        mias[bar] = true
        local onHide = bar:GetScript("OnHide")   -- se lee antes de que LibCandyBar borre los scripts
        onHideRXP = onHide or onHideRXP
        C_Timer.After(0, function()
            Rescatar(bar)
            -- Su OnHide la quita de la lista de RestedXP: solo si seguía en ella (si no, podría quitar a
            -- otra barra con el mismo nombre).
            if onHide and listada then pcall(onHide, bar) end
        end)
    end)
    if RXP and type(RXP.StartTimer) == "function" then
        local original = RXP.StartTimer
        RXP.StartTimer = function(...)
            for bar in pairs(mias) do
                if bar.data == nil then Rescatar(bar) end
            end
            local bar = original(...)
            if bar then
                mias[bar] = true
                onHideRXP = bar:GetScript("OnHide") or onHideRXP
            end
            return bar
        end
    end
end

-- 8) Sin «leones» (2026-11-17). En WoW Forever los adornos de los lados de la barra principal (EndCaps) son
--    sistemas propios del Modo edición: al separar las barras se quedan sueltos por la pantalla y no se
--    esconden. Se dejan transparentes y sin ratón (no se ocultan con Hide para no tocar la barra protegida).
local function SinLeones()
    for _, n in ipairs({ "MainActionBar", "MainMenuBar" }) do
        local caps = _G[n] and _G[n].EndCaps
        if caps then
            caps:SetAlpha(0)
            for _, c in ipairs({ caps.LeftEndCap, caps.RightEndCap }) do
                if c then
                    c:SetAlpha(0)
                    if c.Selection then c.Selection:SetAlpha(0); c.Selection:EnableMouse(false) end
                    if not c.elpingorSinLeon then
                        c.elpingorSinLeon = true
                        c:HookScript("OnShow", function(s) s:SetAlpha(0) end)
                        -- El Modo edición o el propio adorno pueden volver a darle opacidad: se deja a 0.
                        hooksecurefunc(c, "SetAlpha", function(s, a)
                            if a and a > 0 and not s.elpingorPoniendo then
                                s.elpingorPoniendo = true; s:SetAlpha(0); s.elpingorPoniendo = nil
                            end
                        end)
                    end
                end
            end
            if not caps.elpingorSinLeon then
                caps.elpingorSinLeon = true
                caps:HookScript("OnShow", function(s) s:SetAlpha(0) end)
            end
        end
    end
end
local leones = CreateFrame("Frame")
leones:RegisterEvent("PLAYER_LOGIN")
leones:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
leones:SetScript("OnEvent", function() SinLeones(); C_Timer.After(1, SinLeones) end)

-------------------------------------------------------------------------------
--  Glowing Bars (vuelve el 18-11): que NO toque el Cooldown Manager de Blizzard.
--  Por defecto («full») lo enciende al salir o recargar (SetCVar cooldownViewerEnabled=1, desde su
--  código: era el error de taint de CooldownViewer.lua:1691 del 15-11) y mueve sus ventanas. Nosotros
--  lo quitamos a propósito (v33). Con «off» solo pone sus brillos en los botones. Sus ajustes viven en
--  GlowingBarsCharDB (por personaje; es la misma tabla que lee el addon) y se repone al entrar y al salir.
-------------------------------------------------------------------------------
-- ElpingorUI carga antes (orden alfabético), así que en el ADDON_LOADED de GlowingBars esto corre ANTES
-- de que el addon copie su tabla guardada: lo que pongamos aquí es lo que lee desde el primer momento
-- (si no, con cooldownViewerEnabled=1, como en sus personajes, elegiría «full» y enseñaría las ventanas).
local function GlowSinCDM()
    local db = _G.GlowingBarsCharDB
    if type(db) ~= "table" then db = {}; _G.GlowingBarsCharDB = db end
    db.cooldownManagerAccess = "off"
    db.isCooldownManagerSetUp = true
    db.isCooldownManagerOurs = false
    db.trackedBuffsIcons, db.trackedBarsIcons, db.essentialIcons, db.utilityIcons = "hide", "hide", "hide", "hide"
end
local glow = CreateFrame("Frame")
glow:RegisterEvent("ADDON_LOADED")
glow:RegisterEvent("PLAYER_ENTERING_WORLD")
glow:RegisterEvent("PLAYER_LOGOUT")
glow:SetScript("OnEvent", function(_, ev, nombre)
    if ev == "ADDON_LOADED" and nombre ~= "GlowingBars" then return end
    if ev ~= "ADDON_LOADED" and type(_G.GlowingBarsCharDB) ~= "table" then return end -- sin GlowingBars, nada
    GlowSinCDM()
end)

-------------------------------------------------------------------------------
--  Profesiones sin repetir (18-11, al llegar Mastercraft). Una sola vez por cuenta; después manda lo que
--  cambie cada uno en las opciones de esos addons. Corre en el ADDON_LOADED de cada uno: ElpingorUI carga
--  antes (orden alfabético) y su tabla guardada ya está puesta, así que el addon lee esto desde el principio.
--   · Mastercraft: sin sus puntos de recolección (los pone GatherLite, con todos los del juego) y sin las
--     líneas de precio de Auctionator en el tooltip (Mastercraft ya enseña el precio, el más reciente de los dos).
--   · What's Training: sin su pestaña de profesiones (recetas y de dónde salen: lo hace el Codex de Mastercraft);
--     se queda para los hechizos de clase.
-------------------------------------------------------------------------------
local AJUSTES_PROF = {
    Mastercraft = function(m)
        _G.MastercraftDB = _G.MastercraftDB or {}
        local s = _G.MastercraftDB
        s.settings = s.settings or {}
        s.settings.nodesWhen = "never"
        s.settings.hideAuctionatorTips = true
    end,
    WhatsTraining = function() _G.WT_HideProfessionTab = true end,
}
local prof = CreateFrame("Frame")
prof:RegisterEvent("ADDON_LOADED")
prof:SetScript("OnEvent", function(_, _, nombre)
    local f = AJUSTES_PROF[nombre]
    if not f then return end
    ElpingorUIDB = ElpingorUIDB or {}
    ElpingorUIDB.profesiones1 = ElpingorUIDB.profesiones1 or {}
    if ElpingorUIDB.profesiones1[nombre] then return end
    ElpingorUIDB.profesiones1[nombre] = true
    f()
end)
