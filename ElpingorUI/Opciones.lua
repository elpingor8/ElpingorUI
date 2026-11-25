-- ElpingorUI · Opciones del juego (2.1): pone UNA vez por cuenta las opciones que recomienda la guía.
-- Si el jugador las cambia después, no se vuelven a tocar (se apunta la versión aplicada).
--   showSwingTimer 0   barra de ataque de Blizzard fuera (ElpingorUI trae la suya)
--   deselectOnClick 0  objetivo fijo: un clic en el suelo no lo quita
--   nameplateMotion 1  placas apiladas: se puede elegir objetivo en un grupo de gente

--   SoftTargetInteract 0  tecla de interactuar apagada (2: no lanza hechizos sola sobre PNJ cercanos)

-- 3.0 (lo aprendido de Skill Capped, ver el curso PvP en Obsidian):
--   autoSelfCast 1, lossOfControl 1, stopAutoAttackOnTargetChange 0, cámara lejos (2,6) y sin
--   reajuste, temblores al 25 %, sin burbujas de chat y sin voz de errores.
local VERSION = 8  -- 8: números de vida y maná siempre visibles (statusText); 7: sin iconos del soft targeting; 4: objetivo del objetivo; 5: fuera la pantalla de recursos personal; 6: nombres de aliados de EllesmereUI
local CVARS = {
    { "showSwingTimer",     "0", "barra de ataque de Blizzard oculta" },
    { "deselectOnClick",    "0", "objetivo fijo (un clic en el suelo no lo quita)" },
    { "nameplateMotion",    "1", "placas apiladas" },
    { "SoftTargetInteract", "0", "tecla de interactuar apagada" },
    { "autoSelfCast",                  "1",   "autolanzamiento propio" },
    { "lossOfControl",                 "1",   "aviso de pérdida de control" },
    { "stopAutoAttackOnTargetChange",  "0",   "el autoataque no se corta al cambiar de objetivo" },
    { "cameraDistanceMaxZoomFactor",   "2.6", "cámara a la máxima distancia" },
    { "cameraSmoothStyle",             "0",   "cámara sin reajuste automático" },
    { "ShakeStrengthCamera",           "0.25", "temblor de cámara al 25 %" },
    { "ShakeStrengthUI",               "0.25", "temblor de la interfaz al 25 %" },
    { "chatBubbles",                   "0",   "sin burbujas de chat" },
    { "chatBubblesParty",              "0",   "sin burbujas de chat de grupo" },
    { "Sound_EnableErrorSpeech",       "0",   "sin voz de errores" },
    { "statusTextDisplay",             "BOTH", "vida y maná con número y %" },
    { "statusText",                    "1",   "números siempre visibles en vida y maná" },   -- 8 (21-11: a Sara no le salían)
    { "showTargetOfTarget",            "1",   "objetivo del objetivo" },
    { "nameplateShowSelf",             "0",   "sin la pantalla de recursos personal (la vida y la energía ya están en tu marco)" },
    { "nameplateShowFriendlyPlayers",  "1",   "nombres de jugadores aliados con color de clase (EllesmereUI)" },
    { "nameplateShowOnlyNameForFriendlyPlayerUnits", "1", "aliados: solo el nombre, sin barra" },
    -- 7: Lueur usa el soft targeting y el juego ponía su icono encima: rombo en objetos y
    -- «?» repetido encima del PNJ de misión que tienes delante (Elpingor, 20-11).
    { "SoftTargetIconGameObject",      "0",   "sin el rombo encima de los objetos" },
    { "SoftTargetIconInteract",        "0",   "sin el icono repetido encima de los PNJ" },
}

local function Apply()
    ElpingorUIDB = ElpingorUIDB or {}
    if (ElpingorUIDB.cvarsVersion or 0) >= VERSION then return end
    if InCombatLockdown() then return false end
    local done = {}
    for _, c in ipairs(CVARS) do
        local name, value, what = c[1], c[2], c[3]
        if C_CVar.GetCVar(name) ~= nil then
            if C_CVar.GetCVar(name) ~= value then C_CVar.SetCVar(name, value) end
            done[#done + 1] = what
        end
    end
    ElpingorUIDB.cvarsVersion = VERSION
    if #done > 0 then
        print("|cff0cd29fElpingorUI|r: opciones puestas una vez: " .. table.concat(done, ", ") .. ".")
    end
    return true
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(self)
    if Apply() ~= false then self:UnregisterAllEvents() end
end)

