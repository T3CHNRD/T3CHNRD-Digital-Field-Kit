This folder is a placeholder for the future macOS Intel native app and installer.
The full project scope and roadmap live in the root README.md.
This platform is intentionally not built yet while the Windows release gate remains active.

Portable dog-memory Easter egg source: [../macOS Shared/DogMemoryEasterEgg.swift](../macOS%20Shared/DogMemoryEasterEgg.swift).
Both Mac targets must compile that shared source, pass the toolkit-root URL when a tool completes, and present DogMemoryPhotoSheet with the observable presentedPhoto item. The shared JPEGs live at Assets/DogMemories relative to the toolkit root. Count only successful, non-cancelled runs; the helper presents one random photo after the third.

This is reusable Mac source, not a runnable Mac app. Runtime integration and testing remain pending until the native app is built.
