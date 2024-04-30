Campaign Performance Analysis

--Overview

This project involves analyzing marketing campaign data using Python and BigQuery to determine the effectiveness of different campaign versions. The script performs data fetching, cleaning, manipulation, and visual visualization, along with statistical A/B testing to compare the click-through rates (CTR) across different campaign versions.

--Features

Data Fetching: The script pulls data from BigQuery tables: raw_events for user interactions and adsense_monthly for campaign impressions. Data Processing: Includes aggregating data to calculate the estimated clicks based on unique user interactions. Data Visualization: Uses Matplotlib and Seaborn for visual representation of data including bar plots and scatter plots. Statistical Analysis: Implements A/B testing using the chi-squared test to evaluate the statistical significance of differences in CTR between campaign versions.

--Requirements

To run this script, you will need:

-Python 3.x -Google Cloud account with access to BigQuery -Necessary Python libraries: google-cloud-bigquery, pandas, matplotlib, seaborn, scipy, numpy

--Usage

Authentication: Ensure that your Google Cloud credentials are set up correctly for BigQuery access. -Execution: Run the script in a Python environment, such as Jupyter Notebook, Google Colab, or directly in your terminal (if configured to connect to BigQuery).

--Data Structure

raw_events: Contains user interaction data with various campaigns. -adsense_monthly: Contains monthly aggregated data about impressions per campaign.

--Visualizations

Estimated Clicks by Campaign and Month: Bar plot showing the number of clicks per campaign version. -Click-Through Rate by Campaign Version: Bar plot detailing the CTR for each campaign. -Impressions vs. Estimated Clicks: Scatter plot illustrating the relationship between impressions and clicks.

--Statistical Analysis Results

Displays the chi-squared statistic and p-value for each campaign's A/B testing results, helping to identify statistically significant differences between campaign versions.
