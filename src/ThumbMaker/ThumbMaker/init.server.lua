--!strict

--[[

  ThumbMaker plugin by DelzDev (@RenanMSV) - Since July 2023.
  Improved by @Jademaus: auto-frame, better ortho toggle, nudge controls - April 2026

  A Roblox plugin that helps you make model, accessories, tool thumbnails
  Made by RenanMsV at xMoon Games Studios.

]]

local CoreGui = game:GetService("CoreGui")
local SelectionService = game:GetService("Selection")
local UserInputService = game:GetService("UserInputService")

local Types = require(script.Types)
local Utils = require(script.Utils)

local PLUGIN_CURRENT_VERSION = "1.1.1"

local ICON_DEFAULT       = "rbxassetid://14034112968"
local ICON_DEFAULT_DON_E = "rbxassetid://107083275815819"
local ICON_AI_1          = "rbxassetid://108403669183553"
local ICON_AI_2          = "rbxassetid://83975823770967"

local FOV_DEFAULT        = 70
local FOV_ORTHO          = 5

local ATTR_FLAG          = "ThumbMakerSave"
local ATTR_SVVERSION     = "SaveFormat"
local ATTR_IS_ORTHO      = "CamIsOrthoMode"
local ATTR_FOV           = "CamFOV"
local ATTR_PERSP_FOV     = "CamPerspFOV"
local ATTR_ORTHO_DIST    = "CamOrthoDistance"
local ATTR_DIR_X         = "CamDirX"
local ATTR_DIR_Y         = "CamDirY"
local ATTR_DIR_Z         = "CamDirZ"
local ATTR_UP_X          = "CamUpX"
local ATTR_UP_Y          = "CamUpY"
local ATTR_UP_Z          = "CamUpZ"
local ATTR_LOOK_X        = "CamLookX"
local ATTR_LOOK_Y        = "CamLookY"
local ATTR_LOOK_Z        = "CamLookZ"

local toolbar = plugin:CreateToolbar("ThumbMaker")

local openCloseButton = toolbar:CreateButton(
  "ThumbMaker",
  "Make thumbnails for your UGC and models!",
  ICON_DEFAULT
)
openCloseButton.ClickableWhenViewportHidden = true

type ThumbMakerPluginType = Types.ThumbMakerPluginType

local ThumbMakerPlugin = {}
ThumbMakerPlugin.__index = ThumbMakerPlugin

function ThumbMakerPlugin.new(gui: ScreenGui): ThumbMakerPluginType
  local instance = setmetatable({} :: ThumbMakerPluginType, ThumbMakerPlugin)
  instance._version = PLUGIN_CURRENT_VERSION
  instance._versionString = string.format("ver. %s", PLUGIN_CURRENT_VERSION)
  instance._pluginInitialized = false

  instance._selected = {
    instance = nil,
    moveRBXConnection = nil,
  }

  instance._allowedClasses = {
    ["Model"] = true,
    ["Folder"] = true,
    ["Configuration"] = true,
    ["BasePart"] = true,
    ["Accessory"] = true,
    ["Tool"] = true,
    ["SpawnLocation"] = true,
  }

  -- Nudge state
  instance._nudgeConnection = nil :: RBXScriptConnection?
  instance._nudgeStep = 0.5 :: number -- studs per nudge

  local frame: Frame = gui:FindFirstChild("Frame") :: Frame

  local Get = function(...) return Utils:GetFromPath(...) end

  instance._gui = {
    ScreenGui = gui :: ScreenGui,
    Frame = frame :: Frame,
    Props = {
      StartingFOV = (Utils:GetCamera().FieldOfView or FOV_DEFAULT),
      OriginalDeleteButtonColor = Color3.fromRGB(0, 0, 0),
      OriginalResetCameraOffsetButtonColor = Color3.fromRGB(0, 0, 0),
      FOVHandleDragging = false,
      IsOrthoMode = false,
      OrthoDistance = 20, -- Stores the camera distance used for ortho so switching back is seamless
      PerspectiveFOV = FOV_DEFAULT,
      WarningRevertThread = nil,
    },

    Credits = {
      Version = Get(Get(frame, "Credits"), "Version") :: TextLabel,
    },

    FavoriteStarButton = {
      Button = Get(Get(Get(frame, "Tutorial"), "StarButton"), "Favorite") :: ImageButton,
      CloseButton = Get(Get(Get(Get(frame, "Tutorial"), "StarButton"), "Infobox"), "Quit") :: TextButton,
      InfoBox = Get(Get(Get(frame, "Tutorial"), "StarButton"), "Infobox") :: Frame,
    },

    ChangelogButton = {
      Button = Get(Get(Get(frame, "Tutorial"), "ChangelogButton"), "Changelog") :: ImageButton,
      CloseButton = Get(Get(Get(Get(frame, "Tutorial"), "ChangelogButton"), "Infobox"), "Quit") :: TextButton,
      InfoBox = Get(Get(Get(frame, "Tutorial"), "ChangelogButton"), "Infobox") :: Frame,
    },

    Labels = {
      Offset = Get(Get(frame, "Offset-Control"), "OffsetValue") :: TextLabel,
      FOV = Get(Get(frame, "FOV-Control"), "FOVValue") :: TextLabel,
      UGCFOVInfo = Get(Get(frame, "Tutorial"), "UGCFOVInfo") :: TextLabel,
      WarningLabel = Get(Get(frame, "Tutorial"), "WarningLabel") :: TextLabel,
      CameraMode = Get(Get(frame, "Main-Viewport"), "CameraMode") :: TextLabel,
    },

    Buttons = {
      Quit = Get(Get(frame, "Button-Group"), "Quit") :: TextButton,
      Delete = Get(Get(frame, "Button-Group"), "Delete") :: TextButton,
      Make = Get(Get(frame, "Button-Group"), "Make") :: TextButton,
      CameraMode = Get(Get(frame, "Button-Group"), "CameraMode") :: TextButton,
      AutoFrame = Get(Get(frame, "Offset-Control"), "AutoFrame") :: ImageButton,
      ResetOffset = Get(Get(frame, "Offset-Control"), "OffsetReset") :: ImageButton,
    },

    Sliders = {
      FOV = {
        Frame = Get(frame, "FOV-Control") :: Frame,
        Bar = Get(Get(frame, "FOV-Control"), "Bar") :: Frame,
        Handle = Get(Get(Get(frame, "FOV-Control"), "Bar"), "Handle") :: TextButton,
      },
    },

    Viewports = {
      MainViewport = Get(Get(frame, "Main-Viewport"), "ViewportFrame") :: ViewportFrame,
      PreviewLightMode = Get(Get(frame, "Preview-Viewport-Light"), "ViewportFrame") :: ViewportFrame,
      PreviewDarkMode = Get(Get(frame, "Preview-Viewport-Dark"), "ViewportFrame") :: ViewportFrame,
    }
  }

  instance:_init()
  return instance
