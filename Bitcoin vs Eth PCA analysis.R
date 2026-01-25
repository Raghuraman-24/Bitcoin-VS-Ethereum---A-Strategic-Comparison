# ============================
#  PACKAGE SETUP
# ============================

# List of required packages for analysis and modeling
packages_needed <-  c( 
  "GGally", "e1071", "pROC", "randomForest", "tidymodels", "car", 
  "themis", "kknn", "rpart", "rpart.plot", "baguette", 
  "ranger", "xgboost", "lightgbm", "bonsai",  "parallel", "future", 
  "readr", "dplyr", "lubridate", "tidyverse", "reshape2", "cluster","corrplot"
)

# Identify packages that are not already installed
packages_to_install <- packages_needed[!packages_needed %in% installed.packages()]

# Install missing packages from CRAN
sapply(packages_to_install, install.packages, dependencies = TRUE, repos = "https://cloud.r-project.org")

# Load all required packages
sapply(packages_needed, require, character.only = TRUE)


# ============================
# DATA LOADING
# ============================

# Set working directory to project folder
setwd("C:/Users/Raghu/OneDrive/Desktop/Uni - Msba/Q3/703/Group Project 703")

# Read Bitcoin-related datasets
# Historical price data from two sources
# Market cap and volume data
# Energy consumption estimates
# Network difficulty values
df_bitcoin_1       <- read_csv("Bitcoin Historical Data.csv")
df_bitcoin_2       <- read_csv("coin_Bitcoin.csv")
df_bit_market_cap  <- read_csv("btc-usd-max.csv")
df_bit_energy      <- read_csv("bitcoin-energy-consumpti.csv")
df_bit_difficulty  <- read_csv("Bitcoin_Difficulty.csv")

# Read Ethereum-related datasets
df_ethereum_1           <- read_csv("Ethereum Historical Data.csv")
df_ethereum_2           <- read_csv("coin_Ethereum.csv")
df_ethereum_market_cap  <- read_csv("eth-usd-max.csv")
df_ethereum_energy      <- read_csv("ethereum-energy-consumpt.csv")
df_ethereum_difficulty  <- read_csv("Ethereum_Difficulty.csv")


# ============================
#  BITCOIN: CLEANING AND STANDARDIZATION
# ============================

# Clean Bitcoin Dataset 2
# Remove unneeded columns, format date, and convert volume to numeric
df_bitcoin_2_clean <- df_bitcoin_2 %>%
  select(-SNo, -Name) %>%  # Drop identifier columns
  mutate(
    Date = ymd_hms(Date),  # Convert string to POSIXct
    Date = as.Date(Date),  # Convert POSIXct to Date
    Volume = gsub(",", "", Volume),  # Remove commas from Volume
    Volume = gsub("[^0-9.]", "", Volume),  # Keep only numeric and dot
    Volume = as.numeric(Volume)  # Convert to numeric
  )

# Clean Bitcoin Dataset 1
# Handle mixed-format dates and convert to Date type
df_bitcoin_1_clean <- df_bitcoin_1 %>%
  mutate(Date = parse_date_time(as.character(Date), orders = c("Y-m-d", "b d, Y", "d-m-Y", "m/d/Y"))) %>%
  mutate(Date = as.Date(Date))

# Clean market cap data: convert timestamp and select necessary fields
df_bit_market_cap_clean <- df_bit_market_cap %>%
  mutate(Date = ymd_hms(snapped_at), Date = as.Date(Date)) %>%  # Standardize date
  select(Date, Marketcap = market_cap, Volume = total_volume)  # Rename columns

# Clean Bitcoin difficulty data
# Convert UNIX ms timestamps to Date, group by Date and average difficulty values
df_bit_difficulty_clean <- df_bit_difficulty %>%
  mutate(
    Date = as_datetime(as.numeric(timestamp) / 1000),  # Convert from ms to POSIXct
    Date = as.Date(Date)  # Keep only the date
  ) %>%
  group_by(Date) %>%
  summarise(Difficulty = mean(difficulty, na.rm = TRUE)) %>%  # Average by day
  ungroup()
df_bit_difficulty_clean$Difficulty <- format(df_bit_difficulty_clean$Difficulty, scientific = FALSE)

