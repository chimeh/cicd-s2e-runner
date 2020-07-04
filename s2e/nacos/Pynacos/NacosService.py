from Pynacos.func import *

"""
    配置服务的类
"""

class NacosService:
    def __init__(self, ip, port):
        self.ip = ip
        self.port = port

    # 创建服务
    def Add(self, serviceName, groupName = "", namespaceId = "", protectThreshold = 0, metadata = None, selector = ""):
        html = requests.post(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/service"),
            data = {
                "serviceName" : serviceName,
                "groupName" : groupName,
                "namespaceId" : namespaceId,
                "protectThreshold" : protectThreshold,
                "metadata" : json.dumps(metadata, ensure_ascii=False),
                "selector" : selector,
            }
        )
        if f"specified service already exists" in html.text:
            return True
        return check(html)

    # 移除服务
    def Delete(self, serviceName,
               groupName = "", namespaceId = ""):
        html = requests.delete(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/service"),
            data={
                "serviceName": serviceName,
                "groupName": groupName,
                "namespaceId": namespaceId,
            }
        )
        return check(html)

    # 修改服务
    def Put(self, serviceName,
            groupName = "", namespaceId = "", protectThreshold = 0, metadata = None, selector = {"type": "none"}, healthCheckMode = "client"):
        if "type" not in selector:
            selector["type"] = "none"
        html = requests.put(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/service"),
            params = {
                "serviceName" : serviceName,
                "groupName" : groupName,
                "namespaceId" : namespaceId,
                "protectThreshold" : protectThreshold,
                "metadata" : json.dumps(metadata, ensure_ascii=False),
                "selector" : json.dumps(selector, ensure_ascii=False),
                "healthCheckMode" : healthCheckMode
            }
        )
        return check(html)

    # 查询服务
    def Get(self, serviceName,
            groupName = "", namespaceId = ""):
        html = requests.get(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/service"),
            params = {
                "serviceName" : serviceName,
                "groupName" : groupName,
                "namespaceId" : namespaceId,
            }
        )
        return check(html)

    # 查询服务
    def List(self, pageNo = 1, pageSize = 10, groupName = "", namespaceId = ""):
        html = requests.get(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/service/list"),
            params={
                "pageNo": pageNo,
                "pageSize": pageSize,
                "groupName": groupName,
                "namespaceId": namespaceId,
            }
        )
        return check(html)
