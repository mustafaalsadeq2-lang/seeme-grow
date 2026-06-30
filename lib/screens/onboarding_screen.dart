import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Text(
          'ONBOARDING TEST',
          style: TextStyle(fontSize: 24, color: Colors.black),
        ),
      ),
    );
  }
}
