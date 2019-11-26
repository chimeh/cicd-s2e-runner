# 请求错误的类型
class Request_Err(Exception):
    code = {
        400:"Bad Request 客户端请求中的语法错误",
        401:"可能没有访问页面的权限",
        403:"Forbidden 没有权限",
        404:"Not Found 无法找到资源",
        500:"Internal Server Error 服务器内部错误",
    }
    def __init__(self, messge):
        if messge in self.code:
            self.leng = self.code[messge]
        else:
            self.leng = messge

    def __str__(self):
        return self.leng
