--[[
    SCENEPRINT
    Part-based terrain sculpting study for Roblox Studio.
    Handle: ruancr
    Version: 0.1.0
]]

assert(plugin, "Execute este código como um plugin do Roblox Studio.")

local Workspace = game:GetService("Workspace")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local CELL_SIZE = 4
local GRID_SIZE = 16
local MIN_HEIGHT, MAX_HEIGHT = 1.5, 32
local RAISE_STEP = 2.4
local SMOOTH_STRENGTH = 0.55

local T = {
    bg = Color3.fromRGB(13, 13, 16),
    surface = Color3.fromRGB(23, 23, 27),
    text = Color3.fromRGB(239, 238, 244),
    muted = Color3.fromRGB(137, 135, 148),
    line = Color3.fromRGB(46, 45, 53),
    purple = Color3.fromRGB(175, 157, 255),
    purpleDark = Color3.fromRGB(45, 39, 65),
}

local toolbar = plugin:CreateToolbar("Sceneprint")
local toolbarButton = toolbar:CreateButton("Sceneprint", "Abrir Sceneprint", "")
toolbarButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 320, 460, 280, 420)
local widget = plugin:CreateDockWidgetPluginGuiAsync("Sceneprint.Main", widgetInfo)
widget.Title = "Sceneprint"

