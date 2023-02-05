# coding:utf-8

import sys
import io
import os
import time
import re
import json

sys.path.append(os.getcwd() + "/class/core")
import mw
import site_api

app_debug = False
if mw.isAppleSystem():
    app_debug = True


def getPluginName():
    return 'phpmyadmin'


def getPluginDir():
    return mw.getPluginDir() + '/' + getPluginName()


def getServerDir():
    return mw.getServerDir() + '/' + getPluginName()


def getArgs():
    args = sys.argv[2:]
    tmp = {}
    args_len = len(args)

    if args_len == 1:
        t = args[0].strip('{').strip('}')
        t = t.split(':')
        tmp[t[0]] = t[1]
    elif args_len > 1:
        for i in range(len(args)):
            t = args[i].split(':')
            tmp[t[0]] = t[1]

    return tmp


def checkArgs(data, ck=[]):
    for i in range(len(ck)):
        if not ck[i] in data:
            return (False, mw.returnJson(False, '参数:(' + ck[i] + ')没有!'))
    return (True, mw.returnJson(True, 'ok'))


def getConf():
    return mw.getServerDir() + '/web_conf/nginx/vhost/phpmyadmin.conf'


def getConfInc():
    return getServerDir() + "/" + getCfg()['path'] + '/config.inc.php'


def getPort():
    file = getConf()
    content = mw.readFile(file)
    rep = 'listen\s*(.*);'
    tmp = re.search(rep, content)
    return tmp.groups()[0].strip()


def getHomePage():
    try:
        port = getPort()
        ip = '127.0.0.1'
        if not mw.isAppleSystem():
            ip = mw.getLocalIp()
        url = 'http://' + ip + ':' + port + \
            '/' + getCfg()['path'] + '/index.php'
        return mw.returnJson(True, 'OK', url)
    except Exception as e:
        return mw.returnJson(False, '插件未启动!')


def getPhpVer(expect=55):
    v = site_api.site_api().getPhpVersion()
    is_find = False
    for i in range(len(v)):
        t = str(v[i]['version'])
        if (t == expect):
            is_find = True
            return str(t)
    if not is_find:
        if len(v) > 1:
            return v[1]['version']
        return v[0]['version']
    return str(expect)


def getCachePhpVer():
    cacheFile = getServerDir() + '/php.pl'
    v = ''
    if os.path.exists(cacheFile):
        v = mw.readFile(cacheFile)
    else:
        v = getPhpVer()
        mw.writeFile(cacheFile, v)
    return v


def contentReplace(content):
    service_path = mw.getServerDir()
    php_ver = getCachePhpVer()
    tmp = mw.execShell(
        'cat /dev/urandom | head -n 32 | md5sum | head -c 16')
    blowfish_secret = tmp[0].strip()
    # print php_ver
    php_conf_dir = mw.getServerDir() + '/web_conf/php/conf'
    content = content.replace('{$ROOT_PATH}', mw.getRootDir())
    content = content.replace('{$SERVER_PATH}', service_path)
    content = content.replace('{$PHP_CONF_PATH}', php_conf_dir)
    content = content.replace('{$PHP_VER}', php_ver)
    content = content.replace('{$BLOWFISH_SECRET}', blowfish_secret)

    cfg = getCfg()

    if cfg['choose'] == "mysql":
        content = content.replace('{$CHOOSE_DB}', 'mysql')
        content = content.replace('{$CHOOSE_DB_DIR}', 'mysql')
    elif cfg['choose'] == "mysql-apt":
        content = content.replace('{$CHOOSE_DB}', 'mysql')
        content = content.replace('{$CHOOSE_DB_DIR}', 'mysql-apt')
    elif cfg['choose'] == "mysql-yum":
        content = content.replace('{$CHOOSE_DB}', 'mysql')
        content = content.replace('{$CHOOSE_DB_DIR}', 'mysql-yum')
    else:
        content = content.replace('{$CHOOSE_DB}', 'MariaDB')
        content = content.replace('{$CHOOSE_DB_DIR}', 'mariadb')

    content = content.replace('{$PMA_PATH}', cfg['path'])

    port = cfg["port"]
    rep = 'listen\s*(.*);'
    content = re.sub(rep, "listen " + port + ';', content)
    return content


