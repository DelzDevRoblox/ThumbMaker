--!strict

--[[

	ThumbMaker plugin by RenanMSV

]]

local SelectionService = game:GetService("Selection")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local toolbar = plugin:CreateToolbar("Thumb Maker")

local isDonatorEdition = script:FindFirstChild("IsDonatorEdition") and script:FindFirstChild("IsDonatorEdition").Value == true

local openCloseButton = toolbar:CreateButton("Thumb Maker", "Thumb Maker", isDonatorEdition == true and "rbxassetid://107083275815819" or "rbxassetid://14034112968")

openCloseButton.ClickableWhenViewportHidden = true

local ThumbMakerTypes = require(script.Types)
local Utils = require(script.Utils)

local ThumbMakerPlugin = {}
ThumbMakerPlugin.__index = ThumbMakerPlugin

function ThumbMakerPlugin.new(gui: ScreenGui)
  --[[
    A Roblox plugin that helps you make model, accessories, tool thumbnails
    Made by RenanMsV at xMoon Games Studios
  ]]
  local self = setmetatable({}, ThumbMakerPlugin)
  self._version = "ver. 1.0.3" :: string
  self._pluginInitialized = false :: boolean

  self._selected = {
    instance = nil,
    moveRBXConnection = nil,
  } :: ThumbMakerTypes._selectedTable

  self._allowedClasses = {
    ["Model"] = true,
    ["Folder"] = true,
    ["Configuration"] = true,
    ["BasePart"] = true,
    ["Accessory"] = true,
    ["Tool"] = true,
    ["SpawnLocation"] = true,
  }

  local frame: Frame = gui:FindFirstChild("Frame") :: Frame

  self._gui = {
    ScreenGui = gui :: ScreenGui,
    Frame = frame :: Frame,
    Props = {
      StartingFOV = (workspace.CurrentCamera.FieldOfView or 70),
      OriginalDeleteButtonColor = Color3.fromRGB(0, 0, 0),
      OriginalResetCameraOffsetButtonColor = Color3.fromRGB(0, 0, 0),
      FOVHandleDragging = false,
      ResettingCameraOffset = false,
    },
    Credits = {
      Version = frame:FindFirstChild("Credits"):FindFirstChild("Version") :: TextLabel,
    },
    FavoriteStarButton = {
      Button = frame:FindFirstChild("Tutorial"):FindFirstChild("StarButton"):FindFirstChild("Favorite") :: ImageButton,
      CloseButton = frame:FindFirstChild("Tutorial"):FindFirstChild("StarButton"):FindFirstChild("Infobox"):FindFirstChild("Quit") :: TextButton,
      InfoBox = frame:FindFirstChild("Tutorial"):FindFirstChild("StarButton"):FindFirstChild("Infobox") :: Frame,
    },
    ChangelogButton = {
      Button = frame:FindFirstChild("Tutorial"):FindFirstChild("ChangelogButton"):FindFirstChild("Changelog") :: ImageButton,
      CloseButton = frame:FindFirstChild("Tutorial"):FindFirstChild("ChangelogButton"):FindFirstChild("Infobox"):FindFirstChild("Quit") :: TextButton,
      InfoBox = frame:FindFirstChild("Tutorial"):FindFirstChild("ChangelogButton"):FindFirstChild("Infobox") :: Frame,
    },
    Labels = {
      Offset = frame:FindFirstChild("Offset-Control"):FindFirstChild("OffsetValue") :: TextLabel,
      FOV = frame:FindFirstChild("FOV-Control"):FindFirstChild("FOVValue") :: TextLabel,
      WarningLabel = frame:FindFirstChild("Tutorial"):FindFirstChild("WarningLabel") :: TextLabel,
    },
    Buttons = {
      Quit = frame:FindFirstChild("Button-Group"):FindFirstChild("Quit") :: TextButton,
      Delete = frame:FindFirstChild("Button-Group"):FindFirstChild("Delete") :: TextButton,
      Make = frame:FindFirstChild("Button-Group"):FindFirstChild("Make") :: TextButton,
      ResetOffset = frame:FindFirstChild("Offset-Control"):FindFirstChild("OffsetReset") :: ImageButton,
    },
    Sliders = {
      FOV = {
        Frame = frame:FindFirstChild("FOV-Control") :: Frame,
        Bar = frame:FindFirstChild("FOV-Control"):FindFirstChild("Bar") :: Frame,
        Handle = frame:FindFirstChild("FOV-Control"):FindFirstChild("Bar"):FindFirstChild("Handle") :: TextButton,
      },
    },
    Viewports = {
      MainViewport = frame:FindFirstChild("Main-Viewport"):FindFirstChild("ViewportFrame") :: ViewportFrame,
      PreviewLightMode = frame:FindFirstChild("Preview-Viewport-Light"):FindFirstChild("ViewportFrame") :: ViewportFrame,
      PreviewDarkMode = frame:FindFirstChild("Preview-Viewport-Dark"):FindFirstChild("ViewportFrame") :: ViewportFrame,
    }
  } :: ThumbMakerTypes._guiTable

  self:_init()
  return self
