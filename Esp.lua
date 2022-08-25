--[Main Variables]

local plrs = game["Players"]
local rs = game["RunService"]
local client = {}

for I,V in pairs(getgc(true)) do
    if type(V) == "table" then
        if rawget(V, "gammo") then
            client.gamelogic = V
        elseif rawget(V,"basecframe") then
            client.cam = V
        elseif rawget(V,"setbasewalkspeed") then
			client.char = V
        elseif rawget(V,"updateammo") then
            client.hud = V
        end
    elseif type(V) == "function" then
        if debug.getinfo(V).name == "getbodyparts" then
            client.chartbl = debug.getupvalue(V, 1)
        end
    end
    if client.gamelogic and client.chartbl and client.cam and client.char then break end
end

local plr = plrs.LocalPlayer
local mouse = plr:GetMouse()
local camera = workspace.CurrentCamera
local worldToViewportPoint = camera.worldToViewportPoint

--[Optimisation Variables]

local Drawingnew = Drawing.new
local Color3fromRGB = Color3.fromRGB
local Vector3new = Vector3.new
local Vector2new = Vector2.new
local mathfloor = math.floor
local mathceil = math.ceil

--[Setup Table]

local img_link = "https://i.ibb.co/x8Z4VGy/angryimg-5.png"

writefile("currentImage.jpg", img_link)

local img_tt = "https://i.ibb.co/x8Z4VGy/angryimg-5.png"

local esp = {
    players = {},
    objects = {},
    chams = {}, 
    enabled = false,
    teamcheck = false,
    fontsize = 13,
    font = 2,
    settings = {
        name = {enabled = false, outline = true, displaynames = true, color = Color3fromRGB(255, 255, 255)},
        box = {enabled = false, outline = true, filled = false, color = Color3fromRGB(255, 255, 255)},
        imagebox = {enabled = false, image = img_tt},
        healthbar = {enabled = false, size = 1, outline = true},
        healthtext = {enabled = false, outline = true, color = Color3fromRGB(255, 255, 255)},
        distance = {enabled = false, outline = true, color = Color3fromRGB(255, 255, 255)},
        viewangle = {enabled = false, outline = true, color = Color3fromRGB(255, 255, 255)},
    },
    settings_chams = {
        enabled = false,
        outline = true,
        fill_color = Color3fromRGB(255, 255, 255),
        outline_color = Color3fromRGB(0, 0, 0), 
        fill_transparency = 1,
        outline_transparency = 1,
        autocolor = true,
        autocolor_outline = true,
        settings_autocolor = {
            visible = Color3fromRGB(0, 255, 0),
            visibleFillTransparency = 0.5,
            visibleOutlineTransparency = 0.5,
            invisible = Color3fromRGB(255, 0, 0),
            invisibleFillTransparency = 1,
            invisibleOutlineTransparency = 0
        }
    }
}

local self_cham = {
    enabled = false,
    outline = true,
    fill_color = Color3fromRGB(255, 255, 255),
    fill_transparency = 0.5,
    outline_color = Color3fromRGB(0, 0, 0), 
    outline_transparency = 0,
}

local self_cham_instance = Instance.new("Highlight", game.CoreGui)



esp.NewDrawing = function(type, properties)
    local newDrawing = Drawingnew(type)

    for i,v in next, properties or {} do
        newDrawing[i] = v
    end

    return newDrawing
end

esp.NewCham = function(properties)
    local newCham = Instance.new("Highlight", game.CoreGui)

    for i,v in next, properties or {} do
        newCham[i] = v
    end
    

    return newCham
end

function IsAlive(player)
    if client.chartbl[player] and client.chartbl[player].head then
        return true 
    end
    return false
end


esp.WallCheck = function(player)
    if IsAlive(player) and client.chartbl[player] then
        local HeadPos = client.chartbl[player].head.Position
        local Hit = workspace:FindPartOnRayWithIgnoreList(Ray.new(camera.CFrame.p, HeadPos - camera.CFrame.p), {
            workspace.Ignore,
            workspace.Players,
            workspace.Terrain,
            camera,
            game.Players.LocalPlayer.Character
        })
        return Hit == nil
    end
    return false
end

esp.TeamCheck = function(v)
    if plr.TeamColor == v.TeamColor then
        return false
    end

    return true
end

function esp.GetHealth(Player)
    return client.hud:getplayerhealth(Player)
end
function esp.GetCharacter(Player)
    local Character = client.chartbl[Player]

    return Character and Character.torso.Parent, Character and Character.torso
end

