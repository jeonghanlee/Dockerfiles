# Dockerfile Collections for the GitLab Local Runners

For saving valuable resouces (time, electricity, computing power, and so on), this collections will be used to generate Linux Images with the EPICS environment with full libraries for the gitlab runner.
The image size is still big. However, these images should contains almost all libraries for the EPICS application.

## Debian 10 + EPICS

```bash
bash docker_builder.bash -t debian10
```

## Rocky 8 + EPICS

```bash
bash docker_builder.bash -t rocky8
```

## CentOS7 + EPICS

```bash
bash docker_builder.bash -t centos7
```


## Useful Docker Commands

```bash
docker images
```

