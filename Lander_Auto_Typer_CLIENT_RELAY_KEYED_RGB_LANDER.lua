-- ==========================================
-- LANDER AUTO TYPER — Premium Mobile Edition
-- Ultra-sleek, compact design.
-- Clean: No webhooks, HTTP loaders, spawn watchers,
-- trade/invite, or item-transfer functionality.
-- ==========================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

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

-- ========== DISCORD RELAY ==========
local RELAY_BASE = "https://discord-snipe-relay.onrender.com"
local RELAY_URL = RELAY_BASE .. "/snipe"
local VERIFY_URL = RELAY_BASE .. "/verify-key"

local function sendToRelay(message)
    if type(RELAY_URL) ~= "string" or RELAY_URL == "" or RELAY_URL:find("YOUR%-RELAY") then
        return
    end

    local request = (syn and syn.request)
        or (http and http.request)
        or (http_request)
        or request

    if not request then
        return
    end

    local ok = pcall(function()
        request({
            Url = RELAY_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                message = message
            })
        })
    end)

    return ok
end

-- ========== 90-MINUTE KEY GATE ==========
local function relayRequest(url, payload)
    local request = (syn and syn.request)
        or (http and http.request)
        or (http_request)
        or request

    if not request then
        return nil, "HTTP request function unavailable"
    end

    local ok, response = pcall(function()
        return request({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if not ok or not response then
        return nil, "Request failed"
    end

    local body = response.Body or response.body or "{}"

    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if not decodeOk then
        return nil, "Invalid relay response"
    end

    local status = tonumber(
        response.StatusCode or response.Status or 0
    ) or 0

    if status < 200 or status >= 300 then
        return nil, data.error or "Invalid or expired key"
    end

    return data
end

local keyVerified = false

-- ========== OWNER BYPASS ==========
-- Put YOUR Roblox UserId here.
-- Do not put your OWNER_KEY or Discord webhook in this Lua file.
local OWNER_USER_ID = 123456789

if player.UserId == OWNER_USER_ID then
    keyVerified = true
end

-- ========== KEY UI ==========
if not keyVerified then

    local keyGui = Instance.new("ScreenGui")
    keyGui.Name = "LanderHubKey"
    keyGui.ResetOnSpawn = false
    keyGui.IgnoreGuiInset = true
    keyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    keyGui.Parent = PlayerGui

    local keyFrame = Instance.new("Frame")
    keyFrame.Name = "KeyFrame"
    keyFrame.Size = UDim2.new(0, 330, 0, 210)
    keyFrame.Position = UDim2.new(0.5, -165, 0.5, -105)
    keyFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
    keyFrame.BorderSizePixel = 0
    keyFrame.Parent = keyGui

    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 12)
    keyCorner.Parent = keyFrame

    local keyStroke = Instance.new("UIStroke")
    keyStroke.Thickness = 2
    keyStroke.Color = Color3.fromRGB(150, 50, 255)
    keyStroke.Transparency = 0.15
    keyStroke.Parent = keyFrame

    local keyTitle = Instance.new("TextLabel")
    keyTitle.Size = UDim2.new(1, -30, 0, 38)
    keyTitle.Position = UDim2.new(0, 15, 0, 12)
    keyTitle.BackgroundTransparency = 1
    keyTitle.Text = "LANDER HUB"
    keyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyTitle.Font = Enum.Font.GothamBlack
    keyTitle.TextSize = 21
    keyTitle.Parent = keyFrame

    local keySubtitle = Instance.new("TextLabel")
    keySubtitle.Size = UDim2.new(1, -30, 0, 25)
    keySubtitle.Position = UDim2.new(0, 15, 0, 45)
    keySubtitle.BackgroundTransparency = 1
    keySubtitle.Text = "Enter your 90-minute key"
    keySubtitle.TextColor3 = Color3.fromRGB(160, 160, 170)
    keySubtitle.Font = Enum.Font.Gotham
    keySubtitle.TextSize = 13
    keySubtitle.Parent = keyFrame

    local keyBox = Instance.new("TextBox")
    keyBox.Name = "KeyBox"
    keyBox.Size = UDim2.new(1, -30, 0, 42)
    keyBox.Position = UDim2.new(0, 15, 0, 77)
    keyBox.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    keyBox.BorderSizePixel = 0
    keyBox.PlaceholderText = "LANDER-XXXXXXXXXXXXXXXX"
    keyBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
    keyBox.Text = ""
    keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextSize = 14
    keyBox.ClearTextOnFocus = false
    keyBox.Parent = keyFrame

    local keyBoxCorner = Instance.new("UICorner")
    keyBoxCorner.CornerRadius = UDim.new(0, 8)
    keyBoxCorner.Parent = keyBox

    local keyButton = Instance.new("TextButton")
    keyButton.Size = UDim2.new(1, -30, 0, 40)
    keyButton.Position = UDim2.new(0, 15, 0, 127)
    keyButton.BackgroundColor3 = Color3.fromRGB(105, 55, 230)
    keyButton.BorderSizePixel = 0
    keyButton.Text = "VERIFY KEY"
    keyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyButton.Font = Enum.Font.GothamBold
    keyButton.TextSize = 14
    keyButton.AutoButtonColor = true
    keyButton.Parent = keyFrame

    local keyButtonCorner = Instance.new("UICorner")
    keyButtonCorner.CornerRadius = UDim.new(0, 8)
    keyButtonCorner.Parent = keyButton

    local keyStatus = Instance.new("TextLabel")
    keyStatus.Size = UDim2.new(1, -30, 0, 27)
    keyStatus.Position = UDim2.new(0, 15, 0, 174)
    keyStatus.BackgroundTransparency = 1
    keyStatus.Text = ""
    keyStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
    keyStatus.Font = Enum.Font.Gotham
    keyStatus.TextSize = 12
    keyStatus.TextWrapped = true
    keyStatus.Parent = keyFrame

    local checking = false

    keyButton.MouseButton1Click:Connect(function()

        if checking or keyVerified then
            return
        end

        local enteredKey = tostring(keyBox.Text or "")
            :gsub("^%s+", "")
            :gsub("%s+$", "")
            :upper()

        if enteredKey == "" then
            keyStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
            keyStatus.Text = "Enter a key."
            return
        end

        checking = true

        keyButton.Text = "CHECKING..."
        keyStatus.TextColor3 = Color3.fromRGB(255, 220, 100)
        keyStatus.Text = "Contacting key server..."

        local data, err = relayRequest(
            VERIFY_URL,
            {
                key = enteredKey
            }
        )

        if data and data.valid == true then

            keyVerified = true

            keyStatus.TextColor3 = Color3.fromRGB(80, 230, 120)
            keyStatus.Text = "Key accepted!"

            task.wait(0.5)

            keyGui:Destroy()

        else

            keyButton.Text = "VERIFY KEY"

            keyStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
            keyStatus.Text = tostring(
                err
                or (data and data.error)
                or "Invalid or expired key."
            )

            checking = false
        end
    end)

    keyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            keyButton:Activate()
        end
    end)

    while not keyVerified do
        task.wait(0.1)
    end
end

-- ========== LOAD CONFIG ==========
local function loadConfig()
    if not (readfile and isfile and isfile(CONFIG_FILE)) then
        return
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)

    if not ok or type(decoded) ~= "table" then
        return
    end

    for key, value in pairs(decoded) do
        if config[key] ~= nil then
            config[key] = value
        end
    end
