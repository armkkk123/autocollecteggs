-- ==========================================
-- 🛡️ ANTI-AFK & ANTI-CRASH SYSTEM (กันเตะ+กันเด้ง)
-- ==========================================
pcall(function()
    -- 1. Anti-AFK (ดิ้นเมาส์จำลอง)
    local vu = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end)

pcall(function()
    -- 2. Anti-Lag & Memory Optimizer (ลดกราฟิกเพลียเครื่อง)
    -- ฟาร์มมานานแรมอาจจะล้น การใช้ Level01 จะช่วยเซฟแรมตอนเราโหลดแมพเร็วๆ
    settings().Rendering.QualityLevel = "Level01"
    settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
end)

pcall(function()
    -- 3. Auto-Reconnect 
    -- ถ้าติดหน้าต่าง Disconnect (277/268) กลางเซิร์ฟ ให้สคริปต์สแกนแล้วยิงวาร์ปหลบกลับ Lobby
    local coreGui = game:GetService("CoreGui")
    local promptOverlay = coreGui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")
    
    promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" then
            task.wait(2)
            -- บังคับรีคอนเนคเข้า 99 Nights
            local ts = game:GetService("TeleportService")
            ts:Teleport(79546208627805, game:GetService("Players").LocalPlayer)
        end
    end)
end)

-- ==========================================
-- 💡 CUSTOM CLEAN UI (HUD)
-- ==========================================
local coreGui = game:GetService("CoreGui")
local oldGui = coreGui:FindFirstChild("AutoFarmHUD")
if oldGui then oldGui:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "AutoFarmHUD"
pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(sg)
        sg.Parent = coreGui
    elseif gethui then
        sg.Parent = gethui()
    else
        sg.Parent = coreGui
    end
end)

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 75)
frame.Position = UDim2.new(0.5, -140, 0, 20) -- ด้านบนตรงกลาง
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.2 -- โปร่งแสงนิดๆ จะได้ดูสวย
frame.BorderSizePixel = 0
frame.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

-- ขอบเงาสวยๆ (UIStroke)
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 255, 150)
stroke.Thickness = 2
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 5)
title.BackgroundTransparency = 1
title.Text = "🛡️ RUAJADHUB | 99 Nights"
title.TextColor3 = Color3.fromRGB(0, 255, 150) -- สีเขียวนีออนตามแบรนด์
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -20, 0, 35)
statusText.Position = UDim2.new(0, 10, 0, 35)
statusText.BackgroundTransparency = 1
statusText.Text = "Status: Waiting..."
statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 14
statusText.TextWrapped = true
statusText.Parent = frame

local function UpdateStatus(text)
    if statusText then
        statusText.Text = "Status: " .. text
    end
end

-- ==========================================
-- ⚙️ CORE SYSTEM
-- ==========================================
_G.AutoPullEgg = true
_G.AutoHop = true

local function ServerHop()
    UpdateStatus("Searching for Low-Player Server...")
    task.wait(1)
    
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local Player = game:GetService("Players").LocalPlayer
    
    local lobbyId = game.PlaceId
    
    -- 1. หา Place ID ของ Lobby แท้
    pcall(function()
        local universeId = game.GameId
        local url = "https://games.roblox.com/v1/games?universeIds=" .. tostring(universeId)
        local body = game:HttpGet(url)
        local data = HttpService:JSONDecode(body)
        if data and data.data and data.data[1] and data.data[1].rootPlaceId then
            lobbyId = data.data[1].rootPlaceId
        end
    end)
    
    -- 2. สแกนหาเซิร์ฟเวอร์ที่มีคนน้อยที่สุด (เรียงจากน้อยไปมาก: Asc)
    local successAPI, serverResponse = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(lobbyId) .. "/servers/Public?sortOrder=Asc&limit=100")
    end)
    
    local hopped = false
    if successAPI then
        pcall(function()
            local data = HttpService:JSONDecode(serverResponse)
            if data and data.data then
                for _, server in ipairs(data.data) do
                    -- หาห้องที่มีคนเล่นน้อยกว่า 5 คนและไม่ใช่ห้องเดิม
                    if server.playing and server.maxPlayers and server.id ~= game.JobId then
                        if server.playing < server.maxPlayers and server.playing > 0 then
                            UpdateStatus("Found Empty Server! Teleporting...")
                            TeleportService:TeleportToPlaceInstance(lobbyId, server.id, Player)
                            hopped = true
                            break
                        end
                    end
                end
            end
        end)
    end
    
    -- 3. Fallback: ถ้าหาเซิร์ฟคนน้อยไม่เจอ (หรือบั๊ก) ให้วาร์ปแบบสุ่มตามปกติ
    if not hopped then
        UpdateStatus("API Failed or No Empty Servers - Standard Hopping...")
        local success, err = pcall(function()
            TeleportService:Teleport(lobbyId, Player)
        end)
        
        if not success then
            UpdateStatus("Hop Error: "..tostring(err))
        end
    end
