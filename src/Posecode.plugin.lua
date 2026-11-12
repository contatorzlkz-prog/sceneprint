--[[
    POSECODE
    Convert structured animation data into Roblox animation clips.
    Handle: ruancr
    Version: 1.3
    The plugin never executes pasted source; it only extracts and validates JSON.
]]

assert(plugin, "Abra este arquivo como um plugin do Roblox Studio.")

local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local AnimationClipProvider = game:GetService("AnimationClipProvider")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local VERSION = "1.3"
local MAX_FRAMES = 120
local MAX_DURATION = 15
local MAX_SOURCE_LENGTH = 262144
local MAX_TRANSFORM_OFFSET = 5
local MAX_ROTATION = 720

local C = {
    background = Color3.fromRGB(13, 13, 16),
    panel = Color3.fromRGB(20, 20, 25),
    field = Color3.fromRGB(16, 16, 20),
    surface = Color3.fromRGB(28, 27, 34),
    line = Color3.fromRGB(48, 46, 57),
    text = Color3.fromRGB(239, 237, 245),
    muted = Color3.fromRGB(137, 133, 148),
    accent = Color3.fromRGB(179, 160, 255),
    accentDark = Color3.fromRGB(47, 40, 67),
    green = Color3.fromRGB(148, 194, 158),
    red = Color3.fromRGB(220, 135, 135),
}

local toolbar = plugin:CreateToolbar("POSECODE")
local toolbarButton = toolbar:CreateButton("POSECODE", "Abrir POSECODE", "")
toolbarButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Right,
    false,
    false,
    410,
    650,
    330,
    420
)

local widget = plugin:CreateDockWidgetPluginGuiAsync("Posecode.Main", widgetInfo)
widget.Title = "POSECODE"

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
        TextColor3 = color or C.text,
        TextSize = fontSize or 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end

local function button(parent, text, position, size, primary)
    local normalColor = primary and C.accent or C.surface
    local hoverColor = primary and Color3.fromRGB(198, 184, 255) or Color3.fromRGB(39, 37, 47)
    local object = make("TextButton", parent, {
        Position = position,
        Size = size,
        BackgroundColor3 = normalColor,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = text,
        TextColor3 = primary and C.background or C.text,
        TextSize = 10,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    make("UICorner", object, { CornerRadius = UDim.new(0, 5) })
    object.MouseEnter:Connect(function()
        TweenService:Create(object, TweenInfo.new(0.12), { BackgroundColor3 = hoverColor }):Play()
    end)
    object.MouseLeave:Connect(function()
        TweenService:Create(object, TweenInfo.new(0.12), { BackgroundColor3 = normalColor }):Play()
    end)
    return object
end

local root = make("Frame", widget, {
    Name = "PosecodeRoot",
    BackgroundColor3 = C.background,
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
})

local header = make("Frame", root, {
    Name = "Header",
    BackgroundColor3 = C.background,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 58),
})

local headerMark = make("Frame", header, {
    Position = UDim2.fromOffset(14, 13),
    Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = C.accentDark,
    BorderSizePixel = 0,
})
make("UICorner", headerMark, { CornerRadius = UDim.new(0, 6) })
make("Frame", headerMark, {
    Position = UDim2.fromOffset(6, 15),
    Size = UDim2.fromOffset(4, 8),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
})
make("Frame", headerMark, {
    Position = UDim2.fromOffset(13, 9),
    Size = UDim2.fromOffset(4, 14),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
})
make("Frame", headerMark, {
    Position = UDim2.fromOffset(20, 5),
    Size = UDim2.fromOffset(4, 18),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
})

label(header, "POSECODE", UDim2.fromOffset(54, 11), UDim2.new(1, -142, 0, 21), 15, C.text, Enum.Font.GothamBold)
label(header, "ANIMATION WORKSPACE", UDim2.fromOffset(55, 31), UDim2.new(1, -142, 0, 12), 8, C.muted, Enum.Font.GothamMedium)

local versionChip = make("Frame", header, {
    Position = UDim2.new(1, -62, 0, 19),
    Size = UDim2.fromOffset(46, 22),
    BackgroundColor3 = C.surface,
    BorderSizePixel = 0,
})
make("UICorner", versionChip, { CornerRadius = UDim.new(0, 5) })
local versionLabel = label(versionChip, "v" .. VERSION, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 9, C.accent, Enum.Font.GothamBold)
versionLabel.TextXAlignment = Enum.TextXAlignment.Center

make("Frame", root, {
    Position = UDim2.fromOffset(14, 57),
    Size = UDim2.new(1, -28, 0, 1),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
})

local scroll = make("ScrollingFrame", root, {
    Name = "ContentScroll",
    Position = UDim2.fromOffset(0, 62),
    Size = UDim2.new(1, 0, 1, -62),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.fromOffset(0, 590),
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.accent,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    Active = true,
})
local content = make("Frame", scroll, {
    Name = "Content",
    Position = UDim2.fromOffset(14, 0),
    Size = UDim2.new(1, -28, 0, 590),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
})

label(content, "01  /  SOURCE", UDim2.fromOffset(0, 7), UDim2.new(1, 0, 0, 15), 9, C.muted, Enum.Font.GothamBold)
label(content, "POSECODE ou JSON estruturado", UDim2.fromOffset(0, 23), UDim2.new(1, 0, 0, 14), 10, C.text)

local sourceBox = make("TextBox", content, {
    Position = UDim2.fromOffset(0, 43),
    Size = UDim2.new(1, 0, 0, 124),
    BackgroundColor3 = C.field,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    Font = Enum.Font.Code,
    Text = "",
    PlaceholderText = '{ "format": "POSECODE", ... }',
    PlaceholderColor3 = C.muted,
    TextColor3 = C.text,
    TextSize = 10,
    TextWrapped = false,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    MultiLine = true,
})
make("UICorner", sourceBox, { CornerRadius = UDim.new(0, 5) })
make("UIStroke", sourceBox, {
    Color = C.line,
    Thickness = 1,
    Transparency = 0.2,
})
make("UIPadding", sourceBox, {
    PaddingTop = UDim.new(0, 9),
    PaddingBottom = UDim.new(0, 9),
    PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 10),
})

