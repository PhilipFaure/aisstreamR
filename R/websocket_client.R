#' Receive real-time vessel AIS messages.
#' 
#' Connect through the AISStream.io WebSocket to receive real-time vessel AIS messages for a specified bounding box. 
#' 
#' @param api_key Your AISStream API key as a string.
#' @param bounding_box List of coordinates: list(list(c(lat1, lon1), c(lat2, lon2)))
#' @param reconnect_delay Seconds to wait before reconnecting after a disconnect (default: 5)
#' @param heartbeat_interval Seconds between optional heartbeat messages (default: NULL, no heartbeat)
#' @param outDir Character string specifying the output directory to save data. If NULL, data is not saved.
#' @return A WebSocket object
#' @export
connect_ais_stream <- function(api_key, bounding_box, reconnect_delay = 5, heartbeat_interval = NULL, outDir = NULL) {
  
  library(websocket)
  library(jsonlite)
  library(later)
  
  # Master list of all possible AIS message column names
  master_ais_columns <- c(
    "PositionReport_Cog", "PositionReport_CommunicationState", "PositionReport_Latitude", 
    "PositionReport_Longitude", "PositionReport_MessageID", "PositionReport_NavigationalStatus", 
    "PositionReport_PositionAccuracy", "PositionReport_Raim", "PositionReport_RateOfTurn", 
    "PositionReport_RepeatIndicator", "PositionReport_Sog", "PositionReport_Spare", 
    "PositionReport_SpecialManoeuvreIndicator", "PositionReport_Timestamp", 
    "PositionReport_TrueHeading", "PositionReport_UserID", "PositionReport_Valid", 
    "MessageType", "MetaData_MMSI", "MetaData_MMSI_String", "MetaData_ShipName", 
    "MetaData_latitude", "MetaData_longitude", "MetaData_time_utc", 
    "StandardClassBPositionReport_AssignedMode", "StandardClassBPositionReport_ClassBBand", 
    "StandardClassBPositionReport_ClassBDisplay", "StandardClassBPositionReport_ClassBDsc", 
    "StandardClassBPositionReport_ClassBMsg22", "StandardClassBPositionReport_ClassBUnit", 
    "StandardClassBPositionReport_Cog", "StandardClassBPositionReport_CommunicationState", 
    "StandardClassBPositionReport_CommunicationStateIsItdma", "StandardClassBPositionReport_Latitude", 
    "StandardClassBPositionReport_Longitude", "StandardClassBPositionReport_MessageID", 
    "StandardClassBPositionReport_PositionAccuracy", "StandardClassBPositionReport_Raim", 
    "StandardClassBPositionReport_RepeatIndicator", "StandardClassBPositionReport_Sog", 
    "StandardClassBPositionReport_Spare1", "StandardClassBPositionReport_Spare2", 
    "StandardClassBPositionReport_Timestamp", "StandardClassBPositionReport_TrueHeading", 
    "StandardClassBPositionReport_UserID", "StandardClassBPositionReport_Valid", 
    "ShipStaticData_AisVersion", "ShipStaticData_CallSign", "ShipStaticData_Destination", 
    "ShipStaticData_Dimension_A", "ShipStaticData_Dimension_B", "ShipStaticData_Dimension_C", 
    "ShipStaticData_Dimension_D", "ShipStaticData_Dte", "ShipStaticData_Eta_Day", 
    "ShipStaticData_Eta_Hour", "ShipStaticData_Eta_Minute", "ShipStaticData_Eta_Month", 
    "ShipStaticData_FixType", "ShipStaticData_ImoNumber", "ShipStaticData_MaximumStaticDraught", 
    "ShipStaticData_MessageID", "ShipStaticData_Name", "ShipStaticData_RepeatIndicator", 
    "ShipStaticData_Spare", "ShipStaticData_Type", "ShipStaticData_UserID", 
    "ShipStaticData_Valid", "StaticDataReport_MessageID", "StaticDataReport_PartNumber", 
    "StaticDataReport_RepeatIndicator", "StaticDataReport_ReportA_Name", 
    "StaticDataReport_ReportA_Valid", "StaticDataReport_ReportB_CallSign", 
    "StaticDataReport_ReportB_Dimension_A", "StaticDataReport_ReportB_Dimension_B", 
    "StaticDataReport_ReportB_Dimension_C", "StaticDataReport_ReportB_Dimension_D", 
    "StaticDataReport_ReportB_FixType", "StaticDataReport_ReportB_ShipType", 
    "StaticDataReport_ReportB_Spare", "StaticDataReport_ReportB_Valid", 
    "StaticDataReport_ReportB_VenderIDModel", "StaticDataReport_ReportB_VenderIDSerial", 
    "StaticDataReport_ReportB_VendorIDName", "StaticDataReport_Reserved", 
    "StaticDataReport_UserID", "StaticDataReport_Valid", 
    "BaseStationReport_CommunicationState", "BaseStationReport_FixType", 
    "BaseStationReport_Latitude", "BaseStationReport_LongRangeEnable", 
    "BaseStationReport_Longitude", "BaseStationReport_MessageID", 
    "BaseStationReport_PositionAccuracy", "BaseStationReport_Raim", 
    "BaseStationReport_RepeatIndicator", "BaseStationReport_Spare", 
    "BaseStationReport_UserID", "BaseStationReport_UtcDay", 
    "BaseStationReport_UtcHour", "BaseStationReport_UtcMinute", 
    "BaseStationReport_UtcMonth", "BaseStationReport_UtcSecond", 
    "BaseStationReport_UtcYear", "BaseStationReport_Valid", 
    "ExtendedClassBPositionReport_AssignedMode", "ExtendedClassBPositionReport_Cog", 
    "ExtendedClassBPositionReport_Dimension_A", "ExtendedClassBPositionReport_Dimension_B", 
    "ExtendedClassBPositionReport_Dimension_C", "ExtendedClassBPositionReport_Dimension_D", 
    "ExtendedClassBPositionReport_Dte", "ExtendedClassBPositionReport_FixType", 
    "ExtendedClassBPositionReport_Latitude", "ExtendedClassBPositionReport_Longitude", 
    "ExtendedClassBPositionReport_MessageID", "ExtendedClassBPositionReport_Name", 
    "ExtendedClassBPositionReport_PositionAccuracy", "ExtendedClassBPositionReport_Raim", 
    "ExtendedClassBPositionReport_RepeatIndicator", "ExtendedClassBPositionReport_Sog", 
    "ExtendedClassBPositionReport_Spare1", "ExtendedClassBPositionReport_Spare2", 
    "ExtendedClassBPositionReport_Spare3", "ExtendedClassBPositionReport_Timestamp", 
    "ExtendedClassBPositionReport_TrueHeading", "ExtendedClassBPositionReport_Type", 
    "ExtendedClassBPositionReport_UserID", "ExtendedClassBPositionReport_Valid", 
    "Interrogation_MessageID", "Interrogation_RepeatIndicator", 
    "Interrogation_Spare", "Interrogation_Station1Msg1_MessageID", 
    "Interrogation_Station1Msg1_SlotOffset", "Interrogation_Station1Msg1_StationID", 
    "Interrogation_Station1Msg1_Valid", "Interrogation_Station1Msg2_MessageID", 
    "Interrogation_Station1Msg2_SlotOffset", "Interrogation_Station1Msg2_Spare", 
    "Interrogation_Station1Msg2_Valid", "Interrogation_Station2_MessageID", 
    "Interrogation_Station2_SlotOffset", "Interrogation_Station2_Spare1", 
    "Interrogation_Station2_Spare2", "Interrogation_Station2_StationID", 
    "Interrogation_Station2_Valid", "Interrogation_UserID", 
    "Interrogation_Valid", "AddressedBinaryMessage_ApplicationID_DesignatedAreaCode", 
    "AddressedBinaryMessage_ApplicationID_FunctionIdentifier", "AddressedBinaryMessage_ApplicationID_Valid", 
    "AddressedBinaryMessage_BinaryData", "AddressedBinaryMessage_DestinationID", 
    "AddressedBinaryMessage_MessageID", "AddressedBinaryMessage_RepeatIndicator", 
    "AddressedBinaryMessage_Retransmission", "AddressedBinaryMessage_Sequenceinteger", 
    "AddressedBinaryMessage_Spare", "AddressedBinaryMessage_UserID", 
    "AddressedBinaryMessage_Valid", "AidsToNavigationReport_AssignedMode", 
    "AidsToNavigationReport_AtoN", "AidsToNavigationReport_Dimension_A", 
    "AidsToNavigationReport_Dimension_B", "AidsToNavigationReport_Dimension_C", 
    "AidsToNavigationReport_Dimension_D", "AidsToNavigationReport_Fixtype", 
    "AidsToNavigationReport_Latitude", "AidsToNavigationReport_Longitude", 
    "AidsToNavigationReport_MessageID", "AidsToNavigationReport_Name", 
    "AidsToNavigationReport_NameExtension", "AidsToNavigationReport_OffPosition", 
    "AidsToNavigationReport_PositionAccuracy", "AidsToNavigationReport_Raim", 
    "AidsToNavigationReport_RepeatIndicator", "AidsToNavigationReport_Spare", 
    "AidsToNavigationReport_Timestamp", "AidsToNavigationReport_Type", 
    "AidsToNavigationReport_UserID", "AidsToNavigationReport_Valid", 
    "AidsToNavigationReport_VirtualAtoN", "BinaryAcknowledge_Destinations_0_DestinationID", 
    "BinaryAcknowledge_Destinations_0_Sequenceinteger", "BinaryAcknowledge_Destinations_0_Valid", 
    "BinaryAcknowledge_Destinations_1_DestinationID", "BinaryAcknowledge_Destinations_1_Sequenceinteger", 
    "BinaryAcknowledge_Destinations_1_Valid", "BinaryAcknowledge_Destinations_2_DestinationID", 
    "BinaryAcknowledge_Destinations_2_Sequenceinteger", "BinaryAcknowledge_Destinations_2_Valid", 
    "BinaryAcknowledge_Destinations_3_DestinationID", "BinaryAcknowledge_Destinations_3_Sequenceinteger", 
    "BinaryAcknowledge_Destinations_3_Valid", "BinaryAcknowledge_MessageID", 
    "BinaryAcknowledge_RepeatIndicator", "BinaryAcknowledge_Spare", 
    "BinaryAcknowledge_UserID", "BinaryAcknowledge_Valid"
  )
  
  # Ensure the environment for storing the WebSocket object exists
  if (!exists(".aisstream_env")) {
    .aisstream_env <- new.env()
  }
  
  # Reset the shutdown flag
  .aisstream_env$is_shutting_down <- FALSE
  
  ws <- NULL
  
  start_connection <- function() {
    
    ws <- WebSocket$new(
      "wss://stream.aisstream.io/v0/stream",
      autoConnect = FALSE
    )
    
    # Store the WebSocket object in the dedicated environment
    .aisstream_env$ws <- ws
    
    subscription_message <- jsonlite::toJSON(
      list(
        APIKey = api_key,
        BoundingBoxes = bounding_box
      ),
      auto_unbox = TRUE
    )
    
    ws$onOpen(function(event) {
      cat("Connected!\n")
      ws$send(subscription_message)
      
      # Heartbeat
      if (!is.null(heartbeat_interval)) {
        heartbeat_fun <- function() {
          if (!is.null(ws) && ws$readyState() == 1L && !isTRUE(.aisstream_env$is_shutting_down)) {
            ws$send('{"ping":1}')
            .aisstream_env$heartbeat_handle <- later::later(heartbeat_fun, heartbeat_interval)
          }
        }
        .aisstream_env$heartbeat_handle <- later::later(heartbeat_fun, heartbeat_interval)
      }
    })
    
    ws$onMessage(function(event) {
      msg <- event$data
      if (length(msg) > 1) msg <- paste(msg, collapse = "")
      
      decoded <- tryCatch(aisstreamR::decode_ais_hex(msg), error = function(e) {
        cat("Decoding error:", e$message, "\n")
        NULL
      })
      
      if (!is.null(decoded)) {
        
        # Extract and print only the requested fields
        mmsi <- decoded$MetaData$MMSI
        ship_name <- decoded$MetaData$ShipName
        lat <- decoded$MetaData$latitude
        lon <- decoded$MetaData$longitude
        time_utc <- as.POSIXct(decoded$MetaData$time_utc, tz="UTC")
        
        cat(
          "⚓️ Message received: ", 
          "| ShipName =", ship_name, 
          "| MMSI =", mmsi, 
          "| Latitude =", lat, 
          "| Longitude =", lon, 
          "| TimeUTC =", time_utc, 
          "📍 \n"
        )
        
        # Save to CSV if outDir is specified
        if (!is.null(outDir)) {
          if (!dir.exists(outDir)) {
            dir.create(outDir, recursive = TRUE)
          }
          
          filename <- file.path(outDir, "ais_data.csv")
          
          # 1. Convert decoded data to a data frame
          decoded_df <- as.data.frame(
            as.list(unlist(decoded, recursive = TRUE))
          )
          
          # 2. Standardize column names
          raw_names <- names(decoded_df)
          
          # Remove the "Message" prefix and replace periods with underscores
          cleaned_names <- gsub("Message\\.", "", raw_names)
          cleaned_names <- gsub("\\.", "_", cleaned_names)
          names(decoded_df) <- cleaned_names
          
          # 3. Add missing columns with NA values
          missing_cols <- setdiff(master_ais_columns, names(decoded_df))
          if (length(missing_cols) > 0) {
            decoded_df[missing_cols] <- NA
          }
          
          # 4. Reorder the columns to match the master schema
          decoded_df <- decoded_df[, master_ais_columns]
          
          # 5. Write to CSV with a header only if the file is new
          write.table(
            decoded_df, 
            file = filename, 
            append = TRUE, 
            row.names = FALSE, 
            col.names = !file.exists(filename), 
            sep = ","
          )
        }
      }
    })
    
    ws$onClose(function(event) {
      # Check the shutdown flag before attempting to reconnect
      if (!isTRUE(.aisstream_env$is_shutting_down)) {
        cat("WebSocket closed. Reconnecting in", reconnect_delay, "seconds...\n")
        # Store the returned function handle
        .aisstream_env$reconnect_handle <- later::later(start_connection, reconnect_delay)
      } else {
        cat("WebSocket closed gracefully.\n")
      }
    })
    
    ws$onError(function(event) {
      cat("WebSocket error:", event$message, "\n")
    })
    
    ws$connect()
  }
  
  start_connection()
  return(ws)
  
}

