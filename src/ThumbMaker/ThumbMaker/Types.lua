--!strict

export type ThumbMakerPluginType = {
  -- core
  _version: string,
  _pluginInitialized: boolean,

  -- selection
  _selected: {
    instance: Instance?,
    moveRBXConnection: RBXScriptConnection?
  },

  _allowedClasses: {[string]: boolean},

  -- nudge
  _nudgeConnection: RBXScriptConnection?,
  _nudgeStep: number,

  -- gui
  _gui: {
    ScreenGui: ScreenGui,
    Frame: Frame,
    Props : {
      StartingFOV: number,
      OriginalDeleteButtonColor: Color3,
      OriginalResetCameraOffsetButtonColor: Color3,
      FOVHandleDragging: boolean,
      IsOrthoMode: boolean,
      OrthoDistance: number,
      PerspectiveFOV: number,
      WarningRevertThread: thread?,
    },
    Credits : {
      Version: TextLabel
    },
    FavoriteStarButton : {
      Button: ImageButton,
      CloseButton: TextButton,
      InfoBox: Frame
    },
    ChangelogButton : {
      Button: ImageButton,
      CloseButton: TextButton,
      InfoBox: Frame,
    },
    Labels : {
      Offset: TextLabel,
      FOV: TextLabel,
      UGCFOVInfo: TextLabel,
      WarningLabel: TextLabel,
      CameraMode: TextLabel,
    },
    Sliders : {
      [string]: {
        Frame: Frame,
        Bar: Frame,
        Handle: TextButton,
      }
    },
    Buttons : {
      Quit: TextButton,
      Delete: TextButton,
      Make: TextButton,
      ResetOffset: ImageButton,
      CameraMode: TextButton,
      AutoFrame: ImageButton
    },
    Viewports : {
      MainViewport: ViewportFrame,
      PreviewLightMode: ViewportFrame,
      PreviewDarkMode: ViewportFrame,
    },
  },

  -- private methods
  _init: (self: ThumbMakerPluginType) -> (),
  _initGui: (self: ThumbMakerPluginType) -> (),

  _togglePerspective: (self: ThumbMakerPluginType) -> (),
  _forceOrtho: (self: ThumbMakerPluginType, fov: number?) -> (),
  _forcePerspective: (self: ThumbMakerPluginType, fov: number?) -> (),
  _onCameraModeChanges: (self: ThumbMakerPluginType) -> (),

  _autoFrameModel: (self: ThumbMakerPluginType) -> (),
  _initScaledPan: (self: ThumbMakerPluginType) -> (),
  
  _saveCameraState: (self: ThumbMakerPluginType, target: Camera | Configuration) -> (),
  _loadCameraState: (self: ThumbMakerPluginType, target: Camera | Configuration) -> (),

  _guiOpen: (self: ThumbMakerPluginType) -> (),
  _guiClose: (self: ThumbMakerPluginType) -> (),

  _selectInstance: (self: ThumbMakerPluginType, instance: Instance) -> boolean?,
  _onSelectionChanges: (self: ThumbMakerPluginType) -> (),
  _deselectCurrentlySelected: (self: ThumbMakerPluginType) -> (),

  _getSelectedModel: (self: ThumbMakerPluginType) -> Instance?,
  _getSelectedInstance: (self: ThumbMakerPluginType) -> Instance?,

  _updateViewportsClone: (self: ThumbMakerPluginType, instance: Instance) -> (),
  _destroyViewportsClone: (self: ThumbMakerPluginType) -> (),

  _isClassAllowed: (self: ThumbMakerPluginType, instance: Instance) -> boolean,

  _makeThumbnail: (self: ThumbMakerPluginType) -> (),
  _makeThumbnailAccessory: (self: ThumbMakerPluginType) -> (),
  _updateThumbnail: (self: ThumbMakerPluginType) -> (),
  _deleteCurrentThumbnail: (self: ThumbMakerPluginType) -> (),

  _updateButtonColors: (self: ThumbMakerPluginType) -> (),

  _findPivot: (self: ThumbMakerPluginType, instance: Instance) -> CFrame,

  _resetCameraOffset: (self: ThumbMakerPluginType) -> (),
  _resetCameraOffsetAccessory: (self: ThumbMakerPluginType) -> (),
  _loadCameraStateFallback: (self: ThumbMakerPluginType, instance: Instance, target: Camera) -> (),

  _moveCameraTo: (self: ThumbMakerPluginType, cframe: CFrame) -> (),

  _setupMoveEvent: (self: ThumbMakerPluginType) -> (),
  _updateGridPosition: (self: ThumbMakerPluginType) -> (),

  _FOVSliderCalculatePosition: (self: ThumbMakerPluginType, input: InputObject) -> (),
  _FOVSliderSetPosition: (self: ThumbMakerPluginType, fov: number) -> (),
  _FOVSliderSetEnabled: (self: ThumbMakerPluginType, enabled: boolean) -> (),

  _setWarningText: (self: ThumbMakerPluginType, text: string?, revertAfter: number?) -> (),

  -- public methods
  Destroy: (self: ThumbMakerPluginType) -> (),
}

return nil
