# Compiling VMD on Linux: A step by step guide

This guide is mostly modelled off of the excellent [guide by Robin Betz](https://robinbetz.com/blog/2015/01/08/compiling-vmd-with-python-support/).
Our goal is to take someone who would like to compile VMD themselves, and show them how to integrate it together with Debian packaging tools for distribution on Ubuntu desktops.
The steps are all largely self-contained, fetching the preliminaries from various sources so that you have the libraries you need for fully featured VMD (including Python support!).

1. Get VMD source and other preliminaries
2. Setup Debian packaging requirements
3. Make changes to VMD source 
4. Compile
5. Install/make a repository

## Get VMD source and other preliminaries

This is pretty straightforward, since we'll need to grab a copy of the VMD source code, as well as packages that unlock VMD features.
Getting the VMD source is easy, since you just go to the  [VMD download page](https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD) and grab a copy of the source.
This will be a compressed archive, so you will need to uncompress it with `tar -zxf vmdsourcecode.tgz`, with the filenames actually looking something like: `vmd-1.9.4a55.src.tar.gz`.
This specific alpha version is the one that is assumed throughout the guide.

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


# Distributing VMD: An Ubuntu packaging guide

1. [Do the preparation work for compiling VMD](#Do-the-preparation-work-for-compiling-VMD)
2. [A list of broken things](#A-list-of-broken-things)
3. Building a package with `debuild`
4. [Adding to our repository](#Adding-to-our-repository)

## Do the preparation work for compiling VMD

This largely comes from the [debian package building documentation](https://wiki.debian.org/Packaging/Intro)
```bash
#Copy source to an original tarball
export VMDVERSION=1.9.4a55
cp vmdsourcecode.tgz vmd_${VMDVERSION}.orig.tar.gz
tar -zxf vmd_${VMDVERSION}.orig.tar.gz
cd vmd-${VMDVERSION}
mkdir vmd-${VMDVERSION}
mv * vmd-${VMDVERSION}
```

You'd then need to make a `debian` subdirectory, and populate it with files as suggested by the documentation (`changelog`, `compat`, and `control` being the big ones.). Alot of this can be copied from prior versions that Josh put together on github.

## A list of broken things

There are a number of areas where you'll need to change things in order to build VMD.

- Check the general `Makefile`. Odds are you'll need to change a version number here and there.
- `plugins/Make-arch` probably still points to tcl8.5, rather than 8.6.
- `configure` perl script has some key changes that allow for packaging into a debian package. Of particular note is the header, since we are installing into a weird directory. Python and TCL versions likely also need to be updated.
- `bin/vmd.sh` probably has stride, tachyon, and surf executables set to weird paths. I put them in `/usr/bin`.

## Debuild

You need alot of packages to compile VMD. See `debian/control`, and install the dependencies if needed.
The build process itself is largely automated by `debuild`.

```bash
debuild -b
```

## Adding to our repository

Alot of the setup comes from the [debian manual](https://wiki.debian.org/DebianRepository/SetupWithReprepro).
With the setup complete, the commands to add the newly built packages to the repository are something like this:

```bash
cd /var/www/repos/apt/ubuntu/
sudo reprepro includedeb focal ~/VMDPackage/VMD/vmd-cuda_1.9.4a48-12_amd64.deb
sudo reprepro includedeb focal ~/VMDPackage/VMD/vmd-plugins_1.9.4a48-12_amd64.deb
sudo reprepro includedeb focal ~/VMDPackage/VMD/vmd_1.9.4a48-12_amd64.deb
```
