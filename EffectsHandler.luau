--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CameraShaker = require(script:WaitForChild("CameraShaker"))

local ure_Effects = ReplicatedStorage:WaitForChild("Effects")
local camera = workspace.CurrentCamera :: Camera
local char = script.Parent
local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
local earRing = script:WaitForChild("EarRing")

local camShake
local function cameraShake()
    camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value + 1, function(shakeCF)
        camera.CFrame *= shakeCF
    end)
    
    camShake:Start()
    camShake:ShakeSustain(CameraShaker.Presets.Bump)
end

local conn: RBXScriptConnection
ure_Effects.OnClientEvent:Connect(function(action: string, pos: Vector3?, effectDist: number?)
    if action == "A10_Start" and pos and effectDist then
        conn = RunService.PreRender:Connect(function(dt)
            local dist = (pos - hrp.Position).Magnitude
            if dist <= effectDist then
                cameraShake()
                earRing:Play()
                conn:Disconnect()
            end
        end)
    elseif action == "A10_End" then
        if conn then
            conn:Disconnect()
        end
        
        if camShake then
            camShake:StopSustained()
        end
    end
end)
