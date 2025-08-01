import SwiftUI

// 模型
struct TouristSpot: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let imageName: String
}

// 模擬資料
let sampleSpots = [
    TouristSpot(name: "台北 101", description: "台灣知名地標，高樓觀景。", imageName: "taipei101"),
    TouristSpot(name: "日月潭", description: "中台灣美麗湖泊，適合划船和騎腳踏車。", imageName: "sunmoonlake"),
    TouristSpot(name: "阿里山", description: "以觀日、森林鐵道著稱的高山景點。", imageName: "alishan")
]

// 輪播圖
struct CarouselView: View {
    let images: [String]
    @State private var currentIndex = 0
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(0..<images.count, id: \.self) { index in
                Image(images[index])
                    .resizable()
                    .scaledToFill()
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .frame(height: 250)
        .onReceive(timer) { _ in
            withAnimation {
                currentIndex = (currentIndex + 1) % images.count
            }
        }
    }
}

// 主畫面
struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                CarouselView(images: sampleSpots.map { $0.imageName })

                List(sampleSpots) { spot in
                    VStack(alignment: .leading) {
                        Text(spot.name)
                            .font(.headline)
                        Text(spot.description)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("旅遊景點推薦")
        }
    }
}

#Preview {
    ContentView()
}

