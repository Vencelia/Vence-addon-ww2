-- Menú WW2 + HUD Facción + Pantalla de Muerte (Cliente)

if SERVER then return end
include("autorun/shared/ww2_factions_sh.lua")

-- ========= Textos =========
local TITULO_PRINCIPAL = "1942 - En las afueras de Moscú"
local TEXTO_REICH      = "Tercer Reich"
local TEXTO_USSR       = "Unión Soviética"
local TEXTO_CIVIL      = "Civil"

-- ========= Fuentes =========
surface.CreateFont("WW2_Titulo",    {font="Trajan Pro", size=ScreenScale(14), weight=800, antialias=true, extended=true})
surface.CreateFont("WW2_Sub",       {font="Montserrat", size=ScreenScale(10), weight=700, antialias=true, extended=true})
surface.CreateFont("WW2_Opcion",    {font="Montserrat", size=ScreenScale(9),  weight=600, antialias=true, extended=true})
surface.CreateFont("WW2_Pie",       {font="Montserrat", size=ScreenScale(7),  weight=500, antialias=true, extended=true})
surface.CreateFont("WW2_FactionHUD",{font="Montserrat", size=ScreenScale(9),  weight=900, antialias=true, extended=true})
surface.CreateFont("WW2_DeathBig",  {font="Montserrat", size=ScreenScale(16), weight=1000, antialias=true, extended=true})
surface.CreateFont("WW2_DeathBtn",  {font="Montserrat", size=ScreenScale(9),  weight=800,  antialias=true, extended=true})

-- ========= Material blur =========
local blur = Material("pp/blurscreen")
local function PintarBlur(panel, capas)
    local x, y = panel:LocalToScreen(0, 0)
    local scrW, scrH = ScrW(), ScrH()
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(blur)
    for i = 1, (capas or 4) do
        blur:SetFloat("$blur", i * 1.5)
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(-x, -y, scrW, scrH)
    end
end

-- ========= Colores =========
local colOscuro     = Color(10, 10, 12, 245)
local colBorde      = Color(255, 255, 255, 10)
local colTitulo     = Color(240, 240, 240)
local colReich      = Color(140, 0, 0, 200)
local colUSSR       = Color(180, 20, 20, 200)
local colCivil      = Color(40, 40, 45, 220)
local colResalto    = Color(255, 255, 255, 12)
local colLinea      = Color(255, 255, 255, 30)
local colHover      = Color(255, 255, 255, 18)

-- ========= Net helpers =========
local function ElegirFaccion(faccion)
    if not faccion or faccion == "" then return end
    net.Start("WW2_ElegirBando")
        net.WriteString(faccion)
    net.SendToServer()
end

local function SolicitarRespawn()
    net.Start("WW2_RequestRespawn")
    net.SendToServer()
end

