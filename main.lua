-- ⚡ CYBER DRAGON – CLASSIC EDITION (HITMARKER ON EVERY SHOT)
task.wait(1)

-- ========== SAFE ANTI‑KICK ==========
do
    local lp = game:GetService("Players").LocalPlayer
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method:lower():find("kick") or method == "Shutdown" then
            if self == lp or self == game then
                return
            end
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end

-- ========== UNLOCK ALL COSMETICS (ORIGINAL – ONE‑TIME GUARD) ==========
local unlockOnce = false
local function UnlockAll()
    if unlockOnce then return end
    unlockOnce = true

    local plr = game:GetService("Players").LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    local playerScripts = plr.PlayerScripts
    local controllers = playerScripts.Controllers
    local EnumLibrary = require(ReplicatedStorage.Modules:WaitForChild("EnumLibrary", 10))
    if EnumLibrary then EnumLibrary:WaitForEnumBuilder() end
    local CosmeticLibrary = require(ReplicatedStorage.Modules:WaitForChild("CosmeticLibrary", 10))
    local ItemLibrary = require(ReplicatedStorage.Modules:WaitForChild("ItemLibrary", 10))
    local DataController = require(controllers:WaitForChild("PlayerDataController", 10))
    local equipped, favorites = {}, {}
    local constructingWeapon, viewingProfile = nil, nil
    local lastUsedWeapon = nil

    local function cloneCosmetic(name, cosmeticType, options)
        local base = CosmeticLibrary.Cosmetics[name]
        if not base then return nil end
        local data = {}
        for key, value in pairs(base) do data[key] = value end
        data.Name = name
        data.Type = data.Type or cosmeticType
        data.Seed = data.Seed or math.random(1, 1000000)
        if EnumLibrary then
            local success, enumId = pcall(EnumLibrary.ToEnum, EnumLibrary, name)
            if success and enumId then data.Enum, data.ObjectID = enumId, data.ObjectID or enumId end
        end
        if options then
            if options.inverted ~= nil then data.Inverted = options.inverted end
            if options.favoritesOnly ~= nil then data.OnlyUseFavorites = options.favoritesOnly end
        end
        return data
    end

    local saveFile = "unlockall/config.json"
    local function saveConfig()
        if not writefile then return end
        pcall(function()
            local config = {equipped = {}, favorites = favorites}
            for weapon, cosmetics in pairs(equipped) do
                config.equipped[weapon] = {}
                for cosmeticType, cosmeticData in pairs(cosmetics) do
                    if cosmeticData and cosmeticData.Name then
                        config.equipped[weapon][cosmeticType] = {
                            name = cosmeticData.Name,
                            seed = cosmeticData.Seed,
                            inverted = cosmeticData.Inverted
                        }
                    end
                end
            end
            makefolder("unlockall")
            writefile(saveFile, HttpService:JSONEncode(config))
        end)
    end

    local function loadConfig()
        if not readfile or not isfile or not isfile(saveFile) then return end
        pcall(function()
            local config = HttpService:JSONDecode(readfile(saveFile))
            if config.equipped then
                for weapon, cosmetics in pairs(config.equipped) do
                    equipped[weapon] = {}
                    for cosmeticType, cosmeticData in pairs(cosmetics) do
                        local cloned = cloneCosmetic(cosmeticData.name, cosmeticType, {inverted = cosmeticData.inverted})
                        if cloned then cloned.Seed = cosmeticData.seed equipped[weapon][cosmeticType] = cloned end
                    end
                end
            end
            favorites = config.favorites or {}
        end)
    end

    CosmeticLibrary.OwnsCosmeticNormally = function() return true end
    CosmeticLibrary.OwnsCosmeticUniversally = function() return true end
    CosmeticLibrary.OwnsCosmeticForWeapon = function() return true end
    local originalOwnsCosmetic = CosmeticLibrary.OwnsCosmetic
    CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
        if name:find("MISSING_") then return originalOwnsCosmetic(self, inventory, name, weapon) end
        return true
    end

    local originalGet = DataController.Get
    DataController.Get = function(self, key)
        local data = originalGet(self, key)
        if key == "CosmeticInventory" then
            local proxy = {}
            if data then for k, v in pairs(data) do proxy[k] = v end end
            return setmetatable(proxy, {__index = function() return true end})
        end
        if key == "FavoritedCosmetics" then
            local result = data and table.clone(data) or {}
            for weapon, favs in pairs(favorites) do
                result[weapon] = result[weapon] or {}
                for name, isFav in pairs(favs) do result[weapon][name] = isFav end
            end
            return result
        end
        return data
    end

    local originalGetWeaponData = DataController.GetWeaponData
    DataController.GetWeaponData = function(self, weaponName)
        local data = originalGetWeaponData(self, weaponName)
        if not data then return nil end
        local merged = {}
        for key, value in pairs(data) do merged[key] = value end
        merged.Name = weaponName
        if equipped[weaponName] then
            for cosmeticType, cosmeticData in pairs(equipped[weaponName]) do merged[cosmeticType] = cosmeticData end
        end
        return merged
    end

    local FighterController
    pcall(function() FighterController = require(controllers:WaitForChild("FighterController", 10)) end)

    if hookmetamethod then
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local dataRemotes = remotes and remotes:FindFirstChild("Data")
        local equipRemote = dataRemotes and dataRemotes:FindFirstChild("EquipCosmetic")
        local favoriteRemote = dataRemotes and dataRemotes:FindFirstChild("FavoriteCosmetic")
        local replicationRemotes = remotes and remotes:FindFirstChild("Replication")
        local fighterRemotes = replicationRemotes and replicationRemotes:FindFirstChild("Fighter")
        local useItemRemote = fighterRemotes and fighterRemotes:FindFirstChild("UseItem")
        if equipRemote then
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                if getnamecallmethod() ~= "FireServer" then return oldNamecall(self, ...) end
                local args = {...}
                if useItemRemote and self == useItemRemote then
                    local objectID = args[1]
                    if FighterController then
                        pcall(function()
                            local fighter = FighterController:GetFighter(plr)
                            if fighter and fighter.Items then
                                for _, item in pairs(fighter.Items) do
                                    if item:Get("ObjectID") == objectID then
                                        lastUsedWeapon = item.Name
                                        break
                                    end
                                end
                            end
                        end)
                    end
                end
                if self == equipRemote then
                    local weaponName, cosmeticType, cosmeticName, options = args[1], args[2], args[3], args[4] or {}
                    if cosmeticName and cosmeticName ~= "None" and cosmeticName ~= "" then
                        local inventory = DataController:Get("CosmeticInventory")
                        if inventory and rawget(inventory, cosmeticName) then return oldNamecall(self, ...) end
                    end
                    equipped[weaponName] = equipped[weaponName] or {}
                    if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then
                        equipped[weaponName][cosmeticType] = nil
                        if not next(equipped[weaponName]) then equipped[weaponName] = nil end
                    else
                        local cloned = cloneCosmetic(cosmeticName, cosmeticType, {inverted = options.IsInverted, favoritesOnly = options.OnlyUseFavorites})
                        if cloned then equipped[weaponName][cosmeticType] = cloned end
                    end
                    task.defer(function()
                        pcall(function() DataController.CurrentData:Replicate("WeaponInventory") end)
                        task.wait(0.2)
                        saveConfig()
                    end)
                    return
                end
                if self == favoriteRemote then
                    favorites[args[1]] = favorites[args[1]] or {}
                    favorites[args[1]][args[2]] = args[3] or nil
                    saveConfig()
                    task.spawn(function() pcall(function() DataController.CurrentData:Replicate("FavoritedCosmetics") end) end)
                    return
                end
                return oldNamecall(self, ...)
            end)
        end
    end

    local ClientItem
    pcall(function() ClientItem = require(plr.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem) end)
    if ClientItem and ClientItem._CreateViewModel then
        local originalCreateViewModel = ClientItem._CreateViewModel
        ClientItem._CreateViewModel = function(self, viewmodelRef)
            local weaponName = self.Name
            local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
            constructingWeapon = (weaponPlayer == plr) and weaponName or nil
            if weaponPlayer == plr and equipped[weaponName] and equipped[weaponName].Skin and viewmodelRef then
                local dataKey, skinKey, nameKey = self:ToEnum("Data"), self:ToEnum("Skin"), self:ToEnum("Name")
                if viewmodelRef[dataKey] then
                    viewmodelRef[dataKey][skinKey] = equipped[weaponName].Skin
                    viewmodelRef[dataKey][nameKey] = equipped[weaponName].Skin.Name
                elseif viewmodelRef.Data then
                    viewmodelRef.Data.Skin = equipped[weaponName].Skin
                    viewmodelRef.Data.Name = equipped[weaponName].Skin.Name
                end
            end
            local result = originalCreateViewModel(self, viewmodelRef)
            constructingWeapon = nil
            return result
        end
    end

    local viewModelModule = plr.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
    if viewModelModule then
        local ClientViewModel = require(viewModelModule)
        if ClientViewModel.GetWrap then
            local originalGetWrap = ClientViewModel.GetWrap
            ClientViewModel.GetWrap = function(self)
                local weaponName = self.ClientItem and self.ClientItem.Name
                local weaponPlayer = self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.Player
                if weaponName and weaponPlayer == plr and equipped[weaponName] and equipped[weaponName].Wrap then
                    return equipped[weaponName].Wrap
                end
                return originalGetWrap(self)
            end
        end
        local originalNew = ClientViewModel.new
        ClientViewModel.new = function(replicatedData, clientItem)
            local weaponPlayer = clientItem.ClientFighter and clientItem.ClientFighter.Player
            local weaponName = constructingWeapon or clientItem.Name
            if weaponPlayer == plr and equipped[weaponName] then
                local ReplicatedClass = require(ReplicatedStorage.Modules.ReplicatedClass)
                local dataKey = ReplicatedClass:ToEnum("Data")
                replicatedData[dataKey] = replicatedData[dataKey] or {}
                local cosmetics = equipped[weaponName]
                if cosmetics.Skin then replicatedData[dataKey][ReplicatedClass:ToEnum("Skin")] = cosmetics.Skin end
                if cosmetics.Wrap then replicatedData[dataKey][ReplicatedClass:ToEnum("Wrap")] = cosmetics.Wrap end
                if cosmetics.Charm then replicatedData[dataKey][ReplicatedClass:ToEnum("Charm")] = cosmetics.Charm end
            end
            local result = originalNew(replicatedData, clientItem)
            if weaponPlayer == plr and equipped[weaponName] and equipped[weaponName].Wrap and result._UpdateWrap then
                result:_UpdateWrap()
                task.delay(0.1, function() if not result._destroyed then result:_UpdateWrap() end end)
            end
            return result
        end
    end

    local originalGetViewModelImage = ItemLibrary.GetViewModelImageFromWeaponData
    ItemLibrary.GetViewModelImageFromWeaponData = function(self, weaponData, highRes)
        if not weaponData then return originalGetViewModelImage(self, weaponData, highRes) end
        local weaponName = weaponData.Name
        local shouldShowSkin = (weaponData.Skin and equipped[weaponName] and weaponData.Skin == equipped[weaponName].Skin) or (viewingProfile == plr and equipped[weaponName] and equipped[weaponName].Skin)
        if shouldShowSkin and equipped[weaponName] and equipped[weaponName].Skin then
            local skinInfo = self.ViewModels[equipped[weaponName].Skin.Name]
            if skinInfo then return skinInfo[highRes and "ImageHighResolution" or "Image"] or skinInfo.Image end
        end
        return originalGetViewModelImage(self, weaponData, highRes)
    end

    pcall(function()
        local ViewProfile = require(plr.PlayerScripts.Modules.Pages.ViewProfile)
        if ViewProfile and ViewProfile.Fetch then
            local originalFetch = ViewProfile.Fetch
            ViewProfile.Fetch = function(self, targetPlayer)
                viewingProfile = targetPlayer
                return originalFetch(self, targetPlayer)
            end
        end
    end)

    local ClientEntity
    pcall(function() ClientEntity = require(plr.PlayerScripts.Modules.ClientReplicatedClasses.ClientEntity) end)
    if ClientEntity and ClientEntity.ReplicateFromServer then
        local originalReplicateFromServer = ClientEntity.ReplicateFromServer
        ClientEntity.ReplicateFromServer = function(self, action, ...)
            if action == "FinisherEffect" then
                local args = {...}
                local killerName = args[3]
                local decodedKiller = killerName
                if type(killerName) == "userdata" and EnumLibrary and EnumLibrary.FromEnum then
                    local ok, decoded = pcall(EnumLibrary.FromEnum, EnumLibrary, killerName)
                    if ok and decoded then decodedKiller = decoded end
                end
                local isOurKill = tostring(decodedKiller) == plr.Name or tostring(decodedKiller):lower() == plr.Name:lower()
                if isOurKill and lastUsedWeapon and equipped[lastUsedWeapon] and equipped[lastUsedWeapon].Finisher then
                    local finisherData = equipped[lastUsedWeapon].Finisher
                    local finisherEnum = finisherData.Enum
                    if not finisherEnum and EnumLibrary then
                        local ok, result = pcall(EnumLibrary.ToEnum, EnumLibrary, finisherData.Name)
                        if ok and result then finisherEnum = result end
                    end
                    if finisherEnum then
                        args[1] = finisherEnum
                        return originalReplicateFromServer(self, action, unpack(args))
                    end
                end
            end
            return originalReplicateFromServer(self, action, ...)
        end
    end

    loadConfig()
    print("All cosmetics unlocked!")
