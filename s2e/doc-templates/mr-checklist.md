<!--email: jimin.huang@nx-engine.com, jimminh@163.com -->

<!--请说明本MR 解决的缺陷和引入的特性 -->
## 客户视角：MR合并做了哪些变更，解决了哪些缺陷BUG，完成了哪些特性 Feature?

#### BUG
请Dev 回答：参考以下举例填写 Jira 单地址：
- https://jira.nx-code.com/browse/ICEV3-3520 【综合运营管理平台】【设备信息管理】设备关联车辆时，查询可关联的车辆耗时19s
- https://jira.nx-code.com/browse/ICEV3-3683 【运行经济性】ICEv3 Topic 数量优化，topic过多，导致采购云产品成本过高
- BUG N
- BUG N+1

#### Feature
- https://jira.nx-code.com/browse/ICEV3-3109 【智驾伴侣】【语音功能】语意识别：作为翌擎智驾用户，我希望在我输入语音后系统能够识别我的意图，以便能够搜索出我想要的内容
- 特性N
- 特性N+1

## Ops视角：可维护性
#### 升级到UAT是否只需要升级Docker 镜像即可，即是否新引入了配置，回滚操作？
请Dev 回答：



## QA 视角：测试结论
#### 测试结论、功能测试、性能测试
请QA 回答：


## CodeReview 检查点及结论
- 配置规范
  - 配置支持nacos
  - 依赖的数据库地址，账号、密码 可配置；
  - 依赖的数据库中间件 库名/index名等可配置；
- 数据库规范
  - 库名小写
  - 表名小写
  - 只能增加字段，不允许删除字段
- 日志规范
  - 日志不允许打印密码


