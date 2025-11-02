-- WW2 Facciones (Compartido)
-- Define nombres, colores y utilidades comunes

WW2 = WW2 or {}
WW2.FACCION = WW2.FACCION or {}

WW2.FACCION.REICH = "reich"
WW2.FACCION.USSR  = "ussr"

WW2.FactionNames = {
    [WW2.FACCION.REICH] = "Tercer Reich",
    [WW2.FACCION.USSR]  = "Unión Soviética",
}

-- Colores para HUD
WW2.FactionColors = {
    [WW2.FACCION.REICH] = Color(70, 120, 255), -- Azul notable
    [WW2.FACCION.USSR]  = Color(220, 50, 50),  -- Rojo notable
}

-- Network strings
if SERVER then
    util.AddNetworkString("WW2_ElegirBando")   -- C->S: string faccion
    util.AddNetworkString("WW2_SyncFaction")   -- S->C: string faccion actual
end

-- Helpers compartidos
local PLAYER = FindMetaTable("Player")

function PLAYER:WW2_GetFaction()
    return self:GetNWString("ww2_faction", "")
end

function PLAYER:WW2_HasFaction()
    return self:WW2_GetFaction() ~= ""

end

WW2.CLASSES = {
    [WW2.FACCION.REICH] = {
        {
            id = "reich_asalto",
            nombre = "ASALTO",
            descripcion = "Avanza y rompe líneas. Obvio.",
            armas = {
                "doi_atow_mp40",
                "doi_atow_p08",
                "doi_atow_etoolde"
            },
            modelo = "models/player/dod_german.mdl"
        }
    }
}
