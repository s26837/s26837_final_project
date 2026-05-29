class EmailTemplate < ApplicationRecord
  belongs_to :organization
  has_many :campaign_steps, dependent: :restrict_with_error
  has_many :campaigns, through: :campaign_steps
  has_many :automation_rules, dependent: :restrict_with_error

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :subject, presence: true
  validates :html_content, presence: true

  before_validation :render_html_from_blocks

  scope :recent, -> { order(created_at: :desc) }

  def duplicate
    dup.tap do |template|
      template.name = "#{name} (Copy)"
    end
  end

  def blocks_array
    (blocks.is_a?(Array) ? blocks : []).map { |b| b.is_a?(Hash) ? b.with_indifferent_access : {} }
  end

  private

  def render_html_from_blocks
    return if blocks_array.empty?
    self.html_content = BlockRenderer.new(blocks_array).to_html
  end

  class BlockRenderer
    CONTAINER_OPEN = '<div style="max-width:600px;margin:0 auto;padding:24px;font-family:Arial,Helvetica,sans-serif;color:#1f2937;line-height:1.6;">'.freeze
    CONTAINER_CLOSE = '</div>'.freeze

    def initialize(blocks)
      @blocks = blocks
    end

    def to_html
      body = @blocks.map { |block| render_block(block) }.compact.join("\n")
      "#{CONTAINER_OPEN}\n#{body}\n#{CONTAINER_CLOSE}"
    end

    private

    def render_block(block)
      case block[:type]
      when "heading"   then render_heading(block)
      when "paragraph" then render_paragraph(block)
      when "button"    then render_button(block)
      when "link"      then render_link(block)
      when "divider"   then render_divider
      when "image"     then render_image(block)
      when "spacer"    then render_spacer(block)
      end
    end

    def render_heading(block)
      level = block[:level].to_i.clamp(1, 3)
      size  = { 1 => "28px", 2 => "22px", 3 => "18px" }[level]
      %(<h#{level} style="font-size:#{size};font-weight:700;margin:16px 0;">#{escape(block[:text])}</h#{level}>)
    end

    def render_paragraph(block)
      %(<p style="font-size:16px;margin:12px 0;">#{escape(block[:text]).gsub("\n", "<br>")}</p>)
    end

    def render_button(block)
      color = sanitize_color(block[:color]) || "#4F46E5"
      url   = sanitize_url(block[:url])    || "#"
      label = escape(block[:label].presence || "Click here")
      %(<div style="text-align:center;margin:20px 0;">) +
        %(<a href="#{url}" style="display:inline-block;background:#{color};color:#ffffff;padding:12px 28px;border-radius:6px;text-decoration:none;font-weight:600;">#{label}</a>) +
        %(</div>)
    end

    def render_link(block)
      url  = sanitize_url(block[:url]) || "#"
      text = escape(block[:text].presence || url)
      %(<p style="margin:12px 0;"><a href="#{url}" style="color:#4F46E5;text-decoration:underline;">#{text}</a></p>)
    end

    def render_divider
      %(<hr style="border:0;border-top:1px solid #e5e7eb;margin:24px 0;">)
    end

    def render_image(block)
      url      = sanitize_url(block[:url])
      return "" if url.blank?
      alt      = escape(block[:alt].to_s)
      link_url = sanitize_url(block[:link_url])
      img      = %(<img src="#{url}" alt="#{alt}" style="max-width:100%;height:auto;display:block;margin:16px auto;border-radius:4px;">)
      link_url.present? ? %(<a href="#{link_url}">#{img}</a>) : img
    end

    def render_spacer(block)
      height = { "small" => 12, "medium" => 24, "large" => 48 }[block[:size].to_s] || 24
      %(<div style="height:#{height}px;line-height:#{height}px;">&nbsp;</div>)
    end

    def escape(value)
      ERB::Util.html_escape(value.to_s)
    end

    def sanitize_url(value)
      str = value.to_s.strip
      return nil if str.blank?
      return str if str.match?(/\A(https?:|mailto:)/i)
      return "https://#{str}" if str.match?(/\A[\w.-]+\.[a-z]{2,}/i)
      nil
    end

    def sanitize_color(value)
      str = value.to_s.strip
      str.match?(/\A#[0-9a-f]{3,8}\z/i) ? str : nil
    end
  end
end
