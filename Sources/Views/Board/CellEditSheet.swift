import SwiftUI

struct CellEditSheet: View {
    let currentTitle: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""

    init(currentTitle: String, onSave: @escaping (String) -> Void) {
        self.currentTitle = currentTitle
        self.onSave = onSave
        _title = State(initialValue: currentTitle)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BRColors.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(BRColors.blue)
                            .frame(height: 90)
                        HStack {
                            Blob1().fill(BRColors.yellow.opacity(0.5))
                                .frame(width: 70, height: 70).offset(x: -10)
                            Spacer()
                            Circle().fill(BRColors.red.opacity(0.5))
                                .frame(width: 50, height: 50).offset(x: 10)
                        }.padding(.horizontal)

                        Label("항목 제목 수정", systemImage: "crown.fill")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("항목 제목")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(BRColors.secondary)
                        TextField("미션 이름을 입력하세요", text: $title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.05), radius: 4)
                            )
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button {
                        onSave(title)
                        dismiss()
                    } label: {
                        Text("저장")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(title.isEmpty ? BRColors.lightGray : BRColors.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(title.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding(.top, 24)
            }
            .navigationBarHidden(false)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .foregroundStyle(BRColors.blue)
                }
            }
        }
    }
}
