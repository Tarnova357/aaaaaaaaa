-- Ultimate Auto Memory Match (AFK MANAGER V6.1: SAFE TIMINGS)

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer

local mmRemote = ReplicatedStorage.Events.MemoryMatchEvent
local toyRemote = ReplicatedStorage.Events.ToyEvent
local MM_Data = require(ReplicatedStorage:WaitForChild("MemoryMatchGameTypes"))
local CSC = require(ReplicatedStorage:WaitForChild("ClientStatCache"))

local ALLOWED_GAMES = {
    ["Basic"] = true,
    ["BadgeGuild"] = true,
    ["35Zone"] = true,
    ["Night"] = true,
    ["Winter"] = true
}

local TOY_NAMES = {
    ["Basic"] = "Memory Match",
    ["Night"] = "Night Memory Match",
    ["BadgeGuild"] = "Mega Memory Match",
    ["35Zone"] = "Extreme Memory Match",
    ["Winter"] = "Winter Memory Match"
}

-- === CONFIG SYSTEM ===
local folderPath = "AutoMemoryMatch"
local filePath = folderPath .. "/" .. lp.Name .. "_config.json"
local Config = {
    AutoStart = false,
    Games = {}
}

for gameName, _ in pairs(ALLOWED_GAMES) do
    Config.Games[gameName] = { 
        Enabled = false, 
        Priority = 1, 
        IsDupMode = true, 
        DupSearchChances = 2, 
        Rewards = {} 
    }
end

local function SaveConfig()
    pcall(function()
        if not isfolder(folderPath) then makefolder(folderPath) end
        writefile(filePath, HttpService:JSONEncode(Config))
    end)
end

local function LoadConfig()
    pcall(function()
        if isfile(filePath) then
            local decoded = HttpService:JSONDecode(readfile(filePath))
            if decoded then
                if decoded.AutoStart ~= nil then Config.AutoStart = decoded.AutoStart end
                for k, v in pairs(decoded.Games or {}) do
                    if Config.Games[k] then 
                        Config.Games[k].Enabled = v.Enabled or false
                        Config.Games[k].Priority = v.Priority or 1
                        Config.Games[k].IsDupMode = (v.IsDupMode ~= nil) and v.IsDupMode or true
                        Config.Games[k].DupSearchChances = v.DupSearchChances or 2
                        Config.Games[k].Rewards = v.Rewards or {}
                    end
                end
            end
        end
    end)
end
LoadConfig()
-- =====================

local UI_NAME = "FastMemoryMatchSearcher"
if CoreGui:FindFirstChild(UI_NAME) then CoreGui[UI_NAME]:Destroy() end
if lp.PlayerGui:FindFirstChild(UI_NAME) then lp.PlayerGui[UI_NAME]:Destroy() end

local SelectedGameType = nil
local SearchActive = false 
local MatchesScannedCount = 0
local CurrentChances = 3
local MIN_CYCLE_TIME = 0.06 

-- UI Construction
local sg = Instance.new("ScreenGui")
sg.Name = UI_NAME
pcall(function() sg.Parent = CoreGui end)
if not sg.Parent then sg.Parent = lp.PlayerGui end

-- MINIMIZED ICON
local MinIcon = Instance.new("TextButton")
MinIcon.Size = UDim2.new(0, 50, 0, 50)
MinIcon.Position = UDim2.new(0, 20, 0, 20)
MinIcon.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MinIcon.TextColor3 = Color3.fromRGB(0, 200, 100)
MinIcon.Text = "MM"
MinIcon.Font = Enum.Font.GothamBold
MinIcon.TextSize = 20
MinIcon.BorderSizePixel = 2
MinIcon.BorderColor3 = Color3.fromRGB(0, 200, 100)
MinIcon.Visible = false
MinIcon.Draggable = true
MinIcon.Active = true
MinIcon.Parent = sg

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinIcon

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 440, 0, 580)
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -290)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = sg

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "AFK MANAGER [" .. string.upper(lp.Name) .. "]"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.BorderSizePixel = 0
Title.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = MainFrame

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -70, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Text = "-"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.BorderSizePixel = 0
MinBtn.Parent = MainFrame

