class Trailblazer::Operation
  # :private:
  # This code is not beautiful, but could also be worse.
  # I'm expecting some of this to go to Uber, as we use this pattern everywhere.
  class Option
    def self.call(proc)
      type = :proc

      option =
        if proc.is_a? Symbol
          type = :symbol
          ->(input, *_options) { call_method(proc, input, *_options) }
        elsif proc.is_a? Proc
          ->(input, *_options) { call_proc(proc, input, *_options) }
        elsif proc.is_a? Uber::Callable
          type = :callable
          ->(input, *_options) { call_callable(proc, input, *_options) }
        end

      yield type if block_given?

      option
    end

    def self.call_proc(proc, _input, *options)
      ActiveSupport::Notifications.instrument("call_proc.operation.trailblazer",
                                              proc: proc, input: _input,
                                              options: options) do
        proc.(*options)
      end
    end

    def self.call_method(proc, input, *options)
      ActiveSupport::Notifications.instrument("call_method.operation.trailblazer",
                                              proc: proc, input: input,
                                              options: options) do
        input.send(proc, *options)
      end
    end

    def self.call_callable(callable, _input, *options)
      ActiveSupport::Notifications.instrument("call_callable.operation.trailblazer",
                                              callable: callable, input: _input,
                                              options: options) do
        callable.(*options)
      end
    end

    # Call the option with keyword arguments. Ruby <= 2.0.
    class KW < Option
      def self.call_proc(proc, _input, options, tmp_options = {})
        ActiveSupport::Notifications.instrument("kw.call_proc.operation.trailblazer",
                                                proc: proc, input: _input,
                                                options: options, tmp_options: tmp_options) do
          if proc.arity == 1
            proc.(options)
          else
            proc.(options, **options.to_hash(tmp_options))
          end
        end
      end

      def self.call_method(proc, input, options, tmp_options = {})
        ActiveSupport::Notifications.instrument("kw.call_method.operation.trailblazer",
                                                proc: proc, input: input,
                                                options: options, tmp_options: tmp_options) do
          if input.method(proc).arity == 1
            input.send(proc, options)
          else
            input.send(proc, options, **options.to_hash(tmp_options))
          end
        end
      end

      def self.call_callable(callable, _input, options, tmp_options = {})
        ActiveSupport::Notifications.instrument("kw.call_callable.operation.trailblazer",
                                                callable: callable, input: _input,
                                                options: options, tmp_options: tmp_options) do
          if callable.method(:call).arity == 1
            callable.(options)
          else
            callable.(options, **options.to_hash(tmp_options))
          end
        end
      end
    end
  end
end

