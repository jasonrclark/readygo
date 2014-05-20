module Ready
  class Context
    def initialize(name, configuration, old_suite)
      @name = name
      @set_proc = lambda { }
      @after_proc = lambda { }
      @all_definitions = []
      @configuration = configuration
      @old_suite = old_suite
      @suite = Suite.new
    end

    def self.all
      @all ||= []
    end

    def set(&block)
      @set_proc = block
    end

    def after(&block)
      @after_proc = block
    end

    def go(name, options={}, &block)
      full_name = @name + " " + name
      @all_definitions += [
        BenchmarkDefinition.new(full_name + " (GC)",
                                @set_proc, @after_proc, block, true),
        BenchmarkDefinition.new(full_name + " (No GC)",
                                @set_proc, @after_proc, block, false),
      ]
    end

    def finish
      BenchmarkCollection.new(@all_definitions).run.each do |benchmark|
        @suite = @suite.add(benchmark)
      end

      @suite.save! if @configuration.record?
      show_comparison if @configuration.compare?
    end

    def show_comparison
      comparisons = Comparison.from_suites(@old_suite, @suite)
      comparisons.each do |comparison|
        puts
        puts comparison.name
        puts comparison.to_plot.map { |s| "  " + s }.join("\n")
      end
    end
  end
end