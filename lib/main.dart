import 'package:flutter/material.dart';
import 'dart:ui';
import 'api_service.dart';

void main() {
  runApp(const HardwareDashboardApp());
}

class HardwareDashboardApp extends StatefulWidget {
  const HardwareDashboardApp({super.key});

  @override
  State<HardwareDashboardApp> createState() => _HardwareDashboardAppState();
}

class _HardwareDashboardAppState extends State<HardwareDashboardApp> {
  bool isDarkMode = true;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Device Dashboard',
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: DashboardScreen(
        isDarkMode: isDarkMode,
        onThemeToggle: toggleTheme,
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const DashboardScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _backendUrlController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool isConnected = false;
  bool isConnecting = false;
  bool isRefreshing = false;

  List<String> recentUrls = [];

  String temperature = "--";
  String humidity = "--";
  String lightIntensity = "--";
  String lastSyncTime = "--";

  Future<void> fetchLatestData({bool isRefresh = false}) async {
 String formattedUrl = _backendUrlController.text.trim();
    if (formattedUrl.isEmpty) return;

    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'http://$formattedUrl';
    }
    if (formattedUrl.split(':').length == 2) {
      formattedUrl = '$formattedUrl:8000';
    }

    // Turn on the CORRECT spinner
    setState(() {
      if (isRefresh) {
        isRefreshing = true;
      } else {
        isConnecting = true;
      }
    });

    final data = await _apiService.fetchLatestData(formattedUrl);

    if (data != null && data.containsKey('temperature')) {
      setState(() {
        isConnected = true;
        temperature = "${data['temperature']}°C";
        humidity = "${data['humidity']}%";
        lightIntensity = "${data['light']} lux";
        lastSyncTime = data['timestamp'] != null ? data['timestamp'].toString() : "--";
        
        // (Your history chip saving logic stays here!)
        if (!recentUrls.contains(formattedUrl)) {
          recentUrls.insert(0, formattedUrl);
          if (recentUrls.length > 3) {
            recentUrls.removeLast(); 
          }
        }
      });
    } else {
      setState(() {
        isConnected = false;
      });
    }

    // Turn off the CORRECT spinner
    setState(() {
      if (isRefresh) {
        isRefreshing = false;
      } else {
        isConnecting = false;
      }
    });
  }

  Future<void> connectToBackend() async {
    // This strictly tells it NOT to use the refresh spinner
    await fetchLatestData(isRefresh: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isDarkMode
                ? const [Color(0xFF1A1A2E), Color(0xFF121212)]
                : const [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Expanded(
                      child: Text(
                        'Device Dashboard',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),),
                      GestureDetector(
                        onTap: widget.onThemeToggle,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          width: 70,
                          height: 36,
                          padding: const EdgeInsets.all(4),
                          alignment: widget.isDarkMode
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: widget.isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                          ),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Icon(
                              widget.isDarkMode
                                  ? Icons.nightlight_round
                                  : Icons.wb_sunny_rounded,
                              size: 16,
                              color: widget.isDarkMode
                                  ? Colors.indigo.shade900
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.1),
                            ),
                          ),
                          child: TextField(
                            controller: _backendUrlController,
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter ESP32/FastAPI URL...',
                              hintStyle: TextStyle(
                                color: widget.isDarkMode
                                    ? Colors.white38
                                    : Colors.black38,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: isConnecting ? null : connectToBackend,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode
                                ? Colors.indigoAccent
                                : Colors.blueAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: isConnecting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Connect',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),


                  if (recentUrls.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36, // Height of the horizontal scroll area
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: recentUrls.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final url = recentUrls[index];
                          return GestureDetector(
                            onTap: () {
                              // When tapped, fill the text box!
                              setState(() {
                                _backendUrlController.text = url;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: widget.isDarkMode 
                                    ? Colors.white.withOpacity(0.05) 
                                    : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20), // Pill shape
                                border: Border.all(
                                  color: widget.isDarkMode 
                                      ? Colors.white.withOpacity(0.1) 
                                      : Colors.black.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.history, 
                                    size: 16, 
                                    color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    url.replaceAll('http://', ''), // Hide the ugly http:// for a cleaner look
                                    style: TextStyle(
                                      fontSize: 13, 
                                      color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isConnected
                            ? 'Status: Connected 🟢'
                            : 'Status: Disconnected 🔴',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isConnected
                              ? (widget.isDarkMode
                                  ? Colors.greenAccent
                                  : Colors.green.shade700)
                              : (widget.isDarkMode
                                  ? Colors.redAccent
                                  : Colors.red.shade700),
                        ),
                      ),
                      if (isConnected)
                        GestureDetector(
                          onTap: isConnecting ? null : fetchLatestData,
                          child: Icon(
                            Icons.refresh,
                            color: isConnecting
                                ? Colors.grey
                                : (widget.isDarkMode
                                    ? Colors.white70
                                    : Colors.black54),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
       if (isConnected) ...[
                    // 1. The Top Banner Card (Full Width)
                    SyncTimeCard(
                      value: lastSyncTime,
                      isDarkMode: widget.isDarkMode,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 2. The Middle Row (Temperature & Humidity)
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Temperature',
                            value: temperature,
                            icon: Icons.thermostat,
                            color: Colors.orangeAccent,
                            isDarkMode: widget.isDarkMode,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            title: 'Humidity',
                            value: humidity,
                            icon: Icons.water_drop,
                            color: Colors.lightBlueAccent,
                            isDarkMode: widget.isDarkMode,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 3. The Bottom Row (Light)
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Light',
                            value: lightIntensity,
                            icon: Icons.lightbulb,
                            color: const Color.fromARGB(255, 255, 255, 0),
                            isDarkMode: widget.isDarkMode,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // CRITICAL: We use a blank Expanded widget here!
                        // This forces the Light card to stay exactly 50% width and remain a square tile.
                        const Expanded(child: SizedBox()), 
                      ],
                    ),
                  ] else ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60.0),
                        child: Text(
                          'Waiting for connection...\nEnter your backend URL above.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                      ],
                  ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDarkMode;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 36,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class SyncTimeCard extends StatelessWidget {
  final String value;
  final bool isDarkMode;

  const SyncTimeCard({
    super.key,
    required this.value,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity, // Forces it to take up the full screen width
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
          ),
          // A horizontal Row layout instead of a vertical Column
          child: Row(
            children: [
              // A nice glowing background for the icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.access_time_filled, color: Colors.purpleAccent, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Last Synced',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white54 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 18, // Perfectly sized for long date strings
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}