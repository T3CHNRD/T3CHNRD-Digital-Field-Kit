import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class DogMemoryEasterEgg: ObservableObject {
    @Published var presentedPhoto: DogMemoryPhoto?

    private static let photoAttribution = [
        "Diva-Tarabyte-01.jpg": "Diva",
        "Diva-Tarabyte-02.jpg": "Diva",
        "Diva-Tarabyte-03.jpg": "Tarabyte"
    ]

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
            Self.photoAttribution[$0.lastPathComponent] != nil
        }.sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []

        guard let photoURL = photos.randomElement(), let image = NSImage(contentsOf: photoURL) else { return }
        let dogName = Self.photoAttribution[photoURL.lastPathComponent]
        guard let dogName else { return }
        didPresentPhoto = true
        presentedPhoto = DogMemoryPhoto(image: image, dogName: dogName)
    }

    func dismissPhoto() {
        presentedPhoto = nil
        didPresentPhoto = false
        titleTapCount = 0
        lastTitleTap = .distantPast
    }
}

struct DogMemoryPhoto: Identifiable {
    let id = UUID()
    let image: NSImage
    let dogName: String
}

struct DogMemoryPhotoSheet: View {
    let photo: DogMemoryPhoto
    let onClose: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: photo.image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 800, maxHeight: 680)

            Text("This app is brought to you by \(photo.dogName)")
                .font(.title2.weight(.semibold))

            Button("Close") {
                onClose()
                dismiss()
            }
        }
        .padding(24)
        .frame(minWidth: 480, minHeight: 480)
    }
}
