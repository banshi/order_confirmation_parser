require 'sqlite3'
require 'active_record'

# Set up a database that resides in RAM
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Set up database tables and columns
ActiveRecord::Schema.define do
  create_table :orders do |t|
    t.datetime "confirmed_on", null: false
    t.string   "vendor_name", null: false
    t.string   "order_number", null: false
    t.integer  "status", default: 0
    t.string   "po_number"
    t.decimal  "total", precision: 10, scale: 2
  end
  create_table :line_items do |t|
    t.integer  "line_number"
    t.string   "item_number", null: false
    t.string   "description"
    t.integer  "quantity"
    t.decimal  "unit_price", precision: 10, scale: 2
    t.references :order
  end
end

# Set up model classes
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Order < ApplicationRecord
  STATUS_OPTIONS = %w(pending active)
  enum status: STATUS_OPTIONS

  has_many :line_items

  validates_presence_of :confirmed_on, :vendor_name, :order_number
  validates :status, inclusion: { in: STATUS_OPTIONS }

  def as_json
    super(include: :line_items)
  end
end

class LineItem < ApplicationRecord
  belongs_to :order
  validates_presence_of :item_number
end