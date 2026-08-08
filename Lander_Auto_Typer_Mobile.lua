--[[
    LANDER AUTO TYPER
    Standalone cleaned replacement

    Keeps:
      • notification scanning
      • keyword triggers
      • replacement rules
      • automatic code entry
      • force scan
      • saved settings
      • status log

    Intentionally contains NO:
      • Discord webhook
      • Discord invite/copy link
      • spawn watcher
      • trade/invite logic
      • item-transfer logic
      • HttpGet / loadstring / remote-code loading

    Note: this is an original replacement implementation, not a
    verbatim copy of the third-party source.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local CONFIG_FILE = "lander_auto_typer_config.json"

local config = {
    autoCode = true,
    captureCount = 4,
    keywords = {"code is", "", "", "", "", "", "", "", "", ""},
    replaceRules = {
        {kw = "admin war", rep = "jandel"},
        {kw = "", rep = ""}, {kw = "", rep = ""},
        {kw = "", rep = ""}, {kw = "", rep = ""},
        {kw = "", rep = ""}, {kw = "", rep = ""},
        {kw = "", rep = ""}, {kw = "", rep = ""},
        {kw = "", rep = ""}
    },
    x = -215,
    y = -215,
    minimized = false,
    tab = 1,
    theme = "Black",
    transparency = 0
}

local function saveConfig()
    if not writefile then return end
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(config))
    end)
end

local function loadConfig()
    if not (readfile and isfile and isfile(CONFIG_FILE)) then return end
    pcall(function()
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        if type(data) == "table" then
            for k, v in pairs(data) do
                config[k] = v
            end
        end
    end)
end

loadConfig()

local COLORS = {
    bg = Color3.fromRGB(9, 11, 15),
    panel = Color3.fromRGB(15, 18, 24),
    panel2 = Color3.fromRGB(21, 25, 33),
    panel3 = Color3.fromRGB(28, 33, 43),
    accent = Color3.fromRGB(76, 166, 255),
    accent2 = Color3.fromRGB(122, 196, 255),
    text = Color3.fromRGB(241, 245, 250),
    muted = Color3.fromRGB(143, 154, 170),
    good = Color3.fromRGB(78, 211, 139),
    bad = Color3.fromRGB(236, 91, 103),
    border = Color3.fromRGB(48, 58, 72)
}

local function addCorner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
end

local function addStroke(obj, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.border
    s.Thickness = thickness or 1
    s.Transparency = 0.12
    s.Parent = obj
end

local function newLabel(parent, text, size, position, fontSize, color)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.Size = size
    l.Position = position
    l.Font = Enum.Font.GothamMedium
    l.TextSize = fontSize or 12
    l.TextColor3 = color or COLORS.text
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local autoCode = config.autoCode == true
local captureCount = tonumber(config.captureCount) or 4
local keywords = {}
local replacements = {}

for i = 1, 10 do
    keywords[i] = (type(config.keywords) == "table" and config.keywords[i]) or ""
    local r = type(config.replaceRules) == "table" and config.replaceRules[i]
    replacements[i] = {
        kw = r and r.kw or "",
        rep = r and r.rep or ""
    }
end

local collecting = false
local forceScan = false
local collected = {}
local remaining = 0
local seen = {}
local logEntries = {}

local gui = Instance.new("ScreenGui")
gui.Name = "LanderAutoTyper"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 470, 0, 490)
main.Position = UDim2.new(0.5, config.x, 0.5, config.y)
main.BackgroundColor3 = COLORS.panel
main.BorderSizePixel = 0
main.Parent = gui
addCorner(main, 16)
addStroke(main, COLORS.border, 1)

-- Mobile-friendly scaling keeps the complete panel inside phone screens.
local uiScale = Instance.new("UIScale")
uiScale.Parent = main

local function updateMobileScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local scale = math.min(
        math.max(300, viewport.X - 18) / 470,
        math.max(300, viewport.Y - 18) / 490,
        1
    )
    uiScale.Scale = scale
    if viewport.X < 520 or viewport.Y < 560 then
        main.Position = UDim2.new(0.5, 0, 0.5, 0)
    end
