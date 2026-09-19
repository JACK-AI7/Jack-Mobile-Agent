// lib/widgets/jack_approval_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../services/api/jack_api_client.dart';

class JackApprovalCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> requestData;
  final VoidCallback onResolved;

  const JackApprovalCard({
    super.key,
    required this.requestData,
    required this.onResolved,
  });

  @override
  ConsumerState<JackApprovalCard> createState() => _JackApprovalCardState();
}

class _JackApprovalCardState extends ConsumerState<JackApprovalCard> {
  bool _isProcessing = false;

  Future<void> _handleApprove() async {
    setState(() => _isProcessing = true);
    try {
      final executionId = widget.requestData['executionId'] as String? ?? '';
      await ref.read(apiClientProvider).approveExecution(executionId);
    } catch (e) {
      debugPrint('Approve error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        widget.onResolved();
      }
    }
  }

  Future<void> _handleReject() async {
    setState(() => _isProcessing = true);
    try {
      final executionId = widget.requestData['executionId'] as String? ?? '';
      await ref.read(apiClientProvider).rejectExecution(executionId);
    } catch (e) {
      debugPrint('Reject error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        widget.onResolved();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.requestData['action'] as String? ?? 'Unknown Action';
    final reason = widget.requestData['reason'] as String? ?? 'No reason provided';
    final tool = widget.requestData['tool'] as String? ?? 'Unknown Tool';
    final riskLevel = widget.requestData['riskLevel'] as String? ?? 'HIGH';
    final impact = widget.requestData['impact'] as String? ?? 'Will modify state.';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskLevel.toUpperCase() == 'HIGH' ? Colors.redAccent.withAlpha(150) : AppColors.accentViolet.withAlpha(150)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security_rounded,
                color: riskLevel.toUpperCase() == 'HIGH' ? Colors.redAccent : AppColors.accentCyan,
              ),
              const SizedBox(width: 8),
              const Text(
                'APPROVAL REQUIRED',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Action: $action',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            'Tool: $tool',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Reason: $reason',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          Text(
            'Impact: $impact',
            style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _handleReject,
                  child: const Text('REJECT', style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCyan,
                  ),
                  child: const Text('APPROVE'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
