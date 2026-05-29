class ContactImporter
  require 'csv'

  MAX_ROWS = 10_000

  Result = Struct.new(:imported_count, :errors, keyword_init: true) do
    def success?
      errors.empty?
    end
  end

  def self.call(organization:, file:, tag_name: nil)
    new(organization: organization, file: file, tag_name: tag_name).call
  end

  def initialize(organization:, file:, tag_name: nil)
    @organization = organization
    @file = file
    @tag_name = tag_name
  end

  def call
    tag = @organization.tags.find_or_create_by(name: @tag_name) if @tag_name.present?

    imported = 0
    errors   = []

    @organization.contacts.transaction do
      row_count = 0
      CSV.foreach(@file.path, headers: true) do |row|
        row_count += 1
        if row_count > MAX_ROWS
          errors << "File exceeds #{MAX_ROWS} rows only the first #{MAX_ROWS} were considered"
          break
        end

        contact = @organization.contacts.new(
          email: row['email'],
          first_name: row['first_name'],
          last_name: row['last_name']
        )

        if contact.save
          contact.tags << tag if tag
          imported += 1
        else
          errors << "#{row['email']}: #{contact.errors.full_messages.join(', ')}"
        end
      end
    end

    Result.new(imported_count: imported, errors: errors)
  end
end
