# frozen_string_literal: true

require 'roda'
require_relative 'cistercian_svg'

class App < Roda
  plugin :direct_call
  plugin :render

  route do |router|
    router.root do
      view 'index'
    end

    router.post 'numerals' do
      input = router.params['input'] || ''
      show_arabic = router.params['show_arabic'] == '1'
      numbers = extract_numbers(input)
      render_numerals(numbers, show_arabic:)
    end
  end

  private

  def extract_numbers(input)
    input.scan(/\d+/).flat_map { |digits| chunk_digits(digits) }
  end

  def chunk_digits(digits)
    digits.scan(/.{1,4}/).map(&:to_i)
  end

  def render_numerals(numbers, show_arabic:)
    return '' if numbers.empty?

    numbers.map.with_index do |num, index|
      caption = show_arabic ? "<figcaption>#{num}</figcaption>" : ''
      <<~HTML
        <figure id="fig-#{index}">
          #{CistercianSVG.svg(num)}
          #{caption}
        </figure>
      HTML
    end.join
  end
end
