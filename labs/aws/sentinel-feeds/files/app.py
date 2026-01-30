from flask import Flask, request, jsonify, render_template_string
import requests
import logging
from datetime import datetime

logging.basicConfig(filename='/var/log/sentinel.log', level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')

app = Flask(__name__)

TEMPLATE = '''<!DOCTYPE html>
<html>
<head>
<title>SENTINEL - Threat Intelligence Feed Aggregator</title>
<style>
body{font-family:'Courier New',monospace;background:#0a0a0a;color:#0f0;margin:0;padding:20px}
.container{max-width:1000px;margin:0 auto}
.header{border:2px solid #0f0;padding:20px;margin-bottom:20px;text-align:center}
.header h1{margin:0;color:#0f0}
.classification{background:#f00;color:#fff;padding:5px 15px;display:inline-block;font-weight:bold;margin-top:10px}
.section{border:1px solid #0f0;padding:20px;margin-bottom:20px}
.section h2{margin-top:0;border-bottom:1px solid #0f0;padding-bottom:10px}
input[type="text"]{width:70%;padding:10px;background:#1a1a1a;border:1px solid #0f0;color:#0f0;font-family:'Courier New',monospace}
button{padding:10px 20px;background:#030;border:1px solid #0f0;color:#0f0;cursor:pointer;font-family:'Courier New',monospace}
button:hover{background:#040}
.result{background:#1a1a1a;padding:15px;margin-top:15px;white-space:pre-wrap;word-wrap:break-word;max-height:400px;overflow-y:auto;border:1px solid #333}
.feed-list{list-style:none;padding:0}
.feed-list li{padding:5px 0;border-bottom:1px solid #333}
.status-active{color:#0f0}
.status-error{color:#f00}
.warning{background:#320;border:1px solid #f90;padding:10px;margin-bottom:20px;color:#f90}
</style>
</head>
<body>
<div class="container">
<div class="header">
<h1>█ SENTINEL █</h1>
<h2>Threat Intelligence Feed Aggregator</h2>
<div class="classification">SECRET // NOFORN</div>
</div>
<div class="warning">AUTHORIZED USE ONLY - All access is monitored and logged.</div>
<div class="section">
<h2>Feed Validation Tool</h2>
<p>Validate external threat intelligence feed URLs before adding to aggregation queue.</p>
<form id="validateForm">
<input type="text" id="feedUrl" name="url" placeholder="Enter feed URL to validate">
<button type="submit">Validate Feed</button>
</form>
<div id="result" class="result" style="display:none;"></div>
</div>
<div class="section">
<h2>Active Threat Feeds</h2>
<ul class="feed-list">
<li><span class="status-active">[ACTIVE]</span> CISA Known Exploited Vulnerabilities</li>
<li><span class="status-active">[ACTIVE]</span> FBI Flash Alerts</li>
<li><span class="status-active">[ACTIVE]</span> NSA Cybersecurity Advisories</li>
<li><span class="status-error">[ERROR]</span> Allied SIGINT Feed - Connection timeout</li>
</ul>
</div>
<div class="section">
<h2>System Status</h2>
<p>Aggregator Version: 2.4.1</p>
<p>Last Feed Sync: {{ timestamp }}</p>
<p>Indicators Processed (24h): 47,823</p>
</div>
</div>
<script>
document.getElementById('validateForm').addEventListener('submit',async function(e){
e.preventDefault();
const url=document.getElementById('feedUrl').value;
const resultDiv=document.getElementById('result');
resultDiv.style.display='block';
resultDiv.textContent='Validating feed...';
try{
const response=await fetch('/api/validate-feed?url='+encodeURIComponent(url));
const data=await response.json();
if(data.error){resultDiv.textContent='ERROR: '+data.error;}
else{resultDiv.textContent='Status: '+data.status_code+'\\n\\nResponse Preview:\\n'+data.content;}
}catch(err){resultDiv.textContent='ERROR: '+err.message;}
});
</script>
</body>
</html>'''

@app.route('/')
def index():
    return render_template_string(TEMPLATE, timestamp=datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC'))

@app.route('/api/validate-feed')
def validate_feed():
    url = request.args.get('url', '')
    if not url:
        return jsonify({'error': 'No URL provided'}), 400
    app.logger.info(f"Feed validation request: {url} from {request.remote_addr}")
    try:
        response = requests.get(url, timeout=10, allow_redirects=True)
        return jsonify({
            'url': url,
            'status_code': response.status_code,
            'content_type': response.headers.get('Content-Type', 'unknown'),
            'content': response.text[:5000]
        })
    except requests.exceptions.Timeout:
        return jsonify({'error': 'Connection timeout'}), 504
    except requests.exceptions.ConnectionError as e:
        return jsonify({'error': f'Connection failed: {str(e)}'}), 502
    except Exception as e:
        app.logger.error(f"Feed validation error: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health():
    return jsonify({'status': 'operational', 'version': '2.4.1'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
