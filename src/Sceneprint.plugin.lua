--[[
    SCENEPRINT
    A small, selection-first scene check for Roblox Studio.
    Created by Ruan Carlos (ruancr).
    Version: 0.2.0 | MIT License
]]

assert(plugin, "Sceneprint precisa ser executado como um plugin do Roblox Studio.")

local Selection = game:GetService("Selection")
local Workspace = game:GetService("Workspace")

local COLOR = {
    background = Color3.fromRGB(13, 13, 16),
    surface = Color3.fromRGB(23, 23, 27),
    text = Color3.fromRGB(239, 238, 244),
    muted = Color3.fromRGB(137, 135, 148),
    line = Color3.fromRGB(46, 45, 53),
    purple = Color3.fromRGB(175, 157, 255),
    purpleDark = Color3.fromRGB(45, 39, 65),
    amber = Color3.fromRGB(220, 172, 103),
}

local toolbar = plugin:CreateToolbar("Sceneprint")
local toolbarButton = toolbar:CreateButton("Sceneprint", "Revisar a seleção com Sceneprint", "")
toolbarButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Right,
    false,
    false,
    330,
    480,
    280,
    360
)

local widget = plugin:CreateDockWidgetPluginGuiAsync("Sceneprint.Main", widgetInfo)
widget.Title = "Sceneprint"

local function make(className, parent, properties)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    object.Parent = parent
    return object
end