end

local function PullEggs()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Remotes = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")
    local StartDrag = Remotes and Remotes:FindFirstChild("RequestStartDraggingItem")
    local StopDrag = Remotes and Remotes:FindFirstChild("StopDraggingItem")
    
    -- 🕒 ปรับเป็น 5 วินาทีตามสั่งครับ เผื่อคนเน็ตช้าจะได้โหลดไข่ทันชัวร์ๆ
    UpdateStatus("Waiting 5s for Map Loading...")
    task.wait(5)
    
    UpdateStatus("Collecting All Eggs Instantly...")
    
    local itemsFolder = workspace:FindFirstChild("Items")
    local character = LocalPlayer.Character
    
    if character and character:FindFirstChild("HumanoidRootPart") and itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item.Name == "Basic Egg" then
                pcall(function()
                    local root = item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) or (item:IsA("BasePart") and item)
                    if root then
                        local mainPart = item:FindFirstChild("Main")
                        if mainPart then mainPart.Anchored = false end
                        
                        for _, desc in pairs(item:GetDescendants()) do
                            if desc:IsA("Constraint") or desc:IsA("AlignOrientation") or desc:IsA("AlignPosition") 
                               or desc:IsA("AngularVelocity") or desc:IsA("LinearVelocity")
                               or desc:IsA("BodyGyro") or desc:IsA("BodyPosition") or desc:IsA("BodyVelocity") then
                                desc.Enabled = false
                            end
                        end
                        
                        -- CFrame ฐานส่งไข่
                        local deliveryCFrame = CFrame.new(2.73, 4.53, 72.02, -0.937, 0.000, 0.350, 0.000, 1.000, 0.000, -0.350, 0.000, -0.937)
                        if item:IsA("Model") then
                            item:PivotTo(deliveryCFrame)
                        else
                            root.CFrame = deliveryCFrame
                        end
                        
                        -- รัวรีโมทส่ง
                        if StartDrag and StopDrag then
                            for i = 1, 25 do 
                                StartDrag:FireServer(item)
                                StopDrag:FireServer(item)
                            end
                        end
                        
                        local npcEvent = item:FindFirstChild("NpcEvent")
                        if npcEvent and npcEvent:IsA("RemoteEvent") then
                            npcEvent:FireServer()
                        end
                    end
                end)
            end
        end
    end
    
    -- กฎเหล็ก: ทำเสร็จปุ๊บ รอ 3 วิ แล้วเตะออกทันที ไม่มีอิดออด!
    UpdateStatus("Eggs Delivered! Rejoining in 3s...")
    task.wait(3)
    ServerHop()
end

-- ==========================================
-- 🔄 QUEUE ON TELEPORT (เซตค่าอมตะข้ามเซิร์ฟ)
-- ==========================================
pcall(function()
    queue_on_teleport([[
        repeat task.wait() until game:IsLoaded()
        if isfile and isfile("main99.lua") then
            loadstring(readfile("main99.lua"))()
        end
    ]])
end)

-- ==========================================
-- 🚪 AUTO-LOBBY SYSTEM
-- ==========================================
local LOBBY_PLACE_ID = 79546208627805

