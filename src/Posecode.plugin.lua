--[[
    POSECODE
    Convert structured animation data into Roblox animation clips.
    Handle: ruancr
    Version: 1.7
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

local VERSION = "1.7"
local MAX_FRAMES = 120
local MAX_DURATION = 15
local MAX_SOURCE_LENGTH = 262144
local MAX_TRANSFORM_OFFSET = 5
local MAX_ROTATION = 720
local MAX_JOINTS = 256
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
    accent = Color3.fromRGB(83, 119, 158),
    accentHover = Color3.fromRGB(96, 132, 171),
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
    Size = UDim2.new(1, 0, 0, 50),
})

label(header, "POSECODE", UDim2.fromOffset(14, 7), UDim2.new(1, -92, 0, 22), 15, C.text, Enum.Font.GothamBold)
label(header, "IMPORTADOR DE ANIMAÇÕES", UDim2.fromOffset(15, 28), UDim2.new(1, -92, 0, 11), 8, C.muted, Enum.Font.GothamMedium)
local versionLabel = label(header, "v" .. VERSION, UDim2.new(1, -54, 0, 17), UDim2.fromOffset(40, 16), 9, C.muted, Enum.Font.GothamMedium)
versionLabel.TextXAlignment = Enum.TextXAlignment.Right

make("Frame", root, {
    Position = UDim2.fromOffset(14, 49),
    Size = UDim2.new(1, -28, 0, 1),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
})

local scroll = make("ScrollingFrame", root, {
    Name = "ContentScroll",
    Position = UDim2.fromOffset(0, 54),
    Size = UDim2.new(1, 0, 1, -54),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.fromOffset(0, 590),
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.muted,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    Active = true,
})
local content = make("Frame", scroll, {
    Name = "Content",
    Position = UDim2.fromOffset(16, 0),
    Size = UDim2.new(1, -32, 0, 590),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
})

label(content, "DADOS DA ANIMAÇÃO", UDim2.fromOffset(0, 7), UDim2.new(1, 0, 0, 15), 10, C.text, Enum.Font.GothamMedium)
label(content, "POSECODE / JSON", UDim2.fromOffset(0, 24), UDim2.new(1, 0, 0, 14), 10, C.muted)

