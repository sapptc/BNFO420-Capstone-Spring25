# Load necessary libraries
library(readxl)    # to read Excel files
library(dplyr)     # for data manipulation
library(tidyr)     # for pivoting data
library(ggplot2)   # for plotting

# List of aggregate files for each NFL position
files <- list(
  "CB" = "CB_aggregate.xlsx",
  "DL" = "DL_aggregate.xlsx",
  "FB" = "FB_aggregate.xlsx",
  "K"  = "K_aggregate.xlsx",
  "LB" = "LB_aggregate.xlsx",
  "OL" = "OL_aggregate.xlsx",
  "P"  = "P_aggregate.xlsx",
  "QB" = "QB_aggregate.xlsx",
  "RB" = "RB_aggregate.xlsx",
  "S"  = "S_aggregate.xlsx",
  "WR" = "WR_aggregate.xlsx"
)

# Initialize an empty data frame to hold all the data
all_data <- data.frame()

# Loop through each file, read it, and reshape the data
for (position in names(files)) {
  # Read the Excel file (ensure files are in your working directory)
  temp <- read_excel(files[[position]])
  
  # Pivot the data to long format, keeping 'Player' intact and gathering percentage columns
  temp_long <- temp %>%
    pivot_longer(
      cols = -Player,
      names_to = "stat",
      values_to = "percentage"
    )
  
  # Add a column for NFL position based on the file name
  temp_long$Position <- position
  
  # Combine with all_data
  all_data <- bind_rows(all_data, temp_long)
}

# Remove any rows with missing percentage values (if applicable)
all_data <- all_data %>% filter(!is.na(percentage))

# Statistical Tests

# 1. One-way ANOVA to compare means across positions
anova_result <- aov(percentage ~ Position, data = all_data)
print("ANOVA Summary:")
print(summary(anova_result))

# 2. Kruskal-Wallis test as a non-parametric alternative
kruskal_result <- kruskal.test(percentage ~ Position, data = all_data)
print("Kruskal-Wallis Test Result:")
print(kruskal_result)

# 3. One-sample t-tests for each position against a neutral 0 change
positions <- unique(all_data$Position)
t_test_results <- lapply(positions, function(pos) {
  data_pos <- subset(all_data, Position == pos)$percentage
  test <- t.test(data_pos, mu = 0)
  data.frame(Position = pos, t_statistic = test$statistic, p_value = test$p.value)
})
t_test_results <- do.call(rbind, t_test_results)
print("One-Sample t-test Results (mu = 0) by Position:")
print(t_test_results)

# Visual Graph 1: Enhanced Boxplot of percentage changes by NFL Position
boxplot <- ggplot(all_data, aes(x = Position, y = percentage, fill = percentage > 0)) +
  geom_boxplot() +
  # Add a horizontal zero line to distinguish increases vs. decreases
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  # Overlay median points for each position
  stat_summary(fun = median, geom = "point", shape = 23, size = 3, fill = "yellow") +
  theme_minimal() +
  labs(
    title = "Distribution of Percentage Changes by NFL Position",
    x = "NFL Position",
    y = "Percentage Change (%)",
    fill = "Increase?"
  ) +
  scale_fill_manual(values = c("TRUE" = "steelblue", "FALSE" = "tomato"))

print(boxplot)

# Visual Graph 2: Chart Showing Just the Medians

# Calculate the median percentage change for each NFL position
median_data <- all_data %>%
  group_by(Position) %>%
  summarise(median_percentage = median(percentage, na.rm = TRUE))

# Create a bar chart for the medians with numerical labels
median_plot <- ggplot(median_data, aes(x = Position, y = median_percentage, fill = median_percentage > 0)) +
  geom_col() +
  # Add a horizontal zero line for reference
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  # Add text labels to display the numerical median values
  geom_text(aes(label = round(median_percentage, 1), 
                vjust = ifelse(median_percentage >= 0, -0.5, 1.5))) +
  theme_minimal() +
  labs(
    title = "Median Percentage Change by NFL Position",
    x = "NFL Position",
    y = "Median Percentage Change (%)"
  ) +
  scale_fill_manual(values = c("TRUE" = "steelblue", "FALSE" = "tomato"),
                    guide = FALSE)

print(median_plot)

# Visual Graph 3: Chart Showing Just the Means

# Calculate the mean percentage change for each NFL position
mean_data <- all_data %>%
  group_by(Position) %>%
  summarise(mean_percentage = mean(percentage, na.rm = TRUE))

# Create a bar chart for the means with numerical labels
mean_plot <- ggplot(mean_data, aes(x = Position, y = mean_percentage, fill = mean_percentage > 0)) +
  geom_col() +
  # Add a horizontal zero line for reference
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  # Add text labels to display the numerical mean values
  geom_text(aes(label = round(mean_percentage, 1),
                vjust = ifelse(mean_percentage >= 0, -0.5, 1.5))) +
  theme_minimal() +
  labs(
    title = "Mean Percentage Change by NFL Position",
    x = "NFL Position",
    y = "Mean Percentage Change (%)"
  ) +
  scale_fill_manual(values = c("TRUE" = "steelblue", "FALSE" = "tomato"),
                    guide = FALSE)

print(mean_plot)

# Additional Analysis: Training Type Comparison
# Categorize positions into "Strength Based" and "Endurance Based" training groups.
all_data <- all_data %>%
  mutate(TrainingType = case_when(
    Position %in% c("DL", "OL", "FB", "LB", "QB", "K", "P") ~ "Strength Based",
    Position %in% c("CB", "RB", "S", "WR") ~ "Endurance Based",
    TRUE ~ NA_character_
  ))

# Filter out any rows where TrainingType is NA (if any)
all_data <- all_data %>% filter(!is.na(TrainingType))

# Summary statistics for each Training Type
training_summary <- all_data %>%
  group_by(TrainingType) %>%
  summarise(
    mean_percentage = mean(percentage, na.rm = TRUE),
    median_percentage = median(percentage, na.rm = TRUE),
    count = n()
  ) %>%
  # Create a column for vertical adjustment of text labels
  mutate(label_vjust = ifelse(median_percentage >= 0, -0.5, 1.5))
print("Summary statistics by Training Type:")
print(training_summary)

# Visual Graph: Boxplot for Training Type with Median Value Labels
training_boxplot <- ggplot(all_data, aes(x = TrainingType, y = percentage, fill = TrainingType)) +
  geom_boxplot() +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  # Add text labels displaying the median (rounded to an integer) for each training type
  geom_text(data = training_summary, 
            aes(x = TrainingType, y = median_percentage, label = round(median_percentage, 0), vjust = label_vjust)) +
  theme_minimal() +
  labs(title = "Percentage Change by Training Type",
       x = "Training Type",
       y = "Percentage Change (%)")
print(training_boxplot)

# Two-sample t-test comparing mean percentage change between Strength Based and Endurance Based groups
t_test_training <- t.test(percentage ~ TrainingType, data = all_data)
print("Two-Sample t-test comparing percentage change between Training Types:")
print(t_test_training)

# Non-parametric alternative: Wilcoxon rank sum test for the two groups
wilcox_test_training <- wilcox.test(percentage ~ TrainingType, data = all_data)
print("Wilcoxon rank sum test comparing percentage change between Training Types:")
print(wilcox_test_training)