end

local function saveConfig()
    if not (writefile and readfile) then
        return
    end

    pcall(function()
        writefile(
            CONFIG_FILE,
            HttpService:JSONEncode(config)
        )
    end)
end

loadConfig()

-- ========== COLORS ==========
local COLORS = {
    bg = Color3.fromRGB(10, 10, 14),
    panel = Color3.fromRGB(16, 16, 22),
    panel2 = Color3.fromRGB(25, 25, 34),
    panel3 = Color3.fromRGB(34, 34, 44),

    accent = Color3.fromRGB(145, 55, 255),
    accentLt = Color3.fromRGB(195, 115, 255),

    text = Color3.fromRGB(245, 245, 250),
    muted = Color3.fromRGB(145, 145, 155),

    good = Color3.fromRGB(55, 205, 120),
    bad = Color3.fromRGB(235, 70, 80),
    warn = Color3.fromRGB(245, 190, 65),

    black = Color3.fromRGB(0, 0, 0)
}

-- ========== HELPERS ==========
local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
    return c
end

local function stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.accent
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = obj
    return s
end

local function padding(obj, left, right, top, bottom)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.Parent = obj
    return p
end

local function makeTextLabel(parent, text, size, position)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text or ""
    label.TextColor3 = COLORS.text
    label.Font = Enum.Font.Gotham
    label.TextSize = size or 14
    label.Position = position or UDim2.new()
    label.Size = UDim2.new(1, 0, 0, 25)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

-- ========== GUI ==========
local gui = Instance.new("ScreenGui")
gui.Name = "LanderAutoTyper"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local camera = workspace.CurrentCamera
local viewportSize = camera and camera.ViewportSize or Vector2.new(800, 600)

local BASE_W = 420
local BASE_H = 480

local function computeScale()
    local width = viewportSize.X
    if width < 500 then
        return math.clamp(width / 500, 0.72, 1)
    end
    return 1
end

local uiScaleFactor = computeScale()

local safeContainer = Instance.new("Frame")
safeContainer.Name = "SafeContainer"
safeContainer.BackgroundTransparency = 1
safeContainer.Size = UDim2.new(1, 0, 1, 0)
safeContainer.Parent = gui

local uiScale = Instance.new("UIScale")
uiScale.Scale = uiScaleFactor
uiScale.Parent = safeContainer

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, BASE_W, 0, BASE_H)
main.Position = UDim2.new(
    config.posX or 0.5,
    0,
    config.posY or 0.5,
    0
)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = COLORS.bg
main.BorderSizePixel = 0
main.Parent = safeContainer

corner(main, 14)
stroke(main, COLORS.accent, 1.5, 0.2)

local top = Instance.new("Frame")
top.Name = "Top"
top.Size = UDim2.new(1, 0, 0, 58)
top.BackgroundColor3 = COLORS.panel
top.BorderSizePixel = 0
top.Parent = main

corner(top, 14)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 0, 28)
title.Position = UDim2.new(0, 18, 0, 8)
title.BackgroundTransparency = 1
title.Text = "LANDER'S SCRIPTS"
title.TextColor3 = COLORS.text
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -100, 0, 18)
subtitle.Position = UDim2.new(0, 18, 0, 33)
subtitle.BackgroundTransparency = 1
subtitle.Text = "AUTO CODE TYPER"
subtitle.TextColor3 = COLORS.accentLt
subtitle.Font = Enum.Font.GothamBold
subtitle.TextSize = 10
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = top

local minButton = Instance.new("TextButton")
minButton.Size = UDim2.new(0, 38, 0, 32)
minButton.Position = UDim2.new(1, -84, 0, 13)
minButton.BackgroundColor3 = COLORS.panel2
minButton.BorderSizePixel = 0
minButton.Text = "−"
minButton.TextColor3 = COLORS.text
minButton.Font = Enum.Font.GothamBold
minButton.TextSize = 20
minButton.Parent = top

