# aisstreamR

![How to](https://github.com/PhilipFaure/aisstreamR/blob/main/images/connect_ais_stream.gif)


### Build & install locally
```devtools::install_github("PhilipFaure/aisstreamR")```

### Example usage:
```
library(aisstreamR)

api_key <- "YOUR_API_KEY"

bbox <- list(
  list(
    list(-33.90081, 18.39103), 
    list(-33.82374, 18.47033)
  )
)

ws <- connect_ais_stream(api_key, bbox)

close_ais_stream()
```