end

updateMobileScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateMobileScale)
end

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 82)
top.BackgroundColor3 = COLORS.bg
top.BorderSizePixel = 0
top.Parent = main
addCorner(top, 16)

local title = newLabel(
    top,
    "LANDER AUTO TYPER",
    UDim2.new(1, -110, 0, 28),
    UDim2.new(0, 20, 0, 12),
    20,
    COLORS.text
)
title.Font = Enum.Font.GothamBlack

local subtitle = newLabel(
    top,
    "Clean code scanner  •  local-only UI",
    UDim2.new(1, -40, 0, 20),
    UDim2.new(0, 20, 0, 43),
    11,
    COLORS.muted
)

local dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 10, 0, 10)
dot.Position = UDim2.new(1, -28, 0, 20)
dot.BackgroundColor3 = COLORS.good
dot.BorderSizePixel = 0
dot.Parent = top
addCorner(dot, 10)

local minButton = Instance.new("TextButton")
minButton.Size = UDim2.new(0, 28, 0, 24)
minButton.Position = UDim2.new(1, -42, 0, 44)
minButton.BackgroundColor3 = COLORS.panel3
minButton.TextColor3 = COLORS.text
minButton.Text = "−"
minButton.Font = Enum.Font.GothamBold
minButton.TextSize = 16
minButton.BorderSizePixel = 0
minButton.Parent = top
addCorner(minButton, 7)

local tabs = Instance.new("Frame")
tabs.Size = UDim2.new(1, -24, 0, 42)
tabs.Position = UDim2.new(0, 12, 0, 92)
tabs.BackgroundTransparency = 1
tabs.Parent = main

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 7)
tabLayout.Parent = tabs

local pages = {}
for i = 1, 5 do
    local p = Instance.new("Frame")
    p.Size = UDim2.new(1, -24, 1, -150)
    p.Position = UDim2.new(0, 12, 0, 144)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.Parent = main
    pages[i] = p
end

local tabButtons = {}
local tabNames = {"Dashboard", "Triggers", "Replace", "Status", "Settings"}

for i, name in ipairs(tabNames) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 104, 1, 0)
    b.BackgroundColor3 = COLORS.panel2
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Text = name
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.TextColor3 = COLORS.muted
    b.Parent = tabs
    addCorner(b, 8)
    addStroke(b, COLORS.border)
    tabButtons[i] = b
end

local function card(parent, y, height)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, height)
    f.Position = UDim2.new(0, 0, 0, y)
    f.BackgroundColor3 = COLORS.panel2
    f.BorderSizePixel = 0
    f.Parent = parent
    addCorner(f, 11)
    addStroke(f, COLORS.border)
    return f
end

-- Dashboard
local dash = pages[1]

local hero = card(dash, 0, 92)
newLabel(hero, "Code Scanner", UDim2.new(1, -24, 0, 24),
    UDim2.new(0, 12, 0, 10), 14, COLORS.text).Font = Enum.Font.GothamBold
newLabel(hero,
    "Watches the game's notification UI and assembles codes\nfrom the configured notification sequence.",
    UDim2.new(1, -24, 0, 45), UDim2.new(0, 12, 0, 36), 10, COLORS.muted)

local forceCard = card(dash, 104, 52)
local force = Instance.new("TextButton")
force.Size = UDim2.new(1, -20, 1, -12)
force.Position = UDim2.new(0, 10, 0, 6)
force.BackgroundColor3 = COLORS.accent
force.BorderSizePixel = 0
force.Text = "FORCE SCAN + REDEEM"
force.Font = Enum.Font.GothamBold
force.TextSize = 12
force.TextColor3 = Color3.new(1, 1, 1)
force.Parent = forceCard
addCorner(force, 8)

local autoCard = card(dash, 168, 52)
newLabel(autoCard, "Automatic Redeem", UDim2.new(1, -110, 1, 0),
    UDim2.new(0, 14, 0, 0), 12, COLORS.text).Font = Enum.Font.GothamBold

