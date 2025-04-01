CreateClientConVar("bhop_centerbox_pos", "0", true, false, "Toggle a box under the player.")

hook.Add("PostDrawOpaqueRenderables", "DrawWireframeBoxUnderPlayer", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not GetConVar("bhop_centerbox_pos"):GetBool() then return end

    local boxSize = Vector(20, 20, 30)
    local boxOffset = Vector(0, 0, -ply:OBBMaxs().z + 64)

    local boxPos = ply:GetPos() + boxOffset

    local yawAngle = ply:EyeAngles().y
    local boxRotation = Angle(0, yawAngle, 0)

    render.SetColorMaterial()
    render.DrawWireframeBox(boxPos, boxRotation, -boxSize / 2, boxSize / 2, Color(0, 255, 0), true)
end)