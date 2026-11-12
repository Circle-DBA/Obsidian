**鲲鹏 920（aarch64）+ UOS Server 20** 机器上启动金仓 `KingbaseES V008R006C009B0014` 时报错

### 一、问题现象

在 **鲲鹏 920（aarch64）+ UOS Server 20** 机器上启动金仓 `KingbaseES V008R006C009B0014` 时报错：

```
kingbase: error while loading shared libraries: libsasl2.so.3: cannot open shared object file: No such file or directory
```

`kingbase`、`ksql` 均报同一错误，`ldd` 仅缺这一个库，其余依赖齐全。

### 二、根因

- 金仓鲲鹏二进制按 **RPM 系（openEuler / 麒麟）** 环境编译，链接的 SONAME 是 `libsasl2.so.3`；
- 本机 UOS（Debian10）自带的是 Debian 打包的旧版 `libsasl2.so.2`（2.1.27），主版本号不匹配，不能软链顶替；
- 金仓安装介质（iso/tar/patch/shell）未自带该库，属安装环境缺依赖。

### 三、已排除的错误方向

表格

|尝试|结果|
|---|---|
|配 `LD_LIBRARY_PATH=Server/lib`|无效，金仓 lib 里本就没有 sasl 库|
|下载 Debian/UOS deb（`libsasl2-2_arm64.deb`，2.1.28）|包内只有 `.so.2`，Debian 打包 SONAME 固定为 `.so.2`，不可用|
|系统现有 `.so.2` 软链成 `.so.3`|不可行，跨主版本符号缺失会段错误|

### 四、最终解决方案（待执行）

在能联网机器下载 **openEuler 20.03 aarch64** 的运行库 RPM（含 `.so.3`），离线拷到 uos-PC 解包提取，不做系统安装：

**下载文件**

```
cyrus-sasl-lib-2.1.27-10.oe1.aarch64.rpm
https://dl-cdn.openeuler.openatom.cn/openEuler-20.03-LTS/OS/aarch64/Packages/cyrus-sasl-lib-2.1.27-10.oe1.aarch64.rpm
```

**uos-PC 上解包安装（rpm2cpio/cpio 已就绪）**

```
mkdir -p /tmp/sasl-rpm && cd /tmp/sasl-rpm
rpm2cpio ~/kingbase/cyrus-sasl-lib-2.1.27-10.oe1.aarch64.rpm | cpio -idmv
find . -name "libsasl2.so.3*" -ls

cp ./usr/lib64/libsasl2.so.3* /home/kingbase/KingbaseES/V8/Server/lib/
chown kingbase:kingbase /home/kingbase/KingbaseES/V8/Server/lib/libsasl2.so.3*
ldconfig
```

**验证**

```
export LD_LIBRARY_PATH=/home/kingbase/KingbaseES/V8/Server/lib:$LD_LIBRARY_PATH
ldd /home/kingbase/KingbaseES/V8/Server/bin/kingbase | grep -i "not found"
/home/kingbase/KingbaseES/V8/Server/bin/kingbase -V
```

### 五、后续注意事项

1. 若 `ldd` 又冒出新 `not found`（`libdb`、`libgssapi_krb5` 等），从同一 openEuler aarch64 目录补对应 RPM，同样解包提取。
2. 更稳妥的做法是联系金仓售后，按版本 `V008R006C009B0014` + 鲲鹏 920 索要配套 `libsasl2.so.3`；openEuler RPM 为离线兜底。
3. 环境变量需持久化到 `kingbase` 用户 `~/.bashrc`：`export LD_LIBRARY_PATH=/home/kingbase/KingbaseES/V8/Server/lib:$LD_LIBRARY_PATH`。

### 六、当前进度

- 诊断、架构确认（aarch64 鲲鹏 920）、缺库定位、错误方案排除均已完成；
- **待办**：下载 RPM → 拷入 uos-PC → 解包提取 `.so.3` → 拷入金仓 lib → 验证启动。

