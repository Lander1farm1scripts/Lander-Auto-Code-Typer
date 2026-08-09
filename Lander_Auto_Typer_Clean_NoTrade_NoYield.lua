-- ==========================================
-- LANDER AUTO TYPER — Delta Mobile Edition
-- Ultra-polished build with full mobile support.
-- Clean: No webhooks, HTTP loaders, spawn watchers,
-- trade/invite, or item-transfer functionality.
-- ==========================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
if not player then return end

local PlayerGui = player:FindFirstChildOfClass("PlayerGui")
if not PlayerGui then return end

-- ========== CONFIG ==========
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
    minimized = false,
    tab = 1,
    posX = 0.5,
    posY = 0.5,
    miniX = 0.88,
    miniY = 0.12,
}

local function saveConfig()
    if not writefile then return end
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(config)) end)
end

local function loadConfig()
    if not (readfile and isfile and isfile(CONFIG_FILE)) then return end
    pcall(function()
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        if type(data) == "table" then
            for k, v in pairs(data) do config[k] = v end
        end
    end)
end

loadConfig()

-- ========== MOBILE DETECTION ==========
local camera = workspace.CurrentCamera
local viewportSize = camera.ViewportSize
local isMobile = UserInputService.TouchEnabled and (not UserInputService.MouseEnabled or viewportSize.X < 600)

local function computeScale()
    local vw, vh = viewportSize.X, viewportSize.Y
    local guiInset = GuiService:GetGuiInset()
    local availW = vw - 24
    local availH = vh - guiInset.Y - 24
    local scaleW = availW / 470
    local scaleH = availH / 490
    return math.clamp(math.min(scaleW, scaleH), 0.55, 1.15)
end

local uiScaleFactor = computeScale()

-- ========== COLORS ==========
local COLORS = {
    bg        = Color3.fromRGB(9, 11, 15),
    panel     = Color3.fromRGB(15, 18, 24),
    panel2    = Color3.fromRGB(21, 25, 33),
    panel3    = Color3.fromRGB(28, 33, 43),
    panel4    = Color3.fromRGB(34, 40, 52),
    accent    = Color3.fromRGB(76, 166, 255),
    accent2   = Color3.fromRGB(122, 196, 255),
    accentDk  = Color3.fromRGB(40, 110, 200),
    text      = Color3.fromRGB(241, 245, 250),
    muted     = Color3.fromRGB(143, 154, 170),
    good      = Color3.fromRGB(78, 211, 139),
    goodDk    = Color3.fromRGB(40, 160, 100),
    bad       = Color3.fromRGB(236, 91, 103),
    badDk     = Color3.fromRGB(180, 60, 70),
    warn      = Color3.fromRGB(255, 196, 87),
    border    = Color3.fromRGB(48, 58, 72),
    borderLt  = Color3.fromRGB(60, 72, 90),
}

-- ========== UI HELPERS ==========
local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
end

local function stroke(obj, color, thickness, trans)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.border
    s.Thickness = thickness or 1
    s.Transparency = trans or 0.1
    s.Parent = obj
end

local function gradient(obj, color1, color2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(color1, color2)
    g.Rotation = rot or 90
    g.Parent = obj
end

local function pad(obj, all, l, r, t, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or all or 0)
    p.PaddingRight = UDim.new(0, r or all or 0)
    p.PaddingTop = UDim.new(0, t or all or 0)
    p.PaddingBottom = UDim.new(0, b or all or 0)
    p.Parent = obj
end

local function label(parent, text, size, pos, fontSize, color, font)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.Size = size
    l.Position = pos
    l.Font = font or Enum.Font.GothamMedium
    l.TextSize = fontSize or 12
    l.TextColor3 = color or COLORS.text
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function makeButton(parent, text, size, pos, bgColor, textColor, fontSize)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = bgColor or COLORS.panel3
    b.BorderSizePixel = 0
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = fontSize or 12
    b.TextColor3 = textColor or COLORS.text
    b.AutoButtonColor = false
    b.Parent = parent
    corner(b, 8)
    stroke(b, COLORS.border)

    b.MouseButton1Down:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.08), { BackgroundColor3 = bgColor:Lerp(Color3.new(0, 0, 0), 0.2) }):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = bgColor }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = bgColor }):Play()
    end)
    return b
end

-- ========== STATE ==========
local autoCode = config.autoCode == true
local captureCount = tonumber(config.captureCount) or 4

