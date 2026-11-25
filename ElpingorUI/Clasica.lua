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
-- 20-11: placas con BetterBlizzPlates como Skill Capped (Elpingor); las de EllesmereUI se apagan.
local ENCENDER = { "BetterBlizzFrames", "BetterBlizzPlates" }
local APAGAR = { "EllesmereUIActionBars", "EllesmereUINameplates" }

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
        -- 25-11: la base son los marcos de EllesmereUI; BetterBlizzFrames solo si se eligió Blizzard en /elpingor.
        local saltar = a == "BetterBlizzFrames" and not ElpingorUIDB.marcosBlizzard
        if not saltar and Exists(a) and not Loaded(a) then Pedir(a, true) end
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
-- 2026-11-18 tarde (marcosSC4): Elpingor bajó los marcos hacia el centro y es la que se queda («posiblemente la
-- que sí se quede»). Números sacados de su caché del Modo edición tras cerrar el juego: personaje y foco sueltos,
-- el objetivo enganchado a su barra de casteo (campo 8 = marco de referencia). Se aplica a todos, también a
-- quien ya tenía marcosSC3.
local MARCOS = {
    -- 21-11: misma posición en 16:9, pero contada desde el centro de arriba (x - 960) para los panorámicos
    { 3, 1, "TOPLEFT", "TOP", -376, -561, true },                                     -- tu personaje (584)
    { 3, 2, "TOPLEFT", "TOP", 135.4, -564.4, true },                                  -- objetivo (1095.4; 19-11: un poco a la derecha, suelto)
    { 3, 3, "TOPLEFT", "TOP", -328.5, -407, true },                                   -- foco (631.5)
    { 1, nil, "TOP", "TOP", 0, -612.4, true },                                        -- casteo
}
local function Marcos()
    if ElpingorUIDB.marcosSC5 or InCombatLockdown() then return false end
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
                        s.anchorInfo.relativeTo = m[8] or "UIParent"
                        s.anchorInfo.offsetX, s.anchorInfo.offsetY = m[5], m[6]
                        cambiados = cambiados + 1
                    end
                end
            end
        end
    end
    if cambiados == 0 then return false end
    local ok = pcall(C_EditMode.SaveLayouts, info)
    if ok then ElpingorUIDB.marcosSC2 = true; ElpingorUIDB.marcosSC3 = true; ElpingorUIDB.marcosSC4 = true; ElpingorUIDB.marcosSC5 = true end
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

-- 2026-11-21 · Pantallas panorámicas (Sara, 21:9): el diseño guarda casi todo anclado a la esquina de arriba
-- a la izquierda (TOPLEFT) con la x pensada para 1920 de ancho. En una pantalla más ancha el centro se va a la
-- derecha y marcos, barras y medidores se quedan corridos a la izquierda. Lo que está en la parte central
-- (entre el 15 % y el 85 % de 1920) se ancla al centro de arriba (o de abajo) con la misma distancia al centro:
-- en 16:9 queda exactamente igual, y en panorámico va centrado. Lo pegado a los bordes no se toca.
-- Se repite en cada carga (si se mueve algo en el Modo edición y el juego lo vuelve a guardar en la esquina).
local ANCHO = 1920
local function Centrar()
    if InCombatLockdown() then return false end
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then return false end
    if not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts) then return false end
    local info = C_EditMode.GetLayouts()
    if not (info and info.layouts) then return false end
    local cambiados = 0
    for _, l in ipairs(info.layouts) do
        if l.layoutName == DISENO and type(l.systems) == "table" then
            for _, s in ipairs(l.systems) do
                local a = s.anchorInfo
                local x = a and tonumber(a.offsetX)
                if x and a.relativeTo == "UIParent" and x > ANCHO * 0.15 and x < ANCHO * 0.85 then
                    local nuevo = (a.point == "TOPLEFT" and a.relativePoint == "TOPLEFT" and "TOP")
                        or (a.point == "BOTTOMLEFT" and a.relativePoint == "BOTTOMLEFT" and "BOTTOM")
                    if nuevo then
                        a.relativePoint = nuevo
                        a.offsetX = x - ANCHO / 2
                        s.isInDefaultPosition = false
                        cambiados = cambiados + 1
                    end
                end
            end
        end
    end
    if cambiados == 0 then return false end
    return (pcall(C_EditMode.SaveLayouts, info))
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
    local okC, centrado = pcall(Centrar)
    if okC and centrado then
        marcos = true
        print(P .. "marcos y barras anclados al centro (para que en pantallas panorámicas no se vayan a la izquierda).")
    end
    local diseno = Diseno()
    if diseno then
        self:UnregisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
        print(P .. "el diseño del Modo edición «" .. DISENO .. "» se activa al pulsar «Recargar».")
    end
    if marcos or diseno then StaticPopup_Show("ELPINGORUI_RECARGAR_CLASICA") end
