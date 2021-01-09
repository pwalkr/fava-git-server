from flask import Flask
from sys import stderr
import os
import subprocess
import threading


class Repository():
    def __init__(self):
        self.lock = threading.Lock()
        self.upstream = None

    def init_upstream(self):
        #results = subprocess.run(['git', 'rev-parse', '--abbrev-ref', '@{upstream}'], capture_output=True)
        #self.upstream = results.stdout.strip()
        self.upstream = self.rev_parse('@{upstream}', ['--abbrev-ref'])
        print("Got upstream '{}'".format(self.upstream))

    @staticmethod
    def rev_parse(ref, args=[]):
        command = ['git', 'rev-parse'] + args + [ref]
        result = subprocess.run(command, capture_output=True)
        return result.stdout.strip()

    def pull(self):
        print('Received push notification. Pulling updates')
        self.lock.acquire()
        subprocess.run(['git', 'fetch', '-p'])
        local = self.rev_parse('HEAD')
        remote = self.rev_parse(self.upstream)
        if local == remote:
            self.lock.release()
            print('Nothing to pull')
            return
        subprocess.run(['git', 'clean', '-dfx'])
        subprocess.run(['git', 'reset', '--hard', self.upstream])
        self.lock.release()


class Webhook(threading.Thread):
    def __init__(self, name, app, port):
        threading.Thread.__init__(self)
        self.name = name
        self.app = app
        self.port = port

    def run(self):
        self.app.run(host = '0.0.0.0', port = self.port)


app = Flask(__name__)
repo = Repository()

@app.route('/', methods=['POST'])
def post_push():
    repo.pull()
    return ''

if __name__ == '__main__':
    os.chdir(os.environ['REPOSITORY_ROOT'])

    repo.init_upstream()

    webhook = Webhook('webhook', app, os.environ['WEBHOOK_PORT'])
    webhook.start()
    webhook.join()