local MatchesLbl = Instance.new("TextLabel")
MatchesLbl.Size = UDim2.new(1, 0, 0, 20)
MatchesLbl.Position = UDim2.new(0, 0, 0, 40)
MatchesLbl.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MatchesLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
MatchesLbl.Text = "MATCHES SCANNED: 0"
MatchesLbl.Font = Enum.Font.GothamSemibold
MatchesLbl.TextSize = 13
MatchesLbl.BorderSizePixel = 0
MatchesLbl.Parent = MainFrame

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1, 0, 0, 20)
StatusLbl.Position = UDim2.new(0, 0, 0, 60)
StatusLbl.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
StatusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLbl.Text = "STATUS: IDLE"
StatusLbl.Font = Enum.Font.GothamBold
StatusLbl.TextSize = 12
StatusLbl.BorderSizePixel = 0
StatusLbl.Parent = MainFrame

local TypeScroll = Instance.new("ScrollingFrame")
TypeScroll.Size = UDim2.new(1, -20, 0, 100)
TypeScroll.Position = UDim2.new(0, 10, 0, 85)
TypeScroll.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
TypeScroll.BorderSizePixel = 0
TypeScroll.ScrollBarThickness = 6
TypeScroll.Parent = MainFrame

local TypeLayout = Instance.new("UIListLayout")
TypeLayout.Padding = UDim.new(0, 2)
TypeLayout.Parent = TypeScroll

local RewardScroll = Instance.new("ScrollingFrame")
RewardScroll.Size = UDim2.new(1, -20, 1, -365)
RewardScroll.Position = UDim2.new(0, 10, 0, 195)
RewardScroll.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
RewardScroll.BorderSizePixel = 0
RewardScroll.ScrollBarThickness = 6
RewardScroll.Parent = MainFrame

local RewardLayout = Instance.new("UIListLayout")
RewardLayout.Padding = UDim.new(0, 5)
RewardLayout.Parent = RewardScroll

-- DUP SETTINGS FRAME
local DupSettingsFrame = Instance.new("Frame")
DupSettingsFrame.Size = UDim2.new(1, -20, 0, 40)
DupSettingsFrame.Position = UDim2.new(0, 10, 1, -150)
DupSettingsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
DupSettingsFrame.BorderSizePixel = 0
DupSettingsFrame.Visible = false 
DupSettingsFrame.Parent = MainFrame

local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0.5, -5, 1, 0)
ModeBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
ModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeBtn.Text = "MODE: NORMAL"
ModeBtn.Font = Enum.Font.GothamBold
ModeBtn.TextSize = 14
ModeBtn.BorderSizePixel = 0
ModeBtn.Parent = DupSettingsFrame

local SearchChancesFrame = Instance.new("Frame")
SearchChancesFrame.Size = UDim2.new(0.5, -5, 1, 0)
SearchChancesFrame.Position = UDim2.new(0.5, 5, 0, 0)
SearchChancesFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
SearchChancesFrame.BorderSizePixel = 0
SearchChancesFrame.Parent = DupSettingsFrame

local SMinusBtn = Instance.new("TextButton")
SMinusBtn.Size = UDim2.new(0, 30, 1, 0)
SMinusBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
SMinusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SMinusBtn.Text = "-"
SMinusBtn.Font = Enum.Font.GothamBold
SMinusBtn.TextSize = 16
SMinusBtn.BorderSizePixel = 0
SMinusBtn.Parent = SearchChancesFrame

local SPlusBtn = Instance.new("TextButton")
SPlusBtn.Size = UDim2.new(0, 30, 1, 0)
SPlusBtn.Position = UDim2.new(1, -30, 0, 0)
SPlusBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
SPlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SPlusBtn.Text = "+"
SPlusBtn.Font = Enum.Font.GothamBold
SPlusBtn.TextSize = 16
SPlusBtn.BorderSizePixel = 0
SPlusBtn.Parent = SearchChancesFrame

local SearchChancesLbl = Instance.new("TextLabel")
SearchChancesLbl.Size = UDim2.new(1, -60, 1, 0)
SearchChancesLbl.Position = UDim2.new(0, 30, 0, 0)
SearchChancesLbl.BackgroundTransparency = 1
SearchChancesLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchChancesLbl.Text = "SEARCH: 2"
SearchChancesLbl.Font = Enum.Font.GothamBold
SearchChancesLbl.TextSize = 12
SearchChancesLbl.Parent = SearchChancesFrame