end

-- ========== SERVICES & STATE ==========
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local plr = Players.LocalPlayer
local camera = workspace.CurrentCamera

local state = {
    NoRecoil = false, NoSpread = false, AutoDrop = false, ESP = false,
    ThirdPerson = false, AntiKatana = false, NoBounds = false, JumpBug = false,
    AutoStrafe = false, RapidFire = false, AutoWeapon = false, InstantScope = false,
    AlwaysBackstab = false, RemoveKillers = false, NoFireDamage = false,
    AntiFreeze = false, Fly = false, Noclip = false, AntiAim = false,
    AutoFarm = false, TornadoAnim = false, HitNotif = true
}
local settings = {WalkSpeed = 16, JumpPower = 50, StrafeIntensity = 50, FlySpeed = 50}
local farmPosition = "Behind"

-- ========== WEAPON MODS ==========
local function toggleTableAttribute(attribute, value)
    for _, gcVal in pairs(getgc(true)) do
        if type(gcVal) == "table" and rawget(gcVal, attribute) then
            gcVal[attribute] = value
        end
    end
end

local function startWeaponMods()
    if state.NoRecoil then toggleTableAttribute("ShootRecoil", 0) end
    if state.NoSpread then toggleTableAttribute("ShootSpread", 0) end
    if state.RapidFire then toggleTableAttribute("ShootCooldown", 0) end
    if state.InstantScope then toggleTableAttribute("ScopeTime", 0) end
