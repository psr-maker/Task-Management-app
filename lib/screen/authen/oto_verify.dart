import 'dart:async';
import 'package:flutter/material.dart';
import 'package:staff_work_track/screen/authen/login_selection.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/screen/admin/admin.dart';
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
      showTopMessage("OTP verified successfully", isError: false);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      if (role == "Director") {
        _go(const SuperAdmin());
      } else if (role == "Manager") {
        _go(const Admin());
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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 50, 99, 49),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 50, 99, 49),
        leading: IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginSelection()),
          ),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
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
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                textColor: Theme.of(context).colorScheme.secondary,
                iconColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, top: 80.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  Icon(Icons.security, size: 65, color: Colors.white),
                  Text(
                    "Verification",
                    style: TextStyle(
                      fontSize: 25,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 235, 233, 233),
                      ),
                      children: [
                        const TextSpan(
                          text: "We've sent a 6-digit verification code \n",
                        ),
                        const TextSpan(text: "to your Registered Email   "),
                        TextSpan(
                          text: widget.email,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 50,
                        child: TextField(
                          controller: _otpcontrollers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            filled: true,
                            fillColor: const Color.fromARGB(255, 25, 77, 38),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          onChanged: (value) => _onOtpChanged(index, value),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 20),
                  _canResend
                      ? GestureDetector(
                          onTap: _resendOtp,
                          child: const Text(
                            "Resend OTP",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                            children: [
                              const TextSpan(text: "OTP expires in : "),
                              TextSpan(
                                text: formattedTime,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                  SizedBox(height: 40),
                  Center(
                    child: AppButton(
                      text: "Verify OTP",
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _verifyOtp,
                      txtcolor: const Color.fromARGB(255, 50, 99, 49),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