local sourceBox = make("TextBox", content, {
    Position = UDim2.fromOffset(0, 43),
    Size = UDim2.new(1, 0, 0, 124),
    BackgroundColor3 = C.field,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    Font = Enum.Font.Code,
    Text = "",
    PlaceholderText = '{ "format": "POSECODE", "version": 1, ... }',
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

local importButton = button(content, "Importar clip", UDim2.fromOffset(0, 176), UDim2.new(1, 0, 0, 34), true)
local exampleButton = button(content, "Exemplo", UDim2.fromOffset(0, 218), UDim2.new(0.333, -4, 0, 28), false)
local rigCheckButton = button(content, "Analisar rig", UDim2.new(0.333, 2, 0, 218), UDim2.new(0.333, -4, 0, 28), false)
local clearButton = button(content, "Limpar", UDim2.new(0.666, 4, 0, 218), UDim2.new(0.334, -4, 0, 28), false)

local timelinePanel = make("Frame", content, {
    Name = "Timeline",
    Position = UDim2.fromOffset(0, 260),
    Size = UDim2.new(1, 0, 0, 76),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
})
label(timelinePanel, "LINHA DO TEMPO", UDim2.fromOffset(0, 0), UDim2.new(0.38, 0, 0, 14), 10, C.text, Enum.Font.GothamMedium)
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
local statusLabel = label(content, "Selecione um rig R6 ou R15.", UDim2.fromOffset(0, 357), UDim2.new(1, 0, 0, 26), 10, C.muted)
statusLabel.TextWrapped = true
statusLabel.TextYAlignment = Enum.TextYAlignment.Top

make("Frame", content, {
    Position = UDim2.fromOffset(0, 396),
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
})

label(content, "PRÉVIA", UDim2.fromOffset(0, 408), UDim2.new(1, 0, 0, 14), 10, C.text, Enum.Font.GothamMedium)
local previewButton = button(content, "Reproduzir", UDim2.fromOffset(0, 430), UDim2.new(0.25, -5, 0, 32), true)
local pauseButton = button(content, "Pausar", UDim2.new(0.25, 5, 0, 430), UDim2.new(0.25, -5, 0, 32), false)
local stopButton = button(content, "Parar", UDim2.new(0.5, 5, 0, 430), UDim2.new(0.25, -5, 0, 32), false)
local speedButton = button(content, "1×", UDim2.new(0.75, 5, 0, 430), UDim2.new(0.25, -5, 0, 32), false)

local previousKeyButton = button(content, "Quadro anterior", UDim2.fromOffset(0, 470), UDim2.new(0.5, -5, 0, 28), false)
local nextKeyButton = button(content, "Próximo quadro", UDim2.new(0.5, 5, 0, 470), UDim2.new(0.5, -5, 0, 28), false)
local loopButton = button(content, "Repetir: OFF", UDim2.fromOffset(0, 510), UDim2.new(0.34, -4, 0, 34), false)
local saveButton = button(content, "Salvar clip no Studio", UDim2.new(0.34, 4, 0, 510), UDim2.new(0.66, -4, 0, 34), true)
label(content, "Publique pelo Editor de Animação.", UDim2.fromOffset(0, 552), UDim2.new(1, 0, 0, 16), 9, C.muted)

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
local isScrubbing = false
local timelineInputConnections = {}
local previewMarkerConnections = {}
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
    pauseButton.Text = previewPaused and "Continuar" or "Pausar"
    setButtonState(pauseButton, enabled, false)
    setButtonState(stopButton, enabled, false)
end

local function setClipControlsEnabled(enabled)
    setButtonState(previewButton, enabled, true)
    setButtonState(speedButton, enabled, false)
    setButtonState(previousKeyButton, enabled, false)
    setButtonState(nextKeyButton, enabled, false)
    setButtonState(loopButton, enabled, false)
    setButtonState(saveButton, enabled, true)
    timelineHitbox.Active = enabled
    timelineHitbox.Selectable = enabled
    setPreviewRunning(false)
end

local function setStatus(message, color)
    statusLabel.Text = message
    statusLabel.TextColor3 = color or C.muted
end

setClipControlsEnabled(false)
setButtonState(importButton, false, true)
setButtonState(exampleButton, false, false)

local function clearTimeline()
    for _, child in ipairs(timelineTrack:GetChildren()) do
        if child.Name == "KeyMarker" or child.Name == "EventMarker" then
            child:Destroy()
        end
    end
    timelineInfo.Text = "SEM DADOS"
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
    if not data or #data.frames == 0 then
        return
    end

    local duration = math.max(data.duration, 0.001)
    local totalMarkers = 0
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

        for markerIndex, markerData in ipairs(frameData.markers or {}) do
            totalMarkers += 1
            local eventMarker = make("Frame", timelineTrack, {
                Name = "EventMarker",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(math.clamp(frameData.time / duration, 0, 1), 0, 0.5, -8 - ((markerIndex - 1) * 2)),
                Size = UDim2.fromOffset(7, 7),
                BackgroundColor3 = C.event,
                BorderSizePixel = 0,
                ZIndex = 3,
            })
            make("UICorner", eventMarker, { CornerRadius = UDim.new(0, 1) })
        end
    end

    local clipTypeLabel = data.clipType == "CurveAnimation" and "CURVAS*" or "KEYFRAMES"
    timelineInfo.Text = string.format("%d quadros · %d eventos · %.2fs · %s", #data.frames, totalMarkers, data.duration, clipTypeLabel)
    updateTimelineCursor(0)
end

local function isSupportedJoint(instance)
    return instance:IsA("Motor6D")
        or instance:IsA("AnimationConstraint")
        or instance:IsA("Bone")
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
    local childrenByPart0 = {}
    local incomingParts = {}
    local curveChildrenByParent = {}
    local boneChildrenByParent = {}
    local boneRoots = {}

    local hasAnimationConstraint = false
    local hasBone = false
    local hasMotor6D = false
    local partJointCount = 0
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

            if descendant:IsA("Motor6D") then
                hasMotor6D = true
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
                hasAnimationConstraint = true
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

            childrenByPart0[part0] = childrenByPart0[part0] or {}
            table.insert(childrenByPart0[part0], part1)
            incomingParts[part1] = true
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

    return {
        rootPart = rootPart,
        jointsByPart1 = jointsByPart1,
        childrenByPart0 = childrenByPart0,
        curveChildrenByParent = curveChildrenByParent,
        boneChildrenByParent = boneChildrenByParent,
        boneRoots = boneRoots,
        jointCount = discoveredJointCount,
        partJointCount = partJointCount,
        boneCount = boneCount,
        hasMotor6D = hasMotor6D,
        hasAnimationConstraint = hasAnimationConstraint,
        hasBone = hasBone,
        hasCurveAnimation = hasAnimationConstraint or hasBone,
    }
end

local selectedRigCache = nil

local function refreshActionButtons()
    local hasSource = sourceBox.Text:match("^%s*$") == nil
    setButtonState(importButton, selectedRigCache ~= nil and hasSource, true)
    setButtonState(exampleButton, selectedRigCache ~= nil, false)
    setButtonState(rigCheckButton, selectedRigCache ~= nil, false)
end

local function refreshSelectionHint()
    selectedRigCache = selectedRig()
    if not importedData then
        rigInfo.Text = selectedRigCache
            and ("RIG SELECIONADO: " .. selectedRigCache.Name)
            or "RIG: —"
    end
    refreshActionButtons()
end

Selection.SelectionChanged:Connect(refreshSelectionHint)
sourceBox:GetPropertyChangedSignal("Text"):Connect(refreshActionButtons)
refreshSelectionHint()

local function analyzeSelectedRig()
    local rig = selectedRigCache
    if not rig then
        setStatus("Selecione um Model com juntas ou Bones antes de analisar.", C.red)
        return
    end

    local ok, skeleton = pcall(function()
        return getSkeleton(rig)
    end)
    if not ok then
        setStatus("Rig inválido: " .. tostring(skeleton), C.red)
        return
    end

    local humanoid = rig:FindFirstChildOfClass("Humanoid")
    local profile = humanoid and humanoid.RigType.Name or "CUSTOM"
    local details = {}
    if skeleton.partJointCount > 0 then
        table.insert(details, string.format("%d juntas", skeleton.partJointCount))
    end
    if skeleton.boneCount > 0 then
        table.insert(details, string.format("%d Bones", skeleton.boneCount))
    end

    local outputType = skeleton.hasCurveAnimation and "CurveAnimation" or "KeyframeSequence"
    rigInfo.Text = string.format("RIG: %s  /  %d ELEMENTOS  /  %s", profile, skeleton.jointCount, outputType)
    setStatus("Rig compatível: " .. table.concat(details, " + ") .. ". Saída: " .. outputType .. ".", C.green)
end

rigCheckButton.Activated:Connect(analyzeSelectedRig)

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
    if data.rig ~= "R6" and data.rig ~= "R15" and data.rig ~= "CUSTOM" then
        error('Campo "rig" precisa ser "R6", "R15" ou "CUSTOM".')
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
            transforms[jointName] = transformFromData(jointData)
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
        setStatus("Importe uma animação antes de reproduzir.", C.red)
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

        local temporaryId = AnimationClipProvider:RegisterActiveAnimationClip(importedSequence)
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
        setStatus("Selecione um Model com Motor6D, AnimationConstraint ou Bone.", C.red)
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
    previewLooped = importedData.looped
    loopButton.Text = previewLooped and "Repetir: ON" or "Repetir: OFF"
    setClipControlsEnabled(true)

    local clipTypeLabel = "KEYFRAME"
    if importedData.clipType == "CurveAnimation" then
        clipTypeLabel = importedData.hasAnimationConstraint and "CURVE* / CONSTRAINT" or "CURVE / BONE"
    end
    rigInfo.Text = string.format("RIG: %s  /  %s  /  %s", importedData.rig, rig.Name, clipTypeLabel)
    drawTimeline(importedData)

    setStatus(
        importedData.hasAnimationConstraint
            and string.format("%d quadros convertidos. A saída com AnimationConstraint ainda é experimental; confira a prévia no Studio.", #importedData.frames)
            or string.format(
                "%d quadros convertidos. %s Prévia, navegação e salvamento disponíveis.",
                #importedData.frames,
                importedData.hasBone and "Rig com Bone compatível." or "Rig Motor6D compatível."
            ),
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
        local skeleton = getSkeleton(rig)
        local rootChildren = skeleton.rootPart
            and (skeleton.curveChildrenByParent[skeleton.rootPart] or {})
            or skeleton.boneRoots

        if #rootChildren == 0 then
            error("Não encontrei uma junta ou Bone ligado à raiz desse rig.")
        end

        local jointName = rootChildren[1].Name
        local sample = {
            format = "POSECODE",
            version = 1,
            name = "Posecode_Sample",
            rig = humanoid and humanoid.RigType.Name or "CUSTOM",
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
                    markers = not skeleton.hasCurveAnimation and {
                        { name = "PosecodeSampleEvent", value = "middle" },
                    } or nil,
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
    setStatus("Exemplo carregado. Clique em Importar clip.", C.green)
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
    previewLooped = false
    loopButton.Text = "Repetir: OFF"
    setClipControlsEnabled(false)
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
loopButton.Activated:Connect(togglePreviewLoop)

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

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
    if not widget.Enabled then
        isScrubbing = false
        if previewTrack then
            stopPreview()
        end
    end
end)

plugin.Unloading:Connect(function()
    isScrubbing = false
    stopPreview()
    for _, connection in ipairs(timelineInputConnections) do
        connection:Disconnect()
    end
    if importedSequence and importedSequence.Parent == nil then
        importedSequence:Destroy()
    end
end)
