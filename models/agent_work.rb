class AgentWork < ActiveRecord::Base
   belongs_to :agent
   belongs_to :work
end