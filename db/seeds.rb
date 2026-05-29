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
end
