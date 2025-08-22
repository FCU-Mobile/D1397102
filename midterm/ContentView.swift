import SwiftUI
import MapKit

// MARK: - 模型與分類
enum Category: String, CaseIterable, Identifiable {
    case nature = "category_nature"
    case landmark_building = "category_landmark_building"
    case history="category_history"
    case religion="category_religion"
    var id: String { rawValue }
    var localized: LocalizedStringKey { LocalizedStringKey(rawValue) }
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
    TouristSpot(name: "台北 101", description: "北台灣知名地標，高樓觀景。", imageName: "taipei101", latitude: 25.0330, longitude: 121.5654, category: .landmark_building),
    TouristSpot(name: "高雄 85大樓", description: "南台灣知名地標，高樓觀景。", imageName: "bawudalou", latitude: 22.6133, longitude: 120.3005, category: .landmark_building),
    TouristSpot(name: "日月潭", description: "中台灣美麗湖泊，適合划船和騎腳踏車。", imageName: "sunmoonlake", latitude: 23.8659, longitude: 120.9150, category: .nature),
    TouristSpot(name: "阿里山", description: "以觀日、森林鐵道著稱的高山景點。", imageName: "alishan", latitude: 23.5083, longitude: 120.8020, category: .nature),
    TouristSpot(name: "佛光山", description: "位於高雄市的大型佛教寺院，是知名的宗教與文化景點，設有佛陀紀念館。", imageName: "foguangshan", latitude: 22.7564, longitude: 120.4039, category: .religion),
    TouristSpot(name: "烘爐地南山福德宮", description: "位於新北市中和區的著名土地公廟，以巨大金爐與台北盆地夜景聞名，是祈福與觀光的熱門地點。", imageName: "tudigong", latitude: 25.0027, longitude: 121.5077, category: .religion),
    TouristSpot(name: "安平古堡", description: "位於台南市安平區的歷史古蹟，前身為荷蘭人建造的熱蘭遮城，是台灣最具代表性的西式城堡遺址之一。", imageName: "anpinggubao", latitude: 23.0013, longitude: 120.1597, category: .history),
    TouristSpot(name: "台灣原住民文化園區", description: "位於屏東縣瑪家鄉，展示台灣多元原住民族的文化、藝術及傳統工藝，是了解原住民文化的重要場所。", imageName: "tribe", latitude: 22.5370, longitude: 120.7122, category: .history)
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

// MARK: - 語言管理器
class LanguageManager: ObservableObject {
    @Published var selectedLanguage: String = Locale.current.identifier
    
    init() {
        if let saved = UserDefaults.standard.string(forKey: "AppLanguage") {
            selectedLanguage = saved
            UserDefaults.standard.set([saved], forKey: "AppleLanguages")
        }
    }
    
    func setLanguage(_ lang: String) {
        selectedLanguage = lang
        UserDefaults.standard.set([lang], forKey: "AppleLanguages")
        UserDefaults.standard.set(lang, forKey: "AppLanguage")
        UserDefaults.standard.synchronize()
        
        // 強制刷新 UI
        UIApplication.shared.windows.first?.rootViewController =
            UIHostingController(rootView: MainTabView()
                .environmentObject(FavoritesManager())
                .environmentObject(self))
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
                    Text("category_all").tag(Category?.none)
                    ForEach(Category.allCases) { category in
                        Text(category.localized).tag(Category?.some(category))
                    }
                }
                .pickerStyle(.menu)
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
            .navigationTitle(Text("tourism_title"))
        }
    }
}

// MARK: - 詳情頁
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
                    Label(
                        favorites.isFavorite(spot) ? "remove_favorite" : "add_favorite",
                        systemImage: favorites.isFavorite(spot) ? "heart.fill" : "heart"
                    )
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
            .navigationTitle(Text("favorites_title"))
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
            .navigationTitle(Text("map_title"))
            .ignoresSafeArea()
        }
    }
}

// MARK: - 語言設定頁
struct LanguageSettingsView: View {
    @EnvironmentObject var langManager: LanguageManager
    
    var body: some View {
        List {
            Button("繁體中文") { langManager.setLanguage("zh-Hant") }
            Button("English") { langManager.setLanguage("en") }
            Button("日本語") { langManager.setLanguage("ja") }
        }
        .navigationTitle(Text("language_settings"))
    }
}

// MARK: - 分頁畫面
struct MainTabView: View {
    @StateObject private var favorites = FavoritesManager()
    @StateObject private var langManager = LanguageManager()
    
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
            
            NavigationStack {
                LanguageSettingsView()
            }
            .tabItem {
                Label("語言設定", systemImage: "gear")
            }
        }
        .environmentObject(favorites)
        .environmentObject(langManager)
    }
}

// MARK: - 預覽
#Preview {
    MainTabView()
}

