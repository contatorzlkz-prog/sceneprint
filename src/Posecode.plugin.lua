--[[
    POSECODE
    Procedural character animation generator for Roblox Studio.
    Handle: ruancr
    Version: 3.1
    Generates motion directly from procedural profiles. No code import.
]]

assert(plugin, "Abra este arquivo como um plugin do Roblox Studio.")

local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local AnimationClipProvider = game:GetService("AnimationClipProvider")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local VERSION = "3.1"
local MOTION_BASE_COUNT = 20
local MOTION_VARIATION_COUNT = MOTION_BASE_COUNT * 5 * 5 * 5 * 4 * 4 * 4 * 2 * 3 * 17
local MAX_FRAMES = 120
local MAX_DURATION = 15
local MAX_TRANSFORM_OFFSET = 5
local MAX_ROTATION = 720
local MAX_JOINTS = 15
local MAX_MARKERS = 128
local MAX_MARKERS_PER_FRAME = 8
local MAX_POSE_INSTANCES = 18000
local MAX_CURVE_KEYS = 24000

local C = {
    background = Color3.fromRGB(30, 31, 33),
    panel = Color3.fromRGB(34, 35, 38),
    field = Color3.fromRGB(24, 25, 27),
    surface = Color3.fromRGB(48, 50, 53),
    surfaceHover = Color3.fromRGB(57, 59, 63),
    line = Color3.fromRGB(61, 63, 67),
    text = Color3.fromRGB(232, 233, 235),
    muted = Color3.fromRGB(157, 160, 165),
    accent = Color3.fromRGB(93, 132, 158),
    accentHover = Color3.fromRGB(108, 148, 171),
    nodeA = Color3.fromRGB(90, 132, 164),
    nodeB = Color3.fromRGB(94, 151, 139),
    event = Color3.fromRGB(202, 164, 91),
    disabled = Color3.fromRGB(39, 40, 42),
    disabledText = Color3.fromRGB(106, 108, 112),
    green = Color3.fromRGB(133, 172, 139),
    red = Color3.fromRGB(193, 126, 126),
}

local toolbar = plugin:CreateToolbar("POSECODE")
local toolbarButton = toolbar:CreateButton("POSECODE", "Abrir POSECODE", "")
toolbarButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Right,
    false,
    false,
    360,
    640,
    300,
    440
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
    local hoverColor = primary and C.accentHover or C.surfaceHover
    local object = make("TextButton", parent, {
        Position = position,
        Size = size,
        BackgroundColor3 = normalColor,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = C.text,
        TextSize = 11,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Selectable = true,
    })
    make("UICorner", object, { CornerRadius = UDim.new(0, 3) })

    object.MouseEnter:Connect(function()
        if object.Active then
            object.BackgroundColor3 = hoverColor
        end
    end)
    object.MouseLeave:Connect(function()
        object.BackgroundColor3 = object.Active and normalColor or C.disabled
    end)
    return object
end


local motionEngine = {
    recipes = {},
    lastGeneratedRecipe = nil,
    lastGeneratedPrompt = nil,
}
local selectedRigCache = nil

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
local previewLooped = false
local speedOptions = { 0.5, 1, 1.5, 2 }
local speedOptionIndex = 2
local previewMarkerConnections = {}

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
    Size = UDim2.new(1, 0, 0, 48),
})
label(header, "POSECODE", UDim2.fromOffset(13, 6), UDim2.new(1, -70, 0, 21), 15, C.text, Enum.Font.GothamBold)
label(header, "PROCEDURAL MOTION", UDim2.fromOffset(14, 28), UDim2.new(1, -70, 0, 10), 8, C.muted, Enum.Font.GothamMedium)
local versionLabel = label(header, "v" .. VERSION, UDim2.new(1, -52, 0, 15), UDim2.fromOffset(40, 16), 9, C.muted, Enum.Font.GothamMedium)
versionLabel.TextXAlignment = Enum.TextXAlignment.Right
make("Frame", root, {
    Position = UDim2.fromOffset(12, 48),
    Size = UDim2.new(1, -24, 0, 1),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
})

local scroll = make("ScrollingFrame", root, {
    Name = "GeneratorScroll",
    Position = UDim2.fromOffset(0, 54),
    Size = UDim2.new(1, 0, 1, -98),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.fromOffset(0, 596),
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.muted,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    Active = true,
})
local content = make("Frame", scroll, {
    Name = "GeneratorContent",
    Position = UDim2.fromOffset(12, 0),
    Size = UDim2.new(1, -24, 0, 596),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
})

local rigPanel = make("Frame", content, {
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.new(1, 0, 0, 37),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
})
make("UICorner", rigPanel, { CornerRadius = UDim.new(0, 3) })
local rigDot = make("Frame", rigPanel, {
    Position = UDim2.fromOffset(10, 15),
    Size = UDim2.fromOffset(7, 7),
    BackgroundColor3 = C.muted,
    BorderSizePixel = 0,
})
make("UICorner", rigDot, { CornerRadius = UDim.new(1, 0) })
local rigInfo = label(rigPanel, "SELECIONE O MESH RIG 2016", UDim2.fromOffset(25, 4), UDim2.new(1, -88, 1, -8), 9, C.muted, Enum.Font.GothamMedium)
rigInfo.TextWrapped = true
local refreshRigButton = button(rigPanel, "↻", UDim2.new(1, -34, 0, 5), UDim2.fromOffset(27, 27), false)
refreshRigButton.TextSize = 15

label(content, "DESCREVA O MOVIMENTO", UDim2.fromOffset(0, 47), UDim2.new(1, 0, 0, 14), 9, C.text, Enum.Font.GothamMedium)
local promptBox = make("TextBox", content, {
    Position = UDim2.fromOffset(0, 65),
    Size = UDim2.new(1, 0, 0, 56),
    BackgroundColor3 = C.field,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    Font = Enum.Font.Gotham,
    Text = "walk natural",
    PlaceholderText = "Ex.: walk cansado, run confiante, dance feliz...",
    PlaceholderColor3 = C.muted,
    TextColor3 = C.text,
    TextSize = 11,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    MultiLine = true,
})
make("UICorner", promptBox, { CornerRadius = UDim.new(0, 3) })
make("UIStroke", promptBox, { Color = C.line, Thickness = 1, Transparency = 0.1 })
make("UIPadding", promptBox, {
    PaddingTop = UDim.new(0, 7),
    PaddingBottom = UDim.new(0, 7),
    PaddingLeft = UDim.new(0, 9),
    PaddingRight = UDim.new(0, 9),
})

label(content, "IDEIAS RÁPIDAS", UDim2.fromOffset(0, 128), UDim2.new(1, 0, 0, 12), 8, C.muted, Enum.Font.GothamMedium)
local quickPrompts = {
    { "WALK · TIRED", "walk cansado e lento" },
    { "RUN · PROUD", "run confiante com passos largos" },
    { "SNEAK", "sneak furtivo sem quicar" },
    { "WAVE", "wave friendly" },
    { "JUMP", "jump energetic" },
    { "DANCE", "dance playful" },
}
for index, preset in ipairs(quickPrompts) do
    local column = (index - 1) % 3
    local row = math.floor((index - 1) / 3)
    local chip = button(content, preset[1], UDim2.fromOffset(column * 108, 145 + row * 27), UDim2.new(1 / 3, -5, 0, 22), false)
    chip.TextSize = 8
    chip.Activated:Connect(function()
        promptBox.Text = preset[2]
    end)
end

local graphPanel = make("Frame", content, {
    Position = UDim2.fromOffset(0, 203),
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
})
local function graphNode(parent, position, width, titleText, subtitle, tint)
    local node = make("Frame", parent, {
        Position = position,
        Size = UDim2.new(width, 0, 1, 0),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
    })
    make("UICorner", node, { CornerRadius = UDim.new(0, 3) })
    make("UIStroke", node, { Color = tint, Thickness = 1, Transparency = 0.25 })
    make("Frame", node, {
        Position = UDim2.fromOffset(7, 8),
        Size = UDim2.fromOffset(3, 3),
        BackgroundColor3 = tint,
        BorderSizePixel = 0,
    })
    label(node, titleText, UDim2.fromOffset(15, 4), UDim2.new(1, -19, 0, 13), 8, C.text, Enum.Font.GothamBold)
    label(node, subtitle, UDim2.fromOffset(7, 22), UDim2.new(1, -12, 0, 14), 7, C.muted)
    return node
end
graphNode(graphPanel, UDim2.fromScale(0, 0), 0.29, "MOTION", "base cycle", C.nodeA)
make("Frame", graphPanel, {
    Position = UDim2.new(0.29, 3, 0.5, -1),
    Size = UDim2.new(0.035, 0, 0, 2),
    BackgroundColor3 = C.nodeA,
    BorderSizePixel = 0,
})
graphNode(graphPanel, UDim2.new(0.33, 0, 0, 0), 0.31, "BLEND", "style layers", C.nodeB)
make("Frame", graphPanel, {
    Position = UDim2.new(0.64, 3, 0.5, -1),
    Size = UDim2.new(0.035, 0, 0, 2),
    BackgroundColor3 = C.nodeB,
    BorderSizePixel = 0,
})
graphNode(graphPanel, UDim2.new(0.68, 0, 0, 0), 0.32, "POSE", "15 joints", C.accent)

local generateButton = button(content, "GERAR ANIMAÇÃO", UDim2.fromOffset(0, 260), UDim2.new(1, 0, 0, 35), true)
generateButton.TextSize = 11
local variationButton = button(content, "OUTRA VARIAÇÃO", UDim2.fromOffset(0, 302), UDim2.new(0.5, -4, 0, 29), false)
variationButton.TextSize = 8
local saveReferenceButton = button(content, "GUARDAR REFERÊNCIA", UDim2.new(0.5, 4, 0, 302), UDim2.new(0.5, -4, 0, 29), false)
saveReferenceButton.TextSize = 8

label(content, "BIBLIOTECA LOCAL", UDim2.fromOffset(0, 343), UDim2.new(0.58, 0, 0, 13), 8, C.text, Enum.Font.GothamMedium)
local libraryHeading = label(content, "0 / 48", UDim2.new(0.58, 0, 0, 343), UDim2.new(0.42, 0, 0, 13), 8, C.muted, Enum.Font.GothamMedium)
libraryHeading.TextXAlignment = Enum.TextXAlignment.Right
local libraryList = make("Frame", content, {
    Name = "SavedMotionList",
    Position = UDim2.fromOffset(0, 360),
    Size = UDim2.new(1, 0, 0, 72),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
})

label(content, "PRÉVIA NO RIG", UDim2.fromOffset(0, 441), UDim2.new(1, 0, 0, 13), 8, C.text, Enum.Font.GothamMedium)
local timelinePanel = make("Frame", content, {
    Name = "Timeline",
    Position = UDim2.fromOffset(0, 459),
    Size = UDim2.new(1, 0, 0, 53),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
})
make("UICorner", timelinePanel, { CornerRadius = UDim.new(0, 3) })
local timelineInfo = label(timelinePanel, "SEM ANIMAÇÃO", UDim2.fromOffset(8, 4), UDim2.new(0.62, 0, 0, 12), 7, C.muted, Enum.Font.GothamMedium)
local timelineTime = label(timelinePanel, "00:00.00 / 00:00.00", UDim2.new(0.62, -4, 0, 4), UDim2.new(0.38, -4, 0, 12), 7, C.text, Enum.Font.Code)
timelineTime.TextXAlignment = Enum.TextXAlignment.Right
local timelineTrack = make("Frame", timelinePanel, {
    Position = UDim2.fromOffset(8, 25),
    Size = UDim2.new(1, -16, 0, 18),
    BackgroundTransparency = 1,
})
make("Frame", timelineTrack, {
    Position = UDim2.new(0, 0, 0.5, -1),
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
})
local timelineHitbox = make("TextButton", timelineTrack, {
    Name = "TimelineInput",
    Active = false,
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
    Size = UDim2.fromOffset(2, 16),
    BackgroundColor3 = C.text,
    BorderSizePixel = 0,
    ZIndex = 5,
})

local previewButton = button(content, "PLAY", UDim2.fromOffset(0, 520), UDim2.new(0.23, -3, 0, 27), true)
local pauseButton = button(content, "PAUSE", UDim2.new(0.23, 1, 0, 520), UDim2.new(0.23, -3, 0, 27), false)
local stopButton = button(content, "STOP", UDim2.new(0.46, 2, 0, 520), UDim2.new(0.23, -3, 0, 27), false)
local speedButton = button(content, "1×", UDim2.new(0.69, 3, 0, 520), UDim2.new(0.31, -3, 0, 27), false)
local loopButton = button(content, "LOOP OFF", UDim2.fromOffset(0, 553), UDim2.new(0.34, -4, 0, 27), false)
local saveButton = button(content, "SALVAR NO STUDIO", UDim2.new(0.34, 4, 0, 553), UDim2.new(0.66, -4, 0, 27), true)
saveButton.TextSize = 8
label(content, "20 BASES · 16,32 M CONFIGURAÇÕES · MESH RIG 2016", UDim2.fromOffset(0, 583), UDim2.new(1, 0, 0, 13), 7, C.muted)

