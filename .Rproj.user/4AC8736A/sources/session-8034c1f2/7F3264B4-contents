.onLoad <- function(libname, pkgname) {
  # runs when the package is loaded
  .aisstream_env <<- new.env()
}

.onAttach <- function(libname, pkgname) {
  v <- utils::packageVersion(pkgname)
  
  desc_path <- system.file("DESCRIPTION", package = pkgname)
  desc_info <- read.dcf(desc_path)
  vN <- desc_info[, "versionName"]
  
  packageStartupMessage(
    paste0(
      pkgname, "\n",
      "Version: ", "v", v, "\n",
      "VersionName: ", " \"", vN, "\""
    )
  )
}
