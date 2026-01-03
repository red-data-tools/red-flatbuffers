# Copyright 2025-2026 Sutou Kouhei <kou@clear-code.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative "serializer"
require_relative "table"
require_relative "view"

module FlatBuffers
  class RootTable < Table
    class << self
      def save(base_name, data)
        name = "#{base_name}.#{file_extension}"
        File.open(name, "wb") do |output|
          output.print(serialize(data))
        end
      end

      def serialize(data, table_serializer=nil)
        if table_serializer
          # Referenced table
          super(data, table_serializer)
        else
          # Root table
          serializer = Serializer.new(file_identifier)
          serializer.start_table do |table_serializer|
            super(data, table_serializer)
          end
        end
      end
    end

    def initialize(input)
      if input.is_a?(View)
        # Referenced table
        super
      else
        # Root table
        if input.is_a?(String)
          input = IO::Buffer.for(input)
        end
        offset = input.get_value(:u32, 0)
        super(View.new(input, offset, have_vtable: true))
      end
    end
  end
end