corner(minButton, 8)

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 38, 0, 32)
closeButton.Position = UDim2.new(1, -42, 0, 13)
closeButton.BackgroundColor3 = COLORS.panel2
closeButton.BorderSizePixel = 0
closeButton.Text = "×"
closeButton.TextColor3 = COLORS.bad
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 20
closeButton.Parent = top

corner(closeButton, 8)

closeButton.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- ========== TABS ==========
local tabs = Instance.new("Frame")
tabs.Name = "Tabs"
tabs.Size = UDim2.new(1, -20, 0, 42)
tabs.Position = UDim2.new(0, 10, 0, 66)
tabs.BackgroundTransparency = 1
tabs.Parent = main

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Padding = UDim.new(0, 5)
tabLayout.Parent = tabs

local tabNames = {
    "Typer",
    "Keywords",
    "Replace",
    "Snipes",
    "Settings"
}

local tabButtons = {}

for i, name in ipairs(tabNames) do
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(
        0,
        math.floor((BASE_W - 40) / #tabNames),
        0,
        34
    )
    button.BackgroundColor3 = COLORS.panel
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = COLORS.muted
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.AutoButtonColor = false
    button.Parent = tabs

    corner(button, 7)

    tabButtons[i] = button
end

-- ========== PAGES ==========
local pages = {}

local function makePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1, -20, 1, -120)
    page.Position = UDim2.new(0, 10, 0, 112)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = COLORS.accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 9)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    padding(page, 4, 4, 4, 10)

    pages[#pages + 1] = page
    return page
end

local typerPage = makePage("Typer")
local keywordPage = makePage("Keywords")
local replacePage = makePage("Replace")
local snipePage = makePage("Snipes")
local settingsPage = makePage("Settings")

-- ========== TYPER PAGE ==========
local autoCode = config.autoCode == true
local captureCount = tonumber(config.captureCount) or 4

local autoToggle = Instance.new("TextButton")
autoToggle.Size = UDim2.new(1, -8, 0, 45)
autoToggle.BackgroundColor3 = COLORS.good
autoToggle.BorderSizePixel = 0
autoToggle.Text = autoCode and "AUTO: ON" or "AUTO: OFF"
autoToggle.TextColor3 = COLORS.text
autoToggle.Font = Enum.Font.GothamBold
autoToggle.TextSize = 14
autoToggle.AutoButtonColor = false
autoToggle.Parent = typerPage

corner(autoToggle, 9)

local countLabel = makeTextLabel(
    typerPage,
    "CAPTURE COUNT",
    11,
    UDim2.new()
)

countLabel.TextColor3 = COLORS.muted
countLabel.Size = UDim2.new(1, -8, 0, 20)

local countBox = Instance.new("TextBox")
countBox.Size = UDim2.new(1, -8, 0, 40)
countBox.BackgroundColor3 = COLORS.panel
countBox.BorderSizePixel = 0
countBox.Text = tostring(captureCount)
countBox.TextColor3 = COLORS.text
countBox.PlaceholderText = "Number of notification parts"
countBox.PlaceholderColor3 = COLORS.muted
countBox.Font = Enum.Font.Gotham
countBox.TextSize = 14
countBox.ClearTextOnFocus = false
countBox.Parent = typerPage

corner(countBox, 8)
stroke(countBox, COLORS.panel3, 1, 0)

local previewLabel = makeTextLabel(
    typerPage,
    "LAST CODE",
    11,
    UDim2.new()
)

previewLabel.TextColor3 = COLORS.muted
previewLabel.Size = UDim2.new(1, -8, 0, 20)

local preview = Instance.new("TextLabel")
preview.Size = UDim2.new(1, -8, 0, 55)
preview.BackgroundColor3 = COLORS.panel
preview.BorderSizePixel = 0
preview.Text = "Waiting..."
preview.TextColor3 = COLORS.text
preview.Font = Enum.Font.GothamBold
preview.TextSize = 16
preview.TextWrapped = true
preview.Parent = typerPage

corner(preview, 8)
padding(preview, 12, 12, 5, 5)

local force = Instance.new("TextButton")
force.Size = UDim2.new(1, -8, 0, 44)
force.BackgroundColor3 = COLORS.accent
force.BorderSizePixel = 0
force.Text = "⚡ FORCE SCAN + REDEEM"
force.TextColor3 = COLORS.text
force.Font = Enum.Font.GothamBold
force.TextSize = 13
force.AutoButtonColor = false
force.Parent = typerPage

corner(force, 9)

local manualLabel = makeTextLabel(
    typerPage,
    "MANUAL REDEEM",
    11,
    UDim2.new()
)

manualLabel.TextColor3 = COLORS.muted
manualLabel.Size = UDim2.new(1, -8, 0, 20)

local manualRow = Instance.new("Frame")
manualRow.Size = UDim2.new(1, -8, 0, 42)
manualRow.BackgroundTransparency = 1
manualRow.Parent = typerPage

local manualBox = Instance.new("TextBox")
manualBox.Size = UDim2.new(1, -95, 1, 0)
manualBox.BackgroundColor3 = COLORS.panel
manualBox.BorderSizePixel = 0
manualBox.Text = ""
manualBox.PlaceholderText = "Enter code..."
manualBox.PlaceholderColor3 = COLORS.muted
manualBox.TextColor3 = COLORS.text
manualBox.Font = Enum.Font.Gotham
manualBox.TextSize = 13
manualBox.ClearTextOnFocus = false
manualBox.Parent = manualRow

corner(manualBox, 8)

local manualRedeem = Instance.new("TextButton")
manualRedeem.Size = UDim2.new(0, 88, 1, 0)
manualRedeem.Position = UDim2.new(1, -88, 0, 0)
manualRedeem.BackgroundColor3 = COLORS.panel3
manualRedeem.BorderSizePixel = 0
manualRedeem.Text = "REDEEM"
manualRedeem.TextColor3 = COLORS.text
manualRedeem.Font = Enum.Font.GothamBold
manualRedeem.TextSize = 11
manualRedeem.Parent = manualRow

corner(manualRedeem, 8)

-- ========== KEYWORDS PAGE ==========
local keywordBoxes = {}

for i = 1, 10 do

    local label = makeTextLabel(
        keywordPage,
        "KEYWORD " .. i,
        10,
        UDim2.new()
    )

    label.TextColor3 = COLORS.muted
    label.Size = UDim2.new(1, -8, 0, 18)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -8, 0, 38)
    box.BackgroundColor3 = COLORS.panel
    box.BorderSizePixel = 0
    box.Text = tostring(config.keywords[i] or "")
    box.PlaceholderText = "Example: code is"
    box.PlaceholderColor3 = COLORS.muted
    box.TextColor3 = COLORS.text
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.Parent = keywordPage

    corner(box, 8)

    keywordBoxes[i] = box

    box.FocusLost:Connect(function()
        config.keywords[i] = box.Text
        saveConfig()
    end)
