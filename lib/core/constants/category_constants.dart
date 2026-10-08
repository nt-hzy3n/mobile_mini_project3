import 'package:flutter/material.dart';

enum ExpenseCategory {
  food('Food', 'Ăn uống', Icons.restaurant_rounded, Color(0xFFF57C00)),
  study('Study', 'Học tập', Icons.school_rounded, Color(0xFF1976D2)),
  travel(
    'Travel',
    'Di chuyển',
    Icons.directions_car_rounded,
    Color(0xFF388E3C),
  ),
  gear(
    'Gear',
    'Thiết bị & Công nghệ',
    Icons.devices_rounded,
    Color(0xFF7B1FA2),
  ),
  entertainment(
    'Entertainment',
    'Giải trí',
    Icons.movie_rounded,
    Color(0xFFE91E63),
  ),
  other('Other', 'Khác', Icons.category_rounded, Color(0xFF607D8B));

  const ExpenseCategory(this.name, this.vietnameseName, this.icon, this.color);

  final String name;
  final String vietnameseName;
  final IconData icon;
  final Color color;

  static ExpenseCategory fromString(String? value) {
    if (value == null) return ExpenseCategory.other;
    return ExpenseCategory.values.firstWhere(
      (c) =>
          c.name.toLowerCase() == value.toLowerCase() ||
          c.vietnameseName.toLowerCase() == value.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }

  static ExpenseCategory suggestFromText(String text) {
    final lower = text.toLowerCase();

    // Food keywords
    if (RegExp(
      r'(coffee|cafe|cà phê|trà sữa|phúc long|highlands|starbucks|food|cơm|bún|phở|quán|nhà hàng|bánh|ăn|uống|snack|kfc|lotteria|mcdonald|jollibee|pizza|bbq|tea|bakery|market|siêu thị|mart|coop|winmart|circle k|seven eleven|7-eleven)',
    ).hasMatch(lower)) {
      return ExpenseCategory.food;
    }

    // Study keywords
    if (RegExp(
      r'(học phí|tuition|vku|đại học|university|fahasa|sách|book|course|khóa học|tiếng anh|ielts|toeic|udemy|coursera|giáo trình|văn phòng phẩm|bút|vở|thư viện)',
    ).hasMatch(lower)) {
      return ExpenseCategory.study;
    }

    // Travel keywords
    if (RegExp(
      r'(grab|be\b|gojek|xanh sm|taxi|xe buýt|bus|xăng|petro|petrolimex|vé máy bay|flight|vietjet|vietnam airlines|tàu|ga tàu|gửi xe|parking|vé xe|cầu đường|toll)',
    ).hasMatch(lower)) {
      return ExpenseCategory.travel;
    }

    // Gear keywords
    if (RegExp(
      r'(keyboard|bàn phím|mouse|chuột|laptop|máy tính|phone|tai nghe|headphone|airpods|cáp sạc|adapter|gear|fpt shop|thế giới di động|tgdd|cellphones|gearvn|hacom|ram|ssd|màn hình|monitor)',
    ).hasMatch(lower)) {
      return ExpenseCategory.gear;
    }

    // Entertainment keywords
    if (RegExp(
      r'(cgv|bhd|lotte cinema|rạp chiếu phim|cinema|movie|game|steam|playstation|netflix|spotify|youtube|karaoke|billiards|vé xem phim|du lịch|resort|hotel|khách sạn|bar|pub)',
    ).hasMatch(lower)) {
      return ExpenseCategory.entertainment;
    }

    return ExpenseCategory.other;
  }
}
