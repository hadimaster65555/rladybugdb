# Pre-populate src/vendor with the pinned, checksum-verified LadybugDB library.

version <- trimws(readLines("tools/lbug_version", warn = FALSE)[1L])
checksums <- read.table("tools/lbug_checksums", comment.char = "#", col.names = c("asset", "sha256"))
os <- Sys.info()[["sysname"]]
arch <- tolower(Sys.info()[["machine"]])
key <- paste(os, arch, sep = "-")
artifact <- switch(
  key,
  "Darwin-arm64" = "liblbug-static-osx-arm64.tar.gz",
  "Darwin-aarch64" = "liblbug-static-osx-arm64.tar.gz",
  "Darwin-x86_64" = "liblbug-static-osx-x86_64.tar.gz",
  "Linux-x86_64" = "liblbug-static-linux-x86_64-compat.tar.gz",
  "Linux-amd64" = "liblbug-static-linux-x86_64-compat.tar.gz",
  "Linux-aarch64" = "liblbug-static-linux-aarch64-compat.tar.gz",
  "Linux-arm64" = "liblbug-static-linux-aarch64-compat.tar.gz",
  "Windows-x86_64" = "liblbug-windows-x86_64.zip",
  "Windows-amd64" = "liblbug-windows-x86_64.zip",
  "Windows-arm64" = "liblbug-windows-arm64.zip",
  "Windows-aarch64" = "liblbug-windows-arm64.zip",
  stop("Unsupported platform: ", key)
)
expected <- checksums$sha256[match(artifact, checksums$asset)]
if (is.na(expected)) stop("No checksum recorded for ", artifact)

url <- sprintf("https://github.com/LadybugDB/ladybug/releases/download/v%s/%s",
               version, artifact)
archive <- tempfile(fileext = if (endsWith(artifact, ".zip")) ".zip" else ".tar.gz")
directory <- tempfile("rladybugdb-vendor-")
dir.create(directory)
on.exit(unlink(c(archive, directory), recursive = TRUE), add = TRUE)
download.file(url, archive, mode = "wb", quiet = FALSE)

actual <- unname(tools::md5sum(archive))
if (requireNamespace("openssl", quietly = TRUE)) {
  actual <- paste(format(openssl::sha256(file(archive)), upper = FALSE), collapse = "")
} else {
  executable <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  args <- if (executable == "shasum") c("-a", "256", archive) else archive
  actual <- strsplit(system2(executable, args, stdout = TRUE), "[[:space:]]+")[[1L]][1L]
}
if (!identical(tolower(actual), tolower(expected))) {
  stop("SHA-256 mismatch for ", artifact, ": expected ", expected, ", got ", actual)
}

if (endsWith(artifact, ".zip")) unzip(archive, exdir = directory) else untar(archive, exdir = directory)
files <- list.files(directory, recursive = TRUE, full.names = TRUE, all.files = TRUE)
pick <- function(pattern) {
  match <- files[grepl(pattern, basename(files))]
  if (!length(match)) stop("Missing ", pattern, " in ", artifact)
  match[[1L]]
}

include_dir <- "src/vendor/include"
library_dir <- "src/vendor/lib"
dir.create(include_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(library_dir, recursive = TRUE, showWarnings = FALSE)
file.copy(pick("^lbug\\.h$"), file.path(include_dir, "lbug.h"), overwrite = TRUE)

if (os %in% c("Darwin", "Linux")) {
  file.copy(pick("^liblbug\\.a$"), file.path(library_dir, "liblbug.a"), overwrite = TRUE)
} else {
  file.copy(pick("^lbug_shared\\.dll$"), file.path(library_dir, "lbug_shared.dll"), overwrite = TRUE)
  file.copy(pick("^lbug_shared\\.lib$"), file.path(library_dir, "lbug_shared.lib"), overwrite = TRUE)
}
writeLines(version, file.path(library_dir, "ladybugdb-version"))

if (os == "Windows") {
  shell <- Sys.which("sh")
  if (!nzchar(shell)) {
    stop("Rtools sh is required to vendor the Windows runtime dependencies.")
  }
  status <- system2(shell, "configure.win")
  if (!identical(status, 0L)) {
    stop("configure.win failed while vendoring Windows runtime dependencies.")
  }
}

message("Vendored verified LadybugDB v", version, " for ", key, ".")
