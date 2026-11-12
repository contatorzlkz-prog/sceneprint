--[[
    POSECODE
    Convert structured animation data into Roblox KeyframeSequences.
    Handle: ruancr
    Version: 0.1.0
    The plugin never executes pasted source; it only extracts and validates JSON.
]]

assert(plugin, "Abra este arquivo como um plugin do Roblox Studio.")

local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local AnimationClipProvider = game:GetService("AnimationClipProvider")
local Workspace = game:GetService("Workspace")

local VERSION = "0.1.0"
local MAX_FRAMES = 120
local MAX_DURATION = 15
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
    690,
    360,
    540
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

local importButton = button(root, "IMPORTAR E GERAR KEYFRAMES", UDim2.fromOffset(18, 311), UDim2.new(1, -36, 0, 34), true)

local timelinePanel = make("Frame", root, {
    Position = UDim2.fromOffset(18, 363),
    Size = UDim2.new(1, -36, 0, 78),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
})
make("UICorner", timelinePanel, { CornerRadius = UDim.new(0, 5) })
label(timelinePanel, "LINHA DO TEMPO", UDim2.fromOffset(12, 8), UDim2.new(0.55, -12, 0, 14), 8, C.muted, Enum.Font.GothamBold)
local timelineInfo = label(timelinePanel, "SEM DADOS", UDim2.new(0.55, 0, 0, 8), UDim2.new(0.45, -12, 0, 14), 8, C.muted, Enum.Font.GothamMedium)
timelineInfo.TextXAlignment = Enum.TextXAlignment.Right

local timelineTrack = make("Frame", timelinePanel, {
    Position = UDim2.fromOffset(12, 34),
    Size = UDim2.new(1, -24, 0, 22),
    BackgroundTransparency = 1,
})
make("Frame", timelineTrack, {
    Position = UDim2.new(0, 0, 0.5, -1),
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
})

local rigInfo = label(root, "RIG: —", UDim2.fromOffset(18, 451), UDim2.new(1, -36, 0, 16), 9, C.muted, Enum.Font.GothamMedium)
local statusLabel = label(root, "Selecione um rig R6 ou R15 antes de importar.", UDim2.fromOffset(18, 472), UDim2.new(1, -36, 0, 33), 10, C.muted)
statusLabel.TextWrapped = true
statusLabel.TextYAlignment = Enum.TextYAlignment.Top

make("Frame", root, {
    Position = UDim2.fromOffset(18, 516),
    Size = UDim2.new(1, -36, 0, 1),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
})

label(root, "PRÉVIA", UDim2.fromOffset(18, 529), UDim2.new(1, -36, 0, 14), 8, C.muted, Enum.Font.GothamBold)
local previewButton = button(root, "REPRODUZIR", UDim2.fromOffset(18, 550), UDim2.new(0.5, -23, 0, 32), false)
local stopButton = button(root, "PARAR", UDim2.new(0.5, 5, 0, 550), UDim2.new(0.5, -23, 0, 32), false)
local saveButton = button(root, "SALVAR KEYFRAMES NO STUDIO", UDim2.fromOffset(18, 592), UDim2.new(1, -36, 0, 34), true)
label(root, "Publicação: use o Editor de Animação do Studio.", UDim2.fromOffset(18, 638), UDim2.new(1, -36, 0, 18), 9, C.muted)