end
local function stopWeaponMods() end

-- Auto Weapon
local autoWeapConn
local function enableAutoWeapon()
    if autoWeapConn then return end
    autoWeapConn = RunService.Heartbeat:Connect(function()
        if not state.AutoWeapon then return end
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
        local tool = plr.Character and plr.Character:FindFirstChildOfClass("Tool")
        if tool then pcall(function() tool:Activate() end) end
    end)
end
local function disableAutoWeapon()
    if autoWeapConn then autoWeapConn:Disconnect(); autoWeapConn = nil end
end

-- Always Backstab
local function applyAlwaysBackstab(char)
    if not state.AlwaysBackstab then return end
    if not char:FindFirstChild("BackstabBonus") then
        local flag = Instance.new("BoolValue")
        flag.Name = "BackstabBonus"
        flag.Value = true
        flag.Parent = char
    end
end
plr.CharacterAdded:Connect(applyAlwaysBackstab)
for _, p in pairs(Players:GetPlayers()) do
    if p ~= plr then
        p.CharacterAdded:Connect(applyAlwaysBackstab)
        if p.Character then applyAlwaysBackstab(p.Character) end
    end
end
if plr.Character then applyAlwaysBackstab(plr.Character) end

-- Anti Katana
local antiKatConn
local function enableAntiKatana()
    if antiKatConn then return end
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
    if not remotes then return end
    local parryRemote = remotes:FindFirstChild("Parry") or remotes:FindFirstChild("KatanaParry")
    if parryRemote then antiKatConn = parryRemote.OnClientEvent:Connect(function() end) end
end
local function disableAntiKatana()
    if antiKatConn then antiKatConn:Disconnect(); antiKatConn = nil end
end

-- ========== MOVEMENT ==========
-- Fly
local flyConn, flyVel, flyGyro
local function enableFly()
    local char = plr.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    hum.PlatformStand = true
    flyVel = Instance.new("BodyVelocity")
    flyVel.Velocity = Vector3.zero
    flyVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyVel.P = 10000
    flyVel.Parent = hrp
    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    flyGyro.P = 10000
    flyGyro.D = 100
    flyGyro.CFrame = hrp.CFrame
    flyGyro.Parent = hrp
    flyConn = RunService.RenderStepped:Connect(function()
        if not state.Fly then return end
        local c = plr.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then return end
        local speed = settings.FlySpeed
        local dir = Vector3.zero
        local camCF = camera.CFrame
        local forward = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
        local right = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + forward end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - forward end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - right end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + right end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            dir = dir - Vector3.new(0, 1, 0)
        end
        flyVel.Velocity = dir.Unit * speed
        flyGyro.CFrame = camCF
    end)
end
local function disableFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyVel then flyVel:Destroy(); flyVel = nil end
    if flyGyro then flyGyro:Destroy(); flyGyro = nil end
    if plr.Character then
        local hum = plr.Character:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

