from flask import Flask
from sys import stderr
import os
import subprocess
import threading
import time


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

    @staticmethod
    def have_changes():
        result = subprocess.run(['git', 'ls-files', '-m'], capture_output=True)
        return bool(result.stdout)

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

    def push(self):
        print('Pushing changes')
        self.lock.acquire()
        subprocess.run(['git', 'add', '.'])
        subprocess.run(['git', 'commit', '-a', '-m', 'fava snapshot'])
        subprocess.run(['git', 'push'])
        self.lock.release()


class FileMon(threading.Thread):
    def __init__(self, name, repo):
        threading.Thread.__init__(self)
        self.name = name
        self.repo = repo

    def run(self):
        while True:
            time.sleep(10)
            if self.repo.have_changes():
                print('Local changes detected. Commit timer started')
                time.sleep(900)
                self.repo.push()


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

    filemon = FileMon('filemon', repo)
    filemon.start()

    webhook.join()
    filemon.join()
