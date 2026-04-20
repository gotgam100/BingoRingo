import SwiftUI
import PhotosUI

struct CellDetailView: View {
    let cell: BingoCell
    let memberIDs: [String]
    let currentMemberID: String
    let onToggle: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedPhoto: PhotosPickerItem?

    private var isCompletedByMe: Bool {
        cell.completedBy.contains(currentMemberID)
    }

    private var completedCount: Int { cell.completedBy.count }
    private var totalCount: Int { memberIDs.count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 완료 현황 원형 표시
                ZStack {
                    Circle()
                        .stroke(BRColors.lightGray, lineWidth: 8)
                        .frame(width: 120, height: 120)
                    Circle()
                        .trim(from: 0, to: CGFloat(completedCount) / CGFloat(max(totalCount, 1)))
                        .stroke(BRColors.cobaltBlue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                    VStack(spacing: 2) {
                        Text("\(completedCount)/\(totalCount)")
                            .font(BRTypography.sectionTitle)
                            .foregroundStyle(BRColors.cobaltBlue)
                        Text("완료")
                            .font(BRTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // 미션 제목
                Text(cell.title)
                    .font(BRTypography.sectionTitle)
                    .multilineTextAlignment(.center)

                if !cell.description.isEmpty {
                    Text(cell.description)
                        .font(BRTypography.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // 인증 사진 버튼
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("인증 사진 추가", systemImage: "camera.fill")
                        .font(BRTypography.cellTitle)
                        .foregroundStyle(BRColors.cobaltBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(BRColors.cobaltBlue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // 완료 토글 버튼
                Button {
                    onToggle()
                    dismiss()
                } label: {
                    Text(isCompletedByMe ? "완료 취소하기" : "미션 완료!")
                        .font(BRTypography.cellTitle)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isCompletedByMe ? BRColors.red : BRColors.cobaltBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(24)
            .navigationTitle("미션 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
}
