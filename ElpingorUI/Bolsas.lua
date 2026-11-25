-------------------------------------------------------------------------------
--  Bolsas (22-11): Baganator sustituye a la bolsa de EllesmereUI.
--  1) Apaga EllesmereUIBags si Baganator está (y ofrece /reload una vez).
--  2) Deja Baganator en vista por categorías (misiones, consumibles, materiales,
--     equipo y basura cada uno en su sitio), sin ordenar al abrir (era lo que laguea).
--  Solo pone los ajustes la primera vez; lo que cambies después a mano se respeta.
-------------------------------------------------------------------------------
local AJUSTES_VERSION = 1

local function AjustarBaganator()
    if type(BAGANATOR_CONFIG) ~= "table" or type(BAGANATOR_CONFIG.Profiles) ~= "table" then return end
    local p = BAGANATOR_CONFIG.Profiles[BAGANATOR_CURRENT_PROFILE or "DEFAULT"]
    if type(p) ~= "table" then return end
    ElpingorUIDB = ElpingorUIDB or {}
    if (ElpingorUIDB.bolsasVersion or 0) >= AJUSTES_VERSION then return end

    p.view_type = "category"            -- vista por categorías (bolsa y banco)
    p.bag_view_type = "category"
    p.bank_view_type = "category"
    p.auto_sort_on_open = false         -- nada de ordenar al abrir: no hace falta y laguea
    p.category_item_grouping = true     -- un montón por objeto, no 5 casillas sueltas
    p.icon_grey_junk = true             -- la basura gris, apagada a la vista
    p.icon_mark_unusable = true         -- en rojo lo que el pícaro no puede usar
    p.icon_text_quality_colors = true
    p.reduce_spacing = true             -- más compacta

    ElpingorUIDB.bolsasVersion = AJUSTES_VERSION
    print("|cff33ff99ElpingorUI|r: Baganator ajustado (vista por categorías, sin ordenar al abrir).")
end

-- Basura (23-11): Baganator elegía solo a LootTriage como «qué es basura» en cuanto se instalaba,
-- y LootTriage solo marca algo mientras despojas con las bolsas llenas: la categoría Basura salía
-- vacía y lo gris no se veía gris. Se vuelve UNA vez a «calidad pobre» (lo gris) y se apunta
-- LootTriage como ignorado para que Baganator no lo vuelva a elegir al entrar. Si luego eliges
-- LootTriage a mano en Baganator, se respeta.
local function BasuraGris()
    if type(BAGANATOR_CONFIG) ~= "table" or type(BAGANATOR_CONFIG.Profiles) ~= "table" then return end
    local p = BAGANATOR_CONFIG.Profiles[BAGANATOR_CURRENT_PROFILE or "DEFAULT"]
    if type(p) ~= "table" then return end
    ElpingorUIDB = ElpingorUIDB or {}
    if ElpingorUIDB.bolsasBasura1 then return end
    if p.junk_plugin == "loottriage" then
        p.junk_plugin = "poor_quality"
        if type(p.junk_plugin_ignored) ~= "table" then p.junk_plugin_ignored = { none = true } end
        p.junk_plugin_ignored.loottriage = true
        print("|cff33ff99ElpingorUI|r: la basura de Baganator vuelve a ser lo gris (recarga para verlo).")
    end
    ElpingorUIDB.bolsasBasura1 = true
end

-- Categoría «PvP» (22-11): pociones, vendas, granadas y bombas, arriba del todo.
-- Búsqueda con la sintaxis pública de Syndicator: «potion» e «invisibility» son palabras
-- clave; lo demás casa por nombre (en español e inglés). «|» = o.
local PVP_BUSQUEDA = "potion|invisibility|venda|bandage|granada|grenade|bomba|bomb|dinamita|dynamite|explosiv|lanzarredes|net-o-matic"

local function CrearCategoriaPvP()
    if type(BAGANATOR_CONFIG) ~= "table" or type(BAGANATOR_CONFIG.Profiles) ~= "table" then return end
    local p = BAGANATOR_CONFIG.Profiles[BAGANATOR_CURRENT_PROFILE or "DEFAULT"]
    if type(p) ~= "table" then return end
    ElpingorUIDB = ElpingorUIDB or {}
    if ElpingorUIDB.bolsasPvP then return end
    p.custom_categories = p.custom_categories or {}
    p.category_display_order = p.category_display_order or {}
    for _, c in pairs(p.custom_categories) do
        if type(c) == "table" and c.name == "PvP" then ElpingorUIDB.bolsasPvP = true return end
    end
    local id = 1
    while p.custom_categories[tostring(id)] do id = id + 1 end
    id = tostring(id)
    p.custom_categories[id] = { name = "PvP", search = PVP_BUSQUEDA }
    table.insert(p.category_display_order, 1, id)
    ElpingorUIDB.bolsasPvP = true
    print("|cff33ff99ElpingorUI|r: categoría PvP creada en Baganator (pociones, vendas, granadas, bombas).")
end

local function ApagarBolsaEllesmere()
    if not C_AddOns.IsAddOnLoaded("Baganator") then return end
    local _, _, _, _, reason = C_AddOns.GetAddOnInfo("EllesmereUIBags")
    if reason == "MISSING" then return end
    if C_AddOns.GetAddOnEnableState("EllesmereUIBags") == 0 and not C_AddOns.IsAddOnLoaded("EllesmereUIBags") then return end
    C_AddOns.DisableAddOn("EllesmereUIBags")   -- todos los personajes; no se borra nada
    if C_AddOns.IsAddOnLoaded("EllesmereUIBags") then
        StaticPopupDialogs["ELPINGORUI_BOLSAS_RELOAD"] = {
            text = "ElpingorUI: ahora usas Baganator y he apagado la bolsa de EllesmereUI.\nRecarga la interfaz para que no se pisen.",
            button1 = "Recargar", button2 = "Luego",
            OnAccept = function() ReloadUI() end,
            timeout = 0, whileDead = true, hideOnEscape = true,
        }
        StaticPopup_Show("ELPINGORUI_BOLSAS_RELOAD")
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    AjustarBaganator()
    BasuraGris()
    CrearCategoriaPvP()
    ApagarBolsaEllesmere()
end)
