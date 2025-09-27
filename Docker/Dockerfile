# Use a Rocker (R-specific) base image based on Ubuntu/Debian
# This image already has R installed (R 4.4.x)
FROM rocker/r-ver:4.4.2

# Set locale for proper character handling
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Install R system dependencies required for 'sf' and other packages
# libudunits2-dev, libgdal-dev, libgeos-dev, libproj-dev are crucial for spatial packages.
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy all project files into the container's working directory
COPY . /app
WORKDIR /app

# Install R package dependencies using R's package manager
# The 'aisstreamR' package itself is installed using devtools::install_local
RUN R -e "install.packages(c('devtools', 'websocket', 'jsonlite', 'lubridate', 'later', 'sf', 'RSQLite', 'httr'), repos='https://cloud.r-project.org/')"
RUN R -e "devtools::install_github('PhilipFaure/aisstreamR')"

# Install your local package (aisstreamR)
RUN R -e "devtools::install_local('./', upgrade='never')"

# Set the entrypoint command: execute the R script when the container starts
CMD ["Rscript", "run_pipeline.R"]