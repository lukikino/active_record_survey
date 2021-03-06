module ActiveRecordSurvey
	class Answer
		module Chained
			module ClassMethods
				def self.extended(base)
				end
			end

			module InstanceMethods

				# Gets index relative to other chained answers
				def sibling_index
					if node_map = self.survey.node_maps.select { |i|
						i.node == self
					}.first
						return node_map.ancestors_until_node_not_ancestor_of(::ActiveRecordSurvey::Node::Answer).length-1
					end

					return 0
				end

				# Chain nodes are different
				# They must also see if this answer linked to subsequent answers, and re-build the link
				def remove_answer(question_node)
					self.survey = question_node.survey

					# The node from answer from the parent question
					self.survey.node_maps.reverse.select { |i|
						i.node == self && !i.marked_for_destruction?
					}.each { |answer_node_map|
						answer_node_map.children.each { |child|
							answer_node_map.parent.children << child
						}

						answer_node_map.send((answer_node_map.new_record?)? :destroy : :mark_for_destruction )
					}
				end

				# Chain nodes are different - they must find the final answer node added and add to it
				# They must also see if the final answer node then points somewhere else - and fix the links on that
				def build_answer(question_node)
					self.survey = question_node.survey

					question_node_maps = self.survey.node_maps.select { |i|
						i.node == question_node && !i.marked_for_destruction?
					}

					answer_node_maps = self.survey.node_maps.select { |i|
						i.node == self && i.parent.nil? && !i.marked_for_destruction?
					}.collect { |i|
						i.survey = self.survey

						i
					}

					# No node_maps exist yet from this question
					if question_node_maps.length === 0
						# Build our first node-map
						question_node_maps << self.survey.node_maps.build(:node => question_node, :survey => self.survey)
					end

					last_answer_in_chain = (question_node.answers.last || question_node)

					# Each instance of this question needs the answer hung from it
					self.survey.node_maps.select { |i|
						i.node == last_answer_in_chain && !i.marked_for_destruction?
					}.each_with_index { |node_map, index|
						if answer_node_maps[index]
							new_node_map = answer_node_maps[index]
						else
							new_node_map = self.survey.node_maps.build(:node => self, :survey => self.survey)
						end

						# Hack - should fix this - why does self.survey.node_maps still think... yea somethigns not referenced right
						#curr_children = self.survey.node_maps.select { |j|
						#	node_map.children.include?(j) && j != new_node_map
						#}

						node_map.children << new_node_map

						#curr_children.each { |c|
						#	new_node_map.children << c
						#}
					}

					true
				end

				# Moves answer down relative to other answers by swapping parent and children
				def move_up
					# Ensure each parent node to this node (the goal here is to hit a question node) is valid
					!self.survey.node_maps.select { |i|
						i.node == self
					}.collect { |node_map|
						# Parent must be an answer - cannot move into the position of a Question!
						if !node_map.parent.nil? && node_map.parent.node.class.ancestors.include?(::ActiveRecordSurvey::Node::Answer)
							# I know this looks overly complicated, but we need to always work with the survey.node_maps - never children/parent of the relation
							parent_node = self.survey.node_maps.select { |j|
								node_map.parent == j
							}.first

							parent_parent = self.survey.node_maps.select { |j|
								node_map.parent.parent == j
							}.first

							node_map.parent = parent_parent
							parent_parent.children << node_map

							self.survey.node_maps.select { |j|
								node_map.children.include?(j)
							}.each { |c|
								c.parent = parent_node
								parent_node.children << c
							}

							parent_node.parent = node_map
							node_map.children << parent_node
						end
					}
				end

				# Moves answer down relative to other answers by swapping parent and children
				def move_down
					# Ensure each parent node to this node (the goal here is to hit a question node) is valid
					!self.survey.node_maps.select { |i|
						i.node == self
					}.collect { |node_map|
						# Must have children to move lower!
						# And the children are also answers!
						if node_map.children.length > 0 && !node_map.children.select { |j| j.node.class.ancestors.include?(::ActiveRecordSurvey::Node::Answer) }.empty?
							# I know this looks overly complicated, but we need to always work with the survey.node_maps - never children/parent of the relation
							parent_node = self.survey.node_maps.select { |j|
								node_map.parent == j
							}.first

							children = self.survey.node_maps.select { |j|
								node_map.children.include?(j)
							}

							children_children = self.survey.node_maps.select { |j|
								children.collect { |k| k.children }.flatten.include?(j)
							}

							children.each { |c|
								parent_node.children << c
							}

							children.each { |c|
								c.children << node_map
							}

							children_children.each { |i|
								node_map.children << i
							}
						end
					}
				end
			end
		end
	end
end