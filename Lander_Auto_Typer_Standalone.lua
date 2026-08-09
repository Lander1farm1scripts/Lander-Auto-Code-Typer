-- LANDER AUTO TYPER — STANDALONE
-- No HttpGet
-- No request/http_request
-- No loadstring
-- No Discord/webhook
-- No trade/invite functionality
-- No RemoteEvent/RemoteFunction calls
-- No WaitForChild / infinite-yield lookups
--
-- Execute this file directly. Do NOT wrap it in:
-- loadstring(game:HttpGet("..."))()
--
-- This build is intentionally UI-only. It does not guess or call
-- game remotes because doing so could trigger unintended game actions.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then
    warn("Lander Auto Typer: LocalPlayer unavailable.")
    return
end

local playerGui = player:FindFirstChildOfClass("PlayerGui")
if not playerGui then
    warn("Lander Auto Typer: PlayerGui unavailable.")
    return
end

local existing = playerGui:FindFirstChild("LanderAutoTyper")
if existing then
    existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "LanderAutoTyper"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.Size = UDim2.fromOffset(470, 490)
main.BackgroundColor3 = Color3.fromRGB(8, 9, 12)
main.BorderSizePixel = 0
main.Parent = gui

local scale = Instance.new("UIScale")
scale.Parent = main

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = main

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(50, 56, 68)
outline.Thickness = 1
outline.Parent = main

local function updateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local size = camera.ViewportSize
    local sx = math.max(300, size.X - 18) / 470
    local sy = math.max(340, size.Y - 18) / 490
    scale.Scale = math.min(sx, sy, 1)

    -- Always recenter after a viewport change.
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
end

updateScale()

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 64)
header.BackgroundColor3 = Color3.fromRGB(4, 5, 7)
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(18, 8)
title.Size = UDim2.new(1, -90, 0, 25)
title.Text = "LANDER AUTO TYPER"
title.TextColor3 = Color3.fromRGB(245, 247, 250)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(19, 35)
subtitle.Size = UDim2.new(1, -100, 0, 18)
subtitle.Text = "Standalone • local only"
subtitle.TextColor3 = Color3.fromRGB(145, 153, 166)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 10
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(36, 36)
close.Position = UDim2.new(1, -48, 0.5, -18)
close.BackgroundColor3 = Color3.fromRGB(24, 27, 33)
close.BorderSizePixel = 0
close.Text = "×"
close.TextColor3 = Color3.fromRGB(235, 238, 243)
close.Font = Enum.Font.GothamBold
close.TextSize = 21
close.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 9)
closeCorner.Parent = close

local body = Instance.new("Frame")
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(14, 76)
body.Size = UDim2.new(1, -28, 1, -90)
body.Parent = main

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 42)
status.BackgroundColor3 = Color3.fromRGB(14, 18, 20)
status.BorderSizePixel = 0
status.Text = "● READY — NO HTTP"
status.TextColor3 = Color3.fromRGB(90, 225, 135)
status.Font = Enum.Font.GothamBold
status.TextSize = 12
status.Parent = body

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 10)
statusCorner.Parent = status

local info = Instance.new("TextLabel")
info.Position = UDim2.fromOffset(0, 54)
info.Size = UDim2.new(1, 0, 0, 94)
info.BackgroundColor3 = Color3.fromRGB(14, 16, 21)
info.BorderSizePixel = 0
info.Text = "Standalone safety mode\n\nNo web requests • no Discord webhook • no trading/invites • no remote calls"
info.TextColor3 = Color3.fromRGB(225, 229, 236)
info.Font = Enum.Font.Gotham
info.TextSize = 11
info.TextWrapped = true
info.TextXAlignment = Enum.TextXAlignment.Center
info.TextYAlignment = Enum.TextYAlignment.Center
info.Parent = body

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 10)
infoCorner.Parent = info

local codeBox = Instance.new("TextBox")
codeBox.Position = UDim2.fromOffset(0, 162)
codeBox.Size = UDim2.new(1, 0, 0, 54)
codeBox.BackgroundColor3 = Color3.fromRGB(20, 23, 29)
codeBox.BorderSizePixel = 0
codeBox.ClearTextOnFocus = false
codeBox.PlaceholderText = "Enter redeem code..."
codeBox.PlaceholderColor3 = Color3.fromRGB(130, 138, 151)
codeBox.Text = ""
codeBox.TextColor3 = Color3.fromRGB(245, 247, 250)
codeBox.Font = Enum.Font.Gotham
codeBox.TextSize = 13
codeBox.TextXAlignment = Enum.TextXAlignment.Left
codeBox.Parent = body

local codeCorner = Instance.new("UICorner")
codeCorner.CornerRadius = UDim.new(0, 10)
codeCorner.Parent = codeBox

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 14)
padding.PaddingRight = UDim.new(0, 14)
padding.Parent = codeBox

local redeem = Instance.new("TextButton")
redeem.Position = UDim2.fromOffset(0, 230)
redeem.Size = UDim2.new(1, 0, 0, 48)
redeem.BackgroundColor3 = Color3.fromRGB(75, 135, 235)
redeem.BorderSizePixel = 0
redeem.Text = "REDEEM CODE"
redeem.TextColor3 = Color3.new(1, 1, 1)
redeem.Font = Enum.Font.GothamBold
redeem.TextSize = 13
redeem.Parent = body

local redeemCorner = Instance.new("UICorner")
redeemCorner.CornerRadius = UDim.new(0, 10)
redeemCorner.Parent = redeem

local note = Instance.new("TextLabel")
note.Position = UDim2.fromOffset(0, 294)
note.Size = UDim2.new(1, 0, 0, 90)
note.BackgroundTransparency = 1
note.Text = "Redeem codes are stored only in this local UI.\nThis build intentionally does not call unknown game remotes.\nUse the game's normal redeem interface to redeem a code."
note.TextColor3 = Color3.fromRGB(145, 153, 166)
note.Font = Enum.Font.Gotham
note.TextSize = 10
note.TextWrapped = true
note.TextXAlignment = Enum.TextXAlignment.Center
note.TextYAlignment = Enum.TextYAlignment.Top
note.Parent = body

redeem.Activated:Connect(function()
    local code = codeBox.Text:gsub("^%s+", ""):gsub("%s+$", "")

    if code == "" then
        status.Text = "● ENTER A CODE FIRST"
        status.TextColor3 = Color3.fromRGB(255, 190, 80)
        return
    end

    status.Text = "● CODE READY — NO REMOTE CALLED"
    status.TextColor3 = Color3.fromRGB(90, 225, 135)
end)

close.Activated:Connect(function()
    gui:Destroy()
end)

-- Mobile/mouse drag. This only moves the local GUI.
local dragging = false
local dragStart
local startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPos = main.Position

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
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

print("Lander Auto Typer: standalone UI loaded successfully.")
