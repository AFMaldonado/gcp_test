# GCP Event-Driven Architecture, CI/CD Deployment, and Airflow DAG

Este repositorio contiene la solución a tres ejercicios prácticos relacionados con arquitecturas orientadas a eventos en Google Cloud Platform (GCP), despliegue automatizado de funciones mediante CI/CD, y procesamiento de datos con Airflow.

## 🧩 1. Arquitectura orientada a eventos

Define una arquitectura orientada a eventos, en donde al recibir un archivo en un bucket este se procese.

**Descripción de la solución:**  
- Se utiliza **Cloud Storage** como punto de entrada (evento: carga de archivo).
- La carga de un archivo en el bucket dispara una **Cloud Function** (`cloud_function/main.py`).
- La función procesa el archivo según la lógica deseada.

**Diagrama conceptual:**
Usuario o sistema externo
│
Subida de archivo
a Bucket
│
Cloud Function (trigger: finalize/create)
│
Procesamiento del archivo

---

## 🚀 2. CI/CD con GitHub Actions + Terraform

Desarrolle un pipeline de GitHub que despliegue una Cloud Function a través de Terraform.

**Descripción de la solución:**  
- Se utiliza **GitHub Actions** como plataforma de CI/CD (`.github/workflows/deploy_cloud_function.yml`).
- El pipeline ejecuta Terraform para desplegar una Cloud Function con el código actualizado.

**Comandos claves del pipeline:**

- name: Terraform Init
  run: terraform init

- name: Terraform Apply
  run: terraform apply -auto-approve

## 🗃️ **3. DAG de Airflow: carga desde GCS a BigQuery**

Construya un DAG de Airflow que utilice operadores nativos para tomar un archivo desde un bucket e inserte en BigQuery, posteriormente ejecutar una query.

Descripción de la solución:

DAG ubicado en dags/gcs_to_bq_dag.py.

Usa operadores nativos de Airflow:

GCSToBigQueryOperator para cargar datos.

BigQueryInsertJobOperator para ejecutar una consulta SQL posterior.

Programado para ejecutarse diariamente o manualmente.

Pasos del DAG:

1. Toma archivo desde un bucket (GCS)
2. Inserta en una tabla de BigQuery
3. Ejecuta una query analítica sobre esa tabla

Nota: Se utiliza **GitHub Actions** como plataforma de CI/CD (`.github/workflows/deploy-dag.yml`). 

## 🚀 **4. Arquitectura de Datos**

a. Preguntas a las áreas de negocio
1.	¿Cuál es la prioridad de contacto?
o	¿Hay clientes que deben ser contactados antes que otros? (ej. por urgencia, valor del cliente).
2.	¿Cuál es la tolerancia a la latencia?
o	¿Se espera que los clientes sean contactados inmediatamente o se pueden contactar dentro de una ventana de tiempo razonable?
3.	¿Qué debe ocurrir si un intento de llamada falla?
o	¿Se reintenta? ¿Cuántas veces? ¿Con qué intervalo?
4.	¿Qué datos del cliente se deben enviar a la API?
o	Teléfono, nombre, código de campaña, tipo de producto, etc.
5.	¿Qué se espera como resultado?
o	¿La llamada debe completarse? ¿Solo se necesita agendar? ¿Debe capturar respuesta?
6.	¿Existen horarios o días hábiles en los que se puede llamar?
o	¿Se deben restringir llamadas por horarios?
________________________________________
b. Preguntas al proveedor de la API
1.	¿La API tiene alguna documentación?
2.	¿Cuál es el método de autenticación requerido?
o	API Key, OAuth2, JWT, etc.
2.	¿Qué ocurre si se excede el límite de 10 requests/segundo?
o	¿La API responde con 429 (Too Many Requests)? ¿Hay backoff sugerido?
3.	¿Soporta procesamiento asíncrono?
o	¿Existe un endpoint para enviar lote y luego consultar resultados?
4.	¿Qué tipo de respuesta devuelve la API?
o	¿Formato JSON? ¿Incluye estados de llamada?
5.	¿Existe una política de reintentos recomendada?
o	¿Cuántas veces, con qué intervalo?
6.	¿Existe un sandbox o entorno de pruebas?
o	Para hacer pruebas sin impacto en producción.
7.	¿Tienen SLA definidos para disponibilidad de la API?
________________________________________
c. Arquitectura propuesta en GCP
Descripción general
Necesitamos enviar en promedio 600 llamadas por hora = 10 por minuto = ~1 cada 6 segundos, lo que está muy por debajo del límite de 10 rps.
Para garantizar cumplimiento, escalabilidad y tolerancia a errores, usaremos:
Componentes
•	Cloud Scheduler: para lanzar el proceso de llamadas cada minuto.
•	Cloud Function (o Cloud Run): para procesar los lotes y enviar las llamadas.
•	Cloud Tasks: para controlar el rate limit y reintentos.
•	Cloud Logging + BigQuery: para trazabilidad.
________________________________________
Diagrama
En archivo diagrama.png

________________________________________
d. Justificación de la arquitectura
1.	Escalabilidad controlada:
o	Cloud Tasks permite controlar el número de ejecuciones concurrentes y el rate (configurable), cumpliendo los 10 rps máximos.
2.	Tolerancia a fallos y reintentos:
o	Cloud Tasks ofrece reintentos automáticos con backoff exponencial.
3.	Desacoplamiento y modularidad:
o	Scheduler se encarga del disparo periódico.
o	La lógica de envío está encapsulada y puede evolucionar sin afectar la programación.
4.	Costos bajos:
o	Todos los servicios son serverless y con bajo costo en bajo volumen.
5.	Auditoría y monitoreo:
o	Se puede enviar a BigQuery o Cloud Logging la traza de cada intento con resultado (éxito/fallo).
6.	Cumplimiento de reglas de negocio:
o	Se puede implementar lógica para horarios, filtros, prioridad, etc.


