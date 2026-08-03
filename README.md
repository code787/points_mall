# 积分商城（Points Mall）

Flutter 实现的积分兑换系统，支持积分登记、物品管理、兑换申请与审核、库存管理、流水查询和数据统计看板。

## 功能总览

| 角色 | 功能 |
| --- | --- |
| 管理员 | 数据看板、用户管理（增删改查/启停/重置密码）、物品管理（增删改查/上下架/调库存）、积分登记（加/扣分）、积分审核、兑换审核、流水查询、数据统计 |
| 普通用户 | 浏览商城、提交兑换申请、查看个人积分明细、查看兑换记录、修改密码 |

## 审核流程

- **积分登记**：管理员提交加分/扣分申请 → 状态为「待审核」→ 审核通过后积分实际生效（扣分时会校验余额不为负）
- **兑换申请**：用户提交兑换 → 管理员审核 → 通过后自动扣减积分 + 扣减库存 + 生成兑换流水（通过时再次校验库存与余额）

## 技术栈

- Flutter + Material 3
- 状态管理：Riverpod 2
- 路由：GoRouter（StatefulShellRoute 底部导航）
- 本地存储：sqflite（SQLite，事务保证积分/库存一致性）
- 会话持久化：shared_preferences
- 密码：sha256 加盐哈希（crypto）

## 目录结构

```
lib/
├── app.dart / main.dart
├── core/
│   ├── constants/        # 常量（默认管理员、图标库等）
│   ├── router/           # GoRouter 路由 + 角色重定向
│   ├── theme/            # 主题
│   └── utils/            # 密码、格式化、校验
├── data/
│   ├── api/              # 预留 API 配置（当前未使用）
│   ├── local/            # 数据库 schema 与初始化
│   ├── models/           # 领域模型（User/Item/交易/兑换/统计）
│   └── repositories/     # 仓储：抽象接口 + sqflite 实现
├── providers/            # Riverpod providers
├── features/
│   ├── auth/             # 登录
│   ├── home/             # 底部导航壳
│   ├── admin/            # 看板/用户/物品/积分登记/审核/流水
│   └── user/             # 商城/我的积分/兑换记录/我的
└── widgets/              # 通用组件
```

## 运行

环境要求：Flutter 3.27+（推荐最新稳定版）、Android SDK。

```bash
cd points_mall
flutter pub get
flutter run            # Android 真机/模拟器
```

首次启动会自动创建数据库并生成默认管理员：

| 账号 | 密码 |
| --- | --- |
| admin | admin123 |

> 首次登录后请务必在「我的 → 修改密码」中修改默认密码。

## 使用建议

1. 管理员登录后先在「用户」页创建普通用户账号；
2. 在「物品」页上架兑换物品并设置积分与库存；
3. 为用户做积分登记（加/扣分，需审核）；
4. 普通用户登录后在「商城」提交兑换申请；
5. 管理员在「审核中心」处理积分与兑换申请；
6. 「流水查询」查看全部历史，「看板」查看统计。

## 数据重置

删除 App 数据即可重置（`flutter run` 下清空应用数据或卸载重装）。

## 预留后端接口说明

当前为本地存储模式。接入后端时：

1. 在 `lib/data/api/api_config.dart` 配置服务器地址；
2. 在 `lib/data/repositories/` 下新增 `ApiXxxRepository implements XxxRepository`；
3. 修改 `lib/providers/repository_providers.dart` 中的 provider 指向远程实现。

所有界面代码只依赖抽象接口，无需改动。
