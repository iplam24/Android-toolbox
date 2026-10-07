import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/settings_service.dart';

class BentoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badge;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isWide;

  const BentoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.trailing,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF151D2C) : Colors.white;
    final borderColor = isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          try {
            Get.find<SettingsService>().vibrate();
          } catch (_) {}
          onTap();
        },
        borderRadius: BorderRadius.circular(22),
        splashColor: accentColor.withOpacity(0.12),
        highlightColor: accentColor.withOpacity(0.06),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.25)
                    : const Color(0x0C0F172A),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(isDark ? 0.14 : 0.10),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: accentColor.withOpacity(0.28),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                  if (badge != null && badge!.isNotEmpty)
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(isDark ? 0.16 : 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentColor.withOpacity(0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          badge!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    )
                  else if (trailing != null)
                    trailing!
                  else
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: textSecondary.withOpacity(0.35),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