local function AutoLobbyStart()
    if game.PlaceId == LOBBY_PLACE_ID then
        UpdateStatus("At Lobby - Waiting for Load...")
        task.wait(2) -- เพิ่มดีเลย์ 2 วิเพื่อให้โหลดภาพและ UI ทันครับ
        
        UpdateStatus("Hiding Unnecessary UI...")
        local Player = game:GetService("Players").LocalPlayer
        local character = Player.Character or Player.CharacterAdded:Wait()
        local pg = Player:WaitForChild("PlayerGui")
        
        pcall(function()
            local interface = pg:FindFirstChild("Interface")
            if interface then
                for _, frameName in ipairs({"EntryScreen", "RejoinFrame", "ChristmasInstructions"}) do
                    local frame = interface:FindFirstChild(frameName)
                    if frame then frame.Visible = false end
                end
            end
        end)
        -- ลบหน่วงเวลา 1 วิทิ้งเลยเพื่อความลื่น
        
        local zones = {
            CFrame.new(-22.50, 4.95, 26.12, 0.005, -0.000, -1.000, -0.000, 1.000, -0.000, 1.000, 0.000, 0.005), -- ช่อง 1
            CFrame.new(-22.60, 4.95, 3.51, -0.010, -0.000, -1.000, -0.000, 1.000, -0.000, 1.000, 0.000, -0.010),  -- ช่อง 2
            CFrame.new(-22.42, 4.95, -19.12, 0.006, -0.000, -1.000, 0.000, 1.000, -0.000, 1.000, 0.000, 0.006)   -- ช่อง 3
        }
        local currentZoneIndex = 1

        UpdateStatus("Teleporting to Zone 1...")
        pcall(function()
            local hrp = character:WaitForChild("HumanoidRootPart", 5)
            if hrp then
                hrp.CFrame = zones[currentZoneIndex]
            end
        end)
        task.wait(1) -- ลดดีเลย์จาก 3 เหลือ 1 เพื่อความไว
        
        UpdateStatus("Detecting Party Window...")
        
        -- 💡 ใช้ LOOP เดินสลับช่อง 1, 2, 3 จนกว่าหน้าต่างจะเด้ง!
        while true do
            local lobbyCreate = pg.Interface:FindFirstChild("LobbyCreate")
            if lobbyCreate and lobbyCreate.Visible == true then
                break -- หน้าต่างเด้งแล้ว! ออกลูปไปกดสร้างตี้ได้เลย
            end
            
            pcall(function()
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    -- ขยับไปช่องถัดไป (ถ้าเกิน 3 ให้วนกลับมา 1 ใหม่)
                    currentZoneIndex = currentZoneIndex + 1
                    if currentZoneIndex > #zones then currentZoneIndex = 1 end
                    
                    UpdateStatus("Zone Full! Trying Zone " .. currentZoneIndex .. "...")
                    hrp.CFrame = zones[currentZoneIndex]
                end
            end)
            task.wait(3) -- รอชัวร์ๆ 3 วิให้หน้าต่างเด้ง
        end
        
        pcall(function()
            UpdateStatus("Zone Open! Selecting Solo Mode...")
            local btn1 = pg.Interface.LobbyCreate.ButtonList.Button1
            if btn1 then
                for _, connection in pairs(getconnections(btn1.MouseButton1Click)) do connection:Fire() end
                for _, connection in pairs(getconnections(btn1.MouseButton1Down)) do connection:Fire() end
            end
            
            task.wait(1)
            
            UpdateStatus("Clicking 'Create'...")
            local createBtn = pg.Interface.LobbyCreate.HeaderFrame.CreateButton
            if createBtn then
                for _, connection in pairs(getconnections(createBtn.MouseButton1Click)) do connection:Fire() end
                for _, connection in pairs(getconnections(createBtn.MouseButton1Down)) do connection:Fire() end
            end
        end)
        
        UpdateStatus("Waiting for Game Entry...")
        return true
    end
    return false
end

task.spawn(function()
    -- 🚀 รันทันที! ไม่ต้องรอ task.wait(3) แล้ว
    local isLobby = AutoLobbyStart()
    
    if not isLobby then
        UpdateStatus("In Game! Starting Auto-Farm 🥚")
        task.spawn(PullEggs)
    end
end)
