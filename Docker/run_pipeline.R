# run_pipeline.R

# Load all required packages
library(aisstreamR)
library(websocket)
library(jsonlite)
library(lubridate)
library(later)
library(sf)
library(RSQLite)
library(httr) # For Telegram API calls

# Main function to run the pipeline
run_main_pipeline <- function() {
  # Load sensitive information from environment variables
  api_key <- Sys.getenv("AISSTREAM_API_KEY")
  telegram_bot_token <- Sys.getenv("TELEGRAM_BOT_TOKEN")
  telegram_chat_id <- Sys.getenv("TELEGRAM_CHAT_ID")
  
  if (api_key == "" || telegram_bot_token == "" || telegram_chat_id == "") {
    stop("Required environment variables are not set.")
  }
  
  # Define Penguin Colonies as a list of bounding boxes
  penguin_colonies <- list(
    list(c(-34.0, 18.3), c(-33.8, 18.6)), # Example: Cape Town
    list(c(-34.5, 19.1), c(-34.3, 19.3)) # Example: Betty's Bay
  )
  
  # Define Fishing Closures (as sf polygons)
  # You would load these from a file in a real-world scenario
  closure_poly <- sf::st_as_sfc("POLYGON((-34.05 18.4, -34.05 18.5, -33.95 18.5, -33.95 18.4, -34.05 18.4))", crs = 4326)
  
  # Database connection
  db <- RSQLite::dbConnect(RSQLite::SQLite(), "ais_vessels.sqlite")
  RSQLite::dbExecute(db, "CREATE TABLE IF NOT EXISTS tracked_vessels (
        mmsi TEXT PRIMARY KEY, 
        ship_name TEXT, 
        start_time TEXT, 
        last_ping TEXT
    )")
  
  # Main loop logic (simplified for demonstration)
  # Your pipeline will run this in a scheduled GitHub Action
  
  # 1. Connect and scan for 5 minutes
  print("Starting 5-minute scan for all penguin colonies...")
  ws <- connect_ais_stream(
    api_key = api_key,
    bounding_box = penguin_colonies,
    outDir = "ais_data",
    reconnect_delay = 5
  )
  
  # This will need to be an event loop
  # later::later(function() {
  #     ws$close()
  # }, delay = 300) # 300 seconds = 5 minutes
  
  # We need a more robust way to handle the loop
  # Let's outline the core logic of the onMessage handler
  
  # Simplified onMessage logic within the connect_ais_stream function
  # This is for conceptual understanding of the pipeline flow
  on_message_handler <- function(event) {
    # Decode the message
    decoded <- jsonlite::fromJSON(event$data)
    
    # Check if it's a purse seine vessel
    is_purse_seine <- (decoded$MessageType == "ShipStaticData" && decoded$ShipStaticData$Type == 50) # Example type code
    is_at_sea <- !is_in_port(decoded) # You need to define this helper function
    
    if (is_purse_seine && is_at_sea) {
      mmsi <- decoded$MetaData$MMSI
      # Check if the vessel is already being tracked
      if (!is_tracking(mmsi)) {
        # Start tracking: Add to database
        RSQLite::dbExecute(db, "INSERT OR REPLACE INTO tracked_vessels (mmsi, ship_name, start_time, last_ping) VALUES (?, ?, ?, ?)",
                           params = list(mmsi, decoded$MetaData$ShipName, as.character(Sys.time()), as.character(Sys.time())))
        print(paste("Started tracking new purse seine vessel:", mmsi))
      }
    }
    
    # Check if any tracked vessel is in a fishing closure
    if (is_in_closure(decoded, closure_poly)) {
      send_telegram_alert(decoded, telegram_bot_token, telegram_chat_id)
      print(paste("ALERT: Vessel", decoded$MetaData$MMSI, "in a closure!"))
    }
  }
  
  # Your connect_ais_stream needs to be modified to accept this `on_message_handler`
  # and integrate with the database logic.
}

# Helper function to send Telegram alert
send_telegram_alert <- function(decoded_msg, bot_token, chat_id) {
  # ... API call logic to Telegram here ...
  # This would use httr to post a message with the vessel info and location
  # A map could be a static image generated with sf and uploaded or a link
}

# Execute the main function
run_main_pipeline()