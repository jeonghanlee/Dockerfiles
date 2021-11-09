# How to

## Add a new Dockerfile

* Create a docker repository in the docker hub

* Copy other directory to new directory with the different name

* Update the copied one

* Update `release.bash`

* Add `github action

## Docker Tag

```bash


## Docker Tag

```bash
./release.bash
>
> Default latest tag will be used.
>> Do you want to continue (y/N)?
#
#
$ ./release.bash unstablei
$ git diff
.
.
diff --git a/.github/workflows/rocky8.yml b/.github/workflows/rocky8.yml
index fbf50f2..b5e236c 100644
--- a/.github/workflows/rocky8.yml
+++ b/.github/workflows/rocky8.yml
@@ -20,7 +20,7 @@ jobs:
         DOCKER_FILE: rocky8/Dockerfile
         DOCKER_ACCOUNT: alscontrols
         DOCKER_REPO: rocky8-epics
-        DOCKER_TAG: latest
+        DOCKER_TAG: unstable
.
.
.
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   .github/workflows/centos7.yml
	modified:   .github/workflows/debian10.yml
	modified:   .github/workflows/debian11.yml
	modified:   .github/workflows/rocky8.yml
	modified:   .github/workflows/sl7.yml

$ git add ...
$ git commit -m "..."
$ git push
```
