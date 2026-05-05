import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../data/models/InquiryModel.dart';
import '../../data/repositories/inquiry_repository.dart';
import '../providers/inquiry_provider.dart';

/// 내 문의 목록 화면 (사용자)
/// - Provider는 화면 진입 시 자체 생성
/// - FAB: 문의 작성 (post_home_screen FAB 패턴 동일)
class InquiryListScreen extends StatelessWidget {
  const InquiryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
      InquiryProvider(context.read<InquiryRepository>())
        ..fetchMyInquiries(),
      child: const _InquiryListView(),
    );
  }
}

class _InquiryListView extends StatefulWidget {
  const _InquiryListView();

  @override
  State<_InquiryListView> createState() => _InquiryListViewState();
}

class _InquiryListViewState extends State<_InquiryListView> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InquiryProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textTitle),
          onPressed: () => context.pop(),
        ),
        title: const Text('문의하기',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textTitle)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/inquiry/write');
          if (context.mounted) {
            context.read<InquiryProvider>().fetchMyInquiries();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: provider.isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : provider.myInquiries.isEmpty
          ? const Center(
          child: Text('접수된 문의가 없습니다.',
              style: TextStyle(color: AppColors.textSub2)))
          : RefreshIndicator(
        onRefresh: () => provider.fetchMyInquiries(),
        color: AppColors.primary,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: provider.myInquiries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _InquiryCard(inquiry: provider.myInquiries[index]),
        ),
      ),
    );
  }
}

/// 문의 카드 — 상태 배지 + 제목 + 내용 미리보기 + 답변 (있으면 바로 아래)
class _InquiryCard extends StatelessWidget {
  final InquiryModel inquiry;
  const _InquiryCard({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
        Border.all(color: AppColors.inputBorder.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태 배지 + 날짜
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: inquiry.answered
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.textSub1.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inquiry.answered ? '답변 완료' : '접수 중',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: inquiry.answered
                        ? AppColors.primary
                        : AppColors.textSub2,
                  ),
                ),
              ),
              const Spacer(),
              Text(_formatDate(inquiry.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSub2)),
            ],
          ),
          const SizedBox(height: 8),
          // 제목
          Text(inquiry.title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textTitle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          // 내용 미리보기
          Text(inquiry.content,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textBody, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          // 답변 영역 — 있으면 바로 아래, 길면 ... 처리
          if (inquiry.answered && inquiry.answerContent != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.inputBorder),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('답변',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    inquiry.answerContent!,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textBody,
                        height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}