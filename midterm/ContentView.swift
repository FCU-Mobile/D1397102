import SwiftUI
import MapKit

// MARK: - 模型與分類
enum Category: String, CaseIterable, Identifiable {
    case nature = "category_nature"
    case landmark_building = "category_landmark_building"
    case history = "category_history"
    case religion = "category_religion"
    
    var id: String { rawValue }
    var localized: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

struct TouristSpot: Identifiable, Equatable {
    let id = UUID()
    let nameKey: String
    let descriptionKey: String
    let imageName: String
    let latitude: Double
    let longitude: Double
    let category: Category
    
    var name: LocalizedStringKey { LocalizedStringKey(nameKey) }
    var description: LocalizedStringKey { LocalizedStringKey(descriptionKey) }
}

// MARK: - 假資料
let sampleSpots = [
    TouristSpot(nameKey: "spot_taipei101_name", descriptionKey: "spot_taipei101_desc", imageName: "taipei101", latitude: 25.0330, longitude: 121.5654, category: .landmark_building),
    TouristSpot(nameKey: "spot_85tower_name", descriptionKey: "spot_85tower_desc", imageName: "bawudalou", latitude: 22.6133, longitude: 120.3005, category: .landmark_building),
    TouristSpot(nameKey: "spot_sunmoonlake_name", descriptionKey: "spot_sunmoonlake_desc", imageName: "sunmoonlake", latitude: 23.8659, longitude: 120.9150, category: .nature),
    TouristSpot(nameKey: "spot_alishan_name", descriptionKey: "spot_alishan_desc", imageName: "alishan", latitude: 23.5083, longitude: 120.8020, category: .nature),
    TouristSpot(nameKey: "spot_foguangshan_name", descriptionKey: "spot_foguangshan_desc", imageName: "foguangshan", latitude: 22.7564, longitude: 120.4039, category: .religion),
    TouristSpot(nameKey: "spot_tudigong_name", descriptionKey: "spot_tudigong_desc", imageName: "tudigong", latitude: 25.0027, longitude: 121.5077, category: .religion),
    TouristSpot(nameKey: "spot_anping_name", descriptionKey: "spot_anping_desc", imageName: "anpinggubao", latitude: 23.0013, longitude: 120.1597, category: .history),
    TouristSpot(nameKey: "spot_tribe_name", descriptionKey: "spot_tribe_desc", imageName: "tribe", latitude: 22.5370, longitude: 120.7122, category: .history)
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
    @Published var locale: Locale = Locale.current
    
    init() {
        if let saved = UserDefaults.standard.string(forKey: "AppLanguage") {
            selectedLanguage = saved
            locale = Locale(identifier: saved)
            UserDefaults.standard.set([saved], forKey: "AppleLanguages")
        }
    }
    
    func setLanguage(_ lang: String) {
        selectedLanguage = lang
        locale = Locale(identifier: lang)
        UserDefaults.standard.set([lang], forKey: "AppleLanguages")
        UserDefaults.standard.set(lang, forKey: "AppLanguage")
        UserDefaults.standard.synchronize()
        
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
            (searchText.isEmpty || spot.nameKey.contains(searchText)) &&
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
    
    @State private var region: MKCoordinateRegion

    init(spot: TouristSpot) {
        self.spot = spot
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        ScrollView {
            Image(spot.imageName)
                .resizable()
                .scaledToFit()
            
            VStack(alignment: .leading, spacing: 16) {
                Text(spot.name).font(.largeTitle).bold()
                Text(spot.description)
                
                Map(coordinateRegion: $region)
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
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.7, longitude: 121.0), // 台灣中部
        span: MKCoordinateSpan(latitudeDelta: 2.5, longitudeDelta: 2.5)   // 顯示全台
    )
    
    var body: some View {
        NavigationStack {
            Map(coordinateRegion: $region, annotationItems: sampleSpots) { spot in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)) {
                    VStack(spacing: 0) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .font(.title)
                        
                        Text(spot.name)
                            .font(.caption)
                            .fixedSize()
                            .padding(4)
                            .background(Color.white.opacity(0.7))
                            .cornerRadius(5)
                    }
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
                    Label("tourism_title", systemImage: "map")
                }
            
            FavoritesView()
                .tabItem {
                    Label("favorites_title", systemImage: "heart.fill")
                }
            
            AllSpotsMapView()
                .tabItem {
                    Label("map_title", systemImage: "location.fill")
                }
            
            NavigationStack {
                LanguageSettingsView()
            }
            .tabItem {
                Label("language_settings", systemImage: "gear")
            }
        }
        .environmentObject(favorites)
        .environmentObject(langManager)
        .environment(\.locale, langManager.locale)
    }
}

// MARK: - 預覽
#Preview {
    MainTabView()
}