local autoToggle = Instance.new("TextButton")
autoToggle.Size = UDim2.new(0, 74, 0, 30)
autoToggle.Position = UDim2.new(1, -88, 0.5, -15)
autoToggle.BorderSizePixel = 0
autoToggle.Font = Enum.Font.GothamBold
autoToggle.TextSize = 10
autoToggle.TextColor3 = Color3.new(1, 1, 1)
autoToggle.Parent = autoCard
addCorner(autoToggle, 8)

local function refreshAuto()
    autoToggle.Text = autoCode and "ON" or "OFF"
    autoToggle.BackgroundColor3 = autoCode and COLORS.good or COLORS.bad
end
refreshAuto()

local countCard = card(dash, 232, 52)
newLabel(countCard, "Notifications per code", UDim2.new(1, -120, 1, 0),
    UDim2.new(0, 14, 0, 0), 12, COLORS.text).Font = Enum.Font.GothamBold

local countBox = Instance.new("TextBox")
countBox.Size = UDim2.new(0, 74, 0, 30)
countBox.Position = UDim2.new(1, -88, 0.5, -15)
countBox.BackgroundColor3 = COLORS.panel3
countBox.BorderSizePixel = 0
countBox.Text = tostring(captureCount)
countBox.Font = Enum.Font.GothamBold
countBox.TextSize = 12
countBox.TextColor3 = COLORS.text
countBox.TextXAlignment = Enum.TextXAlignment.Center
countBox.ClearTextOnFocus = false
countBox.Parent = countCard
addCorner(countBox, 8)
addStroke(countBox, COLORS.border)

local safetyCard = card(dash, 296, 92)
newLabel(safetyCard, "CLEAN BUILD", UDim2.new(1, -24, 0, 22),
    UDim2.new(0, 12, 0, 10), 11, COLORS.good).Font = Enum.Font.GothamBold
newLabel(safetyCard,
    "No Discord webhook • no spawn watcher\nNo remote-code loader • no trade/invite or item-transfer code",
    UDim2.new(1, -24, 0, 48), UDim2.new(0, 12, 0, 34), 10, COLORS.muted)

-- Triggers
local triggerScroll = Instance.new("ScrollingFrame")
triggerScroll.Size = UDim2.new(1, 0, 1, 0)
triggerScroll.BackgroundColor3 = COLORS.panel2
triggerScroll.BorderSizePixel = 0
triggerScroll.ScrollBarThickness = 4
triggerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
triggerScroll.Parent = pages[2]
addCorner(triggerScroll, 11)
addStroke(triggerScroll, COLORS.border)

local triggerLayout = Instance.new("UIListLayout")
triggerLayout.Padding = UDim.new(0, 6)
triggerLayout.Parent = triggerScroll

local triggerPad = Instance.new("UIPadding")
triggerPad.PaddingTop = UDim.new(0, 10)
triggerPad.PaddingBottom = UDim.new(0, 10)
triggerPad.PaddingLeft = UDim.new(0, 10)
triggerPad.PaddingRight = UDim.new(0, 10)
triggerPad.Parent = triggerScroll

newLabel(triggerScroll, "Trigger keywords", UDim2.new(1, 0, 0, 24),
    UDim2.new(), 13, COLORS.text).Font = Enum.Font.GothamBold

for i = 1, 10 do
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 34)
    box.BackgroundColor3 = COLORS.panel3
    box.BorderSizePixel = 0
    box.Text = keywords[i]
    box.PlaceholderText = "Keyword " .. i
    box.PlaceholderColor3 = COLORS.muted
    box.TextColor3 = COLORS.text
    box.Font = Enum.Font.Gotham
    box.TextSize = 11
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = triggerScroll
    addCorner(box, 8)
    addStroke(box, COLORS.border)

    box.FocusLost:Connect(function()
        keywords[i] = box.Text
        config.keywords[i] = box.Text
        saveConfig()
    end)
end

