import SwiftUI

struct CellDetailView: View {
    let cell: BingoCell
    let row: Int
    let col: Int
    let memberIDs: [String]
    let currentMemberID: String
    let onToggle: () -> Void
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var boardVM: BoardViewModel

    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var fullScreenURL: String?
    @State private var showDeleteConfirm = false
    @State private var showSourceMenu = false
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var currentPhotoIndex = 0
    @State private var showCompletionToast = false
    @State private var showCancellationToast = false
    @State private var commentText = ""
    @State private var editingCommentID: String? = nil
    @FocusState private var commentFocused: Bool
    @State private var showEmojiPicker = false
    @State private var showReactionViewer = false

    init(cell: BingoCell, row: Int, col: Int, memberIDs: [String], currentMemberID: String,
         boardVM: BoardViewModel, onToggle: @escaping () -> Void) {
        self.cell = cell
        self.row = row
        self.col = col
        self.memberIDs = memberIDs
        self.currentMemberID = currentMemberID
        self.onToggle = onToggle
        _boardVM = ObservedObject(wrappedValue: boardVM)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.M.d HH:mm"
        return f
    }()

    private var currentCell: BingoCell {
        boardVM.board?.cell(row: row, col: col) ?? cell
    }

    private var isCompletedByMe: Bool { currentCell.completedBy.contains(currentMemberID) }
    private var completedCount: Int { currentCell.completedBy.count }
    private var totalCount: Int { memberIDs.count }
    private var ratio: CGFloat { totalCount > 0 ? CGFloat(completedCount) / CGFloat(totalCount) : 0 }
    private var myProofURL: String? { currentCell.proofImageURLs[currentMemberID] }

    // 사진 프레임 1:1 크기 (화면 너비 기반)
    private var photoSize: CGFloat { min(UIScreen.main.bounds.width - 48, 340) }

    private var currentOwnerID: String {
        guard currentPhotoIndex < photoSlideMembers.count else { return "" }
        return photoSlideMembers[currentPhotoIndex]
    }

    private var interactionKey: String {
        BingoBoard.interactionKey(cellID: currentCell.id, ownerID: currentOwnerID)
    }

    private var reactionsForCurrentPhoto: [String: String] {
        boardVM.board?.cellReactions[interactionKey] ?? [:]
    }

    private var commentsForCurrentPhoto: [CellComment] {
        boardVM.board?.cellComments[interactionKey] ?? []
    }