-- Noclip
local noclipConn
local function enableNoclip()
    if noclipConn then return end
    noclipConn = RunService.Stepped:Connect(function()
        if not state.Noclip then return end
        local char = plr.Character
        if not char then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end
local function disableNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if plr.Character then
        for _, part in pairs(plr.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

-- AntiAim
local aaConn, aaAngle
local function enableAntiAim()
    if aaConn then return end
    aaAngle = 0
    aaConn = RunService.Heartbeat:Connect(function()
        if not state.AntiAim then return end
        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        aaAngle = (aaAngle + 25) % 360
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(math.pi, math.rad(aaAngle), 0)
    end)
end
local function disableAntiAim()
    if aaConn then aaConn:Disconnect(); aaConn = nil end
end

-- AutoStrafe
local strafeConn, strafeDir, strafeTick
local function enableAutoStrafe()
    if strafeConn then return end
    strafeDir, strafeTick = 1, 0
    strafeConn = RunService.Heartbeat:Connect(function()
        if not state.AutoStrafe then return end
        local char = plr.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end
        if hum:GetState() == Enum.HumanoidStateType.Freefall then
            local now = tick()
            local interval = 0.3 - ((settings.StrafeIntensity / 100) * 0.25)
            if now - strafeTick > interval then
                strafeTick = now
                strafeDir = -strafeDir
            end
            local right = hrp.CFrame.RightVector
            local vel = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.new(vel.X + (right.X * strafeDir * (settings.StrafeIntensity / 10)), vel.Y, vel.Z + (right.Z * strafeDir * (settings.StrafeIntensity / 10)))
        end
    end)
end
local function disableAutoStrafe()
    if strafeConn then strafeConn:Disconnect(); strafeConn = nil end
end

-- JumpBug
local jbConn
local function enableJumpBug()
    if jbConn then return end
    jbConn = RunService.Heartbeat:Connect(function()
        if not state.JumpBug then return end
        local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
        if hum and hum:GetState() == Enum.HumanoidStateType.Landed then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end
local function disableJumpBug()
    if jbConn then jbConn:Disconnect(); jbConn = nil end
end

-- Tornado Animation (original – uses animation file)
local tornadoAnimId = "rbxassetid://92281817840531"
local tornadoAnimObj = Instance.new("Animation")
tornadoAnimObj.AnimationId = tornadoAnimId
local tornadoTrack
local function playTornadoAnim(character)
    local hum = character:FindFirstChildWhichIsA("Humanoid")
    if not hum then return end
    for _, track in next, hum:GetPlayingAnimationTracks() do track:Stop() end
    local resolvedId = tornadoAnimId
    pcall(function()
        local objs = game:GetObjects(resolvedId)
        for _, obj in ipairs(objs) do
            if obj:IsA("Animation") then resolvedId = obj.AnimationId break end
        end
    end)
    tornadoAnimObj.AnimationId = resolvedId
    tornadoTrack = hum:LoadAnimation(tornadoAnimObj)
    tornadoTrack.Priority = Enum.AnimationPriority.Action4
    tornadoTrack:Play()
    tornadoTrack:AdjustSpeed(3)
    tornadoTrack.Stopped:Connect(function()
        if state.TornadoAnim then playTornadoAnim(character) end
    end)
end
local function enableTornadoAnim()
    local char = plr.Character
    if char then playTornadoAnim(char) end
end
local function disableTornadoAnim()
    if tornadoTrack then tornadoTrack:Stop(); tornadoTrack = nil end
end

-- Third Person
local tpConn, originalCamType
local function enableThirdPerson()
    if tpConn then return end
    local char = plr.Character
    if not char then return end
    if not originalCamType then originalCamType = camera.CameraType end
    camera.CameraType = Enum.CameraType.Scriptable
    tpConn = RunService.RenderStepped:Connect(function()
        if not state.ThirdPerson then return end
        local c = plr.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        camera.CFrame = CFrame.new(hrp.Position - hrp.CFrame.LookVector*12 + Vector3.new(0,4,0), hrp.Position + Vector3.new(0,2,0))
    end)
end
local function disableThirdPerson()
    if tpConn then tpConn:Disconnect(); tpConn = nil end
    if originalCamType then camera.CameraType = originalCamType; originalCamType = nil end
end

-- World Protections
local function enableNoBounds()
    local folder = workspace:FindFirstChild("OutOfBounds") or workspace:FindFirstChild("DeathZones")
    if folder then for _, z in ipairs(folder:GetChildren()) do if z:IsA("BasePart") then z.CanTouch = false end end end
end
local function enableRemoveKillers()
    local obj = workspace:FindFirstChild("Killer") or workspace:FindFirstChild("Death")
    if obj then obj:Destroy() end
end
local function enableNoFireDamage()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower():find("fire") then v.CanTouch = false end
    end
end
local function enableAntiFreeze()
    task.spawn(function()
        local lastSpeed = 16
        while state.AntiFreeze do
            local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
            if hum then
                if hum.WalkSpeed == 0 then hum.WalkSpeed = lastSpeed end
                lastSpeed = hum.WalkSpeed
            end
            task.wait(0.2)
        end
    end)
end

-- Auto Farm
local farmConn
local function enableAutoFarm()
    if farmConn then return end
    farmConn = RunService.Heartbeat:Connect(function()
        if not state.AutoFarm then return end
        local char = plr.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local closest, dist = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= plr and p.Character then
                local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChild("Humanoid")
                if tHrp and hum and hum.Health > 0 then
                    local d = (tHrp.Position - hrp.Position).Magnitude
                    if d < dist then closest = p; dist = d end
                end
            end
        end
        if closest and closest.Character then
            local tHrp = closest.Character:FindFirstChild("HumanoidRootPart")
            if tHrp then
                local offset = farmPosition == "Above" and Vector3.new(0,6,0) or (farmPosition == "Under" and Vector3.new(0,-3,0)) or (-tHrp.CFrame.LookVector*3 + Vector3.new(0,0.5,0))
                hrp.CFrame = CFrame.new(tHrp.Position + offset, tHrp.Position)
            end
        end
    end)
end
local function disableAutoFarm()
    if farmConn then farmConn:Disconnect(); farmConn = nil end
end

-- Auto Drop Collector
local drops = {}
workspace.ChildAdded:Connect(function(c) if c.Name == "_drop" then drops[c] = true end end)
workspace.ChildRemoved:Connect(function(c) drops[c] = nil end)
for _, c in pairs(workspace:GetChildren()) do if c.Name == "_drop" then drops[c] = true end end
RunService.Heartbeat:Connect(function()
    if not state.AutoDrop then return end
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for obj in pairs(drops) do
        if obj.Parent then
            pcall(function() firetouchinterest(hrp, obj, 0) end)
            pcall(function() firetouchinterest(hrp, obj, 1) end)
        end
    end
end)

-- ========== ESP (FIXED HIDE) ==========
local espObjects = {}
local drawingSupported = pcall(function() return Drawing.new("Square") end)
if drawingSupported then
    local function newDrawing(t, props)
        local d = Drawing.new(t)
        for k,v in pairs(props) do d[k] = v end
        return d
    end
    local function createESP(p)
        if espObjects[p] then return end
        espObjects[p] = {
            box = newDrawing("Square", {Visible = false, Color = Color3.fromRGB(128,213,247), Thickness = 1.5, Filled = false}),
            name = newDrawing("Text", {Visible = false, Color = Color3.new(1,1,1), Size = 13, Center = true, Outline = true, Font = 2}),
            dist = newDrawing("Text", {Visible = false, Color = Color3.fromRGB(200,200,200), Size = 11, Center = true, Outline = true, Font = 2}),
            hpBg = newDrawing("Square", {Visible = false, Color = Color3.new(0,0,0), Filled = true}),
            hp = newDrawing("Square", {Visible = false, Color = Color3.fromRGB(128,213,247), Filled = true})
        }
    end
    local function removeESP(p)
        if espObjects[p] then for _,v in pairs(espObjects[p]) do v:Remove() end; espObjects[p] = nil end
    end
    local function hideESP(p)
        if not espObjects[p] then return end
        for _, o in pairs(espObjects[p]) do o.Visible = false end
    end
    local function getBounds(char)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        local cnt = 0
        for _, off in ipairs({Vector3.new(2,3,2),Vector3.new(-2,3,-2),Vector3.new(2,3,-2),Vector3.new(-2,3,2),Vector3.new(2,-3,2),Vector3.new(-2,-3,-2),Vector3.new(2,-3,-2),Vector3.new(-2,-3,2)}) do
            local sp, on = camera:WorldToViewportPoint(hrp.Position + off)
            if on then
                cnt += 1
                minX = math.min(minX, sp.X); minY = math.min(minY, sp.Y)
                maxX = math.max(maxX, sp.X); maxY = math.max(maxY, sp.Y)
            end
        end
        if cnt == 0 then return nil end
        return minX, minY, maxX, maxY, (minX+maxX)/2
    end
    local function updateESP(p)
        local esp = espObjects[p]
        if not esp then return end
        local char = p.Character
        if not char then esp.box.Visible = false; return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum then esp.box.Visible = false; return end
        local myHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp then esp.box.Visible = false; return end
        local dist = (hrp.Position - myHrp.Position).Magnitude
        if dist > 1000 then esp.box.Visible = false; return end
        local x1,y1,x2,y2,cx = getBounds(char)
        if not x1 then esp.box.Visible = false; return end
        local w,h = x2-x1, y2-y1
        esp.box.Position = Vector2.new(x1, y1)
        esp.box.Size = Vector2.new(w, h)
        esp.box.Visible = true
        esp.name.Text = p.DisplayName
        esp.name.Position = Vector2.new(cx, y1 - 16)
        esp.name.Visible = true
        esp.dist.Text = math.floor(dist).."m"
        esp.dist.Position = Vector2.new(cx, y2 + 2)
        esp.dist.Visible = true
        local hpFrac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        local barH = h * hpFrac
        esp.hp.Color = Color3.new(2*(1-hpFrac), 2*hpFrac, 0)
        esp.hpBg.Position = Vector2.new(x1 - 7, y1)
        esp.hpBg.Size = Vector2.new(4, h)
        esp.hpBg.Visible = true
        esp.hp.Position = Vector2.new(x1 - 7, y1 + h - barH)
        esp.hp.Size = Vector2.new(4, barH)
        esp.hp.Visible = true
    end
    for _, p in pairs(Players:GetPlayers()) do if p ~= plr then createESP(p) end end
    Players.PlayerAdded:Connect(function(p) if p ~= plr then createESP(p) end end)
    Players.PlayerRemoving:Connect(removeESP)
    RunService.RenderStepped:Connect(function()
        if not state.ESP then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= plr then hideESP(p) end
            end
            return
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= plr then updateESP(p) end
        end
    end)
end

-- ========== BIG NEON FLOATING DAMAGE NUMBERS (NO COOLDOWN) ==========
local lastAttackTime = 0
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        lastAttackTime = tick()
    end
end)
UserInputService.TouchTap:Connect(function()
    lastAttackTime = tick()
end)

local function isAttacking()
    return (tick() - lastAttackTime) <= 0.4
end

local function showDamageNumber(char, damage, isHeadshot)
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if not head then return end

    local bill = Instance.new("BillboardGui")
    bill.Name = "DamageNumber"
    bill.Size = UDim2.new(0, 120, 0, 60)
    bill.StudsOffset = Vector3.new(0, 2.5, 0)
    bill.AlwaysOnTop = true
    bill.LightInfluence = 0
    bill.Parent = head

    local label = Instance.new("TextLabel", bill)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBlack
    label.TextSize = 36
    label.Text = tostring(math.floor(damage))
    label.TextTransparency = 0
    label.TextStrokeTransparency = 0.2

    if isHeadshot then
        label.TextColor3 = Color3.fromRGB(255, 100, 255)
    else
        label.TextColor3 = Color3.fromRGB(0, 255, 255)
    end

    local startTime = tick()
    local duration = 1.2
    local riseSpeed = 50

    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        local elapsed = tick() - startTime
        if elapsed >= duration then
            conn:Disconnect()
            bill:Destroy()
            return
        end
        local progress = elapsed / duration
        label.TextTransparency = math.min(1, progress * 1.2)
        bill.StudsOffset = Vector3.new(0, 2.5 + (riseSpeed * elapsed), 0)
    end)
end

local lastHealth = {}
-- ❌ Cooldown removed – every single damage event now triggers a number
local function monitorPlayer(p)
    if p == plr then return end
    local function onChar(char)
        task.wait(0.3)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        lastHealth[p] = hum.Health
        hum.HealthChanged:Connect(function(new)
            if not state.HitNotif then return end
            local prev = lastHealth[p]
            if prev and new < prev then
                local dmg = prev - new
                if dmg >= 1 and isAttacking() then
                    local isHead = false
                    local head = char:FindFirstChild("Head")
                    if head then
                        local ray = Ray.new(camera.CFrame.Position, (head.Position - camera.CFrame.Position).Unit * 1000)
                        local hit = workspace:FindPartOnRay(ray, plr.Character)
                        if hit and hit:IsDescendantOf(char) and hit.Name == "Head" then
                            isHead = true
                        end
                    end
                    showDamageNumber(char, dmg, isHead)
                end
            end
            lastHealth[p] = new
        end)
    end
    p.CharacterAdded:Connect(onChar)
    if p.Character then onChar(p.Character) end
end
for _, p in pairs(Players:GetPlayers()) do monitorPlayer(p) end
Players.PlayerAdded:Connect(monitorPlayer)
Players.PlayerRemoving:Connect(function(p) lastHealth[p]=nil end)

-- ========== STATIC NEON GUI ==========
local C = {
    bg = Color3.fromRGB(15, 15, 15),
    bg2 = Color3.fromRGB(18, 18, 18),
    bg3 = Color3.fromRGB(22, 22, 22),
    neon = Color3.fromRGB(128, 213, 247),
    neon2 = Color3.fromRGB(60, 60, 60),
    border = Color3.fromRGB(0, 0, 0),
    text = Color3.fromRGB(255, 255, 255),
    dim = Color3.fromRGB(200, 200, 200),
    white = Color3.fromRGB(255, 255, 255),
    red = Color3.fromRGB(255, 60, 60)
}

local isMobileMain = UserInputService.TouchEnabled and not UserInputService.MouseEnabled and not UserInputService.KeyboardEnabled
local rootW = (isMobileMain and 360) or 540
local rootH = (isMobileMain and 300) or 380
local rootPosX = (isMobileMain and 0) or 0.5
local rootPosXO = (isMobileMain and 4) or -270
local rootPosY = (isMobileMain and 0) or 0.5
local rootPosYO = (isMobileMain and 40) or -190
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "🐉CyberDragon🐉"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = false
screenGui.Parent = plr:WaitForChild("PlayerGui")
local root = Instance.new("Frame")
root.Size = UDim2.new(0, rootW, 0, rootH)
root.Position = UDim2.new(rootPosX, rootPosXO, rootPosY, rootPosYO)
root.BackgroundColor3 = C.bg
root.BorderSizePixel = 0
root.BackgroundTransparency = 0
root.ClipsDescendants = true
root.Parent = screenGui
Instance.new("UICorner", root).CornerRadius = UDim.new(0, 8)
local rootStroke = Instance.new("UIStroke", root)
rootStroke.Color = C.neon2
rootStroke.Thickness = 1.5
rootStroke.Transparency = 1
task.defer(function()
    if (root.AbsolutePosition.X < -root.AbsoluteSize.X) or (root.AbsolutePosition.X > (camera.ViewportSize.X + 200)) then
        root.Position = UDim2.new(0.5, -rootW/2, 0.5, -rootH/2)
    end
end)
local titleBarH = (isMobileMain and 28) or 36
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, titleBarH)
titleBar.BackgroundColor3 = C.bg2
titleBar.BorderSizePixel = 0
titleBar.Parent = root
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)
local tbFix = Instance.new("Frame")
tbFix.Size = UDim2.new(1, 0, 0.5, 0)
tbFix.Position = UDim2.new(0, 0, 0.5, 0)
tbFix.BackgroundColor3 = C.bg2
tbFix.BorderSizePixel = 0
tbFix.Parent = titleBar
local titleAccent = Instance.new("Frame")
titleAccent.Size = UDim2.new(0, 3, 1, -8)
titleAccent.Position = UDim2.new(0, 6, 0, 4)
titleAccent.BackgroundColor3 = C.neon
titleAccent.BorderSizePixel = 0
titleAccent.Parent = titleBar
Instance.new("UICorner", titleAccent).CornerRadius = UDim.new(1, 0)
local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -60, 1, 0)
titleLbl.Position = UDim2.new(0, 14, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = (isMobileMain and "◈ Cyber Dragon") or "◈ Cyber Dragon"
titleLbl.TextColor3 = C.neon
titleLbl.TextSize = (isMobileMain and 10) or 12
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = titleBar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -24, 0.5, -10)
closeBtn.BackgroundColor3 = C.bg3
closeBtn.BorderSizePixel = 0
closeBtn.Text = "×"
closeBtn.TextColor3 = C.neon
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", closeBtn).Color = C.neon2
local minimized = false
closeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(root, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = (minimized and UDim2.new(0, rootW, 0, titleBarH)) or UDim2.new(0, rootW, 0, rootH)}):Play()
    closeBtn.Text = (minimized and "+") or "×"