def initCfg():
    cfg = getServerDir() + "/cfg.json"
    if not os.path.exists(cfg):
        data = {}
        data['port'] = '888'
        data['choose'] = 'mysql'
        data['path'] = ''
        data['username'] = 'admin'
        data['password'] = 'admin'
        mw.writeFile(cfg, json.dumps(data))


def setCfg(key, val):
    cfg = getServerDir() + "/cfg.json"
    data = mw.readFile(cfg)
    data = json.loads(data)
    data[key] = val
    mw.writeFile(cfg, json.dumps(data))


def getCfg():
    cfg = getServerDir() + "/cfg.json"
    data = mw.readFile(cfg)
    data = json.loads(data)
    return data


def returnCfg():
    cfg = getServerDir() + "/cfg.json"
    data = mw.readFile(cfg)
    return data


def status():
    conf = getConf()
    conf_inc = getServerDir() + "/" + getCfg()["path"] + '/config.inc.php'
    # 两个文件都在，才算启动成功
    if os.path.exists(conf) and os.path.exists(conf_inc):
        return 'start'
    return 'stop'


def start():
    initCfg()

    pma_dir = getServerDir() + "/phpmyadmin"
    if os.path.exists(pma_dir):
        rand_str = mw.getRandomString(6)
        rand_str = rand_str.lower()
        pma_dir_dst = pma_dir + "_" + rand_str
        mw.execShell("mv " + pma_dir + " " + pma_dir_dst)
        setCfg('path', 'phpmyadmin_' + rand_str)

    file_tpl = getPluginDir() + '/conf/phpmyadmin.conf'
    file_run = getConf()
    if not os.path.exists(file_run):
        centent = mw.readFile(file_tpl)
        centent = contentReplace(centent)
        mw.writeFile(file_run, centent)

    pma_path = getServerDir() + '/pma.pass'
    if not os.path.exists(pma_path):
        username = mw.getRandomString(10)
        pass_cmd = username + ':' + mw.hasPwd(username)
        setCfg('username', username)
        setCfg('password', username)
        mw.writeFile(pma_path, pass_cmd)

    tmp = getServerDir() + "/" + getCfg()["path"] + '/tmp'
    if not os.path.exists(tmp):
        os.mkdir(tmp)
        mw.execShell("chown -R www:www " + tmp)

    conf_run = getServerDir() + "/" + getCfg()["path"] + '/config.inc.php'
    if not os.path.exists(conf_run):
        conf_tpl = getPluginDir() + '/conf/config.inc.php'
        centent = mw.readFile(conf_tpl)
        centent = contentReplace(centent)
        mw.writeFile(conf_run, centent)

    log_a = accessLog()
    log_e = errorLog()

    for i in [log_a, log_e]:
        if os.path.exists(i):
            cmd = "echo '' > " + i
            mw.execShell(cmd)

    mw.restartWeb()
    return 'ok'


def stop():
    conf = getConf()
    if os.path.exists(conf):
        os.remove(conf)
    mw.restartWeb()
    return 'ok'


def restart():
    return start()


def reload():
    file_tpl = getPluginDir() + '/conf/phpmyadmin.conf'
    file_run = getConf()
    if os.path.exists(file_run):
        centent = mw.readFile(file_tpl)
        centent = contentReplace(centent)
        mw.writeFile(file_run, centent)
    return start()


def setPhpVer():
    args = getArgs()

    if not 'phpver' in args:
        return 'phpver missing'

    cacheFile = getServerDir() + '/php.pl'
    mw.writeFile(cacheFile, args['phpver'])

    file_tpl = getPluginDir() + '/conf/phpmyadmin.conf'
    file_run = getConf()

    content = mw.readFile(file_tpl)
    content = contentReplace(content)
    mw.writeFile(file_run, content)

    mw.restartWeb()
    return 'ok'


def getSetPhpVer():
    cacheFile = getServerDir() + '/php.pl'
    if os.path.exists(cacheFile):
        return mw.readFile(cacheFile).strip()
    return ''


def getPmaOption():
    data = getCfg()
    return mw.returnJson(True, 'ok', data)


def getPmaPort():
    try:
        port = getPort()
        return mw.returnJson(True, 'OK', port)
    except Exception as e:
        # print(e)
        return mw.returnJson(False, '插件未启动!')


