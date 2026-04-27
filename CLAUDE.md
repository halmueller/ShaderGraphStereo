# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

ShaderGraphStereo is a visionOS sample app demonstrating stereoscopic image rendering using RealityKit and a ShaderGraph material. It loads left/right image pairs into a `ShaderGraphMaterial` (`StereoMaker.usda`) applied to a plane entity, displaying each eye's texture independently.

## Build & Test

Xcode project, no Makefile. Build via Xcode or `xcodebuild`:

```bash
xcodebuild -project "ShaderGraph Stereo.xcodeproj" -scheme "ShaderGraph Stereo" \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build
```

No tests are configured.

## Architecture

### Data flow
- `StereoPair` — plain struct with `leftImageName`, `rightImageName`, `comment`, `id`; four static examples bundled as asset catalog images
- `ImageViewer` — top-level view; holds `@State var selectedPair: StereoPair`; cycles through pairs via a "Next" button
- `StereoView` — `RealityView`-based view; loads `StereoMaker.usda` ShaderGraphMaterial in the async `make:` closure; applies textures per image pair in `updateStereo`

### Stereo rendering
- `StereoView` loads `ShaderGraphMaterial` named `/Root/StereoImage` from `StereoMaker.usda` (local RealityKitContent package)
- Sets `LeftImage` and `RightImage` parameters with `TextureResource` objects
- Scales a plane `ModelEntity` based on right image aspect ratio
- Entity name is set to `imagePair.id`; the `update:` closure early-exits if name matches (avoids redundant reloads on window resize)

### Dependencies (SPM)
- **RealityKitContent** — local package at `Packages/RealityKitContent/` providing `StereoMaker.usda`

### Deployment target
visionOS 2.0.

## Known Issues & Fix Plan

### Compile error (blocks build)
- **Duplicate `struct StereoView`**: Both `StereoView_revised.swift` and `StereoView_simple.swift` define `struct StereoView` and are both in the Xcode Compile Sources phase. Remove `StereoView_simple.swift` from the target (or delete it). The revised file is strictly better — it has the `imagePair.id` early-exit guard.

### Bugs
- **`TextureResource` load blocks render thread** (`StereoView_revised.swift` `updateStereo`): `TextureResource.load(named:)` is the synchronous overload, called from the `update:` closure which runs on the render thread. Move texture loading into a `.task(id: imagePair.id)` modifier using the async overload; store results in `@State var leftTexture` / `@State var rightTexture`; the `update:` closure should only apply already-loaded textures to the material.
- **`TextureResource` memory leak** (`StereoView_revised.swift:78`, marked `// !!!: Replacing the materials array leaks memory`): old textures are abandoned when the image changes. Storing them in `@State` (see above) gives ARC the opportunity to release old values when replaced.
- **Aspect ratio inversion for portrait images** (`StereoView_revised.swift:71–73`): the portrait branch sets `planeWidth = planeSideLength * aspectRatio` (too wide) and `planeHeight = planeSideLength` (too short). Should be `planeWidth = planeSideLength / aspectRatio`.

### Dead code in `StereoView_revised.swift`
- `@Environment(\.openWindow) var openWindow` (line 19) — never called
- `GeometryReader { geometry in` wrapper (lines 25, 45) — `geometry` never referenced; causes greedy layout expansion
- `let _ = Self._printChanges()` (line 29) — debug API, logs to stdout on every body evaluation; remove before shipping
- `@State private var leftTexture` / `@State private var rightTexture` (lines 16–17) — declared but never assigned (local `let` constants shadow them in `updateStereo`); wire them up as part of the async texture-loading fix or remove

### Dead file
- `StereoView_simple.swift` — superseded by `StereoView_revised.swift`; causes compile error (see above); delete

### Type system gap
- `StereoPair` defines a free `==` operator (line 22) but does not declare `: Equatable` conformance; add `Equatable` to the struct declaration so the type works in generic contexts

### Architecture
- `ImageViewer` cycles pairs via a manual if/else chain — fragile; add a `StereoPair` all-pairs array and index arithmetic instead
- `ShaderGraphMaterial` is loaded per `StereoView` instance; if multiple instances exist it should be cached and shared (only texture parameters change per image)
