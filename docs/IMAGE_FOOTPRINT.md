# Image Footprint

Size history of the EPICS images, kept outside the work register so it
survives every milestone reset.

When the images are rebuilt at a new distribution version, or the package
layer changes, measure all four axes with the commands below and add one row
to each of the four History tables. Partial updates leave the axes at
different lengths and make the history unreadable.

After a release, one target pulls the published images in
`FOOTPRINT_IMAGE_DIRS` of `configure/CONFIG_SITE` at the version tag, runs the
commands below, and prints the measurement conditions, the four rows, and the
`/opt/epics` sizes:

```bash
make footprint VERSION=<version>
```

Add the four rows to the History tables, and add the measurement conditions
as a sentence under History next to those of the earlier rows, since a figure
without its conditions is not comparable.

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
| Download | What a host transfers on pull | `full_size` of `https://hub.docker.com/v2/repositories/<repository>/tags/<tag>` |
| Layer sum | Total written across all layers, including files a later layer deleted | Sum of the Size column of `docker history <image>` |
| Disk usage | What this host spends storing the image | DISK USAGE column of `docker images` |

Real files is the primary axis: it tracks whether the images are getting
leaner, which is what the package work aims at. Download matters once the
images are published, since every host pays it; it is read from the Docker Hub
API, which does not depend on the local image store. With the containerd image
store, `docker image inspect <image> --format '{{.Size}}'` returns the Disk
usage figure instead (1258732348 bytes against a `full_size` of 279343849 on
debian13 at 1.5.0). The 1.2.2 Download row was taken with that command, on a
host where it was recorded to match `full_size`. Layer sum exceeds Real files
by whatever intermediate layers created and later removed. Disk usage roughly
tracks Download plus Layer sum, since
Docker keeps both a compressed copy and an unpacked tree, but it is not that
sum: the two agree within 1 MB on the 1.2.2 images and diverge by 51-106 MB on
the larger previous-generation images, so measure it rather than compute it.

Two cautions on reading `docker images` in Docker 29.x. Older releases showed
a single SIZE column, now replaced by the DISK USAGE and CONTENT SIZE pair, so
a figure copied from an older session may sit on an axis that no longer has
that name. And CONTENT SIZE was 5 percent above `docker image inspect` on the
same image at 1.2.2 (277 MB against 264 MB on debian13); at 1.5.0, with the
containerd image store, it equals the Docker Hub `full_size` (279 MB on
debian13). Read Download from the Docker Hub API rather than from either
local figure.

## History

Each table below holds one axis. Do not read across tables: the same image
differs by up to a factor of five between axes.

The 1.2.2 rows were measured 2026-08-14 with Docker 29.7.1 on a local host,
after `make build.debian13 build.rocky8 build.rocky10`. The previous-generation
rows were measured the same day, with the same Docker and the same commands, on
images pulled from Docker Hub.

The 1.5.0 rows were measured 2026-11-11 with Docker 29.9.2 and the containerd
image store, on the `1.5.0` tags pulled from Docker Hub, with Download read from
the Docker Hub API.

### Real files

| Distribution | Date | debian13 | rocky8 | rocky10 | Note |
| --- | --- | --- | --- | --- | --- |
| none | pushed 2026-06 to 2026-07 | 4943 MB | 3105 MB | 2901 MB | Previous generation, EPICS compiled inside the image |
| 1.2.2 | 2026-08-14 | 925 MB | 893 MB | 901 MB | Rebuild at 1.2.2 |
| 1.5.0 | 2026-11-11 | 931 MB | 897 MB | 909 MB | Published 1.5.0, pulled |

### Download

| Distribution | Date | debian13 | rocky8 | rocky10 | Note |
| --- | --- | --- | --- | --- | --- |
| none | pushed 2026-06 to 2026-07 | 1579 MB | 961 MB | 905 MB | Previous generation |
| 1.2.2 | 2026-08-14 | 264 MB | 292 MB | 292 MB | Rebuild at 1.2.2 |
| 1.5.0 | 2026-11-11 | 279 MB | 303 MB | 307 MB | Published 1.5.0, Docker Hub `full_size` |

### Layer sum

| Distribution | Date | debian13 | rocky8 | rocky10 | Note |
| --- | --- | --- | --- | --- | --- |
| none | pushed 2026-06 to 2026-07 | 5286 MB | 3474 MB | 3142 MB | Previous generation |
| 1.2.2 | 2026-08-14 | 972 MB | 1010 MB | 1026 MB | Rebuild at 1.2.2 |
| 1.5.0 | 2026-11-11 | 979 MB | 1013 MB | 1044 MB | Published 1.5.0, pulled |

### Disk usage

| Distribution | Date | debian13 | rocky8 | rocky10 | Note |
| --- | --- | --- | --- | --- | --- |
| none | pushed 2026-06 to 2026-07 | 6840 MB | 4430 MB | 4040 MB | Previous generation |
| 1.2.2 | 2026-08-14 | 1250 MB | 1310 MB | 1330 MB | Rebuild at 1.2.2 |
| 1.5.0 | 2026-11-11 | 1260 MB | 1320 MB | 1350 MB | Published 1.5.0, pulled |

### Distribution 1.2.1, axis unknown

These figures were recorded without their measuring command, so they belong to
no table above.

| Distribution | Date | debian13 | rocky8 | rocky10 | Note |
| --- | --- | --- | --- | --- | --- |
| 1.2.1 | 2026-07-18 | 1.21 GB | 1.11 GB | 1.31 GB | First build from the distribution |
| 1.2.1 | 2026-07-18 | 912 MB | 891 MB | 944 MB | After pruning surplus packages |
| 1.2.1 | 2026-07-19 | 914 MB | 931 MB | 970 MB | After adding procServ and con |

What is not known about the 1.2.1 rows:

- Which axis they were measured on. No command was recorded with them. Their
  values sit closest to Real files, but that is a resemblance, not evidence.
- Their Download, Layer sum, and Disk usage figures. Never measured.
- Whether the 1.2.2 changes (debian13 +11 MB, rocky8 -38 MB, rocky10 -69 MB
  against the last 1.2.1 row) are real movement or an artifact of comparing
  two axes. The four axes differ by up to a factor of five on the same image,
  so an axis mismatch alone could produce a difference this size.

Re-measuring 1.2.1 would settle all three, but it will not be done: the owner
decided not to pursue it. The distribution tag 1.2.1 still exists, so the data
is not lost to circumstance - it is simply out of scope. These rows stay as
recorded, on an unknown axis.

The previous-generation rows have no such gap. Those images were pulled from
Docker Hub and measured with the same commands as the 1.2.2 row, so the
comparison across them is direct. Every axis tells the same story - Real files
down 69 to 81 percent, Download down 68 to 83 percent - which is what the move
to prebuilt distribution binaries bought: the compiler inputs, sources, and
build residue that the older images carried are simply absent.

## Composition

Where the size goes, as of distribution 1.5.0 (`du -sxm /opt/epics` in each
image):

| Part | Size | Note |
| --- | --- | --- |
| EPICS tree under `/opt/epics` | 232-234 MB | Prebuilt distribution binaries, near-identical across the three images |
| OS package layer | Remainder | Base image plus the resident consumer build toolchain |

The consumer build toolchain stays resident on purpose: runner jobs compile
IOCs inside the running container. The `<os>-epics-slim` images are the
toolchain-free variant for pure IOC execution; see
[CONTAINER_RUNTIME.md](CONTAINER_RUNTIME.md).
