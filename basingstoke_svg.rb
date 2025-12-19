# frozen_string_literal: true

# True Matthew Paris Basingstoke system (c. 1242)
# - Units (1-9) on LEFT side
# - Tens (10-90) on RIGHT side
# - 3 hook shapes × 3 vertical positions
module BasingstokeSVG
  W = 20         # width/length of hooks
  PAD = 8        # padding from edge to stem
  HOOK_PAD = 20  # extra padding for hooks that extend beyond stem
  STEM_LEN = 64  # stem length

  # Three hook shapes per Matthew Paris: "oblique, right, and acute angle"
  # All hooks attach at their zone's attachment point on the stem
  # Each shape as line segments [[x1, y1, x2, y2], ...] extending rightward from stem
  SHAPES = [
    [[0, 0, W, -W]], # oblique: diagonal up-outward
    [[0, 0, W, 0]],  # right: horizontal (90° angle)
    [[0, 0, W, W]]   # acute: diagonal down-outward
  ].freeze

  # Three attachment points per Matthew Paris: "top", "middle", "bottom" of stave
  STEM_TOP = PAD + HOOK_PAD
  ZONES = [
    STEM_TOP,                  # top of stave: digits 1, 2, 3
    STEM_TOP + STEM_LEN / 2,   # middle of stave: digits 4, 5, 6
    STEM_TOP + STEM_LEN        # bottom of stave: digits 7, 8, 9
  ].freeze

  # Digit to (zone_index, shape_index) mapping
  # 0 = empty (just stem)
  DIGIT_MAP = {
    1 => [0, 0], 2 => [0, 1], 3 => [0, 2],
    4 => [1, 0], 5 => [1, 1], 6 => [1, 2],
    7 => [2, 0], 8 => [2, 1], 9 => [2, 2]
  }.freeze

  # Units on LEFT (scale_x: -1), tens on RIGHT (scale_x: 1)
  # This is OPPOSITE to Cistercian!
  QUADRANTS = [
    {scale_x: -1}, # units: left side
    {scale_x: 1}   # tens: right side
  ].freeze

  module_function

  def svg(number)
    raise ArgumentError, 'Must be 0-99' unless (0..99).cover?(number)

    wrap(number:, content: glyph_lines(number))
  end

  def glyph_lines(number)
    digits = number.digits.fill(0, number.digits.length...2) # [units, tens]
    lines = digits.zip(QUADRANTS).flat_map { |digit, quad| render_digit(digit:, **quad) }
    [stem, *lines].join("\n")
  end

  def render_digit(digit:, scale_x:)
    return [] if digit.zero?

    zone_index, shape_index = DIGIT_MAP[digit]
    zone_y = ZONES[zone_index]
    shape = SHAPES[shape_index]

    shape.map do |from_x, from_y, to_x, to_y|
      line(
        from_x: 50 + from_x * scale_x,
        from_y: zone_y + from_y,
        to_x: 50 + to_x * scale_x,
        to_y: zone_y + to_y
      )
    end
  end

  def stem
    %(<line x1="50" y1="#{STEM_TOP}" x2="50" y2="#{STEM_TOP + STEM_LEN}"/>)
  end

  def line(from_x:, from_y:, to_x:, to_y:)
    %(<line x1="#{from_x}" y1="#{from_y}" x2="#{to_x}" y2="#{to_y}"/>)
  end

  def wrap(number:, content:)
    height = PAD + HOOK_PAD + STEM_LEN + HOOK_PAD + PAD
    <<~SVG
      <svg viewBox="0 0 100 #{height}" xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="title">
        <title id="title">Basingstoke centesimal for #{number}</title>
        <rect width="100" height="#{height}" fill="#f5f0e6"/>
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