local keywords = {}
local replacements = {}
for i = 1, 10 do
    keywords[i] = (type(config.keywords) == "table" and config.keywords[i]) or ""
    local r = type(config.replaceRules) == "table" and config.replaceRules[i]
    replacements[i] = { kw = r and r.kw or "", rep = r and r.rep or "" }
end

local collecting = false
local forceScan = false
local collected = {}
local remaining = 0
local seen = {}
local logEntries = {}
local lastCode = ""

local collectDeadline = 0
local redeemDeadline = 0

-- ========== GUI ROOT ==========
local gui = Instance.new("ScreenGui")
gui.Name = "LanderAutoTyper"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = PlayerGui

local safeContainer = Instance.new("Frame")
safeContainer.Name = "SafeContainer"
safeContainer.Size = UDim2.new(1, 0, 1, 0)
safeContainer.BackgroundTransparency = 1
safeContainer.Parent = gui

local BASE_W, BASE_H = 470, 490

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, BASE_W, 0, BASE_H)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(config.posX or 0.5, 0, config.posY or 0.5, 0)
main.BackgroundColor3 = COLORS.panel
main.BorderSizePixel = 0
main.Parent = safeContainer
corner(main, 16)
stroke(main, COLORS.borderLt, 1, 0.05)

local shadow = Instance.new("ImageLabel")
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.55
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.ZIndex = main.ZIndex - 1
shadow.Parent = main

local uiScale = Instance.new("UIScale")
uiScale.Scale = uiScaleFactor
uiScale.Parent = main

-- ========== TOP BAR ==========
local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 72)
top.BackgroundColor3 = COLORS.bg
top.BorderSizePixel = 0
top.Parent = main
corner(top, 16)

local topGrad = Instance.new("Frame")
topGrad.Size = UDim2.new(1, 0, 0, 1)
topGrad.Position = UDim2.new(0, 0, 1, -1)
topGrad.BackgroundColor3 = COLORS.border
topGrad.BorderSizePixel = 0
topGrad.Parent = top

local title = label(top, "LANDER AUTO TYPER",
    UDim2.new(1, -110, 0, 28), UDim2.new(0, 20, 0, 14), 18, COLORS.text, Enum.Font.GothamBlack)

label(top, "Clean code scanner  •  Delta Mobile Edition",
    UDim2.new(1, -40, 0, 18), UDim2.new(0, 20, 0, 42), 10, COLORS.muted)

local dotContainer = Instance.new("Frame")
dotContainer.Size = UDim2.new(0, 16, 0, 16)
dotContainer.Position = UDim2.new(1, -34, 0, 22)
dotContainer.BackgroundTransparency = 1
dotContainer.Parent = top

local dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 10, 0, 10)
dot.Position = UDim2.new(0.5, 0, 0.5, 0)
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.BackgroundColor3 = COLORS.good
dot.BorderSizePixel = 0
dot.Parent = dotContainer
corner(dot, 10)

local dotPulse = Instance.new("Frame")
dotPulse.Size = UDim2.new(0, 10, 0, 10)
dotPulse.Position = UDim2.new(0.5, 0, 0.5, 0)
dotPulse.AnchorPoint = Vector2.new(0.5, 0.5)
dotPulse.BackgroundColor3 = COLORS.good
dotPulse.BackgroundTransparency = 0.5
dotPulse.BorderSizePixel = 0
dotPulse.Parent = dotContainer
corner(dotPulse, 10)

local minButton = makeButton(top, "−",
    UDim2.new(0, 32, 0, 28), UDim2.new(1, -44, 0, 22),
    COLORS.panel3, COLORS.text, 16)

-- ========== TABS ==========
local tabs = Instance.new("Frame")
tabs.Size = UDim2.new(1, -24, 0, 34)
tabs.Position = UDim2.new(0, 12, 0, 82)
tabs.BackgroundTransparency = 1
tabs.Parent = main

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.Parent = tabs

local pages = {}
for i = 1, 4 do
    local p = Instance.new("Frame")
    p.Size = UDim2.new(1, -24, 1, -132)
    p.Position = UDim2.new(0, 12, 0, 124)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.Parent = main
    pages[i] = p
end

local tabButtons = {}
local tabNames = { "Dashboard", "Triggers", "Replace", "Status" }

for i, name in ipairs(tabNames) do
    local b = makeButton(tabs, name,
        UDim2.new(0, 108, 1, 0), UDim2.new(0, 0, 0, 0),
        COLORS.panel2, COLORS.muted, 11)
    tabButtons[i] = b
end

