$: << File.join('..', 'lib')
require 'svg_path_parser'

describe SvgPathParser::Impl do
  attr_accessor :invoked, :context

  before :each do
    @context = {}
    @invoked = false
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
    def validate(vo, cmd_str, context, current_pt)
      vo.command_str.should == cmd_str
      vo.context.should == context
      vo.current_pt.should == current_pt
      yield(vo) if block_given?
    end

    context "of move command" do
      it "should invoke on_move with context, nil current_point and correct destination tuple" do
        test_obj = self
        context = @context
        @on_move = lambda do |vo|
          test_obj.invoked = true
          test_obj.validate(vo, "M5 5", context, nil) do |vo|
            vo.dest_pt.should == [5,5]
          end
        end
        parser = SvgPathParser::Impl.new :on_move => @on_move
        parser.parse(@context, "M5 5").should == context
        invoked.should == true
      end
    end

    context "of line command" do
      it "should invoke on_line with context, previous tuple as current_point and correct destination tuple" do
        test_obj = self
        context = @context
        @on_line = lambda do |vo|
          test_obj.invoked = true
          test_obj.validate(vo, "L10 10", context, [5,5]) do |vo|
            vo.dest_pt.should == [10,10]
          end
        end
        parser = SvgPathParser::Impl.new :on_line => @on_line
        parser.parse(@context, "M5 5L10 10").should == context
        invoked.should == true
      end
    end

    context "of curve command" do
      it "should invoke on_curve with context, previous tuple as current point and  correct destination, c1 and c2 tuples" do
        test_obj = self
        context = @context
        @on_curve = lambda do |vo|
          test_obj.invoked = true
          test_obj.validate(vo, "C10 10 0 0 20 20", context, [5,5]) do |vo|
            vo.dest_pt.should == [10,10]
            vo.control_1.should == [0,0]
            vo.control_2.should == [20,20]
          end
        end
        parser = SvgPathParser::Impl.new :on_curve => @on_curve
        parser.parse(@context, "M5 5C10 10 0 0 20 20").should == context
        invoked.should == true
      end
    end
    
    context "of quadratic command" do
      it "should invoke on_quadratic with context, previous tuple as current point and correct destination and control tuples" do
        test_obj = self
        context = @context
        @on_quadratic = lambda do |vo|
          test_obj.invoked = true
          test_obj.validate(vo, "Q10 10 7 7", context, [5,5]) do |vo|
            vo.dest_pt.should == [10,10]
            vo.control.should == [7,7]
          end
        end
        parser = SvgPathParser::Impl.new :on_quadratic => @on_quadratic
        parser.parse(@context, "M5 5Q10 10 7 7").should == context
        invoked.should == true
      end
    end

    context "of arc command" do
      it "should invoke on arc with context, previous tuple as current point and correct x_rad, y_rad, x_rot, large_arc, sweep and destination tuples" do
        test_obj = self
        @on_arc = lambda do |vo|
          test_obj.invoked = true
          test_obj.validate(vo, "A30 50 -45 1 1 10 10", context, [5, 5]) do |vo|
            vo.x_radius.should == 30.0
            vo.y_radius.should == 50.0
            vo.x_rotation.should == -45.0
            vo.large_arc.should == true
            vo.sweep.should == true
            vo.dest_pt.should == [10,10]
          end
        end
        parser = SvgPathParser::Impl.new :on_arc => @on_arc
        parser.parse(@context, "M5 5A30 50 -45 1 1 10 10").should == context
        invoked.should == true
      end
    end

    context "of close command" do
      it "should invoke on_close with context, previous tuple as current point and first tuple as first point" do
        test_obj = self
        context = @context
        @on_close = lambda do |vo|
          test_obj.invoked = true
          test_obj.validate(vo, "z", context, [10,10]) do |vo|
            vo.first_pt.should == [5,5]
          end
        end
        parser = SvgPathParser::Impl.new :on_close => @on_close
        parser.parse(@context, "M5 5L10 10z").should == context
        invoked.should == true
      end
    end
  end
end
