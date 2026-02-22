import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';
import '../components/responsive_components.dart';

class AppLogo extends StatelessWidget {
  final double? size;
  final bool showText;
  final bool vertical;
  final Color? textColor;

  const AppLogo({
    super.key,
    this.size,
    this.showText = true,
    this.vertical = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = size ?? (ResponsiveUtils.isDesktop(context) ? 48.0 : 32.0);
    final fontMultiplier = ResponsiveUtils.getFontSizeMultiplier(context);
    final effectiveTextColor = textColor ?? AppColors.primaryYellow;

    return vertical ? _buildVerticalLayout(logoSize, fontMultiplier, effectiveTextColor)
                   : _buildHorizontalLayout(logoSize, fontMultiplier, effectiveTextColor);
  }

  Widget _buildVerticalLayout(double logoSize, double fontMultiplier, Color textColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : double.infinity;
        // Reserve approximate space for texts; if not enough height, hide texts to avoid overflow
        final needsSpaceForText = logoSize + (showText ? (24.0 * fontMultiplier + 14.0) : 0.0);
        final showTextNow = showText && maxH >= needsSpaceForText;

        final containerHeight = showTextNow ? needsSpaceForText : logoSize;
        final usedHeight = math.min(containerHeight, maxH);

        return SizedBox(
          height: usedHeight,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogoWidget(logoSize),
              if (showTextNow) ...[
                SizedBox(height: 8 * fontMultiplier),
                Flexible(child: _buildAppName(fontMultiplier, textColor)),
                Flexible(child: _buildSlogan(fontMultiplier, textColor)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHorizontalLayout(double logoSize, double fontMultiplier, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLogoWidget(logoSize),
        if (showText) ...[
          SizedBox(width: 12 * fontMultiplier),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAppName(fontMultiplier, textColor),
              _buildSlogan(fontMultiplier, textColor),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLogoWidget(double logoSize) {
    // Carrega a logo diretamente, com padding, fundo em gradiente e sombra
    return Container(
      width: logoSize,
      height: logoSize,
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [AppColors.primaryYellow, Color(0xFFFFB000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryYellow.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: Colors.black,
          child: Image.asset(
            AppConstants.logoPath,
            width: logoSize - 12,
            height: logoSize - 12,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _buildFallbackLogo(logoSize - 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackLogo(double logoSize) {
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [AppColors.primaryYellow, Color(0xFFFFB000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.directions_car,
        size: logoSize * 0.6,
        color: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildAppName(double fontMultiplier, Color textColor) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        AppConstants.appName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 20 * fontMultiplier,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSlogan(double fontMultiplier, Color textColor) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        AppConstants.appSlogan,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12 * fontMultiplier,
          color: textColor.withValues(alpha: 0.8),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

// Widget específico para diferentes contextos
class AppBarLogo extends StatelessWidget {
  const AppBarLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLogo(
      size: ResponsiveUtils.isMobile(context) ? 32 : 40,
      showText: !ResponsiveUtils.isMobile(context),
      vertical: false,
      textColor: AppColors.primaryYellow,
    );
  }
}

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLogo(
      size: ResponsiveUtils.isDesktop(context) ? 120 : 80,
      showText: true,
      vertical: true,
      textColor: AppColors.primaryYellow,
    );
  }
}

class DrawerLogo extends StatelessWidget {
  const DrawerLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLogo(
      size: 64,
      showText: true,
      vertical: true,
      textColor: AppColors.primaryDark,
    );
  }
}