# EPICS Container Runtime

## Scope

This document records the container runtime scenario for the EPICS images: the role each image plays, the supervised IOC lifecycle, and the decisions that shape them. It is the durable reference the next session resumes from.

**Out of scope:** the image build recipes (each `Dockerfile`), the milestone work items and their status (`docs/milestone-69b9303.md`), and the internals of the upstream `epics-ioc-runner` contract.

## Image Roles

The current four EPICS images (`debian13`, `rocky8`, `rocky10`, `ubuntu24`) are development images. They carry the build toolchain, run `softIoc`, `procServ`, and `con` directly, default to an interactive shell (`CMD ["/bin/bash"]`), and serve the existing CI consumers that invoke them as `docker run <image> <command>`. IOCs are prepared and built in these images.

Supervised IOC execution ships as a separate image per OS - `debian13-epics-runner`, `rocky8-epics-runner`, `rocky10-epics-runner`, and `ubuntu24-epics-runner` (variant A: the development image plus the supervision layer). The development images are not converted to a supervision entry point. See Design Decision below.

## Supervised IOC Lifecycle

A supervision image is an image whose entry point runs `s6-svscan` as PID 1 on the scan directory `/run/s6-procserv`. An IOC runs under that supervision tree through `ioc-runner --container`. Because PID 1 is `s6-svscan`, an operator can enter and leave the container without stopping the IOC.

The session looks like this; the exact `ioc-runner` subcommands follow the runner CLI in `epics-ioc-runner` 1.4.0:

```bash
docker run -d --name ioc jeonghanlee/debian13-epics-runner   # s6-svscan is PID 1
docker exec -it ioc bash                        # enter to prepare or build the IOC
ioc-runner --container generate /path/to/iocBoot  # generate and validate <ioc>.conf
ioc-runner --container install <ioc>.conf         # install the IOC configuration
ioc-runner --container start <ioc>                # start under s6 supervision
exit                                            # leaves the exec shell only
docker logs ioc                                 # IOC output on container stdout
docker stop ioc                                 # stop when done
```

One container supervises a single IOC or several, since `s6-svscan` supervises every service directory under the scan directory.

The runtime-only slim image (M7) is the toolchain-free supervision image that runs finished IOCs under its own tag; it depends on the supervision layer (M1). Whether IOC preparation and build happen in that same image family or stay in the current development images is an open decision (below).

## Design Decision

Decision (2026-09-07): supervised execution ships as a separate image. The current four EPICS images stay development images (toolchain-resident, `CMD ["/bin/bash"]`, current CI consumers) and are not converted to run `s6-svscan` as PID 1.

Rationale: converting the development images would break `docker run <image> <command>` for the current CI consumers until the GitLab consumer cutover (external gate G2) completes. A separate image keeps supervised execution independent of G2, so it can be built and verified now. This also matches the register, where the runtime-only slim image (M7) is already a separate image.

Layering (2026-09-07): the supervision layer - the runner install, its `--container` setup, and the `s6-svscan` entry point - is built as a reusable fragment. Applied on a development image it yields a build-and-run image (A); applied on the slim runtime image (M7) it yields a run-only image (B). Because no infrastructure orchestrates the develop-to-run handoff, the pipeline is operated by hand: start with A (build and run in one container manually), and move to B by hand once A stabilizes.

IOC delivery (2026-09-07): a finished IOC is baked into the slim runtime image (variant B) - compiled in a development image (which has the toolchain) and copied into a slim final stage that carries the supervision fragment, a multi-stage build whose result is one immutable image per IOC. Mounting an IOC at runtime was set aside.

## Open Decisions

None open.

## Verification

The runner image's `ENTRYPOINT` is `s6-svscan`, so `docker run <image> <command>` passes the command to `s6-svscan` as arguments instead of running it. Both the gate and the lifecycle check must bypass the entry point.

- Container gate: run it under an explicit bash entry point - `make gate.<os>-epics-runner` does this: `docker run --rm --entrypoint bash -e GATE_RUNNER=1 -v <repo>/gate.bash:/gate.bash:ro <image> /gate.bash`. `GATE_RUNNER=1` enables the G12 supervision-layer check.
- IOC lifecycle (T1): start the container on its own entry point so `s6-svscan` is PID 1, then run the runner's `tests/test-container-lifecycle.bash` through `docker exec` with `CAP_SYS_PTRACE` for deep inspect: `docker run -d --cap-add SYS_PTRACE -v <runner-repo>:/src:ro <image>`, then `docker exec <container> bash /src/tests/test-container-lifecycle.bash`.

Do not run the runner's `run-container-tests.bash` harness against a runner image: it assumes an ENTRYPOINT-less development image, so its command is swallowed by the runner image's `s6-svscan` entry point and the suite never runs. A long verification run should be smoke-checked (container up, first output present) before it is left to complete, and a backgrounded run checked early rather than after it has hung.

## Slim end-to-end verification

A slim image bakes a specific IOC, so it is verified against a live IOC by running the device simulator on the host and linking the container IOC to it over the host network. Example with tc32sim:

1. Clone tc32sim on the host and start its simulator: `simulator/run_simulators.bash` starts 64 emulators on ports 9400-9463. The simulator is a host-side companion, separate from the copy the image build clones.
2. Run the slim image on the host network so the IOC's `127.0.0.1:<port>` reaches the host simulator, with `CAP_SYS_PTRACE` for deep inspect: `docker run -d --name ioc --network host --cap-add SYS_PTRACE <slim-image>`.
3. Drive the baked IOC, regenerating the conf so its `IOC_CHDIR` matches the baked tree. For tc32sim the iocBoot directory is `/opt/ioc/tc32sim/iocBoot/ioctestlab-tc32sim` and the IOC name is `ioctestlab-tc32sim`: `docker exec ioc bash -lc 'cd <iocBoot-dir> && ioc-runner --container generate . && ioc-runner --container install -f ./<name>.conf && ioc-runner --container start <name>'`. The `install -f` skips the save-restore prompt, which otherwise aborts under a non-interactive `docker exec`.
4. Read records through `docker exec` directly, not `bash -lc`: a login shell reruns `/etc/profile` and drops the EPICS bin from PATH. With the tc32sim device prefix `TC32:008:`: `docker exec ioc caget TC32:008:Ti0` for CA; `docker exec ioc pvxget TC32:008:group` for the PVA group (its pvname is `$(P)$(OBJ)`).
5. Tear down: `ioc-runner --container stop <name>`, `docker rm -f ioc`, then stop the simulator. `run_simulators.bash --stop` leaves the `socat` listeners running, so also run `pkill -f tc32_emulator` and `pkill -x socat`.

## References

- Milestone work items and status: `docs/milestone-69b9303.md` (M1 container runtime, M7 runtime-only slim image).
- Upstream runner: `epics-ioc-runner` tag `1.4.0` (container execution mode).