esp.NewPlayer = function(v)
    esp.players[v] = {
        name = esp.NewDrawing("Text", {Color = Color3fromRGB(255, 255, 255), Outline = true, Center = true, Size = 13, Font = 2}),
        boxOutline = esp.NewDrawing("Square", {Color = Color3fromRGB(0, 0, 0), Thickness = 3}),
        box = esp.NewDrawing("Square", {Color = Color3fromRGB(255, 255, 255), Thickness = 1}),
        image = esp.NewDrawing("Image", {Data = game:HttpGet(img_link)}),
        healthBarOutline = esp.NewDrawing("Line", {Color = Color3fromRGB(0, 0, 0), Thickness = 3}),
        healthBar = esp.NewDrawing("Line", {Color = Color3fromRGB(255, 255, 255), Thickness = 1}),
        healthText = esp.NewDrawing("Text", {Color = Color3fromRGB(255, 255, 255), Outline = true, Center = true, Size = 13, Font = 2}),
        distance = esp.NewDrawing("Text", {Color = Color3fromRGB(255, 255, 255), Outline = true, Center = true, Size = 13, Font = 2}),
        viewAngle = esp.NewDrawing("Line", {Color = Color3fromRGB(255, 255, 255), Thickness = 1}),
        cham = esp.NewCham({FillColor = esp.settings_chams.fill_color, OutlineColor = esp.settings_chams.outline_color, FillTransparency = esp.settings_chams.fill_transparency, OutlineTransparency = esp.settings_chams.outline_transparency})
    }
end

for _,v in ipairs(plrs:GetPlayers()) do
    if v ~= plr then
        esp.NewPlayer(v)
    end
end

plrs.PlayerAdded:Connect(function(v)
    esp.NewPlayer(v)
end)

plrs.ChildRemoved:Connect(function(v)
    for i2,v2 in pairs(esp.players[v]) do
        pcall(function()
            v2:Remove()
            v2:Destroy()
        end)
    end

    esp.players[v] = nil
end)