    /// 슬라이드에 표시할 멤버: 나 우선 + 완료/사진 올린 멤버
    private var photoSlideMembers: [String] {
        let relevant = Set([currentMemberID])
            .union(currentCell.completedBy)
            .union(currentCell.proofImageURLs.keys)
        var result = memberIDs.filter { relevant.contains($0) }
        if !result.contains(currentMemberID) { result.insert(currentMemberID, at: 0) }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BRColors.surface.ignoresSafeArea()

                Circle()
                    .fill(BRColors.primaryDim)
                    .frame(width: 160, height: 160)
                    .offset(x: 140, y: -160)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {

                        // 미션 세부내용 (제목 아래, 진행원 위)
                        if !currentCell.description.isEmpty {
                            Text(currentCell.description)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(BRColors.onSurfaceMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .padding(.top, 16)
                        }

                        // 진행률 원형 (작게)
                        ZStack {
                            Circle().fill(BRColors.surfaceLow).frame(width: 88, height: 88)
                            Circle().stroke(BRColors.surfaceContainer, lineWidth: 8).frame(width: 72, height: 72)
                            Circle()
                                .trim(from: 0, to: ratio)
                                .stroke(BRColors.primaryGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 72, height: 72)
                                .animation(.spring(duration: 0.5), value: ratio)
                            VStack(spacing: 1) {
                                Text("\(completedCount)/\(totalCount)")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundStyle(BRColors.primary)
                                Text(Localization.Board.complete)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(BRColors.onSurfaceMuted)
                            }
                        }
                        .padding(.top, currentCell.description.isEmpty ? 20 : 12)

                        // ── 통합 인증 사진 슬라이드 ──
                        photoSection
                            .padding(.top, 20)

                        // ── 댓글 (사진이 있을 때만) ──
                        if currentCell.proofImageURLs[currentOwnerID] != nil {
                            commentSection
                                .padding(.top, 16)
                        }

                        // 업로드 에러
                        if let error = uploadError {
                            Text(error)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(BRColors.tertiary)
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                        }

                        Spacer(minLength: 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)

                // ── 사진 소스 선택 중앙 오버레이 ──
                if showSourceMenu {
                    sourcePickerOverlay
                }

                // ── 삭제 확인 중앙 오버레이 ──
                if showDeleteConfirm {
                    deleteConfirmOverlay
                }

                // ── 이모지 반응 피커 ──
                if showEmojiPicker {
                    emojiPickerOverlay
                }

                // ── 반응 목록 뷰어 (내 사진용) ──
                if showReactionViewer {
                    reactionViewerOverlay
                }

                // ── 미션 완료 토스트 ──
                if showCompletionToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                            Text(Localization.isEnglish ? "Mission Complete!" : "미션 완료")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(BRColors.primary)
                        .clipShape(Capsule())
                        .shadow(color: BRColors.primary.opacity(0.4), radius: 12, y: 4)
                        .padding(.bottom, 20)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
                }

                // ── 미션 취소 토스트 ──
                if showCancellationToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                            Text(Localization.isEnglish ? "Completion Cancelled" : "완료 취소")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(BRColors.tertiary)
                        .clipShape(Capsule())
                        .shadow(color: BRColors.tertiary.opacity(0.4), radius: 12, y: 4)
                        .padding(.bottom, 20)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
                }
            }
            // 네비게이션 타이틀 = 미션 제목
            .navigationTitle(currentCell.title.isEmpty ? Localization.CellDetail.missionDetail : currentCell.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.Settings.close) { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BRColors.primary)
                }
            }
            .background(
                ImagePickerPresenter(
                    sourceType: imagePickerSource,
                    isPresented: $showImagePicker
                ) { image in
                    Task {
                        isUploading = true
                        uploadError = nil
                        let wasCompleted = isCompletedByMe
                        do {
                            try await boardVM.uploadProofImage(
                                row: row, col: col, memberID: currentMemberID, image: image
                            )
                            // 사진 등록 시 자동 완료
                            if !wasCompleted {
                                onToggle()
                                withAnimation(.spring(duration: 0.3)) { showCompletionToast = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                                    withAnimation(.spring(duration: 0.3)) { showCompletionToast = false }
                                }
                            }
                        } catch {
                            uploadError = Localization.isEnglish
                                ? "Upload failed. Please try again."
                                : "업로드에 실패했어요. 다시 시도해주세요."
                        }
                        isUploading = false
                    }
                }
            )
            .fullScreenCover(item: $fullScreenURL) { urlString in
                FullScreenPhotoView(urlString: urlString)
            }
            .onChange(of: currentPhotoIndex) {
                commentText = ""
                commentFocused = false
                showEmojiPicker = false
                showReactionViewer = false
            }
            .onAppear {
                // 뷰 등장 시 현재 셀의 모든 인증사진을 백그라운드에서 미리 로드
                let urls = photoSlideMembers.compactMap { currentCell.proofImageURLs[$0] }
                CachedAsyncImage.prefetch(urls: urls)
            }
        }
    }

    // MARK: - 사진 소스 선택 중앙 오버레이

    private var sourcePickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { showSourceMenu = false }

            VStack(spacing: 0) {
                Button {
                    showSourceMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        imagePickerSource = .photoLibrary
                        showImagePicker = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 18))
                        Text(Localization.isEnglish ? "Photo Library" : "사진 앨범에서 선택")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundStyle(BRColors.onSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }

                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Divider().opacity(0.25)
                    Button {
                        showSourceMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            imagePickerSource = .camera
                            showImagePicker = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                            Text(Localization.isEnglish ? "Take Photo" : "카메라로 촬영")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundStyle(BRColors.onSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                    }
                }

                Divider().opacity(0.25)

                Button {
                    showSourceMenu = false
                } label: {
                    Text(Localization.isEnglish ? "Cancel" : "취소")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(BRColors.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
            }
            .background(BRColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.18), radius: 24, y: 8)
            .padding(.horizontal, 36)
        }
    }

    // MARK: - 삭제 확인 중앙 오버레이

    private var deleteConfirmOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { showDeleteConfirm = false }

            VStack(spacing: 0) {
                Text(Localization.isEnglish ? "Delete proof photo?" : "인증 사진을 삭제할까요?")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(BRColors.onSurface)
                    .padding(.vertical, 18)

                Divider().opacity(0.25)

                Button {
                    showDeleteConfirm = false
                    Task {
                        await boardVM.deleteProofImage(row: row, col: col, memberID: currentMemberID)
                        withAnimation(.spring(duration: 0.3)) { showCancellationToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            withAnimation(.spring(duration: 0.3)) { showCancellationToast = false }
                        }
                    }
                } label: {
                    Text(Localization.isEnglish ? "Delete" : "삭제")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(BRColors.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }

                Divider().opacity(0.25)

                Button { showDeleteConfirm = false } label: {
                    Text(Localization.isEnglish ? "Cancel" : "취소")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(BRColors.onSurfaceMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
            }
            .background(BRColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.18), radius: 24, y: 8)
            .padding(.horizontal, 36)
        }
    }

    // MARK: - 통합 인증 사진 섹션

    private var photoSection: some View {
        let tabHeight = photoSize + 72 + 8

        return VStack(alignment: .leading, spacing: 8) {
            Text(Localization.isEnglish ? "Complete Your Mission" : "미션을 완료하세요")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(BRColors.onSurface)
                .padding(.horizontal, 24)
                .padding(.bottom, 4)

            TabView(selection: $currentPhotoIndex) {
                ForEach(Array(photoSlideMembers.enumerated()), id: \.element) { idx, mid in
                    photoCard(memberID: mid)
                        .padding(.horizontal, 24)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: tabHeight)
            .onChange(of: photoSlideMembers.count) {
                if currentPhotoIndex >= photoSlideMembers.count {
                    currentPhotoIndex = max(0, photoSlideMembers.count - 1)
                }
            }

            // 하단 페이지 표시 + 좌우 화살표 (항상 표시)
            HStack {
                Spacer()
                HStack(spacing: 10) {
                    if currentPhotoIndex > 0 {
                        Button {
                            withAnimation(.spring(duration: 0.3)) { currentPhotoIndex -= 1 }
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(BRColors.primary)
                        }
                    } else {
                        Color.clear.frame(width: 28, height: 28)
                    }

                    Text("\(currentPhotoIndex + 1) / \(photoSlideMembers.count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BRColors.onSurfaceMuted)
                        .monospacedDigit()

                    if currentPhotoIndex < photoSlideMembers.count - 1 {
                        Button {
                            withAnimation(.spring(duration: 0.3)) { currentPhotoIndex += 1 }
                        } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(BRColors.primary)
                        }
                    } else {
                        Color.clear.frame(width: 28, height: 28)
                    }
                }
                Spacer()
            }
            .padding(.bottom, 4)
        }
    }

    // MARK: - 개별 인증 사진 카드

    private func photoCard(memberID mid: String) -> some View {
        let profile = boardVM.memberProfiles[mid]
        let proofURL = currentCell.proofImageURLs[mid]
        let isMe = mid == currentMemberID
        let isCompleted = currentCell.completedBy.contains(mid)

        return VStack(spacing: 0) {
            // 1:1 사진 프레임
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(BRColors.surfaceLow)

                if let urlString = proofURL {
                    ZStack(alignment: .topTrailing) {
                        CachedAsyncImage(urlString: urlString)
                            .scaledToFill()
                            .frame(width: photoSize, height: photoSize)
                            .clipped()
                            .onTapGesture { fullScreenURL = urlString }

                        // 내 사진: 연필 버튼 → 바로 사진 라이브러리로 이동해 재편집
                        if isMe {
                            Button {
                                imagePickerSource = .photoLibrary
                                showImagePicker = true
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.white.opacity(0.85))
                                    .shadow(color: .black.opacity(0.35), radius: 4)
                                    .padding(10)
                            }
                        }
                    }

                } else if isMe {
                    Button { showSourceMenu = true } label: {
                        VStack(spacing: 10) {
                            if isUploading {
                                ProgressView().scaleEffect(1.4).tint(BRColors.primary)
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(BRColors.primary)
                                Text(Localization.isEnglish ? "Add proof photo" : "인증 사진 추가")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(BRColors.primary)
                                Text(Localization.isEnglish
                                     ? "Upload a photo to complete the mission"
                                     : "사진을 인증해 미션을 완료하세요")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(BRColors.onSurfaceMuted)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .padding(.top, 2)
                            }
                        }
                        .frame(width: photoSize, height: photoSize)
                    }
                    .disabled(isUploading)

                } else {
                    VStack(spacing: 8) {
                        Image(systemName: isCompleted ? "checkmark.circle" : "photo")
                            .font(.system(size: 28))
                            .foregroundStyle(BRColors.onSurfaceMuted.opacity(0.3))
                        Text(isCompleted
                             ? (Localization.isEnglish ? "No photo" : "사진 없음")
                             : (Localization.isEnglish ? "Not completed" : "미완료"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(BRColors.onSurfaceMuted.opacity(0.3))
                    }
                    .frame(width: photoSize, height: photoSize)
                }
            }
            .frame(width: photoSize, height: photoSize)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(alignment: .bottomLeading) {
                if proofURL != nil {
                    photoReactionOverlay(for: mid)
                }
            }

            // 멤버 정보
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(BRColors.primaryDim).frame(width: 34, height: 34)
                    Text(profile?.profileEmoji ?? "😀").font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(profile?.displayName ?? (Localization.isEnglish ? "Unknown" : "알 수 없음"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(BRColors.onSurface)
                        if isMe {
                            Text(Localization.Home.me)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(BRColors.primary)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(BRColors.primaryDim)
                                .clipShape(Capsule())
                        }
                    }
                    if let date = currentCell.completedAt[mid] {
                        Text(Self.dateFormatter.string(from: date))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(BRColors.onSurfaceMuted)
                    }
                }
                Spacer()
                if isMe, proofURL != nil {
                    Button { showDeleteConfirm = true } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 20))
                            .foregroundStyle(BRColors.tertiary.opacity(0.65))
                    }
                }
            }
            .padding(.top, 10)
        }
    }

    // MARK: - 사진 프레임 내 반응 오버레이 (좌하단)

    private func photoReactionOverlay(for ownerID: String) -> some View {
        let key = BingoBoard.interactionKey(cellID: currentCell.id, ownerID: ownerID)
        let reactions = boardVM.board?.cellReactions[key] ?? [:]
        let aggregated: [(String, Int)] = ReactionPalette.emojis.compactMap { emoji in
            let count = reactions.values.filter { $0 == emoji }.count
            return count > 0 ? (emoji, count) : nil
        }
        let isOwnPhoto = ownerID == currentMemberID

        return VStack(alignment: .leading, spacing: 6) {
            // 집계된 이모지 chips
            if !aggregated.isEmpty {
                HStack(spacing: 5) {
                    ForEach(aggregated, id: \.0) { emoji, count in
                        Text(count > 1 ? "\(emoji) \(count)" : emoji)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Capsule())
                    }
                }
            }

            // 반응 버튼 — 내 사진: 반응 목록 보기 / 타인 사진: 이모지 피커 열기
            Button {
                if isOwnPhoto { showReactionViewer = true }
                else { showEmojiPicker = true }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: isOwnPhoto ? "face.smiling" : "face.smiling")
                        .font(.system(size: 13, weight: .semibold))
                    Text(Localization.isEnglish ? "React" : "반응")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
            }
        }
        .padding(12)
    }

    // MARK: - 이모지 피커 오버레이

    private var emojiPickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { showEmojiPicker = false }

            VStack(spacing: 16) {
                Text(Localization.CellDetail.reactions)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(BRColors.onSurface)

                let myReaction = reactionsForCurrentPhoto[currentMemberID]
                let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
                LazyVGrid(columns: cols, spacing: 8) {
                    ForEach(ReactionPalette.emojis, id: \.self) { emoji in
                        let isSelected = myReaction == emoji
                        Button {
                            Task {
                                await boardVM.toggleReaction(
                                    row: row, col: col,
                                    photoOwnerID: currentOwnerID,
                                    reactorID: currentMemberID,
                                    emoji: emoji
                                )
                            }
                            showEmojiPicker = false
                        } label: {
                            Text(emoji)
                                .font(.system(size: 28))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(isSelected ? BRColors.primaryDim : BRColors.surfaceLow)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(isSelected ? BRColors.primary : Color.clear, lineWidth: 2)
                                )
                        }
                        .animation(.spring(duration: 0.2), value: isSelected)
                    }
                }
            }
            .padding(24)
            .background(BRColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.18), radius: 24, y: 8)
            .padding(.horizontal, 36)
        }
    }

    // MARK: - 반응 목록 뷰어 (내 사진용)

    private var reactionViewerOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { showReactionViewer = false }

            VStack(spacing: 16) {
                Text(Localization.isEnglish ? "Reactions" : "반응")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(BRColors.onSurface)

                let reactions = reactionsForCurrentPhoto
                if reactions.isEmpty {
                    Text(Localization.isEnglish ? "No reactions yet." : "아직 반응이 없어요.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(BRColors.onSurfaceMuted)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(reactions.keys).sorted(), id: \.self) { reactorID in
                            let emoji = reactions[reactorID] ?? ""
                            let profile = boardVM.memberProfiles[reactorID]
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle().fill(BRColors.primaryDim).frame(width: 36, height: 36)
                                    Text(profile?.profileEmoji ?? "😀").font(.system(size: 18))
                                }
                                Text(profile?.displayName ?? (Localization.isEnglish ? "Unknown" : "알 수 없음"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(BRColors.onSurface)
                                Spacer()
                                Text(emoji).font(.system(size: 24))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            if reactorID != Array(reactions.keys).sorted().last {
                                Divider().padding(.leading, 64).opacity(0.5)
                            }
                        }
                    }
                    .background(BRColors.surfaceLow)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button { showReactionViewer = false } label: {
                    Text(Localization.isEnglish ? "Close" : "닫기")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BRColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(BRColors.primaryDim)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(24)
            .background(BRColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.18), radius: 24, y: 8)
            .padding(.horizontal, 36)
        }
    }

    // MARK: - 댓글 섹션

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.CellDetail.comments)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(BRColors.onSurface)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            if commentsForCurrentPhoto.isEmpty {
                Text(Localization.CellDetail.noComments)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BRColors.onSurfaceMuted)
                    .padding(.horizontal, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(commentsForCurrentPhoto) { comment in
                        commentRow(comment: comment)
                        if comment.id != commentsForCurrentPhoto.last?.id {
                            Divider()
                                .padding(.leading, 58)
                                .opacity(0.5)
                        }
                    }
                }
                .background(BRColors.surfaceLow)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
            }

            // 댓글 입력창
            HStack(spacing: 10) {
                TextField(Localization.CellDetail.commentPlaceholder, text: $commentText)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.black)
                    .focused($commentFocused)
                    .submitLabel(.send)
                    .onSubmit { sendComment() }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(BRColors.surfaceLow)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Button {
                    sendComment()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(commentText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? BRColors.surfaceContainer : BRColors.primary)
                        .clipShape(Circle())
                }
                .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty)
                .animation(.spring(duration: 0.2), value: commentText.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func commentRow(comment: CellComment) -> some View {
        let profile = boardVM.memberProfiles[comment.authorMemberID]
        let isMe = comment.authorMemberID == currentMemberID

        return HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle().fill(BRColors.primaryDim).frame(width: 32, height: 32)
                Text(profile?.profileEmoji ?? "😀").font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(profile?.displayName ?? (Localization.isEnglish ? "Unknown" : "알 수 없음"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(BRColors.onSurface)
                    Text(Self.dateFormatter.string(from: comment.createdAt))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(BRColors.onSurfaceMuted)
                }
                Text(comment.text)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(BRColors.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if isMe {
                HStack(spacing: 10) {
                    Button {
                        commentText = comment.text
                        editingCommentID = comment.id
                        commentFocused = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 13))
                            .foregroundStyle(BRColors.primary.opacity(0.6))
                    }
                    Button {
                        Task {
                            await boardVM.deleteComment(
                                row: row, col: col,
                                photoOwnerID: currentOwnerID,
                                commentID: comment.id
                            )
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundStyle(BRColors.tertiary.opacity(0.6))
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func sendComment() {
        let trimmed = commentText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let editID = editingCommentID
        commentText = ""
        commentFocused = false
        editingCommentID = nil
        Task {
            if let editID {
                await boardVM.editComment(
                    row: row, col: col,
                    photoOwnerID: currentOwnerID,
                    commentID: editID,
                    newText: trimmed
                )
            } else {
                await boardVM.addComment(
                    row: row, col: col,
                    photoOwnerID: currentOwnerID,
                    authorID: currentMemberID,
                    text: trimmed
                )
            }
        }
    }
}

// ImageCacheStore, CachedAsyncImage → Sources/Services/ImageCache.swift

// MARK: - 카메라 / 사진 앨범 피커
// UIHostingController 경고를 피하기 위해 윈도우 최상단 VC에서 UIKit present() 사용

private struct ImagePickerPresenter: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var isPresented: Bool
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()   // 플레이스홀더 — present는 윈도우 최상단 VC에서 수행
    }

    func updateUIViewController(_ vc: UIViewController, context: Context) {
        if isPresented, context.coordinator.picker == nil {
            DispatchQueue.main.async {
                guard let topVC = Self.topViewController() else { return }
                let picker = UIImagePickerController()
                picker.sourceType = self.sourceType
                picker.allowsEditing = true
                picker.delegate = context.coordinator
                context.coordinator.picker = picker
                topVC.present(picker, animated: true)
            }
        } else if !isPresented, let picker = context.coordinator.picker {
            picker.dismiss(animated: true) { context.coordinator.picker = nil }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    private static func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }

        var top = root
        while let presented = top.presentedViewController { top = presented }
        return top
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePickerPresenter
        var picker: UIImagePickerController?

        init(_ parent: ImagePickerPresenter) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            if let image { parent.onImagePicked(image) }
            picker.dismiss(animated: true) {
                self.picker = nil
                self.parent.isPresented = false
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) {
                self.picker = nil
                self.parent.isPresented = false
            }
        }
    }
}

// MARK: - 전체화면 사진 뷰

extension String: @retroactive Identifiable {
    public var id: String { self }
}

struct FullScreenPhotoView: View {
    let urlString: String
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CachedAsyncImage(urlString: urlString)
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in scale = lastScale * value }
                        .onEnded { _ in
                            lastScale = scale
                            if scale < 1 { withAnimation { scale = 1; lastScale = 1 } }
                        }
                )
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(20)
                    }
                }
                Spacer()
            }
        }
        .onTapGesture(count: 2) {
            withAnimation { scale = scale > 1.5 ? 1 : 2.5; lastScale = scale }
        }
    }
}
