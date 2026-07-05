import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/assistant_provider.dart';
import 'screens/home_screen.dart';
import 'services/background_service.dart';

void main() async {
  // Ensure widget bindings are initialized before configuring system UI overlay styles
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize mock background wake-word service thread
  await BackgroundWakeWordService.initializeService();
  
  // Set system navigation bar and status bar colors to fit futuristic theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF06060A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AssistantProvider()),
      ],
      child: MaterialApp(
        title: 'MRS AI',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00FFF0), // Cyber Cyan
            secondary: Color(0xFFBF5AF2), // Purple Bloom
            surface: Color(0xFF08080C),
            background: Color(0xFF06060A),
            error: Color(0xFFFF453A),
          ),
          scaffoldBackgroundColor: const Color(0xFF06060A),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