local mainLoop = rs.RenderStepped:Connect(function()
    for i,v in pairs(esp.players) do
        local character,torso = esp.GetCharacter(i)
        if i ~= plr and character and torso  then
            local hrp = torso -- btw this is just torso not hrp too lazy i dont wanna change a lot of things
            local head = client.chartbl[i].head
            local Health,MaxHealth = esp.GetHealth(i)

            local Vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
    
            local Size = (camera:WorldToViewportPoint(hrp.Position - Vector3new(0, 3, 0)).Y - camera:WorldToViewportPoint(hrp.Position + Vector3new(0, 2.6, 0)).Y) / 2
            local BoxSize = Vector2new(mathfloor(Size * 1.5), mathfloor(Size * 1.9))
            local BoxPos = Vector2new(mathfloor(Vector.X - Size * 1.5 / 2), mathfloor(Vector.Y - Size * 1.6 / 2))
    
            local BottomOffset = BoxSize.Y + BoxPos.Y + 1

            if onScreen and esp.settings_chams.enabled then -- not sure ab this
                v.cham.Adornee = i.Character
                v.cham.Enabled = esp.settings_chams.enabled
                v.cham.OutlineTransparency =  esp.settings_chams.autocolor and esp.WallCheck(i) and esp.settings_chams.settings_autocolor.visibleOutlineTransparency or esp.settings_chams.autocolor and not esp.WallCheck(i) and esp.settings_chams.settings_autocolor.invisibleOutlineTransparency or esp.settings_chams.outline and esp.settings_chams.outline_transparency
                v.cham.OutlineColor = esp.settings_chams.autocolor and esp.settings_chams.autocolor_outline and esp.WallCheck(i) and esp.settings_chams.settings_autocolor.visible or esp.settings_chams.autocolor and esp.settings_chams.autocolor_outline and not esp.WallCheck(i) and esp.settings_chams.settings_autocolor.invisible or esp.settings_chams.outline_color
                v.cham.FillColor = esp.settings_chams.autocolor and esp.WallCheck(i) and esp.settings_chams.settings_autocolor.visible or esp.settings_chams.autocolor and not esp.WallCheck(i) and esp.settings_chams.settings_autocolor.invisible or esp.settings_chams.fill_color
                v.cham.FillTransparency = esp.settings_chams.autocolor and esp.WallCheck(i) and esp.settings_chams.settings_autocolor.visibleFillTransparency or esp.settings_chams.autocolor and not esp.WallCheck(i) and esp.settings_chams.settings_autocolor.invisibleFillTransparency or esp.settings_chams.fill_transparency
            else
                v.cham.Enabled = false
            end

            if onScreen and esp.enabled then
                if esp.settings.name.enabled then
                    v.name.Position = Vector2new(BoxSize.X / 2 + BoxPos.X, BoxPos.Y - 16)
                    v.name.Outline = esp.settings.name.outline
                    v.name.Color = esp.settings.name.color

                    v.name.Font = esp.font
                    v.name.Size = esp.fontsize

                    if esp.settings.name.displaynames then
                        v.name.Text = i.DisplayName
                    else
                        v.name.Text = i.Name
                    end

                    v.name.Visible = true
                else
                    v.name.Visible = false
                end

                if esp.settings.distance.enabled and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    v.distance.Position = Vector2new(BoxSize.X / 2 + BoxPos.X, BottomOffset)
                    v.distance.Outline = esp.settings.distance.outline
                    v.distance.Text = "[" .. mathfloor((hrp.Position - plr.Character.HumanoidRootPart.Position).Magnitude) .. "m]"
                    v.distance.Color = esp.settings.distance.color
                    BottomOffset = BottomOffset + 15

                    v.distance.Font = esp.font
                    v.distance.Size = esp.fontsize

                    v.distance.Visible = true
                else
                    v.distance.Visible = false
                end

                if esp.settings.box.enabled then
                    v.boxOutline.Size = BoxSize
                    v.boxOutline.Position = BoxPos
                    v.boxOutline.Visible = esp.settings.box.outline
    
                    v.box.Size = BoxSize
                    v.box.Position = BoxPos
                    v.box.Color = esp.settings.box.color
                    v.box.Visible = true
                else
                    v.boxOutline.Visible = false
                    v.box.Visible = false
                end

                if esp.settings.imagebox.enabled then
                    v.image.Size = BoxSize
                    v.image.Position = BoxPos
                    v.image.Visible = true
                else
                    v.image.Visible = false
                end

                if esp.settings.healthbar.enabled then
                    v.healthBar.From = Vector2new((BoxPos.X - 5), BoxPos.Y + BoxSize.Y)
                    v.healthBar.To = Vector2new(v.healthBar.From.X, v.healthBar.From.Y - (Health / MaxHealth) * BoxSize.Y)
                    v.healthBar.Color = Color3fromRGB(255 - 255 / (MaxHealth / Health), 255 / (MaxHealth / Health), 0)
                    v.healthBar.Visible = true
                    v.healthBar.Thickness = esp.settings.healthbar.size

                    v.healthBarOutline.From = Vector2new(v.healthBar.From.X, BoxPos.Y + BoxSize.Y + 1)
                    v.healthBarOutline.To = Vector2new(v.healthBar.From.X, (v.healthBar.From.Y - 1 * BoxSize.Y) -1)
                    v.healthBarOutline.Visible = esp.settings.healthbar.outline
                    v.healthBarOutline.Thickness = esp.settings.healthbar.size + 2
                else
                    v.healthBarOutline.Visible = false
                    v.healthBar.Visible = false
                end

                if esp.settings.healthtext.enabled then
                    v.healthText.Text = tostring(mathfloor((Health / MaxHealth) * 100 + 0.5))
                    v.healthText.Position = Vector2new((BoxPos.X - 20), (BoxPos.Y + BoxSize.Y - 1 * BoxSize.Y) -1)
                    v.healthText.Color = esp.settings.healthtext.color
                    v.healthText.Outline = esp.settings.healthtext.outline

                    v.healthText.Font = esp.font
                    v.healthText.Size = esp.fontsize

                    v.healthText.Visible = true
                else
                    v.healthText.Visible = false
                end

                if esp.settings.viewangle.enabled and head and head.CFrame then
                    v.viewAngle.From = Vector2new(camera:worldToViewportPoint(head.CFrame.p).X, camera:worldToViewportPoint(head.CFrame.p).Y)
                    v.viewAngle.To = Vector2new(camera:worldToViewportPoint((head.CFrame + (head.CFrame.lookVector * 10)).p).X, camera:worldToViewportPoint((head.CFrame + (head.CFrame.lookVector * 10)).p).Y)
                    v.viewAngle.Color = esp.settings.viewangle.color
                    v.viewAngle.Visible = true
                else
                    v.viewAngle.Visible = false
                end

                if esp.teamcheck then
                    if esp.TeamCheck(i) then
						
							
                        v.name.Visible = esp.settings.name.enabled
                        v.box.Visible = esp.settings.box.enabled
                        v.image.Visible = esp.settings.imagebox.enabled
                        v.healthBar.Visible = esp.settings.healthbar.enabled
                        v.healthText.Visible = esp.settings.healthtext.enabled
                        v.distance.Visible = esp.settings.distance.enabled
                        v.viewAngle.Visible = esp.settings.viewangle.enabled
							
							
                    else
						
							
							
                        v.name.Visible = false
                        v.boxOutline.Visible = false
                        v.box.Visible = false
                        v.image.Visible = false
                        v.healthBarOutline.Visible = false
                        v.healthBar.Visible = false
                        v.healthText.Visible = false
                        v.distance.Visible = false
                        v.viewAngle.Visible = false
							
							
                    end
                end
            else
                v.name.Visible = false
                v.boxOutline.Visible = false
                v.box.Visible = false
                v.image.Visible = false
                v.healthBarOutline.Visible = false
                v.healthBar.Visible = false
                v.healthText.Visible = false
                v.distance.Visible = false
                v.viewAngle.Visible = false
            end
        else
            v.name.Visible = false
            v.boxOutline.Visible = false
            v.box.Visible = false
            v.image.Visible = false
            v.healthBarOutline.Visible = false
            v.healthBar.Visible = false
            v.healthText.Visible = false
            v.distance.Visible = false
            v.viewAngle.Visible = false
            v.cham.Enabled = false
        end
    end
end)

getgenv().esp = esp
getgenv().self_cham = self_cham
