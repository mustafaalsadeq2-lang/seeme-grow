import 'package:flutter/material.dart';

import '../utils/app_tokens.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  // 'yearly' or 'monthly'
  String _selectedPlan = 'yearly';
  bool _loading = false;

  Future<void> _purchase() async {
    // RevenueCat purchase logic goes here when paywall is fully wired.
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Purchase flow coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _restorePurchases() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Restore purchases coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // ── Hero ──────────────────────────────────────────────────────
              const AppMark(size: 52),
              const SizedBox(height: 20),
              Text(
                'Capture every frame.',
                style: serif(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  italic: true,
                  color: T.forest,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Unlock the full SeeMeGrow experience\nwith unlimited features.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: T.ink3, height: 1.6),
              ),

              const SizedBox(height: 32),

              // ── Paywall content ───────────────────────────────────────────
              _PaywallContent(
                selectedPlan: _selectedPlan,
                onPlanSelected: (plan) => setState(() => _selectedPlan = plan),
              ),

              const SizedBox(height: 24),

              // ── Purchase CTA ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _purchase,
                  style: FilledButton.styleFrom(
                    backgroundColor: T.ink,
                    disabledBackgroundColor: T.ink4,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _selectedPlan == 'yearly'
                              ? 'Start Yearly Plan'
                              : 'Start Monthly Plan',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Restore ───────────────────────────────────────────────────
              GestureDetector(
                onTap: _restorePurchases,
                child: const Text(
                  'Restore Purchases',
                  style: TextStyle(
                    fontSize: 13,
                    color: T.ink3,
                    decoration: TextDecoration.underline,
                    decorationColor: T.ink3,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ),

              const SizedBox(height: 20),

              // ── Legal note ────────────────────────────────────────────────
              const Text(
                'Cancel anytime. Subscription auto-renews until cancelled.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: T.ink4, height: 1.5),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Paywall content: feature list + plan cards ─────────────────────────────

class _PaywallContent extends StatelessWidget {
  final String selectedPlan;
  final ValueChanged<String> onPlanSelected;

  const _PaywallContent({
    required this.selectedPlan,
    required this.onPlanSelected,
  });

  static const _features = [
    (Icons.people_outline,          'Unlimited children'),
    (Icons.cloud_upload_outlined,   'Cloud backup & sync'),
    (Icons.compare_arrows_outlined, 'Year comparison view'),
    (Icons.slideshow_outlined,      'Timeline slideshow'),
    (Icons.notifications_outlined,  'Birthday reminders'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Feature list ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: T.forestSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: T.forest.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: _features.map((f) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(f.$1, size: 18, color: T.forest),
                    const SizedBox(width: 12),
                    Text(
                      f.$2,
                      style: const TextStyle(
                        fontSize: 14,
                        color: T.ink,
                        fontWeight: FontWeight.w500,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: T.forest,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        // ── Plan cards ──────────────────────────────────────────────────────
        _PlanCard(
          planId: 'yearly',
          title: 'Yearly',
          price: '\$19.99',
          period: '/ year',
          badge: 'Best Value',
          perMonth: '\$1.67 / month',
          isSelected: selectedPlan == 'yearly',
          onTap: () => onPlanSelected('yearly'),
        ),
        const SizedBox(height: 10),
        _PlanCard(
          planId: 'monthly',
          title: 'Monthly',
          price: '\$3.99',
          period: '/ month',
          isSelected: selectedPlan == 'monthly',
          onTap: () => onPlanSelected('monthly'),
        ),
      ],
    );
  }
}

// ── Plan card ──────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final String planId;
  final String title;
  final String price;
  final String period;
  final String? badge;
  final String? perMonth;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.planId,
    required this.title,
    required this.price,
    required this.period,
    this.badge,
    this.perMonth,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: isSelected ? T.forestSoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? T.forest : T.hairline,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: T.forest.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? T.forest : Colors.transparent,
                border: Border.all(
                  color: isSelected ? T.forest : T.ink4,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),

            const SizedBox(width: 12),

            // Plan info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? T.forest : T.ink,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: T.forest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (perMonth != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      perMonth!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? T.forest : T.ink3,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ],
              ),
            ),

            // Price
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? T.forest : T.ink,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    period,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? T.forest : T.ink3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