end

function ThumbMakerPlugin:_init()
  if self._pluginInitialized then return end
  self:_initGui()
  self._pluginInitialized = true
end

function ThumbMakerPlugin:_initGui()
  local self: ThumbMakerPluginType = self

  local camera = Utils:GetCamera()
  script.Parent:FindFirstChild("Grid"):Clone().Parent = self._gui.Viewports.MainViewport

  self._gui.Credits.Version.Text = self._versionString

  SelectionService.SelectionChanged:Connect(function() self:_onSelectionChanges() end)

  openCloseButton.Click:Connect(function()
    if self._gui.ScreenGui.Parent == CoreGui then
      self:_guiClose()
    else
      self:_guiOpen()
    end
  end)

  self._gui.Buttons.Quit.MouseButton1Click:Connect(function()
    self:_guiClose()
  end)

  self._gui.Buttons.Delete.MouseButton1Click:Connect(function()
    self:_deleteCurrentThumbnail()
  end)

  -- Perspective / Orthographic toggle
  self._gui.Buttons.CameraMode.MouseButton1Click:Connect(function()
    self:_togglePerspective()
  end)

  -- Auto-frame button: tries to fit the model into view perfectly
  self._gui.Buttons.AutoFrame.MouseButton1Click:Connect(function()
    self:_autoFrameModel()
  end)

  self._gui.Props.OriginalDeleteButtonColor = self._gui.Buttons.Delete.BackgroundColor3
  self._gui.Props.OriginalResetCameraOffsetButtonColor = self._gui.Buttons.ResetOffset.BackgroundColor3

  self._gui.Buttons.Make.MouseButton1Click:Connect(function()
    self:_makeThumbnail()
  end)

  self._gui.Sliders.FOV.Bar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
      self:_FOVSliderCalculatePosition(input)
    end
  end)

  self._gui.Sliders.FOV.Handle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
      self._gui.Props.FOVHandleDragging = true
    end
  end)

  self._gui.Sliders.FOV.Handle.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
      self._gui.Props.FOVHandleDragging = false
    end
  end)

  UserInputService.InputChanged:Connect(function(input)
    if not self._gui.Props.FOVHandleDragging then return end
    self:_FOVSliderCalculatePosition(input)
  end)

  self:_initScaledPan()

  camera:GetPropertyChangedSignal("CFrame"):Connect(function()
    if not self._gui.ScreenGui.Enabled then return end
    if not self._selected.instance then return end
    local offset: CFrame = self:_findPivot(self._selected.instance):ToObjectSpace(camera.CFrame)
    self._gui.Labels.Offset.Text = ("%.1f,%.1f,%.1f"):format(offset.Position.X, offset.Position.Y, offset.Position.Z)
  end)

  camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
    self:_FOVSliderSetPosition(camera.FieldOfView)
  end)

  self._gui.Buttons.ResetOffset.MouseButton1Click:Connect(function()
    self:_resetCameraOffset()
  end)

  self._gui.ChangelogButton.Button.MouseButton1Click:Connect(function ()
    self._gui.ChangelogButton.InfoBox.Visible = not self._gui.ChangelogButton.InfoBox.Visible
  end)
  self._gui.ChangelogButton.CloseButton.MouseButton1Click:Connect(function ()
    self._gui.ChangelogButton.InfoBox.Visible = false
  end)

  self._gui.FavoriteStarButton.Button.MouseButton1Click:Connect(function ()
    self._gui.FavoriteStarButton.InfoBox.Visible = not self._gui.FavoriteStarButton.InfoBox.Visible
  end)
  self._gui.FavoriteStarButton.CloseButton.MouseButton1Click:Connect(function ()
    self._gui.FavoriteStarButton.InfoBox.Visible = false
  end)