local function card(parent, height)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, height)
    f.BackgroundColor3 = COLORS.panel2
    f.BorderSizePixel = 0
    f.Parent = parent
    corner(f, 12)
    stroke(f, COLORS.border)
    f.LayoutOrder = #parent:GetChildren()
    return f
end

-- ========== DASHBOARD ==========
local dash = pages[1]
local dashLayout = Instance.new("UIListLayout")
dashLayout.Padding = UDim.new(0, 8)
dashLayout.Parent = dash

local hero = card(dash, 70)
label(hero, "Code Scanner",
    UDim2.new(1, -24, 0, 20), UDim2.new(0, 14, 0, 10), 13, COLORS.text, Enum.Font.GothamBold)
label(hero, "Watches game notifications and assembles codes\nfrom the configured notification sequence.",
    UDim2.new(1, -24, 0, 32), UDim2.new(0, 14, 0, 32), 10, COLORS.muted)

local previewCard = card(dash, 56)
label(previewCard, "LIVE PREVIEW",
    UDim2.new(0.4, 0, 0, 16), UDim2.new(0, 14, 0, 8), 9, COLORS.muted, Enum.Font.GothamBold)

local previewText = label(previewCard, "—",
    UDim2.new(1, -28, 0, 24), UDim2.new(0, 14, 0, 26), 14, COLORS.accent2, Enum.Font.Code)
previewText.TextXAlignment = Enum.TextXAlignment.Left

local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(1, -28, 0, 4)
progressBg.Position = UDim2.new(0, 14, 0, 46)
progressBg.BackgroundColor3 = COLORS.panel4
progressBg.BorderSizePixel = 0
progressBg.Parent = previewCard
corner(progressBg, 2)

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = COLORS.accent
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBg
corner(progressFill, 2)

local forceCard = card(dash, 44)
local force = makeButton(forceCard, "⚡ FORCE SCAN + REDEEM",
    UDim2.new(1, -20, 1, -12), UDim2.new(0, 10, 0, 6),
    COLORS.accent, Color3.new(1, 1, 1), 12)
gradient(force, COLORS.accent, COLORS.accentDk, 90)

local autoCard = card(dash, 44)
label(autoCard, "Automatic Redeem",
    UDim2.new(1, -96, 1, 0), UDim2.new(0, 14, 0, 0), 12, COLORS.text, Enum.Font.GothamBold)

local autoToggle = makeButton(autoCard, "ON",
    UDim2.new(0, 76, 0, 30), UDim2.new(1, -86, 0.5, -15),
    COLORS.good, Color3.new(1, 1, 1), 10)

local function refreshAuto()
    autoToggle.Text = autoCode and "ON" or "OFF"
    autoToggle.BackgroundColor3 = autoCode and COLORS.good or COLORS.bad
end
refreshAuto()

local countCard = card(dash, 44)
label(countCard, "Notifications per code",
    UDim2.new(1, -96, 1, 0), UDim2.new(0, 14, 0, 0), 12, COLORS.text, Enum.Font.GothamBold)

local countBox = Instance.new("TextBox")
countBox.Size = UDim2.new(0, 76, 0, 30)
countBox.Position = UDim2.new(1, -86, 0.5, -15)
countBox.BackgroundColor3 = COLORS.panel3
countBox.BorderSizePixel = 0
countBox.Text = tostring(captureCount)
countBox.Font = Enum.Font.GothamBold
countBox.TextSize = 12
countBox.TextColor3 = COLORS.text
countBox.TextXAlignment = Enum.TextXAlignment.Center
countBox.ClearTextOnFocus = false
countBox.Parent = countCard
corner(countBox, 8)
stroke(countBox, COLORS.border)

local manualCard = card(dash, 44)
local manualBox = Instance.new("TextBox")
manualBox.Size = UDim2.new(0.62, 0, 0, 30)
manualBox.Position = UDim2.new(0, 10, 0.5, -15)
manualBox.BackgroundColor3 = COLORS.panel3
manualBox.BorderSizePixel = 0
manualBox.Text = ""
manualBox.PlaceholderText = "Manual code…"
manualBox.PlaceholderColor3 = COLORS.muted
manualBox.Font = Enum.Font.Gotham
manualBox.TextSize = 11
manualBox.TextColor3 = COLORS.text
manualBox.TextXAlignment = Enum.TextXAlignment.Left
manualBox.ClearTextOnFocus = false
manualBox.Parent = manualCard
corner(manualBox, 8)
stroke(manualBox, COLORS.border)
pad(manualBox, 8)