# Merge Bitcoin 1 dataset with market cap data
df_bit_combined <- df_bitcoin_1_clean %>%
  left_join(df_bit_market_cap_clean, by = "Date")

# Ensure consistent Date format
df_bit_combined <- df_bit_combined %>%
  mutate(Date = as.Date(Date))

# Combine cleaned Bitcoin 2 and combined Bitcoin 1+marketcap
df_bit_final <- bind_rows(df_bitcoin_2_clean, df_bit_combined) %>%
  mutate(
    Close = ifelse(is.na(Close) & !is.na(Price), Price, Close),  # Fill Close
    Volume = ifelse(is.na(Volume) & !is.na(`Vol.`), `Vol.`, Volume)  # Fill Volume
  ) %>%
  select(-Price, -`Vol.`) %>%  # Drop original Price/Vol
  mutate(
    Symbol = ifelse(is.na(Symbol) | Symbol == "", "BTC", Symbol),
    Date = as.Date(Date)
  ) %>%
  arrange(Date)  # Sort by date

# Join daily average difficulty to the final Bitcoin dataset
df_bit_final <- df_bit_final %>%
  left_join(df_bit_difficulty_clean, by = "Date")

# Clean and merge energy consumption data with Bitcoin data
df_bit_energy <- df_bit_energy %>%
  mutate(DateTime = as.Date(DateTime))  # Convert to Date type

df_bit_final <- df_bit_final %>%
  left_join(df_bit_energy, by = c("Date" = "DateTime"))  # Join on date

# Format numeric columns (disable scientific notation)
df_bit_final <- df_bit_final %>%
  mutate(across(
    .cols = where(is.numeric) & !c("Date", "Symbol", `Change %`),
    .fns = ~ format(.x, scientific = FALSE)
  ))


# ============================
#  ETHEREUM: CLEANING AND STANDARDIZATION
# ============================

# Clean Ethereum Dataset 2: drop unused, parse date, clean volume
df_ethereum_2_clean <- df_ethereum_2 %>%
  select(-SNo, -Name) %>%
  mutate(
    Date = ymd_hms(Date),
    Date = as.Date(Date),
    Volume = gsub(",", "", Volume),
    Volume = gsub("[^0-9.]", "", Volume),
    Volume = as.numeric(Volume)
  )

# Ethereum 1 date parsing
# Handle inconsistent date formats
df_ethereum_1_clean <- df_ethereum_1 %>%
  mutate(Date = parse_date_time(as.character(Date), orders = c("Y-m-d", "b d, Y", "d-m-Y", "m/d/Y"))) %>%
  mutate(Date = as.Date(Date))

# Market cap cleaning for Ethereum
df_ethereum_market_cap_clean <- df_ethereum_market_cap %>%
  mutate(Date = ymd_hms(snapped_at), Date = as.Date(Date)) %>%
  select(Date, Marketcap = market_cap, Volume = total_volume)

# Ethereum difficulty: cleanup and rename
df_ethereum_difficulty_clean <- df_ethereum_difficulty %>%
  select(-UnixTimeStamp) %>%
  rename(Date = `Date(UTC)`, Difficulty = Value) %>%
  mutate(Date = mdy(Date))  # Parse American format

# Merge Ethereum price and market cap
df_ethereum_combined <- df_ethereum_1_clean %>%
  left_join(df_ethereum_market_cap_clean, by = "Date")

# Combine both Ethereum datasets
df_ethereum_final <- bind_rows(df_ethereum_2_clean, df_ethereum_combined) %>%
  mutate(
    Close = ifelse(is.na(Close) & !is.na(Price), Price, Close),
    Volume = ifelse(is.na(Volume) & !is.na(`Vol.`), `Vol.`, Volume)
  ) %>%
  select(-Price, -`Vol.`) %>%
  mutate(
    Symbol = ifelse(is.na(Symbol) | Symbol == "", "ETH", Symbol),
    Date = as.Date(Date)
  ) %>%
  arrange(Date)

# Merge with difficulty data
df_ethereum_final <- df_ethereum_final %>%
  left_join(df_ethereum_difficulty_clean, by = "Date")

# Merge with energy data
df_ethereum_energy <- df_ethereum_energy %>%
  mutate(DateTime = as.Date(DateTime))
