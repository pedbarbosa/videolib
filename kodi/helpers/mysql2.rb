# frozen_string_literal: true

require 'mysql2'

# Helper for MySQL connections
class MySQL2Helper

  def initialize(params)
    @mysql2_client = Mysql2::Client.new(params)
  end

  def query(mysql_query)
    @mysql2_client.query(mysql_query)
  end
end