-- Aliados solo con el nombre (16-11): algo del juego (p. ej. el atajo de nombres) lo vuelve a 0 y salen
-- barras azules vacías. Se vuelve a poner al entrar y tras cada pantalla de carga, fuera de combate.
-- 18-11: lo mismo con los nombres de aliados en sí (nameplateShowFriendlyPlayers): se volvió a apagar
-- y solo quedaban los nombres diminutos de Blizzard. Ahora se repone igual.
local NOMBRES = { "nameplateShowFriendlyPlayers", "nameplateShowOnlyNameForFriendlyPlayerUnits" }
local nombres = CreateFrame("Frame")
nombres:RegisterEvent("PLAYER_ENTERING_WORLD")
nombres:RegisterEvent("PLAYER_REGEN_ENABLED")
nombres:SetScript("OnEvent", function()
    if InCombatLockdown() or not (ElpingorUIDB and ElpingorUIDB.instalado) then return end
    for _, cv in ipairs(NOMBRES) do
        if C_CVar.GetCVar(cv) == "0" then C_CVar.SetCVar(cv, "1") end
    end
end)

-- «?» pequeño repetido encima del PNJ (21-11): Lueur guarda el SoftTargetIconInteract que había antes
-- (1) y lo vuelve a poner cada vez que se enciende. Se le cambia ese valor guardado a 0 en cuanto carga
-- (antes de que lo use) y, por si acaso, el CVar se repone a 0 al entrar y tras cada carga.
local function SinInteroga()
    local db = LueurDB
    if type(db) == "table" and type(db.savedCVars) == "table" and db.savedCVars.SoftTargetIconInteract == "1" then
        db.savedCVars.SoftTargetIconInteract = "0"
    end
    if not InCombatLockdown() and C_CVar.GetCVar("SoftTargetIconInteract") == "1" then
        C_CVar.SetCVar("SoftTargetIconInteract", "0")
    end
end
-- El «?» pequeño de verdad (21-11, 2.ª vez): es el aviso de misión de BetterBlizzPlates (questIndicator),
-- que pone el icono de entregar misión en la placa del PNJ, justo debajo del «?» del juego. Se apaga
-- UNA vez, antes del PLAYER_LOGIN de BBP (los enemigos de misión ya los marca Questie en su placa).
-- Si alguien lo vuelve a encender en /bbp, se respeta.
local function SinAvisoBBP()
    ElpingorUIDB = ElpingorUIDB or {}
    local db = BetterBlizzPlatesDB
    if ElpingorUIDB.bbpSinAvisoMision1 or type(db) ~= "table" then return end
    db.questIndicator = false
    ElpingorUIDB.bbpSinAvisoMision1 = true
end
local interoga = CreateFrame("Frame")
interoga:RegisterEvent("ADDON_LOADED")
interoga:RegisterEvent("PLAYER_ENTERING_WORLD")
interoga:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name == "Lueur" then pcall(SinInteroga) end
        if name == "ElpingorUI" or name == "BetterBlizzPlates" then pcall(SinAvisoBBP) end
        return
    end
    pcall(SinInteroga)
    C_Timer.After(3, function() pcall(SinInteroga) end)
end)

-- Sin OpenMap (21-11: daba un tirón cada vez que se abría el mapa, 510 MB de texturas): las funciones de
-- mapa de EllesmereUI que se dejaron apagadas por él se encienden UNA vez (coordenadas, ver zonas sin
-- explorar, marcadores de viaje y desvanecer el mapa al moverse). Con OpenMap activo no se toca nada.
local mapa = CreateFrame("Frame")
mapa:RegisterEvent("PLAYER_LOGIN")
mapa:SetScript("OnEvent", function()
    local db = EllesmereUIDB
    if type(db) ~= "table" or not (ElpingorUIDB and ElpingorUIDB.instalado) then return end
    if ElpingorUIDB.mapaSinOpenMap1 or C_AddOns.IsAddOnLoaded("OpenMap") then return end
    db.mapCoords = true
    for _, k in ipairs({ "worldMapReveal", "mapTravel", "worldMapFade" }) do
        if type(db[k]) ~= "table" then db[k] = {} end
        db[k].enabled = true
    end
    ElpingorUIDB.mapaSinOpenMap1 = true
    if EllesmereUI and EllesmereUI._applyMapCoords then pcall(EllesmereUI._applyMapCoords) end
    print("|cff0cd29fElpingorUI|r: mapa de EllesmereUI encendido (coordenadas, zonas sin explorar, marcadores y desvanecer). Haz /reload para verlo entero.")
end)

