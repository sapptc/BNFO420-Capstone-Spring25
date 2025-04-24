# Load required libraries
library(readxl)
library(tidyverse)
library(FactoMineR)
library(factoextra)

# Set working directory to the folder containing the Excel files
setwd("/Users/aaronalexander/Downloads/football_stats") # Uncomment and set your path

# Get list of all standardized output files, excluding temporary Excel files
file_list <- list.files(pattern = "*standardized_output_noncovid.xlsx$") %>% 
  .[!str_detect(., "^~\\$")]  # This excludes temporary files (starting with ~$)

# Check if any files remain
if (length(file_list) == 0) {
  stop("No valid files found after filtering.")
}

# Function to read and process each Excel file
read_process_file <- function(file) {
  # Read the Excel file
  data <- read_excel(file)
  
  # Identify which columns are numeric (excluding Player and Category)
  numeric_cols <- sapply(data, is.numeric)
  
  # Convert all numeric columns to numeric type (in case some were read as character)
  data[, numeric_cols] <- lapply(data[, numeric_cols], as.numeric)
  
  return(data)
}

# Read and combine all files with error handling
combined_data <- map_dfr(file_list, safely(read_process_file))$result %>% 
  compact() %>% 
  bind_rows()


# Remove rows with "Difference" in Season Group as they represent changes, not original values
combined_data <- combined_data %>% 
  filter(!str_detect(`Season Group`, "Difference"))

# Select only numeric columns for PCA (excluding Player and Category)
numeric_data <- combined_data %>% 
  select(where(is.numeric))

# Check for missing values
if (any(is.na(numeric_data))) {
  # Impute missing values with column means
  numeric_data <- as.data.frame(apply(numeric_data, 2, function(x) {
    x[is.na(x)] <- mean(x, na.rm = TRUE)
    x
  }))
}

# Perform PCA
pca_result <- PCA(numeric_data, graph = FALSE)

# Visualize PCA results with Category as grouping variable
fviz_pca_ind(pca_result,
             geom.ind = "point",
             col.ind = combined_data$Category,
             palette = c("#00AFBB", "#FC4E07"),
             addEllipses = TRUE,
             legend.title = "Category",
             title = "PCA - Clustering by Category (Power vs Endurance)")

# Scree plot
fviz_eig(pca_result, addlabels = TRUE, main = "Scree Plot - Variance Explained by PCs")

# Biplot
fviz_pca_biplot(pca_result, 
                col.ind = combined_data$Category,
                palette = c("#00AFBB", "#FC4E07"),
                addEllipses = TRUE,
                legend.title = "Category",
                title = "PCA Biplot - Variables and Individuals")

# Variable contributions to principal components
fviz_contrib(pca_result, choice = "var", axes = 1, top = 10)
fviz_contrib(pca_result, choice = "var", axes = 2, top = 10)

# Summary of PCA results
summary(pca_result)

# Load required packages (if not already loaded)
library(FactoMineR)
library(factoextra)
library(ggrepel)
library(ggplot2)

# 1. Scree Plot with Variance Threshold
scree_plot <- fviz_eig(pca_result, 
                       choice = "eigenvalue", 
                       addlabels = TRUE,
                       hline = c(1, 0.5),  # Kaiser criterion lines
                       geom = c("bar", "line"),
                       barfill = "steelblue",
                       main = "Scree Plot - Identifying Significant Dimensions") +
  theme_minimal()

print(scree_plot)

# 2. Enhanced Biplot (Dim1 vs Dim3)
biplot <- fviz_pca_biplot(pca_result,
                          axes = c(1, 3),  # Focus on dimensions 1 and 3
                          col.ind = combined_data$Category,
                          palette = c("#1F78B4", "#E31A1C"),
                          addEllipses = TRUE,
                          ellipse.type = "confidence",
                          ellipse.level = 0.95,
                          legend.title = "Category",
                          title = "PCA Biplot - Defensive vs Offensive Profiles",
                          repel = TRUE) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(biplot)

# 3. Dimension Contribution Plot (corrected)
contrib_plot <- fviz_contrib(pca_result,
                             choice = "var",
                             axes = 1:3,  # First 3 dimensions
                             top = 10,
                             fill = "steelblue",
                             title = "Variable Contributions to Key Dimensions") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(contrib_plot)

# 4. Variable Correlation Plot (alternative to fviz_contrib)
var_plot <- fviz_pca_var(pca_result,
                         axes = c(1, 3),
                         col.var = "contrib",
                         gradient.cols = c("blue", "yellow", "red"),
                         repel = TRUE,
                         title = "Variable Contribution Map (Dim1 vs Dim3)") +
  theme_minimal()

print(var_plot)

##############################################
### ENHANCED CLUSTERING VISUALIZATIONS ###
##############################################
# 1. Scree Plot with Variance Threshold
scree_plot <- fviz_eig(pca_result, 
                       choice = "eigenvalue", 
                       addlabels = TRUE,
                       hline = c(1, 0.5),  # Kaiser criterion lines
                       geom = c("bar", "line"),
                       barfill = "steelblue",
                       main = "Scree Plot - Identifying Significant Dimensions") +
  theme_minimal()

print(scree_plot)

# 4. Variable Correlation Plot
var_plot <- fviz_pca_var(pca_result,
                         axes = c(1, 2),
                         col.var = "contrib",
                         gradient.cols = c("blue", "yellow", "red"),
                         repel = TRUE,
                         title = "Variable Contribution Map (Dim1 vs Dim2)") +
  theme_minimal()

print(var_plot)


# Add Position Grouping manually if not already in data
library(ggplot2)
library(dplyr)

# Group positions
combined_data <- combined_data %>%
  mutate(PositionGroup = case_when(
    Position %in% c("QB", "RB", "WR", "TE", "FB", "OL") ~ "Offense",
    Position %in% c("DL", "LB", "CB", "S") ~ "Defense",
    Position %in% c("K", "P") ~ "Special Teams",
    TRUE ~ "Other"
  ))

# Define distinct colors manually
position_colors <- c(
  "QB" = "#E41A1C",      # red
  "RB" = "#377EB8",      # blue
  "WR" = "#4DAF4A",      # green
  "TE" = "#984EA3",      # purple
  "FB" = "#FF7F00",      # orange
  "OL" = "#A65628",      # brown
  "DL" = "#F781BF",      # pink
  "LB" = "#999999",      # grey
  "CB" = "#66C2A5",      # teal
  "S"  = "#FFD92F",      # yellow
  "K"  = "#A6D854",      # light green
  "P"  = "#FC8D62",      # salmon
  "Other" = "black"
)

# Prepare PCA coordinates with metadata
pca_coords <- as.data.frame(pca_result$ind$coord)
pca_coords$Player <- combined_data$Player
pca_coords$Position <- combined_data$Position
pca_coords$PositionGroup <- combined_data$PositionGroup

# Create the faceted PCA plot with custom colors
facet_plot <- ggplot(pca_coords, aes(x = Dim.1, y = Dim.2, color = Position)) +
  geom_jitter(width = 0.1, height = 0.1, size = 3, alpha = 0.75) +
  facet_wrap(~ PositionGroup, scales = "free") +
  scale_color_manual(values = position_colors) +
  theme_minimal() +
  labs(title = "PCA by Player Positions - Faceted View",
       x = paste0("Dim1 (", round(pca_result$eig[1, 2], 1), "%)"),
       y = paste0("Dim2 (", round(pca_result$eig[2, 2], 1), "%)"),
       color = "Position") +
  theme(legend.position = "bottom",
        legend.text = element_text(size = 9))

print(facet_plot)