end

-- ─────────────────────────────────────────────────────────────
-- IMPROVED: Toggle between Perspective and Orthographic.
-- When switching to Ortho, the camera is moved back so the model
-- stays the same apparent size. When switching back, it returns
-- to the natural distance.
-- By @Jademaus.
-- ─────────────────────────────────────────────────────────────
function ThumbMakerPlugin:_togglePerspective()
  local self: ThumbMakerPluginType = self
  local camera = Utils:GetCamera()
  local isCurrentlyOrtho = self._gui.Props.IsOrthoMode

  if not self._selected.instance then
    if isCurrentlyOrtho then
      self:_forcePerspective(self._gui.Props.PerspectiveFOV or FOV_DEFAULT)
    end
    return
  end

  if isCurrentlyOrtho then
    local pivot: CFrame = self:_findPivot(self._selected.instance)
    local currentDir: Vector3 = (camera.CFrame.Position - pivot.Position).Unit
    local targetFOV: number = self._gui.Props.PerspectiveFOV or FOV_DEFAULT

    self:_moveCameraTo(CFrame.new(pivot.Position + currentDir * self._gui.Props.OrthoDistance, pivot.Position))
    camera.FieldOfView = targetFOV
    self:_FOVSliderSetPosition(targetFOV)
    self._gui.Props.IsOrthoMode = false
    self._gui.Labels.CameraMode.Text = "📸 PERSPECTIVE"
    self:_FOVSliderSetEnabled(true)
  else
    local pivot: CFrame = self:_findPivot(self._selected.instance)
    local currentDist: number = (camera.CFrame.Position - pivot.Position).Magnitude

    -- Save both the distance and the current perspective FOV before entering ortho
    self._gui.Props.OrthoDistance = currentDist
    self._gui.Props.PerspectiveFOV = camera.FieldOfView

    local oldFOV: number = camera.FieldOfView
    local newFOV: number = FOV_ORTHO
    local ratio: number = math.tan(math.rad(oldFOV / 2)) / math.tan(math.rad(newFOV / 2))
    local newDist: number = currentDist * ratio

    local currentDir: Vector3 = (camera.CFrame.Position - pivot.Position).Unit
    self:_moveCameraTo(CFrame.new(pivot.Position + currentDir * newDist, pivot.Position))
    camera.FieldOfView = newFOV
    self:_FOVSliderSetPosition(newFOV)
    self._gui.Props.IsOrthoMode = true
    self._gui.Labels.CameraMode.Text = "📸 ORTHOGRAPHIC"
  end
  self:_onCameraModeChanges()
end

-- forces the camera mode to be orthographic
function ThumbMakerPlugin:_forceOrtho(fov: number?)
  local camera = Utils:GetCamera()
  self._gui.Props.IsOrthoMode        = true
  camera.FieldOfView                 = fov or FOV_ORTHO
  self._gui.Labels.CameraMode.Text   = "📸 ORTHOGRAPHIC"
  self:_FOVSliderSetPosition(fov or FOV_ORTHO)
  self:_onCameraModeChanges()
end

-- forces the camera mode to be perspective
function ThumbMakerPlugin:_forcePerspective(fov: number?)
  local camera = Utils:GetCamera()
  local resolvedFOV = fov or FOV_DEFAULT
  self._gui.Props.IsOrthoMode        = false
  self._gui.Props.PerspectiveFOV     = resolvedFOV  -- keep it in sync
  camera.FieldOfView                 = resolvedFOV
  self._gui.Labels.CameraMode.Text   = "📸 PERSPECTIVE"
  self:_FOVSliderSetPosition(resolvedFOV)
  self:_onCameraModeChanges()
end

-- Callback that runs after the camera mode changes
function ThumbMakerPlugin:_onCameraModeChanges()
  -- enables/disables the UGC fov warning
  local instance: Instance? = self._selected.instance
  self._gui.Labels.UGCFOVInfo.Visible = instance and instance:IsA("Accessory") and self._gui.Props.IsOrthoMode
end

