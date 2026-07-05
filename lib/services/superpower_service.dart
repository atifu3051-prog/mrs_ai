import 'dart:math';

class SuperpowerService {
  /// Simulates fetching live weather data for a given location.
  static Future<String> fetchLiveWeather(String location) async {
    final cleanLoc = location.trim().isEmpty ? "Mumbai" : location.trim();
    // Simulate API fetch delay
    await Future.delayed(const Duration(milliseconds: 600));

    final random = Random();
    final temp = 22 + random.nextInt(15); // Random temperature between 22 and 37°C
    final humidity = 50 + random.nextInt(40);
    final conditions = ["Scattered Clouds", "Heavy Rain", "Clear Sky", "Humid", "Thunderstorm"];
    final condition = conditions[random.nextInt(conditions.length)];

    return "Live Weather Data -> Location: $cleanLoc. Temperature: ${temp}°C. Humidity: $humidity%. Condition: $condition. Wind Speed: 14 km/h. Timestamp: ${DateTime.now().toLocal()}.";
  }

  /// Simulates fetching latest news bulletins.
  static Future<String> fetchLatestNews() async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    return "Latest News Bulletins -> "
        "1. MRS AI core systems receive Phase 6 pipeline updates successfully. "
        "2. Tech industry registers 15% increase in native mobile device automation integrations. "
        "3. Local weather grids predict unpredictable rain patterns across coastal regions. "
        "Data compiled from global neural indexes.";
  }

  /// Simulates performing a live search index query.
  static Future<String> performWebSearch(String query) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return "Google Search Scrape Results for query '$query' -> "
        "Scraped snippet: '$query refers to an active command entity currently monitored under Boss protocols. "
        "Records indicate active system calibrations are ongoing.' "
        "Index Source: Wikipedia & Global Tech database.";
  }
}
