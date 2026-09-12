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
  runtime_dir <- file.path(source_dir, "vendor", "lib")
  runtime_patterns <- c(
    "lbug_shared.dll",
    "libssl-3-*.dll",
    "libcrypto-3-*.dll"
  )
  runtime_dlls <- unlist(lapply(
    runtime_patterns,
    function(pattern) Sys.glob(file.path(runtime_dir, pattern))
  ), use.names = FALSE)
  matches <- lengths(lapply(
    runtime_patterns,
    function(pattern) Sys.glob(file.path(runtime_dir, pattern))
  ))
  if (any(matches != 1L)) {
    stop(
      "Could not locate the LadybugDB and OpenSSL runtime DLLs: ",
      paste(runtime_patterns[matches != 1L], collapse = ", ")
    )
  }
  copied <- file.copy(runtime_dlls, dest, overwrite = TRUE)
  if (!all(copied)) {
    stop("Could not install the LadybugDB and OpenSSL runtime DLLs.")
  }
}