-- ─────────────────────────────────────────────────────────────
-- Auto-frame — fits the model's bounding sphere into view
-- with a small padding, preserving the current camera angle.
-- By @Jademaus.
-- ─────────────────────────────────────────────────────────────
function ThumbMakerPlugin:_autoFrameModel()
  local self: ThumbMakerPluginType = self
  if not self._selected.instance then return end

  local instance = self._selected.instance
  local pivot: CFrame = self:_findPivot(instance)
  local camera = Utils:GetCamera()

  local radius: number = 5
  if instance:IsA("Model") then
    local extents: Vector3 = instance:GetExtentsSize()
    radius = extents.Magnitude / 2
  elseif instance:IsA("BasePart") then
    local magnitude: number = instance.Size.Magnitude
    radius = magnitude / 2
  elseif instance:IsA("Accessory") then
    local handle: BasePart? = instance:FindFirstChild("Handle") :: BasePart?
    if not handle then
      self:_setWarningText("⚠️ Accessory must have a valid Handle part", 2)
      return
    end
    radius = handle.Size.Magnitude / 2
  else
    local model: Model = Instance.new("Model")
    local clone = instance:Clone()
    clone.Parent = model
    radius = model:GetExtentsSize().Magnitude / 2
    model:Destroy()
  end

  radius = radius * 1.15

  local fov: number = camera.FieldOfView
  local distance: number = radius / math.tan(math.rad(fov / 2))

  local currentDir: Vector3 = (camera.CFrame.Position - pivot.Position)
  if currentDir.Magnitude < 0.001 then
    currentDir = Vector3.new(0, 0.5, 1).Unit
  else
    currentDir = currentDir.Unit
  end

  self:_moveCameraTo(CFrame.new(pivot.Position + currentDir * distance, pivot.Position))
  self:_setWarningText("Camera was moved to fit the model", 2)

  if self._gui.Props.IsOrthoMode then
    local orthoFOV: number = fov
    local perspFOV: number = self._gui.Props.PerspectiveFOV or FOV_DEFAULT
    local ratio: number = math.tan(math.rad(orthoFOV / 2)) / math.tan(math.rad(perspFOV / 2))
    self._gui.Props.OrthoDistance = distance * ratio
  else
    self._gui.Props.OrthoDistance = distance
    self._gui.Props.PerspectiveFOV = fov
  end
end

-- ─────────────────────────────────────────────────────────────
-- Slower camera with mouse for fine positioning.
-- By @Jademaus.
-- ─────────────────────────────────────────────────────────────
function ThumbMakerPlugin:_initScaledPan()
  local REFERENCE_FOV  = FOV_DEFAULT
  local rmbHeld        = false

  UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
    if not self._gui.ScreenGui.Enabled then return end
    if not self._selected.instance then return end
    local camera = Utils:GetCamera()
    if camera.FieldOfView >= 30 then return end

    rmbHeld = true
    camera.CameraType = Enum.CameraType.Scriptable
  end)

  UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
    if not rmbHeld then return end

    rmbHeld = false
    local camera = Utils:GetCamera()
    camera.CameraType = Enum.CameraType.Fixed
  end)

  UserInputService.InputChanged:Connect(function(input)
    if not rmbHeld then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    local camera = Utils:GetCamera()
    local fov   = camera.FieldOfView
    local scale = fov / REFERENCE_FOV
    local delta = input.Delta * 0.5
    local shiftHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

    if shiftHeld then
      delta = delta * 0.2
    end

    local cf = camera.CFrame
    camera.CFrame = cf
      * CFrame.Angles(0, -math.rad(delta.X) * scale, 0)
      * CFrame.Angles(-math.rad(delta.Y) * scale, 0, 0)
  end)
end

function ThumbMakerPlugin:_guiOpen()
  local camera = Utils:GetCamera()
  self:_forcePerspective()
  self._gui.ScreenGui.Parent = CoreGui
  self._gui.ScreenGui.Enabled = true
  self._gui.Props.StartingFOV = camera.FieldOfView or FOV_DEFAULT
  self._gui.Props.IsOrthoMode = false
  if self:_getSelectedModel() then -- when opening the gui, if you have something selected it selects that
    self:_onSelectionChanges()
  end
end

function ThumbMakerPlugin:_guiClose()
  local camera = Utils:GetCamera()
  self:_forcePerspective()
  self._gui.ScreenGui.Parent = script.Parent
  self._gui.ScreenGui.Enabled = false
  self:_deselectCurrentlySelected()
  camera.FieldOfView = self._gui.Props.StartingFOV
  self._gui.Props.IsOrthoMode = false
end

function ThumbMakerPlugin:_selectInstance(instance: Instance)
  local self: ThumbMakerPluginType = self
  if instance.ClassName == "Terrain" or instance.ClassName == "Workspace" or not self:_isClassAllowed(instance) then
    self:_setWarningText("Wrong selection or nothing selected")
    return false
  else
    self:_setWarningText(nil)
  end
  self:_updateViewportsClone(instance)
  self._selected.instance = instance

  self:_updateGridPosition()
  self:_setupMoveEvent()
  self:_updateButtonColors()

  self._gui.Labels.UGCFOVInfo.Visible = instance:IsA("Accessory") and self._gui.Props.IsOrthoMode

  self:_FOVSliderSetEnabled(true)

  return true
end

