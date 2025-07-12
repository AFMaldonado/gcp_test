variable "project_id" {
  description = "ID del proyecto de GCP"
  type        = string
  default     = "test-de-465616"
}

variable "region" {
  description = "Región de despliegue"
  type        = string
  default     = "us-east1"
}

variable "function_name" {
  description = "Nombre de la Cloud Function"
  type        = string
  default     = "gcs_to_bigquery"
}

variable "entry_point" {
  description = "Nombre de la función en main.py"
  type        = string
  default     = "main"
}

variable "trigger_bucket" {
  description = "Bucket que activa la función al subir un archivo"
  type        = string
  default     = "datalake-de-test"
}

variable "bq_project" {
  description = "ID del proyecto de destino en BigQuery"
  type        = string
  default     = "test-de-465616"
}

variable "bq_dataset" {
  description = "Nombre del dataset en BigQuery"
  type        = string
  default     = "raw_data"
}

variable "bq_table" {
  description = "Nombre de la tabla en BigQuery"
  type        = string
  default     = "example_table"
}

variable "service_account_email" {
  description = "Cuenta de servicio que ejecutará la función"
  type        = string
  default     = "199083437557-compute@developer.gserviceaccount.com"
}

# ✅ Nuevas variables para desacoplar la Cloud Function del bucket temporal

variable "function_source_bucket" {
  description = "Nombre del bucket donde está el código fuente ZIP de la función"
  type        = string
  default     = "my-temp-bucket-gcf" # 👈 Cámbialo al bucket real que usas para subir el ZIP
}

variable "function_source_object" {
  description = "Nombre del archivo ZIP subido al bucket"
  type        = string
  default     = "function-source.zip" # 👈 Asegúrate que coincida con el nombre que subas
}