local function make(className, parent, properties)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function label(parent, text, position, size, fontSize, color, font)
    return make("TextLabel", parent, {
        BackgroundTransparency = 1,
        Position = position,
        Size = size,
        Font = font or Enum.Font.Gotham,
        Text = text,
        TextColor3 = color or T.text,
        TextSize = fontSize or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end

local function button(parent, text, position, size, selected)
    local object = make("TextButton", parent, {
        Position = position,
        Size = size,
        BackgroundColor3 = selected and T.purpleDark or T.surface,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = selected and T.purple or T.muted,
        TextSize = 10,
    })
    make("UICorner", object, { CornerRadius = UDim.new(0, 6) })
    return object
end

local root = make("Frame", widget, {
    Name = "SceneprintRoot",
    BackgroundColor3 = T.bg,
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
})

local mark = make("Frame", root, {
    Position = UDim2.fromOffset(18, 16),
    Size = UDim2.fromOffset(28, 28),
    BackgroundColor3 = T.purpleDark,
    BorderSizePixel = 0,
})
make("UICorner", mark, { CornerRadius = UDim.new(0, 7) })
local markLabel = label(mark, "S", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 16, T.purple, Enum.Font.GothamBold)
markLabel.TextXAlignment = Enum.TextXAlignment.Center

label(root, "sceneprint", UDim2.fromOffset(56, 12), UDim2.new(1, -76, 0, 20), 16, T.text, Enum.Font.GothamBold)
label(root, "ruancr", UDim2.fromOffset(57, 31), UDim2.new(1, -76, 0, 14), 9, T.muted, Enum.Font.GothamMedium)
local dev = label(root, "EM DESENVOLVIMENTO", UDim2.new(1, -130, 0, 20), UDim2.fromOffset(112, 14), 8, T.purple, Enum.Font.GothamBold)
dev.TextXAlignment = Enum.TextXAlignment.Right

make("Frame", root, {
    Position = UDim2.fromOffset(18, 56),
    Size = UDim2.new(1, -36, 0, 1),
    BackgroundColor3 = T.line,
    BorderSizePixel = 0,
})

label(root, "Terreno esculpido com Parts.", UDim2.fromOffset(18, 69), UDim2.new(1, -36, 0, 20), 12, T.text, Enum.Font.GothamMedium)
label(root, "Sem usar o sistema Terrain do Roblox.", UDim2.fromOffset(18, 89), UDim2.new(1, -36, 0, 16), 10, T.muted)

local baseButton = button(root, "CRIAR BASE 16 x 16", UDim2.fromOffset(18, 121), UDim2.new(1, -36, 0, 36), true)
label(root, "ESCULPIR", UDim2.fromOffset(18, 177), UDim2.new(1, -36, 0, 16), 9, T.muted, Enum.Font.GothamBold)

local modes = {}
modes.raise = button(root, "SUBIR", UDim2.fromOffset(18, 201), UDim2.fromOffset(84, 32), false)
modes.lower = button(root, "BAIXAR", UDim2.fromOffset(108, 201), UDim2.fromOffset(84, 32), false)
modes.smooth = button(root, "SUAVIZAR", UDim2.fromOffset(198, 201), UDim2.fromOffset(92, 32), false)

label(root, "RAIO DO PINCEL", UDim2.fromOffset(18, 255), UDim2.fromOffset(112, 18), 9, T.muted, Enum.Font.GothamBold)
local radius = 3
local radiusLabel = label(root, tostring(radius), UDim2.new(1, -90, 0, 255), UDim2.fromOffset(24, 18), 11, T.text, Enum.Font.GothamBold)
radiusLabel.TextXAlignment = Enum.TextXAlignment.Center
local minusButton = button(root, "−", UDim2.new(1, -60, 0, 251), UDim2.fromOffset(28, 26), false)
local plusButton = button(root, "+", UDim2.new(1, -28, 0, 251), UDim2.fromOffset(28, 26), false)
local stopButton = button(root, "PARAR FERRAMENTA", UDim2.fromOffset(18, 294), UDim2.new(1, -36, 0, 30), false)

local status = label(root, "Crie uma base sobre a face superior de uma peça.", UDim2.fromOffset(18, 340), UDim2.new(1, -36, 0, 45), 10, T.muted)
status.TextWrapped = true
status.TextYAlignment = Enum.TextYAlignment.Top

make("Frame", root, {
    Position = UDim2.new(0, 18, 1, -25),
    Size = UDim2.new(1, -36, 0, 1),
    BackgroundColor3 = T.line,
    BorderSizePixel = 0,
})
label(root, "PARTS ONLY  /  ruancr", UDim2.new(0, 18, 1, -20), UDim2.new(1, -36, 0, 12), 8, T.muted, Enum.Font.GothamMedium)

local activeMode = nil
local active = false
local mouse = nil
local connections = {}
local cachedPatches = {}
local brushPreview = nil

local function setStatus(text)
    status.Text = text
end

local function refreshButtons()
    for mode, control in pairs(modes) do
        local selected = active and activeMode == mode
        control.BackgroundColor3 = selected and T.purpleDark or T.surface
        control.TextColor3 = selected and T.purple or T.muted
    end
    local selected = active and activeMode == "place"
    baseButton.BackgroundColor3 = selected and T.purpleDark or T.surface
    baseButton.TextColor3 = selected and T.purple or T.muted
    baseButton.Text = selected and "CLIQUE NO MAPA..." or "CRIAR BASE 16 x 16"
end

local function getTerrainFolder()
    local folder = Workspace:FindFirstChild("Sceneprint_Terrain")
    if folder and folder:IsA("Folder") then
        return folder
    end
    return nil
end

local function makePatchFolder()
    local folder = getTerrainFolder()
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "Sceneprint_Terrain"
        folder.Parent = Workspace
    end
    return folder
end

local function key(x, z)
    return tostring(x) .. ":" .. tostring(z)
end

local function patchFromCell(cell)
    local current = cell
    while current and current ~= Workspace do
        if current:GetAttribute("SceneprintPatch") == true then
            if cachedPatches[current] then
                return cachedPatches[current]
            end

            local state = {
                folder = current,
                bottomY = current:GetAttribute("BottomY") or 0,
                cellSize = current:GetAttribute("CellSize") or CELL_SIZE,
                cells = {},
            }

            for _, child in ipairs(current:GetChildren()) do
                if child:IsA("BasePart") and child:GetAttribute("SceneprintCell") == true then
                    state.cells[key(child:GetAttribute("GridX"), child:GetAttribute("GridZ"))] = child
                end
            end

            cachedPatches[current] = state
            return state
        end
        current = current.Parent
    end
    return nil
end

local function getCell(state, x, z)
    local cell = state.cells[key(x, z)]
    if cell and cell.Parent then
        return cell
    end
    return nil
end

local function record(name, displayName, callback)
    local ok, id = pcall(function()
        return ChangeHistoryService:TryBeginRecording(name, displayName)
    end)

    if not ok or not id then
        setStatus("O Studio não iniciou o registro de desfazer.")
        return false
    end

    local success, result = pcall(callback)

    if success then
        pcall(function()
            ChangeHistoryService:FinishRecording(id, Enum.FinishRecordingOperation.Commit)
        end)
        return true, result
    end

    pcall(function()
        ChangeHistoryService:FinishRecording(id, Enum.FinishRecordingOperation.Cancel)
    end)
    setStatus("A ação foi cancelada: " .. tostring(result))
    return false
end

local function createPatch(target, hitPosition)
    if not target or not target:IsA("BasePart") then
        setStatus("Clique na parte de cima de uma peça existente.")
        return
    end

    if target:GetAttribute("SceneprintCell") == true then
        setStatus("Apoie a base em uma peça normal, não em outro tile.")
        return
    end

    if mouse.TargetSurface ~= Enum.NormalId.Top then
        setStatus("Apoie a base na face superior de uma peça.")
        return
    end

    local success, patch = record("Sceneprint_CreatePatch", "Sceneprint: criar base", function()
        local holder = makePatchFolder()
        local folder = Instance.new("Folder")
        folder.Name = "Patch_" .. string.format("%02d", #holder:GetChildren() + 1)

        local bottomY = target.Position.Y + target.Size.Y / 2
        local centerX = math.floor(hitPosition.X / CELL_SIZE + 0.5) * CELL_SIZE
        local centerZ = math.floor(hitPosition.Z / CELL_SIZE + 0.5) * CELL_SIZE
        local originX = centerX - ((GRID_SIZE - 1) * CELL_SIZE) / 2
        local originZ = centerZ - ((GRID_SIZE - 1) * CELL_SIZE) / 2

        folder:SetAttribute("SceneprintPatch", true)
        folder:SetAttribute("BottomY", bottomY)
        folder:SetAttribute("CellSize", CELL_SIZE)
        folder:SetAttribute("GridSize", GRID_SIZE)
        folder.Parent = holder

        local state = { folder = folder, bottomY = bottomY, cellSize = CELL_SIZE, cells = {} }
        local baseColor = Color3.fromRGB(101, 119, 86)

        for z = 1, GRID_SIZE do
            for x = 1, GRID_SIZE do
                local shade = math.sin(x * 12.9898 + z * 78.233) * 0.025
                local cell = Instance.new("Part")
                cell.Name = string.format("Cell_%02d_%02d", x, z)
                cell.Anchored = true
                cell.CanCollide = true
                cell.CanTouch = false
                cell.TopSurface = Enum.SurfaceType.Smooth
                cell.BottomSurface = Enum.SurfaceType.Smooth
                cell.Material = Enum.Material.Grass
                cell.Color = Color3.new(
                    math.clamp(baseColor.R + shade, 0, 1),
                    math.clamp(baseColor.G + shade, 0, 1),
                    math.clamp(baseColor.B + shade, 0, 1)
                )
                cell.Size = Vector3.new(CELL_SIZE, 4, CELL_SIZE)
                cell.Position = Vector3.new(
                    originX + (x - 1) * CELL_SIZE,
                    bottomY + 2,
                    originZ + (z - 1) * CELL_SIZE
                )
                cell:SetAttribute("SceneprintCell", true)
                cell:SetAttribute("GridX", x)
                cell:SetAttribute("GridZ", z)
                cell.Parent = folder
                state.cells[key(x, z)] = cell
            end
        end

        cachedPatches[folder] = state
        return folder
    end)

    if success then
        setStatus("Base criada. Escolha SUBIR, BAIXAR ou SUAVIZAR.")
    end
end

local function brushWeight(distance)
    return math.clamp(1 - distance / (radius + 0.75), 0, 1)
end

local function sculpt(cell, mode)
    if not cell or cell:GetAttribute("SceneprintCell") ~= true then
        setStatus("Clique em um tile criado pelo Sceneprint.")
        return
    end

    local state = patchFromCell(cell)
    if not state then
        setStatus("Não encontrei a base deste tile.")
        return
    end

    local centerX = cell:GetAttribute("GridX")
    local centerZ = cell:GetAttribute("GridZ")
    if typeof(centerX) ~= "number" or typeof(centerZ) ~= "number" then
        return
    end

    local changes = {}

    for dz = -radius, radius do
        for dx = -radius, radius do
            local distance = math.sqrt(dx * dx + dz * dz)
            if distance <= radius + 0.25 then
                local part = getCell(state, centerX + dx, centerZ + dz)
                if part then
                    local oldHeight = part.Size.Y
                    local weight = brushWeight(distance)
                    local newHeight = oldHeight

                    if mode == "raise" then
                        newHeight = math.min(MAX_HEIGHT, oldHeight + RAISE_STEP * weight)
                    elseif mode == "lower" then
                        newHeight = math.max(MIN_HEIGHT, oldHeight - RAISE_STEP * weight)
                    elseif mode == "smooth" then
                        local sum, count = 0, 0
                        for nz = -1, 1 do
                            for nx = -1, 1 do
                                local neighbor = getCell(state, centerX + dx + nx, centerZ + dz + nz)
                                if neighbor then
                                    sum += neighbor.Size.Y
                                    count += 1
                                end
                            end
                        end
                        if count > 0 then
                            local average = sum / count
                            newHeight = oldHeight + (average - oldHeight) * SMOOTH_STRENGTH * weight
                        end
                    end

                    newHeight = math.clamp(newHeight, MIN_HEIGHT, MAX_HEIGHT)
                    if math.abs(newHeight - oldHeight) > 0.001 then
                        table.insert(changes, { part = part, height = newHeight })
                    end
                end
            end
        end
    end

    if #changes == 0 then
        setStatus("Nada para alterar neste ponto.")
        return
    end

    local success = record("Sceneprint_Sculpt", "Sceneprint: " .. mode, function()
        for _, change in ipairs(changes) do
            local part = change.part
            part.Size = Vector3.new(state.cellSize, change.height, state.cellSize)
            part.Position = Vector3.new(
                part.Position.X,
                state.bottomY + change.height / 2,
                part.Position.Z
            )
            part:SetAttribute("Height", change.height)
        end
    end)

    if success then
        setStatus(string.format("%d tiles ajustados.", #changes))
    end
end

local function removePreview()
    if brushPreview then
        brushPreview.Parent = nil
    end
end

local function updatePreview()
    if not active or not activeMode or activeMode == "place" or not mouse then
        removePreview()
        return
    end

    local target = mouse.Target
    if not target or target:GetAttribute("SceneprintCell") ~= true then
        removePreview()
        return
    end

    local state = patchFromCell(target)
    if not state then
        removePreview()
        return
    end

    if not brushPreview then
        brushPreview = Instance.new("Part")
        brushPreview.Name = "SceneprintBrushPreview"
        brushPreview.Shape = Enum.PartType.Cylinder
        brushPreview.Anchored = true
        brushPreview.CanCollide = false
        brushPreview.CanTouch = false
        brushPreview.CanQuery = false
        brushPreview.CastShadow = false
        brushPreview.Material = Enum.Material.SmoothPlastic
        brushPreview.Color = T.purple
        brushPreview.Transparency = 0.82
    end

    local diameter = (radius * 2 + 1) * state.cellSize
    brushPreview.Size = Vector3.new(0.06, diameter, diameter)
    brushPreview.CFrame = CFrame.new(
        target.Position.X,
        target.Position.Y + target.Size.Y / 2 + 0.045,
        target.Position.Z
    ) * CFrame.Angles(0, 0, math.rad(90))
    brushPreview.Parent = Workspace
end

local function stopTool()
    active = false
    activeMode = nil
    removePreview()
    refreshButtons()
    pcall(function()
        plugin:Deactivate()
    end)
end

local function onClick()
    if not active or not mouse then
        return
    end

    local target = mouse.Target
    if activeMode == "place" then
        if target then
            createPatch(target, mouse.Hit.Position)
            stopTool()
        else
            setStatus("Clique na face superior de uma peça.")
        end
    elseif activeMode then
        sculpt(target, activeMode)
        updatePreview()
    end
end

local function activate(mode)
    if not active then
        plugin:Activate(true)
        mouse = plugin:GetMouse()

        if #connections == 0 then
            table.insert(connections, mouse.Button1Down:Connect(onClick))
            table.insert(connections, mouse.Move:Connect(updatePreview))
        end
    end

    active = true
    activeMode = mode
    refreshButtons()

    if mode == "place" then
        setStatus("Clique na face de cima de uma peça para apoiar a base.")
        removePreview()
    else
        setStatus("Clique nos tiles para esculpir. Use PARAR para sair.")
        updatePreview()
    end
end

baseButton.Activated:Connect(function()
    activate("place")
end)

for mode, control in pairs(modes) do
    control.Activated:Connect(function()
        activate(mode)
    end)
end

minusButton.Activated:Connect(function()
    radius = math.max(1, radius - 1)
    radiusLabel.Text = tostring(radius)
    updatePreview()
end)

plusButton.Activated:Connect(function()
    radius = math.min(6, radius + 1)
    radiusLabel.Text = tostring(radius)
    updatePreview()
end)

stopButton.Activated:Connect(function()
    stopTool()
    setStatus("Ferramenta parada.")
end)

plugin.Deactivation:Connect(function()
    active = false
    activeMode = nil
    removePreview()
    refreshButtons()
end)

plugin.Unloading:Connect(function()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    if brushPreview then
        brushPreview:Destroy()
        brushPreview = nil
    end
end)

toolbarButton.Click:Connect(function()
    widget.Enabled = not widget.Enabled
end)

radiusLabel.Text = tostring(radius)
refreshButtons()
