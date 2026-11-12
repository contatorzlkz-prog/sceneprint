--[[
    POSECODE
    Convert structured animation data into Roblox KeyframeSequences.
    Handle: ruancr
    Version: 1.2
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

local VERSION = "1.2"
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

local toolbar = plugin:CreateToolbar("Posecode")
local toolbarButton = toolbar:CreateButton("Posecode", "Abrir Posecode", "")
toolbarButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Right,
    false,
    false,
    440,
    760,
    360,
    650
)

local widget = plugin:CreateDockWidgetPluginGuiAsync("Posecode.Main", widgetInfo)
widget.Title = "Posecode"

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
    local object = make("TextButton", parent, {
        Position = position,
        Size = size,
        BackgroundColor3 = primary and C.accent or C.surface,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = primary and C.background or C.text,
        TextSize = 10,
    })
    make("UICorner", object, { CornerRadius = UDim.new(0, 5) })
    return object
end

local root = make("Frame", widget, {
    Name = "PosecodeRoot",
    BackgroundColor3 = C.background,
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
})

local headerMark = make("Frame", root, {
    Position = UDim2.fromOffset(18, 17),
    Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = C.accentDark,
    BorderSizePixel = 0,
})
make("UICorner", headerMark, { CornerRadius = UDim.new(0, 6) })
make("Frame", headerMark, {
    Position = UDim2.fromOffset(7, 15),
    Size = UDim2.fromOffset(5, 8),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
})
make("Frame", headerMark, {
    Position = UDim2.fromOffset(15, 9),
    Size = UDim2.fromOffset(5, 14),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
})
make("Frame", headerMark, {
    Position = UDim2.fromOffset(23, 5),
    Size = UDim2.fromOffset(2, 18),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
})

label(root, "POSECODE", UDim2.fromOffset(59, 14), UDim2.new(1, -150, 0, 22), 16, C.text, Enum.Font.GothamBold)
label(root, "AI  /  KEYFRAMES", UDim2.fromOffset(60, 34), UDim2.new(1, -150, 0, 13), 8, C.muted, Enum.Font.GothamMedium)
local versionLabel = label(root, "v" .. VERSION, UDim2.new(1, -64, 0, 23), UDim2.fromOffset(46, 14), 9, C.muted)
versionLabel.TextXAlignment = Enum.TextXAlignment.Right

make("Frame", root, {
    Position = UDim2.fromOffset(18, 60),
    Size = UDim2.new(1, -36, 0, 1),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
})

label(root, "IMPORTAR SCRIPT", UDim2.fromOffset(18, 75), UDim2.new(1, -36, 0, 16), 9, C.muted, Enum.Font.GothamBold)
label(root, "Cole o script estruturado pela IA.", UDim2.fromOffset(18, 93), UDim2.new(1, -36, 0, 17), 11, C.text)

local sourceBox = make("TextBox", root, {
    Position = UDim2.fromOffset(18, 116),
    Size = UDim2.new(1, -36, 0, 185),
    BackgroundColor3 = C.field,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    Font = Enum.Font.Code,
    Text = "",
    PlaceholderText = "local POSECODE = [==[\n{\n  \"format\": \"POSECODE\",\n  ...\n}\n]==]\nreturn POSECODE",
    PlaceholderColor3 = C.muted,
    TextColor3 = C.text,
    TextSize = 10,
    TextWrapped = false,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    MultiLine = true,
})
make("UICorner", sourceBox, { CornerRadius = UDim.new(0, 5) })
make("UIPadding", sourceBox, {
    PaddingTop = UDim.new(0, 10),
    PaddingBottom = UDim.new(0, 10),
    PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 10),
})

local importButton = button(root, "IMPORTAR ANIMAÇÃO", UDim2.fromOffset(18, 311), UDim2.new(1, -36, 0, 34), true)
local exampleButton = button(root, "CARREGAR EXEMPLO", UDim2.fromOffset(18, 352), UDim2.new(0.5, -23, 0, 28), false)
local clearButton = button(root, "LIMPAR", UDim2.new(0.5, 5, 0, 352), UDim2.new(0.5, -23, 0, 28), false)

