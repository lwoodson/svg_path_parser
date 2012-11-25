$: << File.join('..', 'lib')
require 'svg_path_parser'

describe SvgPathParser::Impl do
  attr_accessor :inevtked, :context

  before :each do
    @context = {}
    @inevtked = false
  end

  context "unit" do
    context "parse_boolean" do
      it "should parse '1' to true" do
        SvgPathParser.parse_boolean('1').should == true
      end

      it "should parse '1.0' to true" do
        SvgPathParser.parse_boolean('1.0').should == true
      end

      it "should parse -1 to true" do
        SvgPathParser.parse_boolean('-1').should == true
      end

      it "should parse 0 to false" do
        SvgPathParser.parse_boolean('0').should == false
      end
    end

    context "to_points" do
      it "should parse 'M1 1' to [[1,1]]" do
        SvgPathParser.to_points('M1 1').should == [[1,1]]
      end

      it "should parse 'M1,1' to [[1,1]]" do
        SvgPathParser.to_points('M1,1').should == [[1,1]]
      end

      it "should parse 'M1, 1' to [[1,1]]" do
        SvgPathParser.to_points('M1, 1').should == [[1,1]]
      end

      it "should parse 'M 1 1' to [[1,1]]" do
        SvgPathParser.to_points('M 1 1').should == [[1,1]]
      end

      it "should parse M1 1 2 2 3 3 to [[1,1],[2,2],[3,3]]" do
        SvgPathParser.to_points('M1 1 2 2 3 3').should == [[1,1],[2,2],[3,3]] 
      end
    end
  end

  context "functional parse" do
    def validate(evt, cmd_str, context, current_pt)
      evt.command_str.should == cmd_str
      evt.context.should == context
      evt.current_pt.should == current_pt
      yield(evt) if block_given?
    end

    context "of move command" do
      it "should inevtke on_move with context, nil current_point and correct destination tuple" do
        test_obj = self
        context = @context
        @on_move = lambda do |evt|
          test_obj.inevtked = true
          test_obj.validate(evt, "M5 5", context, nil) do |evt|
            evt.dest_pt.should == [5,5]
          end
        end
        parser = SvgPathParser::Impl.new :on_move => @on_move
        parser.parse(@context, "M5 5").should == context
        inevtked.should == true
      end
    end

    context "of line command" do
      it "should inevtke on_line with context, previous tuple as current_point and correct destination tuple" do
        test_obj = self
        context = @context
        @on_line = lambda do |evt|
          test_obj.inevtked = true
          test_obj.validate(evt, "L10 10", context, [5,5]) do |evt|
            evt.dest_pt.should == [10,10]
          end
        end
        parser = SvgPathParser::Impl.new :on_line => @on_line
        parser.parse(@context, "M5 5L10 10").should == context
        inevtked.should == true
      end
    end

    context "of curve command" do
      it "should inevtke on_curve with context, previous tuple as current point and  correct destination, c1 and c2 tuples" do
        test_obj = self
        context = @context
        @on_curve = lambda do |evt|
          test_obj.inevtked = true
          test_obj.validate(evt, "C10 10 0 0 20 20", context, [5,5]) do |evt|
            evt.dest_pt.should == [10,10]
            evt.control_1.should == [0,0]
            evt.control_2.should == [20,20]
          end
        end
        parser = SvgPathParser::Impl.new :on_curve => @on_curve
        parser.parse(@context, "M5 5C10 10 0 0 20 20").should == context
        inevtked.should == true
      end
    end
    
    context "of quadratic command" do
      it "should inevtke on_quadratic with context, previous tuple as current point and correct destination and control tuples" do
        test_obj = self
        context = @context
        @on_quadratic = lambda do |evt|
          test_obj.inevtked = true
          test_obj.validate(evt, "Q10 10 7 7", context, [5,5]) do |evt|
            evt.dest_pt.should == [10,10]
            evt.control.should == [7,7]
          end
        end
        parser = SvgPathParser::Impl.new :on_quadratic => @on_quadratic
        parser.parse(@context, "M5 5Q10 10 7 7").should == context
        inevtked.should == true
      end
    end

    context "of arc command" do
      it "should inevtke on arc with context, previous tuple as current point and correct x_rad, y_rad, x_rot, large_arc, sweep and destination tuples" do
        test_obj = self
        @on_arc = lambda do |evt|
          test_obj.inevtked = true
          test_obj.validate(evt, "A30 50 -45 1 1 10 10", context, [5, 5]) do |evt|
            evt.x_radius.should == 30.0
            evt.y_radius.should == 50.0
            evt.x_rotation.should == -45.0
            evt.large_arc.should == true
            evt.sweep.should == true
            evt.dest_pt.should == [10,10]
          end
        end
        parser = SvgPathParser::Impl.new :on_arc => @on_arc
        parser.parse(@context, "M5 5A30 50 -45 1 1 10 10").should == context
        inevtked.should == true
      end
    end

    context "of close command" do
      it "should inevtke on_close with context, previous tuple as current point and first tuple as first point" do
        test_obj = self
        context = @context
        @on_close = lambda do |evt|
          test_obj.inevtked = true
          test_obj.validate(evt, "z", context, [10,10]) do |evt|
            evt.first_pt.should == [5,5]
          end
        end
        parser = SvgPathParser::Impl.new :on_close => @on_close
        parser.parse(@context, "M5 5L10 10z").should == context
        inevtked.should == true
      end
    end
  end
end
