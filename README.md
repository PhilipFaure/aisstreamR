# aisstreamR ⚓️

![How to](https://github.com/PhilipFaure/aisstreamR/blob/main/images/connect_ais_stream.gif)

### Description ⚓️

`aisstreamR` is an R package that provides a simple and reliable way to connect to the AISStream WebSocket API. It allows users to stream real-time maritime data, including vessel positions, ship names, and other critical information, directly into their R environment. This data can be used for research, data analysis, or real-time monitoring of maritime traffic within a specified geographic area.

The package handles WebSocket connections, subscribes to data streams based on user-defined bounding boxes, and decodes the incoming AIS messages into a user-friendly format. It also includes an option to automatically save the received data to a CSV file.

---

### Installation ⚓️
```devtools::install_github("PhilipFaure/aisstreamR")```

### How to use ⚓️
##### 1. Obtain and API key from https://aisstream.io/apikeys
##### 2. Connect to the Stream
Use the connect_ais_stream() function to start receiving real-time data. You'll need to provide your API key and the coordinates for the bounding box you want to monitor.
The connect_ais_stream() function will open a persistent WebSocket connection. As long as your R session is running, messages will be received and processed automatically. Each message will be printed to your console in a clean format and, if you've specified a directory, saved to a CSV file.
##### 3. Disconnect
To close the connection and stop receiving data, you can use the `close_ais_stream()` function.

---

### Key Functions ⚓️

    `connect_ais_stream()`: Establishes a WebSocket connection and begins streaming data.

    `close_ais_stream()`: Closes the active WebSocket connection.

    `decode_ais_hex()`: Decodes raw hexadecimal AIS messages into a structured R object (used internally by connect_ais_stream).

---

### Example ⚓️
```
# load package
library(aisstreamR)

# add API key
api_key <- "YOUR_API_KEY"

# provide bounding box coordinates
bbox <- list(
  list(
    list(-33.90081, 18.39103), 
    list(-33.82374, 18.47033)
  )
)

# open connection and stream AIS messages
ws <- connect_ais_stream(api_key, bbox)

# close connection
close_ais_stream()
```

---