local timelinePanel = make("Frame", root, {
    Position = UDim2.fromOffset(18, 392),
    Size = UDim2.new(1, -36, 0, 100),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
})
make("UICorner", timelinePanel, { CornerRadius = UDim.new(0, 5) })
label(timelinePanel, "LINHA DO TEMPO", UDim2.fromOffset(12, 9), UDim2.new(0.45, -12, 0, 14), 8, C.muted, Enum.Font.GothamBold)
local timelineInfo = label(timelinePanel, "SEM DADOS", UDim2.new(0.45, 0, 0, 9), UDim2.new(0.55, -12, 0, 14), 8, C.muted, Enum.Font.GothamMedium)
timelineInfo.TextXAlignment = Enum.TextXAlignment.Right

local timelineTrack = make("Frame", timelinePanel, {
    Position = UDim2.fromOffset(12, 38),
    Size = UDim2.new(1, -24, 0, 26),
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
    Size = UDim2.fromOffset(2, 24),
    BackgroundColor3 = C.text,
    BorderSizePixel = 0,
    ZIndex = 5,
})
local timelineTime = label(timelinePanel, "00:00.00", UDim2.fromOffset(12, 72), UDim2.new(1, -24, 0, 16), 9, C.text, Enum.Font.Code)

local rigInfo = label(root, "RIG: —", UDim2.fromOffset(18, 502), UDim2.new(1, -36, 0, 16), 9, C.muted, Enum.Font.GothamMedium)
local statusLabel = label(root, "Selecione um rig R6 ou R15 antes de importar.", UDim2.fromOffset(18, 522), UDim2.new(1, -36, 0, 30), 10, C.muted)
statusLabel.TextWrapped = true
statusLabel.TextYAlignment = Enum.TextYAlignment.Top

make("Frame", root, {
    Position = UDim2.fromOffset(18, 560),
    Size = UDim2.new(1, -36, 0, 1),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
})

label(root, "PRÉVIA", UDim2.fromOffset(18, 572), UDim2.new(1, -36, 0, 14), 8, C.muted, Enum.Font.GothamBold)
local previewButton = button(root, "REPRODUZIR", UDim2.fromOffset(18, 592), UDim2.new(0.25, -8, 0, 32), true)
local pauseButton = button(root, "PAUSAR", UDim2.new(0.25, 14, 0, 592), UDim2.new(0.25, -8, 0, 32), false)
local stopButton = button(root, "PARAR", UDim2.new(0.5, 2, 0, 592), UDim2.new(0.25, -8, 0, 32), false)
local speedButton = button(root, "1×", UDim2.new(0.75, -10, 0, 592), UDim2.new(0.25, -8, 0, 32), false)

local previousKeyButton = button(root, "◀ QUADRO", UDim2.fromOffset(18, 632), UDim2.new(0.5, -23, 0, 28), false)
local nextKeyButton = button(root, "QUADRO ▶", UDim2.new(0.5, 5, 0, 632), UDim2.new(0.5, -23, 0, 28), false)
local saveButton = button(root, "SALVAR CLIP NO STUDIO", UDim2.fromOffset(18, 668), UDim2.new(1, -36, 0, 34), true)
label(root, "Publicação: use o Editor de Animação do Studio.", UDim2.fromOffset(18, 710), UDim2.new(1, -36, 0, 18), 9, C.muted)

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