function ThumbMakerPlugin:_onSelectionChanges()
  if not self._gui.ScreenGui.Enabled then return end
  local selected: Instance? = self:_getSelectedModel()
  local instance: Instance? = self._selected.instance
  if not selected then
    self:_deselectCurrentlySelected()
  end
  if selected and selected ~= instance and self:_isClassAllowed(selected) then
    self:_deselectCurrentlySelected()
    self:_selectInstance(selected)
    return
  else
    self:_deselectCurrentlySelected()
    self:_setWarningText("Wrong selection or nothing selected")
  end
end

function ThumbMakerPlugin:_deselectCurrentlySelected()
  self:_destroyViewportsClone()
  local connection: RBXScriptConnection? = self._selected.moveRBXConnection
  if connection then
    connection:Disconnect()
  end
  self._selected.moveRBXConnection = nil
  self._selected.instance = nil
end

function ThumbMakerPlugin:_getSelectedModel(): Instance?
  return SelectionService:Get()[1] or nil
end

function ThumbMakerPlugin:_updateViewportsClone(instance: Instance)
  self:_destroyViewportsClone()
  local clone: Instance? = instance:Clone()
  if clone then
    clone.Name = "ClonedInstance"
    local mainViewport: ViewportFrame = self._gui.Viewports.MainViewport :: ViewportFrame
    local previewLightMode: ViewportFrame = self._gui.Viewports.PreviewLightMode :: ViewportFrame
    local previewDarkMode: ViewportFrame = self._gui.Viewports.PreviewDarkMode :: ViewportFrame
    clone:Clone().Parent = mainViewport
    clone:Clone().Parent = previewLightMode
    clone:Clone().Parent = previewDarkMode
    mainViewport.CurrentCamera = workspace.CurrentCamera
    previewLightMode.CurrentCamera = workspace.CurrentCamera
    previewDarkMode.CurrentCamera = workspace.CurrentCamera
    clone:Destroy()
    clone = nil
  end
end

function ThumbMakerPlugin:_destroyViewportsClone()
  pcall(function()
    local d = self._gui.Viewports.MainViewport:FindFirstChild("ClonedInstance")
    if d then
      d:Destroy()
    end
  end)
  pcall(function()
    local d = self._gui.Viewports.PreviewLightMode:FindFirstChild("ClonedInstance")
    if d then
      d:Destroy()
    end
  end)
  pcall(function()
    local d = self._gui.Viewports.PreviewDarkMode:FindFirstChild("ClonedInstance")
    if d then
      d:Destroy()
    end
  end)
end

function ThumbMakerPlugin:_isClassAllowed(instance: Instance)
  local self = self :: ThumbMakerPluginType
  if not instance["ClassName"] then return false end
  local allowed: boolean = false
  for name: string, allow: boolean in pairs(self._allowedClasses) do
    if (instance:IsA(name) or instance.ClassName == name) and allow == true then allowed = true; break end
  end
  return allowed
end

function ThumbMakerPlugin:_makeThumbnail()
  local self = self :: ThumbMakerPluginType
  if not self._selected.instance then return end
  if self._selected.instance:IsA("Accessory") then self:_makeThumbnailAccessory(); return end
  self:_deleteCurrentThumbnail()
  local camera: Camera = Utils:GetCamera():Clone()
  camera.Name = "ThumbnailCamera"
  camera.Parent = self._selected.instance
  self:_saveCameraState(camera)
  self:_updateButtonColors()
end

function ThumbMakerPlugin:_makeThumbnailAccessory()
  -- for Accessories we use ThumbnailConfiguration since its what Roblox tell UGC creators to use
  -- https://create.roblox.com/docs/marketplace/custom-thumbnails
  local self: ThumbMakerPluginType = self
  self:_deleteCurrentThumbnail()
  if not self._selected.instance then return end
  local handle: BasePart = self._selected.instance:FindFirstChild("Handle") :: BasePart
  if handle and handle:IsA("BasePart") then
    local conf: Configuration = Instance.new("Configuration")
    conf.Name = "ThumbnailConfiguration"
    local target: ObjectValue = Instance.new("ObjectValue", conf)
    target.Name = "ThumbnailCameraTarget"
    target.Value = handle
    local offset: CFrameValue = Instance.new("CFrameValue", conf)
    offset.Name = "ThumbnailCameraValue"
    if conf and target and offset then
      local _target: BasePart = target.Value :: BasePart
      offset.Value = _target.CFrame:ToObjectSpace(Utils:GetCamera().CFrame)
    end
    conf.Parent = self._selected.instance
    self:_updateButtonColors()
  else
    self:_setWarningText("⚠️ Accessory must have a valid Handle part", 2)
  end
end