-- Replace
local replaceScroll = Instance.new("ScrollingFrame")
replaceScroll.Size = UDim2.new(1, 0, 1, 0)
replaceScroll.BackgroundColor3 = COLORS.panel2
replaceScroll.BorderSizePixel = 0
replaceScroll.ScrollBarThickness = 4
replaceScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
replaceScroll.Parent = pages[3]
addCorner(replaceScroll, 11)
addStroke(replaceScroll, COLORS.border)

local replaceLayout = Instance.new("UIListLayout")
replaceLayout.Padding = UDim.new(0, 6)
replaceLayout.Parent = replaceScroll

local replacePad = Instance.new("UIPadding")
replacePad.PaddingTop = UDim.new(0, 10)
replacePad.PaddingBottom = UDim.new(0, 10)
replacePad.PaddingLeft = UDim.new(0, 10)
replacePad.PaddingRight = UDim.new(0, 10)
replacePad.Parent = replaceScroll

newLabel(replaceScroll, "Replacement rules", UDim2.new(1, 0, 0, 24),
    UDim2.new(), 13, COLORS.text).Font = Enum.Font.GothamBold

for i = 1, 10 do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = COLORS.panel3
    row.BorderSizePixel = 0
    row.Parent = replaceScroll
    addCorner(row, 8)

    local left = Instance.new("TextBox")
    left.Size = UDim2.new(0.5, -8, 1, -8)
    left.Position = UDim2.new(0, 8, 0, 4)
    left.BackgroundTransparency = 1
    left.Text = replacements[i].kw
    left.PlaceholderText = "Match"
    left.PlaceholderColor3 = COLORS.muted
    left.TextColor3 = COLORS.text
    left.Font = Enum.Font.Gotham
    left.TextSize = 10
    left.ClearTextOnFocus = false
    left.Parent = row

    local right = Instance.new("TextBox")
    right.Size = UDim2.new(0.5, -8, 1, -8)
    right.Position = UDim2.new(0.5, 0, 0, 4)
    right.BackgroundTransparency = 1
    right.Text = replacements[i].rep
    right.PlaceholderText = "Replace with"
    right.PlaceholderColor3 = COLORS.muted
    right.TextColor3 = COLORS.accent2
    right.Font = Enum.Font.Gotham
    right.TextSize = 10
    right.ClearTextOnFocus = false
    right.Parent = row

    left.FocusLost:Connect(function()
        replacements[i].kw = left.Text
        config.replaceRules[i].kw = left.Text
        saveConfig()
    end)

    right.FocusLost:Connect(function()
        replacements[i].rep = right.Text
        config.replaceRules[i].rep = right.Text
        saveConfig()
    end)
end

-- Settings
local settingsPage = pages[5]

local themeCard = card(settingsPage, 0, 118)
newLabel(themeCard, "UI Theme", UDim2.new(1, -24, 0, 24),
    UDim2.new(0, 14, 0, 10), 14, COLORS.text).Font = Enum.Font.GothamBold
newLabel(themeCard, "Black, transparent, or animated RGB.",
    UDim2.new(1, -24, 0, 20), UDim2.new(0, 14, 0, 38), 10, COLORS.muted)

local themeButton = Instance.new("TextButton")
themeButton.Size = UDim2.new(1, -28, 0, 38)
themeButton.Position = UDim2.new(0, 14, 0, 68)
themeButton.BackgroundColor3 = COLORS.panel3
themeButton.BorderSizePixel = 0
themeButton.TextColor3 = COLORS.text
themeButton.Font = Enum.Font.GothamBold
themeButton.TextSize = 11
themeButton.Parent = themeCard
addCorner(themeButton, 8)
addStroke(themeButton, COLORS.border)

local transparencyCard = card(settingsPage, 130, 72)
newLabel(transparencyCard, "Transparency (0-80%)",
    UDim2.new(1, -110, 1, 0), UDim2.new(0, 14, 0, 0),
    11, COLORS.text).Font = Enum.Font.GothamBold

