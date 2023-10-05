## README
### Analysis of User Behaviors on an E-Commerce Website

This project aims to analyze user behaviors occurring on an e-commerce website using BigQuery, focusing on identifying distinct user behaviors leading to a purchase. The analyses are performed on the `ga4_obfuscated_sample_ecommerce` dataset available in BigQuery.

### Dataset

The dataset includes default events and e-commerce specific events transferred by GA4 to BigQuery. For detailed information about the dataset and events, please refer to the following links:

- [Detailed Information about Dataset and Events](https://support.google.com/analytics/answer/7586738?hl=en#zippy=%2Cin-this-article)
- [Default Events](https://support.google.com/analytics/answer/9234069?hl=en)

### Project Stages

#### 1. Data Preparation

- **Target Assignment:**
  - Users who perform a specific sequence of actions leading to a purchase are classified into the positive class; otherwise, they are classified into the negative class.
  - The accompanying SQL query supports this classification.

- **Feature Assignment:**
  - Assignment of various features including average session duration, number of distinct days of entry, and others.

#### 2. Exploratory Data Analysis

- Visualization of the weekly variation of the target variable.
- Examination of correlations between variables and their changes over time.
- Drawing scatter plots of lowly correlated variables with the churn rate variation indicated by color coding.
- Analysis and interpretation of variable distributions.

#### 3. Modeling

- Feature selection and engineering stages.
- Processes of model validation and selection.

#### 4. Analysis of Model Variables’ Importance

- Analysis of the importance of model variables and explanations of why they are deemed significant.

#### 5. Analysis Presentation

- Compilation of the aforementioned stages and preparation of the analysis presentation.

### Getting Started

After cloning or downloading the project, you can review the analyses and results, and perform similar analyses with your own data and scenarios.
