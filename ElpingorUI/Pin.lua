-- ElpingorUI · Pin (antes el addon ElpingorPin 1.0): sigue la flecha de RestedXP y pone el pin de
-- mapa de Blizzard en su destino (mapa, minimapa y marcador en pantalla con la distancia). Al acabar
-- el paso lo quita. No toca RestedXP: solo lee su flecha (RXP.arrowFrame.element).
-- Sin RestedXP (p. ej. el paquete de su esposa) se apaga sin decir nada.
-- /epin enciende o apaga (ElpingorPinDB, mismo nombre que antes para no perder el ajuste).

local TAG = "|cff0cd29fElpingorUI|r: "
local CHECK_EVERY = 0.5

local HBD = LibStub and LibStub("HereBeDragons-2.0", true)
local ours        -- pin puesto por este addon: { map, x, y }
local lastElement -- destino de la flecha que ya hemos marcado

local function Enabled() return not (ElpingorPinDB and ElpingorPinDB.off) end

local function InPvP()
    local inInst, t = IsInInstance()
    return inInst and (t == "pvp" or t == "arena")
end

-- ¿El pin que hay ahora es el nuestro? (para no borrar uno que pusiste tú a mano)
local function PinIsOurs()
    if not (ours and C_Map.HasUserWaypoint()) then return false end
    local p = C_Map.GetUserWaypoint()
    return p and p.uiMapID == ours.map
        and math.abs(p.position.x - ours.x) < 0.002
        and math.abs(p.position.y - ours.y) < 0.002
end

local function ClearOurs()
    if PinIsOurs() then C_Map.ClearUserWaypoint() end
    ours = nil
end

-- Destino en coordenadas de un mapa donde se pueda poner pin: primero la zona del paso (así,
-- si el destino está en otra zona, el pin va en el mapa de esa zona y no en el del continente),
-- luego el mapa en el que estás, y si cae fuera, sus mapas padre (zona -> continente).
local function MapPoint(el)
    if not (HBD and el.wx and el.wy) then return end
    local tried = {}
    local function try(map)
        while map and map > 0 and not tried[map] do
            tried[map] = true
            if C_Map.CanSetUserWaypointOnMap(map) then
                local x, y = HBD:GetZoneCoordinatesFromWorld(el.wx, el.wy, map)
                if x and y then return map, x, y end
            end
            local info = C_Map.GetMapInfo(map)
            map = info and info.parentMapID
        end
    end
    local m, x, y
    if type(el.zone) == "number" then m, x, y = try(el.zone) end
    if not m then m, x, y = try(C_Map.GetBestMapForUnit("player")) end
    return m, x, y
end

local function ActiveElement()
    local af = RXP and RXP.arrowFrame
    local el = af and af.element
    if not (el and af:IsShown()) then return end
    local step = el.step
    if step and not step.active then return end
    if el.completed or el.skip then return end
    if el.parent and type(el.parent) == "table" and (el.parent.completed or el.parent.skip) then return end
    return el
end

local function Update()
    if not Enabled() or InPvP() then
        if ours then ClearOurs() end
        lastElement = nil
        return
    end
    local el = ActiveElement()
    if not el then
        if ours then ClearOurs() end
        lastElement = nil
        return
    end
    -- La propia guía ya puso su pin en este paso: no lo pisamos.
    if el.waypointSet then lastElement = el; ours = nil; return end
    if el == lastElement then return end

    local map, x, y = MapPoint(el)
    if not map then return end -- otro continente o mapa sin pin: se reintenta en el siguiente repaso
    -- Si pusiste un pin a mano (no es el nuestro), solo lo cambiamos al pasar a otro destino.
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x, y))
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end
    ours = { map = map, x = x, y = y }
    lastElement = el
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    ElpingorPinDB = ElpingorPinDB or {}
    if not RXP then return end   -- sin RestedXP: módulo apagado, en silencio
    if not (C_Map and C_Map.SetUserWaypoint and UiMapPoint and HBD) then
        print(TAG .. "este cliente no permite pines de mapa o falta RestedXP; no hace nada.")
        return
    end
    C_Timer.NewTicker(CHECK_EVERY, Update)
end)

SLASH_ELPINGORPIN1 = "/epin"
SlashCmdList.ELPINGORPIN = function()
    ElpingorPinDB = ElpingorPinDB or {}
    if not RXP then
        print(TAG .. "el pin de mapa sigue a la flecha de RestedXP, y RestedXP no está instalado: no hace nada.")
        return
    end
    ElpingorPinDB.off = not ElpingorPinDB.off
    if ElpingorPinDB.off then
        ClearOurs(); lastElement = nil
        print(TAG .. "apagado. Escribe /epin para encenderlo.")
    else
        lastElement = nil
        print(TAG .. "encendido: el pin sigue a la flecha de RestedXP.")
    end
end