end

function ThumbMakerPlugin:_init()
  if self._pluginInitialized then return end
  self:_initGui()
  self._pluginInitialized = true
end

function ThumbMakerPlugin:_initGui()

  script.Parent:FindFirstChild("Grid"):Clone().Parent = self._gui.Viewports.MainViewport

  self._gui.Credits.Version.Text = self._version

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

  workspace.CurrentCamera:GetPropertyChangedSignal("CFrame"):Connect(function()
    if not self._gui.ScreenGui.Enabled then return end
    if not self._selected.instance then return end
    local offset: CFrame = self:_findPivot(self._selected.instance):ToObjectSpace(workspace.CurrentCamera.CFrame)
    self._gui.Labels.Offset.Text = ("%.1f,%.1f,%.1f"):format(offset.Position.X, offset.Position.Y, offset.Position.Z)
  end)

  workspace.CurrentCamera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
    self:_FOVSliderSetPosition(workspace.CurrentCamera.FieldOfView)
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

  if not isDonatorEdition then
    self._gui.FavoriteStarButton.Button.MouseButton1Click:Connect(function ()
      self._gui.FavoriteStarButton.InfoBox.Visible = not self._gui.FavoriteStarButton.InfoBox.Visible
    end)
    self._gui.FavoriteStarButton.CloseButton.MouseButton1Click:Connect(function ()
      self._gui.FavoriteStarButton.InfoBox.Visible = false
    end)
  end

end

function ThumbMakerPlugin:_guiOpen()
  self._gui.ScreenGui.Parent = CoreGui
  self._gui.ScreenGui.Enabled = true
  self._gui.Props.StartingFOV = workspace.CurrentCamera.FieldOfView or 70
  if self:_getSelectedModel() then -- when opening the gui, if you have something select it selects that
    self:_onSelectionChanges()
  end
end

function ThumbMakerPlugin:_guiClose()
  self._gui.ScreenGui.Parent = script.Parent
  self._gui.ScreenGui.Enabled = false
  self:_deselectCurrentlySelected()
  workspace.CurrentCamera.FieldOfView = self._gui.Props.StartingFOV
end

function ThumbMakerPlugin:_selectInstance(instance: Instance)
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
  if instance:IsA("Accessory") then
    pcall(function()
      workspace.CurrentCamera.FieldOfView = 70
      self:_FOVSliderSetPosition(70)
      self:_FOVSliderSetEnabled(false)
    end)
  else
    self:_FOVSliderSetEnabled(true)
    pcall(function()
      local thumbnailCamera: Camera = self._selected.instance:FindFirstChild("ThumbnailCamera") :: Camera
      workspace.CurrentCamera.FieldOfView = thumbnailCamera.FieldOfView
      self:_FOVSliderSetPosition(thumbnailCamera.FieldOfView)
    end)
  end
  return true
end

function ThumbMakerPlugin:_onSelectionChanges()
  if not self._gui.ScreenGui.Enabled then return end
  local selected: Instance? = self:_getSelectedModel()
  if not selected then
    self:_deselectCurrentlySelected()
  end
  if selected and selected ~= self._selected.instance and self:_isClassAllowed(selected) then
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
  if self._selected.moveRBXConnection then
    self._selected.moveRBXConnection:Disconnect()
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
  pcall(function() self._gui.Viewports.MainViewport:FindFirstChild("ClonedInstance"):Destroy() end)
  pcall(function() self._gui.Viewports.PreviewLightMode:FindFirstChild("ClonedInstance"):Destroy() end)
  pcall(function() self._gui.Viewports.PreviewDarkMode:FindFirstChild("ClonedInstance"):Destroy() end)
end

function ThumbMakerPlugin:_isClassAllowed(instance: Instance)
  if not instance["ClassName"] then return false end
  local allowed: boolean = false
  for name: string, allow: boolean in pairs(self._allowedClasses) do
    if (instance:IsA(name) or instance.ClassName == name) and allow == true then allowed = true break end
  end
  return allowed
end

