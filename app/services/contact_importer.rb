class ContactImporter
  require 'csv'

  MAX_ROWS = 10_000

  MANDATORY_COLUMNS = %w[email first_name last_name].freeze

  Result = Struct.new(:imported_count, :skipped_count, :errors, keyword_init: true) do
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
    tag = @organization.tags.find_or_create_by(name: Tag.normalize_name(@tag_name)) if @tag_name.present?

    imported = 0
    skipped  = 0
    errors   = []

    @organization.contacts.transaction do
      row_count = 0
      header_converters = ->(header) { header&.strip }

      each_csv_row(headers: true, header_converters: header_converters) do |row|
        row_count += 1
        if row_count > MAX_ROWS
          errors << "File exceeds #{MAX_ROWS} rows only the first #{MAX_ROWS} were considered"
          break
        end

        if incomplete_row?(row)
          skipped += 1
          next
        end

        contact = @organization.contacts.new(
          email: row['email']&.strip,
          first_name: row['first_name']&.strip,
          last_name: row['last_name']&.strip
        )

        if contact.save
          contact.tags << tag if tag
          imported += 1
        else
          errors << "#{row['email']}: #{contact.errors.full_messages.join(', ')}"
        end
      end
    end

    Result.new(imported_count: imported, skipped_count: skipped, errors: errors)
  rescue CSV::MalformedCSVError => e
    Result.new(imported_count: 0, skipped_count: 0, errors: ["Could not read the file as CSV: #{e.message}"])
  end

  private

  def each_csv_row(**options, &block)
    content = File.read(@file.path).gsub(/\r\n?/, "\n")
    CSV.parse(content, **options, &block)
  end

  def incomplete_row?(row)
    MANDATORY_COLUMNS.any? { |column| row[column].to_s.strip.blank? }
  end
end
