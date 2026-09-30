import 'package:flutter/material.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ketentuan Aplikasi'),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Syarat & Ketentuan Penggunaan',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Terakhir diperbarui: 1 Oktober 2026',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Penerimaan Syarat',
              body: 'Dengan mengakses dan menggunakan aplikasi Nyimpeun, Anda menyetujui untuk terikat oleh Syarat dan Ketentuan ini. Jika Anda tidak setuju dengan bagian mana pun dari ketentuan ini, Anda tidak diperkenankan menggunakan aplikasi kami.',
            ),
            _buildSection(
              title: '2. Layanan Aplikasi',
              body: 'Nyimpeun menyediakan layanan pencatatan keuangan pribadi. Segala bentuk keputusan finansial, perencanaan keuangan, atau investasi yang Anda lakukan berdasarkan data di dalam aplikasi adalah murni tanggung jawab Anda sendiri. Kami tidak menjamin keakuratan absolut dan tidak bertanggung jawab atas kerugian finansial apa pun.',
            ),
            _buildSection(
              title: '3. Privasi & Keamanan Data (Privacy Policy)',
              body: 'Kami menghargai privasi Anda. Data keuangan Anda disimpan secara aman menggunakan enkripsi (melalui penyedia layanan cloud standar industri). Kami tidak akan pernah menjual, membagikan, atau mengekspos data pribadi Anda kepada pihak ketiga tanpa izin eksplisit dari Anda, kecuali diwajibkan oleh hukum yang berlaku.',
            ),
            _buildSection(
              title: '4. Akun Pengguna',
              body: 'Anda bertanggung jawab penuh untuk menjaga kerahasiaan kata sandi dan PIN keamanan akun Anda. Segala aktivitas yang terjadi di bawah akun Anda adalah tanggung jawab Anda. Segera hubungi tim dukungan jika Anda mencurigai adanya pelanggaran keamanan pada akun Anda.',
            ),
            _buildSection(
              title: '5. Batasan Tanggung Jawab',
              body: 'Aplikasi ini disediakan "sebagaimana adanya" (as is) tanpa jaminan apa pun, baik tersurat maupun tersirat. Pengembang Nyimpeun tidak bertanggung jawab atas kerusakan langsung, tidak langsung, insidental, atau konsekuensial yang timbul dari penggunaan atau ketidakmampuan menggunakan aplikasi ini.',
            ),
            _buildSection(
              title: '6. Perubahan Ketentuan',
              body: 'Kami berhak untuk mengubah atau mengganti Syarat dan Ketentuan ini kapan saja tanpa pemberitahuan sebelumnya. Kebijakan versi terbaru akan selalu tersedia di halaman ini. Penggunaan berkelanjutan Anda atas aplikasi setelah adanya perubahan merupakan penerimaan Anda terhadap syarat baru tersebut.',
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                '© 2026 Nyimpeun App. All rights reserved.',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTypography.bodyMedium.copyWith(
              color: const Color(0xFF4B5563),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
