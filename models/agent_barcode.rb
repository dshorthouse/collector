class AgentBarcode < ActiveRecord::Base
   belongs_to :agent
   belongs_to :barcode
end