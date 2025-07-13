import functions_framework
from google.cloud import storage, bigquery
import os

# Variables de entorno recomendadas
BUCKET_NAME = os.environ.get('BUCKET_NAME')         # opcional si quieres validar bucket
BQ_PROJECT = os.environ.get('BQ_PROJECT')           # ID del proyecto
BQ_DATASET = os.environ.get('BQ_DATASET')           # Nombre del dataset
BQ_TABLE = os.environ.get('BQ_TABLE')               # Nombre de la tabla

@functions_framework.cloud_event
def main(cloud_event):
    """Se activa con un archivo nuevo en Cloud Storage y lo carga a BigQuery."""
    
    # Obtener los datos del archivo subido
    data = cloud_event.data
    bucket_name = data['bucket']
    file_name = data['name']

    print(f"Archivo detectado: {file_name} en bucket {bucket_name}")

    if not file_name.endswith(".csv"):
        print("No es un archivo CSV, se omite.")
        return

    # Cliente de BigQuery
    bq_client = bigquery.Client(project=BQ_PROJECT)

    # URI del archivo
    uri = f"gs://{bucket_name}/{file_name}"

    # Configuración de la carga
    table_id = f"{BQ_PROJECT}.{BQ_DATASET}.{BQ_TABLE}"
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        autodetect=True,  # Cambia esto si defines un schema explícito
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND
    )

    # Ejecutar el job de carga
    load_job = bq_client.load_table_from_uri(uri, table_id, job_config=job_config)
    load_job.result()  # Espera a que termine

    print(f"Carga completada en BigQuery: {table_id}")