end

-- ========== REPLACE PAGE ==========
local replaceBoxes = {}

for i = 1, 10 do

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 40)
    row.BackgroundTransparency = 1
    row.Parent = replacePage

    local kw = Instance.new("TextBox")
    kw.Size = UDim2.new(0.48, -3, 1, 0)
    kw.BackgroundColor3 = COLORS.panel
    kw.BorderSizePixel = 0
    kw.Text = tostring(
        config.replaceRules[i]
        and config.replaceRules[i].kw
        or ""
    )
    kw.PlaceholderText = "Keyword"
    kw.PlaceholderColor3 = COLORS.muted
    kw.TextColor3 = COLORS.text
    kw.Font = Enum.Font.Gotham
    kw.TextSize = 12
    kw.ClearTextOnFocus = false
    kw.Parent = row

    corner(kw, 7)

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 25, 1, 0)
    arrow.Position = UDim2.new(0.48, 1, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "→"
    arrow.TextColor3 = COLORS.accentLt
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 16
    arrow.TextXAlignment = Enum.TextXAlignment.Center
    arrow.Parent = row

    local rep = Instance.new("TextBox")
    rep.Size = UDim2.new(0.48, -3, 1, 0)
    rep.Position = UDim2.new(0.52, 0, 0, 0)
    rep.BackgroundColor3 = COLORS.panel
    rep.BorderSizePixel = 0
    rep.Text = tostring(
        config.replaceRules[i]
        and config.replaceRules[i].rep
        or ""
    )
    rep.PlaceholderText = "Replacement"
    rep.PlaceholderColor3 = COLORS.muted
    rep.TextColor3 = COLORS.text
    rep.Font = Enum.Font.Gotham
    rep.TextSize = 12
    rep.ClearTextOnFocus = false
    rep.Parent = row

    corner(rep, 7)

    replaceBoxes[i] = {
        kw = kw,
        rep = rep
    }

    kw.FocusLost:Connect(function()
        config.replaceRules[i].kw = kw.Text
        saveConfig()
    end)

    rep.FocusLost:Connect(function()
        config.replaceRules[i].rep = rep.Text
        saveConfig()
    end)
end

-- ========== SNIPE PAGE ==========
local snipeTitle = makeTextLabel(
    snipePage,
    "SNIPE LOG",
    11,
    UDim2.new()
)

snipeTitle.TextColor3 = COLORS.accentLt
snipeTitle.Size = UDim2.new(1, -8, 0, 22)

local snipeList = Instance.new("ScrollingFrame")
snipeList.Size = UDim2.new(1, -8, 0, 220)
snipeList.BackgroundColor3 = COLORS.panel
snipeList.BorderSizePixel = 0
snipeList.ScrollBarThickness = 3
snipeList.ScrollBarImageColor3 = COLORS.accent
snipeList.CanvasSize = UDim2.new(0, 0, 0, 0)
snipeList.AutomaticCanvasSize = Enum.AutomaticSize.Y
snipeList.Parent = snipePage

corner(snipeList, 9)

local snipeLayout = Instance.new("UIListLayout")
snipeLayout.Padding = UDim.new(0, 5)
snipeLayout.SortOrder = Enum.SortOrder.LayoutOrder
snipeLayout.Parent = snipeList

padding(snipeList, 8, 8, 8, 8)

local noSnipes = Instance.new("TextLabel")
noSnipes.Size = UDim2.new(1, -8, 0, 40)
noSnipes.BackgroundTransparency = 1
noSnipes.Text = "No snipes yet."
noSnipes.TextColor3 = COLORS.muted
noSnipes.Font = Enum.Font.Gotham
noSnipes.TextSize = 12
noSnipes.Parent = snipeList

local function addSnipe(message, color)
    if noSnipes and noSnipes.Parent then
        noSnipes:Destroy()
    end

    local item = Instance.new("TextLabel")
    item.Size = UDim2.new(1, 0, 0, 42)
    item.BackgroundColor3 = COLORS.panel2
    item.BorderSizePixel = 0
    item.Text = message
    item.TextColor3 = color or COLORS.text
    item.Font = Enum.Font.GothamBold
    item.TextSize = 12
    item.TextWrapped = true
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.Parent = snipeList

    corner(item, 7)
    padding(item, 10, 8, 4, 4)

    task.delay(30, function()
        if item and item.Parent then
            item:Destroy()
        end
    end)
end

-- ========== SETTINGS PAGE ==========
local settingsTitle = makeTextLabel(
    settingsPage,
    "SETTINGS",
    11,
    UDim2.new()
)

settingsTitle.TextColor3 = COLORS.accentLt
settingsTitle.Size = UDim2.new(1, -8, 0, 22)

local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.new(1, -8, 0, 42)
resetButton.BackgroundColor3 = COLORS.panel2
resetButton.BorderSizePixel = 0
resetButton.Text = "RESET CONFIG"
resetButton.TextColor3 = COLORS.text
resetButton.Font = Enum.Font.GothamBold
resetButton.TextSize = 13
resetButton.Parent = settingsPage

corner(resetButton, 8)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -8, 0, 60)
statusLabel.BackgroundColor3 = COLORS.panel
statusLabel.BorderSizePixel = 0
statusLabel.Text = "Status: Ready"
statusLabel.TextColor3 = COLORS.muted
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = settingsPage