-- TOTAL CHANCES FRAME
local ChancesFrame = Instance.new("Frame")
ChancesFrame.Size = UDim2.new(1, -20, 0, 40)
ChancesFrame.Position = UDim2.new(0, 10, 1, -100)
ChancesFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
ChancesFrame.BorderSizePixel = 0
ChancesFrame.Parent = MainFrame

local MinusBtn = Instance.new("TextButton")
MinusBtn.Size = UDim2.new(0, 40, 1, 0)
MinusBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
MinusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinusBtn.Text = "-"
MinusBtn.Font = Enum.Font.GothamBold
MinusBtn.TextSize = 20
MinusBtn.BorderSizePixel = 0
MinusBtn.Parent = ChancesFrame

local PlusBtn = Instance.new("TextButton")
PlusBtn.Size = UDim2.new(0, 40, 1, 0)
PlusBtn.Position = UDim2.new(1, -40, 0, 0)
PlusBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
PlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlusBtn.Text = "+"
PlusBtn.Font = Enum.Font.GothamBold
PlusBtn.TextSize = 20
PlusBtn.BorderSizePixel = 0
PlusBtn.Parent = ChancesFrame

local ChancesLbl = Instance.new("TextLabel")
ChancesLbl.Size = UDim2.new(1, -80, 1, 0)
ChancesLbl.Position = UDim2.new(0, 40, 0, 0)
ChancesLbl.BackgroundTransparency = 1
ChancesLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
ChancesLbl.Text = "TOTAL CHANCES: ?"
ChancesLbl.Font = Enum.Font.GothamBold
ChancesLbl.TextSize = 14
ChancesLbl.Parent = ChancesFrame

-- ACTION BUTTON
local ActionBtn = Instance.new("TextButton")
ActionBtn.Size = UDim2.new(1, -20, 0, 40)
ActionBtn.Position = UDim2.new(0, 10, 1, -50)
ActionBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ActionBtn.Text = "START AUTO-FARM"
ActionBtn.Font = Enum.Font.GothamBold
ActionBtn.TextSize = 16
ActionBtn.BorderSizePixel = 0
ActionBtn.Parent = MainFrame

-- WINDOW LOGIC
local function Minimize()
    MainFrame.Visible = false
    MinIcon.Visible = true
end

local function Maximize()
    MainFrame.Visible = true
    MinIcon.Visible = false
end

MinBtn.MouseButton1Click:Connect(Minimize)
MinIcon.MouseButton1Click:Connect(Maximize)

-- UI LOGIC
local function UpdateDisplay()
    if not SelectedGameType then return end
    local gameCfg = Config.Games[SelectedGameType]
    
    ChancesLbl.Text = "TOTAL CHANCES (FOR SELECTED): " .. tostring(CurrentChances)
    SearchChancesLbl.Text = "SEARCH: " .. tostring(gameCfg.DupSearchChances)
    
    ModeBtn.BackgroundColor3 = gameCfg.IsDupMode and Color3.fromRGB(150, 50, 200) or Color3.fromRGB(50, 150, 200)
    ModeBtn.Text = gameCfg.IsDupMode and "MODE: DUP" or "MODE: NORMAL"
    SearchChancesFrame.Visible = gameCfg.IsDupMode
    
    SaveConfig()
end

ModeBtn.MouseButton1Click:Connect(function()
    if SearchActive or not SelectedGameType then return end
    local gameCfg = Config.Games[SelectedGameType]
    gameCfg.IsDupMode = not gameCfg.IsDupMode
    UpdateDisplay()
end)

SMinusBtn.MouseButton1Click:Connect(function()
    if SearchActive or not SelectedGameType then return end
    local gameCfg = Config.Games[SelectedGameType]
    if gameCfg.DupSearchChances > 1 then
        gameCfg.DupSearchChances = gameCfg.DupSearchChances - 1
        UpdateDisplay()
    end
end)

SPlusBtn.MouseButton1Click:Connect(function()
    if SearchActive or not SelectedGameType then return end
    local gameCfg = Config.Games[SelectedGameType]
    if gameCfg.DupSearchChances < CurrentChances - 1 then
        gameCfg.DupSearchChances = gameCfg.DupSearchChances + 1
        UpdateDisplay()
    end
end)

