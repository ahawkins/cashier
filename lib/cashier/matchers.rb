module Cashier
  module Matchers

    def be_cached
      Cache.new
    end

    class Cache
      def matches?(target)
        @target = target

        @test_results = Cashier.keys_for(@target).inject({}) do |hash, key|
          hash.merge(key => Rails.cache.exist?(key))
        end

        flag = @test_results.values.inject(true) { |f, v| f && v }
        flag && Cashier.keys_for(@target).present?
      end

      def failure_message_for_should
        <<-msg
          expected the Rails.cache to include all these keys:
          #{Cashier.keys_for(@target).to_sentence}, but
          it did not include these keys:
          #{@test_results.keys.select {|k| @test_results[k] == false }.to_sentence}
        msg
      end

      def failure_message_for_should_not
        <<-msg
          expected the Rails.cache to not include all these keys:
          #{Cashier.keys_for(@target).to_sentence}, but
          it did include these keys:
          #{@test_results.keys.select {|k| @test_results[k] == true }.to_sentence}
        msg
      end
    end
  end
end
