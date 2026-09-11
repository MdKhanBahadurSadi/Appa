import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToDashboard();
  }

  void _navigateToDashboard() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/dashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.05),
              ),
            ).animate().scale(duration: 2.seconds, curve: Curves.easeInOut),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Image.asset(
                    'assets/app.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.picture_as_pdf_rounded, size: 80, color: colorScheme.primary);
                    },
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack)
                .shimmer(delay: 1.seconds, duration: 1500.ms),
                
                const SizedBox(height: 32),
                
                Text(
                  'AppaPDF',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: colorScheme.onSurface,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                
                const SizedBox(height: 8),
                
                Text(
                  'Smart Reading Experience',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
          
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 40,
                height: 2,
                child: LinearProgressIndicator(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            ).animate().fadeIn(delay: 1.seconds),
          ),
        ],
      ),
    );
  }
}
