# tools/vendor.R — pre-populate inst/libs/ and src/vendor/ before R CMD build.
# Run: Rscript tools/vendor.R
# This lets CRAN / offline builds work without network access at check time.

lbug_version <- trimws(readLines("tools/lbug_version", warn = FALSE)[1])

os   <- Sys.info()[["sysname"]]   # Darwin, Linux, Windows
arch <- Sys.info()[["machine"]]   # arm64, x86_64, aarch64

artifact <- switch(
  paste0(os, "-", arch),
  "Darwin-arm64"   = "liblbug-osx-universal.tar.gz",
  "Darwin-x86_64"  = "liblbug-osx-universal.tar.gz",
  "Linux-x86_64"   = "liblbug-linux-x86_64.tar.gz",
  "Linux-aarch64"  = "liblbug-linux-aarch64.tar.gz",
  "Windows-x86-64" = "liblbug-windows-x86_64.zip",
  stop("Unsupported platform: ", os, "-", arch)
)

url <- paste0(
  "https://github.com/LadybugDB/ladybug/releases/download/v",
  lbug_version, "/", artifact
)

vendor_inc <- "src/vendor/include"
inst_libs  <- "inst/libs"
dir.create(vendor_inc, recursive = TRUE, showWarnings = FALSE)
dir.create(inst_libs,  recursive = TRUE, showWarnings = FALSE)

message("Downloading: ", url)

tmp_archive <- tempfile(fileext = if (grepl("\\.zip$", artifact)) ".zip" else ".tar.gz")
on.exit(unlink(tmp_archive), add = TRUE)
download.file(url, tmp_archive, mode = "wb", quiet = FALSE)

# Extract
tmp_dir <- tempfile()
dir.create(tmp_dir)
on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

if (grepl("\\.zip$", artifact)) {
  unzip(tmp_archive, exdir = tmp_dir)
} else {
  untar(tmp_archive, exdir = tmp_dir)
}

# Locate header
hdr <- list.files(tmp_dir, pattern = "^lbug\\.h$", recursive = TRUE, full.names = TRUE)
if (length(hdr) == 0) stop("lbug.h not found in archive")
file.copy(hdr[1], file.path(vendor_inc, "lbug.h"), overwrite = TRUE)
message("Installed: ", file.path(vendor_inc, "lbug.h"))

# Locate shared library
if (os == "Darwin") {
  lib <- list.files(tmp_dir, pattern = "liblbug\\.dylib$", recursive = TRUE, full.names = TRUE)
  lib_dest <- file.path(inst_libs, "liblbug.dylib")
} else if (os == "Linux") {
  lib <- list.files(tmp_dir, pattern = "liblbug\\.so", recursive = TRUE, full.names = TRUE)
  lib_dest <- file.path(inst_libs, "liblbug.so")
} else {
  lib <- list.files(tmp_dir, pattern = "liblbug\\.dll$", recursive = TRUE, full.names = TRUE)
  lib_dest <- file.path(inst_libs, "liblbug.dll")
}
if (length(lib) == 0) stop("shared library not found in archive")
file.copy(lib[1], lib_dest, overwrite = TRUE)
message("Installed: ", lib_dest)

# macOS: fix install name
if (os == "Darwin") {
  ret <- system2("install_name_tool",
                 c("-id", "@rpath/liblbug.dylib", lib_dest),
                 stdout = TRUE, stderr = TRUE)
  message("Fixed dylib install name.")
}

message("vendor.R: done. Ready for R CMD build.")
