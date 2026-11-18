-- ElpingorUI · Instalador dentro del juego (2.3).
-- Sale solo la primera vez (o con /elpingor). Detecta la pantalla, importa los perfiles de las 9 clases
-- en EllesmereUI con su función para instaladores (ImportProfileSilent) y pone los ajustes de Capping,
-- BattleGroundEnemies, ForeverCore, Questie y Attune. Antes guarda una copia para «Volver a mi interfaz».
-- Los datos están en Datos.lua (lo genera herramientas\generar_instalador.py).

local P = "|cff0cd29fElpingorUI|r: "
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
local NECESARIOS = { "EllesmereUI", "EllesmereUIOptions", "EllesmereUILocales", "EllesmereUINameplates",
    "EllesmereUIUnitFrames", "EllesmereUIRaidFrames", "EllesmereUIResourceBars", "EllesmereUIMinimap",
    "EllesmereUIChat", "EllesmereUIBags", "EllesmereUIDamageMeters", "EllesmereUIQoL", "BetterBlizzFrames" }
-- GlowingBars ya no sobra (18-11): vuelve a la lista, lo usan sus amigos guerreros.
local SOBRAN = { "SkillCapped", "BetterBlizzPlates", "MiniAuras", "oGlowClassic", "Leatrix_Maps",
    "Details", "Bagnon", "BagBrother", "MiniCC", "EllesmereUIActionBars",
    "ForeverProfessionMaster", "CraftProfit" }   -- 18-11: los cubre Mastercraft
local SOBRAN_PREFIJOS = { "Details_", "Bagnon_" }
local POR_QUE = { EllesmereUIActionBars = "barras de Blizzard",
    ForeverProfessionMaster = "lo hace Mastercraft", CraftProfit = "lo hace Mastercraft" }

local function Existe(a)
    local _, _, _, _, reason = C_AddOns.GetAddOnInfo(a)
    return reason ~= "MISSING"
end
-- Cargado en esta sesión (fiable). GetAddOnEnableState no coincidía con lo cargado en WoW Forever.
local function Encendido(a) return C_AddOns.IsAddOnLoaded(a) and true or false end

local function PlanAddons()
    local encender, apagar, visto = {}, {}, {}
    for _, a in ipairs(NECESARIOS) do
        if Existe(a) and not Encendido(a) then encender[#encender + 1] = a end
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
    if #apagar > 0 then t[#t + 1] = "Se apagan (EllesmereUI ya lo hace): " .. table.concat(apagar, ", ") end
    if #encender > 0 then t[#t + 1] = "Se encienden: " .. table.concat(encender, ", ") end
    return table.concat(t, "\n")
end

local function AplicarAddons()
    local encender, apagar = PlanAddons()
    for _, a in ipairs(encender) do C_AddOns.EnableAddOn(a) end
    for _, a in ipairs(apagar) do C_AddOns.DisableAddOn(a) end
    return #encender + #apagar
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
    win.cInterfaz = Casilla(win, "Interfaz Clásica", "Marcos y barras de Blizzard con el estilo de ElpingorUI; placas, grupo, auras y medidores (EllesmereUI), para las 9 clases")
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
