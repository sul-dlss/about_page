require 'ostruct'

module AboutPage

  class OpenStructWithHashAccess < OpenStruct
    delegate :each, :map, :to => :to_h
    def to_json(options = {})
      Hash[*@table.map { |k, v| [k, (v.to_h if v.respond_to? :to_h || v) ] }.flatten ]
    end

    def reject &block
      self.class.new to_h.reject(&block)
    end

    def select &block
      self.class.new to_h.select(&block)
    end

    def to_xml(options = {})
      @table
    end

    def to_h
      @table
    end
  end

  class Configuration
    attr_accessor :hash
    delegate :to_xml, :to_h, :to_json, :to => :hash
    delegate :each, :map, :to => :to_h

    def initialize hash = nil
      @hash = hash || OpenStructWithHashAccess.new
    end

    def reject &block
      AboutPage::Configuration.new @hash.reject(&block)
    end

    def select &block
      AboutPage::Configuration.new @hash.select(&block)
    end

    def method_missing *args
      @hash.send(*args)
    end

    def preflight request
      self.nodes.each { |key, profile| profile.preflight(request) }
    end

    def ok?
       self.nodes.select { |key, profile| profile.respond_to? :ok? }.all? { |key, profile| profile.ok? }
    end

    def nodes
      self.to_h.select { |key, profile| profile.is_a? AboutPage::Configuration::Node }
    end

    def set_headers! response
      self.nodes.each { |key, profile| profile.set_headers! response }
    end

    class Node
      def preflight request

      end

      def set_headers! response
        messages.each { |m| add_header(response, m) }
      end

      def add_header response, text
        response.headers['X-AboutPage-Warning'] ||= "" 
        response.headers['X-AboutPage-Warning'] += "#{text};"
        
      end

      def ok?
        true
      end

      def messages
        []
      end
    end
  end
end
