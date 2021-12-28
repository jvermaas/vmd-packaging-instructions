DESTDIR=$(shell pwd)
ARCH=$(shell getconf LONG_BIT)
VMDVER="1.9.4a55"
ifeq ($(ARCH),64)
	PLUGINTEXT=LINUXAMD64
	OPTIX=LIBOPTIX 
else
	PLUGINTEXT=LINUX
	OPTIX=""
endif
PLUGINDIR=$(DESTDIR)/../vmd-plugins/usr/lib/vmd/plugins
PLUGINBINDIR=$(DESTDIR)/../vmd-plugins/usr/bin
TCL_INCLUDE_DIR=/usr/include/tcl8.6/
TCL_LIBRARY_DIR=/usr/lib/x86_64-linux-gnu
TK_INCLUDE_DIR=/usr/include/tcl8.6/
TK_LIBRARY_DIR=/usr/lib/x86_64-linux-gnu
PYTHON_INCLUDE_DIR=/usr/include/python3.8
export
all: compileplugins compilevmd

compileplugins:
	cd plugins; make $(PLUGINTEXT) TCLINC=-I/usr/include/tcl8.6 TCLLIB=-L/usr/lib \
	NETCDFLIB=-L/usr/lib NETCDFINC=-I/usr/include/ -j ; make distrib PLUGINDIR=$(DESTDIR)/vmd-$(VMDVER)/plugins ; \
	# TNGLIB=-L/usr/local/lib TNGINC=-I/usr/local/include
copyvmd:
	cp -r vmd-$(VMDVER) vmd-$(VMDVER)-cuda

compilevmd: copyvmd
	cd vmd-$(VMDVER); \
	./configure $(PLUGINTEXT) OPENGL TK FLTK IMD ACTC XINERAMA LIBTACHYON ZLIB LIBPNG NETCDF TCL PYTHON PTHREADS NUMPY COLVARS LIBOSPRAY2 ; \
	cd src ; make -j
	cd vmd-$(VMDVER)-cuda; \
	./configure $(PLUGINTEXT) OPENGL TK FLTK IMD ACTC XINERAMA LIBTACHYON ZLIB LIBPNG NETCDF TCL PYTHON PTHREADS NUMPY COLVARS LIBOSPRAY2 CUDA  $(OPTIX); \
	cd src ; make -j

installplugins:
	@echo "Destination Directory:"
	@echo $(DESTDIR)
	@echo $(PLUGINDIR)
	cd plugins ; make distrib
	
	
installvmd:
	cd vmd-$(VMDVER)/src; make install
	cd vmd-$(VMDVER)-cuda/src; make install

install: installplugins installvmd
	cp vmd.png debian/vmd/usr/share/pixmaps/
	cp vmd.png debian/vmd-cuda/usr/share/pixmaps/
	cp debian/vmd.desktop debian/vmd/usr/share/applications/
	cp debian/vmd.desktop debian/vmd-cuda/usr/share/applications/
	
clean:
	cd plugins; make clean ; cd ../vmd-$(VMDVER) ; rm -rf plugins; cd src; make veryclean ; \
	cd ../.. ; rm -rf vmd-$(VMDVER)-cuda
