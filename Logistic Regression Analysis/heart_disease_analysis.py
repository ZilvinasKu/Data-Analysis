# Import necessary libraries
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, confusion_matrix, precision_score, recall_score, f1_score
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import make_pipeline


# Function to print evaluation metrics
def print_evaluation_metrics(y_true, y_pred, title):
    accuracy = accuracy_score(y_true, y_pred)
    conf_matrix = confusion_matrix(y_true, y_pred)
    precision = precision_score(y_true, y_pred)
    recall = recall_score(y_true, y_pred)
    f1 = f1_score(y_true, y_pred)

    print(f"{title} - Accuracy: {accuracy:.4f}, Precision: {precision:.4f}, Recall: {recall:.4f}, F1 Score: {f1:.4f}")
    print(f"Confusion Matrix:\n{conf_matrix}\n")


# Function to interpret model coefficients and odds ratios
def print_model_coefficients(features, model):
    coefficients = model.named_steps['logisticregression'].coef_[0]
    odds_ratios = np.exp(coefficients)
    coef_df = pd.DataFrame({'Feature': features, 'Coefficient': coefficients, 'Odds Ratio': odds_ratios})
    coef_df = coef_df.sort_values(by='Odds Ratio', ascending=False)
    print(coef_df)


# Load the dataset
df = pd.read_csv('Heart_disease_data.csv')

# Data preprocessing
df['education'] = df['education'].fillna(df['education'].mode()[0])
df['cigsPerDay'] = df.apply(lambda x: 0 if pd.isnull(x['cigsPerDay']) and x['currentSmoker'] == 0 else x['cigsPerDay'],
                            axis=1)
df['cigsPerDay'] = df['cigsPerDay'].fillna(df['cigsPerDay'].median())
columns_to_fill = ['BPMeds', 'totChol', 'BMI', 'heartRate', 'glucose']
df[columns_to_fill] = df[columns_to_fill].apply(lambda x: x.fillna(x.median()))

# Saving the cleaned dataset
df.to_csv('Heart_disease_data_cleaned.csv', index=False)

# Prepare data for modeling
X = df.drop('TenYearCHD', axis=1)
y = df['TenYearCHD']
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Create and train the logistic regression model
logreg = make_pipeline(StandardScaler(), LogisticRegression(max_iter=2000))
logreg.fit(X_train, y_train)

# Model evaluation
y_pred = logreg.predict(X_test)
print_evaluation_metrics(y_test, y_pred, "Default Threshold")

# Adjusting threshold for predictions
y_proba = logreg.predict_proba(X_test)[:, 1]
threshold = 0.4  # Adjust as needed
y_pred_adjusted = np.where(y_proba > threshold, 1, 0)
print_evaluation_metrics(y_test, y_pred_adjusted, "Adjusted Threshold")

# Interpret model coefficients and odds ratios
print_model_coefficients(X_train.columns, logreg)

# Added a line to calcluate the intercept
intercept = logreg.named_steps['logisticregression'].intercept_[0]
print("Model intercept:", intercept)
