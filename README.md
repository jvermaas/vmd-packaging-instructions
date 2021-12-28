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
sudo apt install nvidia-cuda-toolkit #Building CUDA applications
sudo apt install libtachyon-mt-0-dev python3.8-dev tcl8.6-dev tk8.6-dev libnetcdf-dev libpng-dev python3-numpy mesa-common-dev libglu1-mesa-dev libxinerama-dev libfltk1.3-dev coreutils sed #VMD required headers and libraries.
```

One note that will be important here, is that you *may* already have a CUDA toolkit installed.
CUDA toolkits installed by NVIDIA will install CUDA to `/usr/local/cuda`, whereas the Ubuntu version will install CUDA to `/usr`.
The version installed above is currently CUDA 10, which does not have support for the latest and greatest graphics cards.
Thus, the rest of this tutorial will assume that you got CUDA directly from NVIDIA.
The code below is specific to Ubuntu 20.04.

```bash
sudo wget -O /etc/apt/preferences.d/cuda-repository-pin-600 https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/7fa2af80.pub
sudo add-apt-repository "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /"
sudo apt update
sudo apt install cuda
```

Now is as good a time as any to put together the directory structure Ubuntu expects.
The structure is defined by Debian, and as a result, the [Debian package building documentation](https://wiki.debian.org/Packaging/Intro) is the best source for getting our bearings.
Debian expects a rigid directory structure for packaging:
```
vmdpackaging
|   vmd_1.9.4a55.orig.tar.gz
|
└───vmd-1.9.4a55
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
mv ~/vmd-1.9.4a55.src.tar.gz vmd_1.9.4a55.orig.tar.gz
mkdir vmd-1.9.4a55
cd vmd-1.9.4a55
tar -zxf ../vmd_1.9.4a55.orig.tar.gz
mv vmd-1.9.4a55 vmd
#Get the initial, not totally broken debian files.
git init
git remote add origin https://github.com/jvermaas/vmd-packaging-instructions.git
git fetch origin
git checkout -b main --track origin/main
```

There are *going* to be things we need to edit here. Start with `debian/control`, which helpfully lists the build-dependencies for building VMD and its plugins.
This the build-dependencies here are why we installed all those packages above.
Change the maintainer (line 4) and move on.
If you make your own changes to the VMD source, you'd note them in `debian/changelog`.
Otherwise, we are ready to make changes to the VMD source itself that sort out what options we want to use.

## A list of broken things

There are a number of areas where you'll need to change things in order to build VMD.

### `Makefile`

Check the general makefile first, which defines the optional compilation flags that VMD will be using.
The basic line that is easy to support with just Ubuntu packages from the general repository is: `OPENGL TK FLTK IMD ACTC XINERAMA LIBTACHYON ZLIB LIBPNG NETCDF TCL PYTHON PTHREADS NUMPY COLVARS CUDA`
Two optional raytrace renderers are easy enough to add, but require that packages are installed to support those renderers.
See the section [below](#bonus-libraries-and-fpm) to install `LIBOPTIX` and `LIBOSPRAY2`.
If you choose to forego these rendering engines, you'll need to take them out of the `configure` lines of the `Makefile`.

### `plugins/Make-arch`

We are building with tcl8.6, but tcl8.5 is listed in many places within Make-arch.
We can replace these with a `sed` one-liner.
```bash
sed -i 's/tcl8.5/tcl8.6/g' plugins/Make-arch
```

### `vmd/configure`

This is a perl script that generates the `Makefile` that VMD actually compiles from.
As you can see from [Robin's guide](https://robinbetz.com/blog/2015/01/08/compiling-vmd-with-python-support/), there are a *ton* of things to change here.
This is the diff:
```diff
@@ -6,6 +6,17 @@
 # Perl 5.x must be in your path, and /usr/bin/env must exist in order
 # for this to work correctly.
 
