module WaitUntil

  class Wait

    class << self

      attr_accessor :default_timeout_in_seconds

      def until_true!(args={}, &block)
        operation = WaitUntil::Operation.new(args)
        raise operation.failure_message unless operation.eventually_true?(&block)
      end

      def until_false!(args={}, &block)
        until_true!(args) { !block.call }
      end

      def until!(args={}, &block)
        until_true!(args) do
          block.call
          true
        end
      end

    end

    self.default_timeout_in_seconds = ENV["timeout"] ? ENV["timeout"].to_i : 20

  end

end
