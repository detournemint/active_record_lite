require_relative 'db_connection'
require_relative '01_mass_object'
require 'active_support/inflector'

class MassObject
  def self.parse_all(results)
    p results
    results.map do |result|
      self.new(result)
    end
  end
end

class SQLObject < MassObject
  def self.columns
    return @columns if @columns
    var = DBConnection.execute2("SELECT * FROM #{self.table_name}").first.each do |meth|
      meth = meth.to_sym
      define_method("#{meth}=") do |val|
          meth = meth.to_sym
         attributes[meth] = val
      end
      define_method("#{meth}") do
        meth = meth.to_sym
        attributes[meth]
      end 
    end
    @columns = var.map(&:to_sym)
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.downcase.pluralize.underscore
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        "#{self.table_name}"
    SQL
    parse_all(results)
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL)
      SELECT 
        * 
      FROM 
        #{self.table_name} 
      WHERE 
        id = #{id} 
      LIMIT 
        1
      SQL
    self.new(result.first)
  end

  def attributes
    @attributes ||= Hash.new(nil)
  end

  def insert
    col_names = self.attributes.keys.join(", ")
    p col_names
    question_marks = ["?"] * self.attributes.keys.count
    question_marks = question_marks.join(", ")
    DBConnection.execute(<<-SQL, *self.attribute_values)
      INSERT INTO 
        #{self.class.table_name} (#{col_names})
      VALUES 
        (#{question_marks})
     SQL
     self.id = DBConnection.last_insert_row_id
     p self.id
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      unless self.class.columns.include?(attr_name)
        raise "unknown attribute #{attr_name}"
      end
      self.attributes[attr_name] = value
    end
    self.class.columns
  end

  def save
   if self.id.nil? 
      self.insert
    else
      self.update
    end
  end

  def update
    col_names = self.attributes.keys.join(" = ?, ")
    col_names += " = ?"
    values =  attribute_values
    values << self.id
    DBConnection.execute(<<-SQL, *values)
      UPDATE 
        #{self.class.table_name}
      SET 
        #{col_names}
      WHERE
        id = ?
    SQL
    
  end

  def attribute_values
    @attributes.values
  end
end
