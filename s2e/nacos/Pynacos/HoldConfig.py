from threading import Thread


class HoldConfig:
    def __init__(self, ip, port, NacosConfig):
        self.ip = ip
        self.port = port
        self.config = None
        self.NacosConfig = NacosConfig

    # 持续监测某个配置文件，如果配置文件发生改变，则触发一个新的事件
    def __Hold(self, data_id: str, group: str, target,
               timeout: int = 30, tenant: str = "", contentMD5 = ""):
        from .func import getMD5
        while True:
            if self.HoldState:
                req = self.NacosConfig.Listener(
                    data_id=data_id,
                    group=group,
                    contentMD5=contentMD5,
                    timeout=timeout,
                    tenant=tenant
                )
                if req:
                    newConfig = self.NacosConfig.Get(data_id, group, to_json = False)
                    self.config = newConfig
                    contentMD5 = getMD5(
                        newConfig
                    )
                    target(newConfig)
            else:
                print("停止循环")
                break

    # 创建一个 Hold 线程，专门由于检测配置
    """
        方法 demo 参数为一个 args, 非 kwargs
        def demo(txt):
            print(txt)

        HoldConifg.Start(data_id, group, demo)        
    """
    def Start(self, data_id : str, group : str, target,
                 timeout : int = 30, tenant : str = "", contentMD5 = ""):
        from .func import getMD5
        self.config = self.NacosConfig.Get(data_id, group, to_json = False)
        self.HoldState = Thread(
            target=self.__Hold,
            args=(
                data_id,
                group,
                target
            ),
            kwargs={
                "timeout": timeout,
                "tenant": tenant,
                "contentMD5" : contentMD5
            }
        )
        self.HoldState.start()
        # 当用户有传入 MD5 的时候会做一次校验，并且提示
        if contentMD5 and (contentMD5 != getMD5(self.config)):
            print("当前传入的 MD5 值与服务器中的不一致")
            return False
        return True


    def Stop(self):
        pass

    def IsRunning(self):
        pass