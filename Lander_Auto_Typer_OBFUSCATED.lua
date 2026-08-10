-- ========== LANDERS SCRIPTS FLOATING BUTTON ==========

local miniButton = Instance.new("ImageButton")

miniButton.Name = "LanderFloatingButton"
miniButton.Size = UDim2.new(0, 58, 0, 58)
miniButton.AnchorPoint = Vector2.new(0.5, 0.5)

miniButton.Position = UDim2.new(
    config.miniX or 0.88,
    0,
    config.miniY or 0.12,
    0
)

miniButton.BackgroundColor3 = Color3.fromRGB(10, 5, 18)
miniButton.BackgroundTransparency = 0.05
miniButton.BorderSizePixel = 0

-- PUT YOUR ROBLOX IMAGE ASSET ID HERE
miniButton.Image = "rbxassetid://YOUR_IMAGE_ASSET_ID"

miniButton.ScaleType = Enum.ScaleType.Crop
miniButton.AutoButtonColor = false
miniButton.Visible = false
miniButton.Parent = safeContainer

corner(miniButton, 14)
stroke(miniButton, COLORS.accentLt, 2, 0)

-- Prevent the image from being covered by the pulse effect
miniButton.ZIndex = 20