function ThumbMakerPlugin:_updateThumbnail(newCFrame: CFrame)
  local self: ThumbMakerPluginType = self
  local selected: Instance? = self._selected.instance
  if not selected then return end

  local currentThumbnailCamera: Camera? = selected:FindFirstChild("ThumbnailCamera") :: Camera
  if not currentThumbnailCamera then return end

  local oldCameraOffset: CFrame = currentThumbnailCamera:GetAttribute("ThumbnailCameraOffset") :: CFrame

  if not oldCameraOffset then
    -- since thumbnail camera offset was not saved, we need to calculate it.
    -- somehow in the future, right now its not possible to know where the model was positioned
    -- when the model was published.
    -- (maybe if we knew the AssetId and used AssetService but thats a whole other can of worm)
  else
    self:_deleteCurrentThumbnail()
    local camera = Utils:GetCamera():Clone()
    camera.Name = "ThumbnailCamera"
    camera.Parent = selected
    -- save offset as an attribute
    camera.CFrame = newCFrame * oldCameraOffset
    camera:SetAttribute("ThumbnailCameraOffset", oldCameraOffset)
  end

  self:_updateButtonColors()
  self:_updateViewportsClone(selected)
end

function ThumbMakerPlugin:_deleteCurrentThumbnail()
  pcall(function()
    if not self._selected.instance then return end
    local existing = self._selected.instance:FindFirstChild("ThumbnailCamera")
    if existing then existing:Destroy() end
    self:_updateButtonColors()
  end)
  pcall(function()
    if not self._selected.instance then return end
    local existing = self._selected.instance:FindFirstChild("ThumbnailConfiguration")
    if existing then existing:Destroy() end
    self:_updateButtonColors()
  end)
end

function ThumbMakerPlugin:_updateButtonColors()
  if not self._selected.instance then return end
  local DOESNT_EXIST_COLOR: Color3 = Color3.fromRGB(218, 218, 218)
  local EXIST_COLOR: Color3 = self._gui.Props.OriginalDeleteButtonColor
  local OFFSET_EXIST_COLOR: Color3 = self._gui.Props.OriginalResetCameraOffsetButtonColor

  local toggleColor = function(hide: boolean)
    self._gui.Buttons.Delete.BackgroundColor3 = hide and DOESNT_EXIST_COLOR or EXIST_COLOR
    self._gui.Buttons.Delete.AutoButtonColor = not hide
    self._gui.Buttons.ResetOffset.BackgroundColor3 = hide and DOESNT_EXIST_COLOR or OFFSET_EXIST_COLOR
    self._gui.Buttons.ResetOffset.AutoButtonColor = not hide
    self._gui.Buttons.ResetOffset.ImageTransparency = hide and 0.6 or 0
  end

  if self._selected.instance:IsA("Accessory") then
    toggleColor(self._selected.instance:FindFirstChild("ThumbnailConfiguration") == nil)
  else
    toggleColor(self._selected.instance:FindFirstChild("ThumbnailCamera") == nil)
  end
end

function ThumbMakerPlugin:_findPivot(instance: Instance): CFrame
  if not instance then return CFrame.new() end
  if instance:IsA("Accessory") then
    local handle: BasePart = instance:FindFirstChild("Handle") :: BasePart
    if not handle or not handle:IsA("BasePart") then return CFrame.new() end
    return handle.CFrame
  end

  if instance:IsA("BasePart") or instance:IsA("Model") then
    return (instance :: BasePart | Model):GetPivot()
  end

  if instance:IsA("Folder") or instance:IsA("Configuration") then
    -- group, get pivot, ungroup
    local model: Model = Instance.new("Model")
    local clone: Instance = instance:Clone()
    clone.Parent = model
    local pivt: CFrame = model:GetPivot()
    model:Destroy()
    return pivt
  end
  -- in case nothing returns a default cframe
  return CFrame.new()
end

function ThumbMakerPlugin:_resetCameraOffset()
  local self: ThumbMakerPluginType = self
  local selected: Instance? = self._selected.instance
  if not selected then return end
  if selected:IsA("Accessory") then self:_resetCameraOffsetAccessory(); return end
  local thumbnailCamera: Camera = selected:FindFirstChild("ThumbnailCamera") :: Camera
  self:_loadCameraState(thumbnailCamera)
  self:_setWarningText("Restored camera offset to a saved state", 2)
end

function ThumbMakerPlugin:_resetCameraOffsetAccessory()
  local self: ThumbMakerPluginType = self
  local selected: Instance? = self._selected.instance
  if not selected then return end

  local thumbnailConfiguration: Configuration = selected:FindFirstChild("ThumbnailConfiguration") :: Configuration
  if not thumbnailConfiguration then return end

  local target: ObjectValue = thumbnailConfiguration:FindFirstChild("ThumbnailCameraTarget") :: ObjectValue
  local offset: CFrameValue = thumbnailConfiguration:FindFirstChild("ThumbnailCameraValue") :: CFrameValue
  if not target or not offset or not target.Value or not offset.Value or not target.Value:IsA("BasePart") then
    self:_setWarningText("⚠️ Could not find a valid Thumbnail", 2)
    return
  end

  local targetValue: BasePart = target.Value :: BasePart
  self:_moveCameraTo((targetValue.CFrame * offset.Value))
  self:_setWarningText("Restored camera offset to a saved state", 2)