+
+use Cwd;
+$cwd = getcwd();
+@parts = split(/\//, $cwd) ;
+$name = $parts[-1];
+$versionstring = quotemeta "-1.9.4a55";
+$name =~ s/$versionstring//g;
+print "Current working directory:\n";
+print "$cwd\n";
+print "$name\n";
+
 ##############################################################################
 # User modifiable installation parameters, can be overridden by env variables
 ##############################################################################
@@ -13,10 +24,10 @@
 $install_name = "vmd";
 
 # Directory where VMD startup script is installed, should be in users' paths.
-$install_bin_dir="/usr/local/bin";
+$install_bin_dir="$cwd/../debian/$name/usr/bin";
 
 # Directory where VMD files and executables are installed
-$install_library_dir="/usr/local/lib/$install_name";
+$install_library_dir="$cwd/../debian/$name/usr/lib/$install_name";
 
 
 # optionally override hard-coded defaults above with environment variables
@@ -497,17 +508,16 @@
 
 $arch_cc          = "cc";
 $arch_ccpp        = "CC";
-$arch_nvcc        = "/usr/local/cuda-10.2/bin/nvcc";
+$arch_nvcc        = "/usr/local/cuda/bin/nvcc";
 $arch_nvccflags   = "-lineinfo --ptxas-options=-v " . 
-                    "-gencode arch=compute_30,code=compute_30 " .
-                    "-gencode arch=compute_30,code=sm_35 " .
-                    "-gencode arch=compute_30,code=sm_37 " .
-                    "-gencode arch=compute_50,code=compute_50 " .
-                    "-gencode arch=compute_50,code=sm_50 " .
+			"-gencode arch=compute_52,code=sm_52 " .
                     "-gencode arch=compute_60,code=compute_60 " .
                     "-gencode arch=compute_60,code=sm_60 " .
                     "-gencode arch=compute_70,code=compute_70 " .
                     "-gencode arch=compute_70,code=sm_70 " .
+		    "-gencode arch=compute_75,code=sm_75 " .
+                    "-gencode arch=compute_80,code=sm_80 " .
+                    "-gencode arch=compute_86,code=sm_86 " .
                     "--ftz=true ";
 #                    "-gencode arch=compute_75,code=sm_75 " .
 $arch_gcc         = "gcc";
@@ -782,8 +792,8 @@
 if ($config_tk) { $tcl_include .= " -I$stock_tk_include_dir"; }
 $tcl_library      = "-L$stock_tcl_library_dir";
 if ($config_tk) { $tcl_library .= " -L$stock_tk_library_dir"; }
-$tcl_libs         = "-ltcl8.5";  
-if ($config_tk) { $tcl_libs = "-ltk8.5 -lX11 " . $tcl_libs; }
+$tcl_libs         = "-ltcl8.6";  
+if ($config_tk) { $tcl_libs = "-ltk8.6 -lX11 " . $tcl_libs; }
 
 @tcl_cc           = ();
 @tcl_cu           = ();
@@ -1005,9 +1015,9 @@
 #   This option enables the use of CUDA GPU acceleration functions.
 #######################
 $cuda_defines     = "-DVMDCUDA -DMSMPOT_CUDA";
-$cuda_dir         = "/usr/local/cuda-10.2";
-$cuda_include     = "";
-$cuda_library     = "";
+$cuda_dir         = "/usr/local/cuda";
+$cuda_include     = "-I$cuda_dir/include";
+$cuda_library     = "-L$cuda_dir/lib64";
 $cuda_libs        = "-Wl,-rpath -Wl,\$\$ORIGIN/ -lcudart_static -lrt";
 @cuda_cc          = ();
 @cuda_cu	  = ('msmpot_cuda.cu',
@@ -1198,7 +1208,7 @@
 # OPTIONAL COMPONENT: Built-in NVIDIA OptiX rendering support 
 # This may be commented out if not required.
 if ($config_opengl) {
-  $liboptix_defines     = "-DVMDLIBOPTIX -DVMDOPTIX_INTERACTIVE_OPENGL";
+  $liboptix_defines     = "-DVMDLIBOPTIX -DVMDOPTIX_INTERACTIVE_OPENGL -DVMDOPTIXRTRT";
 } else {
   $liboptix_defines     = "-DVMDLIBOPTIX ";
 }
@@ -1214,7 +1224,7 @@
 # $liboptix_dir         = "/usr/local/encap/NVIDIA-OptiX-SDK-5.0.1-linux64";
 # $liboptix_dir         = "/usr/local/encap/NVIDIA-OptiX-SDK-5.1.0-linux64";
 # $liboptix_dir         = "/usr/local/encap/NVIDIA-OptiX-SDK-6.0.0-linux64";
-$liboptix_dir         = "/usr/local/encap/NVIDIA-OptiX-SDK-6.5.0-linux64";
+$liboptix_dir         = "/usr";
 # $liboptix_dir         = "/usr/local/encap/NVIDIA-OptiX-SDK-7.0.0-linux64";
 
 # NCSA Blue Waters
@@ -1369,7 +1379,7 @@
   die "LIBPNG option requires ZLIB!";
 }
 $libpng_defines     = "-DVMDLIBPNG";
-$libpng_dir         = "/Projects/vmd/vmd/lib/libpng";
+$libpng_dir         = "/usr/include/libpng";
 $libpng_include     = "-I$libpng_dir/include";
 $libpng_library     = "-L$libpng_dir/lib_$config_arch";
 $libpng_libs        = "-lpng16";
@@ -1672,7 +1682,7 @@
 #  $stock_numpy_library_dir=$ENV{"NUMPY_LIBRARY_DIR"} || "/usr/local/lib";
   $stock_numpy_include_dir=$ENV{"NUMPY_INCLUDE_DIR"} || "$vmd_library_dir/numpy/lib_$config_arch/include";
   $stock_numpy_library_dir=$ENV{"NUMPY_LIBRARY_DIR"} || "$vmd_library_dir/python/lib_$config_arch/lib/python2.5/site-packages/numpy/core/include";
-  $python_libs        = "-lpython2.5 -lpthread";
+  $python_libs        = "-lpython3.8 -lpthread";
 }
 
 $python_defines     = "-DVMDPYTHON";
