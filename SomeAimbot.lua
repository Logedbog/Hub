if _G.AlreadyRanItBroDanger then
    return
end

_G.AlreadyRanItBroDanger = ""

local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local teams = game:GetService("Teams")
local plr = players.LocalPlayer
local ms = plr:GetMouse()
local cam = workspace.CurrentCamera

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    cam = workspace.CurrentCamera
end)


_G.aimbotOn = false

function canSee(part, des)
    local origin = cam.CFrame.Position
    local _, onscreen = cam:WorldToViewportPoint(part.Position)
    
    if onscreen then
        local ray = Ray.new(origin, part.Position - origin)
        local hit = workspace:FindPartOnRayWithIgnoreList(ray, plr.Character:GetDescendants())
        local vis = false
        
        if hit and hit:IsDescendantOf(des) then
            vis = true
        else
            vis = false
        end
        
        return vis
    else
        return false
    end
end

function getClosestPlrToMouse()
    local closest, distance = nil, math.huge

    for i, v in pairs(players:GetPlayers()) do
        if v ~= plr then
            pcall(function()
                local checkPassed = true
    
                if _G.TeamCheck then
                    if plr.TeamColor == v.TeamColor then
                        checkPassed = false
                    end
                end
    
                if (ms.Hit.Position - v.Character.PrimaryPart.Position).magnitude < distance and checkPassed then
                    if canSee(v.Character.Head, v.Character) and v.Character.Humanoid.Health > 0 then
                        closest = v
                        distance = (ms.Hit.Position - v.Character.PrimaryPart.Position).magnitude
                    end
                end
            end)
        end
    end

    return closest, distance
end

uis.InputBegan:Connect(function(input, processed)
    if not processed then
        if _G.AimbotInput == "LeftClick" and input.UserInputType == Enum.UserInputType.MouseButton1 then
            _G.aimbotOn = true
        elseif _G.AimbotInput == "RightClick" and input.UserInputType == Enum.UserInputType.MouseButton2 then
            _G.aimbotOn = true
        elseif input.KeyCode.Name == _G.AimbotInput then
            _G.aimbotOn = true
        end
    end
end)

uis.InputEnded:Connect(function(input, processed)
    if not processed then
        if _G.AimbotInput == "LeftClick" and input.UserInputType == Enum.UserInputType.MouseButton1 then
            _G.aimbotOn = false
        elseif _G.AimbotInput == "RightClick" and input.UserInputType == Enum.UserInputType.MouseButton2 then
            _G.aimbotOn = false
        elseif input.KeyCode.Name == _G.AimbotInput then
            _G.aimbotOn = false
        end
    end
end)

while task.wait() do
    if _G.aimbotOn then
        local targ = getClosestPlrToMouse()
        if targ then
            local currentcf = workspace.CurrentCamera.CFrame
            workspace.CurrentCamera.CFrame = currentcf:Lerp(CFrame.new(currentcf.Position, targ.Character.Head.Position), _G.AimbotEasing)
        end
    end
end