local transparencyBox = Instance.new("TextBox")
transparencyBox.Size = UDim2.new(0, 74, 0, 30)
transparencyBox.Position = UDim2.new(1, -88, 0.5, -15)
transparencyBox.BackgroundColor3 = COLORS.panel3
transparencyBox.BorderSizePixel = 0
transparencyBox.Text = tostring(tonumber(config.transparency) or 0)
transparencyBox.TextColor3 = COLORS.text
transparencyBox.Font = Enum.Font.GothamBold
transparencyBox.TextSize = 11
transparencyBox.TextXAlignment = Enum.TextXAlignment.Center
transparencyBox.ClearTextOnFocus = false
transparencyBox.Parent = transparencyCard
addCorner(transparencyBox, 8)
addStroke(transparencyBox, COLORS.border)

local themeInfo = card(settingsPage, 214, 104)
newLabel(themeInfo, "Mobile controls",
    UDim2.new(1, -24, 0, 22), UDim2.new(0, 14, 0, 10),
    12, COLORS.text).Font = Enum.Font.GothamBold
newLabel(themeInfo,
    "The window automatically scales to your screen.\nDrag the header to reposition it, then use − to minimize.",
    UDim2.new(1, -24, 0, 52), UDim2.new(0, 14, 0, 38),
    10, COLORS.muted)

-- Status
local statusPage = pages[4]

local statusScroll = Instance.new("ScrollingFrame")
statusScroll.Size = UDim2.new(1, 0, 1, -42)
statusScroll.BackgroundColor3 = COLORS.panel2
statusScroll.BorderSizePixel = 0
statusScroll.ScrollBarThickness = 4
statusScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
statusScroll.Parent = statusPage
addCorner(statusScroll, 11)
addStroke(statusScroll, COLORS.border)

local statusLayout = Instance.new("UIListLayout")
statusLayout.Padding = UDim.new(0, 3)
statusLayout.Parent = statusScroll

local statusPad = Instance.new("UIPadding")
statusPad.PaddingTop = UDim.new(0, 8)
statusPad.PaddingBottom = UDim.new(0, 8)
statusPad.PaddingLeft = UDim.new(0, 8)
statusPad.PaddingRight = UDim.new(0, 8)
statusPad.Parent = statusScroll

local clear = Instance.new("TextButton")
clear.Size = UDim2.new(1, 0, 0, 34)
clear.Position = UDim2.new(0, 0, 1, -34)
clear.BackgroundColor3 = COLORS.panel3
clear.BorderSizePixel = 0
clear.Text = "CLEAR LOG"
clear.Font = Enum.Font.GothamBold
clear.TextSize = 10
clear.TextColor3 = COLORS.muted
clear.Parent = statusPage
addCorner(clear, 8)

local function logStatus(message)
    local entry = "[" .. os.date("%H:%M:%S") .. "] " .. message
    table.insert(logEntries, entry)
    print("[LANDER AUTO TYPER] " .. entry)

    if statusScroll then
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -4, 0, 0)
        label.AutomaticSize = Enum.AutomaticSize.Y
        label.BackgroundTransparency = 1
        label.Text = entry
        label.Font = Enum.Font.Code
        label.TextSize = 10
        label.TextColor3 = COLORS.text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextWrapped = true
        label.Parent = statusScroll
        task.defer(function()
            statusScroll.CanvasPosition = Vector2.new(0, math.huge)
        end)
    end
end

