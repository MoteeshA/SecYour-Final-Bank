from flask import Flask, request, jsonify, render_template
from twilio.rest import Client

app = Flask(__name__)

# -----------------------------
# Twilio credentials
# -----------------------------
#id here

client = Client(account_sid, auth_token)


# -----------------------------
# Home page with form
# -----------------------------
@app.route("/")
def index():
    return render_template("index.html")


# -----------------------------
# API: Send OTP
# -----------------------------
@app.route("/send-otp", methods=["POST"])
def send_otp():
    phone = request.form.get("phone")

    if not phone:
        return "Phone number is required", 400

    try:
        verification = client.verify.services(verify_sid).verifications.create(
            to=phone,
            channel="sms"
        )
        return f"OTP sent to {phone}. Please go back and verify."
    except Exception as e:
        return f"Error: {str(e)}", 500


# -----------------------------
# API: Verify OTP
# -----------------------------
@app.route("/verify-otp", methods=["POST"])
def verify_otp():
    phone = request.form.get("phone")
    otp = request.form.get("otp")

    if not phone or not otp:
        return "Phone and OTP are required", 400

    try:
        verification_check = client.verify.services(verify_sid).verification_checks.create(
            to=phone,
            code=otp
        )
        if verification_check.status == "approved":
            return "✅ OTP verified successfully!"
        else:
            return "❌ Invalid or expired OTP."
    except Exception as e:
        return f"Error: {str(e)}", 500


if __name__ == "__main__":
    # Run on all IPs so it works on any WiFi/system
    app.run(host="0.0.0.0", port=5001, debug=True)
