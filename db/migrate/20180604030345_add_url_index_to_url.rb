class AddUrlIndexToUrl < ActiveRecord::Migration[5.1]
  def change
  	add_index :urls, :url, unique: true
  end
end
