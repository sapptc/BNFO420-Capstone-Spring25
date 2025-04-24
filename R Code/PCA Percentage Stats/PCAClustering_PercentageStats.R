# Load required libraries
library(readxl)
library(tidyverse)
library(FactoMineR)
library(factoextra)
library(ggrepel)
library(ggplot2)

# Set path to the uploaded Excel file
file_path <- "/Users/shreya/Documents/Aggregate Data/Non-COVID Stat/All Data - Non COVID.xlsx"

# Step 1: Read all sheet names
sheet_names <- excel_sheets(file_path)

# Step 2: Read each sheet as character
read_sheet_as_char <- function(sheet) {
  df <- read_excel(file_path, sheet = sheet)
  df[] <- lapply(df, as.character)  # force all to character
  df$sheet_source <- sheet  # tag with sheet name
  return(df)
}

# Step 3: Read and combine all sheets
combined_data_raw <- map_dfr(sheet_names, read_sheet_as_char)

# Step 4: Filter out rows with "Difference" in Season Group (if it exists)
if ("Season Group" %in% colnames(combined_data_raw)) {
  combined_data_filtered <- combined_data_raw %>%
    filter(!str_detect(`Season Group`, "Difference"))
} else {
  combined_data_filtered <- combined_data_raw
}

# Step 5: Identify ID columns
possible_ids <- c("Player", "Category", "Season Group", "sheet_source")
existing_ids <- intersect(possible_ids, colnames(combined_data_filtered))

# Step 6: Convert remaining columns to numeric
numeric_data <- combined_data_filtered %>%
  select(-all_of(existing_ids)) %>%
  mutate(across(everything(), ~ suppressWarnings(as.numeric(.))))

# Step 7: Impute missing values
numeric_data <- as.data.frame(apply(numeric_data, 2, function(x) {
  x[is.na(x)] <- mean(x, na.rm = TRUE)
  x
}))

# Step 8: Extract metadata for plotting
plot_meta <- combined_data_filtered %>% select(all_of(existing_ids))

# Step 9: Perform PCA
pca_result <- PCA(numeric_data, graph = FALSE)

# Step 10: Plot PCA by Category (if it exists)
if ("Category" %in% colnames(plot_meta)) {
  fviz_pca_ind(pca_result,
               geom.ind = "point",
               col.ind = plot_meta$Category,
               palette = c("#00AFBB", "#FC4E07"),
               addEllipses = TRUE,
               legend.title = "Category",
               title = "PCA - Clustering by Category")
} else {
  fviz_pca_ind(pca_result,
               geom.ind = "point",
               col.ind = "black",
               title = "PCA - Individuals")
}

# Step 11: Scree plot
fviz_eig(pca_result, addlabels = TRUE, main = "Scree Plot")

# Step 12: PCA Biplot
fviz_pca_biplot(pca_result,
                col.ind = if ("Category" %in% colnames(plot_meta)) plot_meta$Category else "black",
                palette = c("#00AFBB", "#FC4E07"),
                addEllipses = TRUE,
                legend.title = "Category",
                title = "PCA Biplot")

# Step 13: Top contributing variables
fviz_contrib(pca_result, choice = "var", axes = 1, top = 10)
fviz_contrib(pca_result, choice = "var", axes = 2, top = 10)

# Step 14: Dim 1 vs 3 biplot
fviz_pca_biplot(pca_result,
                axes = c(1, 3),
                col.ind = if ("Category" %in% colnames(plot_meta)) plot_meta$Category else "black",
                palette = c("#1F78B4", "#E31A1C"),
                addEllipses = TRUE,
                ellipse.type = "confidence",
                legend.title = "Category",
                title = "PCA Biplot - Dim 1 vs 3",
                repel = TRUE) +
  theme_minimal()

# Step 15: Variable correlation plot
fviz_pca_var(pca_result,
             axes = c(1, 3),
             col.var = "contrib",
             gradient.cols = c("blue", "yellow", "red"),
             repel = TRUE,
             title = "Variable Correlation Map (Dim1 vs Dim3)") +
  theme_minimal()