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
    context "of move command" do
      it "should invoke on_move with context, nil current_point and correct destination tuple" do
        test_obj = self
        context = @context
        @on_move = lambda do |ctx, current, dest|
          test_obj.invoked = true
          ctx.should == context
          current.should == nil
          dest.should == [5,5]
        end
        parser = SvgPathParser::Impl.new :on_move => @on_move
        parser.parse(@context, "M5 5")
        invoked.should == true
      end
    end

    context "of line command" do
      it "should invoke on_line with context, previous tuple as current_point and correct destination tuple" do
        test_obj = self
        context = @context
        @on_line = lambda do |ctx, current, dest|
          test_obj.invoked = true
          ctx.should == context
          current.should == [5,5]
          dest.should == [10,10]
        end
        parser = SvgPathParser::Impl.new :on_line => @on_line
        parser.parse(@context, "M5 5L10 10")
        invoked.should == true
      end
    end

    context "of curve command" do
      it "should invoke on_curve with context, previous tuple as current point and  correct destination, c1 and c2 tuples" do
        test_obj = self
        context = @context
        @on_curve = lambda do |ctx, current, dest, c1, c2|
          test_obj.invoked = true
          ctx.should == context
          current.should == [5,5]
          dest.should == [10,10]
          c1.should == [0,0]
          c2.should == [20,20]
        end
        parser = SvgPathParser::Impl.new :on_curve => @on_curve
        parser.parse(@context, "M5 5C10 10 0 0 20 20")
        invoked.should == true
      end
    end
    
    context "of quadratic command" do
      it "should invoke on_quadratic with context, previous tuple as current point and correct destination and control tuples" do
        test_obj = self
        context = @context
        @on_quadratic = lambda do |ctx, current, dest, control|
          test_obj.invoked = true
          ctx.should == context
          current.should == [5,5]
          dest.should == [10,10]
          control.should == [7,7]
        end
        parser = SvgPathParser::Impl.new :on_quadratic => @on_quadratic
        parser.parse(@context, "M5 5Q10 10 7 7")
        invoked.should == true
      end
    end

    context "of arc command" do
      it "should invoke on arc with context, previous tuple as current point and correct x_rad, y_rad, x_rot, large_arc, sweep and destination tuples" do
        test_obj = self
        @on_arc = lambda do |ctx, current, x_rad, y_rad, x_rot, large_arc, sweep, dest|
          test_obj.invoked = true
          ctx.should == test_obj.context
          current.should == [5,5]
          x_rad.should == 30.0
          y_rad.should == 50.0
          x_rot.should == -45.0
          large_arc.should == true
          sweep.should == true
          dest.should == [10,10]
        end
        parser = SvgPathParser::Impl.new :on_arc => @on_arc
        parser.parse(@context, "M5 5A30 50 -45 1 1 10 10")
        invoked.should == true
      end
    end

    context "of close command" do
      it "should invoke on_close with context, previous tuple as current point and first tuple as first point" do
        test_obj = self
        context = @context
        @on_close = lambda do |ctx, current, first|
          test_obj.invoked = true
          ctx.should == context
          current.should == [10,10]
          first.should == [5,5]
        end
        parser = SvgPathParser::Impl.new :on_close => @on_close
        parser.parse(@context, "M5 5L10 10z")
        invoked.should == true
      end
    end
  end
end