local manualRedeem = makeButton(manualCard, "REDEEM",
    UDim2.new(0.36, -6, 0, 30), UDim2.new(0.64, 6, 0.5, -15),
    COLORS.panel4, COLORS.accent2, 10)

-- ========== TRIGGERS TAB ==========
local triggerScroll = Instance.new("ScrollingFrame")
triggerScroll.Size = UDim2.new(1, 0, 1, 0)
triggerScroll.BackgroundColor3 = COLORS.panel2
triggerScroll.BorderSizePixel = 0
triggerScroll.ScrollBarThickness = isMobile and 6 or 4
triggerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
triggerScroll.ScrollBarImageColor3 = COLORS.borderLt
triggerScroll.Parent = pages[2]
corner(triggerScroll, 12)
stroke(triggerScroll, COLORS.border)

local tLayout = Instance.new("UIListLayout")
tLayout.Padding = UDim.new(0, 6)
tLayout.Parent = triggerScroll
pad(triggerScroll, 12)

label(triggerScroll, "Trigger Keywords",
    UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 0), 13, COLORS.text, Enum.Font.GothamBold)

label(triggerScroll, "Notifications containing any keyword start code collection. Leave all empty to capture every notification.",
    UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 24), 9, COLORS.muted)

local triggerDescPad = Instance.new("Frame")
triggerDescPad.Size = UDim2.new(1, 0, 0, 4)
triggerDescPad.BackgroundTransparency = 1
triggerDescPad.Parent = triggerScroll

for i = 1, 10 do
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, isMobile and 40 or 34)
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
    corner(box, 8)
    stroke(box, COLORS.border)
    pad(box, 10)

    box.FocusLost:Connect(function()
        keywords[i] = box.Text
        config.keywords[i] = box.Text
        saveConfig()
    end)
end

-- ========== REPLACE TAB ==========
local replaceScroll = Instance.new("ScrollingFrame")
replaceScroll.Size = UDim2.new(1, 0, 1, 0)
replaceScroll.BackgroundColor3 = COLORS.panel2
replaceScroll.BorderSizePixel = 0
replaceScroll.ScrollBarThickness = isMobile and 6 or 4
replaceScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
replaceScroll.ScrollBarImageColor3 = COLORS.borderLt
replaceScroll.Parent = pages[3]
corner(replaceScroll, 12)
stroke(replaceScroll, COLORS.border)

local rLayout = Instance.new("UIListLayout")
rLayout.Padding = UDim.new(0, 6)
rLayout.Parent = replaceScroll
pad(replaceScroll, 12)

label(replaceScroll, "Replacement Rules",
    UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 0), 13, COLORS.text, Enum.Font.GothamBold)

label(replaceScroll, "If a captured notification matches a rule keyword, it is replaced entirely with the replacement text.",
    UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 24), 9, COLORS.muted)

local replaceDescPad = Instance.new("Frame")
replaceDescPad.Size = UDim2.new(1, 0, 0, 4)
replaceDescPad.BackgroundTransparency = 1
replaceDescPad.Parent = replaceScroll

for i = 1, 10 do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, isMobile and 42 or 36)
    row.BackgroundColor3 = COLORS.panel3
    row.BorderSizePixel = 0
    row.Parent = replaceScroll
    corner(row, 8)

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
    left.TextXAlignment = Enum.TextXAlignment.Left
    left.Parent = row

    local arrow = label(row, "→",
        UDim2.new(0, 12, 1, 0), UDim2.new(0.5, -6, 0, 0), 10, COLORS.muted, Enum.Font.GothamBold)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

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
    right.TextXAlignment = Enum.TextXAlignment.Left
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

-- ========== STATUS TAB ==========
local statusPage = pages[4]

local statusScroll = Instance.new("ScrollingFrame")
statusScroll.Size = UDim2.new(1, 0, 1, -44)
statusScroll.BackgroundColor3 = COLORS.panel2
statusScroll.BorderSizePixel = 0
statusScroll.ScrollBarThickness = isMobile and 6 or 4
statusScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
statusScroll.ScrollBarImageColor3 = COLORS.borderLt
statusScroll.Parent = statusPage
corner(statusScroll, 12)
stroke(statusScroll, COLORS.border)

local sLayout = Instance.new("UIListLayout")
sLayout.Padding = UDim.new(0, 3)
sLayout.Parent = statusScroll
pad(statusScroll, 10)

local clearBtn = makeButton(statusPage, "CLEAR LOG",
    UDim2.new(1, 0, 0, 34), UDim2.new(0, 0, 1, -34),
    COLORS.panel3, COLORS.muted, 10)

