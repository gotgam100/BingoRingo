import SwiftUI

// MARK: - 메모리 + 디스크 이중 이미지 캐시

final class ImageCacheStore {
    static let shared = ImageCacheStore()
    private let memory = NSCache<NSString, UIImage>()
    private let diskDir: URL

    private init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskDir = base.appendingPathComponent("ProofImageCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskDir, withIntermediateDirectories: true)
    }

    func get(_ key: String) -> UIImage? {
        // 1순위: 메모리 (즉시)
        if let img = memory.object(forKey: key as NSString) { return img }
        // 2순위: 디스크 (앱 재시작 후에도 유효)
        let file = diskDir.appendingPathComponent(filename(for: key))
        guard let data = try? Data(contentsOf: file),
              let img = UIImage(data: data) else { return nil }
        memory.setObject(img, forKey: key as NSString)
        return img
    }

    func set(_ img: UIImage, for key: String) {
        memory.setObject(img, forKey: key as NSString)
        let file = diskDir.appendingPathComponent(filename(for: key))
        Task.detached(priority: .background) {
            if let data = img.jpegData(compressionQuality: 0.85) {
                try? data.write(to: file, options: .atomic)
            }
        }
    }

    private func filename(for url: String) -> String { "\(url.hashValue).jpg" }
}

// MARK: - 캐시 연동 비동기 이미지 뷰

struct CachedAsyncImage: View {
    let urlString: String
    @State private var uiImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage).resizable()
            } else {
                ZStack { Color.clear; if isLoading { ProgressView() } }
            }
        }
        .task(id: urlString) { await load() }
    }

    @MainActor
    private func load() async {
        if let cached = ImageCacheStore.shared.get(urlString) { uiImage = cached; return }
        guard let url = URL(string: urlString) else { return }
        isLoading = true
        if let (data, _) = try? await URLSession.shared.data(from: url),
           let img = UIImage(data: data) {
            ImageCacheStore.shared.set(img, for: urlString)
            uiImage = img
        }
        isLoading = false
    }

    /// 백그라운드에서 URL 목록을 미리 캐시에 적재
    static func prefetch(urls: [String]) {
        for urlString in urls {
            guard ImageCacheStore.shared.get(urlString) == nil,
                  let url = URL(string: urlString) else { continue }
            Task.detached(priority: .background) {
                guard let (data, _) = try? await URLSession.shared.data(from: url),
                      let img = UIImage(data: data) else { return }
                ImageCacheStore.shared.set(img, for: urlString)
            }
        }
    }
}
