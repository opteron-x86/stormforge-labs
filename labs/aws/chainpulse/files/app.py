from flask import Flask, request, jsonify, render_template_string
import requests
import logging
from datetime import datetime

logging.basicConfig(filename='/var/log/chainpulse.log', level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')

app = Flask(__name__)

TEMPLATE = '''<!DOCTYPE html>
<html>
<head>
<title>ChainPulse - Price Oracle Aggregator</title>
<style>
body{font-family:'Inter',sans-serif;background:#0d0d0d;color:#e0e0e0;margin:0;padding:20px}
.container{max-width:1000px;margin:0 auto}
.header{border:2px solid #f7931a;padding:20px;margin-bottom:20px;text-align:center;background:linear-gradient(180deg,#1a1a1a 0%,#0d0d0d 100%)}
.header h1{margin:0;color:#f7931a;font-size:2.5em;letter-spacing:2px}
.header h2{color:#888;font-weight:normal;margin-top:5px}
.badge{background:#f7931a;color:#000;padding:5px 15px;display:inline-block;font-weight:bold;margin-top:10px;border-radius:3px;font-size:0.8em}
.section{border:1px solid #333;padding:20px;margin-bottom:20px;background:#1a1a1a;border-radius:8px}
.section h2{margin-top:0;border-bottom:1px solid #333;padding-bottom:10px;color:#f7931a}
input[type="text"]{width:70%;padding:12px;background:#0d0d0d;border:1px solid #444;color:#e0e0e0;font-family:inherit;border-radius:4px}
input[type="text"]:focus{outline:none;border-color:#f7931a}
button{padding:12px 24px;background:#f7931a;border:none;color:#000;cursor:pointer;font-family:inherit;font-weight:bold;border-radius:4px;margin-left:10px}
button:hover{background:#ffa940}
.result{background:#0d0d0d;padding:15px;margin-top:15px;white-space:pre-wrap;word-wrap:break-word;max-height:400px;overflow-y:auto;border:1px solid #333;border-radius:4px;font-family:'Courier New',monospace;font-size:0.9em}
.feed-list{list-style:none;padding:0}
.feed-list li{padding:10px;border-bottom:1px solid #222;display:flex;justify-content:space-between;align-items:center}
.feed-list li:last-child{border-bottom:none}
.status-active{color:#00c853;font-weight:bold}
.status-error{color:#ff5252;font-weight:bold}
.status-pending{color:#ffd740;font-weight:bold}
.warning{background:#1a1200;border:1px solid #f7931a;padding:15px;margin-bottom:20px;color:#ffd740;border-radius:4px;font-size:0.9em}
.stats{display:grid;grid-template-columns:repeat(3,1fr);gap:15px;margin-top:15px}
.stat-box{background:#0d0d0d;padding:15px;border-radius:4px;text-align:center}
.stat-value{font-size:1.5em;color:#f7931a;font-weight:bold}
.stat-label{color:#888;font-size:0.8em;margin-top:5px}
.price{font-family:'Courier New',monospace;color:#00c853}
</style>
</head>
<body>
<div class="container">
<div class="header">
<h1>⛓ CHAINPULSE</h1>
<h2>Decentralized Price Oracle Aggregator</h2>
<div class="badge">INSTITUTIONAL TRADING</div>
</div>
<div class="section">
<h2>Oracle Feed Validator</h2>
<p>Validate external price oracle endpoints before adding to the aggregation pool</p>
<form id="validateForm">
<input type="text" id="feedUrl" name="url" placeholder="Enter oracle endpoint URL to validate">
<button type="submit">Validate Oracle</button>
</form>
<div id="result" class="result" style="display:none;"></div>
</div>
<div class="section">
<h2>Active Price Oracles</h2>
<ul class="feed-list">
<li><span class="status-active">[LIVE]</span> Chainlink ETH/USD <span class="price">$3,247.82</span></li>
<li><span class="status-active">[LIVE]</span> Pyth BTC/USD <span class="price">$97,432.15</span></li>
<li><span class="status-active">[LIVE]</span> Band Protocol SOL/USD <span class="price">$142.67</span></li>
<li><span class="status-pending">[SYNC]</span> Uniswap V3 TWAP - Calculating...</li>
<li><span class="status-error">[FAIL]</span> Custom Oracle #7 - Signature verification failed</li>
</ul>
</div>
<div class="section">
<h2>System Metrics</h2>
<div class="stats">
<div class="stat-box"><div class="stat-value">$847M</div><div class="stat-label">24h Volume</div></div>
<div class="stat-box"><div class="stat-value">12,847</div><div class="stat-label">Trades Executed</div></div>
<div class="stat-box"><div class="stat-value">99.97%</div><div class="stat-label">Oracle Uptime</div></div>
</div>
<p style="margin-top:15px;color:#666;font-size:0.85em">Aggregator v3.2.1 | Last sync: {{ timestamp }} | Median deviation: 0.02%</p>
</div>
</div>
<script>
document.getElementById('validateForm').addEventListener('submit',async function(e){
e.preventDefault();
const url=document.getElementById('feedUrl').value;
const resultDiv=document.getElementById('result');
resultDiv.style.display='block';
resultDiv.textContent='Validating oracle endpoint...';
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
    app.logger.info(f"Oracle validation request: {url} from {request.remote_addr}")
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
        app.logger.error(f"Oracle validation error: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health():
    return jsonify({'status': 'operational', 'version': '3.2.1'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)