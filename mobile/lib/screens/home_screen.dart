import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/birth_info_provider.dart';
import '../providers/ticket_provider.dart';
import '../models/ticket_product.dart';
import 'input_screen.dart';
import 'inquiry_screen.dart';
import 'login_screen.dart';
import 'ticket_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final birthProvider = context.watch<BirthInfoProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'AI 사주 다이어리',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A4FFF),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _authButton(context, authProvider),
                ],
              ),
              const SizedBox(height: 28),
              Text('운명일기', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                '당신의 생년월일과 시간으로\n오늘의 운세와 감정 기록을 연결합니다.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF111827), Color(0xFF312E81)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '오늘의 흐름',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Flexible(
                        child: Text(
                          '사주를 입력하면\n운명선생이 오늘의\n흐름을 알려드립니다.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 4,
                        ),
                      ),
                      const Spacer(),
                      if (birthProvider.hasBirthInfo)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.greenAccent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                '${birthProvider.birthInfo!.birthDate.replaceAll('-', '.')}${birthProvider.birthInfo!.hasTime ? ' ${birthProvider.birthInfo!.birthTime}' : ''}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        )
                      else
                        const Text(
                          '아래 버튼으로 사주 정보를 입력해 주세요.',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.6),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _goToInput(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: const Color(0xFF8A4FFF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    birthProvider.hasBirthInfo ? '사주 정보 수정' : '사주 입력 시작',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _authButton(BuildContext context, AuthProvider authProvider) {
    return GestureDetector(
      onTap: () => _showMyPageModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF8A4FFF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, size: 16, color: Color(0xFF8A4FFF)),
            const SizedBox(width: 6),
            Text(
              authProvider.isLoggedIn ? '마이페이지' : '로그인',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A4FFF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyPageModal(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isLoggedIn) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6EFE5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: _MyPageContent(scrollController: scrollController),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToInput(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InputScreen()),
    );
  }
}

class _MyPageContent extends StatelessWidget {
  final ScrollController scrollController;
  const _MyPageContent({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final birthProvider = context.watch<BirthInfoProvider>();
    final ticketProvider = context.watch<TicketProvider>();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        const Text('마이페이지',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),

        // 프로필
        Container(
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
                            fontSize: 13, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 티켓
        Container(
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
                  const Text('사주 티켓',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8A4FFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ticketProvider.balance != null
                          ? '${ticketProvider.balance}장'
                          : '...',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A4FFF)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('운세를 볼 때마다 티켓 1장이 소모됩니다.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const TicketHistoryScreen()));
                    },
                    child: const Text('사용 내역',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A4FFF))),
                  ),
                ],
              ),
              if (ticketProvider.error != null) ...[
                const SizedBox(height: 8),
                Text(ticketProvider.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 11)),
              ],
              const SizedBox(height: 16),
              Row(
                children: ticketProducts.map((product) {
                  final storeProduct =
                      ticketProvider.iapService.products[product.productId];
                  final price = storeProduct?.price ?? '---';
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: product == ticketProducts.first ? 0 : 4,
                        right: product == ticketProducts.last ? 0 : 4,
                      ),
                      child: GestureDetector(
                        onTap: ticketProvider.isPurchasing
                            ? null
                            : () =>
                                ticketProvider.buyProduct(product.productId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8A4FFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(product.label,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(price,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 사주 정보
        Container(
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
                  const Text('사주 정보',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const InputScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF8A4FFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        birthProvider.hasBirthInfo ? '수정' : '입력',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A4FFF)),
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
                        : '미상'),
                const SizedBox(height: 6),
                _infoRow('성별',
                    birthProvider.birthInfo!.gender == 'male' ? '남성' : '여성'),
              ] else
                const Text('사주 정보를 입력해 주세요.',
                    style:
                        TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 설정
        Container(
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
                onTap: () => _confirmLogout(context, authProvider, ticketProvider),
              ),
              const Divider(height: 1, indent: 52),
              _settingsTile(
                icon: Icons.delete_outline,
                iconColor: Colors.red,
                title: '회원탈퇴',
                titleColor: Colors.red,
                onTap: () => _confirmDeleteAccount(context, authProvider, ticketProvider),
              ),
              const Divider(height: 1, indent: 52),
              _settingsTile(
                icon: Icons.mail_outline,
                iconColor: const Color(0xFF6B7280),
                title: '문의하기',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const InquiryScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style:
                  const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937))),
      ],
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
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: titleColor ?? const Color(0xFF1F2937))),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9CA3AF))),
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

  void _confirmLogout(BuildContext context, AuthProvider authProvider,
      TicketProvider ticketProvider) {
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
              Navigator.of(context).pop(); // 모달 닫기
            },
            child:
                const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, AuthProvider authProvider,
      TicketProvider ticketProvider) {
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
                  Navigator.of(context).pop(); // 모달 닫기
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('회원탈퇴가 완료되었습니다.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            authProvider.error ?? '회원탈퇴 중 오류가 발생했습니다.')),
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
