#' Receive real-time vessel AIS messages.
#'
#' Connect through the AISStream.io WebSocket to receive real-time vessel AIS messages for a specified bounding box or spatial file.
#'
#' @param api_key Your AISStream API key as a string.
#' @param bounding_box List of coordinates: list(list(c(lat1, lon1), c(lat2, lon2))).
#' @param file_path Character string to a shapefile, KML, or KMZ file.
#' @param layer Character string specifying the layer name in the file if it contains multiple layers.
#' @param verbose Logical. If TRUE, status messages will be printed to the console (default: TRUE).
#' @param reconnect_delay Seconds to wait before reconnecting after a disconnect (default: 5)
#' @param heartbeat_interval Seconds between optional heartbeat messages (default: NULL, no heartbeat)
#' @param outDir Character string specifying the output directory to save data. If NULL, data is not saved.
#' @return A WebSocket object
#' @export
#' @importFrom utils write.table
connect_ais_stream <- function(api_key, bounding_box = NULL, file_path = NULL, layer = NULL, verbose = TRUE, reconnect_delay = 5, heartbeat_interval = NULL, outDir = NULL) {
  
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
    "StaticDataReport_ReportB_Spare", "StaticDataReport_ReportB_VenderIDModel",  
    "StaticDataReport_ReportB_VenderIDSerial", "StaticDataReport_ReportB_VendorIDName",  
    "StaticDataReport_Reserved", "StaticDataReport_UserID", "StaticDataReport_Valid",  
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
  
  if (!exists(".aisstream_env")) {
    .aisstream_env <- new.env()
  }
  
  .aisstream_env$is_shutting_down <- FALSE
  
  ws <- NULL
  
  if (!is.null(bounding_box) && !is.null(file_path)) {
    stop("Please provide either a 'bounding_box' or a 'file_path', but not both.")
  }
  
  if (is.null(bounding_box) && is.null(file_path)) {
    stop("Either a 'bounding_box' or a 'file_path' must be provided.")
  }
  
  ais_polygon <- NULL
  bbox_api <- bounding_box
  
  if (!is.null(file_path)) {
    tryCatch({
      ais_polygon <- sf::st_read(file_path, layer = layer, quiet = TRUE)
      if (sf::st_crs(ais_polygon) != sf::st_crs(4326)) {
        ais_polygon <- sf::st_transform(ais_polygon, crs = 4326)
      }
      if (verbose) {
        cat("Successfully loaded spatial file for filtering.\n")
      }
    }, error = function(e) {
      stop("Error reading spatial file: ", e$message)
    })
    
    bbox_sf <- sf::st_bbox(ais_polygon)
    
    bbox_api <- list(
      list(
        # Bottom-left corner: [ymin, xmin]
        c(bbox_sf["ymin"], bbox_sf["xmin"]),
        # Top-right corner: [ymax, xmax]
        c(bbox_sf["ymax"], bbox_sf["xmax"])
      )
    )
  }
  
  # Initialize a list to store data frame rows and set the batch size
  .aisstream_env$batch_list <- list()
  .aisstream_env$batch_size <- 500
  
  start_connection <- function() {
    
    ws <- websocket::WebSocket$new(
      "wss://stream.aisstream.io/v0/stream",
      autoConnect = FALSE
    )
    
    .aisstream_env$ws <- ws
    
    subscription_message <- jsonlite::toJSON(
      list(
        APIKey = api_key,
        BoundingBoxes = bbox_api
      ),
      auto_unbox = TRUE
    )
    
    ws$onOpen(function(event) {
      if (verbose) {
        cat(" 🛜 Connected!                                          🛜\n")
      }
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
        if (verbose) {
          cat("Decoding error:", e$message, "\n")
        }
        NULL
      })
      
      if (!is.null(decoded)) {
        
        is_in_poly <- TRUE
        if (!is.null(ais_polygon)) {
          lat <- decoded$MetaData$latitude
          lon <- decoded$MetaData$longitude
          
          if (!is.null(lat) && !is.null(lon)) {
            point_sf <- sf::st_point(c(lon, lat))
            is_in_poly <- as.logical(sf::st_intersects(point_sf, ais_polygon, sparse = FALSE))
          } else {
            is_in_poly <- FALSE # Exclude messages without lat/lon
          }
        }
        
        if (is_in_poly) {
          
          mmsi <- decoded$MetaData$MMSI
          ship_name <- decoded$MetaData$ShipName
          
          lat <- decoded$MetaData$latitude
          lon <- decoded$MetaData$longitude
          formatted_lat <- sprintf("%9.6f", lat)
          formatted_lon <- sprintf("%9.6f", lon)
          
          time_utc <- decoded$MetaData$time_utc
          time_sast <- as.POSIXct(
            format(
              lubridate::ymd_hms(time_utc), 
              tz = "Africa/Johannesburg"
            )
          )
          
            
          if (verbose) {
            cat(
              " ---------------------------------------------------------", "\n",
              "📧                 NEW MESSAGE RECEIVED                📧", "\n",
              "⚓️ ShipName =", ship_name, "\n",
              "⚓️ MMSI =", mmsi, "\n",
              "⚓️ TimeSAST =", format(time_sast,
                                     "%Y-%m-%d %H:%M:%S %Z"),
              "  \n",
              
              "⚓️ Latitude =", formatted_lat, "| Longitude =", formatted_lon, 
              "      📍\n",
              
              "---------------------------------------------------------", "\n"
            )
          }
          
          # Save to CSV if outDir is specified
          if (!is.null(outDir)) {
            if (!dir.exists(outDir)) {
              dir.create(outDir, recursive = TRUE)
            }
            
            filename <- file.path(outDir, "ais_data.csv")
            
            # Convert decoded data to a data frame
            decoded_df <- as.data.frame(
              as.list(unlist(decoded, recursive = TRUE))
            )
            
            # Standardize column names
            raw_names <- names(decoded_df)
            
            cleaned_names <- gsub("Message\\.", "", raw_names)
            cleaned_names <- gsub("\\.", "_", cleaned_names)
            names(decoded_df) <- cleaned_names
            
            # Add missing columns with NA values
            missing_cols <- setdiff(master_ais_columns, names(decoded_df))
            if (length(missing_cols) > 0) {
              decoded_df[missing_cols] <- NA
            }
            
            # Reorder the columns to match the master list
            decoded_df <- decoded_df[, master_ais_columns]
            
            # Add data to batch list
            .aisstream_env$batch_list[[length(.aisstream_env$batch_list) + 1]] <- decoded_df
            
            # Check if the batch is full
            if (length(.aisstream_env$batch_list) >= .aisstream_env$batch_size) {
              
              # Combine all data frames in the list into one
              full_batch <- do.call(rbind, .aisstream_env$batch_list)
              
              # Write the entire batch to the CSV file
              filename <- file.path(outDir, "ais_data.csv")
              write.table(
                full_batch,
                file = filename,
                append = TRUE,
                row.names = FALSE,
                col.names = !file.exists(filename),
                sep = ","
              )
              
              # Clear the batch list for the next batch
              .aisstream_env$batch_list <- list()
              if (verbose) {
                cat("Wrote a batch of", .aisstream_env$batch_size, "messages to CSV.\n")
              }
            }
            # Write to CSV with a header only if the file is new
            # write.table(
            #   decoded_df, 
            #   file = filename, 
            #   append = TRUE, 
            #   row.names = FALSE, 
            #   col.names = !file.exists(filename), 
            #   sep = ","
            # )
          }
        }
      }
    })
    
    ws$onClose(function(event) {
      if (!isTRUE(.aisstream_env$is_shutting_down)) {
        if (verbose) {
          cat("WebSocket closed. Reconnecting in", reconnect_delay, "seconds...\n")
        }
        
        # New code to write remaining batch data
        if (length(.aisstream_env$batch_list) > 0) {
          if (verbose) {
            cat("Writing remaining", length(.aisstream_env$batch_list), "messages to CSV before reconnecting...\n")
          }
          full_batch <- do.call(rbind, .aisstream_env$batch_list)
          filename <- file.path(outDir, "ais_data.csv")
          write.table(
            full_batch,
            file = filename,
            append = TRUE,
            row.names = FALSE,
            col.names = !file.exists(filename),
            sep = ","
          )
          .aisstream_env$batch_list <- list() # Clear the list
        }
        
        .aisstream_env$reconnect_handle <- later::later(start_connection, reconnect_delay)
      } else {
        # This part handles intentional shutdown, so also write the batch
        if (verbose) {
          message(" 🪦 AIS WebSocket rests peacefully...\n")
        }
        
        # New code to write final batch on intentional shutdown
        if (length(.aisstream_env$batch_list) > 0) {
          if (verbose) {
            cat("Writing final", length(.aisstream_env$batch_list), "messages to CSV...\n")
          }
          full_batch <- do.call(rbind, .aisstream_env$batch_list)
          filename <- file.path(outDir, "ais_data.csv")
          write.table(
            full_batch,
            file = filename,
            append = TRUE,
            row.names = FALSE,
            col.names = !file.exists(filename),
            sep = ","
          )
          .aisstream_env$batch_list <- list() # Clear the list
        }
      }
    })
    # ws$onClose(function(event) {
    #   if (!isTRUE(.aisstream_env$is_shutting_down)) {
    #     if (verbose) {
    #       cat("WebSocket closed. Reconnecting in", reconnect_delay, "seconds...\n")
    #     }
    #     .aisstream_env$reconnect_handle <- later::later(start_connection, reconnect_delay)
    #   } else {
    #     if (verbose) {
    #       message(" 🪦 AIS WebSocket rests peacefully...\n")
    #     }
    #   }
    # })
    
    ws$onError(function(event) {
      if (verbose) {
        cat("WebSocket error:", event$message, "\n")
      }
    })
    
    ws$connect()
  }
  
  start_connection()
  return(ws)
}