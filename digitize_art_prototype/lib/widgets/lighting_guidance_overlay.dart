import 'package:flutter/material.dart';
import '../services/lighting_analysis_service.dart';
import '../theme/app_theme.dart';

class LightingGuidanceOverlay extends StatelessWidget {
  final LightingAnalysisResult? analysis;

  const LightingGuidanceOverlay({super.key, this.analysis});

  @override
  Widget build(BuildContext context) {
    if (analysis == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).padding.top + 76,
          left: 16,
          right: 16,
          child: _buildQualityIndicator(),
        ),
        if (analysis!.positionScore < 0.8)
          Positioned.fill(child: _buildPositionGuide()),
        Positioned(
          bottom: 128,
          left: 16,
          right: 16,
          child: _buildInfoPanel(),
        ),
      ],
    );
  }

  Widget _buildQualityIndicator() {
    final rating = analysis!.getQualityRating();
    final color = _qualityColor(rating);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.78),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _qualityText(rating),
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: analysis!.overallScore.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionGuide() {
    final guidance = analysis!.getPositionGuidance();
    if (guidance == null) return const SizedBox.shrink();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (analysis!.positionVertical == PositionHint.moveUp)
            _buildArrow(Icons.keyboard_arrow_up, 'Monter'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (analysis!.positionHorizontal == PositionHint.moveLeft)
                _buildArrow(Icons.keyboard_arrow_left, 'Gauche'),
              const SizedBox(width: 80),
              if (analysis!.positionHorizontal == PositionHint.moveRight)
                _buildArrow(Icons.keyboard_arrow_right, 'Droite'),
            ],
          ),
          if (analysis!.positionVertical == PositionHint.moveDown)
            _buildArrow(Icons.keyboard_arrow_down, 'Descendre'),
        ],
      ),
    );
  }

  Widget _buildArrow(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryMain.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    final children = <Widget>[];
    final primary = analysis!.getPrimaryIssue();
    if (primary != null) {
      children.add(_buildIssueCard(primary));
    }
    children.add(_buildDetailsCard());

    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _buildIssueCard(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.brandYellow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.priority_high_rounded,
              color: AppTheme.brandBlack, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.brandBlack,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final rows = <_Detail>[];

    // Exposure
    if (analysis!.exposureScore >= 0.8) {
      rows.add(_Detail(Icons.wb_sunny_outlined, 'Exposition', 'Parfaite', true));
    } else {
      final l = analysis!.exposureLevel;
      final txt = l == ExposureLevel.tooDark
          ? 'Trop sombre'
          : l == ExposureLevel.tooLight
              ? 'Trop claire'
              : l == ExposureLevel.slightlyDark
                  ? 'Un peu sombre'
                  : 'Un peu claire';
      rows.add(_Detail(Icons.wb_sunny_outlined, 'Exposition', txt, false));
    }

    // Color temperature
    final k = analysis!.colorTemperature.round();
    rows.add(_Detail(Icons.thermostat, 'Couleur', '${k}K',
        analysis!.colorTempScore >= 0.6));

    // Uniformity
    if (analysis!.hasUnevenLighting) {
      rows.add(_Detail(Icons.gradient, 'Uniformité',
          analysis!.unevenSideLabel(), false));
    } else {
      rows.add(const _Detail(Icons.gradient, 'Uniformité', 'Homogène', true));
    }

    // Optional flags
    if (analysis!.hasMotionBlur) {
      rows.add(const _Detail(Icons.vibration, 'Stabilité', 'Bougé', false));
    }
    if (analysis!.hasGlare) {
      rows.add(const _Detail(Icons.flare, 'Reflets', 'Détectés', false));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.78),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows
            .map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(d.icon,
                          size: 17,
                          color: d.ok
                              ? const Color(0xFF6BD68A)
                              : AppTheme.brandYellow),
                      const SizedBox(width: 10),
                      Text(
                        d.label,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        d.value,
                        style: TextStyle(
                          color: d.ok ? Colors.white : AppTheme.brandYellow,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Color _qualityColor(QualityRating rating) {
    switch (rating) {
      case QualityRating.excellent:
        return const Color(0xFF26A94C);
      case QualityRating.good:
        return const Color(0xFF6BD68A);
      case QualityRating.fair:
        return AppTheme.brandYellow;
      case QualityRating.poor:
        return AppTheme.brandRed;
    }
  }

  String _qualityText(QualityRating rating) {
    switch (rating) {
      case QualityRating.excellent:
        return 'Excellent — prêt à capturer';
      case QualityRating.good:
        return 'Bonne qualité';
      case QualityRating.fair:
        return 'Correct — ajustements conseillés';
      case QualityRating.poor:
        return 'Insuffisant — à améliorer';
    }
  }
}

class _Detail {
  final IconData icon;
  final String label;
  final String value;
  final bool ok;

  const _Detail(this.icon, this.label, this.value, this.ok);
}
