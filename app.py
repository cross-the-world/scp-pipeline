from os import environ, path
from glob import glob

import paramiko
import scp
import sys
import math
import re


envs = environ
INPUT_HOST = envs.get("INPUT_HOST")
INPUT_PORT = int(envs.get("INPUT_PORT", "22"))
INPUT_USER = envs.get("INPUT_USER")
INPUT_PASS = envs.get("INPUT_PASS")
INPUT_KEY = envs.get("INPUT_KEY")
INPUT_CONNECT_TIMEOUT = envs.get("INPUT_CONNECT_TIMEOUT", "30s")
INPUT_SCP = envs.get("INPUT_SCP")
INPUT_LOCAL = envs.get("INPUT_LOCAL")
INPUT_REMOTE = envs.get("INPUT_REMOTE")


seconds_per_unit = {"s": 1, "m": 60, "h": 3600, "d": 86400, "w": 604800, "M": 86400*30}
pattern_seconds_per_unit = re.compile(r'^(' + "|".join(['\\d+'+k for k in seconds_per_unit.keys()]) + ')$')


def convert_to_seconds(s):
    if s is None:
        return 30
    if isinstance(s, str):
        return int(s[:-1]) * seconds_per_unit[s[-1]] if pattern_seconds_per_unit.search(s) else 30
    if (isinstance(s, int) or isinstance(s, float)) and not math.isnan(s):
        return round(s)
    return 30


def connect():
    ssh = paramiko.SSHClient()
    p_key = paramiko.RSAKey.from_private_key(INPUT_KEY) if INPUT_KEY else None
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(INPUT_HOST, port=INPUT_PORT, username=INPUT_USER,
                pkey=p_key, password=INPUT_PASS,
                timeout=convert_to_seconds(INPUT_CONNECT_TIMEOUT))
    return ssh


# Define progress callback that prints the current percentage completed for the file
def progress(filename, size, sent):
    sys.stdout.write(f"{filename} copying: {float(sent)/float(size)*100:.2f}")


def scp_process():
    if (INPUT_KEY is None and INPUT_PASS is None) or (not INPUT_SCP and not (INPUT_LOCAL and INPUT_REMOTE)):
        print("SCP invalid (Script/Key/Passwd)")
        return

    print("+++++++++++++++++++Pipeline: RUNNING SCP+++++++++++++++++++")

    copy_list = []
    if INPUT_LOCAL and INPUT_REMOTE:
        copy_list.append({"l": INPUT_LOCAL, "r": INPUT_REMOTE})
    for c in INPUT_SCP.splitlines():
        if not c:
            continue
        l2r = c.split("=>")
        if len(l2r) == 2:
            local = l2r[0].strip()
            remote = l2r[1].strip()
            if local and remote:
                copy_list.append({"l": local, "r": remote})
                continue
        print(f"SCP ignored {c.strip()}")
    print(copy_list)

    if len(copy_list) <= 0:
        print("SCP no copy list found")
        return

    ssh = connect()
    with scp.SCPClient(ssh.get_transport(), progress=progress, sanitize=lambda x: x) as conn:
        for l2r in copy_list:
            remote = l2r.get('r')
            ssh.exec_command(f"mkdir -p {remote} || true")
            files = [f for f in glob(l2r.get('l'))]
            conn.put(files, remote_path=remote, recursive=True)
            for f in files:
                print(f"{f} -> {remote}")


if __name__ == '__main__':
    scp_process()


