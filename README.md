# Olist E-Commerce SQL Analytics

An end to end SQL analysis of a Brazilian e-commerce marketplace, covering order growth, revenue concentration, high value customers, and customer retention. Built to answer real marketing questions using a relational database of nearly 100,000 orders.

## Business Context

Olist operates an online marketplace connecting small sellers to shoppers across Brazil. The marketing team needed answers to four specific questions in order to prioritize spend and identify growth opportunities.

## Key Finding

97 percent of customers (90,557 of 93,357) made only a single purchase and never returned. Retention drops below 1 percent by the second month across nearly every customer cohort. Applying a conservative 5 percent win back rate to this group represents an estimated $693,000 in recoverable revenue at current average order value.

This finding reframes the core business problem. The company does not have an acquisition problem, it has a retention problem.

## What This Project Covers

* Month over month order growth, using window functions to measure acceleration and identify seasonal spikes
* Revenue concentration by product category, isolating the top five categories driving total revenue
* Customer value ranking, identifying the ten highest spending customers and testing whether high spend correlates with loyalty
* Cohort retention analysis, tracking what percentage of each monthly customer cohort returns to purchase again in subsequent months

## Tools and Techniques

## Full Write Up

The complete analysis, including methodology notes, result screenshots, and the business case behind the recommendation, is available here:

[Full project write up on Notion](https://app.notion.com/p/oluwapelumi-sql-analytics/Project-2-SQL-Analytics-Olist-E-Commerce-39c5420aae2d80919f6adfd896ec7899)

## Dataset

[Brazilian E-Commerce Public Dataset by Olist, via Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

MySQL 8.0, common table expressions, window functions including LAG, RANK, and DENSE_RANK, and cohort based retention modeling.

## Repository Structure
