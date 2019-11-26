import os.path
import logging
import sys
from hashlib import md5
from Pynacos.Err import Request_Err
try:
    import fcntl

    use_fcntl = True
except:
    use_fcntl = False

# unicode char (1) char(2)
u1 = u'\x01'
u2 = u'\x02'


# 检查网页状态的方法
def check(html, json = True):
    if html.status_code == 200:
        if html.text == "ok":
            return html
        if json:
            try:
                return html.json()
            except:
                pass
        return html
    else:
        return html


# 拼接链接的方法
def getUrl(ip, port, more, scheme = "http"):
    if ip == None:
        return f"{more}"
    else:
        return f"{scheme}://{ip}:{port}{more}"
def getMD5(txt):
    return md5(str(txt).encode("utf-8")).hexdigest()


logger = logging.getLogger("nacos")


def read_file_str(base, key):
    content = read_file(base, key)
    return content.decode("UTF-8") if type(content) == bytes else content


def read_file(base, key):
    file_path = os.path.join(base, key)
    if not os.path.exists(file_path):
        return None

    try:
        if sys.version_info[0] == 3:
            with open(file_path, "r+", encoding="UTF-8", newline="") as f:
                lock_file(f)
                return f.read()
        else:
            with open(file_path, "r+") as f:
                lock_file(f)
                return f.read()
    except OSError:
        print("[read-file] read file failed, file path:%s" % file_path)
        return None


def save_file(base, key, content):
    file_path = os.path.join(base, key)
    if not os.path.isdir(base):
        try:
            os.makedirs(base)
        except OSError:
            print("[save-file] dir %s is already exist" % base)

    try:
        with open(file_path, "wb") as f:
            lock_file(f)
            f.write(content if type(content) == bytes else content.encode("UTF-8"))

    except OSError:
        print("[save-file] save file failed, file path:%s" % file_path)


def delete_file(base, key):
    file_path = os.path.join(base, key)
    try:
        os.remove(file_path)
    except OSError:
        print("[delete-file] file not exists, file path:%s" % file_path)


def lock_file(f):
    if use_fcntl:
        fcntl.flock(f, fcntl.LOCK_EX)