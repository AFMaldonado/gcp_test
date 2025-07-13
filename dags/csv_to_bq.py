from airflow import DAG
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from datetime import datetime

PROJECT_ID = 'test-de-465616'
DATASET_ORIGEN = 'raw_data'
DATASET_DESTINO = 'processed_data'
TABLE_ORIGEN = 'tabla_sin_procesar'
TABLE_DESTINO = 'tabla_transformada'
BUCKET = 'datalake-de-test'
GCS_PATH = 'test_file.csv'

with DAG(
    dag_id='gcs_to_bq_transform',
    schedule_interval=None,
    start_date=datetime(2023, 1, 1),
    catchup=False,
    tags=['gcp', 'bigquery', 'etl'],
) as dag:

    # 1. Cargar el archivo CSV de GCS a BigQuery
    cargar_csv_a_bq = GCSToBigQueryOperator(
        task_id='cargar_csv_a_bq',
        bucket=BUCKET,
        source_objects=[GCS_PATH],
        destination_project_dataset_table=f"{PROJECT_ID}.{DATASET_ORIGEN}.{TABLE_ORIGEN}",
        schema_fields=[
            {"name": "id", "type": "INTEGER", "mode": "REQUIRED"},
            {"name": "nombre", "type": "STRING", "mode": "NULLABLE"},
            {"name": "edad", "type": "INTEGER", "mode": "NULLABLE"},
            {"name": "email", "type": "STRING", "mode": "NULLABLE"},
        ],
        source_format='CSV',
        skip_leading_rows=1,
        write_disposition='WRITE_TRUNCATE',
    )

    # 2. Ejecutar una transformación con BigQuery SQL
    transformar_datos = BigQueryInsertJobOperator(
        task_id='transformar_datos',
        configuration={
            "query": {
                "query": f"""
                    CREATE OR REPLACE TABLE `{PROJECT_ID}.{DATASET_DESTINO}.{TABLE_DESTINO}` AS
                    SELECT
                        id,
                        UPPER(nombre) AS nombre_mayuscula,
                        edad,
                        LOWER(email) AS email_normalizado
                    FROM `{PROJECT_ID}.{DATASET_ORIGEN}.{TABLE_ORIGEN}`
                    WHERE edad >= 18
                """,
                "useLegacySql": False,
            }
        },
    )

    cargar_csv_a_bq >> transformar_datos
