import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'client_concept_theme.dart';
import 'concept_access_screen.dart';
import 'concept_login_screen.dart';
import 'concept_signup_screen.dart';

class ConceptHomeWelcomeScreen extends StatelessWidget {
  const ConceptHomeWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ConceptColors.burgundyPrimary,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConceptAccessScreen()),
            );
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Header Section
                Column(
                  children: [
                    const SizedBox(height: 28),
                    Text(
                      'MN JEWEL PARK',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: ConceptColors.pureWhite,
                        letterSpacing: 2.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Where Precision Meets Brilliance',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: ConceptColors.champagneNude.withOpacity(0.9),
                        letterSpacing: 0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                // Center Hero Image (Hands with Diamond Necklace & Silk Ribbon)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: size.height * 0.52,
                            maxWidth: 340,
                          ),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/concept_hero_jewelry.jpg',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 260,
                                height: 320,
                                color: ConceptColors.burgundyDark,
                                child: const Icon(
                                  Icons.diamond_outlined,
                                  size: 72,
                                  color: ConceptColors.champagneNude,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Brand Pillars and Enter Navigation
                Column(
                  children: [
                    // Enter / Access button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ConceptColors.pureWhite,
                          foregroundColor: ConceptColors.burgundyPrimary,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ConceptAccessScreen()),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ENTER ECOSYSTEM',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: ConceptColors.burgundyPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: ConceptColors.burgundyPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ConceptLoginScreen()),
                            );
                          },
                          child: Text(
                            'Sign In',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: ConceptColors.champagneNude,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '•',
                          style: TextStyle(color: ConceptColors.champagneNude.withOpacity(0.5)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ConceptSignUpScreen()),
                            );
                          },
                          child: Text(
                            'Create Account',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: ConceptColors.champagneNude,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBottomPillar('PEOPLE'),
                        _buildBottomPillar('PROCESS'),
                        _buildBottomPillar('PRECIOUS FUTURE'),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPillar(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: ConceptColors.champagneNude.withOpacity(0.75),
        letterSpacing: 1.8,
      ),
    );
  }
}