df_ethereum_final <- df_ethereum_final %>%
  left_join(df_ethereum_energy, by = c("Date" = "DateTime"))

# Format numeric fields
# Remove scientific notation from all numeric values except Date/Symbol/Change %
df_ethereum_final_formatted <- df_ethereum_final %>%
  mutate(across(
    .cols = where(is.numeric) & !c("Date", "Symbol", `Change %`),
    .fns = ~ format(.x, scientific = FALSE)
  ))




# ============================
#  FILTERING, COMBINATION, PCA + CLUSTERING SECTION
# ============================

# Add volatility metric to both Bitcoin and Ethereum datasets
# Volatility is calculated as the absolute difference between Close and Open prices
df_bit_final <- df_bit_final %>%
  mutate(
    Close = as.numeric(Close),
    Open = as.numeric(Open),
    Volatility = Close - Open
  )

df_ethereum_final_formatted <- df_ethereum_final_formatted %>%
  mutate(
    Close = as.numeric(Close),
    Open = as.numeric(Open),
    Volatility = Close - Open
  )


# Filter Ethereum dataset: keep only complete records from 2020-01-01 to 2023-06-30
# Ensure no missing dates and valid energy/difficulty/price/volume values
df_ethereum_final_cleaned <- df_ethereum_final_formatted %>%
  filter(
                                           # Exclude rows with missing date
Date >= as.Date("2020-01-01") & Date <= as.Date("2023-06-30"),  # Keep data from Jan 2020 to June 2023
!is.na(High),                                            # Ensure high price is available
!is.na(Low),                                             # Ensure low price is available
!is.na(Open),                                            # Ensure opening price is available
!is.na(Close),                                           # Ensure closing price is available
!is.na(Marketcap),                                       # Ensure market cap is not NA
!is.na(Difficulty),                                      # Ensure difficulty is not missing
!(is.na(`Estimated TWh per Year`) & is.na(`Minimum TWh per Year`)),  # At least one energy column must be present
`Estimated TWh per Year` != "NA"                        # Remove rows where energy column has string 'NA'
)

# Filter Bitcoin dataset similarly
# Apply the same completeness filters for comparison with Ethereum
df_bit_final_cleaned <- df_bit_final %>%
  filter(
                                                # Ensure date exists
Date >= as.Date("2020-01-01") & Date <= as.Date("2023-06-30"),  # Date range match
!is.na(High),                                            # High price must be present
!is.na(Low),                                             # Low price must be present
!is.na(Open),                                            # Open price required
!is.na(Close),                                           # Close price required
!is.na(Marketcap),                                       # Market capitalization must exist
!is.na(Difficulty),                                      # Network difficulty is mandatory
!is.na(`Minimum TWh per Year`),                          # Require minimum energy estimate
`Estimated TWh per Year` != "NA"                        # Disallow string 'NA' entries
)


# Convert critical columns to numeric in both datasets
# This step ensures consistent types for analysis and modeling
df_bit_final_cleaned <- df_bit_final_cleaned %>%
  mutate(
    Energy = as.numeric(`Minimum TWh per Year`),
    Close = as.numeric(Close),
    Volume = as.numeric(Volume),
    Difficulty = as.numeric(Difficulty),
    Volatility  = as.numeric(Volatility)
  )

df_ethereum_final_cleaned <- df_ethereum_final_cleaned %>%
  mutate(
    Energy = as.numeric(`Minimum TWh per Year`),
    Close = as.numeric(Close),
    Volume = as.numeric(Volume),
    Difficulty = as.numeric(Difficulty),
    Volatility  = as.numeric(Volatility)
  )

# Combine cleaned Bitcoin and Ethereum datasets into a single dataframe
df_combined_crypto <- bind_rows(df_bit_final_cleaned, df_ethereum_final_cleaned)