-- OpenMap aligerado (21-11): a Elpingor le gusta el mapa de una pieza, pero daba un tirón al abrirlo y
-- salía muy lleno. Se apaga UNA vez lo más pesado y lo repetido (se respeta si luego se vuelve a encender):
--   minimap/cityMinimap  las teselas del minimapa mezcladas al acercar (lo que más texturas carga)
--   allQuests            todas las misiones dibujadas (Questie ya las pone)
--   zoneLevels           niveles de zona (repetido con EllesmereUI)
--   dungeonBosses, friends, guild  jefes en el mapa de mazmorra y amigos/hermandad
--   townsfolk            solo posadero, reparar, instructores, banco y subastas
-- Y como OpenMap ya hace de mapa, las funciones de mapa de EllesmereUI se vuelven a apagar (marcadores,
-- desvanecer y coordenadas: OpenMap trae las suyas).
local function AligerarOpenMap()
    ElpingorUIDB = ElpingorUIDB or {}
    if ElpingorUIDB.openMapLigero1 or type(OpenMapDB) ~= "table" then return end
    OpenMapDB.worldmap = type(OpenMapDB.worldmap) == "table" and OpenMapDB.worldmap or {}
    local w = OpenMapDB.worldmap
    w.minimap, w.cityMinimap, w.gapMinimap = false, false, false
    w.allQuests, w.zoneLevels, w.dungeonBosses = false, false, false
    w.friends, w.guild = false, false
    w.townsfolk = { innkeeper = true, repair = true, classTrainer = true, profTrainer = true,
        banker = true, auctioneer = true, vendor = false, stable = false, rare = false,
        mailbox = false, spirit = false }
    local db = EllesmereUIDB
    if type(db) == "table" then
        db.mapCoords = false
        for _, k in ipairs({ "mapTravel", "worldMapFade" }) do
            if type(db[k]) == "table" then db[k].enabled = false end
        end
    end
    ElpingorUIDB.openMapLigero1 = true
    ElpingorUIDB.mapaSinOpenMap1 = true
    C_Timer.After(5, function()
        print("|cff0cd29fElpingorUI|r: OpenMap aligerado (sin teselas del minimapa, sin misiones repetidas con Questie y menos iconos de ciudad).")
    end)
end
local om = CreateFrame("Frame")
om:RegisterEvent("ADDON_LOADED")
om:SetScript("OnEvent", function(self, _, name)
    if name == "OpenMap" or (name == "ElpingorUI" and C_AddOns.IsAddOnLoaded("OpenMap")) then
        pcall(AligerarOpenMap)
    end
end)

-- Cola de hechizos según tu ping (2.4): SpellQueueWindow = ping de casa + 100 ms (entre 100 y 400).
-- Con más ping, el siguiente hechizo se encola antes y no se pierde tiempo entre lanzamientos.
-- Se mide sola al entrar y tras cada pantalla de carga, fuera de combate; solo cambia si se mueve
-- 20 ms o más. /ecola la apaga o la enciende (apagada, no se toca el valor que tengas).
local P = "|cff0cd29fElpingorUI|r: "
local colaAvisada = false

local function Cola(forzar)
    if ElpingorUIDB and ElpingorUIDB.colaOff then return end
    if InCombatLockdown() then return end
    local _, _, home = GetNetStats()
    if not home or home <= 0 then return end -- recién conectado: aún sin medida
    local nuevo = math.max(100, math.min(400, math.floor(home + 100)))
    local actual = tonumber(C_CVar.GetCVar("SpellQueueWindow")) or 0
    if not forzar and math.abs(nuevo - actual) < 20 then return end
    C_CVar.SetCVar("SpellQueueWindow", tostring(nuevo))
    if forzar or not colaAvisada then
        colaAvisada = true
        print(P .. ("cola de hechizos ajustada a tu ping: %d ms (ping %d + 100)."):format(nuevo, home))
    end
end

local cola = CreateFrame("Frame")
cola:RegisterEvent("PLAYER_ENTERING_WORLD")
cola:SetScript("OnEvent", function()
    -- El ping se estabiliza unos segundos después de cargar.
    C_Timer.After(10, function() Cola(false) end)
end)

SLASH_ELPINGORCOLA1 = "/ecola"
SlashCmdList.ELPINGORCOLA = function()
    ElpingorUIDB = ElpingorUIDB or {}
    ElpingorUIDB.colaOff = not ElpingorUIDB.colaOff or nil
    if ElpingorUIDB.colaOff then
        print(P .. "cola de hechizos automática apagada (se queda en " .. C_CVar.GetCVar("SpellQueueWindow") .. " ms).")
    else
        Cola(true)
    end
end
