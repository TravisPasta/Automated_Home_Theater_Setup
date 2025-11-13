from flask import Flask
import os
import platform
import subprocess

app = Flask(__name__)

@app.route('/shutdown', methods=['POST'])
def shutdown():
    system = platform.system().lower()
    if "windows" in system:
        os.system("shutdown /s /f /t 0")
    else:
        subprocess.run(["shutdown", "-h", "now"])
    return "Shutting down...", 200

@app.route('/restart', methods=['POST'])
def restart():
    system = platform.system().lower()
    if "windows" in system:
        os.system("shutdown /r /f /t 0")
    else:
        subprocess.run(["shutdown", "-r", "now"])
    return "Restarting...", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5050)