# Define variable combinations to explore using PCA and clustering
var_combos <- list(
  #combo1 = c("Energy", "Close", "Volume", "Difficulty", "Volatility"),
  #combo2 = c("Marketcap", "Close", "Energy"),
  #combo3 = c("Energy", "Difficulty", "Close"),
  #combo4 = c("Close", "Marketcap", "Energy"),
  #combo5 = c("Close", "Difficulty", "Marketcap", "Energy"),
  #combo6 = c("Difficulty", "Marketcap", "Energy"),
  #combo7 = c("Energy", "Close", "Marketcap", "Difficulty"),
  combo8 = c("Energy", "Close", "Volume", "Difficulty")
  #combo9 = c("Energy", "Close", "Volatility", "Difficulty", "Marketcap"),
 # combo10 = c("Energy", "Close", "Open", "Volatility", "Difficulty", "Marketcap")
)

# Ready to run PCA and K-means on each combination and dataset in the next section...

# We will:
# - Loop through each variable combination
# - Apply PCA to reduce to 2 principal components
# - Calculate silhouette scores for k = 2 to 6 to determine best cluster count
# - Perform K-means clustering based on best k
# - Visualize and save the clustering output
# - Store results in a structured list for comparison

# The actual analysis begins in the next code section using a dedicated function
# called `run_pca_then_kmeans()` which performs PCA, K-means, and evaluation for each case

# ============================
#  PCA + K-MEANS FUNCTION WITH EXPLANATORY COMMENTS
# ============================

# Ready to run PCA and K-means on each combination and dataset in the next section...

# We will:
# - Loop through each variable combination
# - Apply PCA to reduce to 2 principal components
# - Calculate silhouette scores for k = 2 to 6 to determine best cluster count
# - Perform K-means clustering based on best k
# - Visualize and save the clustering output
# - Store results in a structured list for comparison

# The actual analysis begins in the next code section using a dedicated function
# called `run_pca_then_kmeans()` which performs PCA, K-means, and evaluation for each case

# ============================
# 🔁 PCA + K-MEANS FUNCTION WITH EXPLANATORY COMMENTS
# ============================

# Function to run PCA and K-means clustering
# Arguments:
# - df: dataframe to analyze
# - variables: vector of variable names to use
# - combo_name: name of the variable combination (e.g., combo1)
# - crypto_label: label for the coin (e.g., "Bitcoin", "Ethereum")
run_pca_then_kmeans <- function(df, variables, combo_name, crypto_label) 
  
{
  
  # Step 1: Subset and scale the selected variables
  df_subset <- df %>%
    select(all_of(variables)) %>%                       # Keep only selected columns
    mutate(across(everything(), as.numeric)) %>%       # Ensure all columns are numeric
    na.omit()                                           # Remove any rows with NA values
  
  df_scaled <- scale(df_subset)                         # Standardize variables (mean=0, sd=1)
  
  # Step 2: Run Principal Component Analysis (PCA)
  pca <- prcomp(df_scaled, center = TRUE, scale. = TRUE)  # Perform PCA with centering & scaling
  df_pc <- data.frame(pca$x[, 1:2])                        # Keep only first two principal components
  
  # Step 3: Correlation matrix of input features
  corrplot(cor(df_subset, use = "complete.obs"),          # Correlation plot of selected variables
           type = "lower", method = "ellipse",
           main = paste("Correlation Plot -", crypto_label, combo_name))
  
  # Step 4: PCA biplot for visualizing variable contribution
  biplot(pca, main = paste("PCA Biplot -", crypto_label, combo_name))
  
  # Step 5: Use silhouette method to determine optimal k (number of clusters)
  scores <- numeric()                                     # Initialize score vector
  message(" Silhouette Scores for ", crypto_label, " - ", combo_name)
  for (k in 2:6) {                                        # Try k = 2 to 6
    model <- kmeans(df_pc, centers = k, nstart = 10)     # Run K-means
    sil <- silhouette(model$cluster, dist(df_pc))        # Calculate silhouette
    scores[k] <- mean(sil[, 3])                          # Store average silhouette width
    message("→ k = ", k, " : ", round(scores[k], 4))     # Print score
  }
  best_k_sil <- which.max(scores)                        # Select k with highest silhouette score
  
  # Step 6: Final K-means clustering using optimal k
  set.seed(703)                                          # Set seed for reproducibility
  df_pc$Cluster <- as.factor(kmeans(df_pc, centers = best_k_sil)$cluster)  # Add cluster label
  
  # Step 7: PCA summary statistics
  cat(" PCA Summary for", crypto_label, combo_name, "")
  print(summary(pca))
  
  # Step 8: Plot clusters using ggplot2
  plot_sil <- ggplot(df_pc, aes(x = PC1, y = PC2, color = Cluster)) +
    geom_point(size = 2) +
    labs(
      title = paste("PCA KMeans Clustering -", crypto_label, combo_name),
      x = "PC1", y = "PC2", color = "Cluster"
    ) +
    theme_minimal()
  
  print(plot_sil)                                        # Display plot
  
  # Step 9: Save cluster plot as PNG
  if (!dir.exists("outputs")) dir.create("outputs")     # Create output folder if not exists
  sil_filename <- paste0("outputs/", crypto_label, "_", combo_name, "_silhouette.png")
  ggsave(sil_filename, plot = plot_sil, width = 7, height = 5, dpi = 300)
  message(" Saved silhouette plot to ", sil_filename)
  
  # Step 10: Return results as a list
  return(list(
    combo = combo_name,
    coin = crypto_label,
    silhouette_scores = scores,
    best_k = best_k_sil
  ))
}


