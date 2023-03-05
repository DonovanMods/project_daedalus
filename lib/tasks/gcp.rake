# frozen_string_literal: true

# rubocop:disable Layout/LineLength
namespace :gcp do
  desc "Build GCP Services"
  task build: :environment do
    sh "gcloud builds submit --config cloudbuild.yaml \
                             --substitutions _SERVICE_NAME=#{ENV.fetch("GOOGLE_SERVICE_NAME")},_INSTANCE_NAME=#{ENV.fetch("GOOGLE_INSTANCE_NAME")},_REGION=#{ENV.fetch("GOOGLE_REGION")}"
  end

  desc "Deploy to GCP Services"
  task deploy: :environment do
    sh "gcloud run deploy #{ENV.fetch("GOOGLE_SERVICE_NAME")} \
      --platform managed \
      --allow-unauthenticated \
      --region #{ENV.fetch("GOOGLE_REGION")} \
      --image gcr.io/#{ENV.fetch("GOOGLE_PROJECT_ID")}/#{ENV.fetch("GOOGLE_SERVICE_NAME")} \
      --add-cloudsql-instances #{ENV.fetch("CLOUD_SQL_CONNECTION_NAME")}"
  end

  desc "Update GCP Services"
  task update: :environment do
    sh "gcloud run deploy #{ENV.fetch("GOOGLE_SERVICE_NAME")} \
      --platform managed \
      --region #{ENV.fetch("GOOGLE_REGION")} \
      --image gcr.io/#{ENV.fetch("GOOGLE_PROJECT_ID")}/#{ENV.fetch("GOOGLE_SERVICE_NAME")}"
  end

  desc "Build and Deploy GCP Services"
  task release: %i[build update]
end
# rubocop:enable Layout/LineLength
