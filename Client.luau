local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local _plr = Players.LocalPlayer
local tool = script.Parent
local re_Fire = tool:WaitForChild("Fire")
local handle = tool:WaitForChild("Handle")
local call = handle:WaitForChild("Call")
local equip = handle:WaitForChild("EquipSound")
local targetMark = script:WaitForChild("TargetMark")
local directionArrow = targetMark:WaitForChild("DirectionArrow"):WaitForChild("Part")

local canFire = tool:WaitForChild("CanFire")

local mouse = _plr:GetMouse()
local conns = {}
local equipped = false
local marking = false

mouse.TargetFilter = targetMark

local function showMark(bool: boolean)
    for _, v in targetMark:GetChildren() do
        if v:IsA("BasePart") then
            v.Transparency = if bool then 0.3 else 1
        end
    end
    targetMark.Parent = if bool then workspace else script
end

local function disconnectAll()
    for _, conn in conns do
        conn:Disconnect()
    end
end

local function fire(pos: Vector3, dir: Vector3, cf: CFrame)
    marking = false
    disconnectAll()
    showMark(false)
    call:Play()
    re_Fire:FireServer(pos, dir, cf)
end

local function setup()
    if marking then
        return
    end
    
    marking = true
    showMark(true)
    local locked = false
    local arrowGoal: CFrame, markGoal: CFrame
    table.insert(conns, RunService.PreRender:Connect(function(dt)
        if not mouse.Target then
            return showMark(false)
        end
        
        local hit = mouse.Hit
        local dist = (hit.Position - directionArrow.Position).Magnitude
        if dist > 1000 and not locked then
            return showMark(false)
        end
        if dist < 2 then
            return
        end
        
        showMark(true)
        if locked then
            local mousePos = Vector3.new(hit.Position.X, 0, hit.Position.Z)
            local goal = CFrame.lookAt(directionArrow.Position, mousePos, Vector3.yAxis)
            directionArrow.CFrame = directionArrow.CFrame:Lerp(goal, 10 * dt)
        else
            local goal = CFrame.new(hit.Position)
            targetMark:PivotTo(targetMark:GetPivot():Lerp(goal, 10 * dt))
        end
    end))
    
    table.insert(conns, tool.Activated:Connect(function()
        if not locked then
            locked = true
            return
        end
        
        -- Fire when direction and position are locked
        fire(targetMark:GetPivot().Position, directionArrow.CFrame.LookVector, directionArrow.CFrame)
    end))
end

tool.Equipped:Connect(function()
    equip:Play()
    equipped = true
    if not canFire.Value then
        return
    end
    setup()
end)

tool.Unequipped:Connect(function()
    equipped = false
    if marking then
        marking = false
        showMark(false)
        disconnectAll()
    end
end)

canFire.Changed:Connect(function(value)
    if value and equipped then
        setup()
    end
end)