function ThumbMakerPlugin:_makeThumbnail()
  if not self._selected.instance then return end
  if self._selected.instance:IsA("Accessory") then self:_makeThumbnailAccessory() return end
  self:_deleteCurrentThumbnail()
  local camera: Camera = workspace.CurrentCamera:Clone()
  camera.Name = "ThumbnailCamera"
  camera.Parent = self._selected.instance
  -- save offset as an attribute
  camera:SetAttribute("ThumbnailCameraOffset", self:_findPivot(self._selected.instance):ToObjectSpace(camera.CFrame))
  self:_updateButtonColors()
end

function  ThumbMakerPlugin:_makeThumbnailAccessory()
  -- for Accessories we use ThumbnailConfiguration since its what Roblox tell UGC creators to use
  -- https://create.roblox.com/docs/art/marketplace/publishing-to-marketplace#creating-thumbnails
  -- Requires FOV to be always 70.
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
      offset.Value = _target.CFrame:ToObjectSpace(workspace.CurrentCamera.CFrame)
    end
    conf.Parent = self._selected.instance
    self:_updateButtonColors()
  else
    warn("Must select a valid accessory with a valid Handle")
  end
end

function ThumbMakerPlugin:_updateThumbnail()
  local selectedInstance: Instance? = self._selected.instance
  if not selectedInstance then return end

  local currentThumbnailCamera: Camera? = selectedInstance:FindFirstChild("ThumbnailCamera") :: Camera
  if not currentThumbnailCamera then return end

  local oldOffset: CFrame = currentThumbnailCamera:GetAttribute("ThumbnailCameraOffset")
  self:_deleteCurrentThumbnail()

  local camera: Camera = workspace.CurrentCamera:Clone()
  camera.Name = "ThumbnailCamera"
  camera.Parent = self._selected.instance

  -- save offset as an attribute
  local pivot: CFrame = self:_findPivot(self._selected.instance)
  camera.CFrame = pivot * oldOffset
  camera:SetAttribute("ThumbnailCameraOffset", oldOffset)
  self:_updateButtonColors()
  self:_updateViewportsClone(self._selected.instance)
end

