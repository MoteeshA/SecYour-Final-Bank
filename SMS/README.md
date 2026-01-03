SMS Module – Secure Messaging & Notification System
==================================================

The SMS module is a Flutter-based component of the SecYour Secure Digital
Banking System. It is responsible for handling user notifications,
alerts, and security-related messages such as OTPs and warnings.

This module is designed to work independently or integrate with the
main banking application and Flask backend.


PURPOSE OF SMS MODULE
---------------------
- Send transaction alerts
- Deliver OTPs for authentication
- Notify users about suspicious activity
- Provide security warnings and confirmations
- Act as a communication bridge between backend and user


MODULE STRUCTURE
----------------
SMS/

android/        -> Android platform files
ios/            -> iOS platform files
macos/          -> macOS platform files
web/            -> Web support files
windows/        -> Windows desktop support
lib/            -> Flutter source code
test/           -> Widget and unit tests
pubspec.yaml    -> Flutter dependencies
pubspec.lock    -> Locked dependency versions


TECHNOLOGIES USED
-----------------
- Flutter (Dart)
- Cross-platform UI framework
- REST API integration (backend-driven messages)
- Secure message handling logic


SECURITY DESIGN
---------------
- No hardcoded API keys or secrets
- Message content is backend-controlled
- Supports OTP-based authentication workflows
- Designed to integrate with trust-score decisions
  (OTP, logout, or challenge flows)


INTEGRATION FLOW
----------------
1. Flask backend evaluates user behavior
2. Trust score is calculated
3. Backend decides action (OTP / Alert / Warning)
4. SMS module displays or sends notification
5. User responds or verifies as required


HOW TO RUN
----------
1. Open terminal
2. Navigate to SMS folder
   cd SMS
3. Install dependencies
   flutter pub get
4. Run application
   flutter run


SUPPORTED PLATFORMS
-------------------
- Android
- iOS
- Web
- Windows
- macOS


DEVELOPMENT STATUS
------------------
Under active development
Part of academic / research project


AUTHOR
------
Moteesh A | Manya Singh | Swaraj Kumar Sahu | Nikhil T Nainan
Secure Systems | Mobile Security | Behavioral Analytics
