-- ElpingorUI · Opciones del juego (2.1): pone UNA vez por cuenta las opciones que recomienda la guía.
-- Si el jugador las cambia después, no se vuelven a tocar (se apunta la versión aplicada).
--   showSwingTimer 0   barra de ataque de Blizzard fuera (ElpingorUI trae la suya)
--   deselectOnClick 0  objetivo fijo: un clic en el suelo no lo quita
--   nameplateMotion 1  placas apiladas: se puede elegir objetivo en un grupo de gente

--   SoftTargetInteract 0  tecla de interactuar apagada (2: no lanza hechizos sola sobre PNJ cercanos)

-- 3.0 (lo aprendido de Skill Capped, ver el curso PvP en Obsidian):
--   autoSelfCast 1, lossOfControl 1, stopAutoAttackOnTargetChange 0, cámara lejos (2,6) y sin
--   reajuste, temblores al 25 %, sin burbujas de chat y sin voz de errores.
local VERSION = 6  -- 4: objetivo del objetivo; 5: fuera la pantalla de recursos personal; 6: nombres de aliados de EllesmereUI
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
    { "showTargetOfTarget",            "1",   "objetivo del objetivo" },
    { "nameplateShowSelf",             "0",   "sin la pantalla de recursos personal (la vida y la energía ya están en tu marco)" },
    { "nameplateShowFriendlyPlayers",  "1",   "nombres de jugadores aliados con color de clase (EllesmereUI)" },
    { "nameplateShowOnlyNameForFriendlyPlayerUnits", "1", "aliados: solo el nombre, sin barra" },
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
local nombres = CreateFrame("Frame")
nombres:RegisterEvent("PLAYER_ENTERING_WORLD")
nombres:RegisterEvent("PLAYER_REGEN_ENABLED")
nombres:SetScript("OnEvent", function()
    if InCombatLockdown() or not (ElpingorUIDB and ElpingorUIDB.instalado) then return end
    if C_CVar.GetCVar("nameplateShowOnlyNameForFriendlyPlayerUnits") == "0" then
        C_CVar.SetCVar("nameplateShowOnlyNameForFriendlyPlayerUnits", "1")
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
