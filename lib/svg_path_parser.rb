require 'super_collections/array'

module SvgPathParser
  # TODO refactor into testable method.
  to_points = lambda {|str| str.split(/[ ,]+/).map(&:to_f).tupelize}

  def self.parse_boolean(numeric)
    if numeric.to_i == 0
      false
    else
      true
    end
  end

  MoveStrategy = Proc.new do |parser, ctx, command_str|
    dest = to_points.call(command_str[1..-1])[0]
    parser.on_move.call(ctx, parser.current_pt, dest)
    dest
  end

  LineStrategy = Proc.new do |parser, ctx, command_str|
    dest = to_points.call(command_str[1..-1])[0]
    parser.on_line.call(ctx, parser.current_pt, dest)
    dest
  end

  CurveStrategy = Proc.new do |parser, ctx, command_str|
    dest, c1, c2 = to_points.call(command_str[1..-1])
    parser.on_curve.call(ctx, parser.current_pt, dest, c1, c2)
  end

  QuadraticStrategy = Proc.new do |parser, ctx, command_str|
    dest, c = to_points.call(command_str[1..-1])
    parser.on_quadratic.call(ctx, parser.current_pt, dest, c)
  end

  ArcStrategy = Proc.new do |parser, ctx, command_str|
    x_radius, y_radius, x_rot, large_arc, sweep, *dest = command_str[1..-1].split(/[ ,]+/).map(&:to_f)
    large_arc, sweep = [large_arc, sweep].map{|flag| SvgPathParser.parse_boolean(flag)}
    parser.on_arc.call(ctx, parser.current_pt, x_radius, y_radius, x_rot, large_arc, sweep, dest)
  end

  CloseStrategy = Proc.new do |parser, ctx, command_str|
    parser.on_close.call(ctx, parser.current_pt, parser.first_pt)
  end

  @strategies = {
    :M => MoveStrategy,
    :L => LineStrategy,
    :C => CurveStrategy,
    :Q => QuadraticStrategy,
    :A => ArcStrategy,
    :Z => CloseStrategy
  }

  class << self
    def strategy_for(command_key)
      @strategies[command_key.to_s.upcase.to_sym]
    end
  end

  class Impl
    attr_reader :current_pt, :first_pt, :on_move, :on_line, :on_curve, :on_quadratic, :on_arc, :on_close

    def initialize(opts={})
      @on_move = opts[:on_move] || lambda {|ctx, current, dest| }
      @on_line = opts[:on_line] || lambda {|ctx, current, dest| }
      @on_curve = opts[:on_curve] || lambda {|ctx, current, dest, c1, c2| }
      @on_quadratic = opts[:on_quadratic] || lambda {|ctx, current, dest, c| }
      @on_arc = opts[:on_arc] || lambda {|ctx, current, x_radius, y_radius, x_rot, large_arc, sweep, dest| }
      @on_close = opts[:on_close] || lambda {|ctx, current, first| }
    end

    def parse(ctx, path)
      tokenized_paths = path.scan /[MLCSQTHVZAmlcsqthvamlz][0-9. ,-]*/
      tokenized_paths.each do |token|
        strategy = SvgPathParser.strategy_for(command_of(token))
        raise "Unparseable command #{command_of token}" if strategy.nil?
        @current_pt = strategy.call(self, ctx, token)
        @first_pt = @current_pt if first_pt.nil?
      end
    end

    private
    def command_of(token)
      token[0..0].upcase.to_sym
    end
  end
end

