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

require_relative "data_definable"
require_relative "field"
require_relative "inspectable"

module FlatBuffers
  class Table
    include Inspectable
    extend DataDefinable

    class << self
      def table_class
        self
      end

      def serialize(data, table_serializer)
        table_serializer.start do
          self::FIELDS.each do |name, field|
            if field.base_type == :utype
              union_field_name = :"#{name.to_s.delete_suffix("_type")}"
              union_field = self::FIELDS[union_field_name]
              union_value = data.public_send(union_field_name)
              if union_value.nil?
                value = nil
              else
                union_class = Object.const_get(union_field.base_type)
                value = union_class.try_convert(union_value.class.table_class)
              end
            else
              value = data.public_send(name)
            end
            table_serializer.add_field(field, value)
          end
        end
      end
    end

    def initialize(view)
      unless view.is_a?(View)
        # For backward compatibility
        if view.is_a?(IO::Buffer)
          buffer = view
        else
          buffer = IO::Buffer.for(view)
        end
        offset = buffer.get_value(:u32, 0)
        view = View.new(buffer, offset, have_vtable: true)
      end
      @view = view
    end

    def ==(other)
      return false unless other.is_a?(self.class)
      self.class::FIELDS.keys.all? do |name|
        public_send(name) == other.public_send(name)
      end
    end
  end
end
