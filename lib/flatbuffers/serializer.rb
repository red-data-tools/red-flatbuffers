# Copyright 2026 Sutou Kouhei <kou@clear-code.com>
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

require_relative "append_as_bytes"

module FlatBuffers
  using AppendAsBytes if const_defined?(:AppendAsBytes)

  class Serializer
    module Alignable
      private
      def align32!(data)
        padding_size = data.bytesize % 4 # IO::Buffer.size_of(:s32)
        return if padding_size.zero?
        data.append_as_bytes("\x00" * padding_size)
      end
    end

    module Packable
      private
      def pack_value(base_type, value)
        case base_type
        when :bool
          [value ? 1 : 0].pack("c")
        when :utype
          [value || 0].pack("C")
        when :byte
          [value || 0].pack("c")
        when :ubyte
          [value || 0].pack("C")
        when :short
          [value || 0].pack("s<")
        when :ushort
          [value || 0].pack("S<")
        when :int
          [value || 0].pack("l<")
        when :uint
          [value || 0].pack("L<")
        when :long
          [value || 0].pack("q<")
        when :ulong
          [value || 0].pack("Q<")
        when :float
          [value || 0.0].pack("e")
        when :double
          [value || 0.0].pack("E")
        when :string
          value ||= ""
          packed_value = [value.bytesize].pack("L<")
          packed_value.append_as_bytes(value)
          packed_value.append_as_bytes("\x00")
          align32!(packed_value)
          packed_value
        when String
          klass = Object.const_get(base_type)
          if klass < Struct
            sub_struct_serializer = StructSerializer.new(+"".b)
            klass.serialize(value, sub_struct_serializer)
          end
        end
      end
    end

    class StructSerializer
      include Alignable
      include Packable

      def initialize(buffer)
        @buffer = buffer
      end

      def start
        yield
        finish
      end

      def add_field(field, value)
        packed_value = pack_value(field.base_type, value)
        @buffer.append_as_bytes(packed_value)
        unless field.padding.zero?
          @buffer.append_as_bytes("\x00" * field.padding)
        end
      end

      def finish
        @buffer
      end
    end

    class TableSerializer
      include Alignable
      include Packable

      def initialize
        @field_metadata = {}
        @field_values = +"".b
        @values = +"".b
      end

      def start
        @field_offsets = []
        yield
        finish
      end

      def add_field(field, value)
        if value.nil?
          @field_metadata[field] = {
            inline: true,
            offset: nil,
          }
        else
          case field.base_type
          when String
            klass = Object.const_get(field.base_type)
            if klass < Struct
              @field_metadata[field] = {
                inline: true,
                offset: @field_values.bytesize,
              }
              sub_struct_serializer = StructSerializer.new(@field_values)
              klass.serialize(value, sub_struct_serializer)
            elsif klass < Union
              sub_table_serializer = TableSerializer.new
              sub_table_data, sub_table_offset =
                value.class.table_class.serialize(value, sub_table_serializer)
              @field_metadata[field] = {
                inline: false,
                field_value_offset: @field_values.bytesize,
                value_offset: @values.bytesize + sub_table_offset,
              }
              @values.append_as_bytes(sub_table_data)
              @field_values << [0].pack("L<") # dummy
            else
              sub_table_serializer = TableSerializer.new
              sub_table_data, sub_table_offset =
                klass.serialize(value, sub_table_serializer)
              @field_metadata[field] = {
                inline: false,
                field_value_offset: @field_values.bytesize,
                value_offset: @values.bytesize + sub_table_offset,
              }
              @values.append_as_bytes(sub_table_data)
              @field_values << [0].pack("L<") # dummy
            end
          when Array
            value_offset = @values.bytesize
            # The number of elements.
            @values.append_as_bytes([value.size].pack("L<"))
            element_base_type = field.base_type[0]
            case element_base_type
            when String
              klass = Object.const_get(element_base_type)
              if klass < Struct
                value.each do |v|
                  sub_struct_serializer = StructSerializer.new(@values)
                  klass.serialize(v, sub_struct_serializer)
                end
              else
                offset_base = @values.bytesize
                # Placeholder for offsets.
                @values.append_as_bytes(([0] * value.size).pack("L<*")) # dummy
                value.each do |v|
                  sub_table_serializer = TableSerializer.new
                  sub_table_data, sub_table_offset =
                    klass.serialize(v, sub_table_serializer)

                  element_offset = @values.bytesize + sub_table_offset
                  # Update offset placeholder.
                  relative_element_offset = element_offset - offset_base
                  @values[offset_base, View::OFFSET_SIZE] =
                    [relative_element_offset].pack("L<")
                  offset_base += View::OFFSET_SIZE

                  @values.append_as_bytes(sub_table_data)
                end
              end
              @field_metadata[field] = {
                inline: false,
                field_value_offset: @field_values.bytesize,
                value_offset: value_offset,
              }
            when :string
              offset_base = @values.bytesize
              # Placeholder for offsets.
              @values.append_as_bytes(([0] * value.size).pack("L<*")) # dummy
              value.each do |v|
                packed_value = pack_value(element_base_type, v)

                element_offset = @values.bytesize
                # Update offset placeholder.
                relative_element_offset = element_offset - offset_base
                @values[offset_base, View::OFFSET_SIZE] =
                  [relative_element_offset].pack("L<")
                offset_base += View::OFFSET_SIZE

                @values.append_as_bytes(packed_value)
              end
              @field_metadata[field] = {
                inline: false,
                field_value_offset: @field_values.bytesize,
                value_offset: value_offset,
              }
            else
              value.each do |v|
                packed_value = pack_value(element_base_type, v)
                @values.append_as_bytes(packed_value)
              end
              @field_metadata[field] = {
                inline: false,
                field_value_offset: @field_values.bytesize,
                value_offset: value_offset,
              }
            end
            @field_values << [0].pack("L<") # dummy
          when :string
            @field_metadata[field] = {
              inline: false,
              field_value_offset: @field_values.bytesize,
              value_offset: @values.bytesize,
            }
            @values.append_as_bytes(pack_value(field.base_type, value))
            @field_values << [0].pack("L<") # dummy
          else
            @field_metadata[field] = {
              inline: true,
              offset: @field_values.bytesize,
            }
            @field_values << pack_value(field.base_type, value)
          end
        end
      end

      def finish
        align32!(@field_values)
        table_size = View::Table.compute_size(@field_values.bytesize)

        field_offset_base =
          View::VTable::VTABLE_SIZE_SIZE +
          View::VTable::TABLE_SIZE_SIZE
        @field_metadata.each do |field, metadata|
          if metadata[:inline]
            offset = metadata[:offset]
            if offset.nil?
              @field_offsets[field.index] = 0
            else
              @field_offsets[field.index] = field_offset_base + offset
            end
          else
            # Table, string or vector.
            field_value_offset = metadata[:field_value_offset]
            field_offset = field_offset_base + field_value_offset
            # Offset in `@values`.
            value_offset = metadata[:value_offset]
            # Offset in `@field_values` is relative from `offset_base`.
            offset_base = table_size - field_offset
            # `@values` is placed just after `@field_values`.
            # Offset in `@values` is relative from `offset`.
            offset = offset_base + value_offset
            @field_values[field_value_offset, View::OFFSET_SIZE] =
              [offset].pack("L<")
            @field_offsets[field.index] = field_offset
          end
        end
        @field_offsets.each_with_index do |offset, i|
          @field_offsets[i] = 0 if offset.nil?
        end

        vtable_size = View::VTable.compute_size(@field_offsets.size)

        data = +"".b
        vtable = View::VTable.serialize(vtable_size, table_size, @field_offsets)
        data.append_as_bytes(vtable)
        # We don't need "-" here because vtable_offset is subtracted
        # (not added).
        vtable_offset = vtable_size
        table = View::Table.serialize(vtable_offset, @field_values)
        data.append_as_bytes(table)
        data.append_as_bytes(@values)
        table_offset = vtable_size
        [data, table_offset]
      end
    end

    include Alignable

    def initialize(identifier)
      identifier = nil if identifier.is_a?(String) and identifier.empty?
      validate_identifier(identifier)
      @identifier = identifier
    end

    def start_table
      table_serializer = TableSerializer.new
      table, table_offset = yield(table_serializer)
      header_size = View::OFFSET_SIZE
      header_size += View::IDENTIFIER_SIZE if @identifier
      root_table_offset = header_size + table_offset
      data = [root_table_offset].pack("L<")
      data << @identifier if @identifier
      data << table
      data
    end

    private
    def validate_identifier(identifier)
      return if identifier.nil?
      return if identifier.bytesize == View::IDENTIFIER_SIZE
      raise ArgumentError,
            "Identifier must be nil or 4 bytes string: #{identifier.inspect}"
    end
  end
end
