-- ElpingorUI · PvP (antes el addon ElpingorPvP 1.1): oculta RestedXP, Questie, SkillUp y Attune
-- en Arena y Campo de batalla.
-- Solo esconde lo que estaba visible (o lo que intenta mostrarse dentro) y lo
-- vuelve a mostrar al salir. Nunca toca nada en combate: espera a salir de él.

local FRAMES = {
    "RXPFrame",          -- RestedXP: ventana de la guía
    "RXPTargetFrame",    -- RestedXP: Active Targets
    "RXPG_ARROW",        -- RestedXP: flecha de ruta
    "Questie_BaseFrame", -- Questie: rastreador de misiones
    "ForeverTrackerCompanion", -- SkillUpForever: lista de reagentes de profesión
    "AttuneNextFrame",   -- Attune: ventana «Attune: Next» (en la columna derecha desde v25)
}

local inPvP, pending = false, false
local hooked, wasShown = {}, {}

local function PvPNow()
    local inInst, t = IsInInstance()
    return inInst and (t == "pvp" or t == "arena") or false
end

local function Apply()
    if InCombatLockdown() then pending = true; return end
    pending = false
    for _, name in ipairs(FRAMES) do
        local f = _G[name]
        if f then
            if not hooked[f] then
                hooked[f] = true
                f:HookScript("OnShow", function(self)
                    if not inPvP then return end
                    if InCombatLockdown() then
                        pending = true -- se oculta al terminar el combate
                    else
                        wasShown[self] = true
                        self:Hide()
                    end
                end)
            end
            if inPvP then
                if f:IsShown() then wasShown[f] = true; f:Hide() end
            elseif wasShown[f] then
                wasShown[f] = nil
                f:Show()
            end
        end
    end
end

-- 3.0: mascotas y tótems enemigos con placa solo en arena (en BG y mundo son ruido).
local function MascotasEnemigas()
    if InCombatLockdown() then pending = true; return end
    local _, t = IsInInstance()
    local want = (t == "arena") and "1" or "0"
    if C_CVar.GetCVar("nameplateShowEnemyPets") ~= nil and C_CVar.GetCVar("nameplateShowEnemyPets") ~= want then
        C_CVar.SetCVar("nameplateShowEnemyPets", want)
    end
    if C_CVar.GetCVar("nameplateShowEnemyTotems") ~= nil and C_CVar.GetCVar("nameplateShowEnemyTotems") ~= "1" then
        C_CVar.SetCVar("nameplateShowEnemyTotems", "1")
    end
end

-- 3.0: Tab inteligente. En arena y BG el Tab elige solo jugadores enemigos (no mascotas ni tótems);
-- al salir vuelve a lo de antes. Solo si el Tab está como viene de serie. /etab lo apaga.
-- La marca va en ElpingorUIDB: si se recarga dentro del BG, al salir se sigue sabiendo que hay que devolverlo.
local function TabInteligente()
    if InCombatLockdown() then pending = true; return end
    if not (GetBindingAction and SetBinding) then return end
    ElpingorUIDB = ElpingorUIDB or {}
    local db = ElpingorUIDB
    local quiero = PvPNow() and not db.tabOff
    local actual = GetBindingAction("TAB")
    if quiero then
        if actual == "TARGETNEARESTENEMY" then
            SetBinding("TAB", "TARGETNEARESTENEMYPLAYER")
            if not db.tabCambiado then
                print("|cff0cd29fElpingorUI|r: Tab elige solo jugadores enemigos (Arena / Campo de batalla).")
            end
            db.tabCambiado = true
        end
    elseif db.tabCambiado then
        if actual == "TARGETNEARESTENEMYPLAYER" then SetBinding("TAB", "TARGETNEARESTENEMY") end
        db.tabCambiado = nil
    end
end

SLASH_ELPINGORTAB1 = "/etab"
SlashCmdList.ELPINGORTAB = function()
    ElpingorUIDB = ElpingorUIDB or {}
    ElpingorUIDB.tabOff = not ElpingorUIDB.tabOff or nil
    TabInteligente()
    print("|cff0cd29fElpingorUI|r: Tab inteligente en PvP " .. (ElpingorUIDB.tabOff and "apagado." or "encendido."))
end

local function Refresh()
    MascotasEnemigas()
    TabInteligente()
    local now = PvPNow()
    if now ~= inPvP then
        inPvP = now
        print(now and "|cff0cd29fElpingorUI|r: guía y rastreadores ocultos (Arena / Campo de batalla)."
                   or "|cff0cd29fElpingorUI|r: guía y rastreadores visibles de nuevo.")
    end
    Apply()
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if pending then Apply(); MascotasEnemigas(); TabInteligente() end
        return
    end
    Refresh()
    -- Questie crea su rastreador unos segundos después de entrar: repasar.
    C_Timer.After(5, Apply)
    C_Timer.After(15, Apply)
end)
