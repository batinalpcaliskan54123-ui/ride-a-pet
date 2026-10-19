-- Ride a Pet | Xeno/Synapse/Fluxus uyumlu
-- Game: Ride a Pet (Roblox)
-- Lua 5.1 (Roblox VM)
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local lp          = Players.LocalPlayer
local char        = lp.Character or lp.CharacterAdded:Wait()
local hrp         = char:WaitForChild("HumanoidRootPart")
local hum         = char:WaitForChild("Humanoid")
-- ════════════════════════════════════════
--  CONFIG
-- ════════════════════════════════════════
local CFG = {
    AutoFarm       = true,   -- otomatik para/xp topla
    AutoRide       = true,   -- en iyi peti otomatik bin
    AutoHatch      = false,  -- yumurtaları otomatik aç
    WalkSpeed      = 60,     -- default 16
    JumpPower      = 80,     -- default 50
    InfiniteJump   = true,
    NoClip         = false,
    AutoSell       = false,  -- petleri otomatik sat
    FarmRadius     = 200,    -- farm menzili (studs)
    TeleportFarm   = true,   -- farm noktalarına tp
}
-- ════════════════════════════════════════
--  UTILS
-- ════════════════════════════════════════
local function notify(title, body, dur)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title    = title,
        Text     = body,
        Duration = dur or 4,
    })
end
local function getChar()
    char = lp.Character
    hrp  = char and char:FindFirstChild("HumanoidRootPart")
    hum  = char and char:FindFirstChild("Humanoid")
end
lp.CharacterAdded:Connect(getChar)
-- ════════════════════════════════════════
--  SPEED & JUMP
-- ════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not hum then return end
    hum.WalkSpeed = CFG.WalkSpeed
    hum.JumpPower = CFG.JumpPower