# ============================
#  APPLY FUNCTION TO ALL COMBINATIONS
# ============================

# Initialize an empty list to store results for each combination
results_list <- list()

# Loop through each combo and apply the clustering pipeline
# For each combination of variables:
# - Apply to Bitcoin
# - Apply to Ethereum
# - Apply to Combined BTC+ETH dataset
for (combo in names(var_combos)) {
  vars <- var_combos[[combo]]                                 # Extract variable names for the combo
  results_list[[paste0("BTC_", combo)]] <- run_pca_then_kmeans(df_bit_final_cleaned, vars, combo, "Bitcoin")
  results_list[[paste0("ETH_", combo)]] <- run_pca_then_kmeans(df_ethereum_final_cleaned, vars, combo, "Ethereum")
  results_list[[paste0("COMBO_", combo)]] <- run_pca_then_kmeans(df_combined_crypto, vars, combo, "Bitcoin & Ethereum")
}


# ============================
#  PRINT SUMMARY OF SILHOUETTE SCORES
# ============================

# Iterate through the results and print silhouette scores for each configuration


for (name in names(results_list)) {
  cat("\n", name, "\n")   # Print combo name
  print(round(results_list[[name]]$silhouette_scores, 4)) # Print rounded silhouette values
}




# ============================
#  SAVE PCA OUTPUTS TO CSV
# ============================

# Define datasets for PCA export
pca_datasets <- list(
  Bitcoin = df_bit_final_cleaned,
  Ethereum = df_ethereum_final_cleaned
)

# Loop through each dataset and variable combination to save PCA coordinates
for (coin_name in names(pca_datasets)) {
  df <- pca_datasets[[coin_name]]
  
  for (combo_name in names(var_combos)) {
    vars <- var_combos[[combo_name]]
    
    # Prepare and filter the relevant columns
    df_subset <- df %>%
      select(Date, Symbol, all_of(vars)) %>%                     # Keep metadata and selected variables
      mutate(across(all_of(vars), as.numeric)) %>%               # Ensure all selected variables are numeric
      na.omit()                                                  # Drop rows with missing values
    
    if (nrow(df_subset) == 0) next  # Skip empty datasets after filtering
    
    meta_data <- df_subset %>% select(Date, Coin = Symbol)       # Retain date and coin symbol separately
    
    # Standardize the data and apply PCA
    df_scaled <- scale(df_subset %>% select(-Date, -Symbol))     # Scale numeric features only
    pca <- prcomp(df_scaled, center = TRUE, scale. = TRUE)       # Run PCA
    
    # Create dataframe for first 2 principal components + metadata
    pca_output <- data.frame(
      PC1 = pca$x[, 1],
      PC2 = pca$x[, 2],
      Date = meta_data$Date,
      Coin = meta_data$Coin
    )
    
    # Uncomment the code below to write the file into the system to Do Bi plot 
    # in power bi 
    
    # Create filename and save the result as CSV
    #filename <- paste0("pca_output_", coin_name, "_", combo_name, ".csv")
    #write.csv(pca_output, file = filename, row.names = FALSE)
   # cat("Saved:", filename, "")
  }
}

