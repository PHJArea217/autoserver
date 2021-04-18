#!/usr/bin/python3
import os
cgroups = ["autoserver_user", "blkio", "cpu", "cpuacct", "devices", "freezer", "memory", "net_cls", "net_prio", "perf_event", "pids", "rdma", "systemd", "unified"]
for path in cgroups:
#   if True:
    try:
        os.mkdir("/sys/fs/cgroup/%s/inner_system" % path)
    except:
        pass

try:
    os.mkdir("/run/inner_pivot")
except:
    pass

os.chdir("/")
cgroup_files = list(('-P/sys/fs/cgroup/%s/inner_system/cgroup.procs' % path) for path in cgroups)
os.execv("/__autoserver__/bin/ctrtool", ["launcher", "-Cimnputr/run/inner_pivot", "-Rslave",
    "-V", "--script-is-shell", """--script=set -eu
cd /proc/self/fd/"$2"/ns
ip link add to_inner type veth peer name eth0 netns /proc/self/cwd/net
ip link set to_inner address 00:00:5e:00:53:1f master br0 up
nsenter --net=net --ipc=ipc --mount=mnt /__autoserver__/bin/ctrtool mount_seq \\
    -m /run/inner_pivot -t tmpfs -o mode=0755 \\
    -c /run/inner_pivot \\
    -m fsroot -E -s /local_disk/__system__ -Ob \\
    -m boot -E -s /boot_disk/boot -Ob \\
    -D run -M 0700 \\
    -m dev -E -t devtmpfs -Oxs \\
    -D proc -M 0700 \\
    -m sys -E -t sysfs -Oxsdo \\
    -D tmp -M 1777 \\
    -l home -s fsroot/home \\
    -l usr -s fsroot/usr \\
    -l etc -s fsroot/etc \\
    -l var -s fsroot/var \\
    -l bin -s usr/bin \\
    -l lib -s usr/lib \\
    -l lib32 -s usr/lib32 \\
    -l lib64 -s usr/lib64 \\
    -l libx32 -s usr/libx32 \\
    -l sbin -s usr/sbin
"""] + cgroup_files + ["/bin/sh", "-c", "exec /bin/bash </dev/tty9 >/dev/tty9 2>&1"])
