# Recreate the pinned, CRAN-patched LadybugDB source archive.
# This maintainer utility is not run by configure or during package install.

version <- trimws(readLines("tools/lbug_version", warn = FALSE)[1L])
checksums_file <- "tools/lbug_source_checksums"
checksums <- read.table(
  checksums_file,
  comment.char = "#",
  col.names = c("asset", "sha256"),
  stringsAsFactors = FALSE
)

crate_name <- sprintf("lbug-%s.crate", version)
archive_name <- sprintf("ladybugdb-%s.tar.xz", version)
expected_crate_sha <- checksums$sha256[match(crate_name, checksums$asset)]
if (is.na(expected_crate_sha)) {
  stop("No upstream crate checksum recorded for ", crate_name)
}

sha256_file <- function(path) {
  executable <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  if (!nzchar(Sys.which(executable))) {
    stop("sha256sum or shasum is required")
  }
  args <- if (executable == "shasum") c("-a", "256", path) else path
  output <- system2(executable, args, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    stop(executable, " failed: ", paste(output, collapse = "\n"))
  }
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][1L]
}

work_dir <- tempfile("rladybugdb-vendor-")
dir.create(work_dir)
on.exit(unlink(work_dir, recursive = TRUE), add = TRUE)

crate <- file.path(work_dir, crate_name)
url <- sprintf(
  "https://static.crates.io/crates/lbug/lbug-%s.crate",
  version
)
download.file(url, crate, mode = "wb", quiet = FALSE)
actual_crate_sha <- sha256_file(crate)
if (!identical(tolower(actual_crate_sha), tolower(expected_crate_sha))) {
  stop(
    "SHA-256 mismatch for ", crate_name, ": expected ", expected_crate_sha,
    ", got ", actual_crate_sha
  )
}

extract_dir <- file.path(work_dir, "source")
dir.create(extract_dir)
untar(crate, exdir = extract_dir)
lbug_root <- file.path(extract_dir, sprintf("lbug-%s", version))
lbug_source <- file.path(lbug_root, "lbug-src")
if (!file.exists(file.path(lbug_source, "CMakeLists.txt"))) {
  stop("The upstream crate does not contain lbug-src/CMakeLists.txt")
}

patch_executable <- Sys.which("patch")
if (!nzchar(patch_executable)) {
  stop("patch is required to apply the CRAN portability patches")
}
apply_patch <- function(file) {
  patch_file <- normalizePath(file)
  status <- system2(
    patch_executable,
    c("-d", shQuote(lbug_source), "-p1", "-i", shQuote(patch_file))
  )
  if (!identical(status, 0L)) {
    stop("Could not apply ", patch_file)
  }
}

# Route upstream std::format calls through common/string_format.h, which the
# macOS compatibility patch adds. That header uses std::format where the C++
# library provides it and the {fmt} library bundled with spdlog otherwise
# (selected by configure). The rewrite is a fixed-string substitution, so it
# can be repeated exactly when the pinned engine is updated.
rewrite_std_format <- function(lbug_source) {
  src_dir <- file.path(lbug_source, "src")
  compat_header <- file.path(src_dir, "include", "common", "string_format.h")
  files <- list.files(src_dir, pattern = "\\.(h|cpp)$", recursive = TRUE,
                      full.names = TRUE)
  files <- files[normalizePath(files) !=
                   normalizePath(compat_header, mustWork = FALSE)]
  rewritten <- 0L
  for (path in files) {
    text <- readChar(path, file.info(path)$size, useBytes = TRUE)
    new <- gsub("#include <format>", "#include \"common/string_format.h\"",
                text, fixed = TRUE, useBytes = TRUE)
    new <- gsub("std::format(", "lbug::common::stringFormat(", new,
                fixed = TRUE, useBytes = TRUE)
    if (!identical(new, text)) {
      writeChar(new, path, eos = NULL, useBytes = TRUE)
      rewritten <- rewritten + 1L
    }
  }
  remaining <- files[vapply(files, function(path) {
    text <- readChar(path, file.info(path)$size, useBytes = TRUE)
    grepl("std::format\\s*\\(|#\\s*include\\s*<format>", text,
          useBytes = TRUE)
  }, logical(1))]
  if (length(remaining)) {
    stop("std::format uses remain after the rewrite: ",
         paste(remaining, collapse = ", "))
  }
  message("Routed std::format through stringFormat in ", rewritten, " files")
}

# Order matters: the macOS compatibility patch is made against the rewritten
# tree.
apply_patch("tools/patches/ladybugdb-cran.patch")
rewrite_std_format(lbug_source)
apply_patch("tools/patches/ladybugdb-macos-compat.patch")

dir.create("tools/vendor", recursive = TRUE, showWarnings = FALSE)
archive <- normalizePath(
  file.path("tools/vendor", archive_name),
  mustWork = FALSE
)
old_wd <- setwd(lbug_root)
on.exit(setwd(old_wd), add = TRUE)
utils::tar(archive, files = "lbug-src", compression = "xz", tar = "internal")
setwd(old_wd)

archive_sha <- sha256_file(archive)
lines <- readLines(checksums_file, warn = FALSE)
pattern <- paste0("^", gsub("\\.", "\\\\.", archive_name), "[[:space:]]+")
replacement <- paste(archive_name, archive_sha)
if (any(grepl(pattern, lines))) {
  lines[grepl(pattern, lines)] <- replacement
} else {
  lines <- c(lines, replacement)
}
writeLines(lines, checksums_file)

message("Vendored LadybugDB v", version, " source: ", archive)
message("SHA-256: ", archive_sha)