local function makeLabel(parent, text, position, size, textSize, color, font)
    return make("TextLabel", parent, {
        BackgroundTransparency = 1,
        Position = position,
        Size = size,
        Font = font or Enum.Font.Gotham,
        Text = text,
        TextColor3 = color or COLOR.text,
        TextSize = textSize or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end

local root = make("Frame", widget, {
    Name = "Sceneprint",
    BackgroundColor3 = COLOR.background,
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
})

-- Header: nome e autoria sem ocupar a tela.
local mark = make("Frame", root, {
    Position = UDim2.fromOffset(18, 17),
    Size = UDim2.fromOffset(27, 27),
    BackgroundColor3 = COLOR.purpleDark,
    BorderSizePixel = 0,
})
make("UICorner", mark, { CornerRadius = UDim.new(0, 7) })

local markText = makeLabel(mark, "S", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 16, COLOR.purple, Enum.Font.GothamBold)
markText.TextXAlignment = Enum.TextXAlignment.Center

makeLabel(root, "sceneprint", UDim2.fromOffset(55, 13), UDim2.new(1, -76, 0, 22), 17, COLOR.text, Enum.Font.GothamBold)
makeLabel(root, "by ruancr", UDim2.fromOffset(56, 34), UDim2.new(1, -76, 0, 14), 9, COLOR.muted, Enum.Font.GothamMedium)

make("Frame", root, {
    Position = UDim2.fromOffset(18, 59),
    Size = UDim2.new(1, -36, 0, 1),
    BackgroundColor3 = COLOR.line,
    BorderSizePixel = 0,
})

makeLabel(
    root,
    "Uma revisão rápida do que você selecionou.",
    UDim2.fromOffset(18, 76),
    UDim2.new(1, -36, 0, 22),
    11,
    COLOR.text
)

local selectionLabel = makeLabel(
    root,
    "NADA SELECIONADO",
    UDim2.fromOffset(18, 108),
    UDim2.new(1, -36, 0, 16),
    9,
    COLOR.muted,
    Enum.Font.GothamMedium
)

local scanButton = make("TextButton", root, {
    Position = UDim2.fromOffset(18, 136),
    Size = UDim2.new(1, -36, 0, 36),
    BackgroundColor3 = COLOR.purple,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.GothamBold,
    Text = "VERIFICAR SELEÇÃO",
    TextColor3 = Color3.fromRGB(20, 18, 25),
    TextSize = 10,
})
make("UICorner", scanButton, { CornerRadius = UDim.new(0, 6) })

local statusLabel = makeLabel(
    root,
    "Selecione um Model ou uma peça no Explorer.",
    UDim2.fromOffset(18, 184),
    UDim2.new(1, -36, 0, 34),
    11,
    COLOR.muted
)
statusLabel.TextWrapped = true
statusLabel.TextYAlignment = Enum.TextYAlignment.Top

local resultsHeading = makeLabel(
    root,
    "",
    UDim2.fromOffset(18, 226),
    UDim2.new(1, -36, 0, 17),
    9,
    COLOR.muted,
    Enum.Font.GothamBold
)

local results = make("ScrollingFrame", root, {
    Name = "Results",
    Position = UDim2.fromOffset(18, 250),
    Size = UDim2.new(1, -36, 1, -292),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = COLOR.muted,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
})

make("UIListLayout", results, {
    Padding = UDim.new(0, 2),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

make("Frame", root, {
    Position = UDim2.new(0, 18, 1, -26),
    Size = UDim2.new(1, -36, 0, 1),
    BackgroundColor3 = COLOR.line,
    BorderSizePixel = 0,
})

makeLabel(
    root,
    "SCENEPRINT  /  CRIADO POR RUAN CARLOS",
    UDim2.new(0, 18, 1, -21),
    UDim2.new(1, -36, 0, 13),
    8,
    COLOR.muted,
    Enum.Font.GothamMedium
)

local findings = {}
local scanToken = 0
local scanning = false

local INTENTIONAL_NAME_PARTS = {
    "hitbox",
    "hurtbox",
    "trigger",
    "collider",
    "collision",
    "boundary",
    "bounds",
    "vehicle",
    "wheel",
    "door",
    "gate",
    "ragdoll",
    "projectile",
    "physics",
    "moving",
}

local function isInWorkspace(instance)
    return instance == Workspace or instance:IsDescendantOf(Workspace)
end

local function getSelectedRoots()
    local selected = Selection:Get()
    local selectedSet = {}

    for _, instance in ipairs(selected) do
        if isInWorkspace(instance) and instance ~= Workspace then
            selectedSet[instance] = true
        end
    end

    local roots = {}

    for _, instance in ipairs(selected) do
        if selectedSet[instance] then
            local parent = instance.Parent
            local hasSelectedAncestor = false

            while parent and parent ~= Workspace do
                if selectedSet[parent] then
                    hasSelectedAncestor = true
                    break
                end

                parent = parent.Parent
            end

            if not hasSelectedAncestor then
                table.insert(roots, instance)
            end
        end
    end

    return roots
end

local function updateSelectionLabel()
    local roots = getSelectedRoots()

    if #roots == 0 then
        selectionLabel.Text = "NADA SELECIONADO"
        return
    end

    local labelText = #roots == 1 and "ITEM SELECIONADO" or "ITENS SELECIONADOS"
    selectionLabel.Text = string.format("%d %s", #roots, labelText)
end

local function hasHumanoidAncestor(instance)
    local parent = instance.Parent

    while parent and parent ~= Workspace do
        if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then
            return true
        end

        parent = parent.Parent
    end

    return false
end

local function hasIntentionalName(instance)
    local current = instance

    while current and current ~= Workspace do
        local name = string.lower(current.Name)

        for _, keyword in ipairs(INTENTIONAL_NAME_PARTS) do
            if string.find(name, keyword, 1, true) then
                return true
            end
        end

        current = current.Parent
    end

    return false
end

local function getPath(instance)
    local ok, path = pcall(function()
        return instance:GetFullName()
    end)

    if not ok then
        return instance.Name
    end

    if #path > 64 then
        return "..." .. string.sub(path, #path - 61, #path)
    end

    return path
end

local function addFinding(kind, title, message, object)
    table.insert(findings, {
        kind = kind,
        title = title,
        message = message,
        object = object,
        path = getPath(object),
    })
end

local function clearResults()
    for _, child in ipairs(results:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
end

local function showEmpty(title, detail)
    clearResults()

    local empty = make("Frame", results, {
        Size = UDim2.new(1, -4, 0, 58),
        BackgroundTransparency = 1,
    })

    makeLabel(empty, title, UDim2.fromOffset(0, 3), UDim2.new(1, 0, 0, 21), 12, COLOR.text, Enum.Font.GothamMedium)

    local detailLabel = makeLabel(empty, detail, UDim2.fromOffset(0, 27), UDim2.new(1, 0, 0, 28), 10, COLOR.muted)
    detailLabel.TextWrapped = true
    detailLabel.TextYAlignment = Enum.TextYAlignment.Top
end

local function renderFindings(partsChecked)
    clearResults()

    if #findings == 0 then
        resultsHeading.Text = "RESULTADO"
        showEmpty(
            "Nada chamou atenção nesta leitura.",
            string.format("%d peças conferidas. Isso não substitui um teste no jogo.", partsChecked)
        )
        return
    end

    resultsHeading.Text = string.format(
        "%d PONTO(s) PARA CONFERIR",
        #findings
    )

    for index, finding in ipairs(findings) do
        local row = make("TextButton", results, {
            Name = "Finding_" .. index,
            Size = UDim2.new(1, -4, 0, 76),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            LayoutOrder = index,
        })

        local tone = finding.kind == "hidden" and COLOR.amber or COLOR.purple
        make("Frame", row, {
            Position = UDim2.fromOffset(0, 8),
            Size = UDim2.fromOffset(2, 58),
            BackgroundColor3 = tone,
            BorderSizePixel = 0,
        })

        makeLabel(
            row,
            finding.title,
            UDim2.fromOffset(12, 4),
            UDim2.new(1, -18, 0, 18),
            11,
            COLOR.text,
            Enum.Font.GothamBold
        )

        makeLabel(
            row,
            finding.path,
            UDim2.fromOffset(12, 23),
            UDim2.new(1, -18, 0, 14),
            9,
            COLOR.muted
        )

        local detail = makeLabel(
            row,
            finding.message,
            UDim2.fromOffset(12, 40),
            UDim2.new(1, -18, 0, 31),
            10,
            COLOR.text
        )
        detail.TextWrapped = true
        detail.TextYAlignment = Enum.TextYAlignment.Top

        row.Activated:Connect(function()
            if finding.object and finding.object.Parent then
                Selection:Set({ finding.object })
                statusLabel.Text = "Selecionado no Explorer."
            else
                statusLabel.Text = "Esse objeto não está mais na cena."
            end
        end)
    end
end

local function collectSelectedParts(roots)
    local parts = {}
    local visited = {}

    local function addIfPart(instance)
        if instance:IsA("BasePart") and not visited[instance] then
            visited[instance] = true
            table.insert(parts, instance)
        end
    end

    for _, rootInstance in ipairs(roots) do
        addIfPart(rootInstance)

        for _, descendant in ipairs(rootInstance:GetDescendants()) do
            addIfPart(descendant)
        end
    end

    return parts
end

local function runChecks(parts, token)
    local seenAssemblies = {}

    for index, part in ipairs(parts) do
        if token ~= scanToken then
            return false
        end

        if not hasHumanoidAncestor(part) then
            -- Uma peça quase invisível que bloqueia o jogador.
            if part.Transparency >= 0.95
                and part.CanCollide
                and not hasIntentionalName(part) then

                addFinding(
                    "hidden",
                    "Colisão escondida",
                    "Quase invisível, mas ainda bloqueia o caminho.",
                    part
                )
            end

            -- Só um aviso por conjunto físico, não um aviso por peça conectada.
            local assemblyRoot = part.AssemblyRootPart or part

            if not seenAssemblies[assemblyRoot] then
                seenAssemblies[assemblyRoot] = true

                if assemblyRoot.Parent
                    and not assemblyRoot.Anchored
                    and assemblyRoot.CanCollide
                    and not hasIntentionalName(assemblyRoot) then

                    addFinding(
                        "loose",
                        "Peça sem ancoragem",
                        "Pode se mover com a física. Confira se isso é intencional.",
                        assemblyRoot
                    )
                end
            end
        end

        if index % 180 == 0 then
            statusLabel.Text = string.format(
                "Lendo a seleção... %d de %d peças.",
                index,
                #parts
            )
            task.wait()
        end
    end

    return token == scanToken
end

local function startScan()
    if scanning then
        scanToken += 1
        scanning = false
        scanButton.Text = "VERIFICAR SELEÇÃO"
        statusLabel.Text = "Leitura cancelada."
        return
    end

    local roots = getSelectedRoots()

    if #roots == 0 then
        statusLabel.Text = "Selecione algo dentro do Workspace no Explorer."
        resultsHeading.Text = ""
        showEmpty(
            "Escolha uma parte do mapa.",
            "O Sceneprint só analisa o que você selecionar."
        )
        return
    end

    local parts = collectSelectedParts(roots)

    if #parts == 0 then
        statusLabel.Text = "Não encontrei peças nessa seleção."
        resultsHeading.Text = ""
        showEmpty(
            "Essa seleção não tem peças 3D.",
            "Escolha um Model, Folder ou BasePart dentro do Workspace."
        )
        return
    end

    scanToken += 1
    local token = scanToken
    scanning = true
    table.clear(findings)

    scanButton.Text = "CANCELAR"
    resultsHeading.Text = ""
    clearResults()
    statusLabel.Text = string.format("Lendo %d peças...", #parts)

    task.spawn(function()
        local ok, errorMessage = pcall(function()
            return runChecks(parts, token)
        end)

        if token ~= scanToken then
            return
        end

        scanning = false
        scanButton.Text = "VERIFICAR NOVAMENTE"

        if not ok then
            statusLabel.Text = "Não consegui terminar a leitura."
            resultsHeading.Text = ""
            showEmpty("A leitura foi interrompida.", tostring(errorMessage))
            return
        end

        statusLabel.Text = string.format("%d peças conferidas.", #parts)
        renderFindings(#parts)
    end)
end

scanButton.Activated:Connect(startScan)

Selection.SelectionChanged:Connect(function()
    updateSelectionLabel()
end)

toolbarButton.Click:Connect(function()
    widget.Enabled = not widget.Enabled
    updateSelectionLabel()
end)

updateSelectionLabel()
showEmpty(
    "Escolha uma parte do mapa.",
    "O Sceneprint só analisa o que você selecionar."
)
