require 'super_collections/array'

module SvgPathParser
  def self.to_points(cmd_str)
    cmd_str[1..-1].split(/[ ,]+/).select{|e| not e.empty?}.map(&:to_f).tupelize 
  end

  def self.parse_boolean(numeric)
    if numeric.to_i == 0
      false
    else
      true
    end
  end

  DestinationVO = Struct.new :command_str, :context, :current_pt, :dest_pt
  CurveVO = Struct.new :command_str, :context, :current_pt, :dest_pt, :control_1, :control_2
  QuadraticVO = Struct.new :command_str, :context, :current_pt, :dest_pt, :control
  ArcVO = Struct.new :command_str, :context, :current_pt, :x_radius, :y_radius, :x_rotation, :large_arc, :sweep, :dest_pt
  CloseVO = Struct.new :command_str, :context, :current_pt, :first_pt

  MoveStrategy = Proc.new do |parser, ctx, command_str|
    dest = SvgPathParser.to_points(command_str)[0]
    parser.on_move.call(DestinationVO.new(command_str, ctx, parser.current_pt, dest))
    dest
  end

  LineStrategy = Proc.new do |parser, ctx, command_str|
    dest = SvgPathParser.to_points(command_str)[0]
    parser.on_line.call(DestinationVO.new(command_str, ctx, parser.current_pt, dest))
    dest
  end

  CurveStrategy = Proc.new do |parser, ctx, command_str|
    dest, c1, c2 = SvgPathParser.to_points(command_str)
    parser.on_curve.call(CurveVO.new(command_str, ctx, parser.current_pt, dest, c1, c2))
    dest
  end

  QuadraticStrategy = Proc.new do |parser, ctx, command_str|
    dest, c = SvgPathParser.to_points(command_str)
    parser.on_quadratic.call(QuadraticVO.new(command_str, ctx, parser.current_pt, dest, c))
    dest
  end

  ArcStrategy = Proc.new do |parser, ctx, command_str|
    x_radius, y_radius, x_rot, large_arc, sweep, *dest = command_str[1..-1].split(/[ ,]+/).map(&:to_f)
    large_arc, sweep = [large_arc, sweep].map{|flag| SvgPathParser.parse_boolean(flag)}
    parser.on_arc.call(ArcVO.new(command_str, ctx, parser.current_pt, x_radius, y_radius, x_rot, large_arc, sweep, dest))
    dest
  end

  CloseStrategy = Proc.new do |parser, ctx, command_str|
    parser.on_close.call(CloseVO.new(command_str, ctx, parser.current_pt, parser.first_pt))
    parser.first_pt
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

    # Initialize the parser with callbacks for commands encountered
    # sequentially within the path data.  All callbacks have default
    # do nothing lambdas that allow you to only specify what you need.
    def initialize(opts={})
      @on_move = opts[:on_move] || lambda {|vo| }
      @on_line = opts[:on_line] || lambda {|vo| }
      @on_curve = opts[:on_curve] || lambda {|ctx, current, dest, c1, c2| }
      @on_quadratic = opts[:on_quadratic] || lambda {|ctx, current, dest, c| }
      @on_arc = opts[:on_arc] || lambda {|ctx, current, x_radius, y_radius, x_rot, large_arc, sweep, dest| }
      @on_close = opts[:on_close] || lambda {|ctx, current, first| }
    end

    # Parse the path data within the given context.  The context can be
    # used as a memo objects, ala inject, to craft a result from the
    # parsing.
    def parse(ctx, path)
      tokenized_paths = path.scan /[MLCSQTHVZAmlcsqthvamlz][0-9. ,-]*/
      tokenized_paths.each do |token|
        strategy = SvgPathParser.strategy_for(command_of(token))
        raise "Unparseable command #{command_of token}" if strategy.nil?
        @current_pt = strategy.call(self, ctx, token)
        @first_pt = @current_pt if first_pt.nil?
      end
      ctx
    end

    private
    def command_of(token)
      token[0..0].upcase.to_sym
    end
  end
end

