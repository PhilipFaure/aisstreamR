# run_pipeline.R

library(aisstreamR)
library(websocket)
library(jsonlite)
library(lubridate)
library(later)
library(sf)
library(RSQLite)
library(httr)

run_main_pipeline <- function(api_key, telegram_bot_token, telegram_chat_id, 
                              outDir, vessels_mmsi = "./data/vessel_mmsi.csv",
                              port_locations = "./data/port_locations.csv") {
  
  # instead of from user argument can get credentials from sys.env:
  # api_key <- Sys.getenv("AISSTREAM_API_KEY")
  # telegram_bot_token <- Sys.getenv("TELEGRAM_BOT_TOKEN")
  # telegram_chat_id <- Sys.getenv("TELEGRAM_CHAT_ID")
  
  if (api_key == "" || telegram_bot_token == "" || telegram_chat_id == "") {
    stop("Required environment variables are not set.")
  }
  
  # Define Penguin Colonies as a list of bounding boxes
  penguin_colonies <- list(
    list(c(-34.0, 18.3), c(-33.8, 18.6)),  # EXAMPLE -- ADD COORDINATES
    list(c(-34.5, 19.1), c(-34.3, 19.3))   # EXAMPLE -- ADD COORDINATES
    list(c(-34.5, 19.1), c(-34.3, 19.3))   # EXAMPLE -- ADD COORDINATES
    list(c(-34.5, 19.1), c(-34.3, 19.3))   # EXAMPLE -- ADD COORDINATES
    list(c(-34.5, 19.1), c(-34.3, 19.3))   # EXAMPLE -- ADD COORDINATES
    list(c(-34.5, 19.1), c(-34.3, 19.3))   # EXAMPLE -- ADD COORDINATES
  )
  
  closure_das <- sf::st_as_sfc("SHAPEFILE", crs = 4326) # to be added by phil
  closure_rob <- sf::st_as_sfc("SHAPEFILE", crs = 4326) # to be added by phil
  closure_sto <- sf::st_as_sfc("SHAPEFILE", crs = 4326) # to be added by phil
  closure_dye <- sf::st_as_sfc("SHAPEFILE", crs = 4326) # to be added by phil
  closure_stc <- sf::st_as_sfc("SHAPEFILE", crs = 4326) # to be added by phil
  closure_bir <- sf::st_as_sfc("SHAPEFILE", crs = 4326) # to be added by phil
  
  # Database connection
  db <- RSQLite::dbConnect(RSQLite::SQLite(), "ais_vessels.sqlite")
  RSQLite::dbExecute(db, "CREATE TABLE IF NOT EXISTS tracked_vessels (
        mmsi TEXT PRIMARY KEY, 
        ship_name TEXT, 
        start_time TEXT, 
        last_ping TEXT
    )")
  
  
  message("Starting 5-minute AIS scan...")
  
  # Run for entire coastline. the stream should search all of the SA EEZ for any 
  # MMSI vessels coded into the pipeline. currently connect_ais_stream() can't 
  # search for specific vessel so it is provided below and then the data is 
  # is filtered. 
  
  ws <- connect_ais_stream(
    api_key = api_key,
    bounding_box = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    file_path = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    layer = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    outDir = outDir,
    reconnect_delay = 5
  )
  
  # This will collect data for 5 minutes until close_ais_connection() is called
  # by later. But before closing, analyse data to check if any of the vessels are 
  # (a) out at sea, and (b) inside a fishing closure area.
  
  later::later(
    function() {
      
      # read in the CSV database and take only the last 5 minutes of data.
      
      # filter for the provided list of MMSI numbers read in as a CSV named: 
      # "ais-monitor/data/vessel_mmsi.csv". Argument `vessels_mmsi` include in 
      # function if the user wants to provide the CSV manually. 
      
      # after selecting all data for vessel included in vessel_mmsi.csv, then check 
      # whether vessel is at sea or not.
      
      # argument:port_locations = "./data/port_locations.csv". check whether they 
      # are at a port (i.e., 500 m from a port coordinates provided in the CSV 
      # named: "./data/port_locations.csv"), or on land, or out at 
      # sea, write to database column: vesselLocation either "port" or "atsea". 
      # When checking whether the vessel is on land it can be overlayed with 
      # country admin boundaries from package: xxxx?
      
      # see whether the points overlap with any of the closure areas' shapefiles 
      # write to database column: "fishingClosure" either "inside" or "outside"
      
      # if the vessel is out at sea (i.e.,  not within 500 m from a port/harbour)
      # then continue tracking it location via AIS stream until it gets back to 
      # a harbour again.
      
      # if any vessels are at sea, the webSocket connection should be kept open
      # and data continuously collected. Therefore need to write a line of code
      # which checks whether the last record for each vessel in the latest 
      # database is "port". E.g.: if(all(db$VesselLocation) == "port"){close_ais_stream()}

    },
    delay = 5*60
  )
  
  close_ais_stream()
  
  
  on_message_handler <- function(event) {
    # Decode the message
    decoded <- jsonlite::fromJSON(event$data)
    
    # Check if it's a purse seine vessel
    is_purse_seine <- "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" 
    is_at_sea <- !is_in_port(decoded) # helper function NOT DONE................
    
    if (is_purse_seine && is_at_sea) {
      mmsi <- decoded$MetaData$MMSI
      
      if (!is_tracking(mmsi)) { # Is the vessel already being tracked?
        # Start tracking. Add to database
        RSQLite::dbExecute(db, 
                           "INSERT OR REPLACE INTO tracked_vessels (mmsi, ship_name, start_time, last_ping) VALUES (?, ?, ?, ?)",
                           params = list(mmsi, decoded$MetaData$ShipName, 
                                         as.character(Sys.time()), 
                                         as.character(Sys.time())))
        print(
          paste(
            "Started tracking new purse seine vessel:", 
            mmsi
          )
        )
      }
    }
    
    # Check if any tracked vessel is in a fishing closure
    if (is_in_closure(decoded, closure_poly)) {
      send_telegram_alert(decoded, 
                          telegram_bot_token, 
                          telegram_chat_id)
      print(paste("ALERT: Vessel", 
                  decoded$MetaData$MMSI, 
                  "in a closure!"))
    }
  }
}

# Send Telegram alert
send_telegram_alert <- function(decoded_msg, bot_token, chat_id) {
  # XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  # XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  # XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
}

# 
is_in_port <- function(){
  # XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  # XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  # XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
}
is_in_closure <- function(){
  # XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  # XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  # XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
}

# Run
run_main_pipeline(
  api_key, 
  telegram_bot_token, 
  telegram_chat_id, 
  outDir,
  vessels_mmsi
)

# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #
# END ---------------------------------------------------------------------- #