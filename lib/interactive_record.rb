require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

  def self.db_execute(sql)
    DB[:conn].execute(sql)
  end

  def self.table_name
    "#{self.to_s.downcase}s"
  end

  def self.column_names
    sql = <<-SQL
      pragma table_info(#{self.table_name});
    SQL
    info_table = self.db_execute(sql)
    columns = info_table.map do |column|
      column["name"]
    end
    columns.compact
  end


  attr_accessor *self.column_names

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names[1..-1].join(', ')
  end

  def values_for_insert
    x = self.class.column_names[1..-1].map do |column|
      self.send(column)
    end.map{|x| "'" + x.to_s + "'"}.join(', ')

  end

  def save
    sql = <<-SQL
      INSERT INTO #{self.table_name_for_insert}
      (#{self.col_names_for_insert})
      VALUES (#{self.values_for_insert})
    SQL
    self.class.db_execute(sql)

    sql = <<-SQL
      SELECT last_insert_rowid() FROM #{self.table_name_for_insert};
    SQL

    self.id = DB[:conn].execute(sql)[0][0]
    self
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE name = "#{name}"
    SQL
    
    self.db_execute(sql)
  end

  def self.find_by(option)
    var = option.keys[0]
    val = option.values[0]

    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE #{var} = "#{val}"
    SQL
    self.db_execute(sql)

  end


end
