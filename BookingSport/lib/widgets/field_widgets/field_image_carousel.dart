// lib/widgets/field_widgets/field_image_carousel.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs; // Sử dụng alias

class FieldImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  const FieldImageCarousel({super.key, required this.imageUrls});

  @override
  State<FieldImageCarousel> createState() => _FieldImageCarouselState();
}

class _FieldImageCarouselState extends State<FieldImageCarousel> {
  int _current = 0;
  // Sử dụng alias khi khai báo và khởi tạo Controller
  final cs.CarouselController _controller = cs.CarouselController();

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey,
        child: const Icon(Icons.sports, size: 100, color: Colors.white54),
      );
    }
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Sử dụng alias khi dùng CarouselSlider
        cs.CarouselSlider(
          items:
              widget.imageUrls.map((url) {
                return Builder(
                  builder: (BuildContext context) {
                    return Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image),
                          ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }).toList(),
          carouselController:
              _controller, // _controller đã là kiểu cs.CarouselController
          // Sử dụng alias khi dùng CarouselOptions
          options: cs.CarouselOptions(
            height: 250,
            autoPlay: widget.imageUrls.length > 1,
            enlargeCenterPage: false,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            },
          ),
        ),
        if (widget.imageUrls.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                widget.imageUrls.asMap().entries.map((entry) {
                  return GestureDetector(
                    onTap: () => _controller.animateToPage(entry.key),
                    child: Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 4.0,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Sửa lỗi deprecated withOpacity (nếu vẫn còn)
                        color: (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black)
                            .withAlpha(
                              (255 * (_current == entry.key ? 0.9 : 0.4))
                                  .round(),
                            ),
                      ),
                    ),
                  );
                }).toList(),
          ),
      ],
    );
  }
}
