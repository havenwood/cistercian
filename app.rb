# frozen_string_literal: true

require 'roda'
require_relative 'cistercian_svg'
require_relative 'basingstoke_svg'

class App < Roda
  plugin :direct_call
  plugin :render
  plugin :class_matchers

  route do |router|
    router.root do
      @initial_input = router.params.fetch('n', '')
      @system = router.params.fetch('system', 'cistercian')
      @system = 'cistercian' unless %w[cistercian basingstoke].include?(@system)

      if @initial_input.empty?
        @initial_numerals = ''
        @initial_backdrop = ''
      else
        numbers = extract_numbers(@initial_input, system: @system)
        @initial_numerals = render_numerals(numbers, secret_mode: false, system: @system)
        @initial_backdrop = render_backdrop(@initial_input, secret_mode: false, system: @system)
      end
      view 'index'
    end

    router.on 'svg' do
      router.on 'cistercian' do
        router.is String do |filename|
          next unless (match = filename.match(/\A(\d+)\.svg\z/))

          number = match[1].to_i
          next unless (0..9999).cover?(number)

          response['Content-Type'] = 'image/svg+xml'
          response['Content-Disposition'] = "inline; filename=\"cistercian-#{number}.svg\""
          response['Cache-Control'] = 'public, max-age=14400'
          CistercianSVG.svg(number)
        end
      end

      router.on 'basingstoke' do
        router.is String do |filename|
          next unless (match = filename.match(/\A(\d+)\.svg\z/))

          number = match[1].to_i
          next unless (0..99).cover?(number)

          response['Content-Type'] = 'image/svg+xml'
          response['Content-Disposition'] = "inline; filename=\"basingstoke-#{number}.svg\""
          response['Cache-Control'] = 'public, max-age=14400'
          BasingstokeSVG.svg(number)
        end
      end
    end

    router.post 'numerals' do
      input = router.params.fetch('input', '')
      secret_mode = router.params['secret_mode'] == '1'
      system = router.params.fetch('system', 'cistercian')
      system = 'cistercian' unless %w[cistercian basingstoke].include?(system)

      numbers = extract_numbers(input, system:)

      # Update browser URL without adding history entry
      url_params = []
      url_params << "n=#{URI.encode_www_form_component(input)}" unless input.empty?
      url_params << 'system=basingstoke' if system == 'basingstoke'
      url = url_params.empty? ? '/' : "/?#{url_params.join('&')}"
      response['HX-Replace-Url'] = url

      numerals = render_numerals(numbers, secret_mode:, system:)
      backdrop = render_backdrop(input, secret_mode:, system:)

      <<~HTML
        #{numerals}
        <div id="input_backdrop" hx-swap-oob="true" aria-hidden="true">#{backdrop}</div>
      HTML
    end
  end

  private

  def extract_numbers(input, system:)
    input.scan(/\d+/).flat_map { |digits| chunk_digits(digits, system:) }
  end

  def chunk_digits(digits, system:)
    max_digits = system == 'basingstoke' ? 2 : 4

    # Extract leading zeros from the entire input first
    leading_zeros_count = digits.match(/^0*/)[0].length
    remainder = digits.sub(/^0+/, '')

    leading_zeros = Array.new(leading_zeros_count, 0)
    return leading_zeros if remainder.empty?

    # Zeros act as separators; non-zero sequences chunk up to max_digits
    pattern = /0+|[1-9]\d{0,#{max_digits - 1}}/
    parts = remainder.scan(pattern)
    expanded = parts.flat_map do |part|
      part.match?(/^0+$/) ? Array.new(part.length, 0) : [part.to_i]
    end

    leading_zeros + expanded
  end

  def render_numerals(numbers, secret_mode:, system:)
    return '' if numbers.empty?

    system_name = system == 'basingstoke' ? 'Basingstoke centesimal' : 'Cistercian numeral'
    numbers.map.with_index do |num, index|
      caption = secret_mode ? '' : "<figcaption>#{num}</figcaption>"
      <<~HTML
        <figure id="fig-#{index}">
          <img src="/svg/#{system}/#{num}.svg" alt="#{system_name} for #{num}">
          #{caption}
        </figure>
      HTML
    end.join
  end

  def render_backdrop(input, secret_mode:, system:)
    return '' if input.empty?

    chunk_index = 0
    input.gsub(/(\d+)|([^\d]+)/) do
      if (digits = ::Regexp.last_match(1))
        chunks = chunk_digits(digits, system:)
        chunks.map do |chunk|
          display = secret_mode ? '•' * chunk.to_s.length : chunk
          style = (chunk_index += 1).odd? ? 'num-a' : 'num-b'
          idx = chunk_index - 1
          %(<span class="#{style}" data-chunk="#{idx}">#{display}</span>)
        end.join
      else
        sep = ::Regexp.last_match(2)
        %(<span class="sep">#{sep}</span>)
      end
    end
  end
end
