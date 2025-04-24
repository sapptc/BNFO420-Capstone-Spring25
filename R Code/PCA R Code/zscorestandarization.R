# Load required libraries
library(readxl)  # For reading Excel files
library(dplyr)   # For data manipulation
library(writexl) # For writing Excel files

# Define the file path (update if needed)
file_path <- "/Users/aaronalexander/Downloads/football_stats/FB_aggregate.xlsx"

# Read the first sheet of the Excel file
data <- read_excel(file_path)

# Display the first few rows to understand the structure
print(head(data))

# Identify numeric columns for standardization (excluding non-numeric ones)
numeric_cols <- sapply(data, is.numeric)
data_numeric <- data[, numeric_cols]

# Perform Z-score standardization: (X - mean) / SD
data_standardized <- as.data.frame(scale(data_numeric))

# Combine with non-numeric columns (if any)
data_final <- cbind(data[!numeric_cols], data_standardized)

# Define output file path
output_file <- "/Users/aaronalexander/Downloads/football_stats/FB_standardized_output.xlsx"

# Write the standardized data to an Excel file
write_xlsx(data_final, output_file)

# Print success message
cat("Standardized data has been saved to:", output_file, "\n")

