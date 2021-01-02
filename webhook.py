from flask import Flask
from sys import stderr
import os
import subprocess

api = Flask(__name__)

@api.route('/', methods=['POST'])
def post_push():
    subprocess.run(['repo.sh', 'pull'])
    return ''

if __name__ == '__main__':
    api.run(host = '0.0.0.0', port = os.environ['WEBHOOK_PORT'])
