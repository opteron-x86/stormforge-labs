#!/bin/bash
set -e

dnf update -y
dnf install -y python3 python3-pip at

pip3 install flask requests boto3

cat > /home/ec2-user/app.py << 'PYAPP'
from flask import Flask, request, jsonify
import requests
import boto3

app = Flask(__name__)

@app.route('/')
def index():
    return '''
    <h1>URL Inspector Service</h1>
    <p>Internal tool for checking URL accessibility</p>
    <form action="/check" method="get">
        <input type="text" name="url" placeholder="Enter URL to check" size="50">
        <input type="submit" value="Check URL">
    </form>
    '''

@app.route('/check')
def check_url():
    url = request.args.get('url')
    if not url:
        return jsonify({'error': 'No URL provided'}), 400
    
    try:
        response = requests.get(url, timeout=5)
        return jsonify({
            'url': url,
            'status_code': response.status_code,
            'content_preview': response.text[:2000]
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health():
    return 'OK'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
PYAPP

cat > /etc/systemd/system/webapp.service << 'SYSD'
[Unit]
Description=URL Inspector Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user
ExecStart=/usr/bin/python3 /home/ec2-user/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SYSD

systemctl daemon-reload
systemctl enable webapp
systemctl start webapp

echo "Configuration note: Data processor role ARN: ${data_processor_role}" >> /var/log/application-setup.log

systemctl enable atd
systemctl start atd
echo "sudo shutdown -h +240" | at now