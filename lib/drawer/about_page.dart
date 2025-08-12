import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ✅ 圓形大頭照區塊
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: Image.asset(
              'assets/images/204156154.jpg',
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ✅ 系統標題區塊
        const Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "大家好，我是jimmy Lee",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ✅ 開發團隊
        const Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "👨‍💻 開發者：\n- Pin-Fan Lee\n- Flutter 支援者",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ✅ 用途說明
        const Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "📌 用途：\n本系統協助模擬聯合國會議進行點名、發言、投票等流程，"
              "讓每場會議更有效率與互動性。",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ✅ 留言卡片
        const Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "💬 留給大家的話：\n秉持著推廣模聯的目標，本App將永遠開源，希望大家使用順利，若有能夠改善的地方也都歡迎聯絡我的email",
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ✅ 聯絡方式
        const Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "📧 聯絡方式：",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text("jimmylee16888@gmail.com", style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
