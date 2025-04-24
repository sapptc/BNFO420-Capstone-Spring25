# Load required libraries
library(readxl)
library(tidyverse)
library(FactoMineR)
library(factoextra)
library(ggrepel)
library(ggplot2)

# Set output folder path
output_folder <- "/Users/shreya/Documents/Aggregate Data"

# File paths
covid_path <- file.path(output_folder, "All Data - COVID.xlsx")
non_covid_path <- file.path(output_folder, "All Data - Non COVID.xlsx")

# Function to read and tag data
read_labeled_data <- function(file_path, label) {
  sheet_names <- excel_sheets(file_path)
  read_sheet_as_char <- function(sheet) {
    df <- read_excel(file_path, sheet = sheet)
    df[] <- lapply(df, as.character)
    df$sheet_source <- sheet
    df$Infection_Status <- label
    return(df)
  }
  map_dfr(sheet_names, read_sheet_as_char)
}

# Read datasets
covid_data_raw <- read_labeled_data(covid_path, "COVID")
non_covid_data_raw <- read_labeled_data(non_covid_path, "Non-COVID")

# Combine
combined_data_raw <- bind_rows(covid_data_raw, non_covid_data_raw)

# Filter out "Difference" rows
if ("Season Group" %in% colnames(combined_data_raw)) {
  combined_data_filtered <- combined_data_raw %>%
    filter(!str_detect(`Season Group`, "Difference"))
} else {
  combined_data_filtered <- combined_data_raw
}

# ID columns
possible_ids <- c("Player", "Category", "Season Group", "sheet_source", "Infection_Status")
existing_ids <- intersect(possible_ids, colnames(combined_data_filtered))

# Convert remaining columns to numeric
numeric_data <- combined_data_filtered %>%
  select(-all_of(existing_ids)) %>%
  mutate(across(everything(), ~ suppressWarnings(as.numeric(.))))

# Impute missing values
numeric_data <- as.data.frame(apply(numeric_data, 2, function(x) {
  x[is.na(x)] <- mean(x, na.rm = TRUE)
  x
}))

# Metadata for plotting
plot_meta <- combined_data_filtered %>% select(all_of(existing_ids))

# Run PCA
pca_result <- PCA(numeric_data, graph = FALSE)

# Save helper
save_plot <- function(plot, filename) {
  ggsave(filename = file.path(output_folder, filename), plot = plot, width = 8, height = 6)
}

# Plot 1: Individuals
p1 <- fviz_pca_ind(pca_result,
                   geom.ind = "point",
                   col.ind = plot_meta$Infection_Status,
                   shape.ind = as.factor(plot_meta$Category),
                   palette = c("#00AFBB", "#E31A1C"),
                   addEllipses = TRUE,
                   legend.title = "Infection Status",
                   title = "PCA - Clustering by COVID Status & Category") +
  theme_classic()
print(p1)
save_plot(p1, "PCA_Individuals_COVID_vs_NonCOVID.png")

# Plot 2: Scree plot
p2 <- fviz_eig(pca_result, addlabels = TRUE, main = "Scree Plot - COVID vs Non-COVID") +
  theme_classic()
print(p2)
save_plot(p2, "PCA_ScreePlot.png")

# Plot 3: Biplot
p3 <- fviz_pca_biplot(pca_result,
                      col.ind = plot_meta$Infection_Status,
                      shape.ind = as.factor(plot_meta$Category),
                      palette = c("#00AFBB", "#E31A1C"),
                      addEllipses = TRUE,
                      legend.title = "Infection Status",
                      title = "PCA Biplot - COVID vs Non-COVID") +
  theme_classic()
print(p3)
save_plot(p3, "PCA_Biplot.png")

# Plot 4: Contribution to PC1
p4 <- fviz_contrib(pca_result, choice = "var", axes = 1, top = 10) +
  ggtitle("Top 10 Contributors to PC1") +
  theme_classic()
print(p4)
save_plot(p4, "PCA_Contrib_PC1.png")

# Plot 5: Contribution to PC2
p5 <- fviz_contrib(pca_result, choice = "var", axes = 2, top = 10) +
  ggtitle("Top 10 Contributors to PC2") +
  theme_classic()
print(p5)
save_plot(p5, "PCA_Contrib_PC2.png")

# Plot 6: Dim 1 vs 3
p6 <- fviz_pca_biplot(pca_result,
                      axes = c(1, 3),
                      col.ind = plot_meta$Infection_Status,
                      shape.ind = as.factor(plot_meta$Category),
                      palette = c("#1F78B4", "#E31A1C"),
                      addEllipses = TRUE,
                      ellipse.type = "confidence",
                      legend.title = "Infection Status",
                      title = "PCA Biplot - Dim 1 vs 3 (COVID vs Non-COVID)",
                      repel = TRUE) +
  theme_classic()
print(p6)
save_plot(p6, "PCA_Biplot_Dim1_vs_3.png")

# Plot 7: Variable correlation
p7 <- fviz_pca_var(pca_result,
                   axes = c(1, 3),
                   col.var = "contrib",
                   gradient.cols = c("blue", "yellow", "red"),
                   repel = TRUE,
                   title = "Variable Correlation Map (Dim1 vs Dim3)") +
  theme_classic()
print(p7)
save_plot(p7, "PCA_Variable_Correlation_Dim1_vs_3.png")