### Loading in the files we need  
library(lme4)   ## estimated the multilevel model (the random intercept for each of the player pre and post covid data)
library(lmerTest) ## gives the more comprehensive anova type output with the respective p values that indicate significance 
library(tidyverse)
library(readr)

### Accessing the folder and getting all of the DL players csv files 
folder_path <- "C:/Users/yogit/Downloads/DL_players/"
file_list <- list.files(path = folder_path, pattern = "*.csv", full.names = TRUE)
df_list <- lapply(file_list, read_csv)  # Load each CSV into a list
df <- bind_rows(df_list)  # Combine all dataframes into one

### Viewing the structure to make sure that it is correct 
str(df)
head(df)

### Apparently LMM needs the titles to be one word so here we are adding the underscore in 
df <- df %>%
  rename(Season_Group = `Season Group`)
df <- df %>% filter(Season_Group != "Difference") ##the difference row is not needed for LMM 

### Converting all of the  categorical variables to factors
df$Season_Group <- factor(df$Season_Group, levels = c("Group1", "Group2"))  ## Pre vs. Post COVID
df$Player <- factor(df$Player)  ## The player is treated as the random effect 

## Checking again
str(df)
head(df)



#Running the LMM tests for each of the 4 statistics 
lmm_comb <- lmer(Comb ~ Season_Group + (1 | Player), data = df) ## comb is the total #/o combined tackles 
summary(lmm_comb)

lmm_solo <- lmer(Solo ~ Season_Group + (1 | Player), data = df) ## these are the #/o solo tackles 
summary(lmm_solo)

lmm_ast <- lmer(Ast ~ Season_Group + (1 | Player), data = df) ## #/o assisted tackles 
summary(lmm_ast)

lmm_pd <- lmer(PD ~ Season_Group + (1 | Player), data = df) ## #/o pass deflections 
summary(lmm_pd)


### generating a table with the key data from the LMM 
results <- tibble(
  Metric = c("Comb", "Solo", "Ast", "PD"),
  Estimate = c(fixef(lmm_comb)["Season_GroupGroup2"], ## these are the estimated differences before and after covid 
               fixef(lmm_solo)["Season_GroupGroup2"], 
               fixef(lmm_ast)["Season_GroupGroup2"],   
               fixef(lmm_pd)["Season_GroupGroup2"]),
  P_Value = c(summary(lmm_comb)$coefficients[2,4], ## these are the p-values for those estimates 
              summary(lmm_solo)$coefficients[2,4],
              summary(lmm_ast)$coefficients[2,4],
              summary(lmm_pd)$coefficients[2,4])
)

# Print results
print(results)

ggplot(df, aes(x = Season_Group, y = Comb, fill = Season_Group)) +
  geom_boxplot() +
  labs(title = "Comparison of Total Tackles (Comb) Before vs. After COVID",
       x = "Season Group",
       y = "Total Tackles") +
  theme_minimal()

