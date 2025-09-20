--//======================================================
--// Grow a Garden - Auto Farm Script (Full + Lengkap)
--//======================================================

-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/source.lua"))()

-- Buat Window
local Window = Rayfield:CreateWindow({
    Name = "Grow A Garden | Auto Farm & Mass Claim Hub",
    LoadingTitle = "Rayfield UI Loader",
    LoadingSubtitle = "by Rud Az",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GrowAGarden",
        FileName = "AutoFarmConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

-- Buat Tab
local MainTab = Window:CreateTab("🌱 Main", 4483362458)
local PlantTab = Window:CreateTab("🌿 Plant Detector", 4483362458)
local MiscTab = Window:CreateTab("⚙ Misc", 4483362458)
local BoostTab = Window:CreateTab("🚀 Boost", 4483362458)

-- Variabel
local autoCollect = false
local autoPlant = false
local autoSell = false
local autoQuest = false
local collectDelay = 0.4
local fpsBoostEnabled = false
local detectedPlants = {}
local plantDetectionEnabled = false

local RunService = game:GetService("RunService")
local Player = game.Players.LocalPlayer

-- Daftar nama tanaman yang umum di Grow a Garden
local commonPlantNames = {
    "plant", "crop", "harvest", "tree", "flower", "bush", 
    "carrot", "tomato", "potato", "corn", "wheat", "berry",
    "apple", "orange", "banana", "strawberry", "blueberry",
    "sunflower", "rose", "tulip", "daisy", "cactus", "pumpkin",
    "melon", "watermelon", "pepper", "eggplant", "cabbage"
}

-- Fungsi untuk mendeteksi semua tanaman dengan lebih akurat
local function getAllPlants()
    local plants = {}
    
    -- Deteksi berdasarkan ProximityPrompt
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Parent then
            local parentName = string.lower(v.Parent.Name)
            for _, plantName in pairs(commonPlantNames) do
                if string.find(parentName, plantName) then
                    table.insert(plants, {
                        Object = v,
                        Name = v.Parent.Name,
                        Position = v.Parent:IsA("BasePart") and v.Parent.Position or 
                                  (v.Parent:FindFirstChildWhichIsA("BasePart") and v.Parent:FindFirstChildWhichIsA("BasePart").Position or nil),
                        Type = "ProximityPrompt"
                    })
                    break
                end
            end
        end
    end
    
    -- Deteksi berdasarkan nama object
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Model") then
            local objectName = string.lower(v.Name)
            for _, plantName in pairs(commonPlantNames) do
                if string.find(objectName, plantName) and not v:FindFirstAncestorWhichIsA("Tool") then
                    local foundPrompt = v:FindFirstChildWhichIsA("ProximityPrompt")
                    
                    table.insert(plants, {
                        Object = foundPrompt or v,
                        Name = v.Name,
                        Position = v:IsA("BasePart") and v.Position or 
                                  (v:FindFirstChildWhichIsA("BasePart") and v:FindFirstChildWhichIsA("BasePart").Position or nil),
                        Type = foundPrompt and "ProximityPrompt" or "PlantObject"
                    })
                    break
                end
            end
        end
    end
    
    -- Deteksi berdasarkan part yang dapat di-harvest (tanaman yang sudah matang)
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v:GetAttribute("Ready") or v:GetAttribute("Grown") or v:GetAttribute("Harvestable")) then
            table.insert(plants, {
                Object = v,
                Name = v.Name,
                Position = v.Position,
                Type = "Harvestable"
            })
        end
    end
    
    -- Hapus duplikat
    local uniquePlants = {}
    local added = {}
    for _, plant in ipairs(plants) do
        if plant.Position and not added[tostring(plant.Position)] then
            table.insert(uniquePlants, plant)
            added[tostring(plant.Position)] = true
        end
    end
    
    return uniquePlants
end

-- Fungsi untuk update daftar tanaman yang terdeteksi
local function updateDetectedPlants()
    detectedPlants = getAllPlants()
    return detectedPlants
end

-- Fungsi Mass Claim Tanaman
local function massClaimPlants()
    local plants = updateDetectedPlants()
    local claimed = 0
    
    for _, plant in pairs(plants) do
        pcall(function()
            if plant.Object:IsA("ProximityPrompt") then
                fireproximityprompt(plant.Object)
                claimed = claimed + 1
            elseif plant.Object:IsA("BasePart") and plant.Object:FindFirstChildWhichIsA("ProximityPrompt") then
                fireproximityprompt(plant.Object:FindFirstChildWhichIsA("ProximityPrompt"))
                claimed = claimed + 1
            end
        end)
        task.wait(0.05) -- Small delay to prevent crashes
    end
    
    return claimed
end

-- Fungsi Auto Collect
local function collectPlants()
    while autoCollect and task.wait(collectDelay) do
        local plants = updateDetectedPlants()
        for _, plant in pairs(plants) do
            if not autoCollect then break end
            pcall(function()
                if plant.Object:IsA("ProximityPrompt") then
                    fireproximityprompt(plant.Object)
                elseif plant.Object:IsA("BasePart") and plant.Object:FindFirstChildWhichIsA("ProximityPrompt") then
                    fireproximityprompt(plant.Object:FindFirstChildWhichIsA("ProximityPrompt"))
                end
            end)
        end
    end
end

-- Fungsi Auto Plant
local function plantSeeds()
    while autoPlant and task.wait(1) do
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
        if remotes then
            local plantRemote = remotes:FindFirstChild("Plant") or remotes:FindFirstChild("PlantEvent")
            if plantRemote and plantRemote:IsA("RemoteEvent") then
                pcall(function()
                    plantRemote:FireServer()
                end)
            end
        end
    end
end

-- Fungsi Auto Sell
local function sellCrops()
    while autoSell and task.wait(2) do
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
        if remotes then
            local sellRemote = remotes:FindFirstChild("Sell") or remotes:FindFirstChild("SellEvent")
            if sellRemote and sellRemote:IsA("RemoteEvent") then
                pcall(function()
                    sellRemote:FireServer()
                end)
            end
        end
    end
end

-- Fungsi untuk mendapatkan semua quest
local function getAllQuests()
    local quests = {}
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
    
    if remotes then
        for _, v in pairs(remotes:GetChildren()) do
            if string.find(string.lower(v.Name), "quest") 
            or string.find(string.lower(v.Name), "task")
            or string.find(string.lower(v.Name), "mission")
            or string.find(string.lower(v.Name), "complete") then
                table.insert(quests, v)
            end
        end
    end
    
    -- Juga cari di tempat lain
    local playerGui = Player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, guiElement in pairs(playerGui:GetDescendants()) do
            if (guiElement:IsA("TextButton") or guiElement:IsA("ImageButton")) and 
               (string.find(string.lower(guiElement.Name), "claim") or 
                string.find(string.lower(guiElement.Name), "collect") or
                string.find(string.lower(guiElement.Name), "complete")) then
                table.insert(quests, guiElement)
            end
        end
    end
    
    return quests
end

-- Fungsi Mass Claim Quest
local function massClaimQuests()
    local quests = getAllQuests()
    local claimed = 0
    
    for _, quest in pairs(quests) do
        pcall(function()
            if quest:IsA("RemoteEvent") then
                quest:FireServer("Complete")
                claimed = claimed + 1
            elseif quest:IsA("RemoteFunction") then
                quest:InvokeServer("Complete")
                claimed = claimed + 1
            elseif (quest:IsA("TextButton") or quest:IsA("ImageButton")) and quest.Visible then
                quest:Fire("Click")
                quest:Fire("Activate")
                claimed = claimed + 1
            end
        end)
        task.wait(0.05) -- Small delay to prevent crashes
    end
    
    return claimed
end

-- Fungsi Auto Complete Quest
local function completeAllQuests()
    while autoQuest and task.wait(1) do
        local quests = getAllQuests()
        for _, v in pairs(quests) do
            if not autoQuest then break end
            pcall(function()
                if v:IsA("RemoteEvent") then
                    v:FireServer("Complete")
                elseif v:IsA("RemoteFunction") then
                    v:InvokeServer("Complete")
                elseif (v:IsA("TextButton") or v:IsA("ImageButton")) and v.Visible then
                    v:Fire("Click")
                    v:Fire("Activate")
                end
            end)
        end
    end
end

-- Fungsi Boost FPS
local function applyFPSBoost()
    if fpsBoostEnabled then
        -- Mengurangi kualitas grafis untuk meningkatkan FPS
        settings().Rendering.QualityLevel = 1
        
        -- Nonaktifkan efek partikel
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                obj.Enabled = false
            end
        end
        
        -- Kurangi detail lingkungan
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").FantasySky.Enabled = false
        
        -- Optimasi karakter
        if Player.Character then
            for _, part in pairs(Player.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Material = Enum.Material.Plastic
                end
            end
        end
    else
        -- Reset pengaturan
        settings().Rendering.QualityLevel = 10
        game:GetService("Lighting").GlobalShadows = true
    end
end

-- Toggle Auto Collect
MainTab:CreateToggle({
    Name = "🌾 Auto Collect Tanaman",
    CurrentValue = false,
    Flag = "AutoCollectPlants",
    Callback = function(Value)
        autoCollect = Value
        if autoCollect then
            task.spawn(collectPlants)
        end
    end,
})

-- Toggle Auto Plant
MainTab:CreateToggle({
    Name = "🌱 Auto Plant (Jika Support)",
    CurrentValue = false,
    Flag = "AutoPlantSeeds",
    Callback = function(Value)
        autoPlant = Value
        if autoPlant then
            task.spawn(plantSeeds)
        end
    end,
})

-- Toggle Auto Sell
MainTab:CreateToggle({
    Name = "💰 Auto Sell (Jika Support)",
    CurrentValue = false,
    Flag = "AutoSellCrops",
    Callback = function(Value)
        autoSell = Value
        if autoSell then
            task.spawn(sellCrops)
        end
    end,
})

-- Toggle Auto Quest
MainTab:CreateToggle({
    Name = "🎯 Auto Selesai Semua Quest",
    CurrentValue = false,
    Flag = "AutoCompleteQuest",
    Callback = function(Value)
        autoQuest = Value
        if autoQuest then
            task.spawn(completeAllQuests)
        end
    end,
})

-- Button Mass Claim Tanaman
MainTab:CreateButton({
    Name = "🚀 Mass Claim Semua Tanaman",
    Callback = function()
        local claimed = massClaimPlants()
        Rayfield:Notify({
            Title = "Mass Claim Berhasil",
            Content = "Berhasil mengklaim " .. claimed .. " tanaman!",
            Duration = 5,
            Image = 4483362458
        })
    end,
})

-- Button Mass Claim Quest
MainTab:CreateButton({
    Name = "✅ Mass Claim Semua Quest",
    Callback = function()
        local claimed = massClaimQuests()
        Rayfield:Notify({
            Title = "Mass Claim Quest Berhasil",
            Content = "Berhasil mengklaim " .. claimed .. " quest!",
            Duration = 5,
            Image = 4483362458
        })
    end,
})

-- Plant Detector UI
local plantCountLabel = PlantTab:CreateLabel("Tanaman Terdeteksi: 0")
local plantListLabel = PlantTab:CreateLabel("Daftar Tanaman: Tidak ada")

-- Button Scan Tanaman
PlantTab:CreateButton({
    Name = "🔍 Scan Tanaman Sekarang",
    Callback = function()
        local plants = updateDetectedPlants()
        plantCountLabel:Set("Tanaman Terdeteksi: " .. #plants)
        
        if #plants > 0 then
            local plantNames = ""
            for i, plant in ipairs(plants) do
                if i <= 10 then  -- Batasi agar tidak terlalu panjang
                    plantNames = plantNames .. plant.Name .. ", "
                else
                    plantNames = plantNames .. "...dan " .. (#plants - 10) .. " lainnya"
                    break
                end
            end
            plantListLabel:Set("Daftar Tanaman: " .. plantNames)
        else
            plantListLabel:Set("Daftar Tanaman: Tidak ada tanaman terdeteksi")
        end
        
        Rayfield:Notify({
            Title = "Scan Selesai",
            Content = "Ditemukan " .. #plants .. " tanaman yang dapat dipanen",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

-- Toggle Auto Deteksi Tanaman
PlantTab:CreateToggle({
    Name = "🔄 Auto Deteksi Tanaman",
    CurrentValue = false,
    Flag = "AutoPlantDetection",
    Callback = function(Value)
        plantDetectionEnabled = Value
        if plantDetectionEnabled then
            task.spawn(function()
                while plantDetectionEnabled do
                    local plants = updateDetectedPlants()
                    plantCountLabel:Set("Tanaman Terdeteksi: " .. #plants)
                    task.wait(2)
                end
            end)
        end
    end,
})

-- Slider Delay Auto Collect
MiscTab:CreateSlider({
    Name = "Delay Auto Collect (Detik)",
    Range = {0.1, 2},
    Increment = 0.1,
    Suffix = "detik",
    CurrentValue = collectDelay,
    Flag = "CollectDelay",
    Callback = function(Value)
        collectDelay = Value
    end,
})

-- Toggle Boost FPS
BoostTab:CreateToggle({
    Name = "🚀 Boost FPS (Rekomendasi)",
    CurrentValue = false,
    Flag = "FPSBoost",
    Callback = function(Value)
        fpsBoostEnabled = Value
        applyFPSBoost()
        
        if fpsBoostEnabled then
            Rayfield:Notify({
                Title = "FPS Boost Diaktifkan",
                Content = "Performance game telah ditingkatkan!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "FPS Boost Dimatikan",
                Content = "Pengaturan grafis kembali normal.",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

-- Button Optimize Game
BoostTab:CreateButton({
    Name = "⚡ Optimasi Game Sekarang",
    Callback = function()
        fpsBoostEnabled = true
        applyFPSBoost()
        Rayfield:Notify({
            Title = "Game Dioptimalkan",
            Content = "Performance game telah ditingkatkan!",
            Duration = 5,
            Image = 4483362458
        })
    end,
})

-- Button Teleport ke Farm
MiscTab:CreateButton({
    Name = "Teleport ke Farm",
    Callback = function()
        if workspace:FindFirstChild("Farm") then
            local char = Player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = workspace.Farm.CFrame + Vector3.new(0, 5, 0)
            end
        else
            Rayfield:Notify({
                Title = "Farm Tidak Ditemukan",
                Content = "Objek 'Farm' tidak ada di workspace.",
                Duration = 5
            })
        end
    end,
})

-- Notifikasi ketika script aktif
Rayfield:Notify({
    Title = "✅ Script Loaded",
    Content = "Grow A Garden Auto Farm + Mass Claim aktif!\nGunakan tombol Mass Claim untuk langsung mengambil semua tanaman dan quest.",
    Duration = 7,
    Image = 4483362458
})

-- Jalankan scan awal
task.spawn(function()
    wait(2)
    local plants = updateDetectedPlants()
    plantCountLabel:Set("Tanaman Terdeteksi: " .. #plants)
    
    -- Terapkan boost FPS otomatis
    fpsBoostEnabled = true
    applyFPSBoost()
end)
