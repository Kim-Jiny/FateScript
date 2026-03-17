import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/birth_info_provider.dart';
import '../providers/ticket_provider.dart';
import 'input_screen.dart';
import 'login_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isLoggedIn) {
      return _notLoggedIn(context);
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('마이페이지',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _profileSection(context, authProvider),
              const SizedBox(height: 20),
              _ticketSection(context),
              const SizedBox(height: 20),
              _sajuInfoSection(context),
              const SizedBox(height: 20),
              _settingsSection(context, authProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notLoggedIn(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline,
                size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            const Text(
              '로그인이 필요합니다',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 8),
            const Text(
              '로그인하면 사주 티켓을 관리하고\n운세를 이용할 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8A4FFF),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('로그인하기'),
            ),
          ],
        ),
      ),
    );
  }

  // ── 프로필 섹션 ──

  Widget _profileSection(BuildContext context, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                const Color(0xFF8A4FFF).withValues(alpha: 0.12),
            backgroundImage: authProvider.photoUrl != null
                ? NetworkImage(authProvider.photoUrl!)
                : null,
            child: authProvider.photoUrl == null
                ? const Icon(Icons.person,
                    size: 28, color: Color(0xFF8A4FFF))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.displayName ?? '사용자',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (authProvider.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    authProvider.email!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 티켓 섹션 ──

  Widget _ticketSection(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();
    final balance = ticketProvider.balance;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number,
                  color: Color(0xFF8A4FFF), size: 20),
              const SizedBox(width: 8),
              const Text(
                '사주 티켓',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8A4FFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  balance != null ? '$balance장' : '...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A4FFF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '운세를 볼 때마다 티켓 1장이 소모됩니다.',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
          if (ticketProvider.error != null) ...[
            const SizedBox(height: 8),
            Text(
              ticketProvider.error!,
              style: const TextStyle(color: Colors.red, fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),
          if (ticketProvider.products.isEmpty && !ticketProvider.productsLoaded)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Row(
              children: ticketProvider.products.map((product) {
                final storeProduct =
                    ticketProvider.iapService.products[product.productId];
                final price = storeProduct?.price ??
                    (product.priceKrw > 0
                        ? '₩${product.priceKrw.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'
                        : '---');
                final isFirst = product == ticketProvider.products.first;
                final isLast = product == ticketProvider.products.last;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isFirst ? 0 : 4,
                      right: isLast ? 0 : 4,
                    ),
                    child: _purchaseButton(
                      context,
                      label: product.label,
                      price: price,
                      onTap: ticketProvider.isPurchasing
                          ? null
                          : () => ticketProvider.buyProduct(product.productId),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _purchaseButton(
    BuildContext context, {
    required String label,
    required String price,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF8A4FFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              price,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 사주 정보 섹션 ──

  Widget _sajuInfoSection(BuildContext context) {
    final birthProvider = context.watch<BirthInfoProvider>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: Color(0xFF8A4FFF), size: 20),
              const SizedBox(width: 8),
              const Text(
                '사주 정보',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InputScreen()),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A4FFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    birthProvider.hasBirthInfo ? '수정' : '입력',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A4FFF),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (birthProvider.hasBirthInfo) ...[
            _infoRow('생년월일', birthProvider.birthInfo!.birthDate),
            const SizedBox(height: 6),
            _infoRow(
              '태어난 시간',
              birthProvider.birthInfo!.hasTime
                  ? birthProvider.birthInfo!.birthTime!
                  : '미상',
            ),
            const SizedBox(height: 6),
            _infoRow(
              '성별',
              birthProvider.birthInfo!.gender == 'male' ? '남성' : '여성',
            ),
          ] else
            const Text(
              '사주 정보를 입력해 주세요.',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  // ── 설정 섹션 ──

  Widget _settingsSection(BuildContext context, AuthProvider authProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _settingsTile(
            icon: Icons.logout,
            iconColor: const Color(0xFF6B7280),
            title: '로그아웃',
            onTap: () => _confirmLogout(context, authProvider),
          ),
          const Divider(height: 1, indent: 52),
          _settingsTile(
            icon: Icons.delete_outline,
            iconColor: Colors.red,
            title: '회원탈퇴',
            titleColor: Colors.red,
            onTap: () => _confirmDeleteAccount(context, authProvider),
          ),
          const Divider(height: 1, indent: 52),
          _settingsTile(
            icon: Icons.mail_outline,
            iconColor: const Color(0xFF6B7280),
            title: '문의하기',
            subtitle: 'kjinyz@naver.com',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? const Color(0xFF1F2937),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    final ticketProvider =
        Provider.of<TicketProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              authProvider.signOut();
              ticketProvider.clearBalance();
              Navigator.of(ctx).pop();
            },
            child:
                const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(
      BuildContext context, AuthProvider authProvider) {
    final ticketProvider =
        Provider.of<TicketProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원탈퇴'),
        content: const Text(
          '탈퇴하면 저장된 모든 데이터(사주 정보, 티켓, 궁합 기록 등)가 삭제되며 복구할 수 없습니다.\n\n정말 탈퇴하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await authProvider.deleteAccount();
              if (context.mounted) {
                if (success) {
                  ticketProvider.clearBalance();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('회원탈퇴가 완료되었습니다.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          authProvider.error ?? '회원탈퇴 중 오류가 발생했습니다.'),
                    ),
                  );
                }
              }
            },
            child: const Text('탈퇴하기',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
