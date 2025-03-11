CreateClientConVar("bhop_showzones", "1", true, false, "Toggle visibility of bhop zones")

local Col = HSVToColor(RealTime() * 40 % 360, 1, 1)
local Iv = IsValid

local Zone = {
    MStart = 0, MEnd = 1,
    BStart = 2, BEnd = 3,
    FS = 5, AC = 4,
    BAC = 7, NAC = 6,
    SStart = 8, SEnd = 9,
    Restart = 10, Velocity = 11,
    HELPER = 130
}

local normal = Material(BHOP.Zone.ZoneMaterial or "models/wireframe")

function ENT:UpdateZoneData()
    local min, max = self:GetCollisionBounds()
    local pos = self:GetPos()

    self.ZoneData = {
        set1 = {
            Vector(min.x, min.y, min.z), Vector(min.x, max.y, min.z), 
            Vector(max.x, max.y, min.z), Vector(max.x, min.y, min.z)
        },
        set2 = {
            Vector(min.x, min.y, max.z), Vector(min.x, max.y, max.z), 
            Vector(max.x, max.y, max.z), Vector(max.x, min.y, max.z)
        },
        min = min,
        max = max,
        pos = pos
    }
end

function ENT:Initialize()
    local min, max = self:GetCollisionBounds()
    self:SetRenderBounds(min, max)

    local GetPos = self:GetPos()
    min = GetPos + min
    max = GetPos + max

    self.bl = Vector(min.x, min.y, min.z)
    self.tl = Vector(min.x, max.y, min.z)
    self.tr = Vector(max.x, max.y, min.z)
    self.br = Vector(max.x, min.y, min.z)
    self.initialized = true
end

local DrawArea = {
    [Zone.MStart] = Color(0, 255, 0, 255),
    [Zone.MEnd] = Color(255, 0, 0, 255),
    [Zone.BStart] = Color(0, 80, 255, 255),
    [Zone.BEnd] = Color(0, 80, 255, 100),
    [Zone.FS] = Color(0, 80, 255, 100),
    [Zone.AC] =  Color(153, 0, 153, 100),
    [Zone.BAC] = Color(0, 0, 153, 100),
    [Zone.NAC] = Color(140, 140, 140, 100),
    [Zone.SStart] = Color(255, 128, 0, 100),
    [Zone.SEnd] = Color(255, 128, 128, 100),
    [Zone.Restart] = Color(128, 0, 255, 100),
    [Zone.Velocity] = Color(255, 0, 128, 100),
    [Zone.HELPER] = Color(255, 0, 128, 100),
}

function ENT:Draw()
    if not GetConVar("bhop_showzones"):GetBool() then return end

    self:UpdateZoneData()

    local Col = DrawArea[self:GetNWInt("zonetype")]
    if not Col then return end
    UTIL:DrawZone(self.ZoneData.set1, self.ZoneData.set2, Col, false, self.ZoneData.pos)
end

function UTIL:DrawZone(set1, set2, colour, fill, pos)
    if not colour then return end

    if not fill then
        render.DrawWireframeBox(pos, Angle(0, 0, 0), set1[1], set2[3], colour, true)
    else
        render.DrawBox(pos, Angle(0, 0, 0), set1[1], set2[3], colour)
    end
end