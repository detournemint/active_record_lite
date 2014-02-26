require 'debugger'
require_relative '03_searchable'
require 'active_support/inflector'

# Phase IVa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key,
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    if self.class_name == "Human"
      return "humans"
    else
      self.class_name.downcase.pluralize 
    end
  end
end

class BelongsToOptions < AssocOptions  
  def initialize(name, options = {})
    defaults = { :foreign_key => "#{name}_id".to_sym,
          :primary_key => "id".to_sym,
          :class_name => name.to_s.capitalize.camelcase }
    defaults = defaults.merge(options)
    defaults.each do |key, value|
      self.send("#{key}=", value) 
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = { :foreign_key => "#{self_class_name}_id".to_sym.downcase,
          :primary_key => "id".to_sym,
          :class_name => name.to_s.capitalize.camelcase.singularize }
    defaults = defaults.merge(options)
    defaults.each do |key, value|
      self.send("#{key}=", value)
    end
  end
end

module Associatable 
  # Phase IVb
  
  def belongs_to(name, options = {})
    opts = BelongsToOptions.new(name, options)
    debugger
    define_method(:name) do 
      opts
        .model_class
        .where(opts.primary_key => self.send(opts.foreign_key))
        .first
    end
  end

  def has_many(name, self_class_name, options = {})
    opts = HasManyOptions.new(name, self_class_name, options)
    define_method(:name) do 
      self.send(options.foreign_key)
      opts
        .model_class
        .where(opts.primary_key => self.send(opts.foreign_key))
        .first
    end
  end

  def assoc_options
    # Wait to implement this in Phase V. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end

