# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/test'
require_relative '../app'

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    App
  end

  def numerals_for(input, secret_mode: false)
    post '/numerals', input: input, secret_mode: secret_mode ? '1' : '0'
    assert last_response.ok?
    extract_captions(last_response.body)
  end

  def extract_captions(html)
    html.scan(%r{<figcaption>(\d+)</figcaption>}).flatten.map(&:to_i)
  end

  def test_simple_number
    assert_equal [1234], numerals_for('1234')
  end

  def test_single_zero
    assert_equal [0], numerals_for('0')
  end

  def test_max_value
    assert_equal [9999], numerals_for('9999')
  end

  def test_multiple_numbers_separated_by_space
    assert_equal [42, 99], numerals_for('42 99')
  end

  def test_multiple_numbers_separated_by_any_character
    assert_equal [1, 2, 3], numerals_for('1-2-3')
    assert_equal [100, 200], numerals_for('100/200')
  end

  def test_leading_zeros_become_individual_zeros
    assert_equal [0, 0, 0, 0], numerals_for('0000')
    assert_equal [0, 0, 0, 0, 0, 1000], numerals_for('000001000')
  end

  def test_zeros_as_separators
    assert_equal [0, 0, 0, 0, 0, 1000, 0, 0, 3222], numerals_for('000001000003222')
  end

  def test_trailing_zeros
    assert_equal [1000, 0, 0], numerals_for('100000')
    assert_equal [0, 0, 0, 0, 0, 1000, 0], numerals_for('0000010000')
  end

  def test_zeros_separate_chunks
    assert_equal [1234, 0, 5678], numerals_for('123405678')
  end

  def test_large_numbers_chunk_every_four_digits
    assert_equal [1234, 5678], numerals_for('12345678')
  end

  def test_secret_mode_hides_captions
    post '/numerals', input: '1234', secret_mode: '1'
    assert last_response.ok?
    refute_includes last_response.body, '<figcaption>'
  end

  def test_secret_mode_still_renders_svg
    post '/numerals', input: '1234', secret_mode: '1'
    assert last_response.ok?
    assert_includes last_response.body, '<svg'
    assert_includes last_response.body, '<figure'
  end

  def test_empty_input_returns_empty
    post '/numerals', input: ''
    assert last_response.ok?
    assert_equal '', last_response.body.strip
  end

  def test_non_digit_input_returns_empty
    post '/numerals', input: 'abc'
    assert last_response.ok?
    assert_equal '', last_response.body.strip
  end

  def test_renders_svg_for_each_numeral
    post '/numerals', input: '1 2 3'
    assert last_response.ok?
    assert_equal 3, last_response.body.scan('<svg').count
  end

  def test_figure_ids_are_sequential
    post '/numerals', input: '1 2 3'
    assert last_response.ok?
    assert_includes last_response.body, 'id="fig-0"'
    assert_includes last_response.body, 'id="fig-1"'
    assert_includes last_response.body, 'id="fig-2"'
  end

  def test_root_returns_html
    get '/'
    assert last_response.ok?
    assert_includes last_response.body, 'Cistercian Numerals'
  end
end