local importedData = nil
local importedSequence = nil
local importedRig = nil
local previewTrack = nil
local previewAnimation = nil
local previewHost = nil
local previewAnimator = nil
local temporaryHost = false
local temporaryAnimator = false

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
        })
        make("UICorner", marker, { CornerRadius = UDim.new(0, 2) })
    end

    timelineInfo.Text = string.format("%d CHAVES  /  %.2FS", #data.frames, data.duration)
end

local function selectedRig()
    local items = Selection:Get()
    for _, item in ipairs(items) do
        local current = item
        while current and current ~= Workspace do
            if current:IsA("Model") then
                local hasMotor = false
                for _, descendant in ipairs(current:GetDescendants()) do
                    if descendant:IsA("Motor6D") then
                        hasMotor = true
                        break
                    end
                end
                if hasMotor then
                    return current
                end
            end
            current = current.Parent
        end
    end
    return nil
end

local function getSkeleton(rig)
    local motors = {}
    local motorsByPart1 = {}
    local childrenByPart0 = {}
    local incoming = {}

    for _, descendant in ipairs(rig:GetDescendants()) do
        if descendant:IsA("Motor6D") and descendant.Part0 and descendant.Part1 then
            if motorsByPart1[descendant.Part1.Name] then
                error("Há duas juntas controlando uma peça chamada " .. descendant.Part1.Name .. ".")
            end

            table.insert(motors, descendant)
            motorsByPart1[descendant.Part1.Name] = descendant
            incoming[descendant.Part1] = true

            childrenByPart0[descendant.Part0] = childrenByPart0[descendant.Part0] or {}
            table.insert(childrenByPart0[descendant.Part0], descendant)
        end
    end

    if #motors == 0 then
        error("O rig não possui juntas Motor6D.")
    end

    for _, children in pairs(childrenByPart0) do
        table.sort(children, function(a, b)
            return a.Part1.Name < b.Part1.Name
        end)
    end

    local rootPart = rig:FindFirstChild("HumanoidRootPart", true)
    if not rootPart or not rootPart:IsA("BasePart") then
        rootPart = rig.PrimaryPart
    end

    if not rootPart then
        for part in pairs(childrenByPart0) do
            if not incoming[part] then
                rootPart = part
                break
            end
        end
    end

    if not rootPart or not rootPart:IsA("BasePart") then
        error("Não foi possível identificar a raiz do rig.")
    end

    local visited = {}
    local function walk(part)
        for _, motor in ipairs(childrenByPart0[part] or {}) do
            if visited[motor] then
                error("A hierarquia de Motor6D contém um ciclo.")
            end
            visited[motor] = true
            walk(motor.Part1)
        end
    end
    walk(rootPart)

    local reachable = 0
    for _ in pairs(visited) do
        reachable += 1
    end
    if reachable ~= #motors then
        error("Há juntas desconectadas da raiz do rig.")
    end

    return {
        rootPart = rootPart,
        motorsByPart1 = motorsByPart1,
        childrenByPart0 = childrenByPart0,
    }
end

local function isFiniteNumber(value)
    return typeof(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function readVector3(value, fieldName, limit)
    if value == nil then
        return 0, 0, 0
    end
    if typeof(value) ~= "table" or #value ~= 3 then
        error(fieldName .. " deve conter três números [x, y, z].")
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
    local payload = source:match("POSECODE_BEGIN(.-)POSECODE_END")
    if payload then
        return payload
    end

    local _, body = source:match("local%s+POSECODE%s*=%s*%[(=*)%[(.-)%]%1%]")
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
    if typeof(data.frames) ~= "table" or #data.frames < 1 or #data.frames > MAX_FRAMES then
        error("A animação precisa ter entre 1 e " .. MAX_FRAMES .. " keyframes.")
    end

    local priorityName = data.priority or "Action"
    local priority = Enum.AnimationPriority[priorityName]
    if not priority then
        error('"priority" precisa ser Core, Idle, Movement ou Action.')
    end

    local frames = {}
    local seenTimes = {}

    for index, frameData in ipairs(data.frames) do
        if typeof(frameData) ~= "table" or not isFiniteNumber(frameData.time) then
            error("Keyframe " .. index .. " não possui um tempo válido.")
        end
        if frameData.time < 0 or frameData.time > data.duration then
            error("O tempo de um keyframe ultrapassa a duração declarada.")
        end

        local timeKey = string.format("%.4f", frameData.time)
        if seenTimes[timeKey] then
            error("Existem dois keyframes no mesmo instante.")
        end
        seenTimes[timeKey] = true

        if typeof(frameData.joints) ~= "table" then
            error("Keyframe " .. index .. " precisa ter um objeto joints.")
        end

        for jointName, jointData in pairs(frameData.joints) do
            if typeof(jointName) ~= "string" or not skeleton.motorsByPart1[jointName] then
                error('A junta "' .. tostring(jointName) .. '" não existe nesse rig.')
            end
            transformFromData(jointData)
        end

        table.insert(frames, frameData)
    end

    table.sort(frames, function(a, b)
        return a.time < b.time
    end)

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
        duration = data.duration,
        priority = priority,
        frames = frames,
    }
end

local function buildSequence(data, skeleton)
    local sequence = Instance.new("KeyframeSequence")
    sequence.Name = data.name
    sequence.Loop = data.looped
    sequence.Priority = data.priority

    local ok, result = pcall(function()
        for index, frameData in ipairs(data.frames) do
            local keyframe = Instance.new("Keyframe")
            keyframe.Name = string.format("Keyframe_%03d", index)
            keyframe.Time = frameData.time

            local rootPose = Instance.new("Pose")
            rootPose.Name = skeleton.rootPart.Name
            rootPose.CFrame = CFrame.identity
            rootPose.Weight = 0
            rootPose.Parent = keyframe

            local function addChildren(part, parentPose)
                for _, motor in ipairs(skeleton.childrenByPart0[part] or {}) do
                    local part1 = motor.Part1
                    local pose = Instance.new("Pose")
                    pose.Name = part1.Name
                    pose.CFrame = transformFromData(frameData.joints[part1.Name])
                    pose.Weight = 1
                    pose.EasingStyle = Enum.PoseEasingStyle.Linear
                    pose.EasingDirection = Enum.PoseEasingDirection.In
                    pose.Parent = parentPose
                    addChildren(part1, pose)
                end
            end

            addChildren(skeleton.rootPart, rootPose)
            keyframe.Parent = sequence
        end
        return sequence
    end)

    if not ok then
        sequence:Destroy()
        error(result)
    end
    return result
end

local function stopPreview()
    if previewTrack then
        pcall(function()
            previewTrack:Stop(0.12)
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

    local ok, result = pcall(function()
        local temporaryId = AnimationClipProvider:RegisterAnimationClip(importedSequence)
        local animation = Instance.new("Animation")
        animation.Name = "PosecodePreview"
        animation.AnimationId = temporaryId

        local track = animator:LoadAnimation(animation)
        track.Looped = importedData.looped
        track.Priority = importedSequence.Priority
        track:Play(0.12)

        previewAnimation = animation
        previewTrack = track
    end)

    if not ok then
        stopPreview()
        setStatus("Não foi possível iniciar a prévia: " .. tostring(result), C.red)
        return
    end

    setStatus("Prévia reproduzindo no rig selecionado.", C.green)
end

local function saveSequence()
    if not importedSequence or not importedRig then
        setStatus("Importe uma animação antes de salvar.", C.red)
        return
    end

    local ok, result = pcall(function()
        local animSaves = importedRig:FindFirstChild("AnimSaves")
        local saveFolder = nil

        if animSaves then
            if not animSaves:IsA("ObjectValue") then
                error('O rig já possui um objeto "AnimSaves" que não é ObjectValue.')
            end
            if animSaves.Value and animSaves.Value:IsA("Folder") then
                saveFolder = animSaves.Value
            end
        end

        if not saveFolder then
            saveFolder = Instance.new("Folder")
            saveFolder.Name = "Posecode_" .. importedRig.Name:gsub("[^%w_%-]", "_")
            saveFolder.Parent = ServerStorage

            if not animSaves then
                animSaves = Instance.new("ObjectValue")
                animSaves.Name = "AnimSaves"
                animSaves.Parent = importedRig
            end
            animSaves.Value = saveFolder
        end

        local baseName = importedData.name
        local finalName = baseName
        local suffix = 2
        while saveFolder:FindFirstChild(finalName) do
            finalName = baseName .. "_" .. suffix
            suffix += 1
        end

        local recordingId = nil
        pcall(function()
            recordingId = ChangeHistoryService:TryBeginRecording(
                "Posecode_SaveAnimation",
                "Posecode: salvar keyframes"
            )
        end)

        importedSequence.Name = finalName
        importedSequence.Parent = saveFolder

        if recordingId then
            pcall(function()
                ChangeHistoryService:FinishRecording(recordingId, Enum.FinishRecordingOperation.Commit)
            end)
        else
            pcall(function()
                ChangeHistoryService:SetWaypoint("Posecode: salvar keyframes")
            end)
        end

        return finalName
    end)

    if not ok then
        setStatus("Falha ao salvar: " .. tostring(result), C.red)
        return
    end

    setStatus('Keyframes salvos em ServerStorage. Nome: "' .. result .. '".', C.green)
end

importButton.Activated:Connect(function()
    stopPreview()

    local rig = selectedRig()
    if not rig then
        setStatus("Selecione um Model com rig R6 ou R15 no Explorer ou na viewport.", C.red)
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

previewButton.Activated:Connect(beginPreview)

stopButton.Activated:Connect(function()
    stopPreview()
    setStatus("Prévia parada.")
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
