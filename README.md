SecYour – Secure Digital Banking System
=====================================

SecYour is a secure digital banking platform designed to detect suspicious
user behavior and prevent fraud using behavior-based trust scoring,
mobile interaction analysis, and real-time backend monitoring.

This repository contains multiple modules including Flutter banking
applications and a Flask-based analytics backend.


PROJECT STRUCTURE
-----------------
SecYour-Final-Bank/

BANKv2BANK/        -> Main Flutter banking application
BankSDKv2/         -> Banking SDK & shared components
SMS/               -> SMS & notification module (Flutter)
flask/             -> Flask backend (analytics, logs, trust engine)
README.txt         -> Project documentation


KEY FEATURES
------------
- Flutter-based banking applications
- Behavior-based trust score calculation
- Session logging and user profiling
- Fraud and anomaly detection
- Real-time decision engine (OTP / Logout / Challenge)
- Flask dashboard for session monitoring
- No hardcoded secrets (public-safe repository)


TRUST SCORE LOGIC (HIGH LEVEL)
-----------------------------
Trust score is calculated using:
- User interaction patterns (tap, swipe, navigation)
- Session behavior anomalies
- Historical user baseline profiles
- Optional ML model inference (TFLite)

Based on trust score:
- Normal access is allowed
- OTP verification may be triggered
- Security questions may be asked
- Forced logout in high-risk scenarios


FLASK BACKEND
-------------
The Flask backend handles:
- Session log ingestion
- User profile analysis
- Trust score computation
- Dashboard rendering

To run locally:
1. Open terminal
2. cd flask
3. pip install -r requirements.txt
4. python app.py


FLUTTER APPLICATIONS
--------------------
Each Flutter module can be run independently:

flutter pub get
flutter run

Supported platforms:
- Android
- iOS
- Web
- Windows
- macOS


SECURITY NOTES
--------------
- Secrets and API keys are not included
- macOS junk files and logs are ignored
- Repository is safe for public sharing


PROJECT STATUS
--------------
Active development
Academic / Research / Prototype project


AUTHOR
------
Moteesh A | Swaraj Kumar Sahu | Manya Singh | Nikhil T Nainan
Secure Systems | Mobile Security | Behavior Analytics
