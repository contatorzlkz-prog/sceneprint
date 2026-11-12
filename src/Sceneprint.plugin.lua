--[[
    SCENEPRINT
    Non-destructive place audit for Roblox Studio.
    Version: 0.1.0 | MIT License
]]
assert(plugin, "Sceneprint precisa ser executado como um plugin do Roblox Studio.")

local Selection = game:GetService("Selection")
local Workspace = game:GetService("Workspace")

local C = {
    bg = Color3.fromRGB(15, 15, 19),
    panel = Color3.fromRGB(23, 23, 29),
    panelSoft = Color3.fromRGB(29, 28, 36),
    line = Color3.fromRGB(49, 47, 59),
    text = Color3.fromRGB(239, 237, 245),
    muted = Color3.fromRGB(145, 141, 158),
    accent = Color3.fromRGB(174, 157, 255),
    accentSoft = Color3.fromRGB(64, 56, 91),
    review = Color3.fromRGB(235, 184, 112),
    info = Color3.fromRGB(154, 164, 190),
}

local toolbar = plugin:CreateToolbar("Sceneprint")
local openButton = toolbar:CreateButton("Sceneprint", "Abrir o inspetor de cena", "")
openButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 410, 620, 340, 420)
local widget = plugin:CreateDockWidgetPluginGuiAsync("Sceneprint.Main", widgetInfo)
widget.Title = "Sceneprint | Auditoria de cena"

local function create(className, parent, properties)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    create("UICorner", parent, { CornerRadius = UDim.new(0, radius or 8) })
end

local function stroke(parent, color, transparency)
    create("UIStroke", parent, {
        Color = color or C.line,
        Transparency = transparency or 0,
        Thickness = 1,
    })
end

