-- Lander Auto Typer
-- Standalone build: no HttpGet, request, loadstring, Discord webhook,
-- no trade/invite logic, no trade remotes, and no yielding remote lookups.
-- external URL, trade/invite, item-transfer, or remote-code-loading logic.
-- Paste/execute this file directly in your Roblox Lua environment.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then
    warn("Lander Auto Typer: LocalPlayer is unavailable.")
    return
end

local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:FindFirstChild("PlayerGui")
if not playerGui then
    warn("Lander Auto Typer: PlayerGui is unavailable.")
    return
end

local old = playerGui:FindFirstChild("LanderAutoTyper")
if old then
    old:Destroy()
end

local COLORS = {
    bg = Color3.fromRGB(7, 8, 10),
    top = Color3.fromRGB(4, 5, 7),
    panel = Color3.fromRGB(14, 16, 20),
    panel2 = Color3.fromRGB(19, 22, 27),
    panel3 = Color3.fromRGB(25, 29, 35),
    text = Color3.fromRGB(242, 244, 248),
    muted = Color3.fromRGB(155, 162, 174),
    accent = Color3.fromRGB(92, 154, 255),
    good = Color3.fromRGB(80, 220, 130),
    border = Color3.fromRGB(48, 54, 65),
}

local gui = Instance.new("ScreenGui")
gui.Name = "LanderAutoTyper"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(470, 490)
-- Always start centered every time the script executes.
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = COLORS.bg
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = COLORS.border
stroke.Thickness = 1
stroke.Parent = main

-- Automatically scales the window for phones/tablets.
local scale = Instance.new("UIScale")
scale.Parent = main

local function resize()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local v = camera.ViewportSize
    local sx = math.max(300, v.X - 18) / 470
    local sy = math.max(330, v.Y - 18) / 490

    scale.Scale = math.min(sx, sy, 1)

    if v.X < 520 or v.Y < 560 then
        main.Position = UDim2.new(0.5, 0, 0.5, 0)
    end
end

resize()

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
end

local top = Instance.new("Frame")
top.Name = "Header"
top.Size = UDim2.new(1, 0, 0, 62)
top.BackgroundColor3 = COLORS.top
top.BorderSizePixel = 0
top.Parent = main

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 16)
topCorner.Parent = top

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -130, 1, 0)
title.Position = UDim2.fromOffset(18, 0)
title.Text = "LANDER AUTO TYPER"
title.TextColor3 = COLORS.text
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Size = UDim2.new(1, -150, 0, 18)
subtitle.Position = UDim2.fromOffset(19, 36)
subtitle.Text = "Standalone • no external HTTP"
subtitle.TextColor3 = COLORS.muted
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 9
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = top

local dot = Instance.new("Frame")
dot.Size = UDim2.fromOffset(9, 9)
dot.Position = UDim2.new(1, -92, 0.5, -5)
dot.BackgroundColor3 = COLORS.good
dot.BorderSizePixel = 0
dot.Parent = top

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dot

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(36, 36)
minimize.Position = UDim2.new(1, -50, 0.5, -18)
minimize.BackgroundColor3 = COLORS.panel3
minimize.BorderSizePixel = 0
minimize.Text = "−"
minimize.TextColor3 = COLORS.text
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = 20
minimize.Parent = top

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 9)
minCorner.Parent = minimize

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -28, 1, -76)
content.Position = UDim2.fromOffset(14, 68)
content.BackgroundTransparency = 1
content.Parent = main

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 42)
status.BackgroundColor3 = COLORS.panel
status.BorderSizePixel = 0
status.Text = "Ready — standalone mode"
status.TextColor3 = COLORS.good
status.Font = Enum.Font.GothamBold
status.TextSize = 12
status.Parent = content

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 10)
statusCorner.Parent = status