local function logStatus(message, logType)
    logType = logType or "info"
    local entry = "[" .. os.date("%H:%M:%S") .. "] " .. message
    table.insert(logEntries, entry)
    if #logEntries > 200 then table.remove(logEntries, 1) end
    print("[LANDER] " .. entry)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -4, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Text = entry
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 10
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local color = COLORS.text
    if logType == "success" then color = COLORS.good
    elseif logType == "error" then color = COLORS.bad
    elseif logType == "warn" then color = COLORS.warn
    elseif logType == "action" then color = COLORS.accent2 end

    lbl.TextColor3 = color
    lbl.Parent = statusScroll

    task.defer(function()
        statusScroll.CanvasPosition = Vector2.new(0, math.huge)
    end)
end

clearBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(statusScroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    logEntries = {}
    logStatus("Log cleared", "info")
end)

-- ========== LOGIC & FILTERS ==========
local lastDispatchedText = ""
local lastDispatchTime = 0

-- Strict filter to ignore game junk (like "Wait 3 seconds" or "<font color=...>")
local function cleanAndValidateText(rawText)
    if not rawText then return nil end
    -- Strip RichText/HTML tags
    local text = rawText:gsub("<[^>]+>", "")
    -- Trim whitespace
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    
    if text == "" then return nil end
    
    local lower = text:lower()
    local junkWords = {"wait", "second", "loading", "please", "verif", "invalid", "expired", "already", "error", "success"}
    for _, word in ipairs(junkWords) do
        if lower:find(word, 1, true) then
            return nil -- It's junk, ignore it completely
        end
    end
    
    return text
end

local function matchesKeyword(text)
    if not text or text == "" then return false end
    local any = false
    for _, kw in ipairs(keywords) do
        if kw ~= "" then any = true break end
    end
    if not any then return true end
    local lower = text:lower()
    for _, kw in ipairs(keywords) do
        if kw ~= "" and lower:find(kw:lower(), 1, true) then
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

local function updatePreview()
    if collecting then
        previewText.Text = table.concat(collected)
        local total = captureCount > 0 and captureCount or 1
        local done = total - remaining
        progressFill.Size = UDim2.new(done / total, 0, 1, 0)
    else
        previewText.Text = lastCode ~= "" and lastCode or "—"
        progressFill.Size = UDim2.new(0, 0, 1, 0)
    end
end

local function setDotColor(color)
    dot.BackgroundColor3 = color
    dotPulse.BackgroundColor3 = color
end

local pulseTween
local function startPulse()
    if pulseTween then pulseTween:Cancel() end
    setDotColor(COLORS.accent)
    pulseTween = TweenService:Create(dotPulse,
        TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Size = UDim2.new(0, 22, 0, 22), BackgroundTransparency = 1 })
    pulseTween:Play()
end

local function stopPulse()
    if pulseTween then pulseTween:Cancel() end
    dotPulse.Size = UDim2.new(0, 10, 0, 10)
    dotPulse.BackgroundTransparency = 0.5
    setDotColor(COLORS.good)
end

local function redeemCode(code)
    if type(code) ~= "string" or code == "" then return false end
    local success = false

    pcall(function()
        local codesRoot = PlayerGui:FindFirstChild("Codes")
        if not codesRoot then return end
        local codes = codesRoot:FindFirstChild("Codes")
        if not codes then return end
        local redeem = codes:FindFirstChild("CodeRedeem")
        if not redeem then return end
        local textBox = redeem:FindFirstChild("TextBox")
        if not textBox then return end
        local confirm = codes:FindFirstChild("Confirm")
        if not confirm then return end

        textBox.Text = code
        task.wait(0.2) -- Wait 0.2s for game to register text

        local button = confirm:FindFirstChildWhichIsA("TextButton") or confirm
        if button then
            if firesignal then
                firesignal(button.MouseButton1Click)
                firesignal(button.Activated)
                success = true
            elseif button:IsA("GuiButton") then
                button:Activate()
                success = true
            end
        end
    end)

    if success then
        lastCode = code
        logStatus("✓ Redeemed: " .. code, "success")
    else
        logStatus("✗ Codes UI unavailable for: " .. code, "error")
    end
    updatePreview()
    return success
end

local function resetCollection()
    collecting = false
    forceScan = false
    collected = {}
    remaining = 0
    collectDeadline = 0
    redeemDeadline = 0
    stopPulse()
    updatePreview()
end

