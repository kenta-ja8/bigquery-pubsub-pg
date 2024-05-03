terraform {
  required_version = "1.6.6"
}

provider "google" {
  region = "asia-northeast1"
}

data "google_project" "project" {
}

resource "google_project_iam_member" "publisher" {
  project = data.google_project.project.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "subscriber" {
  project = data.google_project.project.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "viewer" {
  project = data.google_project.project.project_id
  role    = "roles/bigquery.metadataViewer"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "editor" {
  project = data.google_project.project.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_bigquery_dataset" "test" {
  dataset_id = "example_dataset"
  location   = "asia-northeast1"
}

resource "google_bigquery_table" "test" {
  deletion_protection = true
  table_id            = "example_table"
  dataset_id          = google_bigquery_dataset.test.dataset_id

  # time_partitioning {
  #   type = "MONTH"
  # }

  schema = <<EOF
[
  {
    "name": "data",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The data"
  },
  {
    "name": "add_column",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "add column"
  },
  {
    "fields": [
        {
            "mode": "NULLABLE",
            "name": "a1",
            "type": "STRING"
        }
    ],
    "mode": "NULLABLE",
    "name": "ree",
    "type": "RECORD"
  },
  {
    "mode": "REPEATED",
    "name": "repeated_field",
    "type": "STRING"
  }
]
EOF
}
resource "google_pubsub_topic" "example" {
  name = "example-topic"
}

resource "google_pubsub_topic" "example_dead_letter" {
  name = "example-topic-dead-letter"
}

resource "google_pubsub_subscription" "example" {
  name  = "example-subscription"
  topic = google_pubsub_topic.example.id

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.example_dead_letter.id
    max_delivery_attempts = 5
  }

  bigquery_config {
    table            = "${google_bigquery_table.test.project}.${google_bigquery_table.test.dataset_id}.${google_bigquery_table.test.table_id}"
    use_table_schema = true
  }

  depends_on = [google_project_iam_member.viewer, google_project_iam_member.editor]
}

resource "google_pubsub_subscription" "example_dead_letter" {
  name  = "example-dead-letter-subscription"
  topic = google_pubsub_topic.example_dead_letter.id
}

# -----------------------------------------------------------------------
resource "google_bigquery_table" "deletable_table" {
  deletion_protection = true
  table_id            = "example_table_deletable"
  dataset_id          = google_bigquery_dataset.test.dataset_id

  time_partitioning {
    type = "MONTH"
  }
  clustering = []

  schema = <<EOF
[
  {
    "name": "data",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The data"
  },
  {
    "name": "add_column",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "add column"
  }
]
EOF

}