end)
local hidden = false
if not isMobileMain then
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            hidden = not hidden
            if hidden then
                TweenService:Create(root, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = UDim2.new(0, -560, 0.5, -190), BackgroundTransparency = 1}):Play()
                TweenService:Create(rootStroke, TweenInfo.new(0.25), {Transparency = 1}):Play()
                task.delay(0.25, function() root.Visible = false end)
            else
                root.Visible = true
                root.Position = UDim2.new(0, -560, 0.5, -190)
                TweenService:Create(root, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(rootPosX, rootPosXO, rootPosY, rootPosYO), BackgroundTransparency = 0}):Play()
                TweenService:Create(rootStroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
            end
        end
    end)
end
local tabBarTop = titleBarH + 6
local contentTop = tabBarTop + 34
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -16, 0, 28)
tabBar.Position = UDim2.new(0, 8, 0, tabBarTop)
tabBar.BackgroundColor3 = C.bg3
tabBar.BorderSizePixel = 0
tabBar.Parent = root
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", tabBar).Color = C.neon2
local tabList = Instance.new("UIListLayout", tabBar)
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.SortOrder = Enum.SortOrder.LayoutOrder
tabList.Padding = UDim.new(0, 6)
local tabPad = Instance.new("UIPadding", tabBar)
tabPad.PaddingLeft = UDim.new(0, 3)
tabPad.PaddingRight = UDim.new(0, 3)
tabPad.PaddingTop = UDim.new(0, 3)
tabPad.PaddingBottom = UDim.new(0, 3)
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -16, 1, -(contentTop + 6))
contentArea.Position = UDim2.new(0, 8, 0, contentTop + 6)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0
contentArea.Parent = root
local pages = {}
local currentTab = nil
local function switchTab(name)
    if currentTab == name then return end
    currentTab = name
    for pName, pData in pairs(pages) do
        local active = pName == name
        pData.page.Visible = active
        TweenService:Create(pData.tab, TweenInfo.new(0.15), {BackgroundColor3 = (active and C.neon) or C.bg3}):Play()
        pData.tabLbl.TextColor3 = (active and C.bg) or C.dim
    end
