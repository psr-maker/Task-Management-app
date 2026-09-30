import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/widgets/auth_page_frame.dart';
import 'package:staff_work_track/screen/authen/oto_verify.dart';
import 'package:staff_work_track/services/auth_service.dart';

import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';

class LoginSelection extends StatefulWidget {
  const LoginSelection({super.key});

  @override
  State<LoginSelection> createState() => _LoginSelectionState();
}

class _LoginSelectionState extends State<LoginSelection> {
  final emailController = TextEditingController();
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  final AuthService authService = AuthService();

  bool _isLoading = false;

  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  String? emailRoleMessage;
  bool isCheckingRole = false;

  Future<void> _sendOtp() async {
    if (_isLoading) return; // ✅ HARD BLOCK

    if (emailController.text.trim().isEmpty) {
      _showMessage("Please enter email", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await authService.sendOtp(emailController.text.trim());

      _showMessage(
        "OTP sent to ${emailController.text.trim()}",
        isError: false,
      );

      // ✅ DO NOT reset loading before navigation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Otpverify(email: emailController.text.trim()),
        ),
      );
    } catch (e) {
      final errorMsg = e.toString().replaceAll("Exception:", "").trim();

      if (errorMsg.toLowerCase().contains("inactive")) {
        await showPendingAlert(
          context,
          "Your Email is not Approved Yet, Please Wait for Director approval",
        );
      } else {
        _showMessage(errorMsg, isError: true);
      }

      setState(() => _isLoading = false); // ✅ only reset on error
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    setState(() {
      _topMessage = message;
      _isErrorMessage = isError;
      _showTopMessage = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showTopMessage = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: isDesktop
          ? const Color(0xFFF4F7F5)
          : const Color(0xFF2C6737),
      body: Stack(
        children: [
          AuthPageFrame(
            form: isDesktop
                ? _webLoginCard(440)
                : SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 48,
                            ),
                            child: Center(child: _buildLoginCard(context)),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 24 : -120,
              left: 16,
              right: 16,
              duration: const Duration(milliseconds: 300),
              child: Msgsnackbar(
                context,
                message: _topMessage!,
                isError: _isErrorMessage,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final bool isMobile = screenWidth < 600;
        final bool isDesktop = AppLayout.isDesktop(context);

        final double cardWidth = isMobile
            ? screenWidth
            : isDesktop
            ? 440
            : 480;

        if (isDesktop) {
          return _webLoginCard(cardWidth);
        }

        final double horizontalPadding = isMobile ? 18 : 24;
        final double verticalPadding = isMobile ? 22 : 28;

        return Container(
          width: cardWidth,
          constraints: const BoxConstraints(maxWidth: 500),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1B4F2E),
            borderRadius: BorderRadius.circular(isMobile ? 18 : 24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Welcome Back !",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Login to your account",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color.fromARGB(255, 226, 224, 224),
                ),
              ),
              const SizedBox(height: 15),
              const Icon(Icons.person, size: 64, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
                "Login",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              _loginFields(isWebStyle: false),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/flower.png", height: 15, width: 15),
                  const Text(
                    "  Poornasree Equipments",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color.fromARGB(255, 245, 243, 243),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _webLoginCard(double cardWidth) {
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF163824),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in with your email to continue',
            style: TextStyle(fontSize: 14, color: Color(0xFF5B6B60)),
          ),
          const SizedBox(height: 28),
          _loginFields(isWebStyle: true),
        ],
      ),
    );
  }

  Widget _loginFields({required bool isWebStyle}) {
    final labelColor = isWebStyle ? const Color(0xFF163824) : Colors.white;
    final fieldFill = isWebStyle ? const Color(0xFFF4F7F5) : null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: isWebStyle ? 0 : 20,
        right: isWebStyle ? 0 : 20,
        top: isWebStyle ? 0 : 30,
        bottom: isWebStyle ? 0 : 30,
      ),
      decoration: isWebStyle
          ? null
          : BoxDecoration(
              color: const Color.fromARGB(255, 25, 77, 38),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Email or Username",
            style: TextStyle(
              fontSize: isWebStyle ? 13 : 12,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) async {
              if (value.contains("@") && value.contains(".")) {
                setState(() {
                  isCheckingRole = true;
                  emailRoleMessage = null;
                });

                try {
                  final role = await AuthService.checkEmailRole(value.trim());

                  setState(() {
                    isCheckingRole = false;
                    if (role != null) {
                      emailRoleMessage = "This email role is $role";
                    }
                  });
                } catch (e) {
                  setState(() {
                    isCheckingRole = false;
                  });
                }
              } else {
                setState(() {
                  emailRoleMessage = null;
                });
              }
            },
            controller: emailController,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isWebStyle ? const Color(0xFF163824) : Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'name@company.com',
              hintStyle: TextStyle(
                color: isWebStyle ? Colors.grey.shade500 : Colors.white54,
              ),
              filled: isWebStyle,
              fillColor: fieldFill,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isWebStyle
                      ? const Color(0xFF2C6737)
                      : Colors.white,
                ),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (emailRoleMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                emailRoleMessage!,
                style: TextStyle(
                  color: isWebStyle
                      ? const Color(0xFF2C6737)
                      : Colors.yellow,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: isWebStyle ? double.infinity : null,
            child: Center(
              child: AppButton(
                text: "Send OTP",
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _sendOtp,
                txtcolor: isWebStyle
                    ? Colors.white
                    : const Color.fromARGB(255, 50, 99, 49),
                color: isWebStyle
                    ? const Color(0xFF2C6737)
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
