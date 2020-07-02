import requests
from Pynacos.func import *
from Pynacos.Err import Request_Err

"""
    读写配置的类，负责获取配置内容
"""

class NacosConfig:
    def __init__(self, ip, port, scheme):
        self.ip = ip
        self.port = port
        self.scheme = scheme

    # 获取配置
    def Get(self, data_id : str, group : str,
            tenant : str = "", to_json = True):
        html = requests.get(
            url = getUrl(self.ip, self.port, "/nacos/v1/cs/configs", scheme=self.scheme),
            params = {
                "tenant":tenant,
                "dataId":data_id,
                "group":group
            })
        return check(html, to_json)

    # 监听配置表，如果改变了则立即返回 True 否则会阻塞直到 timeout 返回 False
    def Listener(self, data_id : str, group : str, contentMD5 : str,
                 timeout : int = 30, tenant : str = ""):
        data = f"""{data_id}{u2}{group}{u2}{contentMD5}{u2}{tenant}{u1}"""
        html = requests.post(
            url = getUrl(self.ip, self.port, "/nacos/v1/cs/configs/listener", scheme= self.scheme),
            data = {"Listening-Configs":data},
            headers = {"Long-Pulling-Timeout":str(timeout * 1000)}
        )
        if check(html):
            return True
        return False
        
    # 发布配置  成功 True 失败 Flase
    def Put(self, data_id : str, group : str, content : str,
            tenant : str = "", type : str = ""):
        html = requests.post(
            url = getUrl(self.ip, self.port,  "/nacos/v1/cs/configs", scheme=self.scheme),
            data={
                "tenant": tenant,
                "dataId":data_id,
                "group":group,
                "content":content,
                "type":type,
            },
        )
        return bool(check(html))

    # 删除配置  成功 True 失败 Flase
    def Delete(self, data_id : str, group : str,
               tenant : str = ""):
        html = requests.delete(
            url = getUrl(self.ip, self.port, "/nacos/v1/cs/configs"),
            params={
                "tenant": tenant,
                "dataId": data_id,
                "group": group,
            }
        )
        return bool(check(html))
