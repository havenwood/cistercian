# frozen_string_literal: true

# True Matthew Paris Basingstoke system (c. 1242)
# - Units (1-9) on LEFT side
# - Tens (10-90) on RIGHT side
# - 3 hook shapes × 3 vertical positions
module BasingstokeSVG
  HOOK_LEN = 16
  PAD = 2
  HOOK_PAD = 20
  STEM_LEN = 76
  STEM_TOP = PAD + HOOK_PAD
  HEIGHT = PAD + HOOK_PAD + STEM_LEN + HOOK_PAD + PAD # 120, matches Cistercian

  # Three hook shapes per Matthew Paris: "oblique, right, and acute angle"
  SHAPES = [
    [0, 0, HOOK_LEN, -HOOK_LEN], # oblique: diagonal up-outward
    [0, 0, HOOK_LEN, 0],         # right: horizontal (90° angle)
    [0, 0, HOOK_LEN, HOOK_LEN]   # acute: diagonal down-outward
  ].freeze

  # Units on LEFT (-1), tens on RIGHT (1) - opposite to Cistercian
  SCALES = [-1, 1].freeze

  module_function

  def svg(number)
    raise ArgumentError, 'Must be 0-99' unless (0..99).cover?(number)

    wrap(number:, content: glyph_lines(number))
  end

  def glyph_lines(number)
    digits = number.digits.fill(0, number.digits.length...2) # [units, tens]

    # Shorten stem when 1s/9s extend beyond bounds
    top_offset = digits.include?(1) ? HOOK_LEN : 0
    bottom_offset = digits.include?(9) ? HOOK_LEN : 0

    lines = digits.zip(SCALES).flat_map do |digit, scale_x|
      render_digit(digit, scale_x, top_offset, bottom_offset)
    end

    [stem(top_offset, bottom_offset), *lines].join("\n")
  end

  def render_digit(digit, scale_x, top_offset, bottom_offset)
    return [] if digit.zero?

    zone_index, shape_index = (digit - 1).divmod(3)
    zone_y = zone_at(zone_index, top_offset, bottom_offset)
    from_x, from_y, to_x, to_y = SHAPES[shape_index]

    [line(50 + from_x * scale_x, zone_y + from_y, 50 + to_x * scale_x, zone_y + to_y)]
  end

  def zone_at(index, top_offset, bottom_offset)
    stem_top = STEM_TOP + top_offset
    stem_len = STEM_LEN - top_offset - bottom_offset
    [stem_top, stem_top + stem_len / 2, stem_top + stem_len][index]
  end

  def stem(top_offset, bottom_offset)
    %(<line x1="50" y1="#{STEM_TOP + top_offset}" x2="50" y2="#{STEM_TOP + STEM_LEN - bottom_offset}"/>)
  end

  def line(from_x, from_y, to_x, to_y)
    %(<line x1="#{from_x}" y1="#{from_y}" x2="#{to_x}" y2="#{to_y}"/>)
  end

  def wrap(number:, content:)
    <<~SVG
      <svg viewBox="0 0 100 #{HEIGHT}" xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="title">
        <title id="title">Basingstoke centesimal for #{number}</title>
        <rect width="100" height="#{HEIGHT}" fill="#f5f0e6"/>
        <g stroke="#2c1810" stroke-width="5" stroke-linecap="round">
      #{content.gsub(/^/, '    ')}
        </g>
      </svg>
    SVG
  end
end

if __FILE__ == $PROGRAM_NAME
  number = ARGV.fetch(0, 42).to_i
  puts BasingstokeSVG.svg(number)
end
