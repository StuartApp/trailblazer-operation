require "pp"

require "minitest/autorun"
require "trailblazer/operation"

Minitest::Spec::Circuit = Trailblazer::Circuit

module Test
  # Create a step method in `klass` with the following body.
  #
  #   def a(options, a_return:, data:, **)
  #     data << :a
  #
  #     a_return
  #   end
  def self.step(klass, *names)
    names.each do |name|
      method_def =
        %{def #{name}(options, #{name}_return:, data:, **)
          data << :#{name}

          #{name}_return
        end}

      klass.class_eval(method_def)
    end
  end
end