end
local function createTab(name, order)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(0, 0, 1, 0)
    tab.AutomaticSize = Enum.AutomaticSize.X
    tab.BackgroundColor3 = C.bg3
    tab.BorderSizePixel = 0
    tab.LayoutOrder = order
    tab.Text = ""
    tab.Parent = tabBar
    Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 4)
    local tabLbl = Instance.new("TextLabel")
    tabLbl.Size = UDim2.new(1, 0, 1, 0)
    tabLbl.BackgroundTransparency = 1
    tabLbl.Text = " " .. name .. " "
    tabLbl.TextColor3 = C.dim
    tabLbl.TextSize = 11
    tabLbl.Font = Enum.Font.GothamBold
    tabLbl.Parent = tab
    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = contentArea
    local leftScroll = Instance.new("ScrollingFrame")
    leftScroll.Size = UDim2.new(0.5, -3, 1, 0)
    leftScroll.Position = UDim2.new(0, 0, 0, 0)
    leftScroll.BackgroundTransparency = 1
    leftScroll.BorderSizePixel = 0
    leftScroll.ScrollBarThickness = 2
    leftScroll.ScrollBarImageColor3 = C.neon
    leftScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    leftScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    leftScroll.Parent = page
    local ll = Instance.new("UIListLayout", leftScroll)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Padding = UDim.new(0, 4)
    local lp = Instance.new("UIPadding", leftScroll)
    lp.PaddingRight = UDim.new(0, 3)
    lp.PaddingBottom = UDim.new(0, 4)
    local rightScroll = Instance.new("ScrollingFrame")
    rightScroll.Size = UDim2.new(0.5, -3, 1, 0)
    rightScroll.Position = UDim2.new(0.5, 3, 0, 0)
    rightScroll.BackgroundTransparency = 1
    rightScroll.BorderSizePixel = 0
    rightScroll.ScrollBarThickness = 2
    rightScroll.ScrollBarImageColor3 = C.neon
    rightScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    rightScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    rightScroll.Parent = page
    local rl = Instance.new("UIListLayout", rightScroll)
    rl.SortOrder = Enum.SortOrder.LayoutOrder
    rl.Padding = UDim.new(0, 4)
    local rp = Instance.new("UIPadding", rightScroll)
    rp.PaddingLeft = UDim.new(0, 3)
    rp.PaddingBottom = UDim.new(0, 4)
    pages[name] = {tab = tab, tabLbl = tabLbl, page = page, left = leftScroll, right = rightScroll}
    tab.MouseButton1Click:Connect(function() switchTab(name) end)
    return leftScroll, rightScroll
