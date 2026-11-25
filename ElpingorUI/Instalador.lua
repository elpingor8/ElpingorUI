-- ElpingorUI · Instalador dentro del juego (2.3).
-- Sale solo la primera vez (o con /elpingor). Detecta la pantalla, importa los perfiles de las 9 clases
-- en EllesmereUI con su función para instaladores (ImportProfileSilent) y pone los ajustes de Capping,
-- BattleGroundEnemies, ForeverCore, Questie y Attune. Antes guarda una copia para «Volver a mi interfaz».
-- Los datos están en Datos.lua (lo genera herramientas\generar_instalador.py).

local P = "|cff0cd29fElpingorUI|r: "

-- Questie: el perfil que trae el instalador ya dice «migraciones hechas», así que en un PC nuevo
-- Questie no crea sus tablas globales y falla al iniciar (lastKnownDailyReset nil). Las creamos antes.
-- 21-11: Questie está en OptionalDeps, así que carga ANTES que ElpingorUI y su ADDON_LOADED ya pasó
-- cuando llegamos (en el PC de Sara salía el error igual). Se arregla al cargar ElpingorUI y, por si
-- acaso, también en el ADDON_LOADED de Questie. Questie se inicia después (PLAYER_LOGIN).
do
    local function ArreglarQuestie()
        if type(QuestieConfig) ~= "table" then return end
        if type(QuestieConfig.global) ~= "table" then QuestieConfig.global = {} end
        local g = QuestieConfig.global
        for _, k in ipairs({ "lastKnownDailyReset", "unavailableQuestsDeterminedByTalking", "unavailableDailyQuestsByNpc" }) do
            if type(g[k]) ~= "table" then g[k] = {} end
        end
    end
    local q = CreateFrame("Frame")
    q:RegisterEvent("ADDON_LOADED")
    q:SetScript("OnEvent", function(self, _, name)
        if name == "Questie" or name == "ElpingorUI" then pcall(ArreglarQuestie) end
    end)
end

local ACCENT = { 0.05, 0.82, 0.62 }
-- Crédito informativo, sin pedir nada: Blizzard no permite anuncios ni pedir apoyo dentro de un addon.
local CREDITO = "Hecha por Elpingor  ·  Tutorial, ayuda y novedades: |cff0cd29fYouTube @elpingor8|r"
local REDES = "Instagram y TikTok: @elpingor8   ·   Twitch: twitch.tv/elpingor8"

local PANTALLAS = { "16-9", "21-9", "16-10" }
local NOMBRE_PANTALLA = { ["16-9"] = "Normal 16:9", ["21-9"] = "Panorámica 21:9", ["16-10"] = "16:10" }

local OTROS = {   -- variable global -> addon que la usa
    { var = "CappingSettings",       addon = "Capping",                  grupo = "bg" },
    { var = "BattleGroundEnemiesDB", addon = "BattleGroundEnemiesFixed", grupo = "bg" },
    { var = "ForeverCoreDB",         addon = "ForeverCore",              grupo = "misiones" },
    { var = "QuestieConfig",         addon = "Questie",                  grupo = "misiones" },
    { var = "Attune_DB",             addon = "Attune",                   grupo = "misiones" },
    { var = "BetterBlizzPlatesDB",   addon = "BetterBlizzPlates",        grupo = "interfaz" },   -- placas Skill Capped (20-11)
    { var = "DrpulseV2DB",           addon = "Drpulse",                  grupo = "bg" },         -- DR arriba de la placa
    { var = "BetterBlizzFramesDB",   addon = "BetterBlizzFrames",        grupo = "interfaz" },   -- BBF como el de Elpingor (21-11)
}

local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = DeepCopy(v) end
    return o
end

-- Escribe src dentro de dst sin cambiar las tablas que ya usa el addon (AceDB guarda referencias).
local function Merge(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then Merge(dst[k], v)
        else dst[k] = DeepCopy(v) end
    end
end

-- 21-11: BBF como el de Elpingor (dragón incluido) también para quien ya tenía ElpingorUI instalada:
-- se copia UNA vez al cargar, antes del PLAYER_LOGIN de BBF. Luego se respeta lo que cambies en /bbf.
do
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, _, name)
        if name ~= "ElpingorUI" then return end
        self:UnregisterAllEvents()
        local D = ElpingorUI_DATA
        local src = D and D.sv and D.sv["16-9"] and D.sv["16-9"].BetterBlizzFramesDB
        if not (ElpingorUIDB and ElpingorUIDB.instalado) or ElpingorUIDB.bbfElpingor1 then return end
        if type(src) ~= "table" or type(BetterBlizzFramesDB) ~= "table" then return end
        Merge(BetterBlizzFramesDB, src)
        ElpingorUIDB.bbfElpingor1 = true
    end)
