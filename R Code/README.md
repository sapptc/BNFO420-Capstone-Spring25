# NFL Performance Analysis R Scripts
## Overview

This collection of R scripts supports the end-to-end workflow for analyzing NFL player performance differences pre- vs. post-COVID. The pipeline covers:

   - Data aggregation & preprocessing (Python → CSV/Excel)

   - Statistical testing (R)

   - Visualization of percentage changes (R)

   - Linear mixed-effects modeling (R)

   - PCA & clustering (R)

   - Z-score standardization (R)

Each script is organized by analytic step and grouped into the following categories:

   - Statistical tests

   - Mixed-effects modeling

   - Percentage-difference plots

   - PCA clustering

   - Data standardization

**Prerequisites**

    R (≥ 4.0.0)

    R packages

    install.packages(c(
      "lme4", "lmerTest",            # LMM
      "tidyverse", "readr",          # Data wrangling
      "readxl", "writexl",           # Excel I/O
      "FactoMineR", "factoextra",    # PCA & clustering
      "ggrepel", "ggplot2",          # Plots
      "purrr", "dplyr", "tidyr"      # Functional programming & tidy data
    ))

**File Summary**
1. TestingLMM.R

Purpose: Fit linear mixed-effects models on combined-tackle (Comb), solo-tackle (Solo), assist-tackle (Ast), and pass-deflection (PD) counts, comparing pre- vs. post-COVID within each player as a random intercept.

Key steps:

    Load all per–defensive-lineman CSVs from a directory

    Bind into a single data frame, rename Season Group, drop “Difference” rows

    Convert Player and Season_Group to factors

    Fit lmer(metric ~ Season_Group + (1 | Player)) for each metric

    Extract fixed-effect estimates and p-values into a summary tibble

    Produce a boxplot of Comb by Season_Group

2. statistical_tests.r

Purpose: Ingest all individual player CSVs across positions, tag each record with its Position (derived from the parent directory), and assign a high-level Position_Category (“Power” vs. “Endurance”).

Key steps:

    Recursively list .csv files under NON-COVID Player Stats

    Read each file, extract Position from the file path

    Combine into one data frame

    Create Position_Category based on predefined position lists

3. Percentage Differences w graphs.R

Purpose: Read per-position aggregate Excel workbooks (percentage-change matrices), reshape to long format, perform omnibus and per-position tests, and produce three core plots (boxplot, median bar chart, mean bar chart), plus training-type comparisons.

Key steps:

    Read each *_aggregate.xlsx into a long data frame

    Run one-way ANOVA, Kruskal-Wallis, and one-sample t-tests (μ = 0) by Position

    Plot:

        Enhanced boxplot with zero line and median points

        Median percentage change bar chart

        Mean percentage change bar chart

    Categorize roles into “Strength Based” vs. “Endurance Based” and test/plot group differences

4. zscorestandarization.R

Purpose: Standardize raw aggregate metrics via Z-score transformation.

Key steps:

    Read a single aggregate Excel file (e.g. FB_aggregate.xlsx)

    Identify numeric columns, apply scale()

    Recombine with non-numeric identifiers (Player, etc.)

    Write out a standardized Excel file

5. PCAClustering_Raw.R

Purpose: Perform PCA on raw (non-percentage) player metrics for clustering by “Power” vs. “Endurance.”

Key steps:

    Set working directory to folder of *standardized_output_noncovid.xlsx files

    Read and combine all sheets, filter out “Difference” rows

    Select numeric columns, impute missing values by column mean

    Run PCA() (FactoMineR)

    Generate:

        PCA scatterplot colored by Category

        Scree plot of eigenvalues

        Biplot of variables & individuals

        Contribution plots for top variables

6. PCAClustering_PercentageStats.R

Purpose: Perform PCA on percentage-change spreadsheets for non-COVID aggregate stats.

Key steps:

    Read all sheets from a single workbook (e.g. All Data - Non COVID.xlsx), tag with sheet name

    Filter out “Difference” rows, identify ID vs. numeric columns

    Convert remaining to numeric, impute NAs

    Run PCA(), then plot:

        Individuals scatter (colored by Category)

        Scree plot

        Biplot

        Top contributing variables

        Dim 1 vs 3 biplot

        Variable correlation map

7. PCAClustering_CombinedPercentageStats.R

Purpose: Extend PCA comparison across COVID and non-COVID cohorts and save annotated plots.

Key steps:

    Read two aggregate workbooks (All Data – COVID.xlsx, All Data – Non COVID.xlsx), tag with Infection_Status

    Filter out “Difference” rows, convert to numeric and impute

    Run PCA() on combined data

    Generate & save seven plots:

        PCA individuals by COVID status & category

        Scree plot

        PCA biplot

        Contribution to PC1 & PC2

        Dim 1 vs 3 biplot

        Variable correlation map

        Faceted PCA plot (offense/defense/special teams)

### Usage

    Configure paths at the top of each script (e.g. folder_path, file_path, output_folder).

    Install required R packages (see Prerequisites).

    Run scripts in order, from data ingestion → statistical tests → visualization → PCA clustering.

Rscript TestingLMM.R  
Rscript statistical_tests.r  
Rscript "Percentage Differences w graphs.R"  
Rscript zscorestandarization.R  
Rscript PCAClustering_Raw.R  
Rscript PCAClustering_PercentageStats.R  
Rscript PCAClustering_CombinedPercentageStats.R  

### Output

    CSV / Excel: per-player percentage-change rows; position-level aggregates

    Console: LMM summaries, ANOVA/Kruskal-Wallis/t-test results, training-type summaries

    Plots:

        Boxplots, bar charts (median/mean)

        PCA scatterplots, biplots, scree plots, contribution maps

        Saved PNGs for combined COVID vs. non-COVID analyses

