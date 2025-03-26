// screen/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../provider/font_size_provider.dart';
import 'calendar_screen.dart';
import 'ocr_medicine_scanner.dart';
import 'setting_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontSizeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.teal.shade50,
          appBar: AppBar(
            backgroundColor: Colors.teal.shade600,
            title: Text(
              "Baramed",
              style: GoogleFonts.poppins(
                fontSize: fontSizeProvider.fontSize ?? 16,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          drawer: _buildDrawer(context, fontSizeProvider),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _welcomeCard(fontSizeProvider),
                const SizedBox(height: 20),
                Text(
                  "Schedule",
                  style: GoogleFonts.poppins(
                    fontSize: fontSizeProvider.fontSize ?? 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                _scheduleCard(fontSizeProvider),
              ],
            ),
          ),

          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OcrMedicineScanner(),
                ),
              );
            },
            backgroundColor: Colors.teal.shade700,
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              size: 30,
              color: Colors.white,
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.home),
                    onPressed: () {}, // Huwag i-push muli ang HomeScreen
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CalendarScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 40), // Para sa FloatingActionButton
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(icon: const Icon(Icons.person), onPressed: () {}),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, FontSizeProvider fontSizeProvider) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade700, Colors.teal.shade400],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 35,
                  child: Icon(Icons.person, size: 40, color: Colors.teal),
                ),
                const SizedBox(height: 12),
                Text(
                  "Welcome, Kevin!",
                  style: GoogleFonts.poppins(
                    fontSize: fontSizeProvider.fontSize ?? 16,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          _drawerItem(Icons.home, "Home", () {}, fontSizeProvider),
          _drawerItem(Icons.calendar_today, "Calendar", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CalendarScreen()),
            );
          }, fontSizeProvider),
          _drawerItem(Icons.message, "Messages", () {}, fontSizeProvider),
          _drawerItem(Icons.person, "Profile", () {}, fontSizeProvider),
          _drawerItem(Icons.settings, "Settings", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          }, fontSizeProvider),
        ],
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title,
    VoidCallback onTap,
    FontSizeProvider fontSizeProvider,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal.shade600),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: fontSizeProvider.fontSize ?? 16),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      onTap: onTap,
    );
  }

  Widget _welcomeCard(FontSizeProvider fontSizeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade500, Colors.teal.shade300],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            radius: 35,
            child: Icon(Icons.person, size: 40, color: Colors.teal),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: fontSizeProvider.fontSize ?? 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  "Kevin Gamaro",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: (fontSizeProvider.fontSize ?? 16) + 2,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleCard(FontSizeProvider fontSizeProvider) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Schedule",
              style: GoogleFonts.poppins(
                fontSize: fontSizeProvider.fontSize ?? 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 10),
            Text(
              "No upcoming schedules",
              style: GoogleFonts.poppins(
                fontSize: (fontSizeProvider.fontSize ?? 16) - 2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
