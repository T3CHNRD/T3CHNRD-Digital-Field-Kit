import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class DogMemoryEasterEgg: ObservableObject {
    @Published var presentedPhoto: DogMemoryPhoto?

    private var titleTapCount = 0
    private var lastTitleTap = Date.distantPast
    private var didPresentPhoto = false

    func recordTitleTap(toolkitRoot: URL) {
        guard !didPresentPhoto else { return }

        let now = Date()
        if now.timeIntervalSince(lastTitleTap) > 4 {
            titleTapCount = 0
        }
        lastTitleTap = now
        titleTapCount += 1
        guard titleTapCount >= 3 else { return }

        let photoDirectory = toolkitRoot.appendingPathComponent("Assets/DogMemories", isDirectory: true)
        let photos = (try? FileManager.default.contentsOfDirectory(
            at: photoDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ))?.filter {
            $0.lastPathComponent.hasPrefix("Diva-Tarabyte-") && $0.pathExtension.lowercased() == "jpg"
        }.sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []

        guard let photoURL = photos.randomElement(), let image = NSImage(contentsOf: photoURL) else { return }
        didPresentPhoto = true
        presentedPhoto = DogMemoryPhoto(image: image)
    }
}

struct DogMemoryPhoto: Identifiable {
    let id = UUID()
    let image: NSImage
}

struct DogMemoryPhotoSheet: View {
    let photo: DogMemoryPhoto
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: photo.image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 800, maxHeight: 680)

            Text("Diva & Tarabyte")
                .font(.title2.weight(.semibold))

            Button("Close") {
                dismiss()
            }
        }
        .padding(24)
        .frame(minWidth: 480, minHeight: 480)
    }
}