local function setForceScan(state)
    if state then
        local n = captureCount > 0 and captureCount or 1
        collecting = true
        forceScan = true
        collected = {}
        remaining = n
        collectDeadline = os.clock() + 60 -- 60 second timeout
        startPulse()
        updatePreview()
        force.Text = "✖ CANCEL SCAN"
        force.BackgroundColor3 = COLORS.bad
        gradient(force, COLORS.bad, COLORS.badDk, 90)
        logStatus("Force scan armed — waiting for " .. n .. " notification(s)", "action")
    else
        resetCollection()
        force.Text = "⚡ FORCE SCAN + REDEEM"
        force.BackgroundColor3 = COLORS.accent
        gradient(force, COLORS.accent, COLORS.accentDk, 90)
    end
end

local function dispatch(rawText)
    if not rawText or rawText == "" then return end

    -- Filter out junk and rich text
    local text = cleanAndValidateText(rawText)
    if not text then return end

    local now = os.clock()

    if text == lastDispatchedText and (now - lastDispatchTime) < 0.2 then return end
    lastDispatchedText = text
    lastDispatchTime = now

    if collecting and collectDeadline > 0 and now > collectDeadline then
        logStatus("Collection timed out", "warn")
        if forceScan then setForceScan(false) else resetCollection() end
        return
    end

    if forceScan and collecting then
        table.insert(collected, text)
        remaining -= 1
        redeemDeadline = now + 2 -- Wait 2s of silence before redeeming
        updatePreview()
        logStatus("Collected [" .. (#collected) .. "]: " .. text, "info")
        return
    end

    if captureCount > 0 then
        if collecting then
            local replacement = applyReplacement(text)
            local piece = replacement ~= nil and replacement or text
            table.insert(collected, piece)
            remaining -= 1
            redeemDeadline = now + 2 -- Wait 2s of silence before redeeming
            updatePreview()
            logStatus("Collected [" .. (#collected) .. "]: " .. piece, "info")
        elseif matchesKeyword(rawText) then
            collecting = true
            collected = {}
            remaining = captureCount
            collectDeadline = now + 60
            redeemDeadline = now + 2
            startPulse()
            updatePreview()
            logStatus("Trigger found — collecting " .. captureCount .. " notification(s)", "action")
            
            local replacement = applyReplacement(text)
            local piece = replacement ~= nil and replacement or text
            table.insert(collected, piece)
            remaining -= 1
        end
        return
    end

    if matchesKeyword(rawText) then
        local replacement = applyReplacement(text)
        local result = replacement ~= nil and replacement or text
        if result ~= "" then
            lastCode = result
            updatePreview()
            logStatus("Instant code: " .. result, "action")
            if autoCode then 
                local capturedResult = result
                task.delay(2, function()
                    if lastCode == capturedResult then 
                        redeemCode(capturedResult) 
                    end
                end)
            end
        end
    end
end

-- Background loop to wait for the 2-second silence delay
task.spawn(function()
    while true do
        task.wait(0.2)
        if collecting and #collected > 0 and remaining <= 0 and redeemDeadline > 0 and os.clock() > redeemDeadline then
            local result = table.concat(collected)
            local wasForce = forceScan
            resetCollection()
            if result ~= "" then
                if wasForce then
                    logStatus("Force scan assembled: " .. result, "action")
                    redeemCode(result)
                elseif autoCode then
                    logStatus("Code assembled: " .. result, "action")
                    redeemCode(result)
                end
            end
        end
    end
end)

-- ========== NOTIFICATION WATCHER ==========
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

local function hookObject(obj)
    if seen[obj] or ownedByUs(obj) then return end
    seen[obj] = true

    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        obj:GetPropertyChangedSignal("Text"):Connect(function()
            if ownedByUs(obj) or obj.Text == "" then return end
            dispatch(obj.Text)
        end)
        
        if obj.Text and obj.Text ~= "" then 
            dispatch(obj.Text) 
        end
    end

    obj.DescendantAdded:Connect(function(child)
        if ownedByUs(child) then return end
        hookObject(child)
    end)
end

local function watchTree(obj)
    if not obj or ownedByUs(obj) then return end
    hookObject(obj)
    for _, child in ipairs(obj:GetDescendants()) do 
        hookObject(child)
    end
end

local NOTIF_NAMES = {
    "TopNotification", "Notification", "Notifications",
    "Notify", "Toast", "Alert", "MessageLabel"
}

local function hookNotificationUI()
    for _, name in ipairs(NOTIF_NAMES) do
        local existing = PlayerGui:FindFirstChild(name)
        if existing then watchTree(existing) end
    end
    PlayerGui.ChildAdded:Connect(function(child)
        for _, name in ipairs(NOTIF_NAMES) do
            if child.Name == name then
                watchTree(child)
                break
            end
        end
    end)
end

-- ========== EVENT CONNECTIONS ==========
force.MouseButton1Click:Connect(function() setForceScan(not forceScan) end)

autoToggle.MouseButton1Click:Connect(function()
    autoCode = not autoCode
    config.autoCode = autoCode
    refreshAuto()
    saveConfig()
    logStatus("Automatic redeem " .. (autoCode and "enabled" or "disabled"), "info")
end)

countBox.FocusLost:Connect(function()
    local n = tonumber(countBox.Text:match("%d+")) or 0
    captureCount = math.max(0, math.floor(n))
    config.captureCount = captureCount
    countBox.Text = tostring(captureCount)
    if forceScan then setForceScan(false) end
    saveConfig()
    logStatus("Capture count set to " .. captureCount, "info")
end)

manualRedeem.MouseButton1Click:Connect(function()
    local code = manualBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if code == "" then
        logStatus("Manual redeem: no code entered", "warn")
        return
    end
    logStatus("Manual redeem: " .. code, "action")
    redeemCode(code)
    manualBox.Text = ""
end)

-- ========== TAB SWITCHING ==========
local currentTab = math.clamp(tonumber(config.tab) or 1, 1, 4)
local minimized = config.minimized == true

local function setTab(index)
    currentTab = index
    for i, page in ipairs(pages) do page.Visible = (i == index) and not minimized end
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
    button.MouseButton1Click:Connect(function() setTab(i) end)
end

-- ========== MINIMIZE / FLOATING BUTTON ==========
local miniButton = Instance.new("TextButton")
miniButton.Size = UDim2.new(0, 52, 0, 52)
miniButton.AnchorPoint = Vector2.new(0.5, 0.5)
miniButton.Position = UDim2.new(config.miniX or 0.88, 0, config.miniY or 0.12, 0)
miniButton.BackgroundColor3 = COLORS.accent
miniButton.BorderSizePixel = 0
miniButton.Text = "AT"
miniButton.Font = Enum.Font.GothamBlack
miniButton.TextSize = 14
miniButton.TextColor3 = Color3.new(1, 1, 1)
miniButton.AutoButtonColor = false
miniButton.Visible = false
miniButton.Parent = safeContainer
corner(miniButton, 16)
stroke(miniButton, COLORS.accent2, 1.5, 0)
gradient(miniButton, COLORS.accent, COLORS.accentDk, 90)

local miniShadow = Instance.new("ImageLabel")
miniShadow.AnchorPoint = Vector2.new(0.5, 0.5)
miniShadow.Position = UDim2.new(0.5, 0, 0.5, 3)
miniShadow.Size = UDim2.new(1, 16, 1, 16)
miniShadow.BackgroundTransparency = 1
miniShadow.Image = "rbxassetid://1316045217"
miniShadow.ImageColor3 = Color3.new(0, 0, 0)
miniShadow.ImageTransparency = 0.5
miniShadow.ScaleType = Enum.ScaleType.Slice
miniShadow.SliceCenter = Rect.new(10, 10, 118, 118)
miniShadow.ZIndex = miniButton.ZIndex - 1
miniShadow.Parent = miniButton

local miniRing
local function updateMiniPulse()
    if miniRing then miniRing:Destroy() miniRing = nil end
    if collecting and minimized then
        miniRing = Instance.new("Frame")
        miniRing.Size = UDim2.new(1, 0, 1, 0)
        miniRing.AnchorPoint = Vector2.new(0.5, 0.5)
        miniRing.Position = UDim2.new(0.5, 0, 0.5, 0)
        miniRing.BackgroundColor3 = COLORS.accent
        miniRing.BackgroundTransparency = 0.6
        miniRing.BorderSizePixel = 0
        miniRing.Parent = miniButton
        corner(miniRing, 16)
        TweenService:Create(miniRing,
            TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            { Size = UDim2.new(1.5, 0, 1.5, 0), BackgroundTransparency = 1 }):Play()
    end
end

local function applyMinimized()
    minimized = config.minimized == true
    tabs.Visible = not minimized
    for _, page in ipairs(pages) do page.Visible = false end

    minButton.Text = minimized and "+" or "−"
    miniButton.Visible = minimized

    if minimized then
        main.Visible = true
        TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, BASE_W, 0, 72) }):Play()
        task.delay(0.25, function() if minimized then main.Visible = false end end)
        updateMiniPulse()
    else
        main.Visible = true
        TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, BASE_W, 0, BASE_H) }):Play()
        pages[currentTab].Visible = true
        if miniRing then miniRing:Destroy() miniRing = nil end
    end
