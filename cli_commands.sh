conda install pip
conda create -n *insert desired environment name* 
pip install dbt-databricks # enables dbt to work with databricks
pip install databricks-cli # installs Databricks CLI
databricks configure --token # sets up authentication to use Databricks CLI using a token generated in Databricks
databricks secrets list-scopes # lists all existing Databricks-backed secret scopes
databricks fs ls # lists all directories that exist in databricks file system
dbt init # initialises dbt project
dbt debug # tests database connection
dbt snapshot # creates snapshots
dbt test # runs tests
dbt run # runs models
dbt docs generate # creates dbt documentation
dbt docs serve # opens documentation site in local browser