local importButton = button(content, "↓  IMPORTAR CLIP", UDim2.fromOffset(0, 176), UDim2.new(1, 0, 0, 34), true)
local exampleButton = button(content, "＋  EXEMPLO", UDim2.fromOffset(0, 218), UDim2.new(0.5, -5, 0, 28), false)
local clearButton = button(content, "×  LIMPAR", UDim2.new(0.5, 5, 0, 218), UDim2.new(0.5, -5, 0, 28), false)

local timelinePanel = make("Frame", content, {
    Name = "Timeline",
    Position = UDim2.fromOffset(0, 260),
    Size = UDim2.new(1, 0, 0, 76),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
})
label(timelinePanel, "02  /  TIMELINE", UDim2.fromOffset(0, 0), UDim2.new(0.38, 0, 0, 14), 9, C.muted, Enum.Font.GothamBold)
local timelineInfo = label(timelinePanel, "SEM DADOS", UDim2.new(0.38, 0, 0, 0), UDim2.new(0.62, 0, 0, 14), 8, C.muted, Enum.Font.GothamMedium)
timelineInfo.TextXAlignment = Enum.TextXAlignment.Right

local timelineTrack = make("Frame", timelinePanel, {
    Position = UDim2.fromOffset(0, 23),
    Size = UDim2.new(1, 0, 0, 24),
    BackgroundTransparency = 1,
})
make("Frame", timelineTrack, {
    Position = UDim2.new(0, 0, 0.5, -1),
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
    ZIndex = 1,
})
local timelineHitbox = make("TextButton", timelineTrack, {
    Name = "TimelineInput",
    Active = true,
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 4,
})
local timelineCursor = make("Frame", timelineTrack, {
    Name = "Playhead",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0, 0, 0.5, 0),
    Size = UDim2.fromOffset(2, 22),
    BackgroundColor3 = C.text,
    BorderSizePixel = 0,
    ZIndex = 5,
})
local timelineTime = label(timelinePanel, "00:00.00 / 00:00.00", UDim2.fromOffset(0, 52), UDim2.new(1, 0, 0, 14), 9, C.text, Enum.Font.Code)

local rigInfo = label(content, "RIG: —", UDim2.fromOffset(0, 342), UDim2.new(1, 0, 0, 15), 9, C.muted, Enum.Font.GothamMedium)
local statusIndicator = make("Frame", content, {
    Position = UDim2.fromOffset(1, 366),
    Size = UDim2.fromOffset(6, 6),
    BackgroundColor3 = C.muted,
    BorderSizePixel = 0,
})
make("UICorner", statusIndicator, { CornerRadius = UDim.new(1, 0) })
local statusLabel = label(content, "Selecione um rig R6 ou R15.", UDim2.fromOffset(14, 357), UDim2.new(1, -14, 0, 26), 10, C.muted)
statusLabel.TextWrapped = true
statusLabel.TextYAlignment = Enum.TextYAlignment.Top

make("Frame", content, {
    Position = UDim2.fromOffset(0, 396),
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
})

label(content, "03  /  PREVIEW", UDim2.fromOffset(0, 408), UDim2.new(1, 0, 0, 14), 9, C.muted, Enum.Font.GothamBold)
local previewButton = button(content, "▶", UDim2.fromOffset(0, 430), UDim2.new(0.25, -5, 0, 32), true)
local pauseButton = button(content, "Ⅱ", UDim2.new(0.25, 5, 0, 430), UDim2.new(0.25, -5, 0, 32), false)
local stopButton = button(content, "■", UDim2.new(0.5, 5, 0, 430), UDim2.new(0.25, -5, 0, 32), false)
local speedButton = button(content, "1×", UDim2.new(0.75, 5, 0, 430), UDim2.new(0.25, -5, 0, 32), false)

local previousKeyButton = button(content, "‹  ANTERIOR", UDim2.fromOffset(0, 470), UDim2.new(0.5, -5, 0, 28), false)
local nextKeyButton = button(content, "PRÓXIMO  ›", UDim2.new(0.5, 5, 0, 470), UDim2.new(0.5, -5, 0, 28), false)
local saveButton = button(content, "↓  SALVAR CLIP NO STUDIO", UDim2.fromOffset(0, 510), UDim2.new(1, 0, 0, 34), true)
label(content, "Publicação pelo Editor de Animação do Studio.", UDim2.fromOffset(0, 552), UDim2.new(1, 0, 0, 16), 9, C.muted)

local importedData = nil
local importedSequence = nil
local importedRig = nil
local previewTrack = nil
local previewAnimation = nil
local previewHost = nil
local previewAnimator = nil
local temporaryHost = false
local temporaryAnimator = false
local previewStepConnection = nil
local previewJointSnapshot = {}
local previewPaused = false
local previewSpeed = 1
local speedOptions = { 0.5, 1, 1.5, 2 }
local speedOptionIndex = 2
local isScrubbing = false
local timelineInputConnections = {}

local function setStatus(message, color)
    local statusColor = color or C.muted
    statusLabel.Text = message
    statusLabel.TextColor3 = statusColor
    statusIndicator.BackgroundColor3 = statusColor
end

local function clearTimeline()
    for _, child in ipairs(timelineTrack:GetChildren()) do
        if child.Name == "KeyMarker" then
            child:Destroy()
        end
    end
    timelineInfo.Text = "SEM DADOS"
    timelineTime.Text = "00:00.00"
    timelineCursor.Position = UDim2.new(0, 0, 0.5, 0)
end

local function formatTime(seconds)
    seconds = math.max(0, seconds)
    local minutes = math.floor(seconds / 60)
    local remainder = seconds - minutes * 60
    return string.format("%02d:%05.2f", minutes, remainder)
end

