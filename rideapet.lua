-- ╔══════════════════════════════════════╗
-- ║   Ride a Pet Hub v2 | by 6larping7  ║
-- ║   Xeno / Fluxus / Synapse uyumlu    ║
-- ╚══════════════════════════════════════╝
local ok, err = pcall(function()
-- SERVICES
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local RS           = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local lp           = Players.LocalPlayer
local mouse        = lp:GetMouse()
-- CHARACTER SETUP
local char, hrp, hum
local function setupChar()
    char = lp.Character or lp.CharacterAdded:Wait()
    hrp  = char:WaitForChild("HumanoidRootPart", 10)
    hum  = char:WaitForChild("Humanoid", 10)
end
setupChar()
lp.CharacterAdded:Connect(setupChar)
-- CONFIG
local CFG = {
    AutoFarm     = false,
    AutoRide     = false,
    AutoHatch    = false,
    AutoSell     = false,
    InfJump      = false,
    NoClip       = false,
    Speed        = 60,
    JumpPower    = 80,
    FarmRadius   = 300,
}
-- NOTIFY
local function notify(t, b)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",{
            Title=t, Text=b, Duration=4
        })
    end)
end
-- ══════════════════════════════
-- SPEED / JUMP LOOP
-- ══════════════════════════════
RunService.Heartbeat:Connect(function()
    pcall(function()
        if hum and hum.Parent then
            hum.WalkSpeed = CFG.Speed
            hum.JumpPower = CFG.JumpPower
        end
    end)
end)
-- ══════════════════════════════
-- INF JUMP
-- ══════════════════════════════
UIS.JumpRequest:Connect(function()
    if CFG.InfJump and hum then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end)
-- ══════════════════════════════
-- NO CLIP
-- ══════════════════════════════
RunService.Stepped:Connect(function()
    if not CFG.NoClip or not char then return end
    pcall(function()
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end)
-- ══════════════════════════════
-- REMOTE BULUCU (otomatik tarar)
-- ══════════════════════════════
local function findRemote(...)
    local names = {...}
    -- ReplicatedStorage içini tara
    for _, name in ipairs(names) do
        local r = RS:FindFirstChild(name, true)
        if r then return r end
    end
    -- Workspace içini tara
    for _, name in ipairs(names) do
        local r = workspace:FindFirstChild(name, true)
        if r then return r end
    end
    return nil
end
-- ══════════════════════════════
-- AUTO FARM
-- ══════════════════════════════
local farmCount = 0
local function doFarm()
    if not CFG.AutoFarm or not hrp then return end
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if not CFG.AutoFarm then break end
            local n = obj.Name:lower()
            if obj:IsA("BasePart") and (
                n:find("coin") or n:find("gem") or n:find("token")
                or n:find("reward") or n:find("collec") or n:find("xp")
                or n:find("money") or n:find("cash")
            ) then
                local dist = (obj.Position - hrp.Position).Magnitude
                if dist < CFG.FarmRadius then
                    hrp.CFrame = CFrame.new(obj.Position + Vector3.new(0,3,0))
                    farmCount = farmCount + 1
                    task.wait(0.08)
                end
            end
        end
    end)
end
-- ══════════════════════════════
-- AUTO RIDE
-- ══════════════════════════════
local function doRide()
    if not CFG.AutoRide or not hrp then return end
    pcall(function()
        -- Pet klasörlerini dene
        local pFolder = workspace:FindFirstChild("Pets")
            or workspace:FindFirstChild("PetModels")
            or workspace:FindFirstChild("SpawnedPets")
        if not pFolder then
            -- Tüm workspace'i tara
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj.Name:lower():find("pet") then pFolder = obj break end
            end
        end
        if not pFolder then notify("Ride Hub","Pet klasörü bulunamadı!") return end
        local best, bestDist, bestRoot = nil, math.huge, nil
        for _, pet in ipairs(pFolder:GetChildren()) do
            local root = pet:FindFirstChild("HumanoidRootPart")
                or pet:FindFirstChild("Root")
                or pet.PrimaryPart
                or pet:FindFirstChildWhichIsA("BasePart")
            if root then
                local d = (root.Position - hrp.Position).Magnitude
                if d < bestDist then
                    best = pet bestDist = d bestRoot = root
                end
            end
        end
        if not best then notify("Ride Hub","Yakında pet yok!") return end
        -- Remote dene
        local rideRemote = findRemote(
            "RideEvent","Ride","RidePet","MountPet",
            "PetRide","OnRide","RequestRide","RideRequest"
        )
        if rideRemote then
            rideRemote:FireServer(best)
            notify("Ride Hub","Pete binildi! 🐾")
        else
            -- Remote yoksa tp yap
            hrp.CFrame = CFrame.new(bestRoot.Position + Vector3.new(0,4,0))
            notify("Ride Hub","TP ile pete bindi (remote yok)")
        end
    end)
