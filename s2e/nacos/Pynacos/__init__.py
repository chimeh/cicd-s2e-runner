# -*- coding: utf8 -*-
"""
nacos 官网
https://nacos.io/en-us/

本 SDK 基于 Open-API
https://nacos.io/en-us/docs/open-api.html
"""

name = "Pynacos"
class CreatNewNacos:
    def __init__(self, ip=None, port=None, scheme="http"):
        from .NacosAdmin import NacosAdmin
        from .NacosConfig import NacosConfig
        from .NacosInstance import NacosInstance
        from .NacosService import NacosService


        self.NacosAdmin = NacosAdmin(ip, port)
        self.NacosConfig = NacosConfig(ip, port, scheme=scheme)
        self.NacosInstance = NacosInstance(ip, port)
        self.NacosService = NacosService(ip, port)



