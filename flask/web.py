from flask import Flask, render_template, jsonify, request
import os
import json
import threading
import time
import subprocess
from datetime import datetime

app = Flask(__name__)

# ✅ Paths
LOG_DIR = "session_logs"
DEVICE_PATH = "/sdcard/Download/PhishSafe"

# Ensure the session_logs folder exists
os.makedirs(LOG_DIR, exist_ok=True)


def log_message(message):
    """Helper function for logging with timestamps"""
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {message}")


# ✅ Background thread (ADB sync)
def auto_sync_logs():
    log_message("Starting ADB sync thread...")
    while True:
        try:
            result = subprocess.run(
                ["adb", "shell", "ls", DEVICE_PATH],
                capture_output=True,
                text=True
            )

            if result.returncode == 0:
                device_files = [f for f in result.stdout.strip().split("\n") if f.endswith(".json")]
                log_message(f"Found {len(device_files)} log files on device")

                for device_file in device_files:
                    dest_file = os.path.join(LOG_DIR, device_file)

                    # 🔄 Always replace user_profile.json
                    if device_file == "user_profile.json":
                        log_message("🔄 Updating user_profile.json...")
                        pull_result = subprocess.run(
                            ["adb", "pull", f"{DEVICE_PATH}/{device_file}", dest_file],
                            capture_output=True,
                            text=True
                        )
                        if pull_result.returncode == 0:
                            log_message("✅ user_profile.json synced")
                        else:
                            log_message(f"❌ Failed to sync user_profile.json: {pull_result.stderr}")
                        continue

                    # ✅ For session logs, avoid duplicates
                    if not os.path.exists(dest_file):
                        log_message(f"New session log detected: {device_file} - attempting pull...")
                        pull_result = subprocess.run(
                            ["adb", "pull", f"{DEVICE_PATH}/{device_file}", dest_file],
                            capture_output=True,
                            text=True
                        )
                        if pull_result.returncode == 0:
                            log_message(f"✅ Successfully pulled {device_file}")
                        else:
                            log_message(f"❌ Failed to pull {device_file}: {pull_result.stderr}")
            else:
                log_message(f"❌ ADB ls command failed: {result.stderr}")

        except Exception as e:
            log_message(f"❌ Error during ADB sync: {str(e)}")

        time.sleep(5)


# ✅ Flask routes
@app.route('/')
def index():
    return render_template('dashboard.html')


@app.route('/logs')
def list_logs():
    logs = []
    profile = {}

    try:
        log_files = sorted(
            [f for f in os.listdir(LOG_DIR) if f.endswith(".json")],
            key=lambda x: os.path.getmtime(os.path.join(LOG_DIR, x)),
            reverse=True
        )

        for fname in log_files:
            file_path = os.path.join(LOG_DIR, fname)

            try:
                with open(file_path) as f:
                    file_content = json.load(f)

                    if fname == "user_profile.json":
                        profile = file_content
                        log_message("✅ Loaded user_profile.json")
                    else:
                        logs.append({
                            "filename": fname,
                            "content": file_content,
                            "mtime": os.path.getmtime(file_path)
                        })
                        log_message(f"✅ Loaded log file: {fname}")

            except json.JSONDecodeError as je:
                log_message(f"⚠️ JSON decode error in {fname}: {str(je)}")
            except Exception as e:
                log_message(f"⚠️ Error processing {fname}: {str(e)}")

    except Exception as e:
        log_message(f"❌ Error listing logs: {str(e)}")
        return jsonify({"error": str(e)}), 500

    return jsonify({"profile": profile, "logs": logs})


# ✅ Upload endpoint (works with Dart ExportManager.uploadToServer)
@app.route('/upload', methods=['POST'])
def upload_log():
    if 'file' not in request.files:
        return jsonify({"error": "No file part in request"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    if file and file.filename.endswith('.json'):
        filename = file.filename
        save_path = os.path.join(LOG_DIR, filename)

        # Avoid overwriting session logs, but always replace profile
        if filename != "user_profile.json":
            base_name, ext = os.path.splitext(filename)
            counter = 1
            while os.path.exists(save_path):
                save_path = os.path.join(LOG_DIR, f"{base_name}_{counter}{ext}")
                counter += 1

        try:
            file.save(save_path)
            log_message(f"✅ Uploaded log saved: {save_path}")
            return jsonify({"message": "File uploaded successfully"}), 200
        except Exception as e:
            log_message(f"❌ Failed to save uploaded file: {str(e)}")
            return jsonify({"error": "Failed to save file"}), 500

    return jsonify({"error": "Invalid file type. Must be .json"}), 400


# ✅ Start Flask + optional ADB Sync thread
if __name__ == '__main__':
    log_message("🚀 Starting PhishSafe Analytics Server")

    # Start background sync thread
    sync_thread = threading.Thread(target=auto_sync_logs, daemon=True)
    sync_thread.start()
    log_message(f"🔁 Sync thread running: {sync_thread.is_alive()}")

    app.run(host='0.0.0.0', port=5020)
