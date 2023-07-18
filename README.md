# Flomesh eBPF 负载均衡快速体验

## 系统要求

- Ubuntu20.04

## 下载测试脚本

```
git clone https://github.com/cybwan/fsmxlb.test.git
cd fsmxlb.test
```

## 安装依赖软件

```bash
make depends
```

## 容器模式运行

```bash
make docker-fsmxlb
```

## 部署测试拓扑环境

```bash
make simple
```

## 执行测试

```bash
make simple-test
```

## 清理环境

```
make simple-clean
```

