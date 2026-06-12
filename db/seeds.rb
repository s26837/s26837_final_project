# Mirrors what RegistrationsController#create does for an organic signup:
# creates the user, auto-creates an organization named "<name>'s Organization",
# and the owner membership is established by Organization's after_create callback.

ActiveRecord::Base.transaction do
  default_user = User.find_or_initialize_by(email: "default@mail.com")
  default_user.name                  = "Default User"
  default_user.password              = "Password123"
  default_user.password_confirmation = "Password123"
  was_new_user                       = default_user.new_record?
  default_user.save!
  puts "✓ User: #{default_user.email} / Password123 (#{was_new_user ? 'created' : 'updated'})"

  org_name = "#{default_user.name}'s Organization"
  default_org = Organization.find_or_initialize_by(name: org_name)
  default_org.owner ||= default_user
  was_new_org = default_org.new_record?
  default_org.save!
  puts "✓ Organization: #{default_org.name} (#{was_new_org ? 'created' : 'exists'})"

  unless default_org.organization_memberships.exists?(user: default_user)
    default_org.organization_memberships.create!(user: default_user, role: "owner")
    puts "✓ Membership: #{default_user.email} → #{default_org.name} (owner)"
  end

  sample_contacts = [
    { email: "alice@example.com",   first_name: "Alice",   last_name: "Anderson" },
    { email: "bob@example.com",     first_name: "Bob",     last_name: "Brown"    },
    { email: "carol@example.com",   first_name: "Carol",   last_name: "Clark"    },
    { email: "david@example.com",   first_name: "David",   last_name: "Davis"    },
    { email: "emma@example.com",    first_name: "Emma",    last_name: "Edwards"  },
    { email: "frank@example.com",   first_name: "Frank",   last_name: "Foster"   },
    { email: "grace@example.com",   first_name: "Grace",   last_name: "Garcia"   },
    { email: "henry@example.com",   first_name: "Henry",   last_name: "Harris"   }
  ]

  created = 0
  sample_contacts.each do |attrs|
    contact = default_org.contacts.find_or_initialize_by(email: attrs[:email])
    if contact.new_record?
      contact.update!(attrs.slice(:first_name, :last_name))
      created += 1
    end
  end
  puts "✓ Contacts: #{sample_contacts.size} total in #{default_org.name} (#{created} newly created)"
end