local function setStatus(message, color)
    statusLabel.Text = message
    statusLabel.TextColor3 = color or C.muted
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

    local clipTypeLabel = data.clipType == "CurveAnimation" and "CURVAS" or "KEYFRAMES"
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

    local rootPart = rootCandidate.AssemblyRootPart or rootCandidate
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
    for _, number in ipairs({ x, y, z }) do
        if not isFiniteNumber(number) or math.abs(number) > limit then
            error(fieldName .. " contém um valor fora do limite permitido.")
        end
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

    return CFrame.new(px, py, pz) * CFrame.fromOrientation(
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

        for jointName, jointData in pairs(frameData.joints) do
            if typeof(jointName) ~= "string" or not skeleton.jointsByPart1[jointName] then
                error('A junta "' .. tostring(jointName) .. '" não existe nesse rig. Use o nome da peça conectada pela junta.')
            end
            transformFromData(jointData)
        end

        table.insert(frames, {
            time = frameNumber / data.fps,
            joints = frameData.joints,
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
            easingStyle = frames[1].easingStyle,
            easingDirection = frames[1].easingDirection,
        })
    end

    local lastFrame = frames[#frames]
    if lastFrame.time < normalizedDuration then
        table.insert(frames, {
            time = normalizedDuration,
            joints = table.clone(lastFrame.joints),
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
            for jointName, jointData in pairs(frameData.joints) do
                currentTransforms[jointName] = transformFromData(jointData)
            end

            local keyframe = Instance.new("Keyframe")
            keyframe.Name = string.format("Keyframe_%03d", index)
            keyframe.Time = frameData.time

            local rootPose = Instance.new("Pose")
            rootPose.Name = skeleton.rootPart.Name
            rootPose.Weight = 0

            local function addChildren(part, parentPose)
                for _, part1 in ipairs(skeleton.childrenByPart0[part] or {}) do
                    local pose = Instance.new("Pose")
                    pose.Name = part1.Name
                    pose.CFrame = currentTransforms[part1.Name] or CFrame.identity
                    pose.Weight = 1
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
        for jointName, jointData in pairs(frameData.joints) do
            currentTransforms[jointName] = transformFromData(jointData)
        end

        local snapshot = {}
        for jointName in pairs(skeleton.jointsByPart1) do
            snapshot[jointName] = currentTransforms[jointName] or CFrame.identity
        end
        snapshots[index] = snapshot
    end

    local ok, result = pcall(function()
        local rootFolder = Instance.new("Folder")
        rootFolder.Name = skeleton.rootPart.Name
        rootFolder.Parent = animation

        local function addCurveKeys(floatCurve, axisGetter, partName, axisKind)
            local keys = {}
            for index, frameData in ipairs(data.frames) do
                local transform = snapshots[index][partName]
                local value

                if axisKind == "position" then
                    value = transform.Position[axisGetter]
                else
                    local rx, ry, rz = transform:ToOrientation()
                    local rotationValues = { X = rx, Y = ry, Z = rz }
                    value = rotationValues[axisGetter]
                end

                table.insert(keys, FloatCurveKey.new(
                    frameData.time,
                    value,
                    curveInterpolation(frameData)
                ))
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
                if joint:IsA("Motor6D") and snapshot.currentAngle ~= nil then
                    joint.CurrentAngle = snapshot.currentAngle
                end
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
                currentAngle = descendant:IsA("Motor6D") and descendant.CurrentAngle or nil,
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

    previewTrack:AdjustSpeed(0)
    previewPaused = true
    setStatus("Prévia pausada.", C.muted)
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

    local ok, result = pcall(function()
        local animSaves = importedRig:FindFirstChild("AnimSaves")
        local saveFolder = nil

        if animSaves then
            if animSaves:IsA("Folder") then
                -- Compatibilidade com rigs que ainda usam o formato antigo.
                saveFolder = animSaves
            elseif animSaves:IsA("ObjectValue") then
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

            if not animSaves then
                animSaves = Instance.new("ObjectValue")
                animSaves.Name = "AnimSaves"
                animSaves.Parent = importedRig
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
        setStatus("O Studio não conseguiu concluir o registro de Undo: " .. tostring(finishError), C.red)
        return
    end

    setStatus('Keyframes salvos em AnimSaves. Nome: "' .. result .. '".', C.green)
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

    local ok, result = pcall(function()
        local skeleton = getSkeleton(rig)
        local payload = extractPayload(sourceBox.Text)
        local decoded = HttpService:JSONDecode(payload)
        local data = validateData(decoded, rig, skeleton)
        local sequence = buildSequence(data, skeleton)
        return {
            data = data,
            sequence = sequence,
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
    importedSequence = result.sequence
    importedRig = rig

    rigInfo.Text = string.format("RIG: %s  /  %s", importedData.rig, rig.Name)
    drawTimeline(importedData)

    setStatus(
        string.format("%d keyframes preparados. Prévia e salvamento liberados.", #importedData.frames),
        C.green
    )
end)

timelineHitbox.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        isScrubbing = true
        seekFromScreenX(input.Position.X)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not isScrubbing then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        seekFromScreenX(input.Position.X)
    end
end)

UserInputService.InputEnded:Connect(function(input)
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
    if importedSequence and importedSequence.Parent == nil then
        importedSequence:Destroy()
    end
end)
