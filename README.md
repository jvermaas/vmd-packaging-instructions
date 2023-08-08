# Compiling VMD on Ubuntu: A step by step guide

This guide is mostly modelled off of the excellent [guide by Robin Betz](https://robinbetz.com/blog/2015/01/08/compiling-vmd-with-python-support/).
Our goal is to take someone who would like to compile VMD themselves, and show them how to integrate it together with Debian packaging tools for distribution on Ubuntu desktops.
The steps are all largely self-contained, fetching the preliminaries from various sources so that you have the libraries you need for fully featured VMD (including Python support!).

1. [Get VMD source and other preliminaries](#get-vmd-source-and-other-preliminaries)
2. [Setup Debian packaging requirements](#debian-package-structure)
3. [Make changes to VMD source](#vmd-source-edits)
4. [Compile](#debuild-builds-packages)
5. [Install/make a repository](#adding-to-a-repository)

For completeness, we also provide instructions for [building packages](#bonus-libraries-and-fpm) two raytracing libraries VMD can use.

## Get VMD source and other preliminaries

This is pretty straightforward, since we'll need to grab a copy of the VMD source code, as well as packages that unlock VMD features.
Getting the VMD source is easy, since you just go to the  [VMD download page](https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD) and grab a copy of the source.
This will be a compressed archive, so you will need to uncompress it with `tar -zxf vmdsourcecode.tgz`, with the filenames actually looking something like: `vmd-1.9.4a57.src.tar.gz`.
This specific alpha version is the one that is assumed throughout the guide, and may require revision to be used for other versions.

Now, there are other packages that we will need to grab that are not installed by default on Ubuntu installations.
A number of these are available from [my PPA](https://launchpad.net/~josh-vermaas/+archive/ubuntu/vmd-things), and would be installed via the following commands.

```bash
#Add the repository
sudo add-apt-repository ppa:josh-vermaas/vmd-things
sudo apt-get update
#Install the packages
sudo apt install surf=1.0-1 msms stride libactc actc-dev
sudo apt-mark hold surf
```

The last two lines might look a little funny, but there is an unrelated package called `surf`, and as a result we need to mark that the package is not allowed to change from the SURF 1.0 version made back in 1994.

There are also Debian packages that need to be installed as basic dependencies.
```bash
sudo apt install devscripts debhelper #Package building and general compilation
sudo apt install libtachyon-mt-0-dev python3.10-dev tcl8.6-dev tk8.6-dev libnetcdf-dev libpng-dev python3-numpy python3-tk mesa-common-dev libglu1-mesa-dev libxinerama-dev libfltk1.3-dev coreutils sed #VMD required headers and libraries.
```

To build VMD with CUDA, you will need a CUDA toolkit.
You have two choices, using either the stock CUDA available from the Ubuntu repositories, or a more up to date version that comes from NVIDIA repositories.
One note that will be important here, is that you *may* already have a CUDA toolkit installed.
CUDA toolkits installed by NVIDIA will install CUDA to `/usr/local/cuda`, whereas the Ubuntu version will install CUDA to `/usr`.
The version installed from the Ubuntu repositories is currently CUDA 10, which does not have support for the latest and greatest graphics cards.
Thus, the rest of this tutorial will assume that you got CUDA directly from NVIDIA.
If you use the version directly from Ubuntu, you will need to modify the `configure` [script](#`vmd/configure`) accordingly.
The code below will install the CUDA toolkit from NVIDIA for Ubuntu 20.04.


```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt update
sudo apt install cuda
```

If you prefer the older CUDA packages in the Ubuntu repositories, you'd do the following.
I cannot emphasize enough how much of a pain it is to work with the Ubuntu version, which has at least one showstopping compilation bug in 22.04.
```bash
sudo apt install nvidia-cuda-toolkit
```

## Debian Package Structure

Now is as good a time as any to put together the directory structure Ubuntu expects.
The structure is defined by Debian, and as a result, the [Debian package building documentation](https://wiki.debian.org/Packaging/Intro) is the best source for getting our bearings.
Debian expects a rigid directory structure for packaging:
```
vmdpackaging
|   vmd_1.9.4a57.orig.tar.gz
|
└───vmd-1.9.4a57
    |	Makefile
    |	vmd.png
    |
    └───debian
    |	|	changelog
    |	|	control
    |	|	compat
    |	|	copyright
    |	|	rules
    |	└───source
    |		|	format
    |		|	include-binaries
    └───vmd
    └───plugins
```

The basics are that there is a "source tarball" (ending will `orig.tar.gz`) in the root of the file tree, and a directory within the tree with a name that matches the source tarball.
Inside that directory is the debian subdirectory, which has a number of files.
Feel free to copy from this github repository to start with.

```bash
mkdir vmdpackaging
cd vmdpackaging
mv ~/vmd-1.9.4a57.src.tar.gz vmd_1.9.4a57.orig.tar.gz
mkdir vmd-1.9.4a57
cd vmd-1.9.4a57
tar -zxf ../vmd_1.9.4a57.orig.tar.gz
mv vmd-1.9.4a57 vmd
#Get the initial, not totally broken debian files.
git init
git remote add origin https://github.com/jvermaas/vmd-packaging-instructions.git
git fetch origin
git checkout -b main --track origin/main
```

There are *going* to be things we might want to edit here. Start with `debian/control`, which helpfully lists the build-dependencies for building VMD and its plugins.
This the build-dependencies here are why we installed all those packages above.
Change the maintainer (line 4) and move on.
If you make your own changes to the VMD source, you'd note them in `debian/changelog`.
Otherwise, we are ready to make changes to the VMD source itself that sort out what options we want to use.

## VMD Source Edits

There are a number of areas where you'll need to change things in order to build VMD starting from the released tarball.

### `Makefile`

Check the general makefile first, which defines the optional compilation flags that VMD will be using.
The basic line that is easy to support with just Ubuntu packages from the general repository is: `OPENGL TK FLTK IMD ACTC XINERAMA LIBTACHYON ZLIB LIBPNG NETCDF TCL PYTHON PTHREADS NUMPY COLVARS CUDA`
Two optional raytrace renderers are easy enough to add, but require that packages are installed to support those renderers.
See the section [below](#bonus-libraries-and-fpm) to install `LIBOPTIX` and `LIBOSPRAY2`.
If you choose to add these rendering engines, you'll need to uncomment two commented lines in the `Makefile`.

### `plugins/Make-arch`

We are building with tcl8.6, but tcl8.5 is listed in many places within Make-arch.
We can replace these with a `sed` one-liner.
```bash
sed -i 's/tcl8.5/tcl8.6/g' plugins/Make-arch
```

### `vmd/configure`

This is a perl script that generates the `Makefile` that VMD actually compiles from.
As you can see from [Robin's guide](https://robinbetz.com/blog/2015/01/08/compiling-vmd-with-python-support/), there are a *ton* of things to change here.
What the changes entail are to change libraries and change where the linker should look for the files.
However, to save everyone's sanity, you can just copy this from one directory up. `cp edited/configure vmd/configure`

### `vmd/bin/vmd.sh`
This has stride, tachyon, and surf executables set to weird paths. I put them in `/usr/bin`.
```diff
@@ -436,31 +436,37 @@
 
 # set the path to a few external programs
 # Stride -- used to generate cartoon representations etc.
+STRIDE_BIN="/usr/bin/stride"
+export STRIDE_BIN
 if [ -z "$STRIDE_BIN" ]
 then
   if [ -x "$MASTERVMDDIR/stride_$ARCH" ]
   then
-    STRIDE_BIN="$VMDDIR/stride_$ARCH"
+    STRIDE_BIN="/usr/bin/stride"
     export STRIDE_BIN
   fi
 fi
 
 # Surf -- used to generate molecular surfaces
+SURF_BIN="/usr/bin/surf"
+export SURF_BIN
 if [ -z "$SURF_BIN" ]
 then
   if [ -x "$MASTERVMDDIR/surf_$ARCH" ]
   then
-    SURF_BIN="$VMDDIR/surf_$ARCH"
+    SURF_BIN="/usr/bin/surf"
     export SURF_BIN
   fi
 fi
 
 # Tachyon -- used to generate ray traced graphics
+TACHYON_BIN="/usr/bin/tachyon"
+export TACHYON_BIN
 if [ -z "$TACHYON_BIN" ]
 then
   if [ -x "$MASTERVMDDIR/tachyon_$ARCH" ]
   then
-    TACHYON_BIN="$VMDDIR/tachyon_$ARCH"
+    TACHYON_BIN="/usr/bin/tachyon"
     export TACHYON_BIN
   fi
 fi
```
Again, you could copy this from the edited version from github. `cp edited/vmd.sh vmd/bin/vmd.sh`

## Debuild builds packages

The build process itself is largely automated by `debuild`, run from the base directory we have been working from (`vmdpackaging/vmd-1.9.4a57`).

```bash
debuild -b
```

This rolls through compiling the plugins and VMD itself, generating three packages in the `vmdpackaging` directory.
Note that this generates *unsigned* packages, since y'all don't have my gpg key.
If you want/need signed packages, you'll need to edit `debian/changelog` to have the most recent edit signed by the name and email address matching your [gpg key](https://help.ubuntu.com/community/GnuPrivacyGuardHowto).
Without a gpg key, you may get errors about generating unsigned packages.
This is to be expected, and so long as the `.deb` files are produced, these errors can be ignored.
To install these packages directly, you would do something like:
```bash
cd .. #Puts you in the right directory.
sudo dpkg -i vmd-cuda_1.9.4a57-1_amd64.deb vmd-plugins_1.9.4a57-1_amd64.deb
```

This would get you a `vmd` command already added to your path, which includes Python support through system Python libraries.
At this point, you'd be done, with a functional VMD installation.
If you are interested in additional functionality, you could add in extra pieces, such as the [tpr reader plugin](https://github.com/jvermaas/vmd-tprreader).
The `fastpbc` command is also turned off by default, and can be turned on by editing `vmd/src/tcl_commands.C`, and eliminating preprocessor directives that skip `fastpbc` (line 283).

## Adding to a repository

If you want to host these packages for any reason to facilitate multiple computers keeping up to date via apt, it can be useful to create your own repository.
Alot of the setup to make your own repository comes from the [debian manual](https://wiki.debian.org/DebianRepository/SetupWithReprepro).
With the setup complete, the commands to add the newly built packages to the repository are something like this:

```bash
cd /var/www/repos/apt/ubuntu/
sudo reprepro includedeb focal ~/vmdpackaging/vmd-cuda_1.9.4a57-1_amd64.deb
sudo reprepro includedeb focal ~/vmdpackaging/vmd-plugins_1.9.4a57-1_amd64.deb
sudo reprepro includedeb focal ~/vmdpackaging/vmd_1.9.4a57-1_amd64.deb
```


# Bonus Libraries and fpm

There are optional libraries VMD uses to unlock specific features, principally those distributed by NVIDIA ([OptiX](https://developer.nvidia.com/designworks/optix/download)) and Intel ([ospray](https://www.ospray.org/downloads.html)) for ray-trace rendering.
The APIs for these libraries change from time to time.
While any OSPRay version in the 2.X branch should work (we've tested 2.8.0 and 2.4.0), OptiX is much pickier.
VMD currently assumes the API from OptiX 6.5.0, which is under the "All older versions" button on the OptiX download page.

Both Intel and NVIDIA have big scary legal teams that mean that it is important to pay closer attention to licenses.
OSPRAY is under a permissive [Apache license](http://www.apache.org/licenses/LICENSE-2.0).
OptiX has a different license, so we'll need to download that explicitly from NVIDIA.
Leveraging [fpm](https://github.com/jordansissel/fpm), a simplified ruby gems package for debian packaging, we can make packages for both ospray and OptiX.
To install fpm, you would do this:
```bash
sudo apt install ruby
sudo gem install fpm
```

With fpm, making a Debian package is super simple for precompiled libraries:

```bash
wget https://github.com/ospray/OSPRay/releases/download/v2.8.0/ospray-2.8.0.x86_64.linux.tar.gz
tar -zxf ospray-2.8.0.x86_64.linux.tar.gz
mv ospray-2.8.0.x86_64.linux/lib lib
mv ospray-2.8.0.x86_64.linux/include include
fpm -s dir -t deb -v 2.8.0 --iteration 1 --prefix=/usr -n libospray lib/*
fpm -s dir -t deb -v 2.8.0 --iteration 1 --prefix=/usr -n libospray-dev include/*
sudo dpkg -i libospray*
```

The basic idea is to untar the precompiled library, move the `lib` and `include` subdirectories into somewhere accessible, and use `fpm` to build debian packages from the directory structures.
We can do something similar with OptiX.
To get the OptiX library (specifically the 6.5 version VMD's API expects, which is under "all older versions"), you would download `NVIDIA-OptiX-SDK-6.5.0-linux64.sh` from [NVIDIA's developer site](https://developer.nvidia.com/designworks/optix/download), which requires a free account.
Once downloaded, you would run the shell script, and create packages out of it.

```bash
chmod 755 NVIDIA-OptiX-SDK-6.5.0-linux64.sh
./NVIDIA-OptiX-SDK-6.5.0-linux64.sh #Note that you need to answer some interactive questions at this step.
cd NVIDIA-OptiX-SDK-6.5.0-linux64/
mv lib64 lib
fpm -s dir -t deb -v 6.5.0 --iteration 1 --prefix=/usr -n liboptix lib/*
fpm -s dir -t deb -v 6.5.0 --iteration 1 --prefix=/usr -n liboptix-dev include/*
sudo dpkg -i liboptix*
```
