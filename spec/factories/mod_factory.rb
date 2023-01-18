FactoryBot.define do
  factory :mod do
    id { SecureRandom.uuid }
    name { Faker::App.name }
    author { Faker::App.author }
    description { Faker::Lorem.sentence }
    long_description { Faker::Lorem.paragraph }
    version { Faker::App.version }
    compatibility { Faker::App.version }
    file_type { "zip" }
    url { Faker::Internet.url }
    image_url { Faker::Internet.url }
    readme_url { Faker::Internet.url }
    created_at { Time.now.utc - 1.day }
    updated_at { Time.now.utc }

    initialize_with { new(attributes) }
  end
end
