# Image Footprint

Size history of the EPICS images, kept outside the work register so it
survives every milestone reset.

When the images are rebuilt at a new distribution version, or the package
layer changes, measure all four axes with the commands below and add one row
to each of the four History tables. Partial updates leave the axes at
different lengths and make the history unreadable.

## Measurement axes

One image reports four different sizes, differing by up to a factor of five.
Each is measured separately, and a number without its command is not
comparable to anything, so each History table names the axis it holds.

Measure a specific version tag, never `latest`. A locally built image and a
pulled one share the `latest` tag, so a figure taken from `latest` does not
say which generation it describes.

Measured values live in the History tables below, one table per axis. This
table defines the axes and nothing else.

| Axis | What it answers | Command |
| --- | --- | --- |
| Real files | How much is actually inside the image | `docker run --rm <image> du -sxm /` |
| Download | What a host transfers on pull | `docker image inspect <image> --format '{{.Size}}'` |
| Layer sum | Total written across all layers, including files a later layer deleted | Sum of the Size column of `docker history <image>` |
| Disk usage | What this host spends storing the image | DISK USAGE column of `docker images` |

Real files is the primary axis: it tracks whether the images are getting
leaner, which is what the package work aims at. Download matters once the
images are published, since every host pays it; its command was checked
against the Docker Hub API, where `full_size` returns the same figure for the
same tag. Layer sum exceeds Real files by whatever intermediate layers created
and later removed. Disk usage roughly tracks Download plus Layer sum, since
Docker keeps both a compressed copy and an unpacked tree, but it is not that
sum: the two agree within 1 MB on the 1.2.2 images and diverge by 51-106 MB on
the larger previous-generation images, so measure it rather than compute it.

Two cautions on reading `docker images` in Docker 29.x. Older releases showed
a single SIZE column, now replaced by the DISK USAGE and CONTENT SIZE pair, so
a figure copied from an older session may sit on an axis that no longer has
that name. And CONTENT SIZE is not the Download axis - it runs 5 percent above
`docker image inspect` on the same image (277 MB against 264 MB on debian13 at
1.2.2), and what accounts for the difference has not been established here.

## History

Each table below holds one axis. Do not read across tables: the same image
differs by up to a factor of five between axes.

The 1.2.2 rows were measured 2026-08-14 with Docker 29.7.1 on a local host,
after `make build.debian13 build.rocky8 build.rocky10`. The previous-generation
rows were measured the same day, with the same Docker and the same commands, on
images pulled from Docker Hub.

### Real files

| Distribution | Date | debian13 | rocky8 | rocky10 | Note |
| --- | --- | --- | --- | --- | --- |
| none | pushed 2026-06 to 2026-07 | 4943 MB | 3105 MB | 2901 MB | Previous generation, EPICS compiled inside the image |
| 1.2.2 | 2026-08-14 | 925 MB | 893 MB | 901 MB | Rebuild at 1.2.2 |

### Download

| Distribution | Date | debian13 | rocky8 | rocky10 | Note |
| --- | --- | --- | --- | --- | --- |
| none | pushed 2026-06 to 2026-07 | 1579 MB | 961 MB | 905 MB | Previous generation |
| 1.2.2 | 2026-08-14 | 264 MB | 292 MB | 292 MB | Rebuild at 1.2.2 |

### Layer sum

| Distribution | Date | debian13 | rocky8 | rocky10 | Note |
| --- | --- | --- | --- | --- | --- |
| none | pushed 2026-06 to 2026-07 | 5286 MB | 3474 MB | 3142 MB | Previous generation |
| 1.2.2 | 2026-08-14 | 972 MB | 1010 MB | 1026 MB | Rebuild at 1.2.2 |

### Disk usage

| Distribution | Date | debian13 | rocky8 | rocky10 | Note |
| --- | --- | --- | --- | --- | --- |
| none | pushed 2026-06 to 2026-07 | 6840 MB | 4430 MB | 4040 MB | Previous generation |
| 1.2.2 | 2026-08-14 | 1250 MB | 1310 MB | 1330 MB | Rebuild at 1.2.2 |

### Distribution 1.2.1, axis unknown

These figures were recorded without their measuring command, so they belong to
no table above.

| Distribution | Date | debian13 | rocky8 | rocky10 | Note |
| --- | --- | --- | --- | --- | --- |
| 1.2.1 | 2026-07-18 | 1.21 GB | 1.11 GB | 1.31 GB | First build from the distribution |
| 1.2.1 | 2026-07-18 | 912 MB | 891 MB | 944 MB | After pruning surplus packages |
| 1.2.1 | 2026-07-19 | 914 MB | 931 MB | 970 MB | After adding procServ and con |

What is not known about the 1.2.1 rows, and cannot now be recovered:

- Which axis they were measured on. No command was recorded with them. Their
  values sit closest to Real files, but that is a resemblance, not evidence.
- Their Download, Layer sum, and Disk usage figures. Never measured.
- Whether the 1.2.2 changes (debian13 +11 MB, rocky8 -38 MB, rocky10 -69 MB
  against the last 1.2.1 row) are real movement or an artifact of comparing
  two axes. The four axes differ by up to a factor of five on the same image,
  so an axis mismatch alone could produce a difference this size.

Re-measuring 1.2.1 would settle all three, and it is not possible: upstream
published no release for 1.2.1, the local tree at `~/alsu-epics/1.2.1` retains
only empty directories, and no 1.2.1 image tag ever reached Docker Hub.

The previous-generation rows have no such gap. Those images were pulled from
Docker Hub and measured with the same commands as the 1.2.2 row, so the
comparison across them is direct. Every axis tells the same story - Real files
down 69 to 81 percent, Download down 68 to 83 percent - which is what the move
to prebuilt distribution binaries bought: the compiler inputs, sources, and
build residue that the older images carried are simply absent.

## Composition

Where the size goes, as of distribution 1.2.2:

| Part | Size | Note |
| --- | --- | --- |
| EPICS tree under `/opt/epics` | 229-231 MB | Prebuilt distribution binaries, near-identical across the three images |
| OS package layer | Remainder | Base image plus the resident consumer build toolchain |

The consumer build toolchain stays resident on purpose: runner jobs compile
IOCs inside the running container. A toolchain-free variant for pure IOC
execution is a separate image design, held in the register backlog.
