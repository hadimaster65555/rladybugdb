dest <- file.path(R_PACKAGE_DIR, paste0("libs", R_ARCH))
dir.create(dest, recursive = TRUE, showWarnings = FALSE)

source_dir <- if (file.exists(paste0("rladybugdb", SHLIB_EXT))) "." else "src"
package_dll <- Sys.glob(file.path(source_dir, paste0("rladybugdb", SHLIB_EXT)))
if (length(package_dll) != 1L) {
  stop("Could not locate the compiled rladybugdb shared library.")
}
if (!file.copy(package_dll, dest, overwrite = TRUE)) {
  stop("Could not install the compiled rladybugdb shared library.")
}

if (.Platform$OS.type == "windows") {
  ladybug_lib <- file.path(source_dir, "vendor", "lib", "lbug_shared.dll")
  if (!file.exists(ladybug_lib) ||
      !file.copy(ladybug_lib, dest, overwrite = TRUE)) {
    stop("Could not install the LadybugDB runtime DLL.")
  }
}
