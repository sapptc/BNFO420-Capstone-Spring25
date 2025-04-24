# Load required packages
library(dplyr)
library(readr)
library(purrr)

# Define the base path for your data (adjust to your local path)
data_path <- "NON-COVID Player Stats"

# List all CSV files in the folder and its subfolders
all_files <- list.files(path = data_path, pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)

# Function to read a file, extract the position from its folder name, and add that as a column
read_data <- function(file) {
  # Split file path using the platform's file separator
  split_path <- strsplit(file, .Platform$file.sep)[[1]]
  # Assume the structure: "NFL Player Stats" is the first folder and the position is in the second folder.
  # Adjust the index if your file paths differ.
  pos <- split_path[2]
  df <- read_csv(file)
  df <- mutate(df, Position = pos)
  return(df)
}

# Combine all files into one data frame
all_data <- map_df(all_files, read_data)

# Define the positions by category:
endurance_positions <- c("WR", "RB", "CB", "S", "LB", "FS", "SS", "KR", "PR")
power_positions <- c("OL", "DL", "FB", "TE", "MLB", "OLB", "P", "K", "QB")

# Create a new column for position category
all_data <- all_data %>%
  mutate(Position_Category = case_when(
    Position %in% endurance_positions ~ "Endurance",
    Position %in% power_positions ~ "Power",
    TRUE ~ NA_character_
  ))

# (Optional) Preview the data
head(all_data)
