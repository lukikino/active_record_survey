class AddActiveRecordSurvey < ActiveRecord::Migration
	def self.up
		create_table :active_record_surveys do |t|
			t.timestamps null: false
		end

		create_table :active_record_survey_nodes do |t|
			t.string :type
			t.string :text
			t.belongs_to :active_record_survey, foreign_key: true
			t.timestamps null: false
		end

		create_table :active_record_survey_node_validations do |t|
			t.belongs_to :active_record_survey_node, foreign_key: true
			t.string :type
			t.string :value

			t.timestamps null: false
		end

		create_table :active_record_survey_node_maps do |t|
			t.belongs_to :active_record_survey_node, foreign_key: true

			# AwesomeNestedSet fields
			t.integer :parent_id, :null => true, :index => true
			t.integer :lft, :null => false, :index => true
			t.integer :rgt, :null => false, :index => true

			# optional fields
			t.integer :depth, :null => false, :default => 0
			t.integer :children_count, :null => false, :default => 0

			t.belongs_to :active_record_survey, foreign_key: true

			t.timestamps null: false
		end

		create_table :active_record_survey_instances do |t|
			t.belongs_to :active_record_survey, foreign_key: true

			t.timestamps null: false
		end
		create_table :active_record_survey_instance_nodes do |t|
			t.belongs_to :active_record_survey_instance, foreign_key: true
			t.belongs_to :active_record_survey_node, foreign_key: true
			t.string :value

			t.timestamps null: false
		end
	end

	def self.down
		drop_table :active_record_surveys
		drop_table :active_record_survey_nodes
		drop_table :active_record_survey_node_validations
		drop_table :active_record_survey_node_maps
		drop_table :active_record_survey_instances
		drop_table :active_record_survey_instance_nodes
	end
end