end
local function makeHeader(parent, text, order)
    local h = Instance.new("TextLabel")
    h.Size = UDim2.new(1, 0, 0, 18)
    h.BackgroundTransparency = 1
    h.Text = "▸ " .. text
    h.TextColor3 = C.neon
    h.TextSize = 10
    h.Font = Enum.Font.GothamBold
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.LayoutOrder = order
    h.Parent = parent
end
local function makeToggle(parent, labelText, key, order, onEnable, onDisable)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = C.bg3
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    local rs = Instance.new("UIStroke", row)
    rs.Color = C.neon2
    rs.Thickness = 1
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 2, 1, -8)
    accent.Position = UDim2.new(0, 0, 0, 4)
    accent.BackgroundColor3 = C.neon
    accent.BackgroundTransparency = 0.6
    accent.BorderSizePixel = 0
    accent.Parent = row
    Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -52, 1, 0)
    lbl.Position = UDim2.new(0, 9, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = C.text
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    local pillBg = Instance.new("Frame")
    pillBg.Size = UDim2.new(0, 34, 0, 18)
    pillBg.Position = UDim2.new(1, -40, 0.5, -9)
    pillBg.BackgroundColor3 = C.bg3
    pillBg.BorderSizePixel = 0
    pillBg.Parent = row
    Instance.new("UICorner", pillBg).CornerRadius = UDim.new(1, 0)
    local ps = Instance.new("UIStroke", pillBg)
    ps.Color = C.neon
    ps.Thickness = 1
    ps.Transparency = 0.7
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(0, 3, 0.5, -6)
    knob.BackgroundColor3 = C.dim
    knob.BorderSizePixel = 0
    knob.Parent = pillBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    btn.MouseEnter:Connect(function() TweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(38, 38, 38)}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = C.bg3}):Play() end)
    btn.MouseButton1Down:Connect(function() TweenService:Create(row, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(0, 25, 20)}):Play() end)
    btn.MouseButton1Up:Connect(function() TweenService:Create(row, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(38, 38, 38)}):Play() end)
    local function updateVisual(on)
        TweenService:Create(pillBg, TweenInfo.new(0.18), {BackgroundColor3 = (on and C.neon) or C.bg3}):Play()
        TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Back), {Position = (on and UDim2.new(0, 19, 0.5, -6)) or UDim2.new(0, 3, 0.5, -6), BackgroundColor3 = (on and C.neon) or C.dim}):Play()
        ps.Transparency = (on and 0) or 0.7
        accent.BackgroundTransparency = (on and 0) or 0.6
        lbl.TextColor3 = (on and C.neon) or C.text
        TweenService:Create(rs, TweenInfo.new(0.18), {Color = (on and C.neon) or C.neon2}):Play()
    end
    btn.MouseButton1Click:Connect(function()
        state[key] = not state[key]
        updateVisual(state[key])
        if state[key] then if onEnable then onEnable() end else if onDisable then onDisable() end end
    end)
end
local function makeButton(parent, labelText, order, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = C.bg3
    btn.BorderSizePixel = 0
    btn.Text = labelText
    btn.TextColor3 = C.neon
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = order
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local bs = Instance.new("UIStroke", btn)
    bs.Color = C.neon
    bs.Thickness = 1
    bs.Transparency = 0.5
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(38, 38, 38), TextColor3 = C.white}):Play()
        TweenService:Create(bs, TweenInfo.new(0.12), {Transparency = 0}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = C.bg3, TextColor3 = C.neon}):Play()
        TweenService:Create(bs, TweenInfo.new(0.12), {Transparency = 0.5}):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {Size = UDim2.new(1, -4, 0, 28)}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Back), {Size = UDim2.new(1, 0, 0, 30)}):Play()
    end)
    btn.MouseButton1Click:Connect(function() onClick(btn, bs) end)
end
local function makePicker(parent, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = C.bg3
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", row).Color = C.neon2
    local options = {"Behind", "Above", "Under"}
    local btnWidth = 1 / #options
    local pickerBtns = {}
    for i, opt in ipairs(options) do
        local pb = Instance.new("TextButton")
        pb.Size = UDim2.new(btnWidth, -3, 1, -6)
        pb.Position = UDim2.new((i - 1) * btnWidth, ((i == 1) and 3) or 2, 0, 3)
        pb.BackgroundColor3 = ((opt == farmPosition) and C.neon) or C.bg3
        pb.BorderSizePixel = 0
        pb.Text = opt
        pb.TextColor3 = ((opt == farmPosition) and C.bg) or C.dim
        pb.TextSize = 10
        pb.Font = Enum.Font.GothamBold
        pb.Parent = row
        Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 4)
        pickerBtns[opt] = pb
        pb.MouseButton1Click:Connect(function()
            farmPosition = opt
            for _, o in pairs(options) do
                TweenService:Create(pickerBtns[o], TweenInfo.new(0.15), {BackgroundColor3 = ((o == opt) and C.neon) or C.bg3}):Play()
                pickerBtns[o].TextColor3 = ((o == opt) and C.bg) or C.dim
            end
        end)
    end