end

local function DetectarPantalla()
    local w, h = GetPhysicalScreenSize()
    if not (w and h and h > 0) then return "16-9" end
    local r = w / h
    if r >= 2.1 then return "21-9" end
    if r <= 1.65 then return "16-10" end
    return "16-9"
end

local function Loaded(a) return C_AddOns.IsAddOnLoaded(a) end

-------------------------------------------------------------------------------
--  Addons de la interfaz Clásica (3.0). Se ENSEÑA la lista antes de aplicar (no como otros instaladores,
--  que apagan sin avisar). Los que sobran ya los hace EllesmereUI; solo se apagan, no se borran.
-------------------------------------------------------------------------------
local NECESARIOS = { "EllesmereUI", "EllesmereUIOptions", "EllesmereUILocales", "BetterBlizzPlates",
    "EllesmereUIUnitFrames", "EllesmereUIRaidFrames", "EllesmereUIMinimap",
    "EllesmereUIChat", "Baganator", "Syndicator", "EllesmereUIDamageMeters", "EllesmereUIQoL", "BetterBlizzFrames",
    "GearQuestForever" }                         -- 24-11: equipo para subir de nivel (más su módulo de clase, abajo)
-- 24-11: Naowh Forever es la pieza principal (todos sus módulos); EllesmereUI se queda con lo que Naowh no tiene.
local NECESARIOS_PREFIJOS = { "NaowhForever" }
-- 22-11: bolsas con Baganator (por categorías); la de EllesmereUI pasa a SOBRAN.
-- GlowingBars ya no sobra (18-11): vuelve a la lista, lo usan sus amigos guerreros.
local SOBRAN = { "SkillCapped", "EllesmereUINameplates", "MiniAuras", "oGlowClassic", "Leatrix_Maps",
    "Details", "Bagnon", "BagBrother", "MiniCC", "EllesmereUIActionBars",
    "ForeverProfessionMaster", "CraftProfit",   -- 18-11: los cubría Mastercraft; desde el 24-11, Naowh
    "EllesmereUIBags",                           -- 22-11: la cubre Baganator
    -- 24-11: lo que ya hace Naowh Forever (y el módulo de Naowh que lo hace)
    "ForeverDungeonJournal",                     -- Dungeon Journal
    "ForeverTrinketMenu",                        -- Gear & Trinkets
    "Attune", "RareScanner", "HandyNotes", "HandyNotes_ForeverBooks",   -- Discovery
    "Mastercraft", "Mastercraft_Inbox", "SkillUpForever",               -- Professions
    "Lueur", "ForeverLootSparkles",              -- Glimmer
    "ClassPetWatcher",                           -- aviso de mascota
    "Leatrix_Plus",                              -- sus automatismos los hace Naowh
    "EllesmereUIAuraBuffReminders", "EllesmereUIResourceBars",   -- recordatorio de bufos y swing timer de Naowh
    "EllesmereUIMythicTimer", "EllesmereUIQuickdraw" }           -- sin M+ en Forever; sin tecla
local SOBRAN_PREFIJOS = { "Details_", "Bagnon_" }
local POR_QUE = { EllesmereUIActionBars = "barras de Blizzard", EllesmereUINameplates = "placas con BetterBlizzPlates",
    ForeverProfessionMaster = "lo hace Naowh", CraftProfit = "lo hace Naowh",
    EllesmereUIBags = "bolsas con Baganator" }

local function Existe(a)
    local _, _, _, _, reason = C_AddOns.GetAddOnInfo(a)
    return reason ~= "MISSING"
end
-- Cargado en esta sesión (fiable). GetAddOnEnableState no coincidía con lo cargado en WoW Forever.
local function Encendido(a) return C_AddOns.IsAddOnLoaded(a) and true or false end