function ThumbMakerPlugin:_deleteCurrentThumbnail()
  pcall(function()
    if not self._selected.instance then return end
    self._selected.instance:FindFirstChild("ThumbnailCamera"):Destroy()
    self:_updateButtonColors()
  end)
  pcall(function()
    if not self._selected.instance then return end
    self._selected.instance:FindFirstChild("ThumbnailConfiguration"):Destroy()
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

function ThumbMakerPlugin:_findPivot(instance: Instance)
  if not instance then return CFrame.new() end
  if instance:IsA("Accessory") then
    local handle: BasePart = instance:FindFirstChild("Handle") :: BasePart
    if not handle or not handle:IsA("BasePart") then return CFrame.new() end
    return handle.CFrame
  end

  if instance:IsA("BasePart") or instance:IsA("Model") then
    local pivt: CFrame = (instance :: BasePart | Model):GetPivot()
    return pivt
  end

  if instance:IsA("Folder") or instance:IsA("Configuration") then
    -- group, get pivot, ungroup
    local model: Model = Instance.new("Model")
    local cloneFolder: Folder? = nil
    local cloneConfiguration: Configuration? = nil

    if instance:IsA("Folder") then
      cloneFolder = instance:Clone()
    elseif instance:IsA("Configuration") then
      cloneConfiguration = instance:Clone()
    end

    if cloneFolder then
      cloneFolder.Parent = model
    end
    if cloneConfiguration then
      cloneConfiguration.Parent = model
    end

    local pivt: CFrame = model:GetPivot()
    model:Destroy()
    return pivt
  end

  -- in case nothing returns a default cframe
  return CFrame.new()
end

function ThumbMakerPlugin:_resetCameraOffset()
  pcall(function()
    if not self._selected.instance then return end
    if self._selected.instance:IsA("Accessory") then self:_resetCameraOffsetAccessory() return end
    local thumbnailCamera: Camera = self._selected.instance:FindFirstChild("ThumbnailCamera") :: Camera
    local offset: CFrame = thumbnailCamera:GetAttribute("ThumbnailCameraOffset")
    if offset then
      -- load offset that was set as attribute
      self:_moveCameraTo(self:_findPivot(self._selected.instance) * offset)
    else
      workspace.CurrentCamera.CFrame = thumbnailCamera.CFrame
    end
    pcall(function()
      workspace.CurrentCamera.FieldOfView = thumbnailCamera.FieldOfView
      self:_FOVSliderSetPosition(thumbnailCamera.FieldOfView)
    end)
  end)
end

function ThumbMakerPlugin:_resetCameraOffsetAccessory()
  pcall(function()
    if not self._selected.instance then return end
    local thumbnailConfiguration: Configuration = self._selected.instance:FindFirstChild("ThumbnailConfiguration") :: Configuration
    if not thumbnailConfiguration then return end

    local target: ObjectValue = thumbnailConfiguration:FindFirstChild("ThumbnailCameraTarget") :: ObjectValue
    local offset: CFrameValue = thumbnailConfiguration:FindFirstChild("ThumbnailCameraValue") :: CFrameValue
    if not target or not offset or not target.Value or not offset.Value or not target.Value:IsA("BasePart") then return end

    local targetValue: BasePart = target.Value :: BasePart
    local targetCFrame: CFrame = targetValue.CFrame
    local offsetValue: CFrame = offset.Value
    self:_moveCameraTo((targetCFrame * offsetValue))

    pcall(function()
      workspace.CurrentCamera.FieldOfView = 70
      self:_FOVSliderSetPosition(70)
    end)
  end)
end

function ThumbMakerPlugin:_moveCameraTo(cframe: CFrame)
  task.spawn(function()
    if self._gui.Props.ResettingCameraOffset then return end
    self._gui.Props.ResettingCameraOffset = true
    local cameraType: Enum.CameraType = workspace.CurrentCamera.CameraType
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    task.wait(0.1)
    workspace.CurrentCamera.CFrame = cframe
    task.wait(0.05)
    workspace.CurrentCamera.CameraType = cameraType
    self._gui.Props.ResettingCameraOffset = false
  end)
end

function ThumbMakerPlugin:_setupMoveEvent()
  if self._selected.instance:IsA("Model") then
    self._selected.moveRBXConnection = self._selected.instance:GetPropertyChangedSignal("WorldPivot"):Connect(function()
      self:_updateThumbnail()
    end)
  elseif self._selected.instance:IsA("BasePart") then
    self._selected.moveRBXConnection = self._selected.instance:GetPropertyChangedSignal("CFrame"):Connect(function()
      self:_updateThumbnail()
    end)
  elseif self._selected.instance.ClassName == "Accessory" then
    -- ThumbnailConfiguration does not require a re-calculation
    return
  end
end

function ThumbMakerPlugin:_updateGridPosition()
  if self._selected.instance:IsA("Model") then
    local pos: Vector3 = self._selected.instance:GetPivot().Position
    local size: Vector3 = self._selected.instance:GetExtentsSize()
    self._gui.Viewports.MainViewport:FindFirstChild("Grid").Position = pos - Vector3.new(0, (size.Y / 2) + 0.5, 0)
  elseif self._selected.instance:IsA("BasePart") then
    local pos: Vector3 = self._selected.instance.Position
    local size: Vector3 = self._selected.instance.Size
    self._gui.Viewports.MainViewport:FindFirstChild("Grid").Position = pos - Vector3.new(0, (size.Y / 2) + 0.5, 0)
  end
end

function ThumbMakerPlugin:_FOVSliderCalculatePosition(input: InputObject)
  if self._selected.instance and self._selected.instance:IsA("Accessory") then return end
  local absX: number = self._gui.Sliders.FOV.Bar.AbsolutePosition.X
  local absXMax: number = absX + self._gui.Sliders.FOV.Bar.AbsoluteSize.X
  local delta: number = Utils:MapToInterval(input.Position.X, absX, absXMax, 0, 1)
  delta = math.clamp(delta, 0, 1)
  local newFov: number = Utils:MapToInterval(delta, 0, 1, 0, 120)
  workspace.CurrentCamera.FieldOfView = newFov
  self._gui.Labels.FOV.Text = ("%.0f"):format(newFov)
  self._gui.Sliders.FOV.Handle.Position = UDim2.fromScale(delta, 0.5)
end

function ThumbMakerPlugin:_FOVSliderSetPosition(fov: number)
  local x: number = Utils:MapToInterval(fov, 0, 120, 0, 1)
  x = math.clamp(x, 0, 1)
  self._gui.Labels.FOV.Text = ("%.0f"):format(fov)
  self._gui.Sliders.FOV.Handle.Position = UDim2.fromScale(x, 0.5)
end

function ThumbMakerPlugin:_FOVSliderSetEnabled(enabled: boolean)
  self._gui.Sliders.FOV.Frame.Visible = enabled
end

function ThumbMakerPlugin:_setWarningText(text: string)
  self._gui.Labels.WarningLabel.Visible = text ~= nil
  self._gui.Labels.WarningLabel.Text = text or ""
end

function ThumbMakerPlugin:Destroy()
  self._gui.ScreenGui:Destroy()
end

local myPlugin = ThumbMakerPlugin.new(script.Parent:FindFirstChild(not isDonatorEdition and "ThumbMaker-Gui" or "ThumbMakerDonator-Gui"))
plugin.Unloading:Connect(function() myPlugin:Destroy() end)