end

function ThumbMakerPlugin:_moveCameraTo(cframe: CFrame)
  local camera = Utils:GetCamera()
  local cameraType: Enum.CameraType = camera.CameraType
  camera.CameraType = Enum.CameraType.Scriptable
  camera.CFrame = cframe
  task.wait()
  camera.CameraType = cameraType ~= Enum.CameraType.Scriptable and cameraType or Enum.CameraType.Fixed
end

function ThumbMakerPlugin:_setupMoveEvent()
  local self: ThumbMakerPluginType = self
  local selected: Instance? = self._selected.instance
  if not selected then return end
  if selected:IsA("Model") then
    self._selected.moveRBXConnection = selected:GetPropertyChangedSignal("WorldPivot"):Connect(function()
      self:_updateThumbnail(selected.WorldPivot)
    end)
  elseif selected:IsA("BasePart") then
    self._selected.moveRBXConnection = selected:GetPropertyChangedSignal("CFrame"):Connect(function()
      self:_updateThumbnail(selected.CFrame)
    end)
  end
end

function ThumbMakerPlugin:_updateGridPosition()
  local self = self :: ThumbMakerPluginType
  local pos: Vector3, size: Vector3
  if self._selected.instance and self._selected.instance:IsA("Model") then
    pos = self._selected.instance:GetPivot().Position
    size = self._selected.instance:GetExtentsSize()
  elseif self._selected.instance and self._selected.instance:IsA("BasePart") then
    pos = self._selected.instance.Position
    size = self._selected.instance.Size
  end
  if pos and size then
    local grid = self._gui.Viewports.MainViewport:FindFirstChild("Grid") :: Part
    if grid then
      grid.Position = pos - Vector3.new(0, (size.Y / 2) + 0.5, 0)
    end
  end
end

function ThumbMakerPlugin:_FOVSliderCalculatePosition(input: InputObject)
  local self: Types.ThumbMakerPluginType = self
  if self._selected.instance and self._selected.instance:IsA("Accessory") then return end
  local absX: number = self._gui.Sliders.FOV.Bar.AbsolutePosition.X
  local absXMax: number = absX + self._gui.Sliders.FOV.Bar.AbsoluteSize.X
  local delta: number = math.map(input.Position.X, absX, absXMax, 0, 1)
  delta = math.clamp(delta, 0, 1)
  local newFov: number = math.map(delta, 0, 1, 0, 120)
  local camera = Utils:GetCamera()
  camera.FieldOfView = newFov
  self._gui.Labels.FOV.Text = ("%.0f"):format(newFov)
  self._gui.Sliders.FOV.Handle.Position = UDim2.fromScale(delta, 0.5)
end

function ThumbMakerPlugin:_FOVSliderSetPosition(fov: number)
  local x: number = math.map(fov, 0, 120, 0, 1)
  x = math.clamp(x, 0, 1)
  self._gui.Labels.FOV.Text = ("%.0f"):format(fov)
  self._gui.Sliders.FOV.Handle.Position = UDim2.fromScale(x, 0.5)
end

function ThumbMakerPlugin:_FOVSliderSetEnabled(enabled: boolean)
  self._gui.Sliders.FOV.Frame.Visible = enabled
end

function ThumbMakerPlugin:_setWarningText(text: string?, revertAfter: number?)
  local self: ThumbMakerPluginType = self
  local label: TextLabel = self._gui.Labels.WarningLabel

  -- cancel any pending revert
  if self._gui.Props.WarningRevertThread then
    task.cancel(self._gui.Props.WarningRevertThread)
    self._gui.Props.WarningRevertThread = nil
  end

  label.Visible = text ~= nil
  label.Text = text or ""

  -- if no revertAfter, the warning persists until _setWarningText(nil) is called
  if revertAfter then
    self._gui.Props.WarningRevertThread = task.delay(revertAfter, function()
      self._gui.Props.WarningRevertThread = nil
      label.Visible = false
      label.Text = ""
    end)
  end
end

