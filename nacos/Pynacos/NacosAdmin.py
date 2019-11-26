from Pynacos.func import *

"""
    配置中心方法的类
    以下方法可能无法从外网直接执行，建议使用 curl 命令
    未测试！
"""


class NacosAdmin:
    def __init__(self, ip, port):
        self.ip = ip
        self.port = port

    # 查询系统开关
    def GetSwitches(self):
        html = requests.get(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/operator/switches")
            )
        return check(html)

    # 修改系统开关
    def PutSwitches(self, entry, value, debug = True):
        html = requests.put(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/operator/switches"),
            data = {
                "entry":entry,
                "value":value,
                "debug" : debug
            }
        )
        return check(html)

    # 查看系统当前数据指标
    def GetMetrics(self):
        html = requests.get(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/operator/metrics")
        )
        return check(html)

    # 查看当前集群Server列表
    def GetServers(self, healthy = False):
        html = requests.get(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/operator/servers"),
            data = {
                "healthy" : healthy
            }
        )
        return check(html)

    # 查看当前集群leader
    def GetLeader(self):
        html = requests.get(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/raft/leader")
        )
        return check(html)

    # 更新实例的健康状态
    def PutInstance(self, serviceName,
                    namespaceId = "", groupName = "", clusterName = "", healthy = True):
        html = requests.put(
            url=getUrl(self.ip, self.port, "/nacos/v1/ns/health/instance"),
            params={
                "namespaceId": namespaceId,
                "serviceName": serviceName,
                "groupName": groupName,
                "clusterName": clusterName,
                "ip": self.ip,
                "port": self.port,
                "healthy": healthy
            }
        )
        return check(html)
