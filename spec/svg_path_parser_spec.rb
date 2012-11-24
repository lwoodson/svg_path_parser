$: << File.join('..', 'lib')
require 'svg_path_parser'

describe SvgPathParser::Impl do
  attr_accessor :invoked, :context

  before :each do
    @context = {}
    @invoked = false
  end

  context "functional parse" do
    context "of move command" do
      before :each do
        test_obj = self
        context = @context
        @on_move = lambda do |ctx, current, dest|
          test_obj.invoked = true
          ctx.should == context
          current.should == nil
          dest.should == [5,5]
        end
      end

      context "with points specified with spaces between coordinates" do
        it "should invoke on_move with context, nil current_point and correct destination tuple" do
          parser = SvgPathParser::Impl.new :on_move => @on_move
          parser.parse(@context, "M5 5")
          invoked.should == true
        end
      end

      context "with points specified with commas between coordinates" do
        it "should invoke on_move with context, nil current_point and correct destination tuple" do
          parser = SvgPathParser::Impl.new :on_move => @on_move
          parser.parse(@context, "M5, 5")
          invoked.should == true
        end
      end
    end

    context "of line command" do
      before :each do
        test_obj = self
        context = @context
        @on_line = lambda do |ctx, current, dest|
          test_obj.invoked = true
          ctx.should == context
          current.should == [5,5]
          dest.should == [10,10]
        end
      end

      context "with points specified with spaces between coordinates" do
        it "should invoke on_line with context, previous tuple as current_point and correct destination tuple" do
          parser = SvgPathParser::Impl.new :on_line => @on_line
          parser.parse(@context, "M5 5L10 10")
          invoked.should == true
        end
      end

      context "with points specified with commas between coordinates" do
        it "should invoke on_line with context, previous tuple as current_point and correct destination tuple" do
          parser = SvgPathParser::Impl.new :on_line => @on_line
          parser.parse(@context, "M5, 5L10, 10")
          invoked.should == true
        end
      end
    end

    context "of curve command" do
      before :each do
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
      end

      context "with points separated with spaces and coordinates separated with spaces with spaces" do
        it "should invoke on_curve with context, previous tuple as current point and  correct destination, c1 and c2 tuples" do
          parser = SvgPathParser::Impl.new :on_curve => @on_curve
          parser.parse(@context, "M5 5C10 10 0 0 20 20")
          invoked.should == true
        end
      end 

      context "with points separated with commas and coordinates separated with spaces" do
        it "should invoke on_curve with context, previous tuple as current point and  correct destination, c1 and c2 tuples" do
          parser = SvgPathParser::Impl.new :on_curve => @on_curve
          parser.parse(@context, "M5 5C10 10 0 0 20 20")
          invoked.should == true
        end
      end 
    end
    
    context "of quadratic command" do
      before :each do
        test_obj = self
        context = @context
        @on_quadratic = lambda do |ctx, current, dest, control|
          test_obj.invoked = true
          ctx.should == context
          current.should == [5,5]
          dest.should == [10,10]
          control.should == [7,7]
        end
      end

      context "with points separated with spaces and coordinates separated with spaces" do
        it "should invoke on_quadratic with context, previous tuple as current point and correct destination and control tuples" do
          parser = SvgPathParser::Impl.new :on_quadratic => @on_quadratic
          parser.parse(@context, "M5 5Q10 10 7 7")
          invoked.should == true
        end
      end

      context "with points separated with commas and coordinates separated with spaces" do
        it "should invoke on_quadratic with context, previous tuple as current point and correct destination and control tuples" do
          parser = SvgPathParser::Impl.new :on_quadratic => @on_quadratic
          parser.parse(@context, "M5 5Q10 10,7 7")
          invoked.should == true
        end
      end
    end

    context "of arc command" do
      before :each do
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
      end

      it "should invoke on arc with context, previous tuple as current point and correct x_rad, y_rad, x_rot, large_arc, sweep and destination tuples" do
        parser = SvgPathParser::Impl.new :on_arc => @on_arc
        parser.parse(@context, "M5 5A30 50 -45 1 1 10 10")
        invoked.should == true
      end
    end

    context "of close command" do
      before :each do
        test_obj = self
        context = @context
        @on_close = lambda do |ctx, current, first|
          test_obj.invoked = true
          ctx.should == context
          current.should == [10,10]
          first.should == [5,5]
        end
      end

      context "with points specified with spaces between coordinates" do
        it "should invoke on_close with context, previous tuple as current point and first tuple as first point" do
          parser = SvgPathParser::Impl.new :on_close => @on_close
          parser.parse(@context, "M5 5L10 10z")
          invoked.should == true
        end
      end

      context "with points specified with commas between coordinates" do
        it "should invoke on_close with context, previous tuple as current point and first tuple as first point" do
          parser = SvgPathParser::Impl.new :on_close => @on_close
          parser.parse(@context, "M5, 5L10, 10z")
          invoked.should == true
        end
      end
    end
  end
end
