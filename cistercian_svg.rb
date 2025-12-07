# frozen_string_literal: true

module CistercianSVG
  H = 45   # quadrant height (width is 30)
  GAP = 22 # vertical gap (~half of H for balanced proportions)

  # Each digit as line segments: [[x1, y1, x2, y2], ...]
  GLYPHS = [
    [], # 0
    [[0, 0, 30, 0]],                              # 1: top horiz
    [[0, H, 30, H]],                              # 2: bot horiz
    [[0, 0, 30, H]],                              # 3: diag down
    [[30, 0, 0, H]],                              # 4: diag up
    [[0, 0, 30, 0], [30, 0, 0, H]],               # 5: 1 + 4
    [[30, 0, 30, H]],                             # 6: vert
    [[0, 0, 30, 0], [30, 0, 30, H]],              # 7: 1 + 6
    [[0, H, 30, H], [30, H, 30, 0]],              # 8: 2 + 6
    [[0, 0, 30, 0], [30, 0, 30, H], [30, H, 0, H]] # 9: box open left
  ].freeze

  # Quadrant transforms: {origin_x:, origin_y:, scale_x:, scale_y:}
  QUADRANTS = [
    {origin_x: 50, origin_y: 10, scale_x: 1, scale_y: 1},                  # ones: top-right
    {origin_x: 50, origin_y: 10, scale_x: -1, scale_y: 1},                 # tens: top-left
    {origin_x: 50, origin_y: 10 + H * 2 + GAP, scale_x: 1, scale_y: -1},   # hundreds: bottom-right
    {origin_x: 50, origin_y: 10 + H * 2 + GAP, scale_x: -1, scale_y: -1}   # thousands: bottom-left
  ].freeze

  module_function

  def svg(number)
    raise ArgumentError, 'Must be 0-9999' unless (0..9999).cover?(number)

    wrap(glyph_lines(number))
  end

  def glyph_lines(number)
    digits = number.digits.fill(0, number.digits.length...4)
    lines = digits.zip(QUADRANTS).flat_map { |digit, pos| quadrant(digit:, **pos) }
    [stem, *lines].join("\n")
  end

  def quadrant(digit:, origin_x:, origin_y:, scale_x:, scale_y:)
    GLYPHS[digit].map do |from_x, from_y, to_x, to_y|
      line(
        from_x: origin_x + from_x * scale_x, from_y: origin_y + from_y * scale_y,
        to_x: origin_x + to_x * scale_x, to_y: origin_y + to_y * scale_y
      )
    end
  end

  def stem = %(<line x1="50" y1="10" x2="50" y2="#{10 + H * 2 + GAP}"/>)

  def line(from_x:, from_y:, to_x:, to_y:)
    %(<line x1="#{from_x}" y1="#{from_y}" x2="#{to_x}" y2="#{to_y}"/>)
  end

  def wrap(content)
    height = 10 + H * 2 + GAP + 10
    <<~SVG
      <svg viewBox="0 0 100 #{height}" xmlns="http://www.w3.org/2000/svg">
        <rect width="100" height="#{height}" fill="#f5f0e6"/>
        <g stroke="#2c1810" stroke-width="5" stroke-linecap="round">
      #{content.gsub(/^/, '    ')}
        </g>
      </svg>
    SVG
  end
end

if __FILE__ == $PROGRAM_NAME
  number = (ARGV[0] || 1234).to_i
  puts CistercianSVG.svg(number)
end