end)

-- 2026-11-20 · El icono grande de control de las placas de BetterBlizzPlates (Fear, Miedo, aturdir...),
-- ENCIMA del número de nivel. Lo dijo Elpingor: «el fear a la derecha está demasiado afuera» y luego
-- «que quede exactamente arriba del nivel; ya después que se quite se vuelve a ver el nivel».
-- BBP lo coloca a «5 + hueco del nivel» del final de la barra, pero mide esa distancia DENTRO del icono,
-- que va agrandado (ccIconScale 1,8): el hueco salía 1,8 veces más grande y el icono quedaba lejos.
-- Aquí se le da a BBP la distancia ya dividida por ese tamaño, para que el icono empiece justo donde
-- empieza el número de nivel (INICIO_CC puntos tras la barra, como el nivel de BBP) y lo tape mientras
-- dura el control, sin tapar la barra; sin control se ve el nivel. Si el mob no enseña nivel, el icono
-- queda igual de pegado a la barra. El icono va 10 capas por encima del nivel, así que lo tapa.
-- No toca los archivos de BBP, y el deslizador «CC Icon X» de /bbp sigue sumando por encima.
-- Copia de antes: copias\Clasica.lua.antes-fear-pegado-2026-11-20
local INICIO_CC = 4
local function PegarIconoCC()
    if type(BBP) ~= "table" or type(BBP.GetLevelSpace) ~= "function" or BBP.elpingorIconoCC then return end
    local original = BBP.GetLevelSpace
    BBP.elpingorIconoCC = true
    BBP.GetLevelSpace = function(frame, ...)
        local espacio = original(frame, ...)
        local db = BetterBlizzPlatesDB
        if not (Activa() and type(db) == "table" and type(espacio) == "number") then return espacio end
        -- Solo con el nivel fuera de la barra (sus placas «classic retail»): ahí este hueco solo lo usan
        -- los iconos de la derecha. En los demás estilos también mide la placa y se deja como está.
        if db.classicNameplates then return espacio end
        if not (db.classicRetailNameplates or db.hideLevelFrameBackground or db.centerNameplateHealthBar) then
            return espacio
        end
        local escala = (tonumber(db.ccIconScale) or 1.35) * (tonumber(db.bbpAuraScale) or 1)
        if escala <= 0 then return espacio end
        return INICIO_CC / escala - 5
    end
end
PegarIconoCC()

-- 25-11: con los marcos de EllesmereUI los buffos ya salen encima del marco del jugador: se esconde la fila
-- de buffos de Blizzard de arriba a la derecha. Con «Marcos de Blizzard» (la clásica) se queda como siempre.
local function SinBuffsArriba() return not (ElpingorUIDB and ElpingorUIDB.marcosBlizzard) end
local buffs = CreateFrame("Frame")
buffs:RegisterEvent("PLAYER_LOGIN")
buffs:SetScript("OnEvent", function()
    if not BuffFrame or not SinBuffsArriba() then return end
    BuffFrame:Hide()
    hooksecurefunc(BuffFrame, "Show", function(f) if SinBuffsArriba() then f:Hide() end end)
end)

-- /eclasica se queda como recordatorio (antes cambiaba de variante).
SLASH_ELPINGORCLASICA1 = "/eclasica"
SLASH_ELPINGORCLASICA2 = "/eclásica"
SlashCmdList.ELPINGORCLASICA = function()
    print(P .. "ElpingorUI ya es siempre la interfaz Clásica. Colócala con Esc > Modo edición; "
        .. "ajustes de los marcos: /bbf. Si algo se ve mal: /elpingor fix")
end
