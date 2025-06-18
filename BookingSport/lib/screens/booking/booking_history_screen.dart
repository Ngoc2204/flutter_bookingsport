import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_providers.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_list_placeholder.dart';
import '../../widgets/booking_widgets/booking_card.dart';
import '../review/review_form_screen.dart';
// import '../review/review_form_screen.dart'; // Bỏ comment khi bạn tạo màn hình này
// import 'booking_detail_screen.dart'; // Bỏ comment khi bạn tạo màn hình này


class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  // Danh sách các trạng thái gốc để tạo tab
  final List<BookingStatus> _allPossibleTabStatuses = [
    BookingStatus.unknown,        // Tab "Tất cả"
    BookingStatus.pending,
    BookingStatus.confirmed,
    BookingStatus.completed,
    BookingStatus.cancelledByUser, // Sẽ đại diện cho tab "Đã hủy" gộp
    // BookingStatus.cancelledByAdmin, // Sẽ được gộp vào cancelledByUser
    // Thêm BookingStatus.noShow, BookingStatus.expired nếu bạn muốn có tab riêng
  ];

  // Danh sách các BookingStatus sẽ thực sự được dùng để tạo tab và view
  late List<BookingStatus> _displayedTabFilters;
  // Danh sách các Widget Tab sẽ được hiển thị
  late List<Widget> _actualTabs;

  @override
  void initState() {
    super.initState();
    _prepareTabs(); // Chuẩn bị danh sách tab và filter
    _tabController = TabController(length: _actualTabs.length, vsync: this);
  }

  void _prepareTabs() {
    _displayedTabFilters = [];
    _actualTabs = [];

    // Xử lý logic gộp tab "Đã hủy"
    // Chúng ta sẽ chỉ có một tab "Đã hủy" đại diện cho cả cancelledByUser và cancelledByAdmin
    for (var status in _allPossibleTabStatuses) {
      // Nếu bạn muốn gộp cancelledByAdmin vào cancelledByUser, thì không thêm cancelledByAdmin vào _displayedTabFilters nữa
      // Hiện tại, _allPossibleTabStatuses đã loại bỏ cancelledByAdmin,
      // và logic filter trong TabBarView sẽ xử lý việc gộp này.
      // Để đơn giản, chúng ta sẽ tạo tab cho mỗi status trong _allPossibleTabStatuses đã được định nghĩa.
      // Nếu _allPossibleTabStatuses không chứa cancelledByAdmin, thì không cần logic gộp phức tạp ở đây.

      // Nếu bạn vẫn muốn logic gộp như code cũ:
      // if (status == BookingStatus.cancelledByUser || status == BookingStatus.cancelledByAdmin) {
      //   if (!_displayedTabFilters.any((s) => s == BookingStatus.cancelledByUser || s == BookingStatus.cancelledByAdmin)) {
      //     _displayedTabFilters.add(BookingStatus.cancelledByUser); // Dùng cancelledByUser làm đại diện
      //     _actualTabs.add(Tab(text: _getTabLabel(BookingStatus.cancelledByUser)));
      //   }
      // } else {
      //   _displayedTabFilters.add(status);
      //   _actualTabs.add(Tab(text: _getTabLabel(status)));
      // }

      // Cách làm đơn giản hơn: _allPossibleTabStatuses đã được định nghĩa để không có trùng lặp tab gộp.
      // Logic gộp sẽ nằm ở phần filter data cho TabBarView.
      _displayedTabFilters.add(status);
      _actualTabs.add(Tab(text: _getTabLabel(status)));
    }
    // Nếu bạn muốn đảm bảo tab "Đã hủy" là duy nhất nếu có cả cancelledByUser và cancelledByAdmin trong _allPossibleTabStatuses:
    // Ví dụ:
    // Set<String> addedLabels = {};
    // _actualTabs = [];
    // _displayedTabFilters = [];
    // for (var status in _allPossibleTabStatuses) {
    //   String label = _getTabLabel(status);
    //   if (!addedLabels.contains(label)) {
    //     _actualTabs.add(Tab(text: label));
    //     _displayedTabFilters.add(status); // Dùng status đầu tiên có label đó làm filter
    //     addedLabels.add(label);
    //   }
    // }
  }


  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  String _getTabLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending: return 'Chờ xử lý';
      case BookingStatus.confirmed: return 'Sắp tới';
      case BookingStatus.completed: return 'Đã hoàn thành';
      case BookingStatus.cancelledByUser: // Đây sẽ là label cho tab "Đã hủy"
      case BookingStatus.cancelledByAdmin: // Gộp chung vào đây
        return 'Đã hủy';
      case BookingStatus.noShow: return 'Không đến';
      case BookingStatus.expired: return 'Hết hạn';
      case BookingStatus.unknown:
      default: return 'Tất cả';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);

    if (authState.isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

    if (authState.value == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lịch sử đặt sân')),
        body: const Center(child: Text('Vui lòng đăng nhập để xem lịch sử đặt sân.')),
      );
    }

    final userBookingsAsync = ref.watch(userBookingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đặt sân của tôi'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _actualTabs, // <<<< SỬ DỤNG DANH SÁCH TAB ĐÃ CHUẨN BỊ
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        // Tạo children cho TabBarView dựa trên _displayedTabFilters
        children: _displayedTabFilters.map((statusFilter) {
          return userBookingsAsync.when(
              data: (allBookings) {
                List<BookingModel> filteredBookings;
                if (statusFilter == BookingStatus.unknown) {
                  filteredBookings = allBookings;
                } else if (statusFilter == BookingStatus.cancelledByUser) { // Lọc cho tab "Đã hủy" gộp
                  filteredBookings = allBookings.where((b) =>
                  b.status == BookingStatus.cancelledByUser ||
                      b.status == BookingStatus.cancelledByAdmin).toList();
                } else {
                  filteredBookings = allBookings.where((b) => b.status == statusFilter).toList();
                }

                if (filteredBookings.isEmpty) {
                  return EmptyListPlaceholder(message: 'Không có đơn đặt sân nào ${_getTabLabel(statusFilter) != "Tất cả" ? "thuộc trạng thái '${_getTabLabel(statusFilter).toLowerCase()}'" : "trong lịch sử"}.');
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return BookingCard(
                        booking: booking,
                        onCancel: (booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed)
                        // && booking.startTime.toDate().isAfter(DateTime.now().add(const Duration(hours: 2))) // Điều kiện hủy
                            ? () async {
                          final confirm = await showDialog<bool>( /* ... Dialog xác nhận ... */
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Xác nhận hủy"),
                                content: const Text("Bạn có chắc muốn hủy đơn đặt sân này không?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Không")),
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Có, hủy")),
                                ],
                              ));
                          if (confirm == true && context.mounted) {
                            try {
                              await ref.read(bookingServiceProvider).cancelBookingByUser(booking.id);
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã hủy đơn đặt sân.")));
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi hủy đơn: ${e.toString().replaceFirst("Exception: ", "")}")));
                            }
                          }
                        }
                            : null,
                        onReview: (booking.status == BookingStatus.completed && !booking.isReviewed)
                            ? () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ReviewFormScreen(args: ReviewFormScreenArgs(bookingId: booking.id, fieldId: booking.fieldId, fieldName: booking.fieldName)),
                          ));
                          debugPrint("Navigate to ReviewFormScreen for booking ${booking.id}");
                        }
                            : null,
                        onTap: () {
                          // Navigator.of(context).push(MaterialPageRoute(
                          //   builder: (_) => BookingDetailScreen(bookingId: booking.id),
                          // ));
                          debugPrint("Navigate to BookingDetailScreen for booking ${booking.id}");
                        });
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (err, stack) {
                debugPrint("BookingHistoryScreen - Error loading user bookings: $err\n$stack");
                return Center(child: Text('Lỗi tải lịch sử đặt sân: ${err.toString().split("]").last.trim()}'));
              }
          );
        }).toList(),
      ),
    );
  }
}