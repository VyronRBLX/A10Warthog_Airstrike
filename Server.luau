--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local A10WStorage = ReplicatedStorage.A10W
local A10 = A10WStorage.A10
local trail = A10WStorage.Trail
local bulletHole = A10WStorage.BulletHole
local tool = script.Parent
local re_Fire = tool.Fire
local ure_Effects = ReplicatedStorage.Effects
local canFire = tool.CanFire
local toolName = tool.Name
local fireSounds = script.FireSounds
local echo = fireSounds.Echo
local fire = fireSounds.Fire
local fire2 = fireSounds.Fire2
local goreSounds = script.GoreSounds
local bulletHoles = {"123626001036905", "6552016346", "17875410792"}
local whizzSounds = {"342190005", "342190012", "342190017", "342190024"}

-- //SETTINGS
local UP_SPEED = 2
local COOLDOWN = 10
local RPM = 4200
local DAMAGE = 80
local EFFECTS_DISTANCE = 100 -- Distance to the airstrike where the player will recieve effects (camera shake, SFX)
local SPAWN_DISTANCE = 2500
local SPAWN_HEIGHT = 1500
local BULLET_DESPAWN_TIME = 15

local function playVFX(parent: Instance)
	for _, vfx in parent:QueryDescendants("ParticleEmitter") do
        if vfx:IsA("ParticleEmitter") then
			local amount = vfx:FindFirstChildOfClass("IntValue")
			vfx:Emit(if amount then amount.Value else 1)
		end
	end
end

local function breakJoints(char: Model)
    for _, v in char:GetDescendants() do
        if not 
            (v:IsA("JointInstance")
                or v:IsA("Weld")
                or v:IsA("WeldConstraint"))
        then
            continue
        end
        v:Destroy()
    end
end

local function explosion(char: Model)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        return
    end
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    breakJoints(char)

    -- Apply forces in random directions
    for _, v in char:GetChildren() do
        if not v:IsA("BasePart") then
            continue
        end
        v:ApplyImpulse(Vector3.new(math.random(-75, 75), math.random(20, 100), math.random(-75, 75)))
    end
end