local function AutoCalculateChances(gameTypeName)
    local gameData = MM_Data[gameTypeName]
    local base = gameData.BaseChances or gameData.Chances or 3
    local bonus = 0
    pcall(function()
        local playerBadges = CSC:Get("Badges") or {}
        if gameData.BonusChanceBadges then
            for _, req in ipairs(gameData.BonusChanceBadges) do
                local badgeName = req[1]
                local reqTier = req[2]
                if playerBadges[badgeName] and playerBadges[badgeName] >= reqTier then
                    bonus = bonus + 1
                end
            end
        end
    end)
    return base + bonus
end

local gameButtons = {}

local function LoadRewards(gameTypeName)
    if SearchActive then return end 
    SelectedGameType = gameTypeName
    
    CurrentChances = AutoCalculateChances(gameTypeName)
    
    local gameCfg = Config.Games[gameTypeName]
    if gameCfg.DupSearchChances >= CurrentChances then gameCfg.DupSearchChances = CurrentChances - 1 end
    if gameCfg.DupSearchChances < 1 then gameCfg.DupSearchChances = 1 end
    
    DupSettingsFrame.Visible = true
    UpdateDisplay()

    for name, btn in pairs(gameButtons) do
        btn.BackgroundColor3 = (name == gameTypeName) and Color3.fromRGB(100, 100, 150) or Color3.fromRGB(60, 60, 65)
    end

    for _, child in ipairs(RewardScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local pool = MM_Data[gameTypeName].Pool
    local ySize = 0

    for _, rewardData in ipairs(pool) do
        local rewardName = rewardData.Name

        local rBtn = Instance.new("TextButton")
        rBtn.Size = UDim2.new(1, -10, 0, 30)
        
        local isSelected = false
        for _, v in ipairs(Config.Games[gameTypeName].Rewards) do
            if v == rewardName then isSelected = true break end
        end
        
        rBtn.BackgroundColor3 = isSelected and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50) 
        rBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        rBtn.Text = (isSelected and "[TARGET] " or "[ ] ") .. rewardName
        rBtn.Font = Enum.Font.GothamSemibold
        rBtn.TextSize = 14
        rBtn.BorderSizePixel = 0
        rBtn.Parent = RewardScroll

        rBtn.MouseButton1Click:Connect(function()
            if SearchActive then return end
            local found = false
            for i, v in ipairs(Config.Games[gameTypeName].Rewards) do
                if v == rewardName then
                    table.remove(Config.Games[gameTypeName].Rewards, i)
                    found = true
                    break
                end
            end
            if not found then table.insert(Config.Games[gameTypeName].Rewards, rewardName) end
            
            isSelected = not isSelected
            rBtn.BackgroundColor3 = isSelected and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50) 
            rBtn.Text = (isSelected and "[TARGET] " or "[ ] ") .. rewardName
            SaveConfig()
        end)
        ySize = ySize + 35
    end
    RewardScroll.CanvasSize = UDim2.new(0, 0, 0, ySize)
end

-- POPULATE GAME LIST
local yTypeSize = 0
for gameTypeName, _ in pairs(ALLOWED_GAMES) do
    local gFrame = Instance.new("Frame")
    gFrame.Size = UDim2.new(1, -10, 0, 30)
    gFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    gFrame.BorderSizePixel = 0
    gFrame.Parent = TypeScroll

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 30, 1, 0)
    ToggleBtn.BackgroundColor3 = Config.Games[gameTypeName].Enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    ToggleBtn.Text = Config.Games[gameTypeName].Enabled and "V" or "X"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Parent = gFrame
    
    local NameBtn = Instance.new("TextButton")
    NameBtn.Size = UDim2.new(1, -110, 1, 0)
    NameBtn.Position = UDim2.new(0, 35, 0, 0)
    NameBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    NameBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameBtn.Text = gameTypeName
    NameBtn.Font = Enum.Font.GothamBold
    NameBtn.TextSize = 14
    NameBtn.BorderSizePixel = 0
    NameBtn.Parent = gFrame
    gameButtons[gameTypeName] = NameBtn

    local PrioBox = Instance.new("TextBox")
    PrioBox.Size = UDim2.new(0, 70, 1, 0)
    PrioBox.Position = UDim2.new(1, -70, 0, 0)
    PrioBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    PrioBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    PrioBox.Text = "Prio: " .. tostring(Config.Games[gameTypeName].Priority)
    PrioBox.Font = Enum.Font.GothamBold
    PrioBox.TextSize = 12
    PrioBox.BorderSizePixel = 0
    PrioBox.Parent = gFrame

    ToggleBtn.MouseButton1Click:Connect(function()
        if SearchActive then return end
        Config.Games[gameTypeName].Enabled = not Config.Games[gameTypeName].Enabled
        ToggleBtn.BackgroundColor3 = Config.Games[gameTypeName].Enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        ToggleBtn.Text = Config.Games[gameTypeName].Enabled and "V" or "X"
        SaveConfig()
    end)

    NameBtn.MouseButton1Click:Connect(function() LoadRewards(gameTypeName) end)

    PrioBox.FocusLost:Connect(function()
        local num = tonumber(string.match(PrioBox.Text, "%d+"))
        if num then
            Config.Games[gameTypeName].Priority = num
        end
        PrioBox.Text = "Prio: " .. tostring(Config.Games[gameTypeName].Priority)
        SaveConfig()
    end)

    yTypeSize = yTypeSize + 32
