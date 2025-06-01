# Clickstream Demo on AWS
This project is a **demo clickstream pipeline** built on AWS using infrastructure-as-code (Terraform), and includes real-time data ingestion, S3-based data lake, Glue schema cataloging, and querying in Athena.
It simulates click events and streams them to AWS Firehose, which then stores the data in S3. The data is cataloged using AWS Glue and can be queried using Athena. I have used hive style partitioning and Apache Parquet format for efficient storage and querying.

## Project Structure
<pre><code class="lang-txt">
├── LICENSE
├── README.md
├── data_producer
│   ├── click_events.csv
│   ├── data_producer.py
│   └── requirements.txt
└── terraform
    ├── environments
    │   └── dev.tfvars
    ├── main.tf
    ├── modules
    │   ├── aws_iam_role
    │   │   └── main.tf
    │   ├── firehose
    │   │   └── main.tf
    │   ├── glue
    │   │   └── main.tf
    │   └── s3_bucket
    │       └── main.tf
    ├── terraform.tfstate
    ├── terraform.tfstate.backup
    └── variables.tf
</code></pre>

## Getting Started
### Prerequisites
- **AWS Account**: You need an AWS account to deploy the infrastructure.
- **Terraform**: Install Terraform on your local machine.
- **Python**: Ensure Python is installed for the data producer script.

### Running the Terraform Infrastructure
- In the `environments` directory, create a `dev.tfvars` file with your AWS credentials and region:
```hcl
aws_region = "example-region"
env = "example-env"
```
- Navigate to the `terraform` directory and run the following commands:
```bash
terraform init
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars
```
### Running the Data Producer
- Navigate to the `data_producer` directory.
- Install the required Python packages:
```bash
pip install -r requirements.txt
```
- Run the data producer script to simulate click events:
```bash
python data_producer.py --path click_events.csv --chunksize 100 --stream_name firehose-stream-name --aws_region example-region
```
For this demo, I used 60 seconds delay between each chunk of 100 events. You can adjust the parameters as needed inside `data_producer.py`.
Make sure to replace buffering_interval and buffering_size in the Firehose configuration to match your data producer settings.

### Querying the Data
- After the data is ingested, you can query it using AWS Athena.
- The data in S3 partitioned by `year`, `month`, and `day` which looks like this:
```
s3://your-bucket-name/clickstream/year=2023/month=10/day=01/
```
- You can use the following SQL query to retrieve the data:
```sql
SELECT * FROM "your_database_name"."your_table_name"
WHERE year = '2023' AND month = '10' AND day = '01';
```
### Cleaning Up
- To clean up the resources created by Terraform, run:
```bash
terraform destroy -var-file=environments/dev.tfvars
```
## Data Source
<!-- https://www.kaggle.com/datasets/mkechinov/ecommerce-events-history-in-electronics-store -->
The click events data is sourced from a Kaggle dataset (link: [Ecommerce Events History in Electronics Store](https://www.kaggle.com/datasets/mkechinov/ecommerce-events-history-in-electronics-store)). The `click_events.csv` file contains only 20k rows for demonstration purposes. You can replace it with a larger dataset as needed.