corner(statusLabel, 8)
padding(statusLabel, 10, 10, 8, 8)

local function logStatus(message, kind)
    local color = COLORS.muted

    if kind == "success" then
        color = COLORS.good
    elseif kind == "warn" then
        color = COLORS.warn
    elseif kind == "action" then
        color = COLORS.accentLt
    elseif kind == "error" then
        color = COLORS.bad
    elseif kind == "info" then
        color = COLORS.text
    end

    statusLabel.TextColor3 = color
    statusLabel.Text = "Status: " .. tostring(message)
end

resetButton.MouseButton1Click:Connect(function()
    config = {
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

    autoCode = true
    captureCount = 4

    countBox.Text = "4"

    for i, box in ipairs(keywordBoxes) do
        box.Text = tostring(config.keywords[i] or "")
    end

    for i, pair in ipairs(replaceBoxes) do
        pair.kw.Text = tostring(
            config.replaceRules[i].kw or ""
        )
        pair.rep.Text = tostring(
            config.replaceRules[i].rep or ""
        )
    end

    refreshAuto()
    saveConfig()
    logStatus("Configuration reset.", "success")
end)

-- ========== STATE ==========
local collected = {}
local remaining = 0
local collecting = false
local forceScan = false

local collectDeadline = 0
local redeemDeadline = 0

local lastCode = ""
local lastDispatchedText = ""
local lastDispatchTime = 0

local pulseTween
local rewardWatchArmed = false
local rewardWatchDeadline = 0
local rewardWatchSeen = {}
local seen = {}

local function startPulse()
    if pulseTween then
        pulseTween:Cancel()
        pulseTween = nil
    end

    pulseTween = TweenService:Create(
        force,
        TweenInfo.new(
            0.65,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut,
            -1,
            true
        ),
        {
            BackgroundTransparency = 0.25
        }
    )

    pulseTween:Play()
end

local function stopPulse()
    if pulseTween then
        pulseTween:Cancel()
        pulseTween = nil
    end

    force.BackgroundTransparency = 0
end

local function updatePreview()
    if #collected > 0 then
        preview.Text = table.concat(collected)
    elseif lastCode ~= "" then
        preview.Text = lastCode
    else
        preview.Text = "Waiting..."
    end
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

local function cleanAndValidateText(text)
    if type(text) ~= "string" then
        return nil
    end

    text = text:gsub("<.->", "")
    text = text:gsub("%s+", " ")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")

    if text == "" then
        return nil
    end

    return text
end

local function matchesKeyword(text)
    local lower = string.lower(text or "")

    for _, keyword in ipairs(config.keywords or {}) do
        if keyword and keyword ~= "" then
            if string.find(
                lower,
                string.lower(keyword),
                1,
                true
            ) then
                return true
            end
        end
    end

    return false
end

local function applyReplacement(text)
    local lower = string.lower(text)

    for _, rule in ipairs(config.replaceRules or {}) do
        local kw = tostring(rule.kw or "")
        local rep = tostring(rule.rep or "")

        if kw ~= "" and string.find(
            lower,
            string.lower(kw),
            1,
            true
        ) then
            return rep
        end
    end

    return nil
end

local function redeemCode(code)
    if type(code) ~= "string" or code == "" then
        return
    end

    local ok = pcall(function()

        local playerGui = player:FindFirstChildOfClass(
            "PlayerGui"
        )

        if not playerGui then
            return
        end

        local events = game:GetService("ReplicatedStorage")

        local redeemRemote =
            events:FindFirstChild("RedeemCode")
            or events:FindFirstChild("Redeem")
            or events:FindFirstChild("RedeemCodeEvent")

        if redeemRemote and redeemRemote:IsA("RemoteEvent") then
            redeemRemote:FireServer(code)
        elseif redeemRemote and redeemRemote:IsA("RemoteFunction") then
            redeemRemote:InvokeServer(code)
        end
    end)

    if ok then
        logStatus("Redeemed: " .. code, "success")
    else
        logStatus("Redeem failed.", "error")
    end
end

local function setForceScan(state)
    if state then

        local n = captureCount > 0
            and captureCount
            or 1

        collecting = true
        forceScan = true
        collected = {}
        remaining = n
        collectDeadline = os.clock() + 60

        startPulse()
        updatePreview()

        force.Text = "✖ CANCEL SCAN"
        force.BackgroundColor3 = COLORS.bad

        logStatus(
            "Force scan armed — waiting for "
            .. n
            .. " notification(s)",
            "action"
        )

    else

        resetCollection()

        force.Text = "⚡ FORCE SCAN + REDEEM"
        force.BackgroundColor3 = COLORS.accent
    end
end

local function dispatch(rawText)

    if not rawText or rawText == "" then
        return
    end

    local text = cleanAndValidateText(rawText)

    if not text then
        return
    end

    local now = os.clock()

    if text == lastDispatchedText
        and (now - lastDispatchTime) < 0.2 then
        return
    end

    lastDispatchedText = text
    lastDispatchTime = now

    if collecting
        and collectDeadline > 0
        and now > collectDeadline then

        logStatus(
            "Collection timed out",
            "warn"
        )

        if forceScan then
            setForceScan(false)
        else
            resetCollection()
        end

        return
    end

    if forceScan and collecting then

        table.insert(collected, text)
        remaining -= 1
        redeemDeadline = now + 2

        updatePreview()

        logStatus(
            "Collected ["
            .. (#collected)
            .. "]: "
            .. text,
            "info"
        )

        return
    end

    if captureCount > 0 then

        if collecting then

            local replacement = applyReplacement(text)
            local piece =
                replacement ~= nil
                and replacement
                or text

            table.insert(collected, piece)
            remaining -= 1
            redeemDeadline = now + 2

            updatePreview()

            logStatus(
                "Collected ["
                .. (#collected)
                .. "]: "
                .. piece,
                "info"
            )

        elseif matchesKeyword(rawText) then

            collecting = true
            collected = {}
            remaining = captureCount
            collectDeadline = now + 60
            redeemDeadline = now + 2

            startPulse()
            updatePreview()

            logStatus(
                "Trigger found — collecting "
                .. captureCount
                .. " notification(s)",
                "action"
            )

            local replacement = applyReplacement(text)

            local piece =
                replacement ~= nil
                and replacement
                or text

            table.insert(collected, piece)
            remaining -= 1
        end

        return
    end

    if matchesKeyword(rawText) then

        local replacement = applyReplacement(text)

        local result =
            replacement ~= nil
            and replacement
            or text

        if result ~= "" then

            lastCode = result

            updatePreview()

            logStatus(
                "Instant code: " .. result,
                "action"
            )

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

-- ========== REWARD WATCHER ==========
local function snapshotRewardSlots()
    local result = {}

    local guiObjects = PlayerGui:GetDescendants()

    for _, obj in ipairs(guiObjects) do
        if obj:IsA("GuiObject") then
            if obj.Visible then
                result[obj] = true
            end
        end
    end

    return result
end

local function getRewardName(obj)
    if not obj then
        return "Unknown reward"
    end

    local name = obj.Name

    if obj:IsA("TextLabel")
        or obj:IsA("TextButton")
        or obj:IsA("TextBox") then

        if obj.Text and obj.Text ~= "" then
            name = obj.Text
        end
    end

    return tostring(name)
end

local function stopRewardWatcher()
    rewardWatchArmed = false
    rewardWatchDeadline = 0
    rewardWatchSeen = {}
end

task.spawn(function()

    while true do

        task.wait(0.2)

        if rewardWatchArmed then

            if os.clock() > rewardWatchDeadline then

                logStatus(
                    "Reward watcher timed out",
                    "warn"
                )

                stopRewardWatcher()

            else

                local current = snapshotRewardSlots()
                local added = false

                for obj in pairs(current) do

                    if not rewardWatchSeen[obj] then

                        added = true
                        rewardWatchSeen[obj] = true

                        local rewardName =
                            getRewardName(obj)

                        local rewardMessage =
                            "Wow! "
                            .. player.Name
                            .. " got "
                            .. rewardName
                            .. "!"

                        logStatus(
                            rewardMessage,
                            "success"
                        )

                        addSnipe(
                            rewardMessage,
                            COLORS.good
                        )

                        task.spawn(
                            sendToRelay,
                            "🎉 " .. rewardMessage
                        )

                        stopRewardWatcher()

                        break
                    end
                end

                if not added then
                    rewardWatchSeen = current
                end
            end
        end
    end
end)

-- ========== REDEEM WATCHER ==========
task.spawn(function()

    while true do

        task.wait(0.2)

        if collecting
            and #collected > 0
            and remaining <= 0
            and redeemDeadline > 0
            and os.clock() > redeemDeadline then

            local result = table.concat(collected)
            local wasForce = forceScan

            resetCollection()

            if result ~= "" then

                if wasForce then

                    logStatus(
                        "Force scan assembled: "
                        .. result,
                        "action"
                    )

                    redeemCode(result)

                elseif autoCode then

                    logStatus(
                        "Code assembled: "
                        .. result,
                        "action"
                    )

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

        if current == gui then
            return true
        end

        current = current.Parent
    end

    return false
end

local function hookObject(obj)

    if seen[obj] or ownedByUs(obj) then
        return
    end

    seen[obj] = true

    if obj:IsA("TextLabel")
        or obj:IsA("TextButton")
        or obj:IsA("TextBox") then

        obj:GetPropertyChangedSignal("Text"):Connect(
            function()

                if ownedByUs(obj)
                    or obj.Text == "" then
                    return
                end

                dispatch(obj.Text)
            end
        )

        if obj.Text and obj.Text ~= "" then
            dispatch(obj.Text)
        end
    end

    obj.DescendantAdded:Connect(function(child)

        if ownedByUs(child) then
            return
        end

        hookObject(child)
    end)
end

local function watchTree(obj)

    if not obj or ownedByUs(obj) then
        return
    end

    hookObject(obj)

    for _, child in ipairs(obj:GetDescendants()) do
        hookObject(child)
    end
end

local function hookNotificationUI()

    for _, name in ipairs({
        "TopNotification",
        "Notification",
        "Notifications",
        "Notify",
        "Toast",
        "Alert",
        "MessageLabel"
    }) do

        local existing =
            PlayerGui:FindFirstChild(name)

        if existing then
            watchTree(existing)
        end
    end

    PlayerGui.ChildAdded:Connect(function(child)

        for _, name in ipairs({
            "TopNotification",
            "Notification",
            "Notifications",
            "Notify",
            "Toast",
            "Alert",
            "MessageLabel"
        }) do

            if child.Name == name then
                watchTree(child)
                break
            end
        end
    end)
end

-- ========== EVENTS ==========
force.MouseButton1Click:Connect(function()
    setForceScan(not forceScan)
end)

local function refreshAuto()

    autoToggle.Text =
        autoCode
        and "AUTO: ON"
        or "AUTO: OFF"

    autoToggle.BackgroundColor3 =
        autoCode
        and COLORS.good
        or COLORS.panel3
end

autoToggle.MouseButton1Click:Connect(function()

    autoCode = not autoCode
    config.autoCode = autoCode

    refreshAuto()
    saveConfig()
end)

countBox.FocusLost:Connect(function()

    local n =
        tonumber(
            countBox.Text:match("%d+")
        )
        or 0

    captureCount =
        math.max(
            0,
            math.floor(n)
        )

    config.captureCount = captureCount

    countBox.Text =
        tostring(captureCount)

    if forceScan then
        setForceScan(false)
    end

    saveConfig()
end)

manualRedeem.MouseButton1Click:Connect(function()

    local code =
        manualBox.Text
        :gsub("^%s+", "")
        :gsub("%s+$", "")

    if code == "" then
        return
    end

    logStatus(
        "Manual redeem: " .. code,
        "action"
    )

    redeemCode(code)

    manualBox.Text = ""
end)

-- ========== TAB SWITCHING ==========
local currentTab =
    math.clamp(
        tonumber(config.tab) or 1,
        1,
        5
    )

local minimized =
    config.minimized == true

local function setTab(index)

    currentTab = index

    for i, page in ipairs(pages) do

        page.Visible =
            (i == index)
            and not minimized
    end

    for i, button in ipairs(tabButtons) do

        local isSelected =
            i == index

        button.BackgroundColor3 =
            isSelected
            and COLORS.panel2
            or COLORS.panel

        button.TextColor3 =
            isSelected
            and COLORS.text
            or COLORS.muted
    end

    config.tab = index

    saveConfig()
end

for i, button in ipairs(tabButtons) do

    button.MouseButton1Click:Connect(
        function()
            setTab(i)
        end
    )
end

-- ========== MINIMIZE / FLOATING BUTTON ==========
local miniButton = Instance.new("TextButton")

miniButton.Name = "LanderFloatingButton"

miniButton.Size =
    UDim2.new(
        0,
        86,
        0,
        46
    )

miniButton.AnchorPoint =
    Vector2.new(
        0.5,
        0.5
    )

miniButton.Position =
    UDim2.new(
        config.miniX or 0.88,
        0,
        config.miniY or 0.12,
        0
    )

miniButton.BackgroundColor3 =
    Color3.fromRGB(
        255,
        0,
        0
    )

miniButton.BorderSizePixel = 0

miniButton.Text = "LANDER"

miniButton.Font =
    Enum.Font.GothamBlack

miniButton.TextSize = 15

miniButton.TextColor3 =
    Color3.new(
        1,
        1,
        1
    )

miniButton.AutoButtonColor = false
miniButton.Visible = false
miniButton.Parent = safeContainer

corner(
    miniButton,
    12
)

stroke(
    miniButton,
    Color3.fromRGB(
        255,
        255,
        255
    ),
    1,
    0.15
)

-- ========== RGB LANDER BUTTON ==========
local miniRgbConnection

miniRgbConnection =
    RunService.RenderStepped:Connect(
        function()

            if miniButton
                and miniButton.Parent then

                miniButton.BackgroundColor3 =
                    Color3.fromHSV(
                        (os.clock() * 0.18) % 1,
                        0.9,
                        1
                    )

            elseif miniRgbConnection then

                miniRgbConnection:Disconnect()
                miniRgbConnection = nil
            end
        end
    )

local miniRing

local function updateMiniPulse()

    if miniRing then
        miniRing:Destroy()
        miniRing = nil
    end

    if collecting and minimized then

        miniRing = Instance.new("Frame")

        miniRing.Size =
            UDim2.new(
                1,
                0,
                1,
                0
            )

        miniRing.AnchorPoint =
            Vector2.new(
                0.5,
                0.5
            )

        miniRing.Position =
            UDim2.new(
                0.5,
                0,
                0.5,
                0
            )

        miniRing.BackgroundColor3 =
            COLORS.accent

        miniRing.BackgroundTransparency =
            0.6

        miniRing.BorderSizePixel = 0

        miniRing.Parent = miniButton

        corner(
            miniRing,
            12
        )

        TweenService:Create(
            miniRing,
            TweenInfo.new(
                1,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut,
                -1,
                true
            ),
            {
                Size =
                    UDim2.new(
                        1.5,
                        0,
                        1.5,
                        0
                    ),

                BackgroundTransparency = 1
            }
        ):Play()
    end
end

local function applyMinimized()

    minimized =
        config.minimized == true

    tabs.Visible =
        not minimized

    for _, page in ipairs(pages) do
        page.Visible = false
    end

    minButton.Text =
        minimized
        and "+"
        or "−"

    miniButton.Visible =
        minimized

    if minimized then

        main.Visible = true

        TweenService:Create(
            main,
            TweenInfo.new(
                0.25,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {
                Size =
                    UDim2.new(
                        0,
                        BASE_W,
                        0,
                        44
                    )
            }
        ):Play()

        task.delay(
            0.25,
            function()

                if minimized then
                    main.Visible = false
                end
            end
        )

        updateMiniPulse()

    else

        main.Visible = true

        TweenService:Create(
            main,
            TweenInfo.new(
                0.3,
                Enum.EasingStyle.Back,
                Enum.EasingDirection.Out
            ),
            {
                Size =
                    UDim2.new(
                        0,
                        BASE_W,
                        0,
                        BASE_H
                    )
            }
        ):Play()

        pages[currentTab].Visible = true

        if miniRing then
            miniRing:Destroy()
            miniRing = nil
        end
    end
end

minButton.MouseButton1Click:Connect(function()

    config.minimized =
        not config.minimized

    saveConfig()

    applyMinimized()
end)

miniButton.MouseButton1Click:Connect(function()

    config.minimized = false

    saveConfig()

    applyMinimized()
end)

miniButton.MouseButton1Down:Connect(function()

    TweenService:Create(
        miniButton,
        TweenInfo.new(0.08),
        {
            Size =
                UDim2.new(
                    0,
                    78,
                    0,
                    42
                )
        }
    ):Play()
end)

miniButton.MouseButton1Up:Connect(function()

    TweenService:Create(
        miniButton,
        TweenInfo.new(0.12),
        {
            Size =
                UDim2.new(
                    0,
                    86,
                    0,
                    46
                )
        }
    ):Play()
end)

-- ========== DRAGGING MAIN ==========
do

    local dragging = false
    local dragStart
    local startPos

    top.InputBegan:Connect(function(input)

        if input.UserInputType ==
                Enum.UserInputType.MouseButton1
            or input.UserInputType ==
                Enum.UserInputType.Touch then

            dragging = true

            dragStart =
                input.Position

            startPos =
                main.Position

            input.Changed:Connect(
                function()

                    if input.UserInputState ==
                        Enum.UserInputState.End then

                        if dragging then

                            dragging = false

                            config.posX =
                                main.Position.X.Scale

                            config.posY =
                                main.Position.Y.Scale

                            saveConfig()
                        end
                    end
                end
            )
        end
    end)

    UserInputService.InputChanged:Connect(
        function(input)

            if not dragging then
                return
            end

            if input.UserInputType ==
                    Enum.UserInputType.MouseMovement
                or input.UserInputType ==
                    Enum.UserInputType.Touch then

                local delta =
                    input.Position
                    - dragStart

                main.Position =
                    UDim2.new(
                        startPos.X.Scale
                            + (
                                startPos.X.Offset
                                + delta.X
                            ) / viewportSize.X,
                        0,

                        startPos.Y.Scale
                            + (
                                startPos.Y.Offset
                                + delta.Y
                            ) / viewportSize.Y,
                        0
                    )
            end
        end
    )
end

-- ========== DRAGGING FLOATING BUTTON ==========
do

    local dragging = false

    miniButton.InputBegan:Connect(
        function(input)

            if input.UserInputType ==
                    Enum.UserInputType.MouseButton1
                or input.UserInputType ==
                    Enum.UserInputType.Touch then

                local isDrag = false
                local startInputPos =
                    input.Position

                local startGuiPos =
                    miniButton.Position

                dragging = false

                local moveConn

                moveConn =
                    UserInputService.InputChanged:Connect(
                        function(moveInput)

                            if moveInput.UserInputType
                                == input.UserInputType then

                                local delta =
                                    moveInput.Position
                                    - startInputPos

                                if delta.Magnitude > 8 then

                                    isDrag = true
                                    dragging = true

                                    miniButton.Position =
                                        UDim2.new(
                                            startGuiPos.X.Scale
                                                + (
                                                    startGuiPos.X.Offset
                                                    + delta.X
                                                ) / viewportSize.X,
                                            0,

                                            startGuiPos.Y.Scale
                                                + (
                                                    startGuiPos.Y.Offset
                                                    + delta.Y
                                                ) / viewportSize.Y,
                                            0
                                        )
                                end
                            end
                        end
                    )

                input.Changed:Connect(
                    function(prop)

                        if prop == "UserInputState"
                            and input.UserInputState ==
                                Enum.UserInputState.End then

                            if moveConn then
                                moveConn:Disconnect()
                            end

                            if dragging then

                                dragging = false

                                config.miniX =
                                    miniButton.Position.X.Scale

                                config.miniY =
                                    miniButton.Position.Y.Scale

                                saveConfig()

                            elseif not isDrag then

                                config.minimized = false

                                saveConfig()

                                applyMinimized()
                            end
                        end
                    end
                )
            end
        end
    )
end

-- ========== INITIALIZATION ==========
main.AnchorPoint =
    Vector2.new(
        0.5,
        0.5
    )

main.Position =
    UDim2.new(
        config.posX or 0.5,
        0,
        config.posY or 0.5,
        0
    )

miniButton.Position =
    UDim2.new(
        config.miniX or 0.88,
        0,
        config.miniY or 0.12,
        0
    )

refreshAuto()
setTab(currentTab)
applyMinimized()
hookNotificationUI()
updatePreview()

camera:GetPropertyChangedSignal(
    "ViewportSize"
):Connect(function()

    viewportSize =
        camera.ViewportSize

    uiScaleFactor =
        computeScale()

    TweenService:Create(
        uiScale,
        TweenInfo.new(
            0.2,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        {
            Scale = uiScaleFactor
        }
    ):Play()
end)