function ThumbMakerPlugin:_saveCameraState(target: Camera | Configuration)
  local self: ThumbMakerPluginType = self
  local CURRENT_SAVE_VERSION = 1  -- update this when changes to the saver happen
  local camera = Utils:GetCamera()
  local isOrtho = self._gui.Props.IsOrthoMode
  local perspFOV = self._gui.Props.PerspectiveFOV or FOV_DEFAULT
  local instance: Instance? = self._selected.instance
  if not instance then return end
  local pivot: CFrame = self:_findPivot(instance)

  -- Convert camera CFrame into pivot's local space
  local localCFrame: CFrame = pivot:ToObjectSpace(camera.CFrame)
  local localPos: Vector3 = localCFrame.Position
  local localLook: Vector3 = localCFrame.LookVector
  local localUp: Vector3 = localCFrame.UpVector

  target:SetAttribute(ATTR_FLAG,      true)
  target:SetAttribute(ATTR_SVVERSION, CURRENT_SAVE_VERSION)
  target:SetAttribute(ATTR_IS_ORTHO,  isOrtho)
  target:SetAttribute(ATTR_FOV,       camera.FieldOfView)
  target:SetAttribute(ATTR_PERSP_FOV, perspFOV)
  target:SetAttribute(ATTR_DIR_X,     localPos.X)
  target:SetAttribute(ATTR_DIR_Y,     localPos.Y)
  target:SetAttribute(ATTR_DIR_Z,     localPos.Z)
  target:SetAttribute(ATTR_LOOK_X,    localLook.X)
  target:SetAttribute(ATTR_LOOK_Y,    localLook.Y)
  target:SetAttribute(ATTR_LOOK_Z,    localLook.Z)
  target:SetAttribute(ATTR_UP_X,      localUp.X)
  target:SetAttribute(ATTR_UP_Y,      localUp.Y)
  target:SetAttribute(ATTR_UP_Z,      localUp.Z)

  if isOrtho then
    target:SetAttribute(ATTR_ORTHO_DIST, self._gui.Props.OrthoDistance)
  else
    target:SetAttribute(ATTR_ORTHO_DIST, nil)
  end
end

function ThumbMakerPlugin:_loadCameraState(target: Camera | Configuration)
  local self: ThumbMakerPluginType = self
  local instance: Instance? = self._selected.instance
  if not instance then return end
  if not target:GetAttribute(ATTR_FLAG) then
    return self:_loadCameraStateFallback(instance, target :: Camera)
  end
  local isOrtho = target:GetAttribute(ATTR_IS_ORTHO)
  if isOrtho == nil then return end
  local camera = Utils:GetCamera()
  local pivot: CFrame = self:_findPivot(instance)
  -- Reconstruct local CFrame from saved axes
  local localPos = Vector3.new(
    target:GetAttribute(ATTR_DIR_X),
    target:GetAttribute(ATTR_DIR_Y),
    target:GetAttribute(ATTR_DIR_Z)
  )
  local localLook = Vector3.new(
    target:GetAttribute(ATTR_LOOK_X),
    target:GetAttribute(ATTR_LOOK_Y),
    target:GetAttribute(ATTR_LOOK_Z)
  )
  local localUp = Vector3.new(
    target:GetAttribute(ATTR_UP_X),
    target:GetAttribute(ATTR_UP_Y),
    target:GetAttribute(ATTR_UP_Z)
  )
  -- Reconstruct exact local CFrame then convert back to world space
  local right: Vector3 = localLook:Cross(localUp).Unit
  local correctedUp: Vector3 = right:Cross(localLook).Unit
  local localCFrame = CFrame.fromMatrix(localPos, right, correctedUp, -localLook)
  local worldCFrame: CFrame = pivot:ToWorldSpace(localCFrame)
  self:_moveCameraTo(worldCFrame)
  if isOrtho then
    local savedOrthoDist = target:GetAttribute(ATTR_ORTHO_DIST)
    if savedOrthoDist then
      self._gui.Props.OrthoDistance = savedOrthoDist
    end
    self._gui.Props.PerspectiveFOV = target:GetAttribute(ATTR_PERSP_FOV) or FOV_DEFAULT
    self:_forceOrtho(target:GetAttribute(ATTR_FOV))
  else
    local savedFOV = target:GetAttribute(ATTR_FOV)
    self._gui.Props.PerspectiveFOV = savedFOV
    self._gui.Props.OrthoDistance  = (worldCFrame.Position - pivot.Position).Magnitude
    self:_forcePerspective(savedFOV)
    self:_FOVSliderSetEnabled(true)
  end
end

function ThumbMakerPlugin:_loadCameraStateFallback(instance: Instance, target: Camera)
  -- this is the fallback for when the model was not saved with the new saving format
  local self: ThumbMakerPluginType = self

  if target:IsA("Configuration") then return end  -- ignore accessories
  local camera = Utils:GetCamera()
  local currentSelected: Instance? = self._selected.instance
  if not currentSelected then return end
  local offset: CFrame = target:GetAttribute("ThumbnailCameraOffset")
  if offset then
    -- load offset that was set as attribute
    self:_moveCameraTo(self:_findPivot(currentSelected) * offset)
  else
    -- if not set, set thumbnail camera cframe, it probably won't be right
    self:_moveCameraTo(target.CFrame)
  end
  camera.FieldOfView = target.FieldOfView
  self:_FOVSliderSetPosition(target.FieldOfView)
end

function ThumbMakerPlugin:Destroy()
  local self = self :: ThumbMakerPluginType
  if self._gui.Props.IsOrthoMode then
    self:_togglePerspective()
  end
  if self._nudgeConnection then
    self._nudgeConnection:Disconnect()
  end
  self._gui.ScreenGui:Destroy()
end

local pluginGui = script.Parent:FindFirstChild("ThumbMaker-Gui") :: ScreenGui
local myPlugin = ThumbMakerPlugin.new(pluginGui)

plugin.Unloading:Connect(function ()
  myPlugin:Destroy()
end)
