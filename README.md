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

## Orchestrating the pipeline
Firstly, I linked Data Factory with the database and the storage account. I then created a new pipeline, deploying the database as the dataset. Within the pipeline, I firstly added a Lookup function, which would retrieve all the tables from the database using the query shown in the last screenshot above. I then added a ForEach function which is linked to the Lookup function, in order to iterate through each table and store the data in the Bronze container. Within the ForEach function, I added a Copy Data function, which uses a newly created dataset based on the original dataset as the source, as well as having parameters called SchemaName and TableName; the function was also configured to send each of the tables, once copied, as parquet files to the Bronze container, naming them based on the parameters, while storing them within a folder inside the container that was named using the yearmonthdate format.

The contents within the Bronze container should look as such:

<img width="1432" alt="Screenshot 2024-03-31 at 20 16 30" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/25b3fe48-403b-469e-bafe-cc9d6b649a99">

## Setting up Databricks
After initially creating a Databricks workspace, I created the secret initially in the Azure Key Vault. To then get this information across to, I copied the Vault URI and Resource ID, pasting them onto the Create Secret Scope page, which is accessed using the following URL:

`https://<databricks-instance>#secrets/createScope`

Replace <databricks-instance> with the workspace URL of your Azure Databricks deployment. 

In a new workbook, I verified the Databricks - Key Vault - Secret Scope integration by mounting the bronze layer, using the following code:

`dbutils.fs.mount(
    source = 'wasbs://bronze@medallionstoreacc.blob.core.windows.net',
    mount_point = '/mnt/bronze',
    extra_configs = {'fs.azure.account.key.medallionstoreacc.blob.core.windows.net': dbutils.secrets.get('databricksScope', 'storageAccountKey')}
)`

I did the same for the silver and gold layers, replacing 'bronze' with them in the code. I then used the following code to check the contents of the bronze layer:

`dbutils.fs.ls('/mnt/bronze')`

## Data Factory - Databricks Integration

In Data Factory, I modified the ForEach function by connecting the Databricks workbook in such a way that the Parquet files in the Bronze Layer would be used to create tables in Databricks. This involved creating an Access Token to connect Data Factory with Databricks, which I did within the Developer section of the User settings in Databricks. I also added the notebook path that will be triggered everytime a job is sent to the Databricks notebook cluster, as well as the base parameters that we want to be accessed by the notebook, specifically the table_scheme, table_name, and FileName. Here is a screenshot:

<img width="1387" alt="Screenshot 2024-05-02 at 19 09 54" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/08d119e4-75ac-4070-91b8-84010e8dc564">

Next, within the notebook, I wrote the following piece of code, which creates a new database if one doesn't exist, as well as a new table if one doesn't already exist:

`spark.sql(f'CREATE DATABASE IF NOT EXISTS {tableSchema}')

spark.sql("""CREATE TABLE IF NOT EXISTS """+tableSchema+"""."""+tableName+"""
            USING PARQUET 
            LOCATION '/mnt/bronze/"""+fileName+"""/"""+tableSchema+"""."""+tableName+""".parquet'
          """)`

I then tried running the job in Data Factory, and an example of the results within Databricks can be seen below:

<img width="1266" alt="Screenshot 2024-05-05 at 11 32 19" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/81aea258-b5b3-4968-bf78-10e39a09596e">

<img width="1266" alt="Screenshot 2024-05-05 at 11 37 59" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/ae017283-7b7f-4629-997e-d0b3d751146c">