local function updateTimelineCursor(seconds)
    local duration = importedData and importedData.duration or 0
    local alpha = duration > 0 and math.clamp(seconds / duration, 0, 1) or 0
    timelineCursor.Position = UDim2.new(alpha, 0, 0.5, 0)
    timelineTime.Text = formatTime(seconds) .. " / " .. formatTime(duration)
end

local function drawTimeline(data)
    clearTimeline()
    if not data or #data.frames == 0 then
        return
    end

    local duration = math.max(data.duration, 0.001)
    for _, frameData in ipairs(data.frames) do
        local marker = make("Frame", timelineTrack, {
            Name = "KeyMarker",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(math.clamp(frameData.time / duration, 0, 1), 0, 0.5, 0),
            Size = UDim2.fromOffset(5, 16),
            BackgroundColor3 = C.accent,
            BorderSizePixel = 0,
            ZIndex = 2,
        })
        make("UICorner", marker, { CornerRadius = UDim.new(0, 2) })
    end

    local clipTypeLabel = data.clipType == "CurveAnimation" and "CURVAS · EXPERIMENTAL" or "KEYFRAMES"
    timelineInfo.Text = string.format("%d QUADROS  /  %.2FS  /  %s", #data.frames, data.duration, clipTypeLabel)
    updateTimelineCursor(0)
end

local function isSupportedJoint(instance)
    return instance:IsA("Motor6D") or instance:IsA("AnimationConstraint")
end

local function selectedRig()
    local items = Selection:Get()
    for _, item in ipairs(items) do
        local current = item
        while current and current ~= Workspace do
            if current:IsA("Model") then
                local hasJoint = false
                for _, descendant in ipairs(current:GetDescendants()) do
                    if isSupportedJoint(descendant) then
                        hasJoint = true
                        break
                    end
                end
                if hasJoint then
                    return current
                end
            end
            current = current.Parent
        end
    end
    return nil
end

local function getSkeleton(rig)
    local jointsByPart1 = {}
    local childrenByPart0 = {}
    local incoming = {}
    local hasAnimationConstraint = false

    for _, descendant in ipairs(rig:GetDescendants()) do
        local part0 = nil
        local part1 = nil

        if descendant:IsA("Motor6D") then
            part0 = descendant.Part0
            part1 = descendant.Part1
        elseif descendant:IsA("AnimationConstraint") then
            hasAnimationConstraint = true
            local attachment0 = descendant.Attachment0
            local attachment1 = descendant.Attachment1
            part0 = attachment0 and attachment0.Parent
            part1 = attachment1 and attachment1.Parent

            if not part0 or not part1
                or not part0:IsA("BasePart")
                or not part1:IsA("BasePart") then
                error("Uma AnimationConstraint não possui Attachments ligados a BaseParts.")
            end
        end

        if isSupportedJoint(descendant) and part0 and part1 then
            if not part0:IsA("BasePart") or not part1:IsA("BasePart") then
                error("Uma junta do rig não conecta duas BaseParts.")
            end
            if jointsByPart1[part1.Name] then
                error("Há duas juntas controlando uma peça chamada " .. part1.Name .. ".")
            end

            jointsByPart1[part1.Name] = descendant
            incoming[part1] = true
            childrenByPart0[part0] = childrenByPart0[part0] or {}
            table.insert(childrenByPart0[part0], part1)
        end
    end

    local jointCount = 0
    for _, children in pairs(childrenByPart0) do
        table.sort(children, function(a, b)
            return a.Name < b.Name
        end)
        jointCount += #children
    end
    if jointCount == 0 then
        error("O rig não possui Motor6D ou AnimationConstraint válidas.")
    end

    local rootCandidate = rig:FindFirstChild("HumanoidRootPart", true)
    if not rootCandidate or not rootCandidate:IsA("BasePart") then
        rootCandidate = rig.PrimaryPart
    end

    if not rootCandidate then
        for part in pairs(childrenByPart0) do
            if not incoming[part] then
                rootCandidate = part
                break
            end
        end
    end

    if not rootCandidate or not rootCandidate:IsA("BasePart") then
        error("Não foi possível identificar a raiz do rig.")
    end

    local rootPart = rootCandidate
    local visitedParts = {}
    local visitedChildren = {}

    local function walk(part)
        if visitedParts[part] then
            error("A hierarquia de juntas contém um ciclo.")
        end
        visitedParts[part] = true

        for _, childPart in ipairs(childrenByPart0[part] or {}) do
            if visitedChildren[childPart] then
                error("Uma peça conectada foi encontrada em mais de uma junta.")
            end
            visitedChildren[childPart] = true
            walk(childPart)
        end
    end

    walk(rootPart)

    local reachable = 0
    for _ in pairs(visitedChildren) do
        reachable += 1
    end
    if reachable ~= jointCount then
        error("A hierarquia de juntas não parte da raiz do rig. Confira Attachments e AssemblyRootPart.")
    end

    return {
        rootPart = rootPart,
        jointsByPart1 = jointsByPart1,
        childrenByPart0 = childrenByPart0,
        jointCount = jointCount,
        hasAnimationConstraint = hasAnimationConstraint,
    }
end

local function refreshSelectionHint()
    if importedData then
        return
    end

    local rig = selectedRig()
    rigInfo.Text = rig and ("SELECIONADO: " .. rig.Name) or "RIG: —"
end

Selection.SelectionChanged:Connect(refreshSelectionHint)
refreshSelectionHint()

local function isFiniteNumber(value)
    return typeof(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function arrayLength(value, fieldName, maximum)
    if typeof(value) ~= "table" then
        error(fieldName .. " precisa ser um array.")
    end

    local count = 0
    local highestIndex = 0
    for key in pairs(value) do
        if typeof(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            error(fieldName .. " deve conter apenas índices inteiros começando em 1.")
        end
        count += 1
        highestIndex = math.max(highestIndex, key)
        if highestIndex > maximum then
            error(fieldName .. " ultrapassa o limite de " .. maximum .. " itens.")
        end
    end

    if highestIndex ~= count then
        error(fieldName .. " contém posições vazias ou índices fora de ordem.")
    end

    return count
end

local function readVector3(value, fieldName, limit)
    if value == nil then
        return 0, 0, 0
    end
    if arrayLength(value, fieldName, 3) ~= 3 then
        error(fieldName .. " deve conter exatamente três números [x, y, z].")
    end

    local x, y, z = value[1], value[2], value[3]
    if not isFiniteNumber(x) or math.abs(x) > limit
        or not isFiniteNumber(y) or math.abs(y) > limit
        or not isFiniteNumber(z) or math.abs(z) > limit then
        error(fieldName .. " contém um valor fora do limite permitido.")
    end
    return x, y, z
end

local function transformFromData(jointData)
    if jointData == nil then
        return CFrame.identity
    end
    if typeof(jointData) ~= "table" then
        error("Cada junta precisa ser um objeto com position e rotation.")
    end

    local px, py, pz = readVector3(jointData.position, "position", MAX_TRANSFORM_OFFSET)
    local rx, ry, rz = readVector3(jointData.rotation, "rotation", MAX_ROTATION)

    return CFrame.new(px, py, pz) * CFrame.fromEulerAnglesXYZ(
        math.rad(rx),
        math.rad(ry),
        math.rad(rz)
    )
end

local function extractPayload(source)
    local fence = string.rep(string.char(96), 3)
    source = source:gsub("^%s*" .. fence .. "[%w_-]*%s*", "")
    source = source:gsub("%s*" .. fence .. "%s*$", "")

    local payload = source:match("POSECODE_BEGIN(.-)POSECODE_END")
    if payload then
        return payload
    end

    local _, body = source:match("POSECODE%s*=%s*%[(=*)%[(.-)%]%1%]")
    if body then
        return body
    end

    return source
end

local function validateData(data, rig, skeleton)
    if typeof(data) ~= "table" then
        error("O conteúdo precisa ser um objeto JSON.")
    end
    if data.format ~= "POSECODE" then
        error('Campo "format" precisa ser "POSECODE".')
    end
    if data.version ~= 1 then
        error('Versão incompatível. Use "version": 1.')
    end
    if data.rig ~= "R6" and data.rig ~= "R15" then
        error('Campo "rig" precisa ser "R6" ou "R15".')
    end

    local humanoid = rig:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.RigType.Name ~= data.rig then
        error("O script é para " .. data.rig .. ", mas o rig selecionado é " .. humanoid.RigType.Name .. ".")
    end

    if not isFiniteNumber(data.fps) or data.fps < 1 or data.fps > 60 or data.fps % 1 ~= 0 then
        error('"fps" precisa ser um número inteiro entre 1 e 60.')
    end
    if typeof(data.looped) ~= "boolean" then
        error('"looped" precisa ser true ou false.')
    end
    if not isFiniteNumber(data.duration) or data.duration <= 0 or data.duration > MAX_DURATION then
        error('"duration" precisa estar entre 0 e 15 segundos.')
    end
    local frameCount = arrayLength(data.frames, "frames", MAX_FRAMES)
    if frameCount < 1 then
        error("A animação precisa ter pelo menos um keyframe.")
    end

    local durationFrames = math.floor(data.duration * data.fps + 0.5)
    if durationFrames < 1 then
        error("A duração precisa ser de pelo menos um quadro no FPS informado.")
    end
    local normalizedDuration = durationFrames / data.fps

    local priorityName = data.priority or "Action"
    local validPriorities = {
        Core = true,
        Idle = true,
        Movement = true,
        Action = true,
        Action2 = true,
        Action3 = true,
        Action4 = true,
    }
    if not validPriorities[priorityName] then
        error('"priority" precisa ser Core, Idle, Movement, Action, Action2, Action3 ou Action4.')
    end

    local frames = {}
    local seenFrames = {}

    for index, frameData in ipairs(data.frames) do
        if typeof(frameData) ~= "table" or not isFiniteNumber(frameData.time) then
            error("Keyframe " .. index .. " não possui um tempo válido.")
        end
        if frameData.time < 0 or frameData.time > data.duration then
            error("O tempo de um keyframe ultrapassa a duração declarada.")
        end
        if typeof(frameData.joints) ~= "table" then
            error("Keyframe " .. index .. " precisa ter um objeto joints.")
        end

        local frameNumber = math.floor(frameData.time * data.fps + 0.5)
        if frameNumber > durationFrames then
            error("Um keyframe ficou depois do fim ao ajustar ao FPS informado.")
        end
        if seenFrames[frameNumber] then
            error("Dois keyframes caíram no mesmo quadro depois do ajuste ao FPS.")
        end
        seenFrames[frameNumber] = true

        local easingStyleName = frameData.easingStyle or data.easingStyle or "Linear"
        local easingDirectionName = frameData.easingDirection or data.easingDirection or "InOut"
        local easingStyle = Enum.PoseEasingStyle[easingStyleName]
        local easingDirection = Enum.PoseEasingDirection[easingDirectionName]

        if not easingStyle then
            error('EasingStyle inválido no keyframe ' .. index .. '. Use Linear, Constant, CubicV2, Elastic ou Bounce.')
        end
        if not easingDirection then
            error('EasingDirection inválido no keyframe ' .. index .. '. Use In, Out ou InOut.')
        end

        if skeleton.hasAnimationConstraint then
            if easingStyleName == "Elastic" or easingStyleName == "Bounce" then
                error("CurveAnimation não possui interpolação Elastic ou Bounce. Use Linear, Constant ou CubicV2.")
            end
            if easingStyleName == "CubicV2" and easingDirectionName ~= "InOut" then
                error("Posecode 1.3 usa CubicV2 com direção InOut. Ajuste o easingDirection deste quadro.")
            end
        end

        local transforms = {}
        for jointName, jointData in pairs(frameData.joints) do
            if typeof(jointName) ~= "string" or not skeleton.jointsByPart1[jointName] then
                error('A junta "' .. tostring(jointName) .. '" não existe nesse rig. Use o nome da peça conectada pela junta.')
            end
            transforms[jointName] = transformFromData(jointData)
        end

        table.insert(frames, {
            time = frameNumber / data.fps,
            joints = frameData.joints,
            transforms = transforms,
            easingStyle = easingStyle,
            easingDirection = easingDirection,
        })
    end

    table.sort(frames, function(a, b)
        return a.time < b.time
    end)

    if frames[1].time > 0 then
        table.insert(frames, 1, {
            time = 0,
            joints = {},
            transforms = {},
            easingStyle = frames[1].easingStyle,
            easingDirection = frames[1].easingDirection,
        })
    end

    local lastFrame = frames[#frames]
    if lastFrame.time < normalizedDuration then
        table.insert(frames, {
            time = normalizedDuration,
            joints = table.clone(lastFrame.joints),
            transforms = table.clone(lastFrame.transforms),
            easingStyle = lastFrame.easingStyle,
            easingDirection = lastFrame.easingDirection,
        })
    end

    if #frames > MAX_FRAMES then
        error("A normalização adicionou keyframes e ultrapassou o limite de " .. MAX_FRAMES .. ". Reduza a quantidade de quadros.")
    end

    local cleanName = typeof(data.name) == "string" and data.name or "Posecode_Animation"
    cleanName = cleanName:gsub("[^%w_%-]", "_"):sub(1, 42)
    if cleanName == "" then
        cleanName = "Posecode_Animation"
    end

    return {
        name = cleanName,
        format = data.format,
        version = data.version,
        rig = data.rig,
        fps = data.fps,
        looped = data.looped,
        duration = normalizedDuration,
        priority = Enum.AnimationPriority[priorityName],
        clipType = skeleton.hasAnimationConstraint and "CurveAnimation" or "KeyframeSequence",
        frames = frames,
    }
end

local function buildKeyframeSequence(data, skeleton)
    local sequence = Instance.new("KeyframeSequence")
    sequence.Name = data.name
    sequence.Loop = data.looped
    sequence.Priority = data.priority

    local currentTransforms = {}

    local ok, result = pcall(function()
        for index, frameData in ipairs(data.frames) do
            for jointName, transform in pairs(frameData.transforms) do
                currentTransforms[jointName] = transform
            end

            local keyframe = Instance.new("Keyframe")
            keyframe.Name = string.format("Keyframe_%03d", index)
            keyframe.Time = frameData.time

            local rootPose = Instance.new("Pose")
            rootPose.Name = skeleton.rootPart.Name

            local function addChildren(part, parentPose)
                for _, part1 in ipairs(skeleton.childrenByPart0[part] or {}) do
                    local pose = Instance.new("Pose")
                    pose.Name = part1.Name
                    pose.CFrame = currentTransforms[part1.Name] or CFrame.identity
                    pose.EasingStyle = frameData.easingStyle
                    pose.EasingDirection = frameData.easingDirection
                    parentPose:AddSubPose(pose)
                    addChildren(part1, pose)
                end
            end

            addChildren(skeleton.rootPart, rootPose)
            keyframe:AddPose(rootPose)
            sequence:AddKeyframe(keyframe)
        end
        return sequence
    end)

    if not ok then
        sequence:Destroy()
        error(result)
    end

    return result
end

local function curveInterpolation(frameData)
    local name = frameData.easingStyle.Name
    if name == "Constant" then
        return Enum.KeyInterpolationMode.Constant
    end
    if name == "Linear" then
        return Enum.KeyInterpolationMode.Linear
    end
    return Enum.KeyInterpolationMode.Cubic
end

local function buildCurveAnimation(data, skeleton)
    local animation = Instance.new("CurveAnimation")
    animation.Name = data.name
    animation.Loop = data.looped
    animation.Priority = data.priority

    local snapshots = {}
    local currentTransforms = {}

    for index, frameData in ipairs(data.frames) do
        for jointName, transform in pairs(frameData.transforms) do
            currentTransforms[jointName] = transform
        end

        local snapshot = {}
        for jointName in pairs(skeleton.jointsByPart1) do
            local transform = currentTransforms[jointName] or CFrame.identity
            local rx, ry, rz = transform:ToEulerAnglesXYZ()
            snapshot[jointName] = {
                position = transform.Position,
                rotation = Vector3.new(rx, ry, rz),
            }
        end
        snapshots[index] = snapshot
    end

    local ok, result = pcall(function()
        local rootFolder = Instance.new("Folder")
        rootFolder.Name = skeleton.rootPart.Name
        rootFolder.Parent = animation

        local function addCurveKeys(floatCurve, axisGetter, partName, axisKind)
            local keys = {}

            local function getValue(index)
                local pose = snapshots[index][partName]
                if axisKind == "position" then
                    return pose.position[axisGetter]
                end
                return pose.rotation[axisGetter]
            end

            for index, frameData in ipairs(data.frames) do
                local value = getValue(index)
                local interpolation = curveInterpolation(frameData)
                local key = FloatCurveKey.new(frameData.time, value, interpolation)

                if interpolation == Enum.KeyInterpolationMode.Cubic and index < #data.frames then
                    local nextFrame = data.frames[index + 1]
                    local nextValue = getValue(index + 1)
                    local deltaTime = nextFrame.time - frameData.time
                    if deltaTime > 0 then
                        key.RightTangent = (nextValue - value) / deltaTime
                    end
                end

                if index > 1 and curveInterpolation(data.frames[index - 1]) == Enum.KeyInterpolationMode.Cubic then
                    local previousFrame = data.frames[index - 1]
                    local previousValue = getValue(index - 1)
                    local deltaTime = frameData.time - previousFrame.time
                    if deltaTime > 0 then
                        key.LeftTangent = (value - previousValue) / deltaTime
                    end
                end

                table.insert(keys, key)
            end

            floatCurve:SetKeys(keys)
        end

        local function addJointFolders(part, parentFolder)
            for _, part1 in ipairs(skeleton.childrenByPart0[part] or {}) do
                local jointFolder = Instance.new("Folder")
                jointFolder.Name = part1.Name
                jointFolder.Parent = parentFolder

                local positionCurve = Instance.new("Vector3Curve")
                positionCurve.Name = "Position"
                positionCurve.Parent = jointFolder

                local rotationCurve = Instance.new("EulerRotationCurve")
                rotationCurve.Name = "Rotation"
                rotationCurve.RotationOrder = Enum.RotationOrder.XYZ
                rotationCurve.Parent = jointFolder

                addCurveKeys(positionCurve:X(), "X", part1.Name, "position")
                addCurveKeys(positionCurve:Y(), "Y", part1.Name, "position")
                addCurveKeys(positionCurve:Z(), "Z", part1.Name, "position")

                addCurveKeys(rotationCurve:X(), "X", part1.Name, "rotation")
                addCurveKeys(rotationCurve:Y(), "Y", part1.Name, "rotation")
                addCurveKeys(rotationCurve:Z(), "Z", part1.Name, "rotation")

                addJointFolders(part1, jointFolder)
            end
        end

        addJointFolders(skeleton.rootPart, rootFolder)
        return animation
    end)

    if not ok then
        animation:Destroy()
        error(result)
    end

    return result
end

local function buildAnimationClip(data, skeleton)
    if skeleton.hasAnimationConstraint then
        data.clipType = "CurveAnimation"
        return buildCurveAnimation(data, skeleton)
    end

    data.clipType = "KeyframeSequence"
    return buildKeyframeSequence(data, skeleton)
end

local function stopPreview()
    if previewStepConnection then
        previewStepConnection:Disconnect()
        previewStepConnection = nil
    end

    if previewTrack then
        pcall(function()
            previewTrack:Stop(0)
        end)
    end

    if previewAnimator then
        pcall(function()
            previewAnimator:StepAnimations(0)
        end)
    end

    for joint, snapshot in pairs(previewJointSnapshot) do
        if joint and joint.Parent then
            pcall(function()
                joint.Transform = snapshot.transform
            end)
        end
    end
    table.clear(previewJointSnapshot)

    if previewTrack then
        pcall(function()
            previewTrack:Destroy()
        end)
        previewTrack = nil
    end

    if previewAnimation then
        previewAnimation:Destroy()
        previewAnimation = nil
    end

    if temporaryAnimator and previewAnimator then
        previewAnimator:Destroy()
    end
    if temporaryHost and previewHost then
        previewHost:Destroy()
    end

    previewAnimator = nil
    previewHost = nil
    temporaryAnimator = false
    temporaryHost = false
    previewPaused = false
    pauseButton.Text = "Ⅱ"
    updateTimelineCursor(0)
end

local function beginPreview()
    if not importedSequence or not importedRig then
        setStatus("Importe uma animação antes de reproduzir.", C.red)
        return
    end
    if not importedRig:IsDescendantOf(Workspace) then
        setStatus("O rig precisa estar no Workspace para a prévia.", C.red)
        return
    end

    stopPreview()

    local host = importedRig:FindFirstChildOfClass("Humanoid")
        or importedRig:FindFirstChildOfClass("AnimationController")

    if not host then
        host = Instance.new("AnimationController")
        host.Name = "PosecodePreviewController"
        host.Parent = importedRig
        temporaryHost = true
    end
    previewHost = host

    local animator = host:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = host
        temporaryAnimator = true
    end
    previewAnimator = animator

    for _, descendant in ipairs(importedRig:GetDescendants()) do
        if isSupportedJoint(descendant) then
            previewJointSnapshot[descendant] = {
                transform = descendant.Transform,
            }
        end
    end

    local ok, result = pcall(function()
        local temporaryId = AnimationClipProvider:RegisterActiveAnimationClip(importedSequence)
        local animation = Instance.new("Animation")
        animation.Name = "PosecodePreview"
        animation.AnimationId = temporaryId

        local track = animator:LoadAnimation(animation)
        track.Looped = importedData.looped
        track.Priority = importedData.priority
        track:Play(0, 1, previewSpeed)

        previewAnimation = animation
        previewTrack = track
        previewPaused = false
        pauseButton.Text = "Ⅱ"

        previewStepConnection = RunService.Heartbeat:Connect(function(deltaTime)
            if not previewAnimator or not previewTrack then
                return
            end

            local stepOk, stepError = pcall(function()
                previewAnimator:StepAnimations(deltaTime)
            end)

            if not stepOk then
                stopPreview()
                setStatus("Falha ao atualizar a prévia: " .. tostring(stepError), C.red)
                return
            end

            if previewTrack and previewTrack.IsPlaying then
                updateTimelineCursor(previewTrack.TimePosition)
            elseif previewTrack then
                stopPreview()
                setStatus("Prévia concluída.", C.green)
            end
        end)
    end)

    if not ok then
        stopPreview()
        setStatus("Não foi possível iniciar a prévia: " .. tostring(result), C.red)
        return
    end

    setStatus("Prévia reproduzindo no rig selecionado.", C.green)
end

local function playPreview()
    if previewTrack and previewTrack.IsPlaying then
        previewPaused = false
        pauseButton.Text = "Ⅱ"
        previewTrack:AdjustSpeed(previewSpeed)
        setStatus("Prévia reproduzindo.", C.green)
    else
        beginPreview()
    end
end

local function pausePreview()
    if not previewTrack or not previewTrack.IsPlaying then
        setStatus("Nenhuma prévia está em reprodução.", C.muted)
        return
    end

    if previewPaused then
        previewTrack:AdjustSpeed(previewSpeed)
        previewPaused = false
        pauseButton.Text = "Ⅱ"
        setStatus("Prévia reproduzindo.", C.green)
    else
        previewTrack:AdjustSpeed(0)
        previewPaused = true
        pauseButton.Text = "▶"
        setStatus("Prévia pausada.", C.muted)
    end
end

local function seekToTime(seconds)
    if not importedData then
        return
    end

    if not previewTrack or not previewTrack.IsPlaying then
        beginPreview()
    end
    if not previewTrack or not previewTrack.IsPlaying then
        return
    end

    local target = math.clamp(seconds, 0, importedData.duration)
    previewTrack:AdjustSpeed(0)
    previewPaused = true
    previewTrack.TimePosition = target

    if previewAnimator then
        pcall(function()
            previewAnimator:StepAnimations(0)
        end)
    end

    updateTimelineCursor(target)
    setStatus("Prévia pausada no tempo selecionado.", C.muted)
end

local function seekFromScreenX(screenX)
    if not importedData then
        return
    end

    local width = math.max(1, timelineHitbox.AbsoluteSize.X)
    local localX = screenX - timelineHitbox.AbsolutePosition.X
    local alpha = math.clamp(localX / width, 0, 1)
    seekToTime(importedData.duration * alpha)
end

local function stepKeyframe(direction)
    if not importedData then
        setStatus("Importe uma animação antes de navegar pelos quadros.", C.red)
        return
    end

    local currentTime = previewTrack and previewTrack.IsPlaying and previewTrack.TimePosition or 0
    local targetTime = direction < 0 and 0 or importedData.duration

    if direction < 0 then
        for _, frameData in ipairs(importedData.frames) do
            if frameData.time < currentTime - 0.0001 then
                targetTime = frameData.time
            else
                break
            end
        end
    else
        for _, frameData in ipairs(importedData.frames) do
            if frameData.time > currentTime + 0.0001 then
                targetTime = frameData.time
                break
            end
        end
    end

    seekToTime(targetTime)
end

local function cyclePreviewSpeed()
    speedOptionIndex += 1
    if speedOptionIndex > #speedOptions then
        speedOptionIndex = 1
    end

    previewSpeed = speedOptions[speedOptionIndex]
    speedButton.Text = tostring(previewSpeed) .. "×"

    if previewTrack and previewTrack.IsPlaying and not previewPaused then
        previewTrack:AdjustSpeed(previewSpeed)
    end

    setStatus("Velocidade da prévia: " .. tostring(previewSpeed) .. "×.", C.muted)
end

local function saveSequence()
    if not importedSequence or not importedRig then
        setStatus("Importe uma animação antes de salvar.", C.red)
        return
    end

    local recordingCallOk, recordingId = pcall(function()
        return ChangeHistoryService:TryBeginRecording(
            "Posecode_SaveAnimation",
            "Posecode: salvar keyframes"
        )
    end)

    if not recordingCallOk or not recordingId then
        setStatus("O Studio não iniciou o registro de Undo. Feche um playtest ou finalize outra ação de plugin e tente novamente.", C.red)
        return
    end

    local originalParent = importedSequence.Parent
    local originalName = importedSequence.Name
    local createdRootFolder = nil
    local createdRigFolder = nil
    local createdReference = nil
    local existingReference = nil
    local originalReferenceValue = nil

    local function rollback()
        pcall(function()
            importedSequence.Parent = originalParent
            importedSequence.Name = originalName
        end)

        if createdReference then
            pcall(function()
                createdReference:Destroy()
            end)
        elseif existingReference then
            pcall(function()
                existingReference.Value = originalReferenceValue
            end)
        end

        if createdRigFolder then
            pcall(function()
                if #createdRigFolder:GetChildren() == 0 then
                    createdRigFolder:Destroy()
                end
            end)
        end

        if createdRootFolder then
            pcall(function()
                if #createdRootFolder:GetChildren() == 0 then
                    createdRootFolder:Destroy()
                end
            end)
        end
    end

    local ok, result = pcall(function()
        local animSaves = importedRig:FindFirstChild("AnimSaves")
        local saveFolder = nil

        if animSaves then
            if animSaves:IsA("Folder") then
                -- Compatibilidade com rigs que ainda usam o formato antigo.
                saveFolder = animSaves
            elseif animSaves:IsA("ObjectValue") then
                existingReference = animSaves
                originalReferenceValue = animSaves.Value

                if animSaves.Value then
                    if not animSaves.Value:IsA("Folder") then
                        error("A referência AnimSaves não aponta para uma Folder.")
                    end
                    saveFolder = animSaves.Value
                end
            else
                error('O objeto "AnimSaves" do rig precisa ser Folder ou ObjectValue.')
            end
        end

        if not saveFolder then
            local rootFolder = ServerStorage:FindFirstChild("RBX_ANIMSAVES")
            if rootFolder and not rootFolder:IsA("Folder") then
                error('ServerStorage.RBX_ANIMSAVES existe, mas não é uma Folder.')
            end

            if not rootFolder then
                rootFolder = Instance.new("Folder")
                rootFolder.Name = "RBX_ANIMSAVES"
                rootFolder.Parent = ServerStorage
                createdRootFolder = rootFolder
            end

            local folderName = importedRig.Name:gsub("[^%w_%-]", "_")
            if folderName == "" then
                folderName = "Rig"
            end

            local finalFolderName = folderName
            local suffix = 2
            while rootFolder:FindFirstChild(finalFolderName) do
                finalFolderName = folderName .. "_" .. suffix
                suffix += 1
            end

            saveFolder = Instance.new("Folder")
            saveFolder.Name = finalFolderName
            saveFolder.Parent = rootFolder
            createdRigFolder = saveFolder

            if not animSaves then
                animSaves = Instance.new("ObjectValue")
                animSaves.Name = "AnimSaves"
                animSaves.Parent = importedRig
                createdReference = animSaves
            end

            animSaves.Value = saveFolder
        end

        local baseName = importedData.name
        local finalName = baseName

        if importedSequence.Parent ~= saveFolder then
            local suffix = 2
            while saveFolder:FindFirstChild(finalName) do
                finalName = baseName .. "_" .. suffix
                suffix += 1
            end
        else
            finalName = importedSequence.Name
        end

        importedSequence.Name = finalName
        importedSequence.Parent = saveFolder

        return finalName
    end)

    if not ok then
        pcall(function()
            ChangeHistoryService:FinishRecording(
                recordingId,
                Enum.FinishRecordingOperation.Cancel
            )
        end)
        rollback()
        setStatus("Falha ao salvar: " .. tostring(result), C.red)
        return
    end

    local finishOk, finishError = pcall(function()
        ChangeHistoryService:FinishRecording(
            recordingId,
            Enum.FinishRecordingOperation.Commit
        )
    end)

    if not finishOk then
        pcall(function()
            ChangeHistoryService:FinishRecording(
                recordingId,
                Enum.FinishRecordingOperation.Cancel
            )
        end)
        rollback()
        setStatus("O Studio não conseguiu concluir o registro de Undo: " .. tostring(finishError), C.red)
        return
    end

    setStatus('Clip salvo em AnimSaves. Nome: "' .. result .. '".', C.green)
end

importButton.Activated:Connect(function()
    stopPreview()

    local rig = selectedRig()
    if not rig then
        setStatus("Selecione um rig R6 ou R15 com Motor6D ou AnimationConstraint.", C.red)
        return
    end

    if #sourceBox.Text > MAX_SOURCE_LENGTH then
        setStatus("O conteúdo ultrapassa 256 KB. Reduza o JSON e tente novamente.", C.red)
        return
    end
    if sourceBox.Text:match("^%s*$") then
        setStatus("Cole um script ou JSON de animação antes de importar.", C.red)
        return
    end

    local ok, result = pcall(function()
        local skeleton = getSkeleton(rig)
        local payload = extractPayload(sourceBox.Text)
        local decoded = HttpService:JSONDecode(payload)
        local data = validateData(decoded, rig, skeleton)
        local clip = buildAnimationClip(data, skeleton)
        return {
            data = data,
            clip = clip,
            skeleton = skeleton,
        }
    end)

    if not ok then
        setStatus("Importação recusada: " .. tostring(result), C.red)
        return
    end

    if importedSequence and importedSequence.Parent == nil then
        importedSequence:Destroy()
    end

    importedData = result.data
    importedSequence = result.clip
    importedRig = rig

    local clipTypeLabel = importedData.clipType == "CurveAnimation" and "CURVE (EXPERIMENTAL)" or "KEYFRAME"
    rigInfo.Text = string.format("RIG: %s  /  %s  /  %s", importedData.rig, rig.Name, clipTypeLabel)
    drawTimeline(importedData)

    setStatus(
        importedData.clipType == "CurveAnimation"
            and string.format("%d quadros convertidos. Saída CurveAnimation experimental; confira o rig antes de salvar.", #importedData.frames)
            or string.format("%d quadros convertidos. Prévia, navegação e salvamento disponíveis.", #importedData.frames),
        C.green
    )
end)

exampleButton.Activated:Connect(function()
    local rig = selectedRig()
    if not rig then
        setStatus("Selecione um rig antes de carregar o exemplo.", C.red)
        return
    end

    local ok, result = pcall(function()
        local humanoid = rig:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            error("O rig selecionado precisa ter um Humanoid para identificar R6 ou R15.")
        end

        local skeleton = getSkeleton(rig)
        local rootChildren = skeleton.childrenByPart0[skeleton.rootPart] or {}
        if #rootChildren == 0 then
            error("Não encontrei uma junta conectada à raiz desse rig.")
        end

        local jointName = rootChildren[1].Name
        local sample = {
            format = "POSECODE",
            version = 1,
            name = "Posecode_Sample",
            rig = humanoid.RigType.Name,
            fps = 30,
            duration = 0.6,
            looped = false,
            priority = "Action",
            easingStyle = "CubicV2",
            easingDirection = "InOut",
            frames = {
                {
                    time = 0,
                    joints = {
                        [jointName] = {
                            position = { 0, 0, 0 },
                            rotation = { 0, 0, 0 },
                        },
                    },
                },
                {
                    time = 0.3,
                    joints = {
                        [jointName] = {
                            position = { 0, 0, 0 },
                            rotation = { 0, 0, 22 },
                        },
                    },
                },
                {
                    time = 0.6,
                    joints = {
                        [jointName] = {
                            position = { 0, 0, 0 },
                            rotation = { 0, 0, 0 },
                        },
                    },
                },
            },
        }
        return HttpService:JSONEncode(sample)
    end)

    if not ok then
        setStatus("Não consegui criar o exemplo: " .. tostring(result), C.red)
        return
    end

    sourceBox.Text = result
    setStatus("Exemplo carregado. Clique em Importar Animação.", C.green)
end)

clearButton.Activated:Connect(function()
    stopPreview()
    sourceBox.Text = ""

    if importedSequence and importedSequence.Parent == nil then
        importedSequence:Destroy()
    end

    importedSequence = nil
    importedData = nil
    importedRig = nil
    refreshSelectionHint()
    clearTimeline()
    setStatus("Campo de importação limpo.")
end)

timelineInputConnections[1] = timelineHitbox.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        isScrubbing = true
        seekFromScreenX(input.Position.X)
    end
end)

timelineInputConnections[2] = UserInputService.InputChanged:Connect(function(input)
    if not isScrubbing then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        seekFromScreenX(input.Position.X)
    end
end)

timelineInputConnections[3] = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        isScrubbing = false
    end
end)

previewButton.Activated:Connect(playPreview)

pauseButton.Activated:Connect(pausePreview)

stopButton.Activated:Connect(function()
    stopPreview()
    setStatus("Prévia parada.")
end)

speedButton.Activated:Connect(cyclePreviewSpeed)

previousKeyButton.Activated:Connect(function()
    stepKeyframe(-1)
end)

nextKeyButton.Activated:Connect(function()
    stepKeyframe(1)
end)

saveButton.Activated:Connect(saveSequence)

toolbarButton.Click:Connect(function()
    widget.Enabled = not widget.Enabled
end)

plugin.Unloading:Connect(function()
    stopPreview()
    for _, connection in ipairs(timelineInputConnections) do
        connection:Disconnect()
    end
    if importedSequence and importedSequence.Parent == nil then
        importedSequence:Destroy()
    end
end)
