# frozen_string_literal: true

require 'roda'
require_relative 'cistercian_svg'

class App < Roda
  plugin :direct_call
  plugin :render
  plugin :class_matchers

  route do |router|
    router.root do
      @initial_input = router.params['n'] || ''
      @initial_numerals = if @initial_input.empty?
                            ''
                          else
                            numbers = extract_numbers(@initial_input)
                            render_numerals(numbers, secret_mode: false)
                          end
      view 'index'
    end

    router.on 'svg' do
      router.is String do |filename|
        next unless (match = filename.match(/\A(\d+)\.svg\z/))

        number = match[1].to_i
        next unless (0..9999).cover?(number)

        response['Content-Type'] = 'image/svg+xml'
        response['Content-Disposition'] = "inline; filename=\"cistercian-#{number}.svg\""
        response['Cache-Control'] = 'public, max-age=3600'
        CistercianSVG.svg(number)
      end
    end

    router.post 'numerals' do
      input = router.params['input'] || ''
      secret_mode = router.params['secret_mode'] == '1'
      numbers = extract_numbers(input)

      # Update browser URL without adding history entry
      url = input.empty? ? '/' : "/?n=#{URI.encode_www_form_component(input)}"
      response['HX-Replace-Url'] = url

      render_numerals(numbers, secret_mode:)
    end
  end

  private

  def extract_numbers(input)
    input.scan(/\d+/).flat_map { |digits| chunk_digits(digits) }
  end

  def chunk_digits(digits)
    # Extract leading zeros from the entire input first
    leading_zeros_count = digits.match(/^0*/)[0].length
    remainder = digits.sub(/^0+/, '')

    leading_zeros = Array.new(leading_zeros_count, 0)
    return leading_zeros if remainder.empty?

    # Zeros act as separators; non-zero sequences chunk up to 4 digits
    parts = remainder.scan(/0+|[1-9]\d{0,3}/)
    expanded = parts.flat_map do |part|
      part.match?(/^0+$/) ? Array.new(part.length, 0) : [part.to_i]
    end

    leading_zeros + expanded
  end

  def render_numerals(numbers, secret_mode:)
    return '' if numbers.empty?

    numbers.map.with_index do |num, index|
      caption = secret_mode ? '' : "<figcaption>#{num}</figcaption>"
      <<~HTML
        <figure id="fig-#{index}">
          <img src="/svg/#{num}.svg" alt="Cistercian numeral for #{num}">
          #{caption}
        </figure>
      HTML
    end.join
  end
end
