from Pynacos.func import *

"""
    配置实例的类
"""

class NacosInstance:
    def __init__(self, ip, port):
        self.ip = ip
        self.port = port

    # 注册实例
    def Add(self, serviceName : str,
                 namespaceId = "", weight = "", enabled = "", healthy = "", metadata = "", clusterName = "", groupName = "", ephemeral = ""):
        html = requests.post(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/instance"),
            params={
            "ip" : self.ip,
            "port" : self.port,
            "serviceName" : serviceName,
            "namespaceId" : namespaceId,
            "weight" : weight,
            "enabled" : enabled,
            "healthy" : healthy,
            "metadata" : metadata,
            "clusterName" : clusterName,
            "groupName" : groupName,
            "ephemeral" : ephemeral,
        })
        return check(html)

    # 删除实例
    def Delete(self, serviceName: str,
                 namespaceId="", clusterName="", groupName="", ephemeral=""):
        html = requests.delete(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/instance"),
            params={
            "ip": self.ip,
            "port": self.port,
            "serviceName": serviceName,
            "namespaceId": namespaceId,
            "clusterName": clusterName,
            "groupName": groupName,
            "ephemeral": ephemeral,
        })
        return check(html)

    # 修改实例
    def Put(self, serviceName : str,
                 namespaceId = "", weight = "", enabled = "", metadata = "", clusterName = "", groupName = "", ephemeral = ""):
        html = requests.put(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/instance"),
            params={
                "ip": self.ip,
                "port": self.port,
                "serviceName": serviceName,
                "namespaceId": namespaceId,
                "weight": weight,
                "enabled": enabled,
                "metadata": metadata,
                "clusterName": clusterName,
                "groupName": groupName,
                "ephemeral": ephemeral,
            })
        return check(html)

    # 查询实例状态
    def List(self, serviceName,
             groupName = "", namespaceId = "", clusters = "", healthyOnly : bool = False):
        html = requests.get(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/instance/list"),
            params={
                "ip": self.ip,
                "port": self.port,
                "serviceName": serviceName,
                "namespaceId": namespaceId,
                "clusters": clusters,
                "healthyOnly": healthyOnly,
                "groupName": groupName,
            })
        return check(html)

    # 查询实例状态
    def Get(self, serviceName,
             groupName = "", namespaceId = "", clusters = "", healthyOnly : bool = False, ephemeral : bool = False):
        html = requests.get(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/instance"),
            params={
                "ip": self.ip,
                "port": self.port,
                "serviceName": serviceName,
                "namespaceId": namespaceId,
                "clusters": clusters,
                "healthyOnly": healthyOnly,
                "groupName": groupName,
                "ephemeral" : ephemeral,
            })
        return check(html)

    # 发送心跳包
    def Beat(self, serviceName,
             groupName = "", ephemeral = False, cluster = "", metadata = None, scheduled = True, weight = 1, hold = 0):
        html = requests.put(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/instance/beat"),
            params={
                "serviceName": serviceName,
                "beat" : json.dumps(
                    {
                        "cluster" : cluster,
                        "ip" : self.ip,
                        "metadata" : metadata,
                        "port" : self.port,
                        "scheduled" : scheduled,
                        "serviceName" : serviceName,
                        "weight" : weight
                    },
                    ensure_ascii=False
                ),
                "groupName": groupName,
                "ephemeral": ephemeral,
            })
        sleep(hold / 1000)
        return check(html)

if __name__ == '__main__':
    n = NacosInstance("47.102.96.180", 8848)
    print(n.Add("444"))
    print(n.Get("444"))
    print(n.Put("444"))
    print(n.Get("444"))
    print(n.List("444"))
    print(n.Delete("444"))