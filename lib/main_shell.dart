import 'package:flutter/material.dart';
import 'screen/home.dart';
import 'screen/ticket.dart';
import 'screen/Notification.dart';
import 'screen/Profile.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {

  int currentIndex = 0;

  final pages = [
    HomeScreen(),
    TicketScreen(),
    NotificationScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: pages[currentIndex],

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),

        child: BottomNavigationBar(

          currentIndex: currentIndex,

          type: BottomNavigationBarType.fixed,

          selectedItemColor: Colors.blue,

          unselectedItemColor: Colors.grey,

          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },

          items: const [

            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number),
              label: "Bus",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: "Notifications",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
            ),

          ],
        ),
      ),
    );
  }
}