end

minButton.MouseButton1Click:Connect(function()
    config.minimized = not config.minimized
    saveConfig()
    applyMinimized()
end)

miniButton.MouseButton1Down:Connect(function()
    TweenService:Create(miniButton, TweenInfo.new(0.08), { Size = UDim2.new(0, 46, 0, 46) }):Play()
end)
miniButton.MouseButton1Up:Connect(function()
    TweenService:Create(miniButton, TweenInfo.new(0.12), { Size = UDim2.new(0, 52, 0, 52) }):Play()
end)

-- ========== DRAGGING ==========
do
    local dragging = false
    local dragStart, startPos

    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if dragging then
                        dragging = false
                        config.posX = main.Position.X.Scale
                        config.posY = main.Position.Y.Scale
                        saveConfig()
                    end
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            local newPosX = startPos.X.Scale + (startPos.X.Offset + delta.X) / viewportSize.X
            local newPosY = startPos.Y.Scale + (startPos.Y.Offset + delta.Y) / viewportSize.Y
            newPosX = math.clamp(newPosX, 0.05, 0.95)
            newPosY = math.clamp(newPosY, 0.05, 0.95)
            main.Position = UDim2.new(newPosX, 0, newPosY, 0)
        end
    end)
end

-- Mini Button Drag & Tap Logic
do
    local dragging = false
    miniButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local isDrag = false
            local startPos = input.Position
            local startGuiPos = miniButton.Position
            dragging = false

            local moveConn
            local endConn

            moveConn = UserInputService.InputChanged:Connect(function(moveInput)
                if moveInput.UserInputType == input.UserInputType then
                    local delta = moveInput.Position - startPos
                    if delta.Magnitude > 8 then
                        isDrag = true
                        dragging = true
                        local newPosX = startGuiPos.X.Scale + (startGuiPos.X.Offset + delta.X) / viewportSize.X
                        local newPosY = startGuiPos.Y.Scale + (startGuiPos.Y.Offset + delta.Y) / viewportSize.Y
                        newPosX = math.clamp(newPosX, 0.06, 0.94)
                        newPosY = math.clamp(newPosY, 0.06, 0.94)
                        miniButton.Position = UDim2.new(newPosX, 0, newPosY, 0)
                    end
                end
            end)

            endConn = input.Changed:Connect(function(prop)
                if prop == "UserInputState" and input.UserInputState == Enum.UserInputState.End then
                    moveConn:Disconnect()
                    endConn:Disconnect()
                    if dragging then
                        dragging = false
                        config.miniX = miniButton.Position.X.Scale
                        config.miniY = miniButton.Position.Y.Scale
                        saveConfig()
                    else
                        config.minimized = false
                        saveConfig()
                        applyMinimized()
                    end
                end
            end)
        end
    end)