-- ========= MENÚ DE FACCIONES =========
function WW2_AbrirMenu()
    local scrW, scrH = ScrW(), ScrH()
    local margen     = math.max(16, math.floor(scrW * 0.01))
    local altoHeader = math.max(64, math.floor(scrH * 0.12))
    local altoPie    = math.max(52, math.floor(scrH * 0.10))
    local anchoCol   = math.floor((scrW - margen*3) * 0.5)
    local altoCol    = math.floor(scrH - altoHeader - altoPie - margen*2)

    local frame = vgui.Create("DFrame")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:SetTitle("")
    frame:SetSize(scrW, scrH)
    frame:Center()
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(true)
    frame:SetMouseInputEnabled(true)
    frame.Paint = function(self, w, h)
        PintarBlur(self, 5)
        surface.SetDrawColor(colOscuro)  surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(colBorde)   surface.DrawOutlinedRect(margen/2, margen/2, w - margen, h - margen, 2)
        surface.SetDrawColor(colLinea)
        surface.DrawRect(margen, altoHeader, w - margen*2, 1)
        surface.DrawRect(margen, h - altoPie, w - margen*2, 1)
    end
    g_WW2_Menu = frame

    local header = vgui.Create("DPanel", frame)
    header:SetPos(margen, margen)
    header:SetSize(scrW - margen*2, altoHeader - margen)
    header.Paint = function(self, w, h)
        draw.SimpleText(TITULO_PRINCIPAL, "WW2_Titulo", w*0.5, h*0.55, colTitulo, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Selecciona tu bando", "WW2_Pie", w*0.5, h*0.85, Color(220,220,220,160), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Reich
    local panelIzq = vgui.Create("DButton", frame)
    panelIzq:SetText("")
    panelIzq:SetPos(margen, altoHeader + margen)
    panelIzq:SetSize(anchoCol, altoCol)
    panelIzq.HoverFrac = 0
    panelIzq.Paint = function(self, w, h)
        self.HoverFrac = Lerp(FrameTime()*8, self.HoverFrac, self:IsHovered() and 1 or 0)
        surface.SetDrawColor(colReich) surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(colResalto) surface.DrawRect(0, 0, w, h * 0.18 * self.HoverFrac)
        surface.SetDrawColor(colBorde) surface.DrawOutlinedRect(0, 0, w, h, 2)
        draw.SimpleText(TEXTO_REICH, "WW2_Sub", w*0.5, math.floor(h*0.08), Color(255,240,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Infantería, Panzer, doctrina Blitzkrieg", "WW2_Opcion", w*0.5, h*0.16, Color(255,240,240,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    panel.DoClick = function()
    surface.PlaySound("buttons/button14.wav")
    if data.faccion == WW2.FACCION.REICH then
        timer.Simple(0.2, function()
            WW2_AbrirClases(WW2.FACCION.REICH)
            if IsValid(frame) then frame:Remove() end
        end)
    else
        ElegirFaccion(data.faccion)
        if IsValid(frame) then frame:Remove() end
    end
end


    -- USSR
    local panelDer = vgui.Create("DButton", frame)
    panelDer:SetText("")
    panelDer:SetPos(margen*2 + anchoCol, altoHeader + margen)
    panelDer:SetSize(anchoCol, altoCol)
    panelDer.HoverFrac = 0
    panelDer.Paint = function(self, w, h)
        self.HoverFrac = Lerp(FrameTime()*8, self.HoverFrac, self:IsHovered() and 1 or 0)
        surface.SetDrawColor(colUSSR) surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(colResalto) surface.DrawRect(0, 0, w, h * 0.18 * self.HoverFrac)
        surface.SetDrawColor(colBorde) surface.DrawOutlinedRect(0, 0, w, h, 2)
        draw.SimpleText(TEXTO_USSR, "WW2_Sub", w*0.5, math.floor(h*0.08), Color(255,240,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Guardias, T-34, defensa en profundidad", "WW2_Opcion", w*0.5, h*0.16, Color(255,240,240,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    panelDer.DoClick = function()
        surface.PlaySound("buttons/button14.wav")
        ElegirFaccion(WW2.FACCION.USSR)
        if IsValid(frame) then frame:Remove() end
    end

    -- Civil (placeholder)
    local panelPie = vgui.Create("DButton", frame)
    panelPie:SetText("")
    panelPie:SetPos(margen, scrH - altoPie + 1)
    panelPie:SetSize(scrW - margen*2, altoPie - margen)
    panelPie.HoverFrac = 0
    panelPie.Paint = function(self, w, h)
        self.HoverFrac = Lerp(FrameTime()*8, self.HoverFrac, self:IsHovered() and 1 or 0)
        surface.SetDrawColor(colCivil)  surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(self:IsHovered() and colHover or colResalto) surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(colBorde)  surface.DrawOutlinedRect(0, 0, w, h, 2)
        draw.SimpleText(TEXTO_CIVIL, "WW2_Sub", w*0.5, h*0.5, Color(235,235,235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    panelPie.DoClick = function()
        surface.PlaySound("buttons/button14.wav")
        if IsValid(frame) then frame:Remove() end
    end
end

-- Mostrar automáticamente al entrar
hook.Add("InitPostEntity", "WW2_MostrarMenu_Init", function()
    timer.Simple(1.0, function()
        if not IsValid(g_WW2_Menu) then
            WW2_AbrirMenu()
        end
    end)
end)

-- ========= HUD de Facción (abajo izquierda) =========
hook.Add("HUDPaint", "WW2_FactionHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local fac = ply:GetNWString("ww2_faction", "")
    if fac == "" then return end

    local nombre = WW2.FactionNames[fac] or string.upper(fac)
    local col    = WW2.FactionColors[fac] or color_white

    local margin = math.max(12, math.floor(ScrW()*0.008))
    local x = margin
    local y = ScrH() - margin - draw.GetFontHeight("WW2_FactionHUD")

    draw.SimpleText(nombre, "WW2_FactionHUD", x+2, y+2, Color(0,0,0,200), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    draw.SimpleText(nombre, "WW2_FactionHUD", x,   y,   col,             TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
end)

-- ========= PANTALLA DE MUERTE =========
local DeathUI = {
    active = false,
    diedAt = 0,
    btnRespawn = nil,
    btnChange  = nil,
    frame = nil
}

local function DeathUI_RemoveButtons()
    if IsValid(DeathUI.btnRespawn) then DeathUI.btnRespawn:Remove() end
    if IsValid(DeathUI.btnChange)  then DeathUI.btnChange:Remove()  end
    if IsValid(DeathUI.frame)      then DeathUI.frame:Remove()      end
    DeathUI.btnRespawn, DeathUI.btnChange, DeathUI.frame = nil, nil, nil
end

local function DeathUI_Start()
    DeathUI.active = true
    DeathUI.diedAt = CurTime()
    DeathUI_RemoveButtons()

    gui.EnableScreenClicker(true)  -- <<< HABILITA EL MOUSE

    -- Crea un frame invisible para capturar input del mouse al aparecer botones
    local f = vgui.Create("DPanel")
    f:SetSize(ScrW(), ScrH())
    f:SetPos(0, 0)
    f:SetKeyboardInputEnabled(true)
    f:SetMouseInputEnabled(true)
    f:SetZPos(32767)
    f:SetVisible(true)
    f.Paint = function() end
    DeathUI.frame = f
end

local function DeathUI_Stop()
    DeathUI.active = false
    gui.EnableScreenClicker(false) -- <<< DESHABILITA EL MOUSE
    DeathUI_RemoveButtons()
end

-- Crear botones tras 1s
local function DeathUI_CreateButtons()
    if not DeathUI.active or not IsValid(DeathUI.frame) then return end
    if IsValid(DeathUI.btnRespawn) then return end

    local scrW, scrH = ScrW(), ScrH()
    local btnW, btnH = math.floor(scrW*0.16), math.floor(scrH*0.07)
    local gap        = math.max(16, math.floor(scrW*0.01))
    local totalW     = btnW*2 + gap
    local baseX      = (scrW - totalW) * 0.5
    local baseY      = scrH * 0.60

    local function styleBtn(btn, text)
        btn:SetText("")
        btn.Paint = function(self, w, h)
            surface.SetDrawColor(30,30,30,230) surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(255,255,255,30) surface.DrawOutlinedRect(0,0,w,h,2)
            local clr = self:IsHovered() and Color(255,255,255) or Color(220,220,220)
            draw.SimpleText(text, "WW2_DeathBtn", w*0.5, h*0.5, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    local btn1 = vgui.Create("DButton", DeathUI.frame)
    btn1:SetSize(btnW, btnH)
    btn1:SetPos(baseX, baseY)
    styleBtn(btn1, "REAPARECER")
    btn1.DoClick = function()
        surface.PlaySound("buttons/button14.wav")
        SolicitarRespawn()
        DeathUI_Stop()
    end
    DeathUI.btnRespawn = btn1

    local btn2 = vgui.Create("DButton", DeathUI.frame)
    btn2:SetSize(btnW, btnH)
    btn2:SetPos(baseX + btnW + gap, baseY)
    styleBtn(btn2, "CAMBIAR DE EQUIPO")
    btn2.DoClick = function()
        surface.PlaySound("buttons/button14.wav")
        DeathUI_Stop()
        WW2_AbrirMenu()
    end
    DeathUI.btnChange = btn2
end

-- Detectar transición vivo->muerto / muerto->vivo y dibujar overlay
local wasAlive = true

hook.Add("Think", "WW2_DeathUI_AliveDetector", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local alive = ply:Alive()

    if wasAlive and not alive then
        -- Murió: activar UI
        DeathUI_Start()
    elseif (not wasAlive) and alive then
        -- Revivió: cerrar UI
        DeathUI_Stop()
    end

    wasAlive = alive
end)

hook.Add("HUDPaint", "WW2_DeathUI_Draw", function()
    if not DeathUI.active then return end

    local scrW, scrH = ScrW(), ScrH()

    -- Fondo negro brusco (sin fade)
    surface.SetDrawColor(0,0,0,255)
    surface.DrawRect(0,0,scrW,scrH)

    -- Texto central "TE HAN MATADO" en rojo
    local msg = "TE HAN MATADO"
    draw.SimpleText(msg, "WW2_DeathBig", scrW*0.5 + 2, scrH*0.42 + 2, Color(0,0,0,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(msg, "WW2_DeathBig", scrW*0.5,     scrH*0.42,     Color(220,30,30),   TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Tras 1s, crear botones si aún no están
    if CurTime() - DeathUI.diedAt >= 1 then
        DeathUI_CreateButtons()
    end
end)

-- Comando para reabrir manualmente el menú
concommand.Add("ww2menu_open", function()
    if IsValid(g_WW2_Menu) then g_WW2_Menu:Remove() end
    WW2_AbrirMenu()
end)

function WW2_AbrirClases(faccion)
    local clases = WW2.CLASSES and WW2.CLASSES[faccion] or {}
    if #clases == 0 then return end

    local scrW, scrH = ScrW(), ScrH()
    local frame = vgui.Create("DFrame")
    frame:SetSize(scrW, scrH)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        PintarBlur(self, 5)
        surface.SetDrawColor(Color(10,10,10,245)) surface.DrawRect(0, 0, w, h)
        draw.SimpleText("Selecciona tu clase", "WW2_Titulo", w * 0.5, 80, color_white, TEXT_ALIGN_CENTER)
    end

    for i, clase in ipairs(clases) do
        local btn = vgui.Create("DButton", frame)
        btn:SetSize(scrW * 0.4, scrH * 0.12)
        btn:SetPos((scrW - btn:GetWide()) / 2, 160 + (i - 1) * (btn:GetTall() + 20))
        btn:SetText("")
        btn.Paint = function(self, w, h)
            surface.SetDrawColor(50,50,50,220) surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(255,255,255,20) surface.DrawOutlinedRect(0,0,w,h,2)
            draw.SimpleText(string.upper(clase.nombre), "WW2_Sub", w * 0.5, h * 0.3, color_white, TEXT_ALIGN_CENTER)
            draw.SimpleText(clase.descripcion, "WW2_Opcion", w * 0.5, h * 0.65, color_white, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function()
            net.Start("WW2_ElegirClase")
                net.WriteString(clase.id)
            net.SendToServer()
            surface.PlaySound("buttons/button14.wav")
            if IsValid(frame) then frame:Remove() end
        end
    end

    local btnCerrar = vgui.Create("DButton", frame)
    btnCerrar:SetSize(32, 32)
    btnCerrar:SetPos(scrW - 40, 8)
    btnCerrar:SetText("")
    btnCerrar.Paint = function(self, w, h)
        surface.SetDrawColor(200, 0, 0, 220)
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText("X", "WW2_Sub", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnCerrar.DoClick = function()
        if IsValid(frame) then frame:Remove() end
    end
end


