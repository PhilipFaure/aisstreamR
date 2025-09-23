#' Decode AIS hex string to R list
#'
#' @param hex_string A character string containing the AIS message in hex format
#' @return A list of the AIS message
#' @export
decode_ais_hex <- function(hex_string) {
  # Remove spaces if present
  hex_string <- gsub(" ", "", hex_string)
  
  # Convert hex to raw bytes
  raw_bytes <- as.raw(strtoi(substring(hex_string, seq(1, nchar(hex_string), 2),
                                       seq(2, nchar(hex_string), 2)), 16L))
  
  # Convert raw bytes to character string
  json_text <- rawToChar(raw_bytes)
  
  # Parse JSON
  parsed <- jsonlite::fromJSON(json_text, flatten = TRUE)
  
  return(parsed)
}
