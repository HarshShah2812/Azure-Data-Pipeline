# Azure Data Pipeline

> This project is about setting up an end-to-end data pipeline using Azure (Data Lake Gen2, Data Factory, Databricks), Apache Spark, and dbt (Data Build Tool)

## Overview
The aim of the project is to illustrate the process of data ingestion into a data lake, followed by data integration using Azure Data Factory, and then data transformation using Databricks and dbt. The project was completed with the help of the following tutorial: https://www.youtube.com/watch?v=divjURi-low&t=4866s

## Project Architecture

![architecture](https://github.com/airscholar/modern-data-eng-dbt-databricks-azure/blob/main/System%20Architecture.jpeg)

## Setting up the base Azure Infrastructure
After creating an Azure account, I firstly created the resource group, within which we will be able to manage all the resources needed for the project. Then, I created a storage account using the Data Lake Gen2 service, within which I set up the Medallion architecture, by creating separate containers for the Bronze, Silver, and Gold layers. Next, I set up Azure Data Factory, within which I would be building the data pipeline. I then created a Key Vault for managing secrets, which will be necessary when integrating Azure Databricks, as it will allow Databricks to retrieve secrets securely at runtime, which will ensure that sensitive information is never exposed in plaintext within Databricks notebooks, jobs, or configurations. Lastly, I created a SQL database, using the sample AdventureWorks database as the source.

If done successfuly, you will get the following example output within the Query Editor:

<img width="1432" alt="Screenshot 2024-03-31 at 19 05 08" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/91166a09-66b3-4281-af11-c50474c55dcc">

You can also run the following query to see all the tables available within the SalesLT schema:

<img width="1432" alt="Screenshot 2024-03-31 at 19 07 44" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/5b70a533-e1c9-45ab-b1f6-9f53a4ed0a59">
