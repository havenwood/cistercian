# frozen_string_literal: true

require 'roda'
require_relative 'cistercian_svg'
require_relative 'basingstoke_svg'

class App < Roda
  plugin :direct_call
  plugin :render
  plugin :class_matchers

  SYSTEMS = {
    'cistercian' => {range: 0..9999, renderer: CistercianSVG},
    'basingstoke' => {range: 0..99, renderer: BasingstokeSVG}
  }.freeze

  route do |r|
    r.root do
      @initial_input = r.params.fetch('n', '')
      @system = r.params.fetch('system', 'cistercian')
      @orientation = r.params.fetch('orientation', 'vertical')
      @hidden = r.params['hidden'] == '1'

      if @initial_input.empty?
        @initial_numerals = ''
        @initial_backdrop = ''
      else
        numbers = extract_numbers(@initial_input, system: @system)
        @initial_numerals = render_numerals(numbers, secret_mode: @hidden, system: @system)
        @initial_backdrop = render_backdrop(@initial_input, secret_mode: @hidden, system: @system)
      end
      view 'index'
    end

    r.on 'svg', String, String do |system, filename|
      serve_svg(system, filename)
    end

    r.post 'numerals' do
      input = r.params.fetch('input', '')
      secret_mode = r.params['secret_mode'] == '1'
      system = r.params.fetch('system', 'cistercian')
      orientation = r.params.fetch('orientation', 'vertical')

      numbers = extract_numbers(input, system:)

      response['HX-Replace-Url'] = build_url(input:, system:, orientation:, hidden: secret_mode)

      numerals = render_numerals(numbers, secret_mode:, system:)
      backdrop = render_backdrop(input, secret_mode:, system:)

      <<~HTML
        #{numerals}
        <div id="input_backdrop" hx-swap-oob="true" aria-hidden="true">#{backdrop}</div>
      HTML
    end
  end

  private

  def build_url(input:, system:, orientation:, hidden:)
    params = {
      n: (input unless input.empty?),
      system: ('basingstoke' if system == 'basingstoke'),
      orientation: ('horizontal' if orientation == 'horizontal'),
      hidden: (1 if hidden)
    }.compact
    params.empty? ? '/' : "/?#{URI.encode_www_form(params)}"
  end

  def serve_svg(system, filename)
    config = SYSTEMS[system]
    return unless config
    return unless (match = filename.match(/\A(\d+)\.svg\z/))

    number = match[1].to_i
    return unless config[:range].cover?(number)

    response['Content-Type'] = 'image/svg+xml'
    response['Content-Disposition'] = %(inline; filename="#{system}-#{number}.svg")
    response['Cache-Control'] = 'public, max-age=14400'
    config[:renderer].svg(number)
  end

  def extract_numbers(input, system:)
    input.scan(/\d+/).flat_map { |digits| chunk_digits(digits, system:) }
  end

  def chunk_digits(digits, system:)
    max_digits = system == 'basingstoke' ? 2 : 4

    leading_zeros_count = digits.match(/^0*/)[0].length
    remainder = digits.sub(/^0+/, '')

    leading_zeros = Array.new(leading_zeros_count, 0)
    return leading_zeros if remainder.empty?

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
