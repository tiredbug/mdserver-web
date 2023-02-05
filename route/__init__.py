# coding:utf-8

import sys
import io
import os
import time
import shutil
import uuid
import traceback

from datetime import timedelta

from flask import Flask
from flask import render_template
from flask import make_response
from flask import Response
from flask import session
from flask import request
from flask import redirect
from flask import url_for
from flask import render_template_string, abort
from flask_caching import Cache
from flask_session import Session

sys.path.append(os.getcwd() + "/class/core")

import db
import slemp
import config_api

app = Flask(__name__, template_folder='templates/default')
app.config.version = config_api.config_api().getVersion()

cache = Cache(config={'CACHE_TYPE': 'simple'})
cache.init_app(app, config={'CACHE_TYPE': 'simple'})

try:
    from flask_sqlalchemy import SQLAlchemy
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////tmp/slemp_session.db'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = True
    app.config['SESSION_TYPE'] = 'sqlalchemy'
    app.config['SESSION_SQLALCHEMY'] = sdb
    app.config['SESSION_SQLALCHEMY_TABLE'] = 'session'
    sdb = SQLAlchemy(app)
    sdb.create_all()
except:
    app.config['SESSION_TYPE'] = 'filesystem'
    app.config['SESSION_FILE_DIR'] = '/tmp/py_slemp_session_' + \
        str(sys.version_info[0])
    app.config['SESSION_FILE_THRESHOLD'] = 1024
    app.config['SESSION_FILE_MODE'] = 384
    slemp.execShell("pip install flask_sqlalchemy &")

app.secret_key = uuid.UUID(int=uuid.getnode()).hex[-12:]
app.config['SESSION_PERMANENT'] = True
app.config['SESSION_USE_SIGNER'] = True
app.config['SESSION_KEY_PREFIX'] = 'SLEMP_:'
app.config['SESSION_COOKIE_NAME'] = "SLEMP_VER_1"
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(days=31)
# Session(app)

# socketio
from flask_socketio import SocketIO, emit, send
socketio = SocketIO()
socketio.init_app(app)

# debug macosx dev
if slemp.isAppleSystem():
    app.debug = True
    app.config.version = app.config.version + str(time.time())

import common
common.init()


def funConvert(fun):
    block = fun.split('_')
    func = block[0]
    for x in range(len(block) - 1):
        suf = block[x + 1].title()
        func += suf
    return func


def isLogined():
    # print('isLogined', session)
    if 'login' in session and 'username' in session and session['login'] == True:
        userInfo = slemp.M('users').where(
            "id=?", (1,)).field('id,username,password').find()
        if userInfo['username'] != session['username']:
            return False

        now_time = int(time.time())

        if 'overdue' in session and now_time > session['overdue']:
            session['overdue'] = int(time.time()) + 7 * 24 * 60 * 60
            return False

        return True

    if os.path.exists('data/api_login.txt'):
        content = slemp.readFile('data/api_login.txt')
        session['login'] = True
        session['username'] = content
        os.remove('data/api_login.txt')
    return False


def publicObject(toObject, func, action=None, get=None):
    name = funConvert(func) + 'Api'
    try:
        if hasattr(toObject, name):
            efunc = 'toObject.' + name + '()'
            data = eval(efunc)
            return data
        data = {'msg': '404,not find api[' + name + ']', "status": False}
        return slemp.getJson(data)
    except Exception as e:
        print(traceback.print_exc())
        data = {'msg': 'Access exception:' + str(e) + '!', "status": False}
        return slemp.getJson(data)


@app.route("/debug")
def debug():
    print(sys.version_info)
    print(session)
    os = slemp.getOs()
    print(os)
    return slemp.getLocalIp()


@app.route('/close')
def close():
    if not os.path.exists('data/close.pl'):
        return redirect('/')
    data = {}
    data['cmd'] = 'rm -rf ' + slemp.getRunDir() + '/data/close.pl'
    return render_template('close.html', data=data)


@app.route("/code")
def code():
    import vilidate
    vie = vilidate.vieCode()
    codeImage = vie.GetCodeImage(80, 4)

    out = io.BytesIO()
    codeImage[0].save(out, "png")

    session['code'] = slemp.md5(''.join(codeImage[1]).lower())

    img = Response(out.getvalue(), headers={'Content-Type': 'image/png'})
    return make_response(img)


