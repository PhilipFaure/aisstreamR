#' Close the AIS WebSocket Stream
#'
#' This function closes the active AIS WebSocket connection.
#'
#' @details
#' The `close_ais_stream()` function attempts to close the WebSocket connection
#' gracefully. It looks for the connection object in the `.aisstream_env`
#' environment. If the connection was started with automatic reconnection
#' or a heartbeat enabled, these will also be cancelled.
#'
#' @return
#' Invisibly returns `TRUE` if a connection was closed, `FALSE` otherwise.
#'
#' @export
close_ais_stream <- function() {
  
  if (!exists(".aisstream_env") || !exists("ws", envir = .aisstream_env)) {
    message("No active AIS stream found.")
    return(invisible(FALSE))
  }
  
  ws <- get("ws", envir = .aisstream_env)
  
  # Check for a valid WebSocket object
  if (inherits(ws, "WebSocket")) {
    # Set the shutdown flag before closing the connection
    .aisstream_env$is_shutting_down <- TRUE
    
    try(ws$close(), silent = TRUE)
    message("💀 AIS WebSocket closing...")
    
    if (exists("reconnect_handle", envir = .aisstream_env)) {
      later_handle <- get("reconnect_handle", envir = .aisstream_env)
      if (is.function(later_handle)) {
        later_handle()  # Call the handle to cancel it
      }
      rm("reconnect_handle", envir = .aisstream_env)
    }
    
    if (exists("heartbeat_handle", envir = .aisstream_env)) {
      later_handle <- get("heartbeat_handle", envir = .aisstream_env)
      if (is.function(later_handle)) {
        later_handle() # Call the handle to cancel it
      }
      rm("heartbeat_handle", envir = .aisstream_env)
    }
    
    rm("ws", envir = .aisstream_env)
    
    return(invisible(TRUE))
  } else {
    message("No valid WebSocket object found.")
    return(invisible(FALSE))
  }
}