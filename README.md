# Svg Path Parser
This is an event-based parser for SVG path element data.  Each of the commands
in a path string will generate a callback to a handler method specified at
parser creation.

## Usage
```ruby
require 'svg_path_parser'

on_move = lambda{ |vo| puts "Hey!  on_move received"}
on_line = lambda{|vo| puts "Hey!  on_line received"}
on_curve  = lambda{|vo| puts "Hey!  on_curve received"}
on_quadratic = lambda{|vo| puts "Hey!  on_quadratic received"}
on_arc = lambda{|vo| puts "Hey!  on_arc received"}
on_close = lambda{|vo| puts "Hey!  on_close received"}

parser = SvgPathParser::Impl.new :on_move => on_move,
                                 :on_line => on_line,
                                 :on_curve => on_curve,
                                 :on_quadratic => on_quadratic,
                                 :on_arc => on_arc,
                                 :on_close => on_close
parser.parse(nil, "M5 5L10 10C15 15 0 0 20 20Q10 10 7 7A30 50 -45 1 1 30 30Z")
Hey!  on_move received
Hey!  on_line received
Hey!  on_curve received
Hey!  on_quadratic received
Hey!  on_arc received
Hey!  on_close received
 => nil
```

You only need to specify callbacks for the path commands you are interested in.
All callbacks have default do-nothing lambdas that are invoked in response to
the various commands.

The context object passed as the first argument is used to collect results of
the parsing and needs to be modified by the callbacks to produce a meaningful
result of the parsing.  It is roughly analogous to a memo for the Array#inject method.
It is returned as the result of the parse call.

## Concrete Example
In this example, we will convert curves to lines in an SVG path, but otherwise
keep the path the same.

```ruby
require 'svg_path_parser'

convert_to_line = lambda do |vo|
  # a really bad conversion algorithm
  vo.context << "L#{vo.dest_pt[0]} #{vo.dest_pt[1]}"
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
 => "M5 5L10 10L15.0 15.0L10.0 10.0L30.0 30.0Z"
```

## Issues
* This currently does not support the horizontal/vertical (H/V) line shortcuts.
* This currently does not support the shortcuts for stringing together sets of 
bezier or quadratic curves (S/T).

Both of these should be easy to implement.