end)
-- ════════════════════════════════════════
--  INFINITE JUMP
-- ════════════════════════════════════════
if CFG.InfiniteJump then
    game:GetService("UserInputService").JumpRequest:Connect(function()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end
-- ════════════════════════════════════════
--  NO CLIP
-- ════════════════════════════════════════
if CFG.NoClip then
    RunService.Stepped:Connect(function()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end
-- ════════════════════════════════════════
--  AUTO RIDE (en yakın/en iyi pet'e bin)
-- ════════════════════════════════════════
local function findBestPet()
    -- Pet'ler genelde workspace'te "Pets" klasöründe durur
    local petsFolder = workspace:FindFirstChild("Pets")
    if not petsFolder then return nil end
    local best, bestDist = nil, math.huge
    for _, pet in ipairs(petsFolder:GetChildren()) do
        local petRoot = pet:FindFirstChild("HumanoidRootPart") or pet:FindFirstChild("Root")
        if petRoot and hrp then
            local dist = (petRoot.Position - hrp.Position).Magnitude
            if dist < bestDist then
                best     = pet
                bestDist = dist
            end
        end
    end
    return best
end
local function autoRide()
    if not CFG.AutoRide then return end
    local pet = findBestPet()
    if not pet then
        notify("Ride a Pet", "Pet bulunamadı!", 3)
        return
    end
    -- Remote event adını oyuna göre ayarla
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("RideEvent")
        or game:GetService("ReplicatedStorage"):FindFirstChild("Ride")
        or game:GetService("ReplicatedStorage"):FindFirstChildWhichIsA("RemoteEvent")
    if remote then
        remote:FireServer(pet)
        notify("Ride a Pet", "Pet'e binildi: " .. pet.Name, 3)
    else
        -- Fallback: karakteri pet'e tp et
        if hrp then
            local petRoot = pet:FindFirstChild("HumanoidRootPart") or pet:FindFirstChild("Root")
            if petRoot then hrp.CFrame = petRoot.CFrame + Vector3.new(0, 3, 0) end
        end
        notify("Ride a Pet", "Remote bulunamadı, tp ile bindi.", 3)
    end
end
-- ════════════════════════════════════════
--  AUTO FARM (coin / xp topla)
-- ════════════════════════════════════════
local farmedCount = 0
local function autoFarm()
    if not CFG.AutoFarm or not hrp then return end
    -- Coin/collectible objeleri workspace'ten tara
    local targets = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("coin") or name:find("gem") or name:find("xp")
               or name:find("reward") or name:find("collect") then
                local root = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                if root then
                    local dist = (root.Position - hrp.Position).Magnitude
                    if dist < CFG.FarmRadius then
                        table.insert(targets, {obj = root, dist = dist})
                    end
                end
            end
        end
    end
    -- En yakına git / tp yap
    table.sort(targets, function(a, b) return a.dist < b.dist end)
    for _, t in ipairs(targets) do
        if CFG.TeleportFarm and hrp then
            hrp.CFrame = CFrame.new(t.obj.Position + Vector3.new(0, 3, 0))
            farmedCount = farmedCount + 1
            task.wait(0.1)
        end
    end
end
-- ════════════════════════════════════════
--  AUTO HATCH
-- ════════════════════════════════════════
local function autoHatch()
    if not CFG.AutoHatch then return end
    local eggs = workspace:FindFirstChild("Eggs") or workspace:FindFirstChild("EggArea")
    if not eggs then return end
    for _, egg in ipairs(eggs:GetChildren()) do
        local eggRoot = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
        if eggRoot and hrp then
            hrp.CFrame = CFrame.new(eggRoot.Position + Vector3.new(0, 3, 0))
            task.wait(0.3)
            -- Hatch remote'unu ateşle
            local hatchRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Hatch")
                or game:GetService("ReplicatedStorage"):FindFirstChild("HatchEgg")
            if hatchRemote then
                hatchRemote:FireServer(egg)
                task.wait(0.5)
            end
        end
    end
end
-- ════════════════════════════════════════
--  AUTO SELL
-- ════════════════════════════════════════
local function autoSell()
    if not CFG.AutoSell then return end
    local sellRemote = game:GetService("ReplicatedStorage"):FindFirstChild("SellPets")
        or game:GetService("ReplicatedStorage"):FindFirstChild("Sell")
    if sellRemote then
        sellRemote:FireServer()
        notify("Ride a Pet", "Petler satıldı!", 2)
    end
end
-- ════════════════════════════════════════
--  MAIN LOOP
-- ════════════════════════════════════════
notify("Ride a Pet Hile", "Script yüklendi! 6larping7 🥔", 5)
autoRide()
task.spawn(function()
    while task.wait(2) do
        getChar()
        autoFarm()
    end
end)
task.spawn(function()
    while task.wait(30) do
        autoHatch()
        autoSell()
    end
end)
-- ════════════════════════════════════════
--  SIMPLE GUI (toggle panel)
-- ════════════════════════════════════════
local ScreenGui   = Instance.new("ScreenGui")
local Frame       = Instance.new("Frame")
local UICorner    = Instance.new("UICorner")
local Title       = Instance.new("TextLabel")
local BtnFarm     = Instance.new("TextButton")
local BtnRide     = Instance.new("TextButton")
local BtnHatch    = Instance.new("TextButton")
local BtnSell     = Instance.new("TextButton")
local StatsLabel  = Instance.new("TextLabel")
ScreenGui.Name            = "RideAPetHub"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
-- executor koruma (syngui vs)
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = lp:WaitForChild("PlayerGui") end
Frame.Size                  = UDim2.new(0, 220, 0, 240)
Frame.Position              = UDim2.new(0, 20, 0.3, 0)
Frame.BackgroundColor3      = Color3.fromRGB(20, 20, 30)
Frame.BorderSizePixel       = 0
Frame.Active                = true
Frame.Draggable             = true
Frame.Parent                = ScreenGui
UICorner.CornerRadius       = UDim.new(0, 10)
UICorner.Parent             = Frame
Title.Text                  = "🥔 Ride a Pet Hub"
Title.Size                  = UDim2.new(1, 0, 0, 35)
Title.Position              = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3      = Color3.fromRGB(90, 40, 200)
Title.TextColor3            = Color3.new(1,1,1)
Title.Font                  = Enum.Font.GothamBold
Title.TextSize              = 14
Title.Parent                = Frame
local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0,10); tc.Parent = Title
local btnY = 40
local function makeBtn(label, y, toggleKey)
    local btn               = Instance.new("TextButton")
    btn.Size                = UDim2.new(1, -20, 0, 30)
    btn.Position            = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3    = Color3.fromRGB(50, 50, 80)
    btn.TextColor3          = Color3.new(1,1,1)
    btn.Font                = Enum.Font.Gotham
    btn.TextSize            = 13
    btn.BorderSizePixel     = 0
    btn.Parent              = Frame
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,6); bc.Parent = btn
    local function refresh()
        local state = CFG[toggleKey]
        btn.Text            = label .. ": " .. (state and "✅ ON" or "❌ OFF")
        btn.BackgroundColor3 = state
            and Color3.fromRGB(40, 120, 60)
            or  Color3.fromRGB(120, 40, 40)
    end
    refresh()
    btn.MouseButton1Click:Connect(function()
        CFG[toggleKey] = not CFG[toggleKey]
        refresh()
        notify("Ride a Pet Hub", label .. " -> " .. (CFG[toggleKey] and "AÇıK" or "KAPALI"), 2)
    end)
    return btn
end
makeBtn("Auto Farm",  45,  "AutoFarm")
makeBtn("Auto Ride", 82,  "AutoRide")
makeBtn("Auto Hatch", 119, "AutoHatch")
makeBtn("Auto Sell",  156, "AutoSell")
StatsLabel.Size             = UDim2.new(1, -10, 0, 25)
StatsLabel.Position         = UDim2.new(0, 5, 0, 200)
StatsLabel.BackgroundTransparency = 1
StatsLabel.TextColor3       = Color3.fromRGB(180, 180, 255)
StatsLabel.Font             = Enum.Font.Gotham
StatsLabel.TextSize         = 11
StatsLabel.Text             = "Farmed: 0"
StatsLabel.Parent           = Frame
RunService.Heartbeat:Connect(function()
    StatsLabel.Text = string.format("Farmed: %d | Speed: %d", farmedCount, CFG.WalkSpeed)
end)