local function playGoreSound(char: Model)
    if not Players:GetPlayerFromCharacter(char) then
        return
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end
    local sounds = goreSounds:GetChildren() :: { Sound }
    local goreSound = sounds[Random.new():NextInteger(1, #sounds)]
    goreSound.Parent = hrp
    goreSound:Play()
    goreSound.Ended:Wait()
    if goreSound then
        goreSound:Destroy()
    end
end

local function toolDisplayCountdown()
    for i = COOLDOWN, 0, -1 do
        tool.Name = tostring(i)
        task.wait(1)
    end
    tool.Name = toolName
    canFire.Value = true
end

local function airstrike(plr: Player, pos: Vector3, jetLook: Vector3)
	if not canFire.Value then
		return
	end
	
	canFire.Value = false
	task.defer(toolDisplayCountdown)
	
	-- MAIN
    local newJet = A10:Clone()
    task.delay(40, newJet.Destroy, newJet)
	local vel = newJet:WaitForChild("Vel")
	local a10Fly = vel:WaitForChild("A10")
	local engine = vel:WaitForChild("Engine")
    local G8A = newJet:WaitForChild("G8A")
    local deadChars: { Model } = {}
    
    -- Positioning
    local spawnPos = pos + (-jetLook * SPAWN_DISTANCE) + Vector3.new(0, SPAWN_HEIGHT, 0)
    newJet:PivotTo(CFrame.new(spawnPos))
    newJet.Parent = workspace
    task.wait()
    vel.CFrame = CFrame.lookAt(vel.Position, pos)
    
    local att0 = Instance.new("Attachment")
    att0.Parent = vel
    att0.WorldPosition = vel.Position

    local linearVelocity = Instance.new("LinearVelocity")
    linearVelocity.Parent = vel
    linearVelocity.ForceLimitsEnabled = true
    linearVelocity.MaxForce = 1250
    linearVelocity.Attachment0 = att0
    linearVelocity.VectorVelocity = Vector3.new(0, 2, 0)
    
	a10Fly:Play()
	engine:Play()
	
	-- Velocity handler
	local velocity = 300
	task.defer(function()
		while newJet.Parent do
			linearVelocity.VectorVelocity = vel.CFrame.LookVector * velocity
            task.wait()
		end
	end)
	task.wait(7)
	velocity = 200
	
	-- Shoot
	local fireSound = (if Random.new():NextInteger(1, 2) == 1 then fire else fire2):Clone()
	fireSound:Play()
	fireSound.Parent = workspace
	task.delay(5, fireSound.Destroy, fireSound)
	
	local shootingDuration = fireSound.TimeLength / 2
	local shooting = true
	local cooldown = 60 / RPM
	
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
    params.FilterDescendantsInstances = { newJet }
    
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = { newJet }
    
    local function createBulletHole(result: RaycastResult)
        local random = Random.new()
        local img = bulletHoles[random:NextInteger(1, #bulletHoles)]
        local whizz = whizzSounds[random:NextInteger(1, #whizzSounds)]
        
        local bulletHoleClone = bulletHole:Clone()
        local smoke = bulletHoleClone:WaitForChild("ParticleEmitter")
        local holeDecal = bulletHoleClone:WaitForChild("Decal") :: Decal
        holeDecal.Texture = `rbxassetid://{img}`
        bulletHoleClone.CFrame = CFrame.lookAt(result.Position, result.Position + result.Normal)
        bulletHoleClone.Parent = workspace
        task.delay(BULLET_DESPAWN_TIME, bulletHoleClone.Destroy, bulletHoleClone)
        
        playVFX(bulletHoleClone)
        
        local whizzSound = Instance.new("Sound")
        whizzSound.SoundId = `rbxassetid://{whizz}`
        whizzSound.Parent = bulletHoleClone
        whizzSound:Play()
        
        -- Hitbox
        local size = bulletHoleClone.Size * 3
        local cf = bulletHoleClone.CFrame + Vector3.new(0, size.Y / 2, 0)
        local parts = workspace:GetPartBoundsInBox(cf, size, overlapParams)
        for _, part in parts do
            local char = part.Parent :: Model
            local plr = Players:GetPlayerFromCharacter(char)
            if not plr then
                return
            end
            if table.find(deadChars, char) then
                return
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then
                return
            end
            hum:TakeDamage(DAMAGE)
            task.defer(playGoreSound, char)
            
            if hum.Health <= 0 then
                table.insert(deadChars, char)
                explosion(char)
            end
        end
    end
    
    local function shoot()
        local trailClone = trail:Clone()
        trailClone.Position = pos
        trailClone.Parent = workspace
        task.delay(0.1, trailClone.Destroy , trailClone)

        local a0, a1 = trailClone:WaitForChild("Attachment"), trailClone:WaitForChild("Attachment2")
        a0.WorldPosition = G8A.Position
        playVFX(G8A)

        -- Shoot
        local random = Random.new()
        local randomPos = pos + Vector3.new( random:NextInteger(0, 25), random:NextInteger(0, 25), random:NextInteger(0, 25))
        local origin = vel.Position
        local dir = (randomPos - origin).Unit * 1500
        local result = workspace:Raycast(origin, dir, params)

        -- Make bullet trail
        a1.WorldPosition = if result then result.Position else origin + dir
        if not result then
            return
        end
        
        createBulletHole(result)
    end
    
    local function startShooting()
        ure_Effects:FireAllClients("A10_Start", pos, EFFECTS_DISTANCE)
		G8A.Muzzle.LightFlash.Enabled = true
        while shooting do
            task.defer(shoot)
			task.wait(cooldown)
		end
        G8A.Muzzle:Destroy()
	end
    task.defer(startShooting)
    
    -- Flies the jet back up
    local function flyUp()
        local _, yaw, _ = vel.CFrame:ToEulerAnglesYXZ()
        local goalCF = CFrame.Angles(0, yaw, 0)
        local startCF = vel.CFrame
        local alpha = 0
        local conn: RBXScriptConnection
        conn = RunService.PostSimulation:Connect(function(dt)
            alpha += dt * UP_SPEED
            alpha = math.clamp(alpha, 0, 1)

            local currentRotation = startCF:Lerp(CFrame.new(startCF.Position) * goalCF, alpha)
            vel.CFrame = CFrame.new(vel.Position) * currentRotation.Rotation

            if alpha >= 1 then
                conn:Disconnect()
            end
        end)
    end
    
    task.wait((shootingDuration/4) * 3) -- 3/4 of the way through play the echo sound
    local echoClone = echo:Clone()
    echoClone:Play()
    echoClone.Parent = workspace
    echoClone.Ended:Connect(function()
        echoClone:Destroy()
    end)
    
    task.wait(shootingDuration/4)
    
    -- End
	shooting = false
    flyUp()
    task.wait(2)
    ure_Effects:FireAllClients("A10_End", pos, EFFECTS_DISTANCE)
    velocity = 300
end

re_Fire.OnServerEvent:Connect(airstrike)
