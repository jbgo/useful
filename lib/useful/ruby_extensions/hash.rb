module Useful; end
module Useful::RubyExtensions; end

require 'json' unless defined?(JSON) && defined?(JSON::parse)
require 'useful/ruby_extensions/string' unless ::String.new.respond_to?(:cgi_escape)

module Useful::RubyExtensions::Hash
  
  module ClassMethods
    
    def from_json(string)
      JSON.parse(string)
    end
    
    # Return the hash with only keys in *keys
    def only(hash, *keys)
      s_keys = keys.flatten.collect{|k| k.to_s}
      hash.delete_if{ |k,v| !keys.flatten.include?(k) && !s_keys.include?(k) }
      hash
    end

    # Return the hash with only keys NOT in *keys
    def except(hash, *keys)
      s_keys = keys.flatten.collect{|k| k.to_s}
      hash.delete_if{ |k,v| keys.flatten.include?(k) || s_keys.include?(k) }
      hash
    end

    # takes any empty values and makes them nil
    def nillify(hash)
      hash.each do |key,value|
        if !value.nil? && ( (value.respond_to?('empty?') && value.empty?) || (value.respond_to?('to_s') && value.to_s.empty?) )
          hash[key] = nil
        end
      end
      hash
    end
    
  end
  
  module InstanceMethods
    
    def only(*keys)
      self.class.only(self.dup, keys)
    end
    def only!(*keys)
      self.class.only(self, keys)
    end

    def except(*keys)
      self.class.except(self.dup, keys)
    end
    
    def except!(*keys)
      self.class.except(self, keys)
    end

    def nillify
      self.class.nillify(self.dup)
    end
    def nillify!
      self.class.nillify(self)
    end

    # Returns the value for the provided key(s).  Allows searching in nested hashes
    def get_value(*keys_array)
      keys = keys_array.flatten
      if !keys.respond_to?('empty?') || keys.empty?
        nil
      else
        val = self[keys.shift]
        val.respond_to?('get_value') && !keys.empty? ? val.get_value(keys) : val
      end
    end
    alias search get_value

    # Determines if a value exists for the provided key(s).  Allows searching in nested hashes
    def check_value?(*keys_array)
      val = self.get_value(keys_array)
      val && !val.empty? ? true : false
    end

    # Returns string formatted for HTTP URL encoded name-value pairs.
    # For example,
    #  {:id => 'thomas_hardy'}.to_http_query_str 
    #  # => "?id=thomas_hardy"
    #  {:id => 23423, :since => Time.now}.to_http_query_str
    #  # => "?since=Thu,%2021%20Jun%202007%2012:10:05%20-0500&id=23423"
    #  {:id => [1,2]}.to_http_query_str
    #  # => "?id[]=1&id[]=2"
    #  {:poo => {:foo => 1, :bar => 2}}.to_http_query_str
    #  # => "?poo[bar]=2&poo[foo]=1"
    #  {:poo => {:foo => 1, :bar => {:bar1 => 1, :bar2 => "nasty"}}}.to_http_query_str
    #  "?poo[bar][bar1]=1&poo[bar][bar2]=nasty&poo[foo]=1"
    def to_http_query_str(opts = {})
      opts[:prepend] ||= '?'
      opts[:append] ||= ''
      opts[:key_ns] ||= nil
      opt_strings = self.sort{|a,b| a[0].to_s <=> b[0].to_s}.collect do |key_val|
        key = key_val[0]
        val = key_val[1]
        key_s = opts[:key_ns] ? "#{opts[:key_ns]}[#{key.to_s}]" : key.to_s
        if val.kind_of?(::Array)
          val.sort.collect{|i| "#{key_s}[]=#{i.to_s.cgi_escape}"}.join('&')
        elsif val.respond_to?('to_http_query_str')
          val.to_http_query_str({
            :prepend => '',
            :key_ns => key_s,
            :append => ''
          })
        else
          "#{key_s}=#{val.to_s.cgi_escape}"
        end
      end 
      self.empty? ? '' : "#{opts[:prepend]}#{opt_strings.join('&')}#{opts[:append]}"
    end

    def to_html_attrs
      self.empty? ? '' : self.sort{|a,b| a[0].to_s <=> b[0].to_s}.collect{|k_v| "#{k_v[0]}=\"#{k_v[1]}\""}.join(' ')
    end

  end
  
  module FromActivesupport
    
    module ClassMethods
      
      # inspired by ActiveSupport::CoreExtensions::Hash::Keys (http://api.rubyonrails.org/)
      def stringify_keys(hash)
        hash.keys.each{ |key| hash[(key.to_s rescue key)] ||= hash.delete(key) }
        hash
      end unless ::Hash.respond_to?('stringify_keys')

      # inspired by ActiveSupport::CoreExtensions::Hash::Keys (http://api.rubyonrails.org/)
      def symbolize_keys(hash)
        hash.keys.each{ |key| hash[(key.to_sym rescue key)] ||= hash.delete(key) }
        hash
      end unless ::Hash.respond_to?('symbolize_keys')
      
    end
    
    module InstanceMethods
      
      # Return a new hash with all keys converted to strings.
      def stringify_keys
        self.class.stringify_keys(self.dup)
      end unless {}.respond_to?('stringify_keys')
      # Destructively convert all keys to strings. 
      def stringify_keys!
        self.class.stringify_keys(self)
      end unless {}.respond_to?('stringify_keys!')

      # Return a new hash with all keys converted to strings.
      def symbolize_keys
        self.class.symbolize_keys(self.dup)
      end unless {}.respond_to?('symbolize_keys')
      # Destructively convert all keys to strings. 
      def symbolize_keys!
        self.class.symbolize_keys(self)
      end unless {}.respond_to?('symbolize_keys!')

    end
    
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.extend         FromActivesupport::ClassMethods
    receiver.send :include, InstanceMethods
    receiver.send :include, FromActivesupport::InstanceMethods
  end
  
end

class Hash
  include Useful::RubyExtensions::Hash  
end
