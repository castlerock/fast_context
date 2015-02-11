require 'shoulda/context'

module ShouldaContextExtensions
  def self.included(base)
    base.class_eval do
      alias_method :build_without_fast_context, :build
      alias_method :build, :build_with_fast_context

      alias_method :am_subcontext_without_fast_context?, :am_subcontext?
      alias_method :am_subcontext?, :am_subcontext_with_fast_context?
    end
  end

  def fast_context(name, &blk)
    @fast_subcontexts ||= []
    @fast_subcontexts << Shoulda::Context::FastContext.new(name, self, &blk)
  end

  def build_with_fast_context
    build_without_fast_context
    @fast_subcontexts ||= []
    @fast_subcontexts.each {|f| f.build }
  end

  def am_subcontext_with_fast_context?
    parent.is_a?(Shoulda::Context::Context) || parent.is_a?(Shoulda::Context::FastContext)
  end
end

module Shoulda
  module Context
    class FastContext < Context
      def test_method_name
        joined_should_name = shoulds.collect{ |should_hash| should_hash[:name] }.join(' and ')
        test_name = ["test", full_name, "should", joined_should_name].flatten.join('_')
        test_name = test_name.gsub(' ', '_').gsub(/[^a-zA-Z0-9_?!]/, '').gsub(/__+/, '_').to_sym
        return test_name
      end

      def create_test_from_should_hash
        test_name = test_method_name

        if test_unit_class.instance_methods.include?(test_name.to_s)
          warn "  * WARNING: '#{test_name}' is already defined"
        end

        context = self
        test_unit_class.send(:define_method, test_name) do
          @shoulda_context = context
          @current_should = nil
          begin
            context.run_parent_setup_blocks(self)
            context.shoulds.each do |s|
              @current_should = s
              s[:before].bind(self).call if s[:before]
            end
            context.run_current_setup_blocks(self)

            context.shoulds.each {|should| should[:block].bind(self).call }
          rescue Test::Unit::AssertionFailedError => e
            error = Test::Unit::AssertionFailedError.new(["test:", context.full_name, "should", "run_fast", "#{@current_should[:name]}:", e.message].flatten.join(' '))
            error.set_backtrace e.backtrace
            raise error
          ensure
            context.run_all_teardown_blocks(self)
          end
        end

        def build
          create_test_from_should_hash
          subcontexts.each {|context| context.build }

          @fast_subcontexts ||= []
          @fast_subcontexts.each {|f| f.build }

          print_should_eventuallys
        end
      end
    end
  end
end

module FastContextMethods
  def self.included(base)
    base.class_eval do
      def self.fast_context(name, &blk)
        if Shoulda::Context.current_context
          Shoulda::Context.current_context.fast_context(name, &blk)
        else
          context = Shoulda::Context::FastContext.new(name, self, &blk)
          context.build
        end
      end
    end
  end
end

module TestUnitOutputHelpers
  def self.included(base)
    base.class_eval do
      alias_method :add_failure_without_fast_context, :add_failure
      alias_method :add_failure, :add_failure_with_fast_context
    end
  end

  def add_failure_with_fast_context(message, all_locations=caller())
    message_name = name.include?('run_fast') ? name : message
    @test_passed = false
    @_result.add_failure(Test::Unit::Failure.new(message, filter_backtrace(all_locations), nil))
  end
end

ActiveSupport::TestCase.send(:include, FastContextMethods) if defined? ActiveSupport::TestCase
Test::Unit::TestCase.send(:include, FastContextMethods) if defined? Test::Unit::TestCase
Test::Unit::TestCase.send(:include, TestUnitOutputHelpers)

Shoulda::Context::Context.send :include, ShouldaContextExtensions