clear.MouseButton1Click:Connect(function()
    for _, child in ipairs(statusScroll:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    logEntries = {}
    logStatus("Log cleared")
end)

local function matchesKeyword(text)
    if not text or text == "" then return false end

    local any = false
    for _, keyword in ipairs(keywords) do
        if keyword ~= "" then
            any = true
            break
        end
    end

    if not any then return true end

    local lower = text:lower()
    for _, keyword in ipairs(keywords) do
        if keyword ~= "" and lower:find(keyword:lower(), 1, true) then
            return true
        end
    end
    return false
end

local function applyReplacement(text)
    local lower = text:lower()
    for _, rule in ipairs(replacements) do
        if rule.kw ~= "" and lower:find(rule.kw:lower(), 1, true) then
            return rule.rep
        end
    end
    return nil
end

local function redeemCode(code)
    if type(code) ~= "string" or code == "" then return false end

    local success = false

    pcall(function()
        local codesRoot = PlayerGui:WaitForChild("Codes", 3)
        local codes = codesRoot:WaitForChild("Codes", 3)
        local redeem = codes:WaitForChild("CodeRedeem", 3)
        local textBox = redeem:WaitForChild("TextBox", 3)
        local confirm = codes:WaitForChild("Confirm", 3)

        textBox.Text = code

        local button =
            confirm:FindFirstChildWhichIsA("TextButton")
            or confirm

        if button then
            if firesignal then
                firesignal(button.MouseButton1Click)
                firesignal(button.Activated)
            elseif button:IsA("GuiButton") then
                button:Activate()
            end
            success = true
        end
    end)

    if success then
        logStatus("Redeemed: " .. code)
    else
        logStatus("Codes UI unavailable for: " .. code)
    end

    return success
end

local function dispatch(text)
    if not text or text == "" then return end

    if forceScan and collecting then
        table.insert(collected, text)
        remaining -= 1

        if remaining <= 0 then
            local result = table.concat(collected)
            collecting = false
            forceScan = false
            collected = {}
            remaining = 0

            logStatus("Force scan assembled: " .. result)
            redeemCode(result)
        end
        return
    end

    if captureCount > 0 then
        if collecting then
            local replacement = applyReplacement(text)
            table.insert(collected, replacement ~= nil and replacement or text)
            remaining -= 1

            if remaining <= 0 then
                local result = table.concat(collected)
                collecting = false
                collected = {}
                remaining = 0

                if result ~= "" then
                    logStatus("Code assembled: " .. result)
                    if autoCode then
                        redeemCode(result)
                    end
                end
            end
        elseif matchesKeyword(text) then
            collecting = true
            collected = {}
            remaining = captureCount
            logStatus("Trigger found; collecting " .. captureCount .. " notification(s)")
        end
        return
    end

    if matchesKeyword(text) then
        local replacement = applyReplacement(text)
        local result = replacement ~= nil and replacement or text
        if result ~= "" and autoCode then
            redeemCode(result)
        end
    end
end

local function ownedByUs(obj)
    local current = obj
    while current and current ~= game do
        if current == gui then return true end
        current = current.Parent
    end
    return false
end

local function getText(obj)
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        return obj.Text
    end
end

local function watchObject(obj)
    if seen[obj] or ownedByUs(obj) then return end
    seen[obj] = true

    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        obj:GetPropertyChangedSignal("Text"):Connect(function()
            if not ownedByUs(obj) and obj.Text ~= "" then
                dispatch(obj.Text)
            end
        end)
    end

    for _, child in ipairs(obj:GetDescendants()) do
        watchObject(child)
    end

    obj.DescendantAdded:Connect(function(child)
        if ownedByUs(child) then return end
        local isNew = not seen[child]
        watchObject(child)
        if isNew then
            local text = getText(child)
            if text and text ~= "" then
                dispatch(text)
            end
        end
    end)
end

local function hookNotificationUI()
    local existing = PlayerGui:FindFirstChild("TopNotification")
    if existing then
        watchObject(existing)
    end

    PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "TopNotification" then
            watchObject(child)
        end
    end)
end

force.MouseButton1Click:Connect(function()
    local n = captureCount > 0 and captureCount or 1
    collecting = true
    forceScan = true
    collected = {}
    remaining = n
    logStatus("Force scan armed for " .. n .. " notification(s)")
end)

autoToggle.MouseButton1Click:Connect(function()
    autoCode = not autoCode
    config.autoCode = autoCode
    refreshAuto()
    saveConfig()
    logStatus("Automatic redeem " .. (autoCode and "enabled" or "disabled"))
end)

countBox.FocusLost:Connect(function()
    local n = tonumber(countBox.Text:match("%d+")) or 0
    captureCount = math.max(0, math.floor(n))
    config.captureCount = captureCount
    countBox.Text = tostring(captureCount)
    collecting = false
    forceScan = false
    collected = {}
    remaining = 0
    saveConfig()
end)