@@ -2586,7 +2596,7 @@
 
     if ($config_cuda) {
       $arch_nvccflags   .= " --machine 64 -O3 $cuda_include";
-      $cuda_library     = "-L/usr/local/cuda-10.2/lib64";
+      $cuda_library     = "-L/usr/local/cuda/lib64";
     }
 
     $arch_lex		= "flex"; # has problems with vendor lex
@@ -3834,8 +3844,9 @@
 	(cd "$install_library_dir" ; \$(TAR) -xf -)
 	-\$(CD) ..; \$(TAR) -cf - python | \\
 	(cd "$install_library_dir"/scripts ; \$(TAR) -xf -)
-	-\$(CD) ..; \$(TAR) -cf - plugins | \\
-	(cd "$install_library_dir" ; \$(TAR) -xf -)
+	#Plugins get installed by vmd-plugins. Don't worry about it. It's all taken care of.
+	#-\$(CD) ..; \$(TAR) -cf - plugins | \\
+	#(cd "$install_library_dir" ; \$(TAR) -xf -)
 	-\$(CD) ..; \$(TAR) -cf - shaders | \\
 	(cd "$install_library_dir" ; \$(TAR) -xf -)
 	if [ -f ../$config_arch/OptiXShaders.ptx ]; then \\
@@ -3844,21 +3855,14 @@
 	-\$(COPY) ../data/.vmdrc ../data/.vmdsensors ../data/vmd_completion.dat "$install_library_dir"
 	\$(CD) $vmd_bin_dir ; \\
 	if [ -f run_vmd_tmp ]; then \$(DELETE) run_vmd_tmp; fi ; \\
