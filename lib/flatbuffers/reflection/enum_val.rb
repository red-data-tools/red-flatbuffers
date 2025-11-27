# Automatically generated. Don't modify manually.
#
# Red FlatBuffers version: 0.0.1
# Declared by:             //reflection.fbs
# Rooting type:            reflection.Schema (//reflection.fbs)

require "flatbuffers"
require_relative "key_value"
require_relative "type"

module FlatBuffers
  module Reflection
    class EnumVal < ::FlatBuffers::Table
      def attributes
        field_offset = @view.unpack_virtual_offset(14)
        return nil if field_offset.zero?

        @view.unpack_vector(field_offset, 4) do |element_offset|
          @view.unpack_table(KeyValue, element_offset)
        end
      end

      def documentation
        field_offset = @view.unpack_virtual_offset(12)
        return nil if field_offset.zero?

        @view.unpack_vector(field_offset, 4) do |element_offset|
          @view.unpack_string(element_offset)
        end
      end

      def name
        field_offset = @view.unpack_virtual_offset(4)
        return nil if field_offset.zero?

        @view.unpack_string(field_offset)
      end

      def union_type
        field_offset = @view.unpack_virtual_offset(10)
        return nil if field_offset.zero?

        @view.unpack_table(Type, field_offset)
      end

      def value
        field_offset = @view.unpack_virtual_offset(6)
        return 0 if field_offset.zero?

        @view.unpack_long(field_offset)
      end
    end
  end
end