def setPmaPort():
    args = getArgs()
    data = checkArgs(args, ['port'])
    if not data[0]:
        return data[1]

    port = args['port']
    if port == '80':
        return mw.returnJson(False, '80端不能使用!')

    file = getConf()
    if not os.path.exists(file):
        return mw.returnJson(False, '插件未启动!')
    content = mw.readFile(file)
    rep = 'listen\s*(.*);'
    content = re.sub(rep, "listen " + port + ';', content)
    mw.writeFile(file, content)

    setCfg("port", port)
    mw.restartWeb()
    return mw.returnJson(True, '修改成功!')


def setPmaChoose():
    args = getArgs()
    data = checkArgs(args, ['choose'])
    if not data[0]:
        return data[1]

    choose = args['choose']
    setCfg('choose', choose)

    pma_path = getCfg()['path']
    conf_run = getServerDir() + "/" + pma_path + '/config.inc.php'

    conf_tpl = getPluginDir() + '/conf/config.inc.php'
    content = mw.readFile(conf_tpl)
    content = contentReplace(content)
    mw.writeFile(conf_run, content)

    mw.restartWeb()
    return mw.returnJson(True, '修改成功!')


def setPmaUsername():
    args = getArgs()
    data = checkArgs(args, ['username'])
    if not data[0]:
        return data[1]

    username = args['username']
    setCfg('username', username)

    cfg = getCfg()
    pma_path = getServerDir() + '/pma.pass'
    username = mw.getRandomString(10)
    pass_cmd = cfg['username'] + ':' + mw.hasPwd(cfg['password'])
    mw.writeFile(pma_path, pass_cmd)

    mw.restartWeb()
    return mw.returnJson(True, '修改成功!')


def setPmaPassword():
    args = getArgs()
    data = checkArgs(args, ['password'])
    if not data[0]:
        return data[1]

    password = args['password']
    setCfg('password', password)

    cfg = getCfg()
    pma_path = getServerDir() + '/pma.pass'
    username = mw.getRandomString(10)
    pass_cmd = cfg['username'] + ':' + mw.hasPwd(cfg['password'])
    mw.writeFile(pma_path, pass_cmd)

    mw.restartWeb()
    return mw.returnJson(True, '修改成功!')


def setPmaPath():
    args = getArgs()
    data = checkArgs(args, ['path'])
    if not data[0]:
        return data[1]

    path = args['path']

    if len(path) < 5:
        return mw.returnJson(False, '不能小于5位!')

    old_path = getServerDir() + "/" + getCfg()['path']
    new_path = getServerDir() + "/" + path

    mw.execShell("mv " + old_path + " " + new_path)
    setCfg('path', path)
    return mw.returnJson(True, '修改成功!')


def accessLog():
    return getServerDir() + '/access.log'


def errorLog():
    return getServerDir() + '/error.log'


def Version():
    return mw.readFile(getServerDir() + '/version.pl')


if __name__ == "__main__":
    func = sys.argv[1]
    if func == 'status':
        print(status())
    elif func == 'start':
        print(start())
    elif func == 'stop':
        print(stop())
    elif func == 'restart':
        print(restart())
    elif func == 'reload':
        print(reload())
    elif func == 'conf':
        print(getConf())
    elif func == 'version':
        print(Version())
    elif func == 'get_cfg':
        print(returnCfg())
    elif func == 'config_inc':
        print(getConfInc())
    elif func == 'get_home_page':
        print(getHomePage())
    elif func == 'set_php_ver':
        print(setPhpVer())
    elif func == 'get_set_php_ver':
        print(getSetPhpVer())
    elif func == 'get_pma_port':
        print(getPmaPort())
    elif func == 'set_pma_port':
        print(setPmaPort())
    elif func == 'get_pma_option':
        print(getPmaOption())
    elif func == 'set_pma_choose':
        print(setPmaChoose())
    elif func == 'set_pma_username':
        print(setPmaUsername())
    elif func == 'set_pma_password':
        print(setPmaPassword())
    elif func == 'set_pma_path':
        print(setPmaPath())
    elif func == 'access_log':
        print(accessLog())
    elif func == 'error_log':
        print(errorLog())
    else:
        print('error')
