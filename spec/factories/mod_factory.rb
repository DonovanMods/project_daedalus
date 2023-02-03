FactoryBot.define do
  factory :mod do
    id { SecureRandom.uuid }
    name { Faker::App.name }
    author { Faker::App.author }
    description { Faker::Lorem.sentence }
    files { { zip: Faker::Internet.url } }
    version { Faker::App.version }
    compatibility { Faker::App.version }
    image_url { Faker::Internet.url }
    readme_url { Faker::Internet.url }
    created_at { Time.now.utc - 1.day }
    updated_at { Time.now.utc }

    initialize_with { new(attributes) }

    trait :old_type do
      files { {} }
      file_type { :zip }
      url { Faker::Internet.url }
    end
  end
end
