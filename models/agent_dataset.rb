class AgentDataset < ActiveRecord::Base
   belongs_to :agent
   belongs_to :dataset
end