@app.route("/check_login", methods=['POST'])
def checkLogin():
    if isLogined():
        return "true"
    return "false"


@app.route("/do_login", methods=['POST'])
def doLogin():
    username = request.form.get('username', '').strip()
    password = request.form.get('password', '').strip()
    code = request.form.get('code', '').strip()
    # print(session)
    if 'code' in session:
        if session['code'] != slemp.md5(code):
            return slemp.returnJson(False, 'Incorrect verification code, please re-enter!')

    userInfo = slemp.M('users').where(
        "id=?", (1,)).field('id,username,password').find()

    password = slemp.md5(password)

    login_cache_count = 5
    login_cache_limit = cache.get('login_cache_limit')
    filename = 'data/close.pl'
    if os.path.exists(filename):
        return slemp.returnJson(False, 'Panel is closed!')

    if userInfo['username'] != username or userInfo['password'] != password:
        msg = "<a style='color: red'>Incorrect password</a>, account: {1}, password: {2}, login IP: {3}", ((
            '****', '******', request.remote_addr))

        if login_cache_limit == None:
            login_cache_limit = 1
        else:
            login_cache_limit = int(login_cache_limit) + 1

        if login_cache_limit >= login_cache_count:
            slemp.writeFile(filename, 'True')
            return slemp.returnJson(False, 'Panel is closed!')

        cache.set('login_cache_limit', login_cache_limit, timeout=10000)
        login_cache_limit = cache.get('login_cache_limit')
        slemp.writeLog('User login', slemp.getInfo(msg))
        return slemp.returnJson(False, slemp.getInfo("Incorrect username or password, you can try [{1}] more times!", (str(login_cache_count - login_cache_limit))))

    cache.delete('login_cache_limit')
    session['login'] = True
    session['username'] = userInfo['username']
    session['overdue'] = int(time.time()) + 7 * 24 * 60 * 60

    slemp.writeFile('data/api_login.txt', userInfo['username'])
    return slemp.returnJson(True, 'Login berhasil, dialihkan...')


@app.errorhandler(404)
def page_unauthorized(error):
    return render_template_string('404 not found', error_info=error), 404


def get_admin_safe():
    path = 'data/admin_path.pl'
    if os.path.exists(path):
        cont = slemp.readFile(path)
        cont = cont.strip().strip('/')
        return (True, cont)
    return (False, '')


def admin_safe_path(path, req, data, pageFile):
    if path != req and not isLogined():
        return render_template('path.html')

    if not isLogined():
        return render_template('login.html', data=data)

    if not req in pageFile:
        return redirect('/')

    return render_template(req + '.html', data=data)


@app.route('/<reqClass>/<reqAction>', methods=['POST', 'GET'])
@app.route('/<reqClass>/', methods=['POST', 'GET'])
@app.route('/<reqClass>', methods=['POST', 'GET'])
@app.route('/', methods=['POST', 'GET'])
def index(reqClass=None, reqAction=None, reqData=None):

    comReturn = common.local()
    if comReturn:
        return comReturn

    if reqAction == None:
        import config_api
        data = config_api.config_api().get()

        if reqClass == None:
            reqClass = 'index'

        pageFile = ('config', 'control', 'crontab', 'files', 'firewall',
                    'index', 'plugins', 'login', 'system', 'site', 'ssl', 'task', 'soft')

        ainfo = get_admin_safe()

        if reqClass == 'login':
            dologin = request.args.get('dologin', '')
            if dologin == 'True':
                session.clear()
                session['login'] = False
                session['overdue'] = 0

            if ainfo[0]:
                return admin_safe_path(ainfo[1], reqClass, data, pageFile)

            return render_template('login.html', data=data)

        if ainfo[0]:
            return admin_safe_path(ainfo[1], reqClass, data, pageFile)

        if not reqClass in pageFile:
            return redirect('/')

        if not isLogined():
            return redirect('/login')

        return render_template(reqClass + '.html', data=data)

    if not isLogined():
        return 'request error!'

    classFile = ('config_api', 'crontab_api', 'files_api', 'firewall_api',
                 'plugins_api', 'system_api', 'site_api', 'task_api')
    className = reqClass + '_api'
    if not className in classFile:
        return "api request error"

    eval_str = "__import__('" + className + "')." + className + '()'
    newInstance = eval(eval_str)

    return publicObject(newInstance, reqAction)