local footer = make("Frame", root, {
    Name = "StatusFooter",
    Position = UDim2.new(0, 0, 1, -40),
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = C.background,
    BorderSizePixel = 0,
})
make("Frame", footer, {
    Position = UDim2.fromOffset(12, 0),
    Size = UDim2.new(1, -24, 0, 1),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
})
local statusDot = make("Frame", footer, {
    Position = UDim2.fromOffset(15, 16),
    Size = UDim2.fromOffset(6, 6),
    BackgroundColor3 = C.muted,
    BorderSizePixel = 0,
})
make("UICorner", statusDot, { CornerRadius = UDim.new(1, 0) })
local statusLabel = label(footer, "Selecione o Mesh Rig 2016 no Explorer.", UDim2.fromOffset(27, 5), UDim2.new(1, -39, 0, 30), 8, C.muted)
statusLabel.TextWrapped = true
statusLabel.TextYAlignment = Enum.TextYAlignment.Top

local function setStatus(message, color)
    local statusColor = color or C.muted
    statusLabel.Text = message
    statusLabel.TextColor3 = statusColor
    statusDot.BackgroundColor3 = statusColor
end

local function setButtonState(target, enabled, primary)
    target.Active = enabled
    target.Selectable = enabled
    target.BackgroundColor3 = enabled
        and (primary and C.accent or C.surface)
        or C.disabled
    target.TextColor3 = enabled
        and (primary and Color3.fromRGB(248, 249, 251) or C.text)
        or C.disabledText
end

local function setPreviewRunning(enabled)
    pauseButton.Text = previewPaused and "RESUME" or "PAUSE"
    setButtonState(pauseButton, enabled, false)
    setButtonState(stopButton, enabled, false)
end

local function setClipControlsEnabled(enabled)
    setButtonState(previewButton, enabled, true)
    setButtonState(speedButton, enabled, false)
    setButtonState(loopButton, enabled, false)
    setButtonState(saveButton, enabled, true)
    timelineHitbox.Active = enabled
    timelineHitbox.Selectable = enabled
    setPreviewRunning(false)
end