local function label(parent, text, position, size, textSize, color, font)
    return create("TextLabel", parent, {
        BackgroundTransparency = 1,
        Position = position,
        Size = size,
        Font = font or Enum.Font.Gotham,
        Text = text,
        TextColor3 = color or C.text,
        TextSize = textSize or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end

local root = create("Frame", widget, {
    Name = "SceneprintRoot",
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
})

-- Identidade
local mark = create("Frame", root, {
    Position = UDim2.fromOffset(16, 14),
    Size = UDim2.fromOffset(36, 36),
    BackgroundColor3 = C.accentSoft,
    BorderSizePixel = 0,
})
corner(mark, 10)
local markText = label(mark, "S", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 19, C.accent, Enum.Font.GothamBold)
markText.TextXAlignment = Enum.TextXAlignment.Center
label(root, "sceneprint", UDim2.fromOffset(62, 11), UDim2.new(1, -160, 0, 24), 17, C.text, Enum.Font.GothamBold)
label(root, "AUDITORIA DE CENA", UDim2.fromOffset(63, 34), UDim2.new(1, -160, 0, 15), 9, C.muted, Enum.Font.GothamMedium)
local versionLabel = label(root, "0.1.0", UDim2.new(1, -62, 0, 18), UDim2.fromOffset(46, 20), 10, C.muted)
versionLabel.TextXAlignment = Enum.TextXAlignment.Right

-- Ações
local scanButton = create("TextButton", root, {
    Position = UDim2.fromOffset(16, 64),
    Size = UDim2.new(1, -132, 0, 36),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.GothamBold,
    Text = "ANALISAR CENA",
    TextColor3 = Color3.fromRGB(22, 20, 29),
    TextSize = 11,
})
corner(scanButton, 7)

local scopeButton = create("TextButton", root, {
    Position = UDim2.new(1, -108, 0, 64),
    Size = UDim2.fromOffset(92, 36),
    BackgroundColor3 = C.panelSoft,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.GothamMedium,
    Text = "WORKSPACE",
    TextColor3 = C.text,
    TextSize = 9,
})
corner(scopeButton, 7)
stroke(scopeButton, C.line, 0.15)

-- Resumo
local function statCard(xScale, title)
    local card = create("Frame", root, {
        Position = UDim2.new(xScale, xScale == 0 and 16 or (xScale < 0.5 and 8 or 0), 0, 114),
        Size = UDim2.new(0.333, -16, 0, 58),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
    })
    corner(card, 7)
    stroke(card, C.line, 0.35)
    label(card, title, UDim2.fromOffset(10, 7), UDim2.new(1, -18, 0, 15), 9, C.muted, Enum.Font.GothamMedium)
    return label(card, "—", UDim2.fromOffset(10, 24), UDim2.new(1, -18, 0, 25), 19, C.text, Enum.Font.GothamBold)
end

local reviewValue = statCard(0, "REVISAR")
local infoValue = statCard(0.333, "NOTAS")
local objectValue = statCard(0.666, "OBJETOS")

local progressTrack = create("Frame", root, {
    Position = UDim2.fromOffset(16, 184),
    Size = UDim2.new(1, -32, 0, 3),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
})
corner(progressTrack, 3)
local progressFill = create("Frame", progressTrack, {
    Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
})
corner(progressFill, 3)

local statusLabel = label(root, "Pronto para analisar.", UDim2.fromOffset(16, 190), UDim2.new(1, -32, 0, 18), 10, C.muted)

local filterBar = create("Frame", root, {
    Position = UDim2.fromOffset(16, 216),
    Size = UDim2.new(1, -32, 0, 28),
    BackgroundTransparency = 1,
})
create("UIListLayout", filterBar, {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

local list = create("ScrollingFrame", root, {
    Name = "Findings",
    Position = UDim2.fromOffset(16, 254),
    Size = UDim2.new(1, -32, 1, -294),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.muted,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
})
create("UIListLayout", list, {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
})
label(root, "LEITURA SOMENTE · NENHUMA ALTERAÇÃO AUTOMÁTICA", UDim2.new(0, 16, 1, -30), UDim2.new(1, -32, 0, 18), 9, C.muted)

local findings = {}
local currentFilter = "all"
local currentScope = "workspace"
local scanToken = 0
local scanning = false
local scannedObjectCount = 0
local filterButtons = {}

local function setStatus(message)
    statusLabel.Text = message
end

local function severityColor(severity)
    return severity == "review" and C.review or C.info
end

local function getCounts()
    local reviewCount = 0
    local infoCount = 0
    for _, finding in ipairs(findings) do
        if finding.severity == "review" then
            reviewCount += 1
        else
            infoCount += 1
        end
    end
    return reviewCount, infoCount
end

local function updateSummary()
    local reviewCount, infoCount = getCounts()
    reviewValue.Text = tostring(reviewCount)
    reviewValue.TextColor3 = C.review
    infoValue.Text = tostring(infoCount)
    infoValue.TextColor3 = C.info
    objectValue.Text = tostring(scannedObjectCount)
    objectValue.TextColor3 = C.text
end

local function getPath(instance)
    if not instance then
        return "Workspace"
    end
    local ok, path = pcall(function()
        return instance:GetFullName()
    end)
    if not ok then
        return instance.Name
    end
    if #path > 76 then
        path = "..." .. string.sub(path, #path - 72, #path)
    end
    return path
end

local function clearRows()
    for _, child in ipairs(list:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
end

local function renderFindings()
    clearRows()
    local visibleCount = 0

    for _, finding in ipairs(findings) do
        if currentFilter == "all" or finding.severity == currentFilter then
            visibleCount += 1
            local row = create("TextButton", list, {
                Name = finding.code,
                Size = UDim2.new(1, -8, 0, 104),
                BackgroundColor3 = C.panel,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                LayoutOrder = visibleCount,
            })
            corner(row, 7)
            stroke(row, C.line, 0.4)
            create("Frame", row, {
                Position = UDim2.fromOffset(0, 10),
                Size = UDim2.fromOffset(3, 84),
                BackgroundColor3 = severityColor(finding.severity),
                BorderSizePixel = 0,
            })

            local severityText = finding.severity == "review" and "REVISAR" or "NOTA"
            label(row, finding.code .. "   /   " .. severityText, UDim2.fromOffset(13, 8), UDim2.new(1, -26, 0, 16), 9, severityColor(finding.severity), Enum.Font.GothamBold)
            label(row, finding.title, UDim2.fromOffset(13, 27), UDim2.new(1, -26, 0, 19), 12, C.text, Enum.Font.GothamBold)
            label(row, getPath(finding.object), UDim2.fromOffset(13, 48), UDim2.new(1, -26, 0, 14), 9, C.muted)
            local explanation = label(row, finding.message, UDim2.fromOffset(13, 65), UDim2.new(1, -26, 0, 30), 10, C.text)
            explanation.TextWrapped = true
            explanation.TextYAlignment = Enum.TextYAlignment.Top

            row.Activated:Connect(function()
                if finding.object and finding.object.Parent then
                    Selection:Set({ finding.object })
                    setStatus("Selecionado: " .. finding.object.Name)
                else
                    setStatus("Este apontamento não possui um objeto selecionável.")
                end
            end)
        end
    end

    if visibleCount == 0 then
        local empty = create("Frame", list, {
            Size = UDim2.new(1, -8, 0, 112),
            BackgroundColor3 = C.panel,
            BorderSizePixel = 0,
        })
        corner(empty, 7)
        label(empty, #findings == 0 and "Nenhum apontamento nesta leitura." or "Nenhum resultado neste filtro.", UDim2.fromOffset(14, 25), UDim2.new(1, -28, 0, 22), 12, C.text, Enum.Font.GothamMedium)
        local hint = label(empty, "Isso não certifica que o mapa está perfeito.", UDim2.fromOffset(14, 51), UDim2.new(1, -28, 0, 32), 10, C.muted)
        hint.TextWrapped = true
    end
end

local function updateFilterButtons()
    for name, button in pairs(filterButtons) do
        local active = name == currentFilter
        button.BackgroundColor3 = active and C.accentSoft or C.panel
        button.TextColor3 = active and C.accent or C.muted
    end
end

local filterDefinitions = {
    { id = "all", label = "TUDO", width = 60 },
    { id = "review", label = "REVISAR", width = 76 },
    { id = "info", label = "NOTAS", width = 66 },
}

for order, definition in ipairs(filterDefinitions) do
    local filterButton = create("TextButton", filterBar, {
        Name = "Filter_" .. definition.id,
        Size = UDim2.fromOffset(definition.width, 28),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = definition.label,
        TextColor3 = C.muted,
        TextSize = 9,
        LayoutOrder = order,
    })
    corner(filterButton, 6)
    filterButtons[definition.id] = filterButton
    filterButton.Activated:Connect(function()
        currentFilter = definition.id
        updateFilterButtons()
        renderFindings()
    end)
end
updateFilterButtons()

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

local function addFinding(code, severity, title, message, object)
    table.insert(findings, {
        code = code,
        severity = severity,
        title = title,
        message = message,
        object = object,
    })
end

local function inspectObject(object, counters, seenAssemblies)
    if object:IsA("BasePart") then
        counters.parts += 1

        if object:IsA("MeshPart") and object.CollisionFidelity == Enum.CollisionFidelity.PreciseConvexDecomposition then
            addFinding("GEO-01", "review", "Colisão precisa em MeshPart",
                "A colisão detalhada pode custar mais que Hull ou Box. Compare a forma real com o custo antes de manter esta opção.", object)
        end

        local assemblyRoot = object.AssemblyRootPart or object
        if assemblyRoot == object and not seenAssemblies[object] then
            seenAssemblies[object] = true
            if not object.Anchored and not hasHumanoidAncestor(object) then
                addFinding("PHY-01", "review", "Conjunto físico não ancorado",
                    "Este conjunto pode se mover pela física. Confirme se deveria permanecer no lugar ou se faz parte de uma mecânica.", object)
            end
        end

        if object.Transparency >= 0.98 and object.CanCollide then
            addFinding("COL-01", "review", "Colisão em peça invisível",
                "A peça está quase invisível e ainda bloqueia movimento. Pode ser uma barreira intencional; confira se está posicionada corretamente.", object)
        end
    elseif object:IsA("ParticleEmitter") then
        if object.Rate > 180 then
            addFinding("FX-01", "review", "Emissão intensa de partículas",
                string.format("A taxa está em %d partículas por segundo. Teste em dispositivos mais fracos e considere limitar a emissão.", object.Rate), object)
        end
    elseif object:IsA("PointLight") or object:IsA("SpotLight") or object:IsA("SurfaceLight") then
        if object.Brightness >= 5 and object.Range >= 48 then
            addFinding("LGT-01", "review", "Luz com alcance amplo",
                "Brilho e alcance altos podem aumentar o custo visual em cenas com muitas luzes. Confira o efeito em conjunto com o mapa.", object)
        end
    elseif object:IsA("Sound") then
        if object.RollOffMaxDistance >= 350 then
            addFinding("AUD-01", "review", "Áudio com alcance longo",
                string.format("O alcance máximo está em %.0f studs. Confirme se o som precisa ser ouvido tão longe.", object.RollOffMaxDistance), object)
        end
    elseif object:IsA("ProximityPrompt") then
        if object.MaxActivationDistance > 30 then
            addFinding("UX-01", "review", "Prompt com alcance elevado",
                string.format("O prompt pode ser ativado a %.0f studs. Confira se isso combina com a distância visual da interação.", object.MaxActivationDistance), object)
        end
    elseif object:IsA("Folder") and #object:GetChildren() == 0 then
        addFinding("ORG-01", "info", "Pasta vazia",
            "Esta pasta não contém objetos. Se for apenas uma estrutura reservada, pode ser ignorada.", object)
    end
end

local function sortFindings()
    local order = { review = 1, info = 2 }
    table.sort(findings, function(a, b)
        if order[a.severity] == order[b.severity] then
            if a.code == b.code then
                return getPath(a.object) < getPath(b.object)
            end
            return a.code < b.code
        end
        return order[a.severity] < order[b.severity]
    end)
end

local function finishScan(token, counters, elapsed)
    if token ~= scanToken then
        return
    end
    scanning = false
    scanButton.Text = "ANALISAR NOVAMENTE"
    progressFill.Size = UDim2.fromScale(1, 1)
    scannedObjectCount = counters.total
    sortFindings()
    updateSummary()
    renderFindings()

    local reviewCount, infoCount = getCounts()
    local scopeName = currentScope == "workspace" and "Workspace" or "place inteiro"
    setStatus(string.format("%s: %d objetos • %d revisões • %d notas • %.2fs",
        scopeName, counters.total, reviewCount, infoCount, elapsed))
end

local function startScan()
    if scanning then
        scanToken += 1
        scanning = false
        scanButton.Text = "ANALISAR CENA"
        setStatus("Leitura interrompida.")
        progressFill.Size = UDim2.fromScale(0, 1)
        return
    end

    scanToken += 1
    local token = scanToken
    scanning = true
    scannedObjectCount = 0
    scanButton.Text = "CANCELAR LEITURA"
    progressFill.Size = UDim2.fromScale(0, 1)
    setStatus("Preparando leitura...")
    table.clear(findings)
    updateSummary()
    renderFindings()

    task.spawn(function()
        local startedAt = os.clock()
        local ok, errorMessage = pcall(function()
            local rootToScan = currentScope == "workspace" and Workspace or game
            local descendants = rootToScan:GetDescendants()
            local total = #descendants
            local counters = { total = total, parts = 0 }
            local seenAssemblies = {}

            for index, object in ipairs(descendants) do
                if token ~= scanToken then
                    return
                end
                inspectObject(object, counters, seenAssemblies)

                if index % 180 == 0 then
                    progressFill.Size = UDim2.fromScale(total > 0 and index / total or 1, 1)
                    setStatus(string.format("Lendo %d de %d objetos...", index, total))
                    task.wait()
                end
            end

            if currentScope == "workspace" and counters.parts >= 2500 and not Workspace.StreamingEnabled then
                addFinding("STR-01", "review", "Mapa grande sem streaming",
                    string.format("Foram encontradas %d BaseParts no Workspace e o streaming está desativado. Avalie a estratégia de carregamento e teste antes de mudar.", counters.parts),
                    Workspace)
            end

            finishScan(token, counters, os.clock() - startedAt)
        end)

        if not ok and token == scanToken then
            scanning = false
            scanButton.Text = "TENTAR NOVAMENTE"
            progressFill.Size = UDim2.fromScale(0, 1)
            setStatus("A leitura falhou: " .. tostring(errorMessage))
        end
    end)
end

scanButton.Activated:Connect(startScan)

scopeButton.Activated:Connect(function()
    if scanning then
        setStatus("Interrompa a leitura antes de trocar o escopo.")
        return
    end
    currentScope = currentScope == "workspace" and "place" or "workspace"
    scopeButton.Text = currentScope == "workspace" and "WORKSPACE" or "PLACE INTEIRO"
    setStatus(currentScope == "workspace" and "Escopo: Workspace." or "Escopo: todos os serviços do DataModel.")
end)

openButton.Click:Connect(function()
    widget.Enabled = not widget.Enabled
end)

updateSummary()
renderFindings()
