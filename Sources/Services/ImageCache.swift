import SwiftUI
import CryptoKit

// MARK: - 메모리 + 디스크 이중 이미지 캐시

final class ImageCacheStore {
    static let shared = ImageCacheStore()
    private let memory = NSCache<NSString, UIImage>()
    private let diskDir: URL

    private init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        // 예전 캐시는 앱을 켤 때마다 파일 이름이 달라져 재사용되지 않고 쌓이기만 했으므로 한 번 정리
        try? FileManager.default.removeItem(at: base.appendingPathComponent("ProofImageCache", isDirectory: true))
        diskDir = base.appendingPathComponent("ProofImageCache_v2", isDirectory: true)
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

    /// URL → 항상 같은 파일 이름 (String.hashValue는 앱 실행마다 바뀌어서 디스크 캐시가 맞지 않았음)
    private func filename(for url: String) -> String {
        let digest = SHA256.hash(data: Data(url.utf8))
        return digest.map { String(format: "%02x", $0) }.joined() + ".jpg"
    }
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
