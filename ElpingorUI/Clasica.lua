-- ElpingorUI · Interfaz Clásica fija (3.0). Ya no hay variante Moderna:
--   marcos y barras de acción de Blizzard (con BetterBlizzFrames y el estilo de Estilo.lua)
--   y EllesmereUI para todo lo demás (placas, grupo, minimapa, chat, bolsas, medidores, auras...).
-- Solo actúa si ElpingorUI está instalada (ElpingorUIDB.instalado; «Volver» lo borra) y el jugador no
-- desmarcó «Addons» en el instalador:
--   · comprueba que BBF está encendido y las barras de EllesmereUI apagadas;
--   · enciende una vez el mapa sin niebla de EllesmereUI (en lugar de Leatrix_Maps);
--   · ofrece activar una vez el diseño del Modo edición «ElpingorUI Clásica». Se activa AL PULSAR
--     «Recargar» y se recarga en el acto: activar un diseño desde un addon deja el Modo edición
--     contaminado hasta recargar, así que nunca se deja activado en una sesión abierta.

local P = "|cff0cd29fElpingorUI|r: "
local DISENO = "ElpingorUI Clásica"
local ENCENDER = { "BetterBlizzFrames" }
local APAGAR = { "EllesmereUIActionBars" }

local function Exists(name)
    local _, _, _, _, reason = C_AddOns.GetAddOnInfo(name)
    return reason ~= "MISSING"
end

-- Lo que cuenta es si está CARGADO en esta sesión (seguro). GetAddOnEnableState daba un estado que no
-- coincidía con lo cargado en WoW Forever y pedía recargar en bucle (2026-11-16).
local function Loaded(name)
    return C_AddOns.IsAddOnLoaded(name) and true or false
end

-- «Volver a mi interfaz» borra ElpingorUIDB.instalado; «omitido» solo significa «no abrir el instalador solo».
local function Activa()
    local db = ElpingorUIDB
    return db and db.instalado and db.instalado.addons ~= false
end

