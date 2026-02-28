import 'package:flutter/material.dart';
import '../services/lighting_analysis_service.dart';

class LightingGuidanceOverlay extends StatelessWidget {
  final LightingAnalysisResult? analysis;

  const LightingGuidanceOverlay({
    super.key,
    this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    if (analysis == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Quality indicator (top left)
        Positioned(
          top: MediaQuery.of(context).padding.top + 80,
          left: 16,
          right: 16,
          child: _buildQualityIndicator(),
        ),

        // Center positioning guide
        if (analysis!.positionScore < 0.8)
          Positioned.fill(
            child: _buildPositionGuide(),
          ),

        // Bottom info panel
        Positioned(
          bottom: 120,
          left: 16,
          right: 16,
          child: _buildInfoPanel(),
        ),
      ],
    );
  }

  Widget _buildQualityIndicator() {
    final rating = analysis!.getQualityRating();
    final color = _getQualityColor(rating);
    final icon = _getQualityIcon(rating);
    final text = _getQualityText(rating);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _buildScoreBar(analysis!.overallScore, color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(double score, Color color) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: score,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionGuide() {
    final positionGuidance = analysis!.getPositionGuidance();
    if (positionGuidance == null) return const SizedBox.shrink();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Arrows
          if (analysis!.positionVertical == PositionHint.moveUp)
            _buildArrow(Icons.arrow_upward, 'Move Up'),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (analysis!.positionHorizontal == PositionHint.moveLeft)
                _buildArrow(Icons.arrow_back, 'Move Left'),
              
              const SizedBox(width: 80),
              
              if (analysis!.positionHorizontal == PositionHint.moveRight)
                _buildArrow(Icons.arrow_forward, 'Move Right'),
            ],
          ),
          
          if (analysis!.positionVertical == PositionHint.moveDown)
            _buildArrow(Icons.arrow_downward, 'Move Down'),
        ],
      ),
    );
  }

  Widget _buildArrow(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    final issues = <Widget>[];

    // Primary issue
    final primaryIssue = analysis!.getPrimaryIssue();
    if (primaryIssue != null) {
      issues.add(_buildIssueCard(
        primaryIssue,
        Icons.warning_amber_rounded,
        Colors.orange,
      ));
    }

    // Lighting details
    issues.add(_buildDetailsCard());

    if (issues.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: issues,
    );
  }

  Widget _buildIssueCard(String message, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final details = <String>[];

    // Exposure
    if (analysis!.exposureScore < 0.8) {
      final level = analysis!.exposureLevel;
      if (level == ExposureLevel.tooDark) {
        details.add('💡 Exposure: Too dark');
      } else if (level == ExposureLevel.tooLight) {
        details.add('💡 Exposure: Too bright');
      } else if (level == ExposureLevel.slightlyDark) {
        details.add('💡 Exposure: Slightly dark');
      } else if (level == ExposureLevel.slightlyLight) {
        details.add('💡 Exposure: Slightly bright');
      }
    } else {
      details.add('💡 Exposure: Perfect');
    }

    // Color temperature
    final tempK = analysis!.colorTemperature.round();
    final tempEmoji = tempK < 4000 ? '🟡' : (tempK > 6000 ? '🔵' : '✅');
    details.add('$tempEmoji Color: ${tempK}K');

    // Blur
    if (analysis!.hasMotionBlur) {
      details.add('📷 Motion detected');
    }

    // Glare
    if (analysis!.hasGlare) {
      details.add('✨ Glare detected');
    }

    // Shadows
    if (analysis!.hasShadows) {
      details.add('🌑 Harsh shadows');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lighting Analysis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...details.map((detail) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  detail,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Color _getQualityColor(QualityRating rating) {
    switch (rating) {
      case QualityRating.excellent:
        return Colors.green;
      case QualityRating.good:
        return Colors.lightGreen;
      case QualityRating.fair:
        return Colors.orange;
      case QualityRating.poor:
        return Colors.red;
    }
  }

  IconData _getQualityIcon(QualityRating rating) {
    switch (rating) {
      case QualityRating.excellent:
        return Icons.check_circle;
      case QualityRating.good:
        return Icons.thumb_up;
      case QualityRating.fair:
        return Icons.warning_amber_rounded;
      case QualityRating.poor:
        return Icons.error_outline;
    }
  }

  String _getQualityText(QualityRating rating) {
    switch (rating) {
      case QualityRating.excellent:
        return 'Excellent - Ready to capture!';
      case QualityRating.good:
        return 'Good quality';
      case QualityRating.fair:
        return 'Fair - Adjustments recommended';
      case QualityRating.poor:
        return 'Poor - Please adjust';
    }
  }
}
