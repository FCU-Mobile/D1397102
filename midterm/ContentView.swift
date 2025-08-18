import SwiftUI
import MapKit

// MARK: - 模型與分類
enum Category: String, CaseIterable, Identifiable {
    case nature = "自然景觀"
    case culture = "文化古蹟"
    case food = "美食景點"
    
    var id: String { rawValue }
}

struct TouristSpot: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let imageName: String
    let latitude: Double
    let longitude: Double
    let category: Category
}

// MARK: - 假資料
let sampleSpots = [
    TouristSpot(name: "台北 101", description: "台灣知名地標，高樓觀景。", imageName: "taipei101", latitude: 25.0330, longitude: 121.5654, category: .culture),
    TouristSpot(name: "日月潭", description: "中台灣美麗湖泊，適合划船和騎腳踏車。", imageName: "sunmoonlake", latitude: 23.8659, longitude: 120.9150, category: .nature),
    TouristSpot(name: "阿里山", description: "以觀日、森林鐵道著稱的高山景點。", imageName: "alishan", latitude: 23.5083, longitude: 120.8020, category: .nature)
]

// MARK: - 收藏功能
class FavoritesManager: ObservableObject {
    @Published var favorites: [TouristSpot] = []
    
    func toggle(_ spot: TouristSpot) {
        if let index = favorites.firstIndex(of: spot) {
            favorites.remove(at: index)
        } else {
            favorites.append(spot)
        }
    }
    
    func isFavorite(_ spot: TouristSpot) -> Bool {
        favorites.contains(spot)
    }
}

// MARK: - 輪播圖
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

// MARK: - 主畫面
struct ContentView: View {
    @State private var searchText = ""
    @State private var selectedCategory: Category? = nil
    
    var filteredSpots: [TouristSpot] {
        sampleSpots.filter { spot in
            (searchText.isEmpty || spot.name.contains(searchText)) &&
            (selectedCategory == nil || spot.category == selectedCategory)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                CarouselView(images: sampleSpots.map { $0.imageName })
                
                Picker("分類", selection: $selectedCategory) {
                    Text("全部").tag(Category?.none)
                    ForEach(Category.allCases) { category in
                        Text(category.rawValue).tag(Category?.some(category))
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                List(filteredSpots) { spot in
                    NavigationLink(destination: DetailView(spot: spot)) {
                        VStack(alignment: .leading) {
                            Text(spot.name).font(.headline)
                            Text(spot.description).font(.subheadline)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("旅遊景點推薦")
        }
    }
}

// MARK: - 詳情頁（地圖 + 收藏）
struct DetailView: View {
    let spot: TouristSpot
    @EnvironmentObject var favorites: FavoritesManager
    
    var body: some View {
        ScrollView {
            Image(spot.imageName)
                .resizable()
                .scaledToFit()
            
            VStack(alignment: .leading, spacing: 16) {
                Text(spot.name).font(.largeTitle).bold()
                Text(spot.description)
                
                Map(coordinateRegion: .constant(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                ))
                .frame(height: 200)
                
                Button {
                    favorites.toggle(spot)
                } label: {
                    Label(favorites.isFavorite(spot) ? "取消收藏" : "加入收藏", systemImage: favorites.isFavorite(spot) ? "heart.fill" : "heart")
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

// MARK: - 收藏頁
struct FavoritesView: View {
    @EnvironmentObject var favorites: FavoritesManager
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(favorites.favorites) { spot in
                    NavigationLink(destination: DetailView(spot: spot)) {
                        Text(spot.name)
                    }
                }
            }
            .navigationTitle("我的收藏")
        }
    }
}

// MARK: - 地圖總覽
struct AllSpotsMapView: View {
    var body: some View {
        NavigationStack {
            Map {
                ForEach(sampleSpots) { spot in
                    Marker(spot.name, coordinate: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude))
                }
            }
            .navigationTitle("地圖總覽")
            .ignoresSafeArea()
        }
    }
}

// MARK: - 分頁畫面
struct MainTabView: View {
    @StateObject private var favorites = FavoritesManager()
    
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("景點", systemImage: "map")
                }
            
            FavoritesView()
                .tabItem {
                    Label("收藏", systemImage: "heart.fill")
                }
            
            AllSpotsMapView()
                .tabItem {
                    Label("地圖", systemImage: "location.fill")
                }
        }
        .environmentObject(favorites)
    }
}

// MARK: - 預覽
#Preview {
    MainTabView()
}
