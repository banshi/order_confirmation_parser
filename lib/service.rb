module OrderConfirmationParser
  class Service
    class << self
      def exec
        validate_arguments

        OrderConfirmationParser::Parser.new.exec

        puts "Parsing completed"
      end

      def validate_arguments
        unless File.exists?(ARGV[0].to_s) && File.file?(ARGV[0].to_s)
          raise RuntimeError.new("Input file is invalid or doesn't exist")
        end

        if File.zero?(ARGV[0].to_s)
          raise RuntimeError.new("Nothing to parse. Input file is blank")
        end
      end
    end
  end
end
