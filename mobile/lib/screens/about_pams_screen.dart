import 'package:flutter/material.dart';

class AboutPamsScreen extends StatelessWidget {
  const AboutPamsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PAMSについて',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    Icons.info_outline,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'PAMSについて',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            _AboutSection(
              title: 'PAMS Companionとは',
              children: [
                Text(
                  'PAMS Companionは、'
                  'あなたの記憶やAIとの対話を残し、'
                  'そこから生まれた「知」を'
                  '育てていくためのアプリです。',
                ),
                SizedBox(height: 12),
                Text(
                  'AIとの対話は、そのままにしておくと、'
                  '過去の会話に埋もれていきます。',
                ),
                SizedBox(height: 12),
                Text(
                  'PAMSでは、まず残し、'
                  'あとから振り返り、'
                  '自分にとって大切なものを'
                  '知として育てていきます。',
                ),
                SizedBox(height: 12),
                Text(
                  '何を残し、何を大切にするかを'
                  '決めるのは、AIではなく'
                  'あなた自身です。',
                ),
              ],
            ),

            SizedBox(height: 20),

            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.eco_outlined,
                      size: 36,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'まず残す。あとから育てる。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            _AboutSection(
              title: 'PAMSの使い方',
              children: [
                _AboutFeature(
                  icon: Icons.today_outlined,
                  title: '今日の記憶',
                  description:
                      '今日の出来事や考えを残します。',
                ),
                SizedBox(height: 16),
                _AboutFeature(
                  icon: Icons.chat_bubble_outline,
                  title: 'AIと考える',
                  description:
                      'AIとの新しい対話を始めます。',
                ),
                SizedBox(height: 16),
                _AboutFeature(
                  icon: Icons.eco_outlined,
                  title: '知を育てる',
                  description:
                      '残した対話から、自分の知を育てます。',
                ),
                SizedBox(height: 16),
                _AboutFeature(
                  icon: Icons.folder_outlined,
                  title: 'テーマ',
                  description:
                      '知や対話を、自分なりに整理します。',
                ),
              ],
            ),

            SizedBox(height: 20),

            _AboutSection(
              title: 'PAMSが大切にしていること',
              children: [
                Text(
                  '記憶と知の主体は、あなたです。',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'AIは、考えたり、整理したり、'
                  '新しい問いを見つけたりすることを'
                  '助けます。',
                ),
                SizedBox(height: 12),
                Text(
                  'しかし、何を大切にするかを'
                  '決めるのは、あなた自身です。',
                ),
                SizedBox(height: 12),
                Text(
                  'PAMSは、AIにあなたを'
                  '覚えてもらうためではなく、'
                  'あなた自身が自分の記憶と知を'
                  '持ち続けるための仕組みを'
                  '目指しています。',
                ),
              ],
            ),

            SizedBox(height: 20),

            _AboutSection(
              title: 'あなたのデータについて',
              children: [
                Text(
                  'PAMS Companionの記録は、'
                  '原則としてあなたの端末の中に'
                  '保存します。',
                ),
                SizedBox(height: 12),
                Text(
                  'あなたの記憶を、'
                  '特定のAIサービスだけに'
                  '預けることを前提としません。',
                ),
                SizedBox(height: 12),
                Text(
                  '将来AIサービスや端末が変わっても、'
                  '自分の記憶と知を'
                  '自分で持ち続けられることを'
                  '大切にします。',
                ),
              ],
            ),

            SizedBox(height: 20),

            _AboutSection(
              title: 'PAMSの理念',
              children: [
                Text(
                  'PAMSは、人・AI・知識を「結び」、'
                  'その知識を人生に「利かせる」ための'
                  'プラットフォームです。',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.6,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            _AboutSection(
              title: 'このアプリについて',
              children: [
                _AboutInfoRow(
                  label: 'アプリ名',
                  value: 'PAMS Companion',
                ),
                Divider(height: 28),
                _AboutInfoRow(
                  label: 'Version',
                  value: '1.0.0',
                ),
              ],
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _AboutFeature extends StatelessWidget {
  const _AboutFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 26,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutInfoRow extends StatelessWidget {
  const _AboutInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
          ),
        ),
      ],
    );
  }
}