end

-- ========== RESPONSIVE RESIZE ==========
camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    viewportSize = camera.ViewportSize
    uiScaleFactor = computeScale()
    TweenService:Create(uiScale, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Scale = uiScaleFactor }):Play()
end)

-- ========== INITIALIZATION ==========
main.AnchorPoint = Vector2.new(0.5, 0.5)
config.posX = math.clamp(tonumber(config.posX) or 0.5, 0.1, 0.9)
config.posY = math.clamp(tonumber(config.posY) or 0.5, 0.1, 0.9)
main.Position = UDim2.new(config.posX, 0, config.posY, 0)

config.miniX = math.clamp(tonumber(config.miniX) or 0.88, 0.1, 0.9)
config.miniY = math.clamp(tonumber(config.miniY) or 0.12, 0.1, 0.9)
miniButton.Position = UDim2.new(config.miniX, 0, config.miniY, 0)

setTab(currentTab)
applyMinimized()
hookNotificationUI()
updatePreview()

logStatus("Lander Auto Typer loaded", "success")
logStatus("Platform: " .. (isMobile and "Mobile" or "Desktop") .. "  |  Scale: " .. string.format("%.2f", uiScaleFactor), "info")
logStatus("AutoCode: " .. (autoCode and "ON" or "OFF") .. "  |  Capture: " .. captureCount, "info")

if not isMobile and UserInputService.KeyboardEnabled then
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            config.minimized = not config.minimized
            saveConfig()
            applyMinimized()
        end
    end)
end
