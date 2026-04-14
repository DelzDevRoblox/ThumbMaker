# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-04-14

### Added

- Button to change camera mode from Perspective to Orthographic, by @Jademaus.
- Nudge camera with keyboard for fine positioning of the Camera, by @Jademaus.
- When switching from Normal to Orthographic view the Thumbnails stays roughly the same, by @Jademaus.

### Changed

- Accessories are now able to use FOV with a trick discovered by @RZKU and the help of @Jademaus.
- Changed how camera state is saved and loaded for others than Accessories.

## [1.0.6] - 2024-11-08

### Changed

- Displays to the users that accessories can't use the FOV Slider. To avoid confusion.

## [1.0.5] - 2024-09-06

### Changed

- A few UI improvements.

## [1.0.4] - 2024-08-03

### Added

- Added Roblox Typechecking.

## [1.0.3] - 2023-07-22

### Changed

- Accessories now use ThumbnailConfiguration as Roblox tells UGC creators to.

## [1.0.2] - 2023-07-17

### Added

- Added Folder to the allowed classes.
- Added Configuration to the allowed classes since it can be rarely used as a container just as Model and Folder.

### Fixed

- Error when no thumbnail existed but the plugin tried to access it.

### Changed

- Changes to the code have been made, but the plugin still functions in the same way.
- Changed Grid and Gui binary from .rbxm to .rbxmx

## [1.0.1] - 2023-07-12

### Added

- Add camera reset button, that resets the camera back to the saved ThumbnailCamera position.
- Add a label displaying of the ThumbnailCamera offset from the model.
- Try to account for when the user starts moving the models.

### Changed

- When closing the plugin GUI, the current selected model is deselected from the GUI.
- When opening the plugin GUI, if you have a model selected the GUI will try to select it.

## [1.0.0] - 2023-07-11

### Added

- Published first version of the plugin.