#' #' Connect to AISStream WebSocket and receive messages. Sign up here: https://aisstream.io/apikeys
#' #'
#' #' @param api_key Your AISStream API key as a string.
#' #' @param bounding_box List of coordinates: list(list(c(lat1, lon1), c(lat2, lon2)))
#' #' @param reconnect_delay Seconds to wait before reconnecting after a disconnect (default: 5)
#' #' @param heartbeat_interval Seconds between optional heartbeat messages (default: NULL, no heartbeat)
#' #' @param outDir Character string specifying the output directory to save data. If NULL, data is not saved.
#' #' @return A WebSocket object
#' #' @export
#' connect_ais_stream <- function(api_key, bounding_box, reconnect_delay = 5, heartbeat_interval = NULL, outDir = NULL) {
#' 
#'   library(websocket)
#'   library(jsonlite)
#'   library(later)
#' 
#'   # Reset the shutdown flag
#'   .aisstream_env$is_shutting_down <- FALSE
#' 
#'   ws <- NULL
#' 
#'   start_connection <- function() {
#' 
#'     ws <- WebSocket$new(
#'       "wss://stream.aisstream.io/v0/stream",
#'       autoConnect = FALSE
#'     )
#' 
#'     # Store the WebSocket object in the dedicated environment
#'     .aisstream_env$ws <- ws
#' 
#'     subscription_message <- jsonlite::toJSON(
#'       list(
#'         APIKey = api_key,
#'         BoundingBoxes = bounding_box
#'       ),
#'       auto_unbox = TRUE
#'     )
#' 
#'     ws$onOpen(function(event) {
#'       cat("Connected!\n")
#'       ws$send(subscription_message)
#' 
#'       # Heartbeat
#'       if (!is.null(heartbeat_interval)) {
#'         heartbeat_fun <- function() {
#'           if (!is.null(ws) && ws$readyState() == 1L && !isTRUE(.aisstream_env$is_shutting_down)) {
#'             ws$send('{"ping":1}')
#'             .aisstream_env$heartbeat_handle <- later::later(heartbeat_fun, heartbeat_interval)
#'           }
#'         }
#'         .aisstream_env$heartbeat_handle <- later::later(heartbeat_fun, heartbeat_interval)
#'       }
#'     })
#' 
#'     ws$onMessage(function(event) {
#'       msg <- event$data
#'       if (length(msg) > 1) msg <- paste(msg, collapse = "")
#' 
#'       cat("[Message received]:\n", msg, "\n")
#' 
#'       decoded <- tryCatch(aisstreamR::decode_ais_hex(msg), error = function(e) {
#'         cat("Decoding error:", e$message, "\n")
#'         NULL
#'       })
#' 
#'       if (!is.null(decoded)) {
#'         print(decoded)
#' 
#'         # Save to CSV if outDir is specified
#'         if (!is.null(outDir)) {
#'           if (!dir.exists(outDir)) {
#'             dir.create(outDir, recursive = TRUE)
#'           }
#' 
#'           filename <- file.path(outDir, "ais_data.csv")
#' 
#'           # Convert decoded data to a data frame, handling nested lists
#'           decoded_df <- as.data.frame(
#'             as.list(unlist(decoded, recursive = TRUE))
#'           )
#' 
#'           if (!file.exists(filename)) {
#'             # Write header if file doesn't exist
#'             write.csv(decoded_df, file = filename, row.names = FALSE)
#'           } else {
#'             # Append data without header if file exists
#'             write.table(decoded_df, file = filename, append = TRUE, row.names = FALSE, col.names = FALSE, sep = ",")
#'           }
#'         }
#'       }
#'     })
#' 
#'     ws$onClose(function(event) {
#'       # Check the shutdown flag before attempting to reconnect
#'       if (!isTRUE(.aisstream_env$is_shutting_down)) {
#'         cat("WebSocket closed. Reconnecting in", reconnect_delay, "seconds...\n")
#'         # Store the returned function handle
#'         .aisstream_env$reconnect_handle <- later::later(start_connection, reconnect_delay)
#'       } else {
#'         cat("WebSocket closed gracefully.\n")
#'       }
#'     })
#' 
#'     ws$onError(function(event) {
#'       cat("WebSocket error:", event$message, "\n")
#'     })
#' 
#'     ws$connect()
#'   }
#' 
#'   start_connection()
#'   return(ws)
#' 
#' }