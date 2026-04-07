import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        "Please waiting for Director Approvel",
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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 50, 99, 49),

      body: Stack(
        children: [
          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 40 : -120,
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

          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 50),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Welcome Back !",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Login to your account",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color.fromARGB(255, 226, 224, 224),
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

                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 30,
                        bottom: 30,
                      ),
                      decoration: BoxDecoration(
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
                            "Enter Email or Username",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            onChanged: (value) async {
                              if (value.contains("@") && value.contains(".")) {
                                setState(() {
                                  isCheckingRole = true;
                                  emailRoleMessage = null;
                                });

                                try {
                                  final role = await AuthService.checkEmailRole(
                                    value.trim(),
                                  );

                                  setState(() {
                                    isCheckingRole = false;
                                    if (role != null) {
                                      emailRoleMessage =
                                          "This email role is $role";
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
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                ),
                              ),

                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          // if (isCheckingRole)
                          //   const Padding(
                          //     padding: EdgeInsets.only(top: 8),
                          //     child: LinearProgressIndicator(
                          //       minHeight: 2,
                          //     ),
                          //   ),
                          if (emailRoleMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                emailRoleMessage!,
                                style: const TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          const SizedBox(height: 20),

                          Center(
                            child: AppButton(
                              text: "Send OTP",
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _sendOtp,
                              txtcolor: const Color.fromARGB(255, 50, 99, 49),
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("assets/flower.png", height: 15, width: 15),
                        Text(
                          "  Poornasree Equipements",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color.fromARGB(255, 245, 243, 243),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
