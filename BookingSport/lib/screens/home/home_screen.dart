import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Để lấy thông tin user nếu cần
import '../field/field_list_screen.dart';    // Màn hình danh sách sân (tab chính)
import '../booking/booking_history_screen.dart'; // Màn hình lịch sử đặt sân
import '../profile/favorite_fields_screen.dart'; // Màn hình sân yêu thích
import '../profile/profile_screen.dart';      // Màn hình tài khoản

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0; // Index của tab đang được chọn

  // Danh sách các widget cho từng tab
  static const List<Widget> _widgetOptions = <Widget>[
    FieldListScreen(),      // Tab 0: Danh sách sân
    BookingHistoryScreen(), // Tab 1: Đặt sân của tôi
    FavoriteFieldsScreen(), // Tab 2: Yêu thích
    ProfileScreen(),        // Tab 3: Tài khoản
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // final user = ref.watch(authStateChangesProvider).value; // Lấy thông tin user nếu cần hiển thị gì đó ở AppBar

    return Scaffold(
      // AppBar có thể thay đổi tùy theo tab được chọn, hoặc là một AppBar chung
      // Ví dụ AppBar chung:
      // appBar: AppBar(
      //   title: Text('Xin chào, ${user?.fullName ?? "Bạn"}!'), // Ví dụ chào user
      //   actions: [
      //     IconButton(
      //       icon: Icon(Icons.notifications_none),
      //       onPressed: () {
      //         // Điều hướng đến màn hình thông báo
      //         // Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotificationListScreen()));
      //       },
      //     ),
      //   ],
      // ),

      // Nội dung chính sẽ là widget tương ứng với tab được chọn
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

      // Thanh điều hướng dưới
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Đặt sân',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Yêu thích',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor, // Màu của item được chọn
        unselectedItemColor: Colors.grey, // Màu của item chưa được chọn
        showUnselectedLabels: true, // Hiển thị label cho item chưa được chọn
        type: BottomNavigationBarType.fixed, // Giữ các item cố định, không bị hiệu ứng shifting
        onTap: _onItemTapped,
      ),
    );
  }
}