end
-- ══════════════════════════════
-- AUTO HATCH
-- ══════════════════════════════
local function doHatch()
    if not CFG.AutoHatch or not hrp then return end
    pcall(function()
        local hatchRemote = findRemote(
            "Hatch","HatchEgg","OpenEgg","BuyEgg",
            "EggHatch","HatchRequest","PurchaseEgg"
        )
        local eggZones = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if obj:IsA("BasePart") and (n:find("egg") or n:find("hatch")) then
                table.insert(eggZones, obj)
            end
        end
        for _, egg in ipairs(eggZones) do
            hrp.CFrame = CFrame.new(egg.Position + Vector3.new(0,4,0))
            task.wait(0.5)
            if hatchRemote then
                pcall(function() hatchRemote:FireServer(egg.Parent or egg) end)
                task.wait(0.3)
            end
        end
    end)
end
-- ══════════════════════════════
-- AUTO SELL
-- ══════════════════════════════
local function doSell()
    if not CFG.AutoSell then return end
    pcall(function()
        local sellRemote = findRemote(
            "SellPets","Sell","SellAll","AutoSell",
            "PetSell","SellRequest","SellPet"
        )
        if sellRemote then
            sellRemote:FireServer()
            notify("Ride Hub","Petler satıldı! 💰")
        else
            notify("Ride Hub","Sell remote'u bulunamadı")
        end
    end)
end
-- ══════════════════════════════
-- MAIN LOOPS
-- ══════════════════════════════
task.spawn(function()
    while task.wait(1.5) do pcall(doFarm) end
end)
task.spawn(function()
    while task.wait(5) do pcall(doRide) end
end)
task.spawn(function()
    while task.wait(25) do pcall(doHatch) pcall(doSell) end
end)
-- ══════════════════════════════
-- GUI
-- ══════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "RideHubV2"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end
-- Ana frame
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 230, 0, 320)
main.Position = UDim2.new(0, 15, 0.25, 0)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)
-- Başlık
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,38)
title.BackgroundColor3 = Color3.fromRGB(100,50,220)
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Text = "🥔  Ride a Pet Hub  v2"
title.Parent = main
Instance.new("UICorner", title).CornerRadius = UDim.new(0,12)
-- Toggle buton factory
local function makeToggle(label, cfgKey, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-20,0,32)
    btn.Position = UDim2.new(0,10,0,yPos)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = main
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,8)
    local function refresh()
        local on = CFG[cfgKey]
        btn.Text = (on and "✅ " or "❌ ") .. label
        btn.BackgroundColor3 = on
            and Color3.fromRGB(35,110,55)
            or  Color3.fromRGB(110,35,35)
        btn.TextColor3 = Color3.new(1,1,1)
    end
    refresh()
    btn.MouseButton1Click:Connect(function()
        CFG[cfgKey] = not CFG[cfgKey]
        refresh()
    end)
end
makeToggle("Auto Farm",   "AutoFarm",  48)
makeToggle("Auto Ride",   "AutoRide",  88)
makeToggle("Auto Hatch",  "AutoHatch", 128)
makeToggle("Auto Sell",   "AutoSell",  168)
makeToggle("Infinite Jump","InfJump",  208)
makeToggle("No Clip",     "NoClip",   248)
-- Stats
local stats = Instance.new("TextLabel")
stats.Size = UDim2.new(1,-10,0,22)
stats.Position = UDim2.new(0,5,0,288)
stats.BackgroundTransparency = 1
stats.TextColor3 = Color3.fromRGB(160,160,255)
stats.Font = Enum.Font.Gotham
stats.TextSize = 11
stats.Parent = main
RunService.Heartbeat:Connect(function()
    pcall(function()
        stats.Text = string.format("Farmed: %d | Speed: %d | Jump: %d",
            farmCount, CFG.Speed, CFG.JumpPower)
    end)
end)
notify("Ride a Pet Hub v2","Script yüklendi! 🥔 absolute 6larping7", 5)
end) -- pcall sonu
if not ok then
    -- Hata varsa ekrana yaz
    local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui"); sg.Parent = pg
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0,400,0,60)
    lbl.Position = UDim2.new(0.5,-200,0,10)
    lbl.BackgroundColor3 = Color3.fromRGB(180,30,30)
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextWrapped = true
    lbl.Text = "HATA: " .. tostring(err)
    lbl.Parent = sg
end