end
TypeScroll.CanvasSize = UDim2.new(0, 0, 0, yTypeSize)

CloseBtn.MouseButton1Click:Connect(function()
    SearchActive = false
    Config.AutoStart = false
    SaveConfig()
    if sg then sg:Destroy() end
    print("[AFK MANAGER] UI CLOSED AND SCRIPT TERMINATED.")
end)

-- === AFK BRAIN ===
local function GetBestGame()
    local readyGames = {}
    local cdGames = {}
    
    local toyTimes = {}
    pcall(function() toyTimes = CSC:Get("ToyTimes") or {} end)
    
    for gameName, gameConfig in pairs(Config.Games) do
        if gameConfig.Enabled and #gameConfig.Rewards > 0 then
            local toyName = TOY_NAMES[gameName] or "Memory Match"
            local cdTime = MM_Data[gameName].Cooldown or 0
            local lastTime = toyTimes[toyName] or 0
            local remaining = math.floor(lastTime + cdTime - os.time())
            
            if remaining <= 0 then
                table.insert(readyGames, {Name = gameName, Prio = gameConfig.Priority, CD = 0})
            else
                table.insert(cdGames, {Name = gameName, Prio = gameConfig.Priority, CD = remaining})
            end
        end
    end
    
    table.sort(readyGames, function(a, b) return a.Prio > b.Prio end)
    table.sort(cdGames, function(a, b) 
        if math.abs(a.CD - b.CD) < 300 then 
            return a.Prio > b.Prio
        end
        return a.CD < b.CD 
    end)
    
    if #readyGames > 0 then return readyGames[1] end
    if #cdGames > 0 then return cdGames[1] end
    return nil
end