local statusStroke = Instance.new("UIStroke")
statusStroke.Color = COLORS.border
statusStroke.Parent = status

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 0, 82)
info.Position = UDim2.fromOffset(0, 54)
info.BackgroundColor3 = COLORS.panel
info.BorderSizePixel = 0
info.Text = "This build contains no external web requests.\n\nRedeem-code automation remains local to this script.\nNo Discord webhook, trade, invite, item-transfer, or remote-code loader is included."
info.TextColor3 = COLORS.text
info.Font = Enum.Font.Gotham
info.TextSize = 11
info.TextWrapped = true
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Center
info.Parent = content

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 10)
infoCorner.Parent = info

local infoPadding = Instance.new("UIPadding")
infoPadding.PaddingLeft = UDim.new(0, 14)
infoPadding.PaddingRight = UDim.new(0, 14)
infoPadding.Parent = info

local codeBox = Instance.new("TextBox")
codeBox.Size = UDim2.new(1, 0, 0, 54)
codeBox.Position = UDim2.fromOffset(0, 150)
codeBox.BackgroundColor3 = COLORS.panel2
codeBox.BorderSizePixel = 0
codeBox.ClearTextOnFocus = false
codeBox.PlaceholderText = "Enter redeem code..."
codeBox.PlaceholderColor3 = COLORS.muted
codeBox.Text = ""
codeBox.TextColor3 = COLORS.text
codeBox.Font = Enum.Font.Gotham
codeBox.TextSize = 13
codeBox.TextXAlignment = Enum.TextXAlignment.Left
codeBox.Parent = content

local codeCorner = Instance.new("UICorner")
codeCorner.CornerRadius = UDim.new(0, 10)
codeCorner.Parent = codeBox

local codePadding = Instance.new("UIPadding")
codePadding.PaddingLeft = UDim.new(0, 14)
codePadding.PaddingRight = UDim.new(0, 14)
codePadding.Parent = codeBox

local redeem = Instance.new("TextButton")
redeem.Size = UDim2.new(1, 0, 0, 48)
redeem.Position = UDim2.fromOffset(0, 218)
redeem.BackgroundColor3 = COLORS.accent
redeem.BorderSizePixel = 0
redeem.Text = "REDEEM CODE"
redeem.TextColor3 = Color3.new(1, 1, 1)
redeem.Font = Enum.Font.GothamBold
redeem.TextSize = 13
redeem.Parent = content

local redeemCorner = Instance.new("UICorner")
redeemCorner.CornerRadius = UDim.new(0, 10)
redeemCorner.Parent = redeem

local note = Instance.new("TextLabel")
note.Size = UDim2.new(1, 0, 0, 80)
note.Position = UDim2.fromOffset(0, 282)
note.BackgroundTransparency = 1
note.Text = "Important\nA standalone file cannot know the game's private redeem-code RemoteEvent unless the game exposes it locally. This UI therefore does not guess or call unknown remotes."
note.TextColor3 = COLORS.muted
note.Font = Enum.Font.Gotham
note.TextSize = 10
note.TextWrapped = true
note.TextXAlignment = Enum.TextXAlignment.Left
note.TextYAlignment = Enum.TextYAlignment.Top
note.Parent = content

redeem.MouseButton1Click:Connect(function()
    local code = codeBox.Text:gsub("^%s+", ""):gsub("%s+$", "")

    if code == "" then
        status.Text = "Enter a redeem code first."
        status.TextColor3 = Color3.fromRGB(255, 190, 90)
        return
    end

    -- Deliberately no HTTP, loadstring, unknown RemoteEvent, or external loader.
    status.Text = "Code captured locally: " .. code
    status.TextColor3 = COLORS.good
end)

local minimized = false

minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    content.Visible = not minimized
    main.Size = minimized and UDim2.fromOffset(470, 62) or UDim2.fromOffset(470, 490)
    minimize.Text = minimized and "+" or "−"
    resize()
end)

-- Touch + mouse dragging.
local dragging = false
local dragStart
local startPosition

top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

print("Lander Auto Typer loaded: standalone / zero external HTTP")
