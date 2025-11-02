-- WW2 Facciones (Servidor)
-- Persiste elección, mata silenciosamente y equipa en spawn + respawn manual

AddCSLuaFile("autorun/shared/ww2_factions_sh.lua")
AddCSLuaFile("autorun/client/ww2_menu.lua")

include("autorun/shared/ww2_factions_sh.lua")

-- Network extras
util.AddNetworkString("WW2_RequestRespawn") -- C->S: pedir respawn

local function ValidFaction(f)
    return f == WW2.FACCION.REICH or f == WW2.FACCION.USSR
end

-- Guardado en PData + NW
local function SetPlayerFaction(ply, fac)
    if not IsValid(ply) then return end
    if not ValidFaction(fac) then return end

    ply:SetPData("ww2_faction", fac)
    ply:SetNWString("ww2_faction", fac)

    -- Opcional: sync explícito
    net.Start("WW2_SyncFaction")
        net.WriteString(fac)
    net.Send(ply)
end

-- Cargar facción al entrar (si existía)
hook.Add("PlayerInitialSpawn", "WW2_LoadFactionOnJoin", function(ply)
    local saved = ply:GetPData("ww2_faction", "")
    if saved ~= "" then
        SetPlayerFaction(ply, saved)
    end
end)

-- Equipar por facción
local function ApplyFactionLoadout(ply, fac)
    if fac == WW2.FACCION.REICH then
        ply:SetModel("models/player/Group03/male_07.mdl") -- REEMPLAZA por tus modelos WW2
        ply:StripWeapons()
        ply:Give("weapon_crowbar")
        ply:Give("weapon_pistol")
        ply:GiveAmmo(60, "Pistol", true)
    elseif fac == WW2.FACCION.USSR then
        ply:SetModel("models/player/Group03/male_02.mdl")
        ply:StripWeapons()
        ply:Give("weapon_crowbar")
        ply:Give("weapon_357")
        ply:GiveAmmo(18, "357", true)
    end
end

hook.Add("PlayerSpawn", "WW2_ApplyFactionOnSpawn", function(ply)
    local fac = ply:GetNWString("ww2_faction", "")
    if fac == "" then return end
    timer.Simple(0, function()
        if IsValid(ply) then
            ApplyFactionLoadout(ply, fac)
        end
    end)
end)

-- Elegir facción desde el menú
net.Receive("WW2_ElegirBando", function(_, ply)
    local fac = net.ReadString()
    if not ValidFaction(fac) then return end

    SetPlayerFaction(ply, fac)

    if ply:Alive() then
        -- Si está vivo, lo "reiniciamos" silenciosamente
        ply:KillSilent()
        timer.Simple(0.1, function()
            if IsValid(ply) then ply:Spawn() end
        end)
    else
        -- Si ya está muerto, spawnear directo
        timer.Simple(0.1, function()
            if IsValid(ply) then ply:Spawn() end
        end)
    end
end)

-- Respawn manual pedido desde el cliente (botón REAPARECER)
net.Receive("WW2_RequestRespawn", function(_, ply)
    if not IsValid(ply) then return end
    -- Solo tiene sentido si está muerto; aun así no hace daño en vivo
    timer.Simple(0.05, function()
        if IsValid(ply) then ply:Spawn() end
    end)
end)
