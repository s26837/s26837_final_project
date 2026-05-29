module ApplicationHelper
  def tag_badge(tag, classes: "")
    bg = tag.display_color
    fg = contrasting_text_color(bg)
    content_tag(
      :span,
      tag.name,
      class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{classes}".strip,
      style: "background-color: #{bg}; color: #{fg};"
    )
  end

  def active_status_badge(active, extra_classes: "")
    palette = active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
    content_tag(
      :span,
      active ? 'Active' : 'Inactive',
      class: "inline-flex items-center rounded font-semibold #{palette} #{extra_classes}".strip
    )
  end

  def send_status_badge(status, extra_classes: "")
    palette = case status.to_s
              when 'delivered'                 then 'bg-green-100 text-green-800'
              when 'failed', 'bounced', 'spam' then 'bg-red-100 text-red-800'
              else                                  'bg-yellow-100 text-yellow-800'
              end
    content_tag(
      :span,
      status.to_s.titleize,
      class: "inline-flex items-center rounded font-semibold #{palette} #{extra_classes}".strip
    )
  end

  def campaign_status_badge(status, extra_classes: "")
    palette = case status.to_s
              when 'sent', 'sending' then 'bg-green-100 text-green-800'
              when 'scheduled'       then 'bg-blue-100 text-blue-800'
              when 'cancelled'       then 'bg-gray-100 text-gray-800'
              else                        'bg-yellow-100 text-yellow-800'
              end
    content_tag(
      :span,
      status.to_s.titleize,
      class: "inline-flex items-center rounded font-semibold #{palette} #{extra_classes}".strip
    )
  end

  def contrasting_text_color(hex)
    digits = hex.to_s.delete('#')
    return '#1F2937' unless digits.match?(/\A[0-9A-Fa-f]{6}\z/)
    r, g, b = digits.scan(/../).map { |c| c.to_i(16) }
    luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
    luminance > 0.6 ? '#1F2937' : '#FFFFFF'
  end

  def nav_link_class(section)
    active_class = "border-indigo-500 text-gray-900 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-semibold"
    inactive_class = "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"

    case section
    when :dashboard
      controller_name == 'dashboard' ? active_class : inactive_class
    when :contacts
      ['contacts', 'tags'].include?(controller_name) ? active_class : inactive_class
    when :templates
      controller_name == 'email_templates' ? active_class : inactive_class
    when :campaigns
      controller_name == 'campaigns' ? active_class : inactive_class
    when :automation
      controller_name == 'automation_rules' ? active_class : inactive_class
    when :analytics
      controller_name == 'analytics' ? active_class : inactive_class
    when :team
      ['members', 'invitations'].include?(controller_name) ? active_class : inactive_class
    else
      inactive_class
    end
  end
end