local function clearTimeline()
    for _, child in ipairs(timelineTrack:GetChildren()) do
        if child.Name == "KeyMarker" or child.Name == "EventMarker" then
            child:Destroy()
        end
    end
    timelineInfo.Text = "SEM ANIMAÇÃO"
    timelineTime.Text = "00:00.00 / 00:00.00"
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
    if not data or #data.frames == 0 then return end
    local duration = math.max(data.duration, 0.001)
    for _, frameData in ipairs(data.frames) do
        local marker = make("Frame", timelineTrack, {
            Name = "KeyMarker",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(math.clamp(frameData.time / duration, 0, 1), 0, 0.5, 0),
            Size = UDim2.fromOffset(3, 10),
            BackgroundColor3 = C.accent,
            BorderSizePixel = 0,
            ZIndex = 2,
        })
        make("UICorner", marker, { CornerRadius = UDim.new(0, 1) })
    end
    local clipType = data.clipType == "CurveAnimation" and "CURVE" or "KEYFRAME"
    timelineInfo.Text = string.format("%s · %d FRAMES · %.2fs", clipType, #data.frames, data.duration)
    updateTimelineCursor(0)
end
local MESH_RIG_2016_PARTS = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local MESH_RIG_2016_PARENT = {
    LowerTorso = "HumanoidRootPart",
    UpperTorso = "LowerTorso",
    Head = "UpperTorso",
    LeftUpperArm = "UpperTorso",
    LeftLowerArm = "LeftUpperArm",
    LeftHand = "LeftLowerArm",
    RightUpperArm = "UpperTorso",
    RightLowerArm = "RightUpperArm",
    RightHand = "RightLowerArm",
    LeftUpperLeg = "LowerTorso",
    LeftLowerLeg = "LeftUpperLeg",
    LeftFoot = "LeftLowerLeg",
    RightUpperLeg = "LowerTorso",
    RightLowerLeg = "RightUpperLeg",
    RightFoot = "RightLowerLeg",
}

local MESH_RIG_2016_PART_SET = {}
for _, partName in ipairs(MESH_RIG_2016_PARTS) do
    MESH_RIG_2016_PART_SET[partName] = true
end

local function validateMeshRig2016(rig, skeleton)
    local humanoid = rig:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
        error("O POSECODE 3.0 aceita somente o Mesh Rig 2016 R15. Selecione esse rig no Explorer.")
    end

    local meshParts = {}
    for _, descendant in ipairs(rig:GetDescendants()) do
        if descendant:IsA("MeshPart") and MESH_RIG_2016_PART_SET[descendant.Name] then
            if meshParts[descendant.Name] then
                error("O rig possui mais de uma MeshPart chamada " .. descendant.Name .. ".")
            end
            meshParts[descendant.Name] = descendant
        end
    end

    for _, partName in ipairs(MESH_RIG_2016_PARTS) do
        if not meshParts[partName] then
            error("Mesh Rig 2016 incompleto: não encontrei a MeshPart " .. partName .. ".")
        end
    end

    if not skeleton.rootPart or skeleton.rootPart.Name ~= "HumanoidRootPart" then
        error("Mesh Rig 2016 precisa ter HumanoidRootPart como raiz.")
    end
    if skeleton.hasBone or skeleton.boneCount > 0 then
        error("Este POSECODE não aceita rigs de Bones. Ele é exclusivo do Mesh Rig 2016 articulado por juntas.")
    end
    if skeleton.partJointCount ~= 15 or skeleton.jointCount ~= 15 then
        error("Estrutura incompatível: o Mesh Rig 2016 precisa ter exatamente 15 juntas corporais.")
    end

    local usesAnimationConstraints = skeleton.animationConstraintCount == 15 and skeleton.motor6DCount == 0
    local usesMotor6D = skeleton.motor6DCount == 15 and skeleton.animationConstraintCount == 0
    if not usesAnimationConstraints and not usesMotor6D then
        error("As 15 juntas precisam ser todas AnimationConstraint ou todas Motor6D. Juntas misturadas não são aceitas.")
    end

    for _, partName in ipairs(MESH_RIG_2016_PARTS) do
        local part = meshParts[partName]
        local parentName = MESH_RIG_2016_PARENT[partName]
        local expectedParent = parentName == "HumanoidRootPart"
            and skeleton.rootPart
            or meshParts[parentName]

        if skeleton.jointsByPart1[partName] ~= part
            or skeleton.parentByPart1[part] ~= expectedParent then
            error(
                "Hierarquia incompatível em "
                    .. partName
                    .. ". Esperado: "
                    .. parentName
                    .. " -> "
                    .. partName
                    .. "."
            )
        end
    end

    return {
        meshParts = meshParts,
        jointType = usesAnimationConstraints and "AnimationConstraint" or "Motor6D",
    }
end

local function isSupportedJoint(instance)
    return instance:IsA("Motor6D")
        or instance:IsA("AnimationConstraint")
end

local function selectedRig()
    local items = Selection:Get()
    for _, item in ipairs(items) do
        local current = item
        while current and current ~= Workspace do
            if current:IsA("Model") then
                for _, descendant in ipairs(current:GetDescendants()) do
                    if isSupportedJoint(descendant) then
                        return current
                    end
                end
            end
            current = current.Parent
        end
    end
    return nil
end

local function getSkeleton(rig)
    local jointsByPart1 = {}
    local jointKindsByName = {}
    local childrenByPart0 = {}
    local incomingParts = {}
    local parentByPart1 = {}
    local jointInstancesByPart1 = {}
    local curveChildrenByParent = {}
    local boneChildrenByParent = {}
    local boneRoots = {}

    local hasAnimationConstraint = false
    local hasBone = false
    local hasMotor6D = false
    local partJointCount = 0
    local motor6DCount = 0
    local animationConstraintCount = 0
    local boneCount = 0
    local discoveredJointCount = 0

    local function addCurveChild(parent, child)
        curveChildrenByParent[parent] = curveChildrenByParent[parent] or {}
        table.insert(curveChildrenByParent[parent], child)
    end

    local function registerJointName(name, target)
        if jointsByPart1[name] then
            error(
                'Há mais de uma junta ou Bone com o nome "'
                    .. name
                    .. '". Renomeie os alvos para que cada canal seja único.'
            )
        end
        jointsByPart1[name] = target
    end

    for _, descendant in ipairs(rig:GetDescendants()) do
        if descendant:IsA("Bone") then
            hasBone = true
            boneCount += 1
            discoveredJointCount += 1

            local parent = descendant.Parent
            if not parent
                or (not parent:IsA("Bone") and not parent:IsA("BasePart")) then
                error(
                    "O Bone "
                        .. descendant:GetFullName()
                        .. " precisa estar dentro de outro Bone ou de uma BasePart."
                )
            end

            registerJointName(descendant.Name, descendant)
            jointKindsByName[descendant.Name] = "Bone"
            addCurveChild(parent, descendant)

            if parent:IsA("Bone") then
                boneChildrenByParent[parent] = boneChildrenByParent[parent] or {}
                table.insert(boneChildrenByParent[parent], descendant)
            else
                table.insert(boneRoots, descendant)
            end

        elseif descendant:IsA("Motor6D") or descendant:IsA("AnimationConstraint") then
            local part0
            local part1
            local jointKind

            if descendant:IsA("Motor6D") then
                jointKind = "Motor6D"
                hasMotor6D = true
                motor6DCount += 1
                part0 = descendant.Part0
                part1 = descendant.Part1
                if not part0 or not part1 then
                    error(
                        "O Motor6D "
                            .. descendant:GetFullName()
                            .. " não possui Part0 e Part1 definidos."
                    )
                end
            else
                jointKind = "AnimationConstraint"
                hasAnimationConstraint = true
                animationConstraintCount += 1
                local attachment0 = descendant.Attachment0
                local attachment1 = descendant.Attachment1
                part0 = attachment0 and attachment0.Parent
                part1 = attachment1 and attachment1.Parent

                if not part0 or not part1
                    or not part0:IsA("BasePart")
                    or not part1:IsA("BasePart") then
                    error(
                        "A AnimationConstraint "
                            .. descendant:GetFullName()
                            .. " não possui Attachments ligados a BaseParts."
                    )
                end
            end

            if not part0:IsA("BasePart")
                or not part1:IsA("BasePart")
                or not part0:IsDescendantOf(rig)
                or not part1:IsDescendantOf(rig) then
                error("Uma junta do rig conecta partes fora do Model selecionado.")
            end

            partJointCount += 1
            discoveredJointCount += 1
            registerJointName(part1.Name, part1)
            jointKindsByName[part1.Name] = jointKind

            childrenByPart0[part0] = childrenByPart0[part0] or {}
            table.insert(childrenByPart0[part0], part1)
            incomingParts[part1] = true
            parentByPart1[part1] = part0
            jointInstancesByPart1[part1.Name] = descendant
            addCurveChild(part0, part1)
        end

        if discoveredJointCount > MAX_JOINTS then
            error("O rig ultrapassa o limite de " .. MAX_JOINTS .. " juntas e Bones suportados.")
        end
    end

    if discoveredJointCount == 0 then
        error("O Model não possui Motor6D, AnimationConstraint ou Bone suportado.")
    end

    local function sortChildren(map)
        for _, children in pairs(map) do
            table.sort(children, function(a, b)
                if a.Name == b.Name then
                    return a:GetFullName() < b:GetFullName()
                end
                return a.Name < b.Name
            end)
        end
    end

    sortChildren(childrenByPart0)
    sortChildren(curveChildrenByParent)
    sortChildren(boneChildrenByParent)
    table.sort(boneRoots, function(a, b)
        return a:GetFullName() < b:GetFullName()
    end)

    local rootPart = nil
    local visitedParts = {}
    local visitedBones = {}

    if partJointCount > 0 then
        rootPart = rig:FindFirstChild("HumanoidRootPart", true)
        if not rootPart or not rootPart:IsA("BasePart") then
            rootPart = rig.PrimaryPart
        end

        if not rootPart then
            local rootCandidates = {}
            for part in pairs(childrenByPart0) do
                if not incomingParts[part] then
                    table.insert(rootCandidates, part)
                end
            end
            table.sort(rootCandidates, function(a, b)
                return a:GetFullName() < b:GetFullName()
            end)

            if #rootCandidates == 1 then
                rootPart = rootCandidates[1]
            elseif #rootCandidates > 1 then
                error("O rig possui mais de uma raiz possível. Defina PrimaryPart ou HumanoidRootPart.")
            end
        end

        if not rootPart
            or not rootPart:IsA("BasePart")
            or not rootPart:IsDescendantOf(rig) then
            error("Não foi possível identificar uma raiz válida dentro do Model.")
        end

        local function walkParts(part)
            if visitedParts[part] then
                error("A hierarquia de juntas contém um ciclo.")
            end
            visitedParts[part] = true

            for _, childPart in ipairs(childrenByPart0[part] or {}) do
                if visitedParts[childPart] then
                    error("Uma peça conectada foi encontrada em mais de uma junta ou em um ciclo.")
                end
                walkParts(childPart)
            end
        end

        walkParts(rootPart)

        local reachableParts = 0
        for _ in pairs(visitedParts) do
            reachableParts += 1
        end
        if reachableParts ~= partJointCount + 1 then
            error("A hierarquia de juntas não parte da raiz do rig. Confira Attachments, PrimaryPart e AssemblyRootPart.")
        end
    end

    local function walkBones(bone)
        if visitedBones[bone] then
            error("A hierarquia de Bones contém uma referência repetida.")
        end
        visitedBones[bone] = true

        for _, childBone in ipairs(boneChildrenByParent[bone] or {}) do
            walkBones(childBone)
        end
    end

    for _, rootBone in ipairs(boneRoots) do
        if partJointCount > 0 and not visitedParts[rootBone.Parent] then
            error(
                "O Bone raiz "
                    .. rootBone:GetFullName()
                    .. " está em uma BasePart fora da hierarquia principal do rig."
            )
        end
        walkBones(rootBone)
    end

    local reachableBones = 0
    for _ in pairs(visitedBones) do
        reachableBones += 1
    end
    if reachableBones ~= boneCount then
        error("A hierarquia de Bones possui elementos sem uma raiz válida.")
    end
    if hasBone and #boneRoots == 0 then
        error("O rig possui Bones, mas nenhum Bone raiz ligado diretamente a uma BasePart.")
    end

    local skeleton = {
        rootPart = rootPart,
        jointsByPart1 = jointsByPart1,
        jointKindsByName = jointKindsByName,
        childrenByPart0 = childrenByPart0,
        parentByPart1 = parentByPart1,
        jointInstancesByPart1 = jointInstancesByPart1,
        curveChildrenByParent = curveChildrenByParent,
        boneChildrenByParent = boneChildrenByParent,
        boneRoots = boneRoots,
        jointCount = discoveredJointCount,
        partJointCount = partJointCount,
        motor6DCount = motor6DCount,
        animationConstraintCount = animationConstraintCount,
        boneCount = boneCount,
        hasMotor6D = hasMotor6D,
        hasAnimationConstraint = hasAnimationConstraint,
        hasBone = hasBone,
        hasCurveAnimation = hasAnimationConstraint or hasBone,
    }

    validateMeshRig2016(rig, skeleton)
    return skeleton
end

local MOTION_LIBRARY_SETTING = "PosecodeMotionLibrary"
local MOTION_SEED_SETTING = "PosecodeMotionSeed"
local MAX_SAVED_MOTIONS = 48
local MOTION_FPS = 30
local MOTION_SEGMENTS = 12

local MOTION_CATALOG = {
    walk = {
        label = "Walk",
        aliases = { "walk", "walking", "walking cycle", "andar", "andando", "caminhar", "caminhada" },
        leg = 25, knee = 19, arm = 14, armBend = 7,
        lean = 2, bounce = 1.2, sway = 2.1, head = 1.2,
        periodFrames = 36, defaultSpeed = 3, asymmetry = 0,
    },
    run = {
        label = "Run",
        aliases = { "run", "running", "jog", "jogging", "correr", "correndo", "corrida" },
        leg = 34, knee = 37, arm = 22, armBend = 19,
        lean = 7, bounce = 2.6, sway = 2.6, head = 1.8,
        periodFrames = 30, defaultSpeed = 4, asymmetry = 0,
    },
    sprint = {
        label = "Sprint",
        aliases = { "sprint", "sprinting", "sprintar", "corrida rapida", "correr rapido" },
        leg = 41, knee = 48, arm = 28, armBend = 25,
        lean = 11, bounce = 3.2, sway = 2.5, head = 2.5,
        periodFrames = 24, defaultSpeed = 5, asymmetry = 0,
    },
    sneak = {
        label = "Sneak",
        aliases = { "sneak", "sneaking", "stealth", "agachar", "agachado", "agachada", "furtivo", "esgueirar" },
        leg = 12, knee = 26, arm = 6, armBend = 15,
        lean = 16, bounce = 0.4, sway = 1.3, head = 4,
        periodFrames = 48, defaultSpeed = 2, asymmetry = 0,
    },
    tiptoe = {
        label = "Tiptoe",
        aliases = { "tiptoe", "tiptoeing", "na ponta", "ponta dos pes", "pontas dos pes" },
        leg = 9, knee = 18, arm = 4, armBend = 6,
        lean = 4, bounce = 0.6, sway = 1, head = 1,
        periodFrames = 48, defaultSpeed = 2, asymmetry = 0,
    },
    march = {
        label = "March",
        aliases = { "march", "marching", "marchar", "marcha" },
        leg = 29, knee = 8, arm = 24, armBend = 3,
        lean = 1, bounce = 1.1, sway = 1.2, head = 0.5,
        periodFrames = 36, defaultSpeed = 3, asymmetry = 0,
    },
    limp = {
        label = "Limp",
        aliases = { "limp", "limping", "mancar", "mancando", "manco", "manca" },
        leg = 20, knee = 15, arm = 9, armBend = 8,
        lean = 4, bounce = 0.7, sway = 4, head = 2,
        periodFrames = 42, defaultSpeed = 2, asymmetry = 0.32,
    },
    idle = {
        label = "Idle",
        aliases = { "idle", "standing idle", "still", "parado", "parada", "respirar", "respirando", "em pe" },
        leg = 0, knee = 0, arm = 1, armBend = 3,
        lean = 0, bounce = 0.4, sway = 0.7, head = 1.2,
        periodFrames = 60, defaultSpeed = 2, asymmetry = 0,
    },
    wave = {
        label = "Wave",
        aliases = { "wave", "waving", "acenar", "aceno", "acene", "tchau" },
        leg = 0, knee = 0, arm = 0, armBend = 0,
        lean = 0, bounce = 0.1, sway = 0.5, head = 1,
        periodFrames = 60, defaultSpeed = 3, asymmetry = 0,
        gesture = "wave", rightArmRaise = 58, rightElbowBias = 46, handWave = 17,
        looped = true, priority = "Action",
    },
    salute = {
        label = "Salute",
        aliases = { "salute", "saluting", "continencia", "prestar continencia", "saudacao militar" },
        leg = 0, knee = 0, arm = 0, armBend = 0,
        lean = 0, bounce = 0, sway = 0.4, head = 1.4,
        periodFrames = 48, defaultSpeed = 3, asymmetry = 0,
        gesture = "salute", rightArmRaise = 64, rightElbowBias = 38,
        looped = false, priority = "Action",
    },
    jump = {
        label = "Jump",
        aliases = { "jump", "jumping", "pular", "pulando", "salto", "saltando" },
        leg = 0, knee = 0, arm = 0, armBend = 0,
        lean = 0, bounce = 1.8, sway = 0.8, head = 1,
        periodFrames = 36, defaultSpeed = 3, asymmetry = 0,
        gesture = "jump", jumpKnee = 44, jumpArmRaise = 28, jumpLean = 8,
        looped = false, priority = "Action",
    },
    bow = {
        label = "Bow",
        aliases = { "bow", "bowing", "reverencia", "reverenciar", "curvar o corpo" },
        leg = 0, knee = 0, arm = 1, armBend = 4,
        lean = 0, bounce = 0, sway = 0.4, head = 2,
        periodFrames = 48, defaultSpeed = 2, asymmetry = 0,
        gesture = "bow", bowAngle = 36,
        looped = false, priority = "Action",
    },
    point = {
        label = "Point",
        aliases = { "point", "pointing", "apontar", "apontando", "aponta" },
        leg = 0, knee = 0, arm = 0, armBend = 0,
        lean = 0, bounce = 0, sway = 0.5, head = 1,
        periodFrames = 42, defaultSpeed = 3, asymmetry = 0,
        gesture = "point", rightArmRaise = 49, rightElbowBias = 6,
        looped = false, priority = "Action",
    },
    clap = {
        label = "Clap",
        aliases = { "clap", "clapping", "bater palmas", "aplaudir", "aplaudindo", "palmas" },
        leg = 0, knee = 0, arm = 0, armBend = 0,
        lean = 0, bounce = 0.2, sway = 0.5, head = 1,
        periodFrames = 48, defaultSpeed = 3, asymmetry = 0,
        gesture = "clap", clapArmRaise = 34, clapPulse = 8, clapElbow = 48,
        looped = true, priority = "Action",
    },
    dance = {
        label = "Dance",
        aliases = { "dance", "dancing", "dancar", "dancando", "danca" },
        leg = 31, knee = 22, arm = 13, armBend = 14,
        lean = 2, bounce = 2.6, sway = 2.8, head = 1.5,
        periodFrames = 36, defaultSpeed = 3, asymmetry = 0.06,
        gesture = "dance", danceArmRaise = 38, handWave = 9,
        looped = true, priority = "Action",
    },
   loccrawl = {
        label = "Crawl",
        aliases = { "crawl", "crawling", "rastejar", "rastejando", "engatinhar", "engatinhando" },
        leg = 18, knee = 32, arm = 20, armBend = 24,
        lean = 27, bounce = 0.25, sway = 2.6, head = 4,
        periodFrames = 54, defaultSpeed = 2, asymmetry = 0.04,
    },
    strafe = {
        label = "Strafe",
        aliases = { "strafe", "strafing", "side step", "sideways walk", "andar de lado", "passo lateral" },
        leg = 18, knee = 15, arm = 8, armBend = 5,
        lean = 2, bounce = 0.4, sway = 4, head = 1.2,
        periodFrames = 36, defaultSpeed = 3, asymmetry = 0,
        sideways = true,
    },
    backpedal = {
        label = "Backpedal",
        aliases = { "backpedal", "backpedaling", "walk backwards", "andar de costas", "andar para tras", "recuar andando" },
        leg = 21, knee = 18, arm = 12, armBend = 10,
        lean = 7, bounce = 0.6, sway = 2, head = 1.8,
        periodFrames = 42, defaultSpeed = 3, asymmetry = 0,
        reverseStride = true, leanDirection = -1,
    },
    stretch = {
        label = "Stretch",
        aliases = { "stretch", "stretching", "alongar", "alongando", "espreguicar", "espreguicando" },
        leg = 0, knee = 0, arm = 0, armBend = 0,
        lean = 0, bounce = 0, sway = 0.4, head = 1,
        periodFrames = 48, defaultSpeed = 2, asymmetry = 0,
        gesture = "stretch", stretchRaise = 72, stretchArch = 12,
        looped = false, priority = "Action",
    },
    shrug = {
        label = "Shrug",
        aliases = { "shrug", "shrugging", "dar de ombros", "encolher os ombros", "nao sei" },
        leg = 0, knee = 0, arm = 0, armBend = 0,
        lean = 0, bounce = 0.1, sway = 0.5, head = 2,
        periodFrames = 42, defaultSpeed = 3, asymmetry = 0,
        gesture = "shrug", shrugRaise = 25, shrugElbow = 18,
        looped = false, priority = "Action",
    },
    crawl = {
        label = "Crawl",
        aliases = { "crawl", "crawling", "rastejar", "rastejando", "engatinhar", "engatinhando" },
        leg = 18, knee = 32, arm = 20, armBend = 24,
        lean = 27, bounce = 0.25, sway = 2.6, head = 4,
        periodFrames = 54, defaultSpeed = 2, asymmetry = 0.04,
    },
}

local MOTION_STYLE_ORDER = {
    "sprint", "run", "backpedal", "strafe", "crawl", "march",
    "sneak", "tiptoe", "limp", "salute", "wave", "jump",
    "bow", "point", "clap", "dance", "stretch", "shrug",
    "idle", "walk",
}
local MOOD_PROFILES = {
    tired = { speed = 2, intensity = 2, stride = 2, arms = 1, torso = 4, bounce = 1 },
    happy = { speed = 4, intensity = 3, stride = 3, arms = 3, torso = 2, bounce = 4 },
    confident = { speed = 3, intensity = 3, stride = 4, arms = 3, torso = 1, bounce = 2 },
    angry = { speed = 4, intensity = 4, stride = 4, arms = 4, torso = 3, bounce = 2 },
    heavy = { speed = 2, intensity = 3, stride = 2, arms = 2, torso = 4, bounce = 1 },
    sad = { speed = 2, intensity = 2, stride = 2, arms = 1, torso = 4, bounce = 1 },
    robotic = { speed = 3, intensity = 3, stride = 3, arms = 2, torso = 2, bounce = 1, easing = 1 },
    exaggerated = { speed = 3, intensity = 5, stride = 5, arms = 4, torso = 4, bounce = 4 },
    casual = { speed = 3, intensity = 2, stride = 3, arms = 2, torso = 2, bounce = 2 },
    sleepy = { speed = 1, intensity = 1, stride = 2, arms = 1, torso = 4, bounce = 1, easing = 2 },
    nervous = { speed = 4, intensity = 2, stride = 2, arms = 3, torso = 3, bounce = 2 },
    proud = { speed = 3, intensity = 3, stride = 4, arms = 3, torso = 1, bounce = 2 },
    curious = { speed = 2, intensity = 2, stride = 2, arms = 2, torso = 2, bounce = 1 },
    playful = { speed = 4, intensity = 3, stride = 4, arms = 4, torso = 2, bounce = 4 },
    serious = { speed = 3, intensity = 2, stride = 3, arms = 1, torso = 1, bounce = 0 },
    relaxed = { speed = 2, intensity = 1, stride = 3, arms = 1, torso = 2, bounce = 1 },
}
local MOOD_LABELS = {
    tired = "cansado",
    happy = "feliz",
    confident = "confiante",
    angry = "intenso",
    heavy = "pesado",
    sad = "abatido",
    robotic = "robotico",
    exaggerated = "exagerado",
    casual = "casual",
    sleepy = "sonolento",
    nervous = "nervoso",
    proud = "orgulhoso",
    curious = "curioso",
    playful = "brincalhao",
    serious = "serio",
    relaxed = "relaxado",
}
local SPEED_FACTORS = { 1.66, 1.33, 1, 0.67, 0.4 }
local INTENSITY_FACTORS = { 0.55, 0.75, 1, 1.2, 1.4 }
local STRIDE_FACTORS = { 0.6, 0.8, 1, 1.2, 1.4 }
local ARM_FACTORS = { 0.45, 0.7, 1, 1.3 }
local TORSO_FACTORS = { 0.45, 0.75, 1.05, 1.4 }
local BOUNCE_FACTORS = { 0, 0.5, 1, 1.45 }
local EASING_OPTIONS = {
    [1] = { style = "Linear", direction = "InOut" },
    [2] = { style = "CubicV2", direction = "InOut" },
    [3] = { style = "Constant", direction = "InOut" },
}
function motionEngine.cleanPrompt(value)
    local result = tostring(value or "")
    result = result:gsub("[\r\n\t]", " ")
    result = result:gsub("\\", "")
    result = result:gsub('"', "")
    result = result:gsub("%s+", " ")
    result = result:gsub("^%s+", ""):gsub("%s+$", "")
    return string.sub(result, 1, 96)
end

function motionEngine.normalizeText(value)
    local result = tostring(value or "")
    local replacements = {
        { "Á", "a" }, { "À", "a" }, { "Ã", "a" }, { "Â", "a" },
        { "É", "e" }, { "Ê", "e" }, { "Í", "i" },
        { "Ó", "o" }, { "Ô", "o" }, { "Õ", "o" },
        { "Ú", "u" }, { "Ç", "c" },
        { "á", "a" }, { "à", "a" }, { "ã", "a" }, { "â", "a" },
        { "é", "e" }, { "ê", "e" }, { "í", "i" },
        { "ó", "o" }, { "ô", "o" }, { "õ", "o" },
        { "ú", "u" }, { "ç", "c" },
    }
    for _, replacement in ipairs(replacements) do
        result = result:gsub(replacement[1], replacement[2])
    end
    result = string.lower(result)
    result = result:gsub("[^%w%s%-]", " ")
    result = result:gsub("%s+", " ")
    return " " .. result .. " "
end

function motionEngine.hasAny(text, terms)
    for _, term in ipairs(terms) do
        if string.find(text, " " .. term .. " ", 1, true) then
            return true
        end
    end
    return false
end

function motionEngine.nextSeed()
    local previous = 0
    local readOk, stored = pcall(function()
        return plugin:GetSetting(MOTION_SEED_SETTING)
    end)
    if readOk and typeof(stored) == "number" then
        previous = stored
    end
    local nextValue = (math.floor(previous) % 999999) + 1
    pcall(function()
        plugin:SetSetting(MOTION_SEED_SETTING, nextValue)
    end)
    return nextValue
end

function motionEngine.copyRecipe(recipe)
    local copy = {}
    for key, value in pairs(recipe or {}) do
        copy[key] = value
    end
    return copy
end

function motionEngine.parsePrompt(prompt)
    local text = motionEngine.normalizeText(prompt)
    local result = {
        base = "walk",
        mood = nil,
        explicit = {},
        values = {},
    }

    local recognizedBase = false
    for _, styleName in ipairs(MOTION_STYLE_ORDER) do
        if motionEngine.hasAny(text, MOTION_CATALOG[styleName].aliases) then
            result.base = styleName
            recognizedBase = true
            break
        end
    end
    if not recognizedBase then
        error("Não reconheci o movimento. Tente walk, run, sprint, sneak, crawl, wave, jump, dance ou outro tipo da biblioteca.")
    end

    local moodAliases = {
        { "tired", { "cansado", "cansada", "com sono", "exausto", "exausta", "tired" } },
        { "happy", { "feliz", "alegre", "animado", "animada", "happy" } },
        { "confident", { "confiante", "seguro", "segura", "confident" } },
        { "angry", { "bravo", "brava", "irritado", "irritada", "furioso", "furiosa", "angry" } },
        { "heavy", { "pesado", "pesada", "heavy" } },
        { "sad", { "triste", "abatido", "abatida", "sad" } },
        { "robotic", { "robotico", "robotica", "mecanico", "mecanica", "robotic" } },
        { "exaggerated", { "exagerado", "exagerada", "exagerado", "exaggerated" } },
        { "casual", { "casual" } },
        { "sleepy", { "sleepy", "sonolento", "sonolenta", "com sono" } },
        { "nervous", { "nervous", "nervoso", "nervosa", "ansioso", "ansiosa" } },
        { "proud", { "proud", "orgulhoso", "orgulhosa", "peito estufado" } },
        { "curious", { "curious", "curioso", "curiosa" } },
        { "playful", { "playful", "brincalhao", "brincalhona", "divertido" } },
        { "serious", { "serious", "serio", "seria" } },
        { "relaxed", { "relaxed", "relaxado", "relaxada", "tranquilo", "tranquila" } },
    }
    for _, moodEntry in ipairs(moodAliases) do
        if motionEngine.hasAny(text, moodEntry[2]) then
            result.mood = moodEntry[1]
            break
        end
    end

    local function setValue(name, value)
        result.values[name] = value
        result.explicit[name] = true
    end

    if motionEngine.hasAny(text, { "muito devagar", "bem devagar", "bem lento", "quase parando", "very slow", "extremely slow" }) then
        setValue("speed", 1)
    elseif motionEngine.hasAny(text, { "devagar", "lento", "lenta", "slow" }) then
        setValue("speed", 2)
    elseif motionEngine.hasAny(text, { "muito rapido", "muito veloz", "super rapido", "explosivo", "very fast", "extremely fast" }) then
        setValue("speed", 5)
    elseif motionEngine.hasAny(text, { "rapido", "rapida", "veloz", "fast" }) then
        setValue("speed", 4)
    end

    if motionEngine.hasAny(text, { "muito sutil", "bem suave", "suave", "subtle", "sutil" }) then
        setValue("intensity", 1)
    elseif motionEngine.hasAny(text, { "leve", "low intensity" }) then
        setValue("intensity", 2)
    elseif motionEngine.hasAny(text, { "muito forte", "muito intenso", "extremo", "exagerado", "exagerada" }) then
        setValue("intensity", 5)
    elseif motionEngine.hasAny(text, { "forte", "intenso", "intensa" }) then
        setValue("intensity", 4)
    end

    if motionEngine.hasAny(text, { "passos muito curtos", "passo muito curto", "tiny steps", "very short stride" }) then
        setValue("stride", 1)
    elseif motionEngine.hasAny(text, { "passos curtos", "passo curto", "curto", "short stride" }) then
        setValue("stride", 2)
    elseif motionEngine.hasAny(text, { "passos largos", "passada larga", "passos longos", "long stride", "wide stride" }) then
        setValue("stride", 5)
    elseif motionEngine.hasAny(text, { "passo longo", "passadas longas" }) then
        setValue("stride", 4)
    end

    if motionEngine.hasAny(text, { "bracos soltos", "bracos relaxados", "relaxed arms", "arms loose" }) then
        setValue("arms", 1)
    elseif motionEngine.hasAny(text, { "bracos leves", "soft arm swing" }) then
        setValue("arms", 2)
    elseif motionEngine.hasAny(text, { "bracos fortes", "bracos exagerados", "strong arm swing" }) then
        setValue("arms", 4)
    end

    if motionEngine.hasAny(text, { "postura ereta", "corpo ereto", "upright", "peito aberto" }) then
        setValue("torso", 1)
    elseif motionEngine.hasAny(text, { "postura neutra", "corpo neutro", "neutral torso" }) then
        setValue("torso", 2)
    elseif motionEngine.hasAny(text, { "muito inclinado", "bem curvado", "deep lean" }) then
        setValue("torso", 4)
    elseif motionEngine.hasAny(text, { "inclinado", "curvado", "forward lean" }) then
        setValue("torso", 3)
    end

    if motionEngine.hasAny(text, { "sem quicar", "sem salto", "no bounce" }) then
        setValue("bounce", 1)
    elseif motionEngine.hasAny(text, { "pouco quique", "low bounce" }) then
        setValue("bounce", 2)
    elseif motionEngine.hasAny(text, { "muito saltitante", "saltitante", "bouncy" }) then
        setValue("bounce", 4)
    end

    if motionEngine.hasAny(text, { "de costas", "para tras", "backwards", "backward", "reverse" }) then
        setValue("direction", -1)
    end

    if motionEngine.hasAny(text, { "robotico", "robotica", "mecanico", "mecanica", "linear", "robotic" }) then
        setValue("easing", 1)
    elseif motionEngine.hasAny(text, { "travado", "em blocos", "stepped", "constant" }) then
        setValue("easing", 3)
    elseif motionEngine.hasAny(text, { "suave", "smooth", "fluido", "fluida" }) then
        setValue("easing", 2)
    end

    return result
end

function motionEngine.loadLibrary()
    motionEngine.recipes = {}
    local ok, stored = pcall(function()
        return plugin:GetSetting(MOTION_LIBRARY_SETTING)
    end)
    if not ok or typeof(stored) ~= "table" then
        return
    end

    local count = math.clamp(math.floor(tonumber(stored.count) or 0), 0, MAX_SAVED_MOTIONS)
    for index = 1, count do
        local entry = stored["entry" .. tostring(index)]
        if typeof(entry) == "table"
            and typeof(entry.prompt) == "string"
            and MOTION_CATALOG[entry.base] then
            table.insert(motionEngine.recipes, {
                prompt = motionEngine.cleanPrompt(entry.prompt),
                name = motionEngine.cleanPrompt(entry.name or entry.prompt),
                base = entry.base,
                mood = typeof(entry.mood) == "string" and entry.mood ~= "" and entry.mood or nil,
                speed = math.clamp(math.floor(tonumber(entry.speed) or 3), 1, 5),
                intensity = math.clamp(math.floor(tonumber(entry.intensity) or 3), 1, 5),
                stride = math.clamp(math.floor(tonumber(entry.stride) or 3), 1, 5),
                arms = math.clamp(math.floor(tonumber(entry.arms) or 3), 1, 4),
                torso = math.clamp(math.floor(tonumber(entry.torso) or 2), 1, 4),
                bounce = math.clamp(math.floor(tonumber(entry.bounce) or 3), 1, 4),
                direction = tonumber(entry.direction) == -1 and -1 or 1,
                easing = math.clamp(math.floor(tonumber(entry.easing) or 2), 1, 3),
                seed = math.clamp(math.floor(tonumber(entry.seed) or 1), 1, 999999),
            })
        end
    end
end

function motionEngine.persistLibrary()
    local payload = { count = #motionEngine.recipes }
    for index, recipe in ipairs(motionEngine.recipes) do
        payload["entry" .. tostring(index)] = {
            prompt = motionEngine.cleanPrompt(recipe.prompt),
            name = motionEngine.cleanPrompt(recipe.name),
            base = recipe.base,
            mood = recipe.mood or "",
            speed = recipe.speed,
            intensity = recipe.intensity,
            stride = recipe.stride,
            arms = recipe.arms,
            torso = recipe.torso,
            bounce = recipe.bounce,
            direction = recipe.direction,
            easing = recipe.easing,
            seed = recipe.seed,
        }
    end

    local ok, message = pcall(function()
        plugin:SetSetting(MOTION_LIBRARY_SETTING, payload)
    end)
    if not ok then
        setStatus("Não consegui gravar a biblioteca local: " .. tostring(message), C.red)
        return false
    end

    local verifyOk, stored = pcall(function()
        return plugin:GetSetting(MOTION_LIBRARY_SETTING)
    end)
    if not verifyOk
        or typeof(stored) ~= "table"
        or tonumber(stored.count) ~= #motionEngine.recipes then
        setStatus("O Studio não confirmou a gravação da biblioteca. Tente novamente.", C.red)
        return false
    end

    if #motionEngine.recipes > 0 then
        local firstSaved = stored.entry1
        local firstExpected = motionEngine.recipes[1]
        if typeof(firstSaved) ~= "table"
            or firstSaved.prompt ~= firstExpected.prompt
            or firstSaved.base ~= firstExpected.base
            or tonumber(firstSaved.seed) ~= tonumber(firstExpected.seed) then
            setStatus("A biblioteca foi gravada, mas a leitura de confirmação não bateu. Tente novamente.", C.red)
            return false
        end
    end

    return true
end

function motionEngine.renderLibrary()
    for _, child in ipairs(libraryList:GetChildren()) do
        child:Destroy()
    end

    libraryHeading.Text = string.format("%d / %d REFERÊNCIAS", #motionEngine.recipes, MAX_SAVED_MOTIONS)
    if #motionEngine.recipes == 0 then
        local empty = label(
            libraryList,
            "Depois de testar uma animação, guarde-a como referência.",
            UDim2.fromOffset(0, 5),
            UDim2.new(1, 0, 0, 28),
            9,
            C.muted
        )
        empty.TextWrapped = true
        return
    end

    for index = 1, math.min(3, #motionEngine.recipes) do
        local recipe = motionEngine.recipes[index]
        local row = button(
            libraryList,
            recipe.name,
            UDim2.fromOffset(0, (index - 1) * 28),
            UDim2.new(1, 0, 0, 24),
            false
        )
        row.TextSize = 9
        row.Activated:Connect(function()
            promptBox.Text = recipe.prompt
            motionEngine.run(recipe.prompt, motionEngine.copyRecipe(recipe))
        end)
    end
end

function motionEngine.findReference(parsed)
    local best = nil
    local bestScore = 0
    for _, saved in ipairs(motionEngine.recipes) do
        if saved.base == parsed.base then
            local score = 10
            if saved.mood == parsed.mood then
                score += 10
            elseif parsed.mood == nil and saved.mood == nil then
                score += 10
            else
                score -= 5
            end
            if score > bestScore then
                best = saved
                bestScore = score
            end
        end
    end
    return best
end

function motionEngine.resolveRecipe(prompt, forcedRecipe)
    if forcedRecipe then
        local recipe = motionEngine.copyRecipe(forcedRecipe)
        recipe.prompt = motionEngine.cleanPrompt(prompt)
        recipe.seed = recipe.seed or motionEngine.nextSeed()
        return recipe, nil
    end

    local parsed = motionEngine.parsePrompt(prompt)
    local base = MOTION_CATALOG[parsed.base]
    local mood = parsed.mood and MOOD_PROFILES[parsed.mood] or nil
    local recipe = {
        prompt = motionEngine.cleanPrompt(prompt),
        base = parsed.base,
        mood = parsed.mood,
        speed = base.defaultSpeed or 3,
        intensity = 3,
        stride = 3,
        arms = 3,
        torso = 2,
        bounce = 3,
        direction = 1,
        easing = 2,
    }

    if mood then
        for key, value in pairs(mood) do
            recipe[key] = value
        end
    end

    local reference = motionEngine.findReference(parsed)
    if reference and (reference.mood == parsed.mood) then
        for _, field in ipairs({ "speed", "intensity", "stride", "arms", "torso", "bounce", "direction", "easing" }) do
            if not parsed.explicit[field] then
                recipe[field] = reference[field]
            end
        end
        recipe.referenceName = reference.name
    end

    for field, value in pairs(parsed.values) do
        recipe[field] = value
    end

    recipe.seed = motionEngine.nextSeed()
    local moodLabel = recipe.mood and (" · " .. (MOOD_LABELS[recipe.mood] or recipe.mood)) or ""
    recipe.name = base.label .. moodLabel
    return recipe, reference
end

function motionEngine.buildDocument(recipe, skeleton)
    local base = MOTION_CATALOG[recipe.base]
    if not base then
        error("Não encontrei o movimento-base solicitado.")
    end

    local intensity = INTENSITY_FACTORS[recipe.intensity] or 1
    local stride = STRIDE_FACTORS[recipe.stride] or 1
    local arms = ARM_FACTORS[recipe.arms] or 1
    local torso = TORSO_FACTORS[recipe.torso] or 1
    local bounce = BOUNCE_FACTORS[recipe.bounce] or 1

    local moodLean = 0
    local headDrop = 0
    if recipe.mood == "tired" then
        moodLean = 5
        headDrop = 4
    elseif recipe.mood == "sad" then
        moodLean = 5
        headDrop = 6
    elseif recipe.mood == "confident" then
        moodLean = -1.5
    elseif recipe.mood == "angry" then
        moodLean = 3
    elseif recipe.mood == "heavy" then
        moodLean = 4
        headDrop = 2
    elseif recipe.mood == "happy" then
        headDrop = -1
    end

    local random = Random.new(recipe.seed or 1)
    local phaseOffset = random:NextNumber(-0.055, 0.055)
    local swingVariance = random:NextNumber(0.96, 1.04)
    local leanVariance = random:NextNumber(0.96, 1.04)

    local cycleFrames = math.clamp(
        math.floor((base.periodFrames * (SPEED_FACTORS[recipe.speed] or 1) / MOTION_SEGMENTS) + 0.5)
            * MOTION_SEGMENTS,
        MOTION_SEGMENTS,
        60
    )
    local duration = cycleFrames / MOTION_FPS
    local easing = EASING_OPTIONS[recipe.easing] or EASING_OPTIONS[2]
    local jointNames = {
        "Head", "UpperTorso", "LowerTorso",
        "LeftUpperArm", "LeftLowerArm", "LeftHand",
        "RightUpperArm", "RightLowerArm", "RightHand",
        "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
        "RightUpperLeg", "RightLowerLeg", "RightFoot",
    }
    local tracksByName = {}

    for _, jointName in ipairs(jointNames) do
        local targetType = skeleton.jointKindsByName[jointName]
        if not targetType then
            error("O Mesh Rig 2016 selecionado não possui o canal " .. jointName .. ".")
        end
        tracksByName[jointName] = {
            target = { type = targetType, name = jointName },
            keys = {},
        }
    end

    local legAmplitude = base.leg * intensity * stride * swingVariance
    local kneeAmplitude = base.knee * intensity * stride
    local armAmplitude = base.arm * intensity * arms * swingVariance
    local leanAngle = (base.lean * torso + moodLean) * leanVariance * (base.leanDirection or 1)
    local asymmetry = base.asymmetry or 0
    if recipe.mood == "tired" then
        asymmetry += 0.08
    end
    if recipe.direction == -1 then
        leanAngle = -leanAngle * 0.45
    end

    for step = 0, MOTION_SEGMENTS do
        local phase = (math.pi * 2 * step / MOTION_SEGMENTS) * (recipe.direction or 1) + phaseOffset
        local sine = math.sin(phase)
        local cosine = math.cos(phase)
        local progress = step / MOTION_SEGMENTS
        local actionPulse = math.sin(math.pi * progress)
        local gaitPhase = base.reverseStride and -phase or phase
        local gaitSine = math.sin(gaitPhase)
        local rightSwing = gaitSine * legAmplitude * (1 + asymmetry)
        local leftSwing = -gaitSine * legAmplitude * (1 - asymmetry)
        local rightKnee = math.max(0, math.sin(gaitPhase + math.pi * 0.5)) * kneeAmplitude
        local leftKnee = math.max(0, math.sin(gaitPhase - math.pi * 0.5)) * kneeAmplitude
        local armSwingRight = -sine * armAmplitude
        local armSwingLeft = sine * armAmplitude
        local armBendRight = base.armBend + math.max(0, math.sin(phase + math.pi * 0.5)) * base.armBend * 0.42
        local armBendLeft = base.armBend + math.max(0, math.sin(phase - math.pi * 0.5)) * base.armBend * 0.42
        local leftArmRaise = 0
        local rightArmRaise = 0
        local leftElbowBias = 0
        local rightElbowBias = 0
        local handWave = 0
        local torsoAction = 0
        local kneeAction = 0
        local bodyBob = math.sin(phase * 2) * base.bounce * bounce

        if base.gesture == "wave" then
            rightArmRaise = ((base.rightArmRaise or 0) + math.sin(phase * 2) * 3) * arms
            rightElbowBias = (base.rightElbowBias or 0) * arms
            handWave = math.sin(phase * 2) * (base.handWave or 0)
        elseif base.gesture == "salute" then
            rightArmRaise = (base.rightArmRaise or 0) * actionPulse * arms
            rightElbowBias = (base.rightElbowBias or 0) * actionPulse * arms
        elseif base.gesture == "jump" then
            kneeAction = (base.jumpKnee or 0) * actionPulse * intensity * stride
            local armLift = (base.jumpArmRaise or 0) * actionPulse * arms
            leftArmRaise = -armLift
            rightArmRaise = armLift
            torsoAction = -(base.jumpLean or 0) * actionPulse * torso
            bodyBob = base.bounce * bounce * actionPulse
        elseif base.gesture == "bow" then
            torsoAction = (base.bowAngle or 0) * actionPulse * torso
        elseif base.gesture == "point" then
            rightArmRaise = (base.rightArmRaise or 0) * actionPulse * arms
            rightElbowBias = (base.rightElbowBias or 0) * actionPulse * arms
        elseif base.gesture == "clap" then
            local clap = math.sin(phase * 2) * (base.clapPulse or 0)
            leftArmRaise = -((base.clapArmRaise or 0) + clap) * arms
            rightArmRaise = ((base.clapArmRaise or 0) + clap) * arms
            leftElbowBias = (base.clapElbow or 0) * arms
            rightElbowBias = (base.clapElbow or 0) * arms
            handWave = math.sin(phase * 2) * 3
        elseif base.gesture == "dance" then
            leftArmRaise = math.max(0, sine) * (base.danceArmRaise or 0) * arms
            rightArmRaise = math.max(0, -sine) * (base.danceArmRaise or 0) * arms
            handWave = math.sin(phase * 2) * (base.handWave or 0)
        elseif base.gesture == "stretch" then
            leftArmRaise = -(base.stretchRaise or 0) * arms * actionPulse
            rightArmRaise = (base.stretchRaise or 0) * arms * actionPulse
            torsoAction = -(base.stretchArch or 0) * torso * actionPulse
        elseif base.gesture == "shrug" then
            leftArmRaise = -(base.shrugRaise or 0) * arms * actionPulse
            rightArmRaise = (base.shrugRaise or 0) * arms * actionPulse
            leftElbowBias = (base.shrugElbow or 0) * arms * actionPulse
            rightElbowBias = (base.shrugElbow or 0) * arms * actionPulse
        end

        local torsoYaw = base.sideways and math.sin(phase) * 12 * (recipe.direction or 1) or 0
        local bodySway = sine * base.sway * intensity
        local bodyRoll = cosine * base.sway * 0.42
        local rightFoot = -rightSwing * 0.18 - (rightKnee + kneeAction) * 0.42
        local leftFoot = -leftSwing * 0.18 - (leftKnee + kneeAction) * 0.42

        local rotations = {
            Head = { headDrop - bodyBob * 0.35, -bodySway * 0.08 - torsoYaw * 0.12, -bodyRoll * 0.25 },
            UpperTorso = { -leanAngle + bodyBob - torsoAction, bodySway * 0.18 + torsoYaw, bodyRoll },
            LowerTorso = { leanAngle * 0.22 + torsoAction * 0.18, bodySway * 0.12 + torsoYaw * 0.35, -bodyRoll * 0.32 },
            LeftUpperArm = { armSwingLeft, 0, -base.sway * 0.18 + leftArmRaise },
            LeftLowerArm = { armBendLeft + leftElbowBias, 0, 0 },
            LeftHand = { 0, 0, math.sin(phase + math.pi * 0.5) * 2.2 * arms - handWave },
            RightUpperArm = { armSwingRight, 0, base.sway * 0.18 + rightArmRaise },
            RightLowerArm = { armBendRight + rightElbowBias, 0, 0 },
            RightHand = { 0, 0, math.sin(phase - math.pi * 0.5) * 2.2 * arms + handWave },
            LeftUpperLeg = { leftSwing, 0, -asymmetry * 2 },
            LeftLowerLeg = { leftKnee + kneeAction, 0, 0 },
            LeftFoot = { leftFoot, 0, 0 },
            RightUpperLeg = { rightSwing, 0, asymmetry * 2 },
            RightLowerLeg = { rightKnee + kneeAction, 0, 0 },
            RightFoot = { rightFoot, 0, 0 },
        }

        local time = (cycleFrames * step / MOTION_SEGMENTS) / MOTION_FPS
        for _, jointName in ipairs(jointNames) do
            local rotation = rotations[jointName]
            table.insert(tracksByName[jointName].keys, {
                time = time,
                transform = {
                    rotation = {
                        rotation[1],
                        rotation[2],
                        rotation[3],
                    },
                },
            })
        end
    end

    local tracks = {}
    for _, jointName in ipairs(jointNames) do
        table.insert(tracks, tracksByName[jointName])
    end

    local safeName = ("PC_" .. recipe.base .. (recipe.mood and ("_" .. recipe.mood) or "") .. "_" .. tostring(recipe.seed or 1))
    local description = "Gerado por descrição: " .. motionEngine.cleanPrompt(recipe.prompt)
    if recipe.referenceName then
        description = description .. " | referência: " .. motionEngine.cleanPrompt(recipe.referenceName)
    end

    return {
        format = "POSECODE",
        version = 2,
        metadata = {
            name = string.sub(safeName, 1, 64),
            author = "POSECODE Generator",
            description = string.sub(description, 1, 256),
        },
        rig = { profile = "R15" },
        timeline = {
            fps = MOTION_FPS,
            duration = duration,
            looped = base.looped ~= false,
            priority = base.priority or (recipe.base == "idle" and "Idle" or (base.gesture and "Action" or "Movement")),
            rotationSpace = "character",
            defaultEasing = {
                style = easing.style,
                direction = easing.direction,
            },
        },
        tracks = tracks,
        events = {},
    }
end

function motionEngine.saveCurrentReference()
    local recipe = motionEngine.lastGeneratedRecipe
    if not recipe
        or not importedSequence
        or importedRig ~= selectedRigCache
        or motionEngine.cleanPrompt(promptBox.Text) ~= recipe.prompt then
        setStatus("Gere e confira uma animação antes de guardar a referência.", C.red)
        return
    end

    local saved = motionEngine.copyRecipe(recipe)
    saved.prompt = motionEngine.cleanPrompt(saved.prompt)
    saved.name = motionEngine.cleanPrompt(saved.name or saved.prompt)
    for index, existing in ipairs(motionEngine.recipes) do
        if existing.base == saved.base and existing.mood == saved.mood and existing.prompt == saved.prompt then
            table.remove(motionEngine.recipes, index)
            break
        end
    end
    table.insert(motionEngine.recipes, 1, saved)
    while #motionEngine.recipes > MAX_SAVED_MOTIONS do
        table.remove(motionEngine.recipes)
    end

    if motionEngine.persistLibrary() then
        motionEngine.renderLibrary()
        setStatus("Referência aprovada e guardada na biblioteca local.", C.green)
    end
end

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

local function transformCharacterRotationToJointSpace(transform, jointName, skeleton)
    local joint = skeleton.jointInstancesByPart1[jointName]
    if not joint then
        error("Não encontrei a junta do alvo " .. jointName .. ".")
    end

    local jointWorldFrame
    if joint:IsA("AnimationConstraint") then
        local attachment0 = joint.Attachment0
        if not attachment0 or not attachment0.Parent or not attachment0.Parent:IsA("BasePart") then
            error("A junta " .. jointName .. " não possui Attachment0 válido.")
        end
        jointWorldFrame = attachment0.WorldCFrame
    elseif joint:IsA("Motor6D") then
        if not joint.Part0 then
            error("A junta " .. jointName .. " não possui Part0 válido.")
        end
        jointWorldFrame = joint.Part0.CFrame * joint.C0
    else
        error("Tipo de junta não suportado para conversão de eixos.")
    end

    local characterBasis = skeleton.rootPart.CFrame.Rotation
    local requestedWorldRotation = characterBasis
        * transform.Rotation
        * characterBasis:Inverse()
    local jointLocalRotation = jointWorldFrame.Rotation:Inverse()
        * requestedWorldRotation
        * jointWorldFrame.Rotation

    return CFrame.new(transform.Position) * jointLocalRotation
end

local function normalizeV2Data(data, skeleton)
    if typeof(data) ~= "table" or data.format ~= "POSECODE" or data.version ~= 2 then
        error("O normalizador recebeu um documento que não é POSECODE V2.")
    end

    local metadata = data.metadata
    local rigData = data.rig
    local timeline = data.timeline
    if typeof(metadata) ~= "table" then
        error('V2 precisa de um objeto "metadata".')
    end
    if typeof(rigData) ~= "table" then
        error('V2 precisa de um objeto "rig".')
    end
    if typeof(timeline) ~= "table" then
        error('V2 precisa de um objeto "timeline".')
    end

    local name = metadata.name
    if typeof(name) ~= "string" or name:match("^%s*$") or #name > 64 then
        error('metadata.name precisa ter entre 1 e 64 caracteres.')
    end
    if metadata.author ~= nil
        and (typeof(metadata.author) ~= "string" or #metadata.author > 64) then
        error('metadata.author precisa ser texto com até 64 caracteres.')
    end
    if metadata.description ~= nil
        and (typeof(metadata.description) ~= "string" or #metadata.description > 256) then
        error('metadata.description precisa ser texto com até 256 caracteres.')
    end

    local rigProfile = rigData.profile
    if rigProfile ~= "R15" then
        error('O POSECODE 3.0 aceita somente rig.profile = "R15" no Mesh Rig 2016.')
    end

    if not isFiniteNumber(timeline.fps)
        or timeline.fps < 1
        or timeline.fps > 60
        or timeline.fps % 1 ~= 0 then
        error("timeline.fps precisa ser um inteiro entre 1 e 60.")
    end
    if not isFiniteNumber(timeline.duration)
        or timeline.duration <= 0
        or timeline.duration > MAX_DURATION then
        error("timeline.duration precisa estar entre 0 e 15 segundos.")
    end
    if timeline.looped ~= nil and typeof(timeline.looped) ~= "boolean" then
        error("timeline.looped precisa ser true ou false.")
    end
    if timeline.priority ~= nil and typeof(timeline.priority) ~= "string" then
        error("timeline.priority precisa ser texto.")
    end

    local rotationSpace = timeline.rotationSpace or "joint"
    if rotationSpace ~= "joint" and rotationSpace ~= "character" then
        error('timeline.rotationSpace precisa ser "joint" ou "character".')
    end

    local defaultEasing = timeline.defaultEasing
    if defaultEasing == nil then
        defaultEasing = {}
    end
    if typeof(defaultEasing) ~= "table" then
        error("timeline.defaultEasing precisa ser um objeto.")
    end
    local defaultEasingStyle = defaultEasing.style or "Linear"
    local defaultEasingDirection = defaultEasing.direction or "InOut"
    if typeof(defaultEasingStyle) ~= "string"
        or typeof(defaultEasingDirection) ~= "string" then
        error("O easing padrão precisa conter style e direction como texto.")
    end

    local tracks = data.tracks
    local trackCount = arrayLength(tracks, "tracks", MAX_JOINTS)
    if trackCount < 1 then
        error("V2 precisa ter pelo menos uma track.")
    end

    local framesByTime = {}
    local seenTargets = {}
    local optimizedKeyCount = 0
    local durationFrames = math.floor(timeline.duration * timeline.fps + 0.5)

    local function normalizeTime(time, sourceLabel)
        if not isFiniteNumber(time) or time < 0 or time > timeline.duration then
            error(sourceLabel .. " precisa estar dentro de timeline.duration.")
        end
        local frameNumber = math.floor(time * timeline.fps + 0.5)
        if frameNumber > durationFrames then
            error(sourceLabel .. " ultrapassa o último quadro depois do ajuste ao FPS.")
        end
        return frameNumber / timeline.fps
    end

    local function getFrame(time)
        local frame = framesByTime[time]
        if not frame then
            frame = {
                time = time,
                joints = {},
            }
            framesByTime[time] = frame
        end
        return frame
    end

    for trackIndex, track in ipairs(tracks) do
        if typeof(track) ~= "table" or typeof(track.target) ~= "table" then
            error("Track " .. trackIndex .. " precisa ter um objeto target.")
        end

        local targetType = track.target.type
        local targetName = track.target.name
        if targetType ~= "Motor6D" and targetType ~= "AnimationConstraint" then
            error('Track ' .. trackIndex .. ' tem target.type inválido. Use "Motor6D" ou "AnimationConstraint".')
        end
        if typeof(targetName) ~= "string" or targetName:match("^%s*$") then
            error("Track " .. trackIndex .. " precisa informar target.name.")
        end
        if seenTargets[targetName] then
            error('O alvo "' .. targetName .. '" aparece em mais de uma track. Cada canal deve ter apenas uma track.')
        end
        seenTargets[targetName] = true

        if not skeleton.jointsByPart1[targetName] then
            error('O alvo "' .. targetName .. '" não existe no rig selecionado.')
        end
        if skeleton.jointKindsByName[targetName] ~= targetType then
            error(
                'O alvo "'
                    .. targetName
                    .. '" não é do tipo '
                    .. targetType
                    .. ". Tipo encontrado: "
                    .. tostring(skeleton.jointKindsByName[targetName])
                    .. "."
            )
        end

        local keys = track.keys
        local keyCount = arrayLength(keys, "keys da track " .. trackIndex, MAX_FRAMES)
        if keyCount < 1 then
            error("Cada track precisa ter pelo menos um keyframe.")
        end

        local seenTrackTimes = {}
        local parsedKeys = {}
        for keyIndex, key in ipairs(keys) do
            if typeof(key) ~= "table" or typeof(key.transform) ~= "table" then
                error("Keyframe " .. keyIndex .. " da track " .. trackIndex .. " precisa ter transform.")
            end
            if key.transform.position == nil and key.transform.rotation == nil then
                error("key.transform precisa ter position, rotation ou ambos.")
            end
            local time = normalizeTime(key.time, "O time de um keyframe")
            if seenTrackTimes[time] then
                error('A track "' .. targetName .. '" possui dois keyframes no mesmo quadro após o ajuste ao FPS.')
            end
            seenTrackTimes[time] = true

            local easing = key.easing
            local easingStyle = defaultEasingStyle
            local easingDirection = defaultEasingDirection
            if easing ~= nil then
                if typeof(easing) ~= "table"
                    or typeof(easing.style) ~= "string"
                    or typeof(easing.direction) ~= "string" then
                    error("key.easing precisa conter style e direction como texto.")
                end
                easingStyle = easing.style
                easingDirection = easing.direction
            end

            table.insert(parsedKeys, {
                time = time,
                transform = key.transform,
                easingStyle = easingStyle,
                easingDirection = easingDirection,
            })
        end

        table.sort(parsedKeys, function(a, b)
            return a.time < b.time
        end)

        local optimizedKeys = {}
        local keyCursor = 1
        while keyCursor <= #parsedKeys do
            local runEnd = keyCursor
            local referenceTransform = transformFromData(parsedKeys[keyCursor].transform)

            while runEnd < #parsedKeys
                and transformFromData(parsedKeys[runEnd + 1].transform) == referenceTransform do
                runEnd += 1
            end

            local runLength = runEnd - keyCursor + 1
            if runLength >= 3 then
                table.insert(optimizedKeys, parsedKeys[keyCursor])
                table.insert(optimizedKeys, parsedKeys[runEnd])
                optimizedKeyCount += runLength - 2
            else
                for index = keyCursor, runEnd do
                    table.insert(optimizedKeys, parsedKeys[index])
                end
            end
            keyCursor = runEnd + 1
        end

        for _, parsedKey in ipairs(optimizedKeys) do
            local frame = getFrame(parsedKey.time)
            if frame.easingStyle ~= nil
                and (frame.easingStyle ~= parsedKey.easingStyle
                    or frame.easingDirection ~= parsedKey.easingDirection) then
                error(
                    "Tracks com keyframes no mesmo instante precisam usar o mesmo easing. "
                        .. "Ajuste key.easing ou timeline.defaultEasing."
                )
            end
            frame.easingStyle = parsedKey.easingStyle
            frame.easingDirection = parsedKey.easingDirection

            if frame.joints[targetName] ~= nil then
                error('A track "' .. targetName .. '" repetiu um keyframe no mesmo instante.')
            end
            frame.joints[targetName] = parsedKey.transform
        end
    end

    local events = data.events
    if events == nil then
        events = {}
    end
    arrayLength(events, "events", MAX_MARKERS)
    local eventCountsByTime = {}

    for eventIndex, event in ipairs(events) do
        if typeof(event) ~= "table" then
            error("Event " .. eventIndex .. " precisa ser um objeto.")
        end
        local eventTime = normalizeTime(event.time, "O time de um evento")
        if typeof(event.name) ~= "string"
            or event.name:match("^%s*$")
            or #event.name > 64 then
            error("O nome de cada evento precisa ter entre 1 e 64 caracteres.")
        end
        local value = event.value
        if value == nil then
            value = ""
        end
        if typeof(value) ~= "string" or #value > 256 then
            error("event.value precisa ser texto com até 256 caracteres.")
        end

        eventCountsByTime[eventTime] = (eventCountsByTime[eventTime] or 0) + 1
        if eventCountsByTime[eventTime] > MAX_MARKERS_PER_FRAME then
            error("Há mais de " .. MAX_MARKERS_PER_FRAME .. " eventos no mesmo quadro.")
        end

        local frame = getFrame(eventTime)
        frame.markers = frame.markers or {}
        table.insert(frame.markers, {
            name = event.name,
            value = value,
        })
    end

    local frames = {}
    for _, frame in pairs(framesByTime) do
        table.insert(frames, frame)
    end
    table.sort(frames, function(a, b)
        return a.time < b.time
    end)

    if #frames > MAX_FRAMES then
        error("V2 ultrapassa o limite de " .. MAX_FRAMES .. " instantes de keyframe.")
    end

    return {
        format = "POSECODE",
        version = 1,
        name = name,
        rig = rigProfile,
        fps = timeline.fps,
        duration = timeline.duration,
        rotationSpace = rotationSpace,
        looped = timeline.looped == true,
        priority = timeline.priority or "Action",
        easingStyle = defaultEasingStyle,
        easingDirection = defaultEasingDirection,
        optimizedKeyCount = optimizedKeyCount,
        frames = frames,
    }
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
    if data.rig ~= "R15" then
        error('O POSECODE 3.0 aceita somente Mesh Rig 2016 com rig = "R15".')
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

    local rotationSpace = data.rotationSpace or "joint"
    if rotationSpace ~= "joint" and rotationSpace ~= "character" then
        error('rotationSpace precisa ser "joint" ou "character".')
    end

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
    if typeof(priorityName) ~= "string" or not validPriorities[priorityName] then
        error('"priority" precisa ser Core, Idle, Movement, Action, Action2, Action3 ou Action4.')
    end

    local frames = {}
    local seenFrames = {}
    local totalMarkerCount = 0

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

        local markers = {}
        if frameData.markers ~= nil then
            local markerCount = arrayLength(frameData.markers, "markers do quadro " .. index, MAX_MARKERS_PER_FRAME)
            if markerCount > 0 and skeleton.hasCurveAnimation then
                error("Eventos KeyframeMarker exigem saída KeyframeSequence. Remova os markers deste rig CurveAnimation experimental.")
            end

            for markerIndex, markerData in ipairs(frameData.markers) do
                if typeof(markerData) ~= "table" then
                    error("Evento " .. markerIndex .. " do quadro " .. index .. " precisa ser um objeto.")
                end
                if typeof(markerData.name) ~= "string" or markerData.name:match("^%s*$") or #markerData.name > 64 then
                    error("O nome de cada evento precisa ter entre 1 e 64 caracteres.")
                end
                local markerValue = markerData.value or ""
                if typeof(markerValue) ~= "string" or #markerValue > 256 then
                    error("O valor do evento precisa ser texto com até 256 caracteres.")
                end

                totalMarkerCount += 1
                if totalMarkerCount > MAX_MARKERS then
                    error("A animação ultrapassa o limite de " .. MAX_MARKERS .. " eventos.")
                end

                table.insert(markers, {
                    name = markerData.name,
                    value = markerValue,
                })
            end
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
        if typeof(easingStyleName) ~= "string" or typeof(easingDirectionName) ~= "string" then
            error("EasingStyle e EasingDirection precisam ser strings.")
        end
        local easingStyle = Enum.PoseEasingStyle[easingStyleName]
        local easingDirection = Enum.PoseEasingDirection[easingDirectionName]

        if not easingStyle then
            error('EasingStyle inválido no keyframe ' .. index .. '. Use Linear, Constant, CubicV2, Elastic ou Bounce.')
        end
        if not easingDirection then
            error('EasingDirection inválido no keyframe ' .. index .. '. Use In, Out ou InOut.')
        end

        if skeleton.hasCurveAnimation then
            if easingStyleName == "Elastic" or easingStyleName == "Bounce" then
                error("CurveAnimation não possui interpolação Elastic ou Bounce. Use Linear, Constant ou CubicV2.")
            end
            if easingStyleName == "CubicV2" and easingDirectionName ~= "InOut" then
                error("CurveAnimation com CubicV2 exige easingDirection InOut. Ajuste o easingDirection deste quadro.")
            end
        end

        local transforms = {}
        for jointName, jointData in pairs(frameData.joints) do
            if typeof(jointName) ~= "string" or not skeleton.jointsByPart1[jointName] then
                error('A junta "' .. tostring(jointName) .. '" não existe nesse rig. Use o nome da peça conectada pela junta.')
            end
            local transform = transformFromData(jointData)
            if rotationSpace == "character" then
                transform = transformCharacterRotationToJointSpace(transform, jointName, skeleton)
            end
            transforms[jointName] = transform
        end

        table.insert(frames, {
            time = frameNumber / data.fps,
            joints = frameData.joints,
            transforms = transforms,
            markers = markers,
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
            markers = {},
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
            markers = {},
            easingStyle = lastFrame.easingStyle,
            easingDirection = lastFrame.easingDirection,
        })
    end

    if #frames > MAX_FRAMES then
        error("A normalização adicionou keyframes e ultrapassou o limite de " .. MAX_FRAMES .. ". Reduza a quantidade de quadros.")
    end

    local estimatedJointFrames = skeleton.jointCount * #frames
    if skeleton.hasCurveAnimation then
        local estimatedCurveKeys = estimatedJointFrames * 6
        if estimatedCurveKeys > MAX_CURVE_KEYS then
            error(string.format(
                "A saída CurveAnimation exigiria %d chaves de curva; o limite seguro é %d. Reduza quadros ou juntas.",
                estimatedCurveKeys,
                MAX_CURVE_KEYS
            ))
        end
    else
        local estimatedPoseInstances = (skeleton.jointCount + 1) * #frames
        if estimatedPoseInstances > MAX_POSE_INSTANCES then
            error(string.format(
                "A saída KeyframeSequence exigiria %d poses; o limite seguro é %d. Reduza quadros ou juntas.",
                estimatedPoseInstances,
                MAX_POSE_INSTANCES
            ))
        end
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
        rotationSpace = rotationSpace,
        duration = normalizedDuration,
        priority = Enum.AnimationPriority[priorityName],
        clipType = skeleton.hasCurveAnimation and "CurveAnimation" or "KeyframeSequence",
        hasBone = skeleton.hasBone,
        hasAnimationConstraint = skeleton.hasAnimationConstraint,
        hasMotor6D = skeleton.hasMotor6D,
        frames = frames,
    }
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
    if data.rig ~= "R15" then
        error('O POSECODE 3.0 aceita somente Mesh Rig 2016 com rig = "R15".')
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

    local rotationSpace = data.rotationSpace or "joint"
    if rotationSpace ~= "joint" and rotationSpace ~= "character" then
        error('rotationSpace precisa ser "joint" ou "character".')
    end

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
    if typeof(priorityName) ~= "string" or not validPriorities[priorityName] then
        error('"priority" precisa ser Core, Idle, Movement, Action, Action2, Action3 ou Action4.')
    end

    local frames = {}
    local seenFrames = {}
    local totalMarkerCount = 0

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

        local markers = {}
        if frameData.markers ~= nil then
            local markerCount = arrayLength(frameData.markers, "markers do quadro " .. index, MAX_MARKERS_PER_FRAME)
            if markerCount > 0 and skeleton.hasCurveAnimation then
                error("Eventos KeyframeMarker exigem saída KeyframeSequence. Remova os markers deste rig CurveAnimation experimental.")
            end

            for markerIndex, markerData in ipairs(frameData.markers) do
                if typeof(markerData) ~= "table" then
                    error("Evento " .. markerIndex .. " do quadro " .. index .. " precisa ser um objeto.")
                end
                if typeof(markerData.name) ~= "string" or markerData.name:match("^%s*$") or #markerData.name > 64 then
                    error("O nome de cada evento precisa ter entre 1 e 64 caracteres.")
                end
                local markerValue = markerData.value or ""
                if typeof(markerValue) ~= "string" or #markerValue > 256 then
                    error("O valor do evento precisa ser texto com até 256 caracteres.")
                end

                totalMarkerCount += 1
                if totalMarkerCount > MAX_MARKERS then
                    error("A animação ultrapassa o limite de " .. MAX_MARKERS .. " eventos.")
                end

                table.insert(markers, {
                    name = markerData.name,
                    value = markerValue,
                })
            end
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
        if typeof(easingStyleName) ~= "string" or typeof(easingDirectionName) ~= "string" then
            error("EasingStyle e EasingDirection precisam ser strings.")
        end
        local easingStyle = Enum.PoseEasingStyle[easingStyleName]
        local easingDirection = Enum.PoseEasingDirection[easingDirectionName]

        if not easingStyle then
            error('EasingStyle inválido no keyframe ' .. index .. '. Use Linear, Constant, CubicV2, Elastic ou Bounce.')
        end
        if not easingDirection then
            error('EasingDirection inválido no keyframe ' .. index .. '. Use In, Out ou InOut.')
        end

        if skeleton.hasCurveAnimation then
            if easingStyleName == "Elastic" or easingStyleName == "Bounce" then
                error("CurveAnimation não possui interpolação Elastic ou Bounce. Use Linear, Constant ou CubicV2.")
            end
            if easingStyleName == "CubicV2" and easingDirectionName ~= "InOut" then
                error("CurveAnimation com CubicV2 exige easingDirection InOut. Ajuste o easingDirection deste quadro.")
            end
        end

        local transforms = {}
        for jointName, jointData in pairs(frameData.joints) do
            if typeof(jointName) ~= "string" or not skeleton.jointsByPart1[jointName] then
                error('A junta "' .. tostring(jointName) .. '" não existe nesse rig. Use o nome da peça conectada pela junta.')
            end
            local transform = transformFromData(jointData)
            if rotationSpace == "character" then
                transform = transformCharacterRotationToJointSpace(transform, jointName, skeleton)
            end
            transforms[jointName] = transform
        end

        table.insert(frames, {
            time = frameNumber / data.fps,
            joints = frameData.joints,
            transforms = transforms,
            markers = markers,
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
            markers = {},
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
            markers = {},
            easingStyle = lastFrame.easingStyle,
            easingDirection = lastFrame.easingDirection,
        })
    end

    if #frames > MAX_FRAMES then
        error("A normalização adicionou keyframes e ultrapassou o limite de " .. MAX_FRAMES .. ". Reduza a quantidade de quadros.")
    end

    local estimatedJointFrames = skeleton.jointCount * #frames
    if skeleton.hasCurveAnimation then
        local estimatedCurveKeys = estimatedJointFrames * 6
        if estimatedCurveKeys > MAX_CURVE_KEYS then
            error(string.format(
                "A saída CurveAnimation exigiria %d chaves de curva; o limite seguro é %d. Reduza quadros ou juntas.",
                estimatedCurveKeys,
                MAX_CURVE_KEYS
            ))
        end
    else
        local estimatedPoseInstances = (skeleton.jointCount + 1) * #frames
        if estimatedPoseInstances > MAX_POSE_INSTANCES then
            error(string.format(
                "A saída KeyframeSequence exigiria %d poses; o limite seguro é %d. Reduza quadros ou juntas.",
                estimatedPoseInstances,
                MAX_POSE_INSTANCES
            ))
        end
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
        rotationSpace = rotationSpace,
        duration = normalizedDuration,
        priority = Enum.AnimationPriority[priorityName],
        clipType = skeleton.hasCurveAnimation and "CurveAnimation" or "KeyframeSequence",
        hasBone = skeleton.hasBone,
        hasAnimationConstraint = skeleton.hasAnimationConstraint,
        hasMotor6D = skeleton.hasMotor6D,
        frames = frames,
    }
end

local function buildKeyframeSequence(data, skeleton)
    local sequence = Instance.new("KeyframeSequence")
    local ok, result = pcall(function()
        sequence.Name = data.name
        sequence.Loop = data.looped
        sequence.Priority = data.priority

        local currentTransforms = {}
        for index, frameData in ipairs(data.frames) do
            for jointName, transform in pairs(frameData.transforms) do
                currentTransforms[jointName] = transform
            end

            local keyframe = Instance.new("Keyframe")
            keyframe.Name = string.format("Keyframe_%03d", index)
            keyframe.Time = frameData.time
            sequence:AddKeyframe(keyframe)

            for _, markerData in ipairs(frameData.markers or {}) do
                local marker = Instance.new("KeyframeMarker")
                marker.Name = markerData.name
                marker.Value = markerData.value
                keyframe:AddMarker(marker)
            end

            local rootPose = Instance.new("Pose")
            rootPose.Name = skeleton.rootPart.Name
            keyframe:AddPose(rootPose)

            local function addChildren(part, parentPose)
                for _, part1 in ipairs(skeleton.childrenByPart0[part] or {}) do
                    local pose = Instance.new("Pose")
                    pose.Name = part1.Name
                    parentPose:AddSubPose(pose)
                    pose.CFrame = currentTransforms[part1.Name] or CFrame.identity
                    pose.EasingStyle = frameData.easingStyle
                    pose.EasingDirection = frameData.easingDirection
                    addChildren(part1, pose)
                end
            end

            addChildren(skeleton.rootPart, rootPose)
        end
        return sequence
    end)

    if not ok then
        pcall(function()
            sequence:Destroy()
        end)
        error(result, 0)
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
    local ok, result = pcall(function()
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

        local rootFolder = nil
        if skeleton.rootPart then
            rootFolder = Instance.new("Folder")
            rootFolder.Name = skeleton.rootPart.Name
            rootFolder.Parent = animation
        end

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

        local function addNodeFolder(node, parentFolder)
            local jointFolder = Instance.new("Folder")
            jointFolder.Name = node.Name
            jointFolder.Parent = parentFolder

            local positionCurve = Instance.new("Vector3Curve")
            positionCurve.Name = "Position"
            positionCurve.Parent = jointFolder

            local rotationCurve = Instance.new("EulerRotationCurve")
            rotationCurve.Name = "Rotation"
            rotationCurve.RotationOrder = Enum.RotationOrder.XYZ
            rotationCurve.Parent = jointFolder

            addCurveKeys(positionCurve:X(), "X", node.Name, "position")
            addCurveKeys(positionCurve:Y(), "Y", node.Name, "position")
            addCurveKeys(positionCurve:Z(), "Z", node.Name, "position")

            addCurveKeys(rotationCurve:X(), "X", node.Name, "rotation")
            addCurveKeys(rotationCurve:Y(), "Y", node.Name, "rotation")
            addCurveKeys(rotationCurve:Z(), "Z", node.Name, "rotation")

            for _, childNode in ipairs(skeleton.curveChildrenByParent[node] or {}) do
                addNodeFolder(childNode, jointFolder)
            end
        end

        if skeleton.rootPart then
            for _, rootNode in ipairs(skeleton.curveChildrenByParent[skeleton.rootPart] or {}) do
                addNodeFolder(rootNode, rootFolder)
            end
        else
            for _, rootBone in ipairs(skeleton.boneRoots) do
                addNodeFolder(rootBone, animation)
            end
        end
        return animation
    end)

    if not ok then
        pcall(function()
            animation:Destroy()
        end)
        error(result, 0)
    end

    return result
end

local function buildAnimationClip(data, skeleton)
    if skeleton.hasCurveAnimation then
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

    for _, connection in ipairs(previewMarkerConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(previewMarkerConnections)

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
        pcall(function()
            previewAnimation:Destroy()
        end)
        previewAnimation = nil
    end

    if temporaryAnimator and previewAnimator then
        pcall(function()
            previewAnimator:Destroy()
        end)
    end
    if temporaryHost and previewHost then
        pcall(function()
            previewHost:Destroy()
        end)
    end

    previewAnimator = nil
    previewHost = nil
    temporaryAnimator = false
    temporaryHost = false
    previewPaused = false
    setPreviewRunning(false)
    updateTimelineCursor(0)
end

local function beginPreview()
    if not importedSequence or not importedRig then
        setStatus("Gere uma animação antes de reproduzir.", C.red)
        return
    end
    if not importedRig:IsDescendantOf(Workspace) then
        setStatus("O rig precisa estar no Workspace para a prévia.", C.red)
        return
    end

    stopPreview()

    local ok, result = pcall(function()
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

        local temporaryId = AnimationClipProvider:RegisterAnimationClip(importedSequence)
        local animation = Instance.new("Animation")
        previewAnimation = animation
        animation.Name = "PosecodePreview"
        animation.AnimationId = temporaryId

        local track = animator:LoadAnimation(animation)
        previewTrack = track
        track.Looped = previewLooped
        track.Priority = importedData.priority
        track:Play(0, 1, previewSpeed)
        previewPaused = false
        setPreviewRunning(true)

        local markerNames = {}
        for _, frameData in ipairs(importedData.frames) do
            for _, markerData in ipairs(frameData.markers or {}) do
                markerNames[markerData.name] = true
            end
        end

        for markerName in pairs(markerNames) do
            local capturedName = markerName
            local connection = track:GetMarkerReachedSignal(capturedName):Connect(function(value)
                if previewTrack ~= track then
                    return
                end

                local suffix = typeof(value) == "string" and value ~= "" and (" · " .. value) or ""
                setStatus("Evento: " .. capturedName .. suffix, C.event)
            end)
            table.insert(previewMarkerConnections, connection)
        end

        local timelineRefreshElapsed = 0
        previewStepConnection = RunService.Heartbeat:Connect(function(deltaTime)
            if not previewAnimator or not previewTrack then
                return
            end

            if not importedRig or not importedRig:IsDescendantOf(Workspace) then
                stopPreview()
                setStatus("O rig saiu do Workspace; a prévia foi encerrada.", C.red)
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
                timelineRefreshElapsed += deltaTime
                if timelineRefreshElapsed >= (1 / 30) then
                    timelineRefreshElapsed = 0
                    updateTimelineCursor(previewTrack.TimePosition)
                end
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
        setPreviewRunning(true)
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
        setPreviewRunning(true)
        setStatus("Prévia reproduzindo.", C.green)
    else
        previewTrack:AdjustSpeed(0)
        previewPaused = true
        setPreviewRunning(true)
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
    setPreviewRunning(true)
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

local function togglePreviewLoop()
    local nextLooped = not previewLooped

    if previewTrack then
        local ok, loopError = pcall(function()
            previewTrack.Looped = nextLooped
        end)
        if not ok then
            setStatus("Não foi possível alterar a repetição: " .. tostring(loopError), C.red)
            return
        end
    end

    previewLooped = nextLooped
    loopButton.Text = previewLooped and "Repetir: ON" or "Repetir: OFF"
    setStatus(previewLooped and "Repetição da prévia ativada." or "Repetição da prévia desativada.", C.muted)
end

local function saveSequence()
    if not importedSequence or not importedRig then
        setStatus("Gere uma animação antes de salvar.", C.red)
        return
    end

    local recordingCallOk, recordingId = pcall(function()
        return ChangeHistoryService:TryBeginRecording(
            "Posecode_SaveAnimation",
            "Posecode: salvar animação procedural"
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


function motionEngine.run(prompt, forcedRecipe)
    local rig = selectedRig()
    if not rig then
        setStatus("Selecione um Mesh Rig 2016 no Explorer.", C.red)
        return false
    end
    if not rig:IsDescendantOf(Workspace) then
        setStatus("O rig selecionado precisa estar no Workspace.", C.red)
        return false
    end

    local ok, result = pcall(function()
        local skeleton = getSkeleton(rig)
        local recipe, reference = motionEngine.resolveRecipe(prompt, forcedRecipe)
        if reference then recipe.referenceName = reference.name end
        local document = motionEngine.buildDocument(recipe, skeleton)
        local canonicalData = normalizeV2Data(document, skeleton)
        local data = validateData(canonicalData, rig, skeleton)
        data.sourceVersion = 2
        data.optimizedKeyCount = canonicalData.optimizedKeyCount or 0
        return {
            recipe = recipe,
            data = data,
            clip = buildAnimationClip(data, skeleton),
        }
    end)

    if not ok then
        setStatus("Não consegui gerar: " .. tostring(result), C.red)
        return false
    end

    stopPreview()
    if importedSequence and importedSequence.Parent == nil then importedSequence:Destroy() end
    importedData = result.data
    importedSequence = result.clip
    importedRig = rig
    previewLooped = importedData.looped
    loopButton.Text = previewLooped and "LOOP ON" or "LOOP OFF"
    setClipControlsEnabled(true)
    drawTimeline(importedData)

    motionEngine.lastGeneratedRecipe = result.recipe
    motionEngine.lastGeneratedPrompt = motionEngine.cleanPrompt(prompt)
    setButtonState(variationButton, true, false)
    setButtonState(saveReferenceButton, true, false)

    local refNote = result.recipe.referenceName and (" · REF " .. result.recipe.referenceName) or ""
    local clipType = importedData.clipType == "CurveAnimation" and "CURVE" or "KEYFRAME"
    setStatus(string.format("%s gerada · %s · %d frames · %.2fs%s", result.recipe.name, clipType, #importedData.frames, importedData.duration, refNote), C.green)
    beginPreview()
    return true
end

local function refreshSelectionHint()
    local candidate = selectedRig()
    if candidate ~= selectedRigCache then
        if previewTrack or previewStepConnection then stopPreview() end
        if importedSequence and importedSequence.Parent == nil then importedSequence:Destroy() end
        importedData = nil
        importedSequence = nil
        importedRig = nil
        motionEngine.lastGeneratedRecipe = nil
        motionEngine.lastGeneratedPrompt = nil
        setClipControlsEnabled(false)
        clearTimeline()
        setButtonState(variationButton, false, false)
        setButtonState(saveReferenceButton, false, false)
    end

    selectedRigCache = candidate
    if not candidate then
        rigInfo.Text = "SELECIONE O MESH RIG 2016"
        rigInfo.TextColor3 = C.muted
        rigDot.BackgroundColor3 = C.muted
        setButtonState(generateButton, false, true)
        setStatus("Selecione o Mesh Rig 2016 no Explorer.", C.muted)
        return
    end

    local ok, skeleton = pcall(function() return getSkeleton(candidate) end)
    if not ok then
        rigInfo.Text = "RIG INCOMPATÍVEL · MESH RIG 2016"
        rigInfo.TextColor3 = C.red
        rigDot.BackgroundColor3 = C.red
        setButtonState(generateButton, false, true)
        setStatus("Rig recusado: " .. tostring(skeleton), C.red)
        return
    end

    local jointLabel = skeleton.animationConstraintCount == 15 and "15 CONSTRAINTS" or "15 MOTOR6D"
    rigInfo.Text = string.format("%s · MESH RIG 2016 · %s", candidate.Name, jointLabel)
    rigInfo.TextColor3 = C.green
    rigDot.BackgroundColor3 = C.green
    setButtonState(generateButton, true, true)
    setStatus("Rig pronto. Descreva o movimento e gere.", C.green)
end

refreshRigButton.Activated:Connect(refreshSelectionHint)
Selection.SelectionChanged:Connect(refreshSelectionHint)
promptBox:GetPropertyChangedSignal("Text"):Connect(function()
    local recipe = motionEngine.lastGeneratedRecipe
    local matches = recipe ~= nil
        and motionEngine.cleanPrompt(promptBox.Text) == recipe.prompt
        and importedRig == selectedRigCache
    setButtonState(saveReferenceButton, matches, false)
    setButtonState(variationButton, matches, false)
end)

generateButton.Activated:Connect(function() motionEngine.run(promptBox.Text) end)
variationButton.Activated:Connect(function()
    local current = motionEngine.lastGeneratedRecipe
    if not current or importedRig ~= selectedRigCache then
        setStatus("Gere primeiro uma animação para criar variações.", C.red)
        return
    end
    local recipe = motionEngine.copyRecipe(current)
    recipe.seed = motionEngine.nextSeed()
    motionEngine.run(recipe.prompt, recipe)
end)
saveReferenceButton.Activated:Connect(function() motionEngine.saveCurrentReference() end)

previewButton.Activated:Connect(playPreview)
pauseButton.Activated:Connect(pausePreview)
stopButton.Activated:Connect(function()
    stopPreview()
    setStatus("Prévia parada.", C.muted)
end)
speedButton.Activated:Connect(cyclePreviewSpeed)
loopButton.Activated:Connect(togglePreviewLoop)
saveButton.Activated:Connect(saveSequence)
timelineHitbox.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        seekFromScreenX(input.Position.X)
    end
end)

motionEngine.loadLibrary()
motionEngine.renderLibrary()
setClipControlsEnabled(false)
refreshSelectionHint()
