FactoryGirl.define do
  factory :feature do
    trait :dhcp do
      name 'dhcp'
    end

    trait :dns do
      name 'dns'
    end
  end
end
