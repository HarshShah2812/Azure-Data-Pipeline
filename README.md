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

`spark.sql(f'CREATE DATABASE IF NOT EXISTS {tableSchema}')`

`spark.sql("""CREATE TABLE IF NOT EXISTS """+tableSchema+"""."""+tableName+"""
            USING PARQUET 
            LOCATION '/mnt/bronze/"""+fileName+"""/"""+tableSchema+"""."""+tableName+""".parquet'
            """)`

I then tried running the job in Data Factory, and an example of the results within Databricks can be seen below:

<img width="1266" alt="Screenshot 2024-05-05 at 11 32 19" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/36705f58-770b-464f-9707-4f3a18cf4d02">

<img width="1266" alt="Screenshot 2024-05-05 at 11 37 59" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/5e4a8e9d-d6ae-4dcc-a06e-42e279b6dcde">

## DBT setup and configuration with Databricks

In the terminal on VS code, I installed dbt-databricks using the pip installer, which allowed me to integrate dbt with Databricks. I then installed databricks-cli in order to access Databricks from the terminal.

The next thing to do was configure dbt with Databricks. I firstly used a token generated in Databricks to connect to it from the terminal. If you then use the command `secrets list-scopes`, you will be able to see all the secrets created. When using the `databricks fs ls` command, the terminal returned all the files in the Databricks File System. I then initialised the dbt project by naming it and selecting the database I'd like to use (Databricks as opposed to Spark), as well as inputting the host, which follows this structure `https://adb-<workspace-id>.<random-number>.azuredatabricks.net`, and the HTTP path, which can be retrieved from the Advanced Configuration settings of the Cluster you've created, which is accessed in the Compute section of Databricks. The default schema that I chose for dbt to run the projects in was saleslt, as can be seen within the hive_metastore in the image above. When running `dbt debug`, it initially returned an error, which led me to modify the profiles.yml file within the .dbt directory and change the directory I was running the command in, after which the `dbt debug` command returned successfully.

## DBT snapshots with Databricks and ADLS Gen2

I now had to create snapshots for each of the tables in the saleslt database, creating the SQL scripts for each of them. If we take the example of the 'address' snapshot below:

<img width="445" alt="Screenshot 2024-05-06 at 17 44 34" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/d405294d-cf88-4c8b-9d84-9d1a0048a1b7">

The configuration involves defining the format of the file, which in this case, is Delta; the mounting point i.e. where the data will be stored, is in the Silver layer; the target schema i.e. the default schema that dbt will built objects into; hard deletes will be invalidated, so that dbt can track the records in the source table that have been deleted, creating a row in the snapshot for each deleted record; the unique key will be the AddressID column i.e. dbt will use this column to match records between a result set and the existing snapshot; the strategy used will be check as opposed to timestamp, which will result in changes being tracked based on the values of specific columns, and all the columns will be checked, therefore dbt will create a new snapshot whenever any column changes for a user.
Using a Common Table Expression (CTE), I then selected the columns that I wanted to appear in the snapshot.

I then ran the `dbt snapshot` command in the terminal, however this initially returned an error due to the customer snapshot depending on the customer table within the saleslt schema, which couldn't be found.

This led me to fix the models by creating a YML file inside a 'staging' sub-folder within the 'models' folder, that will recognise all the tables and the schema as a whole, which I called bronze.yml. The contents of the file can be seen below:

<img width="569" alt="Screenshot 2024-05-08 at 18 48 17" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/a325710a-ce2e-4f87-bbe9-f61dcfd0fdbe">

After succesfully running `dbt debug` again, I ran the `dbt snapshot` command once again, which was successful this time. The result in Databricks can be seen below:

<img width="1275" alt="Screenshot 2024-05-07 at 21 57 40" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/89c27645-0f39-4f08-93b5-b7f446dd515c">

<img width="1275" alt="Screenshot 2024-05-07 at 22 00 40" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/743d0e66-c646-4c2c-9bfe-5bb7342bb7cc">

The snapshots could also be seen within the Silver container in Azure.

## DBT Data Marts with Databricks and ADLS Gen2

Using the snapshots, I could now build the Data Marts i.e. the final tables. I created another sub-folder inside the models folder, calling it marts, and created 3 more sub-folders within the folder for the customer, product, and sales data. I then created sql and yml files within each of these folders. The sql file contains the necessary transformations, while the yml defines the structure of the data. Below are screeshots of the dim_product.sql and dim_product.yml files:

<img width="569" alt="Screenshot 2024-05-08 at 22 34 16" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/816c1611-45fd-4cb1-b0ed-80249de8c1bf">

<img width="656" alt="Screenshot 2024-05-08 at 22 35 02" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/00c8abb0-fc92-4ba8-bc06-7e8705079afc">

<img width="656" alt="Screenshot 2024-05-08 at 22 36 16" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/b3b83b08-2800-4c8b-91ce-5e6855aa1eaf">

<img width="656" alt="Screenshot 2024-05-08 at 22 36 30" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/db333dbc-cff2-4da2-b293-9397070be963">

I then tried to run the `dbt test` command, however it returned a error about configuration paths existing in the dbt_project.yml that didn't apply to any resources. This led me to modify the dbt_project.yml file by commenting out the medallion_dbt_spark config. When I then ran the `dbt run` and `dbt test` commands, I achieved the desired results. A screenshot of the dim_customer table can be seen below:

<img width="1071" alt="Screenshot 2024-05-09 at 00 00 31" src="https://github.com/HarshShah2812/de-pipeline-dbt-databricks-azure/assets/67421468/9f70acf7-9c68-42d0-9039-4676cf0d1746">