local currentTab = math.clamp(tonumber(config.tab) or 1, 1, 5)
local minimized = config.minimized == true
local themes = {"Black", "Transparent", "RGB"}
local themeIndex = 1
for i, name in ipairs(themes) do
    if name == config.theme then
        themeIndex = i
        break
    end
end
local rgbConnection
local rgbStroke = main:FindFirstChildOfClass("UIStroke")

local function applyTheme()
    local theme = themes[themeIndex]
    config.theme = theme
    themeButton.Text = "Theme: " .. theme

    if rgbConnection then
        rgbConnection:Disconnect()
        rgbConnection = nil
    end

    local transparency = math.clamp(tonumber(config.transparency) or 0, 0, 80) / 100

    if theme == "Black" then
        main.BackgroundColor3 = Color3.fromRGB(7, 8, 10)
        top.BackgroundColor3 = Color3.fromRGB(4, 5, 7)
        main.BackgroundTransparency = transparency
        top.BackgroundTransparency = math.min(transparency + 0.05, 0.85)
        if rgbStroke then rgbStroke.Color = COLORS.border end
        dot.BackgroundColor3 = COLORS.good
    elseif theme == "Transparent" then
        main.BackgroundColor3 = Color3.fromRGB(18, 20, 25)
        top.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
        main.BackgroundTransparency = math.max(0.28, transparency)
        top.BackgroundTransparency = math.min(math.max(0.34, transparency + 0.05), 0.85)
        if rgbStroke then rgbStroke.Color = COLORS.border end
        dot.BackgroundColor3 = COLORS.accent
    else
        main.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
        top.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
        main.BackgroundTransparency = transparency
        top.BackgroundTransparency = transparency

        local hue = 0
        rgbConnection = game:GetService("RunService").RenderStepped:Connect(function(dt)
            hue = (hue + dt * 0.12) % 1
            local c = Color3.fromHSV(hue, 0.75, 0.95)
            if rgbStroke then rgbStroke.Color = c end
            dot.BackgroundColor3 = c
        end)
    end

    saveConfig()
end

themeButton.MouseButton1Click:Connect(function()
    themeIndex = (themeIndex % #themes) + 1
    applyTheme()
end)

transparencyBox.FocusLost:Connect(function()
    local n = tonumber(transparencyBox.Text:match("%d+")) or 0
    n = math.clamp(math.floor(n), 0, 80)
    config.transparency = n
    transparencyBox.Text = tostring(n)
    applyTheme()
end)

local function setTab(index)
    currentTab = index
    for i, page in ipairs(pages) do
        page.Visible = (i == index) and not minimized
    end

    for i, button in ipairs(tabButtons) do
        if i == index then
            button.BackgroundColor3 = COLORS.accent
            button.TextColor3 = Color3.new(1, 1, 1)
        else
            button.BackgroundColor3 = COLORS.panel2
            button.TextColor3 = COLORS.muted
        end
    end

    config.tab = index
    saveConfig()
end

for i, button in ipairs(tabButtons) do
    button.MouseButton1Click:Connect(function()
        setTab(i)
    end)
end

local function applyMinimized()
    minimized = config.minimized == true
    tabs.Visible = not minimized

    for _, page in ipairs(pages) do
        page.Visible = false
    end

    minButton.Text = minimized and "+" or "−"

    local targetHeight = minimized and 82 or 490
    TweenService:Create(
        main,
        TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 470, 0, targetHeight)}
    ):Play()

    if not minimized then
        pages[currentTab].Visible = true
    end
end

minButton.MouseButton1Click:Connect(function()
    config.minimized = not config.minimized
    saveConfig()
    applyMinimized()
end)

do
    local dragging = false
    local dragStart
    local startPosition

    top.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        dragStart = input.Position
        startPosition = main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                config.x = main.Position.X.Offset
                config.y = main.Position.Y.Offset
                saveConfig()
            end
        end)
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)
end

setTab(currentTab)
applyMinimized()
hookNotificationUI()

logStatus("Lander Auto Typer loaded")
logStatus("Clean build: no Discord, spawn, trade, or remote-code features")