-- Addons de la Clásica. Devuelve true si hace falta recargar.
-- Freno anti-bucle: cada cambio se pide como mucho UNA vez. Si tras recargar sigue igual (el juego no lo
-- aplicó), no se vuelve a pedir: se avisa en el chat y se deja estar.
local function Addons()
    ElpingorUIDB = ElpingorUIDB or {}
    local hecho = ElpingorUIDB.addonsPedido or {}
    ElpingorUIDB.addonsPedido = hecho
    local cambio, atascado = false, {}
    local function Pedir(a, encender)
        local clave = a .. (encender and ":on" or ":off")
        if hecho[clave] then atascado[#atascado + 1] = a; return end
        hecho[clave] = true
        if encender then C_AddOns.EnableAddOn(a) else C_AddOns.DisableAddOn(a) end
        cambio = true
    end
    for _, a in ipairs(ENCENDER) do
        if Exists(a) and not Loaded(a) then Pedir(a, true) end
    end
    for _, a in ipairs(APAGAR) do
        if Exists(a) and Loaded(a) then Pedir(a, false) end
    end
    -- Lo que ya está bien deja de contar como pedido (por si un día hay que volver a pedirlo).
    for _, a in ipairs(ENCENDER) do if Loaded(a) then hecho[a .. ":on"] = nil end end
    for _, a in ipairs(APAGAR) do if Exists(a) and not Loaded(a) then hecho[a .. ":off"] = nil end end
    if cambio then print(P .. "addons de la interfaz Clásica ajustados (BetterBlizzFrames, barras de Blizzard).") end
    if #atascado > 0 then
        print(P .. "no he podido cambiar " .. table.concat(atascado, ", ") .. ". Míralo en el botón «AddOns» "
            .. "de la pantalla de personajes.")
    end
    return cambio
end

-- Barras de acción 2, 3 y 4 encendidas como en el brujo (16-11). Qué barras se ven es un ajuste de CADA
-- personaje (CVar enableMultiActionBars: 1 = abajo izquierda, 2 = abajo derecha, 4 = derecha) y en los
-- demás personajes estaba a 0: el druida salía con una sola barra. Una vez por personaje; luego se respeta
-- lo que elija en Opciones > Barras de acción. Devuelve true si cambió (se ve al recargar).
local BARRAS = 7
local function Barras()
    ElpingorUIDB = ElpingorUIDB or {}
    local yo = (UnitName("player") or "?") .. "-" .. (GetRealmName and GetRealmName() or "")
    ElpingorUIDB.barras30 = type(ElpingorUIDB.barras30) == "table" and ElpingorUIDB.barras30 or {}
    if ElpingorUIDB.barras30[yo] or InCombatLockdown() or not (C_CVar and C_CVar.GetCVar) then return false end
    ElpingorUIDB.barras30[yo] = true
    local actual = tonumber(C_CVar.GetCVar("enableMultiActionBars")) or 0
    local nuevo = bit.bor(actual, BARRAS)
    if nuevo == actual then return false end
    C_CVar.SetCVar("enableMultiActionBars", tostring(nuevo))
    print(P .. "barras de acción 2, 3 y 4 encendidas en este personaje (como en el resto de ElpingorUI).")
    return true
end

-- Mapa sin niebla de EllesmereUI. Una vez; luego se respeta. Devuelve true si cambió (se ve al recargar).
local function Mapa()
    ElpingorUIDB = ElpingorUIDB or {}
    if ElpingorUIDB.mapa30 or type(EllesmereUIDB) ~= "table" then return false end
    ElpingorUIDB.mapa30 = true
    if C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Leatrix_Maps") then return false end
    EllesmereUIDB.worldMapReveal = EllesmereUIDB.worldMapReveal or {}
    if EllesmereUIDB.worldMapReveal.enabled == true then return false end
    EllesmereUIDB.worldMapReveal.enabled = true
    print(P .. "mapa sin niebla de EllesmereUI encendido (en lugar de Leatrix_Maps).")
    return true
end

-- Diseño del Modo edición: índice = posición en la lista + número de diseños de Blizzard.
local function IndiceDiseno()
    if not (C_EditMode and C_EditMode.GetLayouts) then return end
    local info = C_EditMode.GetLayouts()
    if not (info and info.layouts) then return end
    -- Diseños de Blizzard delante (Moderno y Clásico): se cuentan como EllesmereUI (EditModeLayoutsForSave).
    local mgr = EditModePresetLayoutManager
    local presets = mgr and mgr.GetCopyOfPresetLayouts and mgr:GetCopyOfPresetLayouts()
    local base = (type(presets) == "table" and #presets > 0 and #presets)
        or (Enum and Enum.EditModePresetLayoutsMeta and Enum.EditModePresetLayoutsMeta.NumValues) or 2
    for i, l in ipairs(info.layouts) do
        if l.layoutName == DISENO then return i + base, info.activeLayout end
    end
end

local disenoPendiente -- índice a activar al pulsar «Recargar»

-- El diseño activo del Modo edición es de cada personaje: se apunta por personaje (antes era de la cuenta
-- y solo el primer personaje lo recibía).
local function Yo() return (UnitName("player") or "?") .. "-" .. (GetRealmName and GetRealmName() or "") end
local function DisenoHecho()
    return type(ElpingorUIDB.disenoClasica30) == "table" and ElpingorUIDB.disenoClasica30[Yo()]
end
local function MarcarDiseno()
    if type(ElpingorUIDB.disenoClasica30) ~= "table" then ElpingorUIDB.disenoClasica30 = {} end
    ElpingorUIDB.disenoClasica30[Yo()] = true
end

StaticPopupDialogs["ELPINGORUI_RECARGAR_CLASICA"] = {
    text = "ElpingorUI: interfaz Clásica preparada.\nRecarga una vez para terminar.",
    button1 = "Recargar", button2 = "Luego",
    OnAccept = function()
        if disenoPendiente and not InCombatLockdown() then
            C_EditMode.SetActiveLayout(disenoPendiente)
            MarcarDiseno()
        end
        ReloadUI()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

-- true si hay que activar el diseño (queda pendiente hasta que pulse «Recargar»).
local function Diseno()
    ElpingorUIDB = ElpingorUIDB or {}
    if DisenoHecho() or InCombatLockdown() then return false end
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then return false end
    local idx, activo = IndiceDiseno()
    if not idx then return false end
    if idx == activo then MarcarDiseno(); return false end
    disenoPendiente = idx
    return true
end

-- 2026-11-17 · Marcos estilo Skill Capped: tu personaje y el objetivo arriba a la izquierda, el foco debajo de tu
-- personaje y la barra de casteo en el centro, algo por debajo. Se cambia UNA vez por cuenta (ElpingorUIDB.marcosSC2)
-- dentro del diseño «ElpingorUI Clásica» y se guarda en el servidor; después se puede retocar en el Modo edición.
-- Sistemas y números como los guarda el cliente: UnitFrame = 3 (1 personaje, 2 objetivo, 3 foco: en Lua van desde 1; el archivo de caché los guarda desde 0. marcosSC1 los contó desde 0 y movió mal el objetivo), CastBar = 1.
local MARCOS = {
    { 3, 1, "TOPLEFT", "TOPLEFT", 200, -50 },    -- tu personaje
    -- 2026-11-18 (marcosSC3, lo pidió Elpingor): el objetivo pegado a tu personaje y el foco debajo del objetivo,
    -- más abajo, con sitio para los bufos y debuffs del objetivo. Quien ya tenía marcosSC2 solo recibe estos dos
    -- (campo 7): no se le vuelve a mover su personaje ni el casteo, por si los retocó.
    -- Los números de abajo son los que colocó él mismo en el Modo edición el 18-11 («así lo quiero en todos»):
    -- también el casteo, suelto del marco y arriba-centro (ver CasteoSuelto).
    { 3, 2, "TOPLEFT", "TOPLEFT", 395, -53, true },      -- objetivo
    { 3, 3, "TOPLEFT", "TOPLEFT", 449.5, -274.5, true }, -- foco
    { 1, nil, "TOP", "TOP", 0, -612.4, true },           -- casteo
}
local function Marcos()
    if ElpingorUIDB.marcosSC3 or InCombatLockdown() then return false end
    local soloNuevos = ElpingorUIDB.marcosSC2
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then return false end
    if not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts) then return false end
    local info = C_EditMode.GetLayouts()
    if not (info and info.layouts) then return false end
    local cambiados = 0
    for _, l in ipairs(info.layouts) do
        if l.layoutName == DISENO and type(l.systems) == "table" then
            for _, s in ipairs(l.systems) do
                for _, m in ipairs(MARCOS) do
                    if s.system == m[1] and (m[2] == nil or s.systemIndex == m[2]) and (m[7] or not soloNuevos) then
                        s.isInDefaultPosition = false
                        s.anchorInfo = s.anchorInfo or {}
                        s.anchorInfo.point, s.anchorInfo.relativePoint = m[3], m[4]
                        s.anchorInfo.relativeTo = "UIParent"
                        s.anchorInfo.offsetX, s.anchorInfo.offsetY = m[5], m[6]
                        cambiados = cambiados + 1
                    end
                end
            end
        end
    end
    if cambiados == 0 then return false end
    local ok = pcall(C_EditMode.SaveLayouts, info)
    if ok then ElpingorUIDB.marcosSC2 = true; ElpingorUIDB.marcosSC3 = true end
    return ok
end

-- 2026-11-17 · Tu barra de casteo pegada debajo de tu marco (ajuste del Modo edición «Fijar al marco del
-- jugador»: CastBar = 1, ajuste 1 = 1). Una vez por cuenta (ElpingorUIDB.casteoMarco1).
-- 2026-11-18 · Elpingor la soltó del marco y la puso él (MARCOS): ahora el ajuste 1 va a 0, una vez por cuenta
-- (ElpingorUIDB.casteoSuelto1), también para quien ya la tenía fijada.
local function CasteoSuelto()
    if ElpingorUIDB.casteoSuelto1 or InCombatLockdown() then return false end
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then return false end
    if not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts) then return false end
    local info = C_EditMode.GetLayouts()
    if not (info and info.layouts) then return false end
    local hecho = false
    for _, l in ipairs(info.layouts) do
        if l.layoutName == DISENO and type(l.systems) == "table" then
            for _, s in ipairs(l.systems) do
                if s.system == 1 then
                    s.settings = s.settings or {}
                    local puesto = false
                    for _, st in ipairs(s.settings) do
                        if st.setting == 1 then st.value = 0; puesto = true end
                    end
                    if not puesto then s.settings[#s.settings + 1] = { setting = 1, value = 0 } end
                    hecho = true
                end
            end
        end
    end
    if not hecho then return false end
    local ok = pcall(C_EditMode.SaveLayouts, info)
    if ok then ElpingorUIDB.casteoMarco1 = true; ElpingorUIDB.casteoSuelto1 = true end
    return ok
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
ev:SetScript("OnEvent", function(self, event)
    if not Activa() then return end
    if event == "PLAYER_LOGIN" then
        local mapa = Mapa()
        local addons = Addons()
        local barras = Barras()
        if mapa or addons or barras then StaticPopup_Show("ELPINGORUI_RECARGAR_CLASICA") end
        return
    end
    -- EDIT_MODE_LAYOUTS_UPDATED: los diseños ya están cargados.
    local marcos = Marcos()
    if marcos then
        print(P .. "marcos colocados: el objetivo pegado a tu personaje, el foco debajo del objetivo y el casteo en el centro.")
    end
    if CasteoSuelto() then marcos = true end
    local diseno = Diseno()
    if diseno then
        self:UnregisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
        print(P .. "el diseño del Modo edición «" .. DISENO .. "» se activa al pulsar «Recargar».")
    end
    if marcos or diseno then StaticPopup_Show("ELPINGORUI_RECARGAR_CLASICA") end
end)

-- /eclasica se queda como recordatorio (antes cambiaba de variante).
SLASH_ELPINGORCLASICA1 = "/eclasica"
SLASH_ELPINGORCLASICA2 = "/eclásica"
SlashCmdList.ELPINGORCLASICA = function()
    print(P .. "ElpingorUI ya es siempre la interfaz Clásica. Colócala con Esc > Modo edición; "
        .. "ajustes de los marcos: /bbf. Si algo se ve mal: /elpingor fix")
end