local function ToggleFarm()
    if SearchActive then
        SearchActive = false
        ActionBtn.Text = "STOPPING..."
        ActionBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        StatusLbl.Text = "STATUS: STOPPING ENGINE..."
        Config.AutoStart = false
        SaveConfig()
        return
    end

    SearchActive = true
    MatchesScannedCount = 0
    ActionBtn.Text = "STOP AUTO-FARM"
    ActionBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    
    Config.AutoStart = true
    SaveConfig()
    Minimize()

    task.spawn(function()
        local tiles = {}
        local connection = mmRemote.OnClientEvent:Connect(function(data)
            if typeof(data) == "table" and data.Action == "RevealTile" then
                tiles[data.TileIndex] = data.TileType
            end
        end)

        print("[AFK MANAGER] ENGINE STARTED FOR: " .. lp.Name)

        while SearchActive do
            local bestGameInfo = GetBestGame()
            
            if not bestGameInfo then
                StatusLbl.Text = "STATUS: NO GAMES ENABLED / NO TARGETS"
                StatusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
                task.wait(2)
                continue
            end
            
            local tGame = bestGameInfo.Name
            local tCD = bestGameInfo.CD
            local tChances = AutoCalculateChances(tGame)
            local tRewards = Config.Games[tGame].Rewards
            local gameCfg = Config.Games[tGame]
            
            StatusLbl.Text = "STATUS: SCANNING " .. string.upper(tGame) .. " (CD: " .. tostring(tCD) .. "s)"
            StatusLbl.TextColor3 = Color3.fromRGB(100, 200, 255)

            local cycleStartTime = tick()
            tiles = {} 
            
            local chancesToBurn = 1
            local claimsToMake = 1
            if gameCfg.IsDupMode then
                chancesToBurn = gameCfg.DupSearchChances
                if chancesToBurn >= tChances then chancesToBurn = tChances - 1 end
                if chancesToBurn < 1 then chancesToBurn = 1 end
                claimsToMake = tChances - chancesToBurn
            else
                chancesToBurn = tChances - 1
                if chancesToBurn < 1 then chancesToBurn = 1 end
                claimsToMake = 1
            end
            
            local tilesToOpen = chancesToBurn * 2
            
            mmRemote:FireServer({["Action"] = "Start", ["GameType"] = tGame})
            
            for i = 1, tilesToOpen do
                mmRemote:FireServer({["Action"] = "SelectTile", ["TileIndex"] = i})
            end

            local waitTimer = tick()
            repeat task.wait() until next(tiles) ~= nil or (tick() - waitTimer > 0.2)

            local foundPairIndices = nil
            local foundItemName = nil
            local itemMemory = {}

            for index, item in pairs(tiles) do
                local isWanted = false
                for _, w in ipairs(tRewards) do if w == item then isWanted = true break end end
                
                if isWanted then
                    if not itemMemory[item] then itemMemory[item] = {} end
                    table.insert(itemMemory[item], index)
                    
                    if #itemMemory[item] >= 2 then
                        foundPairIndices = itemMemory[item]
                        foundItemName = item
                        break
                    end
                end
            end

            if foundPairIndices then
                if tCD > 0 then
                    print("[AFK MANAGER] TARGET LOCKED ON CD! SLEEPING FOR " .. tostring(tCD + 20) .. "s...")
                    
                    local sleepTime = tCD + 20
                    while sleepTime > 0 and SearchActive do
                        StatusLbl.Text = "STATUS: TARGET LOCKED! WAITING CD: " .. tostring(sleepTime) .. "s"
                        StatusLbl.TextColor3 = Color3.fromRGB(255, 150, 50)
                        task.wait(1)
                        sleepTime = sleepTime - 1
                    end
                    
                    if not SearchActive then break end
                else
                    print("[AFK MANAGER] TARGET LOCKED! SETTLING BOARD...")
                    task.wait(2)
                end
                
                StatusLbl.Text = "STATUS: PAYING FOR " .. string.upper(foundItemName) .. "..."
                StatusLbl.TextColor3 = Color3.fromRGB(50, 255, 50)
                
                local toyName = TOY_NAMES[tGame] or "Memory Match"
                toyRemote:FireServer(toyName)
                task.wait(3) 
                
                StatusLbl.Text = "STATUS: CLAIMING " .. string.upper(foundItemName) .. "!"
                
                for attempt = 1, claimsToMake do
                    if not SearchActive then break end
                    mmRemote:FireServer({["Action"] = "SelectTile", ["TileIndex"] = foundPairIndices[1]})
                    task.wait(0.2)
                    mmRemote:FireServer({["Action"] = "SelectTile", ["TileIndex"] = foundPairIndices[2]})
                    task.wait(1.5) 
                end
                
                task.wait(3) 
                mmRemote:FireServer({["Action"] = "Finish", ["GameType"] = tGame})
                print("[AFK MANAGER] SECURED " .. string.upper(foundItemName) .. " FROM " .. tGame)
                
                pcall(function()
                    local cache = CSC:Get("ToyTimes")
                    if cache then cache[toyName] = os.time() end
                end)
                
                task.wait(2) 
            else
                mmRemote:FireServer({["Action"] = "Finish", ["GameType"] = tGame})
                MatchesScannedCount = MatchesScannedCount + 1
                if sg.Parent then MatchesLbl.Text = "MATCHES SCANNED: " .. tostring(MatchesScannedCount) end
                
                local elapsed = tick() - cycleStartTime
                if elapsed < MIN_CYCLE_TIME then
                    task.wait(MIN_CYCLE_TIME - elapsed)
                end
            end
        end
        
        if connection then connection:Disconnect() end

        if sg.Parent and ActionBtn.Text == "STOPPING..." then
            ActionBtn.Text = "START AUTO-FARM"
            ActionBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            StatusLbl.Text = "STATUS: IDLE"
            StatusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end)
end

ActionBtn.MouseButton1Click:Connect(ToggleFarm)

if Config.AutoStart then
    task.spawn(function()
        task.wait(1) 
        if not SearchActive then ToggleFarm() end
    end)
end
