# SCP Pipeline

[Github actions](https://help.github.com/en/actions/creating-actions/creating-a-docker-container-action)

This action allows copying per scp
* scp if defined
* local -> remote if defined

## Inputs
see the [action.yml](./action.yml) file for more detail imformation.

### `host`

**Required** ssh remote host.

### `port`

**NOT Required** ssh remote port. Default 22

### `user`

**Required** ssh remote user.

### `pass`

**NOT Required** ssh remote pass.

### `key`

**NOT Required** ssh remote key as string.

### `connect_timeout`

**NOT Required** connection timeout to remote host. Default 30s

### `local`

**NOT Required** execute pre-commands before scp.

### `remote`

**NOT Required** execute pre-commands after scp.

### `scp`

**NOT Required** scp from local to remote.

**Syntax**
local_path => remote_path
e.g.
/opt/test/* => /home/github/test


## Usages
see the [deploy.yml](./.github/workflows/deploy.yml) file for more detail imformation.

#### scp pipeline
```yaml
- name: scp pipeline
  uses: cross-the-world/scp-pipeline@master
  with:
    host: ${{ secrets.DC_HOST }}
    user: ${{ secrets.DC_USER }}
    pass: ${{ secrets.DC_PASS }}
    port: ${{ secrets.DC_PORT }}
    connect_timeout: 10s
    local: './test/*'
    remote: /home/github/test/
    scp: |
      ./test/test*.csv => "/home/github/test/test2/"
```

#### local remote scp
```yaml
- name: local remote scp
  uses: cross-the-world/scp-pipeline@master
  with:
    host: ${{ secrets.DC_HOST }}
    user: ${{ secrets.DC_USER }}
    pass: ${{ secrets.DC_PASS }}
    local: "./test/test1*"
    remote: /home/github/test/test1/
```

  
