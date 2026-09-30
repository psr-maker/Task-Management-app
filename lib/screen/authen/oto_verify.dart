import 'dart:async';
import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/auth_page_frame.dart';
import 'package:staff_work_track/screen/authen/login_selection.dart';
import 'package:staff_work_track/services/firebase_noti_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/screen/admin/admin.dart';
import 'package:staff_work_track/screen/division_head/division_head.dart';
import 'package:staff_work_track/screen/staff/staff.dart';
import 'package:staff_work_track/screen/super%20admin/superadmin.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';

class Otpverify extends StatefulWidget {
  final String email;
  const Otpverify({super.key, required this.email});
  @override
  State<Otpverify> createState() => _OtpverifyState();
}

class _OtpverifyState extends State<Otpverify> {
  final AuthService _authService = AuthService();
  final List<TextEditingController> _otpcontrollers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String get _enteredOtp => _otpcontrollers.map((c) => c.text).join();
  int _secondsLeft = 600;
  int _otpAttempts = 0;
  Timer? _timer;
  bool _canResend = false;
  bool _isLoading = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  @override
  void initState() {
    super.initState();
    _startOtpTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpcontrollers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_enteredOtp.length == 6) {
      _verifyOtp();
    }
  }

  void _clearOtpFields() {
    for (var c in _otpcontrollers) c.clear();
  }

  void _startOtpTimer() {
    _timer?.cancel();
    _secondsLeft = 600;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
        setState(() => _canResend = true); // enable resend
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void showTopMessage(String message, {bool isError = true}) {
    setState(() {
      _topMessage = message;
      _isErrorMessage = isError;
      _showTopMessage = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showTopMessage = false);
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _enteredOtp.trim();
    if (otp.length != 6) {
      showTopMessage("Please enter 6-digit OTP", isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _authService.verifyOtp(widget.email, otp);
      final token = result["token"];
      if (token == null || token.isEmpty) {
        showTopMessage("Invalid server response", isError: true);
        return;
      }
      final role = JwtHelper.getRole(token);
      await AuthService.saveToken(token);
      // Get FCM token
      final fcmToken = await NotificationService.getToken();

      if (fcmToken != null && fcmToken.isNotEmpty) {
        try {
          await _authService.registerFcmToken(fcmToken);

          print("✅ FCM token registered successfully");
        } catch (e) {
          print("❌ Failed to register FCM token: $e");
        }
      }
      showTopMessage("OTP verified successfully", isError: false);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      if (role == "1") {
        _go(const SuperAdmin());
      } else if (role == "3") {
        _go(const Admin());
      } else if (AppRoles.isDivisionHead(role)) {
        _go(const DivisionHead());
      } else {
        _go(const Staff());
      }
    } catch (e) {
      final error = e.toString().replaceAll("Exception: ", "");
      if (error.contains("Invalid OTP")) {
        showTopMessage("Invalid OTP. Please try again", isError: true);
      } else if (error.contains("OTP expired")) {
        showTopMessage("OTP expired. Please resend OTP", isError: true);
      } else if (error.contains("Maximum OTP attempts")) {
        showTopMessage("Maximum OTP attempts reached", isError: true);
      } else {
        showTopMessage("OTP verification failedddddddddddddd", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      _otpAttempts = await _authService.sendOtp(widget.email);
      _clearOtpFields();
      _startOtpTimer();
      if (_otpAttempts < 3) {
        showTopMessage(
          "OTP resent successfully ($_otpAttempts / 3)",
          isError: false,
        );
      } else if (_otpAttempts == 3) {
        showTopMessage("Warning: Last OTP resend attempt", isError: true);
      }
    } catch (e) {
      final error = e.toString().replaceAll("Exception: ", "");
      if (error.contains("Maximum OTP attempts")) {
        showTopMessage(
          "Maximum OTP attempts reached. Try again later.",
          isError: true,
        );
      } else {
        showTopMessage(error, isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _go(Widget page) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  String get formattedTime {
    final secondsLeft = _secondsLeft - 1; // subtract 1 for accurate display
    final minutes = (secondsLeft ~/ 60).clamp(0, 59).toString().padLeft(2, '0');
    final seconds = (secondsLeft % 60).clamp(0, 59).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: isDesktop
          ? const Color(0xFFF4F7F5)
          : const Color.fromARGB(255, 50, 99, 49),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: const Color.fromARGB(255, 50, 99, 49),
              elevation: 0,
              leading: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginSelection()),
                  );
                },
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
            ),
      body: Stack(
        children: [
          AuthPageFrame(
            form: _otpBody(context),
          ),
          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 5 : -120,
              left: 16,
              right: 16,
              duration: const Duration(milliseconds: 300),
              child: Msgsnackbar(
                context,
                message: _topMessage!,
                isError: _isErrorMessage,
                backgroundColor: _isErrorMessage
                    ? Colors.red
                    : Theme.of(context).colorScheme.onPrimary,
                textColor: Theme.of(context).colorScheme.secondary,
                iconColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _otpBody(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final bool isMobile = screenWidth < 600;
          final bool isDesktop = AppLayout.isDesktop(context);
          final onColor = isDesktop ? WebTheme.ink : Colors.white;
          final mutedColor = isDesktop
              ? WebTheme.muted
              : const Color.fromARGB(255, 235, 233, 233);
          final fieldFill = isDesktop
              ? WebTheme.canvas
              : WebTheme.dark;
          final fieldBorder = isDesktop ? WebTheme.line : Colors.white;
          final double contentWidth = isMobile
              ? screenWidth
              : isDesktop
              ? 440
              : 520;
          final double horizontalPadding = isMobile ? 16 : 24;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isMobile ? 20 : 30,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight - 40),
              child: Center(
                child: Container(
                  width: contentWidth,
                  padding: isDesktop
                      ? const EdgeInsets.fromLTRB(28, 24, 28, 28)
                      : EdgeInsets.zero,
                  decoration: isDesktop
                      ? BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: WebTheme.line),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 30,
                              offset: Offset(0, 12),
                            ),
                          ],
                        )
                      : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isDesktop)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginSelection(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.arrow_back_ios,
                              color: onColor,
                            ),
                          ),
                        ),
                            // --------------------------------------------------
                            // SECURITY ICON
                            // --------------------------------------------------
                            Icon(
                              Icons.security,
                              size: isMobile ? 58 : 65,
                              color: onColor,
                            ),

                            SizedBox(height: isMobile ? 4 : 8),

                            // --------------------------------------------------
                            // TITLE
                            // --------------------------------------------------
                            Text(
                              "Verification",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 22 : 25,
                                color: onColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: isMobile ? 22 : 32),

                            // --------------------------------------------------
                            // DESCRIPTION
                            // --------------------------------------------------
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: mutedColor,
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(
                                    text:
                                        "We've sent a 6-digit verification code\n",
                                  ),
                                  const TextSpan(
                                    text: "to your Registered Email\n",
                                  ),
                                  TextSpan(
                                    text: widget.email,
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 13,
                                      fontWeight: FontWeight.bold,
                                      color: onColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: isMobile ? 28 : 40),

                            // --------------------------------------------------
                            // OTP BOXES
                            // --------------------------------------------------
                            LayoutBuilder(
                              builder: (context, otpConstraints) {
                                final availableWidth = otpConstraints.maxWidth;

                                // Space between OTP boxes
                                const double spacing = 8;

                                // Calculate box width dynamically
                                double boxWidth =
                                    (availableWidth - (spacing * 5)) / 6;

                                // Keep boxes from becoming too large
                                boxWidth = boxWidth.clamp(42.0, 55.0);

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(6, (index) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: index == 5 ? 0 : spacing,
                                      ),
                                      child: SizedBox(
                                        width: boxWidth,
                                        height: isMobile ? 52 : 56,
                                        child: TextField(
                                          controller: _otpcontrollers[index],
                                          focusNode: _focusNodes[index],

                                          keyboardType: TextInputType.number,

                                          textAlign: TextAlign.center,

                                          maxLength: 1,

                                          style: TextStyle(
                                            fontSize: isMobile ? 15 : 16,
                                            fontWeight: FontWeight.bold,
                                            color: onColor,
                                          ),

                                          decoration: InputDecoration(
                                            counterText: "",

                                            filled: true,

                                            fillColor: fieldFill,

                                            contentPadding: EdgeInsets.zero,

                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),

                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: fieldBorder,
                                              ),
                                            ),

                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                color: isDesktop
                                                    ? WebTheme.brand
                                                    : Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                          ),

                                          onChanged: (value) =>
                                              _onOtpChanged(index, value),
                                        ),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),

                            SizedBox(height: isMobile ? 18 : 20),

                            // --------------------------------------------------
                            // RESEND / TIMER
                            // --------------------------------------------------
                            _canResend
                                ? GestureDetector(
                                    onTap: _resendOtp,
                                    child: Text(
                                      "Resend OTP",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: onColor,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  )
                                : RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: isMobile ? 11 : 12,
                                        color: mutedColor,
                                      ),
                                      children: [
                                        const TextSpan(
                                          text: "OTP expires in : ",
                                        ),
                                        TextSpan(
                                          text: formattedTime,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: onColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                            SizedBox(height: isMobile ? 28 : 40),

                            // --------------------------------------------------
                            // VERIFY BUTTON
                            // --------------------------------------------------
                            SizedBox(
                              width: isMobile ? double.infinity : 250,
                              child: AppButton(
                                text: "Verify OTP",
                                isLoading: _isLoading,
                                onPressed: _isLoading ? null : _verifyOtp,
                                txtcolor: isDesktop
                                    ? Colors.white
                                    : const Color.fromARGB(255, 50, 99, 49),
                                color: isDesktop
                                    ? WebTheme.brand
                                    : Colors.white,
                              ),
                            ),

                            SizedBox(height: isMobile ? 20 : 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
  }
}
