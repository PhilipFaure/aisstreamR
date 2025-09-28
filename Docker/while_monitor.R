library(aisstreamR)
library(parallel)

bbox <- list(
  list(
    list(-37.08311425943465, 16.04298993558595), 
    list(-26.92246585657491, 38.276498517677524)
  )
)

latest_csv <- "path"

target_time <- Sys.time() + 300
stop_file <- "stop.txt"

ws <- connect_ais_stream(
  api_key,
  bounding_box = bbox,
  outDir = "./test/",
  verbose = F
)

stream_open <- TRUE  # flag to track state

tryCatch({
  while (TRUE) {
    current_time <- Sys.time()
    
    # Add here
    # filter data for selected mmsi numbers
    # check within port or at sea, record to db
    # if any at sea continue
    # check whether inside closure, record to db
    
    latest_ais_data <- readr::read_csv(latest_csv)
    
    # Get the last GPS coordinate of each target vessel
    last_location <- latest_ais_data %>% 
      dplyr::filter(mmsi %in% target_mmsi) %>% 
      dplyr::arrange(datetime) %>% 
      dplyr::distinct(mmsi, .keep_all = TRUE) %>% 
      sf::st_as_sf(coords = c("longitude", "latitude"), crs = 4326)
    
    results_df <- last_location %>%
      sf::st_drop_geometry() %>% 
      dplyr::mutate(
        # Check port status
        is_at_port = sapply(1:nrow(last_location), function(i) {
          is_at_port(last_location[i, ], 
                     port_locations_df, 
                     threshold_m = 500)
        }),
        # Check closure status
        is_in_closure = sapply(1:nrow(last_location), function(i) {
          is_in_closure(last_location[i, ], 
                        closure_sf_list)
        })
      )
    
    all_at_port <- all(results_df$is_at_port) 
    
    if (current_time >= target_time && all_at_port == TRUE) {
      cat("Reached target time!\n")
      if (stream_open) {
        try({
          close_ais_stream()
          stream_open <- FALSE
        }, silent = TRUE)
      }
      Sys.sleep(10)
      break
    }
    
    if (file.exists(stop_file)) {
      cat("Stop file detected. Ending loop.\n")
      if (stream_open) {
        try({
          close_ais_stream()
          stream_open <- FALSE
        }, silent = TRUE)
      }
      Sys.sleep(10)
      break
    }
    
    Sys.sleep(10)
  }
})

start_time <- Sys.time()

df <- readr::read_csv("./test/ais_data.csv") %>% 
  dplyr::filter(mmsi %in% target_mmsi) %>% 
  dplyr::arrange(datetime) %>% 
  dplyr::distinct(mmsi,
                  latitude, 
                  longitude, 
                  .keep_all = TRUE) 

df_sf <- df %>% 
  sf::st_as_sf(coords = c("longitude", 
                          "latitude"),
               crs = 4326)