##################### ssh  start ###########################
ssh = None
shell = None


def create_rsa():
    # slemp.execShell("rm -f /root/.ssh/*")
    if not os.path.exists('/root/.ssh/authorized_keys'):
        slemp.execShell('touch /root/.ssh/authorized_keys')

    if not os.path.exists('/root/.ssh/id_rsa.pub') and os.path.exists('/root/.ssh/id_rsa'):
        slemp.execShell(
            'echo y | ssh-keygen -q -t rsa -P "" -f /root/.ssh/id_rsa')
    else:
        slemp.execShell('ssh-keygen -q -t rsa -P "" -f /root/.ssh/id_rsa')

    slemp.execShell('cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys')
    slemp.execShell('chmod 600 /root/.ssh/authorized_keys')


def clear_ssh():
    ip = slemp.getHostAddr()
    sh = '''
#!/bin/bash
PLIST=`who | grep localhost | awk '{print $2}'`
for i in $PLIST
do
    ps -t /dev/$i |grep -v TTY | awk '{print $1}' | xargs kill -9
done

#getHostAddr
PLIST=`who | grep "${ip}" | awk '{print $2}'`
for i in $PLIST
do
    ps -t /dev/$i |grep -v TTY | awk '{print $1}' | xargs kill -9
done
'''
    if not slemp.isAppleSystem():
        info = slemp.execShell(sh)
        print(info[0], info[1])


def connect_ssh():
    # print 'connect_ssh ....'
    # clear_ssh()
    global shell, ssh
    if not os.path.exists('/root/.ssh/id_rsa') or not os.path.exists('/root/.ssh/id_rsa.pub'):
        create_rsa()

    data = slemp.execShell("cat /root/.ssh/id_rsa.pub | awk '{print $3}'")
    if data[0] != "":
        ak_data = slemp.execShell(
            "cat /root/.ssh/authorized_keys | grep " + data[0])
        if ak_data[0] == "":
            slemp.execShell(
                'cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys')
            slemp.execShell('chmod 600 /root/.ssh/authorized_keys')

    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        ssh.connect(slemp.getHostAddr(), slemp.getSSHPort(), timeout=5)
    except Exception as e:
        ssh.connect('127.0.0.1', slemp.getSSHPort())
    except Exception as e:
        ssh.connect('localhost', slemp.getSSHPort())
    except Exception as e:
        return False

    shell = ssh.invoke_shell(term='xterm', width=83, height=21)
    shell.setblocking(0)
    return True

def get_input_data(data):
    pdata = common.dict_obj()
    for key in data.keys():
        pdata[key] = str(data[key])
    return pdata


@socketio.on('webssh')
def webssh(msg):
    # print('webssh ...')
    if not isLogined():
        emit('server_response', {'data': 'Session lost, please re-login to the panel!\r\n'})
        return None
    global shell, ssh
    ssh_success = True
    if not shell:
        ssh_success = connect_ssh()
    if not shell:
        emit('server_response', {'data': 'Failed to connect to SSH service!\r\n'})
        return
    if shell.exit_status_ready():
        ssh_success = connect_ssh()
    if not ssh_success:
        emit('server_response', {'data': 'Failed to connect to SSH service!\r\n'})
        return
    shell.send(msg)
    try:
        time.sleep(0.005)
        recv = shell.recv(4096)
        emit('server_response', {'data': recv.decode("utf-8")})
    except Exception as ex:
        pass
        # print 'webssh:' + str(ex)


@socketio.on('connect_event')
def connected_msg(msg):
    if not isLogined():
        emit('server_response', {'data': 'Session lost, please re-login to the panel!\r\n'})
        return None
    global shell, ssh
    ssh_success = True
    if not shell:
        ssh_success = connect_ssh()
        # print(ssh_success)
    if not ssh_success:
        emit('server_response', {'data': 'Failed to connect to SSH service!\r\n'})
        return
    try:
        recv = shell.recv(8192)
        # print recv.decode("utf-8")
        emit('server_response', {'data': recv.decode("utf-8")})
    except Exception as e:
        pass
        # print 'connected_msg:' + str(e)


if not slemp.isAppleSystem():
    try:
        import paramiko
        ssh = paramiko.SSHClient()

        # connect_ssh()
    except Exception as e:
        print("The local terminal cannot be used")


##################### ssh  end ###########################