-	if [ ! -x "/bin/csh" ]; then \\
-		\$(ECHO) "Info: /bin/csh shell not found, installing Bourne shell startup script instead" ; \\
-		\$(ECHO) '#!/bin/sh' >> run_vmd_tmp ; \\
-		\$(ECHO) 'defaultvmddir="$install_library_dir"' >> run_vmd_tmp ; \\
-		\$(ECHO) 'vmdbasename=vmd' >> run_vmd_tmp ; \\
-		cat $vmd_bin_sh >> run_vmd_tmp ; \\
-	else \\
-		\$(ECHO) '#!/bin/csh' >> run_vmd_tmp ; \\
-		\$(ECHO) 'set defaultvmddir="$install_library_dir"' >> run_vmd_tmp ; \\
-		\$(ECHO) 'set vmdbasename=vmd' >> run_vmd_tmp ; \\
-		cat $vmd_bin_csh >> run_vmd_tmp ; \\
-	fi ; \\
-	chmod +x run_vmd_tmp ; \\
-	\$(COPY) run_vmd_tmp "$install_bin_dir"/$install_name ; \\
-	\$(DELETE) run_vmd_tmp
+    \$(ECHO) "Info: /bin/csh shell not found, installing Bourne shell startup script instead" ; \\
+    \$(ECHO) '#!/bin/sh' >> run_vmd_tmp ; \\
+    \$(ECHO) 'defaultvmddir=/usr/lib/vmd' >> run_vmd_tmp ; \\
+    \$(ECHO) 'vmdbasename=vmd' >> run_vmd_tmp ; \\
+    cat $vmd_bin_sh >> run_vmd_tmp ; \\
+  chmod +x run_vmd_tmp ; \\
+  \$(COPY) run_vmd_tmp "$install_bin_dir"/$install_name ; \\
+  \$(DELETE) run_vmd_tmp
 	\$(ECHO) Make sure "$install_bin_dir"/$install_name is in your path.
 	\$(ECHO) "VMD installation complete.  Enjoy!"
```
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

There is a syntactical mistake in `vmd/src/OptiXRenderer.C` in version 1.9.4a55 that newer versions of `gcc` don't like, so we also have one more copy to make.
`cp edited/OptiXRenderer.C vmd/src/OptiXRenderer.C`

## Debuild builds packages

The build process itself is largely automated by `debuild`, run from the base directory we have been working from (`vmdpackaging/vmd-1.9.4a55`).

```bash
debuild -b
```

This rolls through compiling the plugins and VMD itself, generating three packages in the `vmdpackaging` directory.
Note that this generates *unsigned* packages, since y'all don't have my gpg key.
If you want/need signed packages, you'll need to edit `debian/changelog` to have the most recent edit signed by the name and email address matching your gpg key.
To install these packages directly, you would do something like:
```bash
cd ..
sudo dpkg -i vmd-cuda_1.9.4a55-3_amd64.deb vmd-plugins_1.9.4a55-3_amd64.deb
```

This would get you a `vmd` command already added to your path, which includes Python support through system Python libraries.

## Adding to a repository

If you want to host these packages for any reason to facilitate multiple computers keeping up to date via apt, it can be useful to create your own repository.
Alot of the setup to make your own repository comes from the [debian manual](https://wiki.debian.org/DebianRepository/SetupWithReprepro).
With the setup complete, the commands to add the newly built packages to the repository are something like this:

```bash
cd /var/www/repos/apt/ubuntu/
sudo reprepro includedeb focal ~/vmdpackaging/vmd-cuda_1.9.4a55-3_amd64.deb
sudo reprepro includedeb focal ~/vmdpackaging/vmd-plugins_1.9.4a55-3_amd64.deb
sudo reprepro includedeb focal ~/vmdpackaging/vmd_1.9.4a55-3_amd64.deb
```


# Bonus Libraries and fpm

There are optional libraries VMD uses to unlock specific features, principally those distributed by NVIDIA ([OptiX](https://developer.nvidia.com/designworks/optix/download)) and Intel ([ospray](https://www.ospray.org/downloads.html)) for ray-trace rendering.
Both Intel and NVIDIA have big scary legal teams that mean that it is important to pay closer attention to licenses.
OSPRAY is under a permissive [Apache license](http://www.apache.org/licenses/LICENSE-2.0).
OptiX has a different license, so we'll need to download that explicitly.
Leveraging [fpm](https://github.com/jordansissel/fpm), a simplified ruby gems package for debian packaging, we can make packages for both ospray and OptiX.
To install fpm, you would do this:
```bash
sudo apt install ruby
sudo gem install fpm
```

With fpm, making a Debian package is super simple for precompiled stuff:

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
To get the OptiX library (specifically the 6.5 version VMD's API expects), you would download `NVIDIA-OptiX-SDK-6.5.0-linux64.sh` from [NVIDIA's developer site](https://developer.nvidia.com/designworks/optix/download), which requires a free account.
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