end
local function makeSlider(parent, labelText, order, minVal, maxVal, defaultVal, settingKey, onChange)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 50)
    row.BackgroundColor3 = C.bg3
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", row).Color = C.neon2
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 0, 16)
    lbl.Position = UDim2.new(0, 9, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = C.text
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 44, 0, 16)
    valLbl.Position = UDim2.new(1, -50, 0, 5)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(defaultVal)
    valLbl.TextColor3 = C.neon
    valLbl.TextSize = 10
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = row
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -18, 0, 4)
    track.Position = UDim2.new(0, 9, 0, 30)
    track.BackgroundColor3 = C.bg3
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = C.neon
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 10, 0, 10)
    handle.Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), -5, 0.5, -5)
    handle.BackgroundColor3 = C.neon
    handle.BorderSizePixel = 0
    handle.Parent = track
    Instance.new("UICorner", handle).CornerRadius = UDim.new(1, 0)
    local draggingSlider = false
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(1, 0, 0, 20)
    sliderBtn.Position = UDim2.new(0, 0, 0, 24)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    sliderBtn.Parent = row
    local function updateSlider(inputX)
        local tp = track.AbsolutePosition.X
        local ts = track.AbsoluteSize.X
        local rel = math.clamp((inputX - tp) / ts, 0, 1)
        local val = math.floor(minVal + (rel * (maxVal - minVal)))
        settings[settingKey] = val
        valLbl.Text = tostring(val)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        handle.Position = UDim2.new(rel, -5, 0.5, -5)
        if onChange then onChange(val) end
    end
    sliderBtn.MouseButton1Down:Connect(function()
        draggingSlider = true
        updateSlider(UserInputService:GetMouseLocation().X)
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if draggingSlider and i.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(i.Position.X)
        end
    end)
end

-- Build Tabs
local cL, cR = createTab("Combat", 1)
makeHeader(cL, "Weapon", 1)
makeToggle(cL, "No Recoil", "NoRecoil", 2, startWeaponMods, stopWeaponMods)
makeToggle(cL, "No Spread", "NoSpread", 3, startWeaponMods, stopWeaponMods)
makeToggle(cL, "Rapid Fire", "RapidFire", 4, startWeaponMods, stopWeaponMods)
makeToggle(cL, "Auto Weapon", "AutoWeapon", 5, enableAutoWeapon, disableAutoWeapon)
makeToggle(cL, "Instant Scope", "InstantScope", 6, startWeaponMods, stopWeaponMods)
makeToggle(cL, "Always Backstab", "AlwaysBackstab", 7, nil, nil)
makeToggle(cL, "Anti Katana", "AntiKatana", 8, enableAntiKatana, disableAntiKatana)
makeHeader(cR, "Silent Aim", 1)
makeButton(cR, "⚡ Load Bolts Silent Aim", 2, function(btn, bs)
    btn.Text = "⏳ Loading..."
    btn.TextColor3 = C.dim
    local ok = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ThunderScriptSolutions/Misc/refs/heads/main/RivalsSilentAim"))()
    end)
    if ok then
        btn.Text = "✓ Loaded!"
        btn.TextColor3 = Color3.fromRGB(0, 255, 100)
        bs.Color = Color3.fromRGB(0, 255, 100)
    else
        btn.Text = "✗ Failed"
        btn.TextColor3 = C.red
        bs.Color = C.red
    end
end)
makeHeader(cR, "Utility", 4)
makeToggle(cR, "Auto Drop Collector", "AutoDrop", 5, nil, nil)
makeHeader(cR, "Auto Farm", 6)
makeToggle(cR, "Auto Farm", "AutoFarm", 7, enableAutoFarm, disableAutoFarm)
makePicker(cR, 8)

local mL, mR = createTab("Movement", 2)
makeHeader(mL, "Actions", 1)
makeToggle(mL, "Jump Bug", "JumpBug", 2, enableJumpBug, disableJumpBug)
makeToggle(mL, "Auto Strafe", "AutoStrafe", 3, enableAutoStrafe, disableAutoStrafe)
makeHeader(mL, "Fly", 4)
makeToggle(mL, "Fly", "Fly", 5, enableFly, disableFly)
makeHeader(mL, "Misc", 6)
makeToggle(mL, "Noclip", "Noclip", 7, enableNoclip, disableNoclip)
makeToggle(mL, "Anti Aim", "AntiAim", 8, enableAntiAim, disableAntiAim)
makeToggle(mL, "Tornado Animation", "TornadoAnim", 9, enableTornadoAnim, disableTornadoAnim)
makeHeader(mL, "Strafe", 10)
makeSlider(mL, "Strafe Intensity", 11, 1, 100, 50, "StrafeIntensity", nil)
makeHeader(mR, "Speed & Jump", 1)
makeSlider(mR, "Walk Speed", 2, 1, 150, 16, "WalkSpeed", function(v)
    local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = v end
end)
makeSlider(mR, "Jump Power", 3, 1, 200, 50, "JumpPower", function(v)
    local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
    if hum then hum.JumpPower = v end
end)
makeHeader(mR, "Fly Speed", 5)
makeSlider(mR, "Fly Speed", 6, 0, 1000, 50, "FlySpeed", nil)

local vL, vR = createTab("Visuals", 3)
makeHeader(vL, "Players", 1)
makeToggle(vL, "ESP", "ESP", 2, nil, nil)
makeToggle(vL, "Third Person", "ThirdPerson", 3, enableThirdPerson, disableThirdPerson)
makeHeader(vL, "Hit Notification", 4)
makeToggle(vL, "Hit Notification", "HitNotif", 5, nil, nil)

local wL, wR = createTab("World", 4)
makeHeader(wL, "Protection", 1)
makeToggle(wL, "Prevent OOB", "NoBounds", 2, nil, nil)
makeToggle(wL, "Remove Killers", "RemoveKillers", 3, nil, nil)
makeToggle(wL, "No Fire Damage", "NoFireDamage", 4, nil, nil)
makeToggle(wL, "Anti Freeze", "AntiFreeze", 5, nil, nil)

local uL, uR = createTab("Unlock", 5)
makeHeader(uL, "Cosmetic Unlocker", 1)
makeButton(uL, "🔓 Unlock All Cosmetics", 2, function(btn, bs)
    btn.Text = "⏳ Unlocking..."
    task.spawn(function()
        pcall(UnlockAll)
        btn.Text = "✅ Unlocked!"
        bs.Color = Color3.fromRGB(0, 255, 0)
        task.delay(2, function()
            btn.Text = "🔓 Unlock All Cosmetics"
            bs.Color = C.neon
        end)
    end)
end)
makeHeader(uL, "Status", 3)
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 40)
statusLabel.Position = UDim2.new(0, 10, 0, 120)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Anti-kick active.\nPress the button above to unlock all cosmetics."
statusLabel.TextColor3 = C.dim
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextWrapped = true
statusLabel.Parent = uL

switchTab("Combat")

task.spawn(function()
    task.wait(0.1)
    TweenService:Create(root, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
    TweenService:Create(rootStroke, TweenInfo.new(0.4), {Transparency = 0}):Play()
end)

do
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = root.Position
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

print("Cyber Dragon – Hit on every shot. Press RightShift to open.")
