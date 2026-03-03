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

require_relative "alignable"

module FlatBuffers
  using AppendAsBytes if const_defined?(:AppendAsBytes)

  class Serializer
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
          pad!(@buffer, field.padding)
        end
      end

      def finish
        @buffer
      end
    end

    class TableSerializer
      include Alignable
      include Packable

      DUMMY_OFFSET = [0].pack("L<")

      def initialize
        @field_metadata = {}
        # vtable_offset. This is replaced later.
        @table = DUMMY_OFFSET.dup
        @values = +"".b
      end

      def start
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
            add_field_object(field, value)
          when Array
            add_field_array(field, value)
          when :string
            align!(@table, View::OFFSET_SIZE)
            align!(@values, View::OFFSET_SIZE)
            @field_metadata[field] = {
              inline: false,
              table_offset: @table.bytesize,
              value_offset: @values.bytesize,
            }
            @values.append_as_bytes(pack_value(field.base_type, value))
            @table.append_as_bytes(DUMMY_OFFSET) # Replaced later
          else
            align!(@table, field.alignment_size)
            @field_metadata[field] = {
              inline: true,
              offset: @table.bytesize,
            }
            @table.append_as_bytes(pack_value(field.base_type, value))
          end
        end
      end

      def finish
        vtable_size = View::VTable.compute_size(@field_metadata.size)
        align!(@table, LARGEST_ALIGNMENT_SIZE)
        table_size = @table.bytesize

        field_offsets = []
        @field_metadata.each do |field, metadata|
          if metadata[:inline] # Scalar or struct
            offset = metadata[:offset]
            if offset.nil?
              field_offsets[field.index] = 0
            else
              field_offsets[field.index] = offset
            end
          else # Table, string or vector.
            # |vtable|@table|@values|
            #
            # `vtable:` |vtable_size|table_size|field_offsets|
            # `field_offsets` uses relative offset from the start of
            # `vtable`.
            #
            # `@table`: |vtable_offset|fields|
            # `fields` uses relative offset from itself.

            # The offset in `fields`. This is relative from the start
            # of `@table`.
            table_offset = metadata[:table_offset]
            # The offset in `@values`. This is relative from the start
            # of `@table`.
            value_offset = metadata[:value_offset]
            # `@values` is placed just after `@table`.
            # `offset` is relative from `table_offset`.
            offset = table_size - table_offset + value_offset
            @table[table_offset, View::Table::VTABLE_OFFSET_SIZE] =
              [offset].pack("L<")
            field_offsets[field.index] = table_offset
          end
        end
        field_offsets.each_with_index do |offset, i|
          field_offsets[i] = 0 if offset.nil?
        end

        data = +"".b
        vtable = View::VTable.serialize(vtable_size,
                                        table_size,
                                        field_offsets)
        data.append_as_bytes(vtable)
        # We don't need "-" here because vtable_offset is subtracted
        # (not added).
        vtable_offset = vtable_size
        @table[0, View::Table::VTABLE_OFFSET_SIZE] = [vtable_offset].pack("l<")
        data.append_as_bytes(@table)
        align!(@values, LARGEST_ALIGNMENT_SIZE)
        data.append_as_bytes(@values)
        table_offset = vtable_size
        [data, table_offset]
      end

      private
      # Struct, union or table
      def add_field_object(field, value)
        align!(@table, View::OFFSET_SIZE)
        klass = Object.const_get(field.base_type)
        if klass < Struct
          @field_metadata[field] = {
            inline: true,
            offset: @table.bytesize,
          }
          sub_struct_serializer = StructSerializer.new(@table)
          klass.serialize(value, sub_struct_serializer)
        elsif klass < Union
          align!(@values, LARGEST_ALIGNMENT_SIZE)
          sub_table_serializer = TableSerializer.new
          sub_table_data, sub_table_offset =
          value.class.table_class.serialize(value, sub_table_serializer)
          @field_metadata[field] = {
            inline: false,
            table_offset: @table.bytesize,
            value_offset: @values.bytesize + sub_table_offset,
          }
          @values.append_as_bytes(sub_table_data)
          @table.append_as_bytes(DUMMY_OFFSET) # Replaced later
        else
          align!(@values, LARGEST_ALIGNMENT_SIZE)
          sub_table_serializer = TableSerializer.new
          sub_table_data, sub_table_offset =
          klass.serialize(value, sub_table_serializer)
          @field_metadata[field] = {
            inline: false,
            table_offset: @table.bytesize,
            value_offset: @values.bytesize + sub_table_offset,
          }
          @values.append_as_bytes(sub_table_data)
          @table.append_as_bytes(DUMMY_OFFSET) # Replaced later
        end
      end

      def add_field_array(field, value)
        align!(@table, View::OFFSET_SIZE)

        # Vector body must be aligned with 8 byte. Vector is
        # serialized as |length|body|. `length` is uoffset_t
        # (uint32_t) and its size is 4 byte. So we need to align
        # `@values` with 8 byte and pad the first 4 byte:
        # |4 byte padding|length (4 byte)|body (8 byte aligned)|
        vector_body_alignment = 8
        vector_length_pack_string = "L<"
        vector_length_size = 4
        align!(@values, vector_length_size)
        unless @values.bytesize % vector_body_alignment == vector_length_size
          pad!(@values, vector_body_alignment - vector_length_size)
        end
        value_offset = @values.bytesize
        @values.append_as_bytes([value.size].pack(vector_length_pack_string))

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
            value.size.times do
              @values.append_as_bytes(DUMMY_OFFSET) # Replaced later
            end
            align!(@values, LARGEST_ALIGNMENT_SIZE)
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
            table_offset: @table.bytesize,
            value_offset: value_offset,
          }
        when :string
          offset_base = @values.bytesize
          # Placeholder for offsets.
          value.size.times do
            @values.append_as_bytes(DUMMY_OFFSET) # Replaced later
          end
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
            table_offset: @table.bytesize,
            value_offset: value_offset,
          }
        else
          value.each do |v|
            packed_value = pack_value(element_base_type, v)
            @values.append_as_bytes(packed_value)
          end
          @field_metadata[field] = {
            inline: false,
            table_offset: @table.bytesize,
            value_offset: value_offset,
          }
        end
        @table.append_as_bytes(DUMMY_OFFSET) # Replaced later
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
      header_size += compute_padding_size(header_size, LARGEST_ALIGNMENT_SIZE)
      root_table_offset = header_size + table_offset
      data = [root_table_offset].pack("L<")
      data.append_as_bytes(@identifier) if @identifier
      align!(data, LARGEST_ALIGNMENT_SIZE)
      data.append_as_bytes(table)
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
