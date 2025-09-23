# aisstreamR

![How to](images/connect_ais_stream.gif)

### Install devtools if needed
```install.packages("devtools")```

### Build & install locally
`devtools::install_github("PhilipFaure/aisstreamR")`

### Example usage:
```library(aisstreamR)```

```api_key <- "YOUR_API_KEY"```

```
bbox <- list(
  list(
    list(-33.90081, 18.39103), 
    list(-33.82374, 18.47033)
  )
)
```
```ws <- connect_ais_stream(api_key, bbox)```

### ws will remain connected, messages printed automatically
### To disconnect manually:
```close_ais_stream()```