local function PlanAddons()
    local encender, apagar, visto = {}, {}, {}
    local function Falta(a)
        if not visto[a] and Existe(a) and not Encendido(a) then visto[a] = true; encender[#encender + 1] = a end
    end
    for _, a in ipairs(NECESARIOS) do Falta(a) end
    local _, clase = UnitClass("player")
    if clase then Falta("GearQuestForever_" .. clase) end      -- el módulo de GearQuest de su clase
    local total = C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or 0
    for i = 1, total do
        local name = C_AddOns.GetAddOnInfo(i)
        for _, pre in ipairs(NECESARIOS_PREFIJOS) do
            if name and name:sub(1, #pre) == pre then Falta(name) end
        end
    end
    local function Sobra(a)
        if not visto[a] and Existe(a) and Encendido(a) then visto[a] = true; apagar[#apagar + 1] = a end
    end
    for _, a in ipairs(SOBRAN) do Sobra(a) end
    local n = C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or 0
    for i = 1, n do
        local name = C_AddOns.GetAddOnInfo(i)
        for _, pre in ipairs(SOBRAN_PREFIJOS) do
            if name and name:sub(1, #pre) == pre then Sobra(name) end
        end
    end
    return encender, apagar
end

local function TextoPlan()
    local encender, apagar = PlanAddons()
    if #encender == 0 and #apagar == 0 then return "Tus addons ya están como hacen falta." end
    local t = {}
    if #apagar > 0 then t[#t + 1] = "Se apagan (ya lo hacen Naowh Forever o EllesmereUI): " .. table.concat(apagar, ", ") end
    if #encender > 0 then t[#t + 1] = "Se encienden: " .. table.concat(encender, ", ") end
    return table.concat(t, "\n")
end

local function AplicarAddons()
    local encender, apagar = PlanAddons()
    for _, a in ipairs(encender) do C_AddOns.EnableAddOn(a) end
    for _, a in ipairs(apagar) do C_AddOns.DisableAddOn(a) end
    return #encender + #apagar
end

-------------------------------------------------------------------------------
--  Naowh Forever y compañía (24-11). Regla de Elpingor: lo que hace Naowh, lo hace Naowh; EllesmereUI y los
--  demás se quedan con lo que Naowh no tiene. Todo se escribe en sus tablas y vale tras el ReloadUI.
-------------------------------------------------------------------------------
-- Ajustes que no dependen del perfil: también los pone /elpingor fix.
local EUI_REPETIDOS = { "autoSellJunk", "quickLoot", "repairWarning", "autoRepair", "autoFillDelete",
    "autoGossip", "hideScreenshotStatus", "talentAlertEnabled" }   -- los hace Naowh (vender, botín, reparar...)
local function AjustesFijos()
    local n = 0
    if Loaded("NaowhForever") and type(NaowhForeverDB) == "table" then
        NaowhForeverDB.account = NaowhForeverDB.account or {}
        NaowhForeverDB.account.onboardingSeen = true      -- sin la ventana de bienvenida: ya viene configurado
        NaowhForeverDB.account.welcomeSeen = true
        n = n + 1
    end
    if Loaded("EllesmereUI") and type(EllesmereUIDB) == "table" then
        for _, k in ipairs(EUI_REPETIDOS) do EllesmereUIDB[k] = false end
        for _, k in ipairs({ "lootFeed", "flightTimer" }) do
            if type(EllesmereUIDB[k]) ~= "table" then EllesmereUIDB[k] = {} end
            EllesmereUIDB[k].enabled = false
        end
        n = n + 1
    end
    -- ProcDoc necesita el Cooldown Manager del juego encendido; se queda funcionando pero invisible.
    -- (cdmShownByDefault: si falta, ProcDoc vuelve a enseñarlo al cargar.) Vale para toda la cuenta.
    if Loaded("ProcDoc") and type(ProcDocDB) == "table" then
        ProcDocDB.globalVars = ProcDocDB.globalVars or {}
        ProcDocDB.globalVars.cdmHideBuffs = true
        ProcDocDB.globalVars.cdmShownByDefault = true
        n = n + 1
    end
    return n
end

-- El perfil de Naowh de Elpingor (Datos.lua, naowh) dentro del perfil que usa este personaje.
local function PerfilNaowh(datos)
    if not (datos and Loaded("NaowhForever") and type(NaowhForeverDB) == "table") then return false end
    local api = _G.NaowhForever_API
    local nombre = api and api.GetCurrentProfileKey and api:GetCurrentProfileKey() or "Default"
    NaowhForeverDB.profiles = NaowhForeverDB.profiles or {}
    if type(NaowhForeverDB.profiles[nombre]) ~= "table" then NaowhForeverDB.profiles[nombre] = {} end
    Merge(NaowhForeverDB.profiles[nombre], DeepCopy(datos))
    return true
end

-- Diseño del Modo edición de la Clásica (cadena exportada en Datos.lua, si la hay): se añade a los diseños
-- de la cuenta con el nombre «ElpingorUI Clásica» y Clasica.lua lo activa en el siguiente arranque.
local DISENO = "ElpingorUI Clásica"
local function ImportarDiseno(str)
    if type(str) ~= "string" or str == "" then return false end
    -- Mejor con la función de EllesmereUI (adapta el diseño, respeta el máximo de diseños y lo activa;
    -- Instalar recarga justo después, como pide para no dejar el Modo edición contaminado).
    if EllesmereUI and EllesmereUI.ApplyPresetEditMode then
        return EllesmereUI.ApplyPresetEditMode(str, DISENO) and "activo" or false
    end
    if not (C_EditMode and C_EditMode.ConvertStringToLayoutInfo and C_EditMode.GetLayouts) then return false end
    local info = C_EditMode.GetLayouts()
    if not (info and info.layouts) then return false end
    for _, l in ipairs(info.layouts) do if l.layoutName == DISENO then return true end end
    local ok, nuevo = pcall(C_EditMode.ConvertStringToLayoutInfo, str)
    if not (ok and nuevo) then return false end
    nuevo.layoutName = DISENO
    nuevo.layoutType = Enum and Enum.EditModeLayoutType and Enum.EditModeLayoutType.Account or nuevo.layoutType
    info.layouts[#info.layouts + 1] = nuevo
    C_EditMode.SaveLayouts(info)
    return true
end

-------------------------------------------------------------------------------
--  Instalar / volver
-------------------------------------------------------------------------------
local function GuardarCopia()
    local db = EllesmereUIDB
    local copia = { fecha = date("%Y-%m-%d %H:%M"), sv = {} }
    if db then
        copia.activeProfile = db.activeProfile
        copia.specProfiles = DeepCopy(db.specProfiles)
        copia.ppUIScale = db.ppUIScale
    end
    for _, o in ipairs(OTROS) do copia.sv[o.var] = DeepCopy(_G[o.var]) end
    -- 3.0: estado de los addons que el instalador puede tocar, para devolverlos al volver
    copia.addons = {}
    local encender, apagar = PlanAddons()
    for _, a in ipairs(encender) do copia.addons[a] = false end
    for _, a in ipairs(apagar) do copia.addons[a] = true end
    -- 24-11: el perfil de Naowh que tenía este personaje, para devolverlo al volver
    local api = _G.NaowhForever_API
    if type(NaowhForeverDB) == "table" and type(NaowhForeverDB.profiles) == "table" then
        local nombre = api and api.GetCurrentProfileKey and api:GetCurrentProfileKey() or "Default"
        copia.naowh = { nombre = nombre, perfil = DeepCopy(NaowhForeverDB.profiles[nombre]) }
    end
    ElpingorUIDB.copia = copia
end

local function Instalar(pantalla, opc)
    if InCombatLockdown() then print(P .. "sal de combate para instalar.") return end
    local D = ElpingorUI_DATA
    if not D then print(P .. "faltan los datos del instalador (Datos.lua).") return end
    ElpingorUIDB = ElpingorUIDB or {}
    if not ElpingorUIDB.copia then GuardarCopia() end   -- la copia es de lo que había ANTES de ElpingorUI

    local fallos = {}
    if opc.interfaz then
        if not (EllesmereUI and EllesmereUI.ImportProfileSilent) then
            fallos[#fallos + 1] = "EllesmereUI no está cargado"
        else
            if EllesmereUI.RegisterExternalInstaller then EllesmereUI.RegisterExternalInstaller("ElpingorUI") end
            for _, e in ipairs(D.eui[pantalla]) do
                local ok, err = EllesmereUI.ImportProfileSilent({
                    importString = e.str, profileName = e.name,
                    applyUIScale = true, autoAssignSpecs = true, cleanSlate = true,
                })
                if not ok then fallos[#fallos + 1] = e.name .. " (" .. tostring(err) .. ")" end
            end
        end
    end
    local sv = D.sv[pantalla]
    for _, o in ipairs(OTROS) do
        if opc[o.grupo] and sv[o.var] and Loaded(o.addon) then
            if type(_G[o.var]) ~= "table" then _G[o.var] = {} end
            Merge(_G[o.var], sv[o.var])
        end
    end
    if #fallos > 0 then
        print(P .. "no se pudo instalar: " .. table.concat(fallos, ", ") .. ". Haz una captura y mándasela a Elpingor.")
        return
    end
    if opc.addons then AplicarAddons() end
    if opc.interfaz then
        PerfilNaowh(D.naowh)   -- (Datos.lua anteriores al 24-11 no lo traen: entonces no se toca Naowh)
        AjustesFijos()
    end
    if opc.interfaz then
        local r = ImportarDiseno(D.editmode)
        if r == "activo" then ElpingorUIDB.disenoClasica30 = true      -- ya activo; se recarga abajo
        elseif r then ElpingorUIDB.disenoClasica30 = nil end            -- que Clasica.lua lo ofrezca al recargar
    end
    ElpingorUIDB.bbfEstilo = nil             -- el estilo de BBF se vuelve a poner (Estilo.lua)
    ElpingorUIDB.instalado = { version = C_AddOns.GetAddOnMetadata("ElpingorUI", "Version"), pantalla = pantalla,
        fecha = date("%Y-%m-%d %H:%M"), addons = opc.addons and true or false }
    ElpingorUIDB.omitido = nil
    ReloadUI()
end

local function Volver()
    if InCombatLockdown() then print(P .. "sal de combate.") return end
    local c = ElpingorUIDB and ElpingorUIDB.copia
    if not c then print(P .. "no hay copia guardada.") return end
    local db = EllesmereUIDB
    if db then
        db.specProfiles = DeepCopy(c.specProfiles) or {}
        db.ppUIScale = c.ppUIScale
        if c.activeProfile and db.profiles and db.profiles[c.activeProfile] then db.activeProfile = c.activeProfile end
    end
    for _, o in ipairs(OTROS) do
        if Loaded(o.addon) then
            local old = c.sv[o.var]
            local cur = _G[o.var]
            if type(cur) == "table" and type(old) == "table" then
                for k in pairs(cur) do cur[k] = nil end
                Merge(cur, old)
            else
                _G[o.var] = DeepCopy(old)
            end
        end
    end
    for a, on in pairs(c.addons or {}) do
        if on then C_AddOns.EnableAddOn(a) else C_AddOns.DisableAddOn(a) end
    end
    if c.naowh and type(c.naowh.perfil) == "table" and type(NaowhForeverDB) == "table"
        and type(NaowhForeverDB.profiles) == "table" then
        local cur = NaowhForeverDB.profiles[c.naowh.nombre]
        if type(cur) == "table" then
            for k in pairs(cur) do cur[k] = nil end
            Merge(cur, c.naowh.perfil)
        else
            NaowhForeverDB.profiles[c.naowh.nombre] = DeepCopy(c.naowh.perfil)
        end
    end
    ElpingorUIDB.instalado = nil
    ElpingorUIDB.copia = nil
    ElpingorUIDB.omitido = true
    ReloadUI()
end

-------------------------------------------------------------------------------
--  Ventana
-------------------------------------------------------------------------------
local win
local function Texto(parent, size, txt, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    local font = fs:GetFont()
    fs:SetFont(font, size, "")
    fs:SetText(txt)
    if r then fs:SetTextColor(r, g, b) end
    return fs
end

local function Boton(parent, w, txt, fn)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, 26)
    b:SetText(txt)
    b:SetScript("OnClick", fn)
    return b
end

local function Casilla(parent, txt, sub)
    local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    c:SetSize(26, 26)
    c:SetChecked(true)
    local t = Texto(c, 13, txt)
    t:SetPoint("LEFT", c, "RIGHT", 4, 6)
    local s = Texto(c, 11, sub, 0.7, 0.7, 0.7)
    s:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -2)
    return c
end

local function Crear()
    win = CreateFrame("Frame", "ElpingorUIInstalador", UIParent, "BackdropTemplate")
    win:SetSize(560, 520)
    win:SetPoint("CENTER", 0, 40)
    win:SetFrameStrata("DIALOG")
    win:SetMovable(true); win:EnableMouse(true); win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving); win:SetScript("OnDragStop", win.StopMovingOrSizing)
    win:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    win:SetBackdropColor(0.04, 0.05, 0.07, 0.96)
    win:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.9)
    tinsert(UISpecialFrames, "ElpingorUIInstalador")   -- se cierra con Esc

    local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    local title = Texto(win, 26, "ElpingorUI", ACCENT[1], ACCENT[2], ACCENT[3])
    title:SetPoint("TOP", 0, -18)
    local ver = Texto(win, 11, "Instalador · versión " .. (C_AddOns.GetAddOnMetadata("ElpingorUI", "Version") or "?"), 0.7, 0.7, 0.7)
    ver:SetPoint("TOP", title, "BOTTOM", 0, -2)
    local credito = Texto(win, 12, CREDITO)
    credito:SetPoint("TOP", ver, "BOTTOM", 0, -10)
    local redes = Texto(win, 11, REDES, 0.7, 0.7, 0.7)
    redes:SetPoint("TOP", credito, "BOTTOM", 0, -4)

    -- Pantalla
    local lp = Texto(win, 13, "Tu pantalla:")
    lp:SetPoint("TOPLEFT", 28, -128)
    win.pantalla = DetectarPantalla()
    win.botonesPantalla = {}
    local prev
    for _, k in ipairs(PANTALLAS) do
        local b = Boton(win, 130, NOMBRE_PANTALLA[k], function()
            win.pantalla = k; win:Refrescar()
        end)
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 8, 0) else b:SetPoint("TOPLEFT", lp, "BOTTOMLEFT", 0, -6) end
        win.botonesPantalla[k] = b
        prev = b
    end
    local auto = Texto(win, 11, "(detectada sola; cámbiala si no es la tuya)", 0.7, 0.7, 0.7)
    auto:SetPoint("TOPLEFT", win.botonesPantalla["16-9"], "BOTTOMLEFT", 0, -4)

    -- Qué instalar
    win.cInterfaz = Casilla(win, "Interfaz Clásica", "Naowh Forever configurado como el de Elpingor; marcos y barras de Blizzard con el estilo de ElpingorUI; placas, grupo, chat, minimapa y medidores (EllesmereUI), para las 9 clases")
    win.cInterfaz:SetPoint("TOPLEFT", 26, -205)
    win.cBG = Casilla(win, "Campos de batalla y arena", "Tiempos de bases (Capping) y barras de los enemigos con abalorio y DR (BattleGroundEnemies)")
    win.cBG:SetPoint("TOPLEFT", win.cInterfaz, "BOTTOMLEFT", 0, -14)
    win.cMis = Casilla(win, "Misiones", "Questie, Attune y la columna de reagentes, colocados")
    win.cMis:SetPoint("TOPLEFT", win.cBG, "BOTTOMLEFT", 0, -14)
    win.cAddons = Casilla(win, "Addons", "Encender los que hacen falta y apagar los que sobran (no se borra nada):")
    win.cAddons:SetPoint("TOPLEFT", win.cMis, "BOTTOMLEFT", 0, -14)
    win.lAddons = Texto(win, 11, "", 0.85, 0.75, 0.5)
    win.lAddons:SetPoint("TOPLEFT", win.cAddons, "BOTTOMLEFT", 30, -4)
    win.lAddons:SetWidth(490)
    if win.lAddons.SetJustifyH then win.lAddons:SetJustifyH("LEFT") end

    local nota = Texto(win, 11, "Se recarga la interfaz al terminar. Lo de antes se guarda: puedes volver cuando quieras.", 0.7, 0.7, 0.7)
    nota:SetPoint("BOTTOM", 0, 58)

    win.instalar = Boton(win, 200, "Instalar", function()
        Instalar(win.pantalla, { interfaz = win.cInterfaz:GetChecked(), bg = win.cBG:GetChecked(),
            misiones = win.cMis:GetChecked(), addons = win.cAddons:GetChecked() })
    end)
    win.instalar:SetPoint("BOTTOM", 0, 20)
    win.ahora = Boton(win, 110, "Ahora no", function()
        ElpingorUIDB.omitido = true; win:Hide()
        print(P .. "puedes abrir el instalador cuando quieras con /elpingor")
    end)
    win.ahora:SetPoint("RIGHT", win.instalar, "LEFT", -10, 0)
    win.volver = Boton(win, 150, "Volver a mi interfaz", Volver)
    win.volver:SetPoint("LEFT", win.instalar, "RIGHT", 10, 0)

    function win:Refrescar()
        for k, b in pairs(self.botonesPantalla) do
            if k == self.pantalla then b:LockHighlight() else b:UnlockHighlight() end
        end
        self.volver:SetEnabled(ElpingorUIDB.copia ~= nil)
        local inst = ElpingorUIDB.instalado
        local nueva = inst and inst.version ~= C_AddOns.GetAddOnMetadata("ElpingorUI", "Version")
        self.instalar:SetText(not inst and "Instalar" or nueva and "Actualizar" or "Reinstalar")
        self.lAddons:SetText(TextoPlan())
    end
end

-- /elpingor fix: arreglo rápido sin reinstalar: addons de la Clásica, estilo de BBF y diseño del Modo edición.
StaticPopupDialogs["ELPINGORUI_RECARGAR_FIX"] = {
    text = "ElpingorUI: arreglo preparado.\nRecarga para aplicarlo.",
    button1 = "Recargar", button2 = "Luego",
    OnAccept = function() ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}
local function Arreglar()
    if InCombatLockdown() then print(P .. "sal de combate.") return end
    ElpingorUIDB = ElpingorUIDB or {}
    local n = AplicarAddons()
    AjustesFijos()   -- 24-11: sin repetidos entre Naowh y EllesmereUI, Cooldown Manager oculto (no toca el perfil de Naowh)
    ElpingorUIDB.bbfEstilo = nil
    ElpingorUIDB.disenoClasica30 = nil
    print(P .. "arreglo: " .. n .. " addons ajustados; el estilo y el diseño de la Clásica se vuelven a poner al recargar.")
    StaticPopup_Show("ELPINGORUI_RECARGAR_FIX")
end

local function Abrir()
    ElpingorUIDB = ElpingorUIDB or {}
    if not win then Crear() end
    win:Refrescar()
    win:Show()
end

SLASH_ELPINGORUI1 = "/elpingor"
SLASH_ELPINGORUI2 = "/elpingorui"
SlashCmdList.ELPINGORUI = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "fix" or msg == "arreglar" then Arreglar() else Abrir() end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    ElpingorUIDB = ElpingorUIDB or {}
    if ElpingorUIDB.instalado and ElpingorUIDB.instalado.fecha and not ElpingorUIDB.instalado.avisado then
        ElpingorUIDB.instalado.avisado = true
        print(P .. "instalada (pantalla " .. NOMBRE_PANTALLA[ElpingorUIDB.instalado.pantalla] .. "). Instalador: /elpingor")
    end
    -- Versión nueva del addon: se avisa una vez por versión (no se instala sola).
    local actual = C_AddOns.GetAddOnMetadata("ElpingorUI", "Version")
    local inst = ElpingorUIDB.instalado
    -- En el PC de Elpingor (ElpingorUIDB.autor) los perfiles del paquete salen de los suyos: «Actualizar»
    -- le pondría encima la copia genérica (18-11 le movió cosas). Ahí la versión se apunta sin avisar.
    if inst and ElpingorUIDB.autor and inst.version ~= actual then inst.version = actual end
    if inst and inst.version ~= actual and ElpingorUIDB.avisoVersion ~= actual then
        ElpingorUIDB.avisoVersion = actual
        print(P .. "versión " .. tostring(actual) .. " (tenías la " .. tostring(inst.version) .. "): novedades en el "
            .. "instalador. Abre /elpingor y pulsa «Actualizar» cuando quieras. Si algo se ve mal: /elpingor fix")
    end
    if not ElpingorUIDB.instalado and not ElpingorUIDB.omitido then C_Timer.After(2, Abrir) end
end)

ElpingorUI_Instalador = { Instalar = Instalar, Volver = Volver, DetectarPantalla = DetectarPantalla, Abrir = Abrir,
    PlanAddons = PlanAddons, Arreglar = Arreglar, ImportarDiseno = ImportarDiseno }
