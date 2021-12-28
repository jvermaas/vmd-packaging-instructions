#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "ospray::ospray" for configuration "Release"
set_property(TARGET ospray::ospray APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(ospray::ospray PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libospray.so.2.8.0"
  IMPORTED_SONAME_RELEASE "libospray.so.2"
  )

list(APPEND _IMPORT_CHECK_TARGETS ospray::ospray )
list(APPEND _IMPORT_CHECK_FILES_FOR_ospray::ospray "${_IMPORT_PREFIX}/lib/libospray.so.2.8.0" )

# Import target "ospray::ospray_module_ispc" for configuration "Release"
set_property(TARGET ospray::ospray_module_ispc APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(ospray::ospray_module_ispc PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libospray_module_ispc.so.2.8.0"
  IMPORTED_SONAME_RELEASE "libospray_module_ispc.so.2"
  )

list(APPEND _IMPORT_CHECK_TARGETS ospray::ospray_module_ispc )
list(APPEND _IMPORT_CHECK_FILES_FOR_ospray::ospray_module_ispc "${_IMPORT_PREFIX}/lib/libospray_module_ispc.so.2.8.0" )

# Import target "ospray::ospray_imgui" for configuration "Release"
set_property(TARGET ospray::ospray_imgui APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(ospray::ospray_imgui PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libospray_imgui.so.2.8.0"
  IMPORTED_SONAME_RELEASE "libospray_imgui.so.2"
  )

list(APPEND _IMPORT_CHECK_TARGETS ospray::ospray_imgui )
list(APPEND _IMPORT_CHECK_FILES_FOR_ospray::ospray_imgui "${_IMPORT_PREFIX}/lib/libospray_imgui.so.2.8.0" )

# Import target "ospray::ospray_testing" for configuration "Release"
set_property(TARGET ospray::ospray_testing APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(ospray::ospray_testing PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libospray_testing.so.2.8.0"
  IMPORTED_SONAME_RELEASE "libospray_testing.so.2"
  )

list(APPEND _IMPORT_CHECK_TARGETS ospray::ospray_testing )
list(APPEND _IMPORT_CHECK_FILES_FOR_ospray::ospray_testing "${_IMPORT_PREFIX}/lib/libospray_testing.so.2.8.0" )

# Import target "ospray::ospray_module_denoiser" for configuration "Release"
set_property(TARGET ospray::ospray_module_denoiser APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(ospray::ospray_module_denoiser PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libospray_module_denoiser.so.2.8.0"
  IMPORTED_SONAME_RELEASE "libospray_module_denoiser.so.2"
  )

list(APPEND _IMPORT_CHECK_TARGETS ospray::ospray_module_denoiser )
list(APPEND _IMPORT_CHECK_FILES_FOR_ospray::ospray_module_denoiser "${_IMPORT_PREFIX}/lib/libospray_module_denoiser.so.2.8.0" )

# Import target "ospray::ospray_module_mpi" for configuration "Release"
set_property(TARGET ospray::ospray_module_mpi APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(ospray::ospray_module_mpi PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libospray_module_mpi.so.2.8.0"
  IMPORTED_SONAME_RELEASE "libospray_module_mpi.so.2"
  )

list(APPEND _IMPORT_CHECK_TARGETS ospray::ospray_module_mpi )
list(APPEND _IMPORT_CHECK_FILES_FOR_ospray::ospray_module_mpi "${_IMPORT_PREFIX}/lib/libospray_module_mpi.so.2.8.0" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
