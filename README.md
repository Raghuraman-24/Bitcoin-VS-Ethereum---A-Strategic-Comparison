# BTC vs ETH: Battle of the Blockchains  
**Volatility, Liquidity, Network Difficulty & Sustainability (2020–2023)**

## Overview
This project presents a data-driven comparison of Bitcoin (BTC) and Ethereum (ETH) from 2020 to 2025, examining how market volatility, liquidity, mining difficulty, and energy consumption evolve under different blockchain designs.  
Using Python for data engineering, Power BI for interactive analytics, and R for unsupervised machine learning (PCA), the project evaluates the market and sustainability implications of Proof of Work versus Proof of Stake.

---

## Problem Statement
Cryptocurrency analysis often focuses on price movements while ignoring structural drivers such as mining difficulty, energy usage, and protocol design changes.

This project addresses:
- How BTC and ETH differ in volatility and liquidity over time
- The impact of major crypto events (LUNA crash, FTX collapse, BTC halving)
- The relationship between mining difficulty and energy consumption
- Whether Ethereum’s transition to Proof of Stake materially improved efficiency and sustainability

**Constraints & Assumptions**
- Publicly available historical data
- Daily-granularity time series
- Energy consumption based on Digiconomist estimates
- Exploratory and explanatory analysis (no price prediction)

---

## Design and Architecture

### High-Level Architecture
Raw Data Sources
↓
Python (Web Scraping & Data Wrangling)
↓
Unified Analytical Dataset
↓
Power BI (Modeling, DAX, Dashboards)
↓
R (PCA & Clustering)
↓
Insights & ESG-Oriented Recommendations


### Key Components
- **Python**: Data ingestion, cleaning, feature engineering
- **Power BI**: Interactive dashboards and business-facing analytics
- **R**: Unsupervised learning using PCA and K-Means clustering
- **Shared Date Dimension**: Ensures consistent time-series alignment

---

## Datasets and Metadata

### Bitcoin
| Dataset | Source | Size | Notes |
|------|------|------|------|
| Historical Prices (2021–2025) | [Investing.com](https://www.investing.com/crypto/bitcoin/historical-data) | 1,416 × 7 | Clean daily OHLC & volume |
| Historical Prices (2013–2021) | [Kaggle – Rajkumar](https://www.kaggle.com/datasets/sudalairajkumar/cryptocurrencypricehistory) | 2,991 × 10 | Timestamp normalized |
| Market Capitalization | [CoinGecko](https://www.coingecko.com/en/coins/bitcoin) | 4,405 × 4 | One missing value handled |
| Difficulty Index | [Gigasheet – Blockchain Data](https://gigasheet.com/sample-data/bitcoin-blockchain-historical-data) | 800k+ × 13 | Aggregated to daily |
| Energy Consumption | [Digiconomist](https://digiconomist.net/bitcoin-energy-consumption) | 3,021 × 3 | Minimum TWh/year used |

### Ethereum
| Dataset | Source | Size | Notes |
|------|------|------|------|
| Historical Prices (2021–2025) | [Investing.com](https://www.investing.com/crypto/ethereum/historical-data) | 1,416 × 7 | Clean daily OHLC & volume |
| Historical Prices (2013–2021) | [Kaggle – Rajkumar](https://www.kaggle.com/datasets/sudalairajkumar/cryptocurrencypricehistory) | 2,160 × 10 | Timestamp normalized |
| Market Capitalization | [CoinGecko](https://www.coingecko.com/en/coins/ethereum) | 3,575 × 4 | One missing value handled |
| Difficulty Index | [Etherscan](https://etherscan.io/chart/difficulty) | 3,589 × 3 | Daily difficulty values |
| Energy Consumption | [Digiconomist](https://digiconomist.net/ethereum-energy-consumption) | 2,918 × 3 | Post-Merge energy drop visible |



---

## Key Technical Decisions
- **Python for data engineering** to handle heterogeneous, multi-source crypto data
- **Power BI** for stakeholder-friendly interactive storytelling
- **R for PCA** due to strong statistical tooling and explainability
- **PCA over correlation analysis** to reveal latent structure between energy, difficulty, and price
- **Event-based framing** to contextualize market shocks

---

## Implementation Details

### Python (Data Engineering)
- Web scraping and ingestion from multiple sources
- Volume normalization and numeric conversion
- Daily aggregation of blockchain difficulty
- Feature engineering for volatility and liquidity
- Export of ML-ready datasets

### Power BI
- Star-schema inspired model with shared date dimension
- DAX measures for:
  - Growth rate
  - Volatility
  - Liquidity compression
  - Energy growth factors
- Interactive event filters (LUNA, FTX, Halving)

### Unsupervised Learning (R)
- PCA on standardized variables:
  - Price, Volume, Difficulty, Energy
- Silhouette analysis for optimal clustering
- Separate PCA pipelines for BTC and ETH
- PCA outputs integrated into Power BI visuals

---

## Output and Key Insights

### Market & Liquidity
- BTC maintains higher liquidity but shows sustained energy growth (2.43× from 2020–2022)
- ETH exhibits higher growth and volatility but improved efficiency post-Merge

### Event Impact
- **LUNA Crash (2022):** Market-wide liquidity shock
- **FTX Collapse (2022):** Severe volume contraction, ETH more affected
- **BTC Halving:** Long-term price support via supply reduction

### PCA Findings
- Bitcoin shows strong coupling between difficulty and energy consumption
- Ethereum exhibits a clear structural break post-2022
- Post-Merge ETH achieves similar price behavior with dramatically lower energy use
- PCA confirms Proof of Stake as a more sustainable design

---

## Reproducibility & Environment
- **Python**: pandas, numpy, requests
- **R**: tidyverse, cluster, corrplot
- **Power BI Desktop**: Data modeling & DAX
- All transformations scripted and reproducible
- Fixed random seed for clustering stability

---

## Project Files
| File | Description |
|-----|------------|
| `Bitcoin vs ETH - Python.ipynb` | Data wrangling and Web Scrapping |
| `Bitcoin vs Eth PCA analysis.R` | PCA and clustering analysis |
| `Power BI Dashboard (.pbix)` | Interactive analytics |
| `Dataset/` | Cleaned source datasets |
| `Visuals/` | Dashboard screenshots |

---

## Limitations and Future Work
- Energy estimates are approximations
- No causal inference or forecasting
- Future enhancements:
  - Time-series clustering
  - Carbon intensity by geography
  - On-chain transaction metrics

---

## Lessons Learned
- Market events reshape structure, not just trends
- PCA enables explainable insights into complex systems
- ESG framing strengthens technical crypto analysis
- Combining BI and ML improves stakeholder impact


