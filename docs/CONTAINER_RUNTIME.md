# EPICS Container Runtime

## Scope

This document records the container runtime scenario for the EPICS images: the role each image plays, the supervised IOC lifecycle, and the decisions that shape them. It is the durable reference the next session resumes from.

**Out of scope:** the image build recipes (each `Dockerfile`), the milestone work items and their status (`docs/milestone-69b9303.md`), and the internals of the upstream `epics-ioc-runner` contract.

## Image Roles

The current four EPICS images (`debian13`, `rocky8`, `rocky10`, `ubuntu24`) are development images. They carry the build toolchain, run `softIoc`, `procServ`, and `con` directly, default to an interactive shell (`CMD ["/bin/bash"]`), and serve the existing CI consumers that invoke them as `docker run <image> <command>`. IOCs are prepared and built in these images.

Supervised IOC execution ships as a separate image; the development images are not converted to a supervision entry point. See Design Decision below.

## Supervised IOC Lifecycle

A supervision image is an image whose entry point runs `s6-svscan` as PID 1 on the scan directory `/run/s6-procserv`. An IOC runs under that supervision tree through `ioc-runner --container`. Because PID 1 is `s6-svscan`, an operator can enter and leave the container without stopping the IOC.

The session looks like this; the exact `ioc-runner` subcommands follow the runner CLI in `epics-ioc-runner` 1.4.0:

```bash
docker run -d --name ioc <supervision-image>   # s6-svscan becomes PID 1
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

## Open Decisions

- Supervision image layering: whether one toolchain-carrying supervision image serves both preparation and execution, or preparation stays in the current development images while only the slim runtime image (M7) carries the supervision entry point. Resolve before the M1 implementation plan.
- IOC delivery into the slim runtime image (M7): baked at image build time, or mounted at container runtime.

## References

- Milestone work items and status: `docs/milestone-69b9303.md` (M1 container runtime, M7 runtime-only slim image).
- Upstream runner: `epics-ioc-runner` tag `1.4.0` (container execution mode).
