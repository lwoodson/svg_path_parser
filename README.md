= Svg Path Parser =
This is an event-based parser for SVG path element data.

== Usage ==
```ruby
require 'svg_path_parser'

on_move = lambda{ |ctx, current, dest| puts "on_move received"}
on_line = lambda{|ctx, current, dest| puts "on_line received"}
on_curve  = lambda{|ctx, current, dest, c1, c2| puts "on_curve received"}
on_quadratic = lambda{|ctx, current, dest, c| puts "on_quadratic received"}
on_arc = lambda{|ctx, current, x_rad, y_rad, x_rot, large_arc, sweep, dest| puts "on_arc received"}
on_close = lambda{|ctx, current, first| puts "on_close received"}

parser = SvgPathParser::Impl.new :on_move => on_move,
                                 :on_line => on_line,
                                 :on_curve => on_curve,
                                 :on_quadratic => on_quadratic,
                                 :on_arc => on_arc,
                                 :on_close => on_close
parser.parse({}, "M5 5L10 10C15 15 0 0 20 20Q10 10 7 7A30 50 -45 1 1 30 30Z")
```

You only need to specify callbacks for the path commands you are interested in.

The context object passed as the first argument is used to collect results of
the parsing and needs to be modified by the callbacks to produce a meaningful
result of the parsing.  It is roughly analogous to a memo for the Array#inject method.
It is returned as the result of the parse call.

== Concrete Example ==
In this example, we will convert curves to lines in an SVG path, but otherwise
keep the path the same.

```ruby
convert_to_line = lambda do |vo|
  # a really bad conversion algorithm
  vo.context << "L#{vo.dest_pt[0]}#{vo.dest_pt[1]}"
end
dupe_command = lambda do |vo|
  vo.context << vo.command_str
end
parser = SvgPathParser::Impl.new :on_move => dupe_command,
                                 :on_line => dupe_command,
                                 :on_curve => convert_to_line,
                                 :on_quadratic => convert_to_line,
                                 :on_arc => convert_to_line,
                                 :on_close => dupe_command
parser.parse("", "M5 5L10 10C15 15 0 0 20 20Q10 10 7 7A30 50 -45 1 1 30 30Z")
 => "M5 5L10 10L15 15L10 10L30